"""Read service for concept progress and scheduling history (PRD 016, D12).

Two owner-scoped reads, both bounded and both built from persisted state:

* ``list_concept_progress`` projects the due-selection inputs T11 already owns
  (Commit 5) into client-safe items: stable IDs, retrievability band, review
  window and a plain-language due reason. No ranking inputs (forgetting risk,
  error severity, prerequisite counts) cross this boundary.
* ``get_concept_history`` returns a bounded evidence summary plus the stored
  scheduling explanations (reason codes + template key + safe message). Raw
  ``memory_events.event_payload``, scores and state snapshots are never
  selected, so they cannot leak.

Both run through the standard identity path: ``SET LOCAL ROLE memora_api``,
``memora_resolve_user_id`` for the caller and ``memora.user_id`` for row-level
security. An unknown concept, an unknown subject and another learner's concept
are indistinguishable to the caller (404).
"""

from __future__ import annotations

from collections.abc import Callable, Iterator
from contextlib import contextmanager
from dataclasses import asdict
from datetime import UTC, datetime, timedelta
from typing import Annotated, Any
from uuid import UUID

from fastapi import Depends
from sqlalchemy import Connection, Engine, text

from memora.api.errors import ApiError
from memora.api.security import AuthContext, AuthenticatedRequest
from memora.api.v1.schemas.common import Page
from memora.api.v1.schemas.memory import (
    ConceptHistoryResponse,
    ConceptProgressItem,
    DueReasonExplanation,
    EvidenceSummary,
    SchedulingExplanation,
)
from memora.core.config import Settings, get_settings
from memora.db.runtime import database_engine
from memora.modules.memory import selection
from memora.modules.memory.constants import (
    CONFIDENCE_BAND_HIGH,
    CONFIDENCE_BAND_HIGH_FLOOR,
    CONFIDENCE_BAND_LOW,
    CONFIDENCE_BAND_MEDIUM,
    CONFIDENCE_BAND_MEDIUM_FLOOR,
    HISTORY_EVIDENCE_WINDOW_DAYS,
    MEMORY_EVENT_TYPES,
)
from memora.modules.memory.engine import fsrs
from memora.modules.memory.engine.config import DEFAULT_ENGINE_CONFIG, EngineConfig
from memora.modules.memory.explanations import due_reason, explanation_message

DEFAULT_HISTORY_LIMIT = 20
MAX_HISTORY_LIMIT = 50
# Cursors are bound to the endpoint and filter that produced them (API §5).
PROGRESS_CURSOR_SCOPE = "memory.concept-progress/1"
HISTORY_CURSOR_SCOPE = "memory.concept-history/1"

_STATE_QUERY = text(
    """
    SELECT
        s.concept_id,
        s.active_concept_version_id AS concept_version_id,
        c.stable_code,
        cv.title,
        s.stability_days,
        s.evidence_confidence,
        s.first_exposed_at,
        s.last_reviewed_at,
        s.next_review_at,
        s.exposure_count,
        s.eligible_review_count,
        s.lapse_count
    FROM learner_concept_states s
    JOIN concepts c ON c.id = s.concept_id AND c.status = 'approved'
    JOIN concept_versions cv ON cv.id = s.active_concept_version_id
    WHERE s.user_id = CAST(:user_id AS uuid)
      AND s.concept_id = CAST(:concept_id AS uuid)
    """
)

_SUBJECT_QUERY = text(
    """
    SELECT EXISTS (
        SELECT 1 FROM subjects
        WHERE id = CAST(:subject_id AS uuid) AND status = 'approved'
    ) AS found
    """
)

_EVIDENCE_QUERY = text(
    """
    SELECT
        event_type,
        count(*) AS total_count,
        count(*) FILTER (WHERE is_eligible) AS eligible_count,
        count(*) FILTER (WHERE observed_at >= CAST(:window_start AS timestamptz)) AS recent_count,
        max(observed_at) AS last_observed_at
    FROM memory_events
    WHERE user_id = CAST(:user_id AS uuid)
      AND concept_id = CAST(:concept_id AS uuid)
      AND observed_at <= CAST(:as_of AS timestamptz)
    GROUP BY event_type
    ORDER BY event_type
    """
)

_DECISION_SQL = """
    SELECT
        d.id,
        d.decided_at,
        e.event_type AS trigger_event_type,
        d.next_review_at,
        d.reason_codes,
        d.explanation_template_key,
        d.engine_version,
        d.policy_version
    FROM memory_decisions d
    JOIN memory_events e ON e.id = d.trigger_event_id AND e.user_id = d.user_id
    WHERE d.user_id = CAST(:user_id AS uuid)
      AND d.concept_id = CAST(:concept_id AS uuid)
      {before_clause}
    ORDER BY d.decided_at DESC, d.id DESC
    LIMIT :limit
"""


def confidence_band(evidence_confidence: float) -> str:
    """Map an evidence-confidence estimate onto the client-facing band."""
    if evidence_confidence >= CONFIDENCE_BAND_HIGH_FLOOR:
        return CONFIDENCE_BAND_HIGH
    if evidence_confidence >= CONFIDENCE_BAND_MEDIUM_FLOOR:
        return CONFIDENCE_BAND_MEDIUM
    return CONFIDENCE_BAND_LOW


class MemoryReadRepository:
    """Owner-scoped reads over the memory tables (no writes, no payloads)."""

    def __init__(self, engine: Engine, *, config: EngineConfig = DEFAULT_ENGINE_CONFIG) -> None:
        self.engine = engine
        self.config = config

    @contextmanager
    def _connection(self, auth: AuthContext) -> Iterator[tuple[Connection, UUID]]:
        with self.engine.begin() as connection:
            connection.execute(text("SET LOCAL ROLE memora_api"))
            user_id = connection.scalar(
                text("SELECT memora_resolve_user_id(:issuer, :subject)"),
                {"issuer": auth.issuer, "subject": auth.subject},
            )
            if user_id is None:
                raise ApiError(403, "operation_not_allowed", "Account setup is required.")
            resolved = UUID(str(user_id))
            connection.execute(
                text("SELECT set_config('memora.user_id', :user_id, true)"),
                {"user_id": str(resolved)},
            )
            yield connection, resolved

    def subject_exists(self, auth: AuthContext, subject_id: UUID) -> bool:
        with self._connection(auth) as (connection, _):
            return bool(connection.scalar(_SUBJECT_QUERY, {"subject_id": str(subject_id)}))

    def due_page(
        self,
        auth: AuthContext,
        *,
        subject_id: UUID,
        as_of: datetime,
        horizon_days: float,
        limit: int,
        cursor: str | None,
        cursor_scope: str,
    ) -> selection.DueSelectionPage:
        """Delegate to the Commit-5 selection inputs inside the owner scope."""
        with self._connection(auth) as (connection, user_id):
            return selection.list_due_candidates(
                connection,
                user_id=user_id,
                subject_id=subject_id,
                as_of=as_of,
                horizon_days=horizon_days,
                limit=limit,
                cursor=cursor,
                cursor_scope=cursor_scope,
                config=self.config,
            )

    def concept_state(self, auth: AuthContext, concept_id: UUID) -> dict[str, Any] | None:
        with self._connection(auth) as (connection, user_id):
            row = (
                connection.execute(
                    _STATE_QUERY,
                    {"user_id": str(user_id), "concept_id": str(concept_id)},
                )
                .mappings()
                .first()
            )
        return None if row is None else dict(row)

    def evidence_summary(
        self,
        auth: AuthContext,
        concept_id: UUID,
        *,
        as_of: datetime,
        window_start: datetime,
    ) -> list[dict[str, Any]]:
        with self._connection(auth) as (connection, user_id):
            rows = (
                connection.execute(
                    _EVIDENCE_QUERY,
                    {
                        "user_id": str(user_id),
                        "concept_id": str(concept_id),
                        "as_of": as_of,
                        "window_start": window_start,
                    },
                )
                .mappings()
                .all()
            )
        return [dict(row) for row in rows]

    def list_decisions(
        self,
        auth: AuthContext,
        concept_id: UUID,
        *,
        limit: int,
        before: tuple[datetime, UUID] | None,
    ) -> tuple[list[dict[str, Any]], bool]:
        before_clause = ""
        extra: dict[str, Any] = {}
        if before is not None:
            before_clause = (
                "AND (d.decided_at, d.id) < "
                "(CAST(:before_at AS timestamptz), CAST(:before_id AS uuid))"
            )
            extra = {"before_at": before[0], "before_id": str(before[1])}
        with self._connection(auth) as (connection, user_id):
            rows = (
                connection.execute(
                    text(_DECISION_SQL.format(before_clause=before_clause)),
                    {
                        "user_id": str(user_id),
                        "concept_id": str(concept_id),
                        "limit": limit + 1,
                        **extra,
                    },
                )
                .mappings()
                .all()
            )
        has_more = len(rows) > limit
        return [dict(row) for row in rows[:limit]], has_more


class MemoryService:
    """Client-facing read models for T14/T15 consumers."""

    def __init__(
        self,
        repository: MemoryReadRepository,
        *,
        config: EngineConfig = DEFAULT_ENGINE_CONFIG,
        clock: Callable[[], datetime] | None = None,
    ) -> None:
        self.repository = repository
        self.config = config
        self._clock = clock or (lambda: datetime.now(UTC))

    def list_concept_progress(
        self,
        request: AuthenticatedRequest,
        subject_id: UUID,
        *,
        horizon_days: float,
        limit: int,
        cursor: str | None,
    ) -> Page[ConceptProgressItem]:
        _require_cursor(cursor, scope=f"{PROGRESS_CURSOR_SCOPE}/{subject_id}/{horizon_days:g}")
        if not self.repository.subject_exists(request.context, subject_id):
            raise ApiError(404, "resource_not_found", "Subject was not found.")

        page = self.repository.due_page(
            request.context,
            subject_id=subject_id,
            as_of=self._now(),
            horizon_days=horizon_days,
            limit=limit,
            cursor=cursor,
            cursor_scope=PROGRESS_CURSOR_SCOPE,
        )
        items = [
            ConceptProgressItem(
                concept_id=candidate.concept_id,
                concept_version_id=candidate.concept_version_id,
                stable_code=candidate.stable_code,
                title=candidate.title,
                state_band=candidate.retrievability_band,
                confidence_band=confidence_band(candidate.evidence_confidence),
                review_window=candidate.urgency,
                next_review_at=candidate.next_review_at,
                last_reviewed_at=candidate.last_reviewed_at,
                exposure_count=candidate.exposure_count,
                eligible_review_count=candidate.eligible_review_count,
                lapse_count=candidate.lapse_count,
                is_new_concept=candidate.is_new_concept,
                is_comeback=candidate.is_comeback,
                due_reason=DueReasonExplanation(**asdict(due_reason(candidate.selection_reason))),
            )
            for candidate in page.candidates
        ]
        return Page[ConceptProgressItem](
            items=items,
            next_cursor=page.next_cursor,
            has_more=page.next_cursor is not None,
        )

    def get_concept_history(
        self,
        request: AuthenticatedRequest,
        concept_id: UUID,
        *,
        limit: int,
        cursor: str | None,
    ) -> ConceptHistoryResponse:
        state = self.repository.concept_state(request.context, concept_id)
        if state is None:
            raise ApiError(404, "resource_not_found", "Concept was not found.")

        before = _decode_cursor(cursor, scope=f"{HISTORY_CURSOR_SCOPE}/{concept_id}")
        now = self._now()
        rows, has_more = self.repository.list_decisions(
            request.context,
            concept_id,
            limit=limit,
            before=before,
        )
        evidence_rows = self.repository.evidence_summary(
            request.context,
            concept_id,
            as_of=now,
            window_start=now - timedelta(days=HISTORY_EVIDENCE_WINDOW_DAYS),
        )

        explanations = [
            SchedulingExplanation(
                decision_id=UUID(str(row["id"])),
                decided_at=row["decided_at"],
                trigger_event_type=str(row["trigger_event_type"]),
                next_review_at=row["next_review_at"],
                reason_codes=[str(code) for code in row["reason_codes"]],
                template_key=str(row["explanation_template_key"]),
                message=explanation_message(str(row["explanation_template_key"])),
                engine_version=str(row["engine_version"]),
                policy_version=str(row["policy_version"]),
            )
            for row in rows
        ]
        next_cursor = None
        if has_more and rows:
            next_cursor = selection.encode_cursor(
                rows[-1]["decided_at"],
                UUID(str(rows[-1]["id"])),
                scope=f"{HISTORY_CURSOR_SCOPE}/{concept_id}",
            )

        anchor = state["last_reviewed_at"] or state["first_exposed_at"]
        retrievability = fsrs.retrievability(
            float(state["stability_days"]), anchor, now, config=self.config
        )
        return ConceptHistoryResponse(
            concept_id=UUID(str(state["concept_id"])),
            concept_version_id=UUID(str(state["concept_version_id"])),
            stable_code=str(state["stable_code"]),
            title=str(state["title"]),
            state_band=selection.retrievability_band(retrievability),
            next_review_at=state["next_review_at"],
            evidence=_evidence_summary(evidence_rows, state),
            items=explanations,
            next_cursor=next_cursor,
            has_more=has_more,
        )

    def _now(self) -> datetime:
        current = self._clock()
        if current.tzinfo is None:
            raise ValueError("clock must be timezone-aware")
        return current.astimezone(UTC)


def _require_cursor(cursor: str | None, *, scope: str) -> None:
    if cursor is not None:
        _decode_cursor(cursor, scope=scope)


def _decode_cursor(cursor: str | None, *, scope: str) -> tuple[datetime, UUID] | None:
    if cursor is None:
        return None
    try:
        return selection.decode_cursor(cursor, scope=scope)
    except ValueError as exc:
        raise ApiError(400, "invalid_cursor", "The page cursor is not valid.") from exc


def _evidence_summary(rows: list[dict[str, Any]], state: dict[str, Any]) -> EvidenceSummary:
    """Fold the bounded per-type evidence counts into one summary."""
    counts_by_type: dict[str, int] = {}
    total = 0
    recent = 0
    eligible = 0
    last_observed: datetime | None = None
    for row in rows:
        event_type = str(row["event_type"])
        if event_type not in MEMORY_EVENT_TYPES:  # pragma: no cover - DB CHECK
            continue
        total += int(row["total_count"])
        recent += int(row["recent_count"])
        eligible += int(row["eligible_count"])
        counts_by_type[event_type] = int(row["total_count"])
        observed = row["last_observed_at"]
        if observed is not None and (last_observed is None or observed > last_observed):
            last_observed = observed
    return EvidenceSummary(
        window_days=HISTORY_EVIDENCE_WINDOW_DAYS,
        total_events=total,
        recent_events=recent,
        eligible_events=eligible,
        counts_by_type=counts_by_type,
        last_observed_at=last_observed,
        confidence_band=confidence_band(float(state["evidence_confidence"])),
    )


def get_memory_service(
    settings: Annotated[Settings, Depends(get_settings)],
) -> MemoryService:
    return MemoryService(MemoryReadRepository(database_engine(settings.database_url)))
