"""Due-selection inputs for the mission planner (TRD §9.4, PRD 013).

T11 owns the memory model; T13 owns mission assembly. This module is the
boundary between them: it returns typed, bounded, read-only *inputs* for
ranking - urgency, estimated forgetting risk, recent error severity,
prerequisite impact, weak-prerequisite evidence, comeback and curriculum
coverage flags - and deliberately performs no ranking, no diversity selection
and no workload capping. Those are T13 decisions, and TRD §9.4 forbids the
client from ever receiving the candidate pool.

Every query is bounded (page size, near-due horizon, evidence sample,
coverage fan-out, graph depth) so no unbounded candidate set can leave the
backend. Results are keyset-paginated on ``(next_review_at, concept_id)``,
which matches the ``ix_learner_concept_states_due`` index.

The caller supplies ``user_id`` and is expected to run inside the
authenticated transaction (``memora_api`` with ``memora.user_id`` set). The
predicate documents intent; RLS remains defence in depth, exactly as in
:mod:`memora.modules.memory.prerequisites`.
"""

from __future__ import annotations

import base64
import binascii
from collections.abc import Mapping
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from memora.modules.curriculum.constants import DEFAULT_PREREQ_DEPTH, MAX_PREREQ_DEPTH
from memora.modules.memory.constants import (
    RETRIEVABILITY_BAND_CRITICAL,
    RETRIEVABILITY_BAND_FADING,
    RETRIEVABILITY_BAND_FRESH,
    RETRIEVABILITY_BAND_SETTLING,
    SELECTION_INPUT_VERSION,
    SELECTION_REASON_CODES,
    SELECTION_REASON_ERROR_REPAIR,
    SELECTION_REASON_NEW_CONCEPT,
    SELECTION_REASON_OVERDUE,
    SELECTION_REASON_RETENTION,
    SELECTION_REASON_WEAK_PREREQUISITE,
    URGENCY_BANDS,
    URGENCY_DUE,
    URGENCY_NEAR_DUE,
    URGENCY_OVERDUE,
)
from memora.modules.memory.engine import fsrs
from memora.modules.memory.engine.config import DEFAULT_ENGINE_CONFIG, EngineConfig
from memora.modules.memory.engine.policy import is_comeback_elapsed
from memora.modules.memory.prerequisites import is_weak_prerequisite_state

# --- bounds -------------------------------------------------------------
DEFAULT_SELECTION_LIMIT = 20
MAX_SELECTION_LIMIT = 50
DEFAULT_HORIZON_DAYS = 3.0
MAX_HORIZON_DAYS = 30.0
# A review inside the next day is presented as due, not merely near-due.
DUE_WITHIN_DAYS = 1.0
# Recent-error window and sample: bounded evidence, never the whole history.
RECENT_ERROR_WINDOW_DAYS = 14.0
RECENT_ERROR_SAMPLE = 5
# Mean ``1 - score`` at or above this counts as recent error severity.
RECENT_ERROR_SEVERITY_FLOOR = 0.4
MAX_COVERAGE_OBJECTIVES = 10
# Safety bound for the set-based weak-prerequisite lookup over one page.
MAX_WEAK_PREREQUISITE_ROWS = 500
MAX_CURSOR_LENGTH = 200

# Retrievability band floors for the client-facing band. These are display
# bands, not scheduling thresholds; the policy keeps its own numbers.
BAND_FRESH_FLOOR = 0.8
BAND_SETTLING_FLOOR = 0.5
BAND_FADING_FLOOR = 0.25

_PAGE_QUERY = text(
    """
    SELECT
        s.concept_id,
        s.active_concept_version_id AS concept_version_id,
        c.stable_code,
        s.next_review_at,
        s.stability_days,
        s.evidence_confidence,
        s.first_exposed_at,
        s.last_reviewed_at,
        s.exposure_count,
        s.eligible_review_count,
        s.lapse_count,
        COALESCE(err.severity, 0.0) AS recent_error_severity,
        COALESCE(err.event_count, 0) AS recent_error_count,
        COALESCE(dep.dependent_count, 0) AS prerequisite_impact,
        COALESCE(cov.objective_ids, ARRAY[]::uuid[]) AS coverage_objective_ids
    FROM learner_concept_states s
    JOIN concepts c ON c.id = s.concept_id
    LEFT JOIN LATERAL (
        SELECT avg(1.0 - e.score) AS severity, count(*) AS event_count
        FROM (
            SELECT score
            FROM memory_events
            WHERE user_id = s.user_id
              AND concept_id = s.concept_id
              AND is_eligible
              AND score IS NOT NULL
              AND observed_at >= CAST(:error_window_start AS timestamptz)
              AND observed_at <= CAST(:as_of AS timestamptz)
            ORDER BY observed_at DESC
            LIMIT :error_sample
        ) e
    ) err ON true
    LEFT JOIN LATERAL (
        SELECT count(*) AS dependent_count
        FROM concept_edges e
        WHERE e.from_concept_version_id = s.active_concept_version_id
          AND e.edge_type = 'prerequisite_of'
          AND e.status = 'approved'
          AND e.valid_from <= CAST(:as_of AS timestamptz)
          AND (e.valid_to IS NULL OR e.valid_to > CAST(:as_of AS timestamptz))
    ) dep ON true
    LEFT JOIN LATERAL (
        SELECT array_agg(
            m.learning_objective_id
            ORDER BY m.coverage_weight DESC, m.learning_objective_id
        ) AS objective_ids
        FROM (
            SELECT learning_objective_id, coverage_weight
            FROM concept_objective_maps
            WHERE concept_version_id = s.active_concept_version_id
            ORDER BY coverage_weight DESC, learning_objective_id
            LIMIT :max_objectives
        ) m
    ) cov ON true
    WHERE s.user_id = CAST(:user_id AS uuid)
      AND c.subject_id = CAST(:subject_id AS uuid)
      AND c.status = 'approved'
      AND s.next_review_at <= CAST(:horizon_end AS timestamptz)
      AND (
          CAST(:cursor_at AS timestamptz) IS NULL
          OR (s.next_review_at, s.concept_id) > (
              CAST(:cursor_at AS timestamptz), CAST(:cursor_concept AS uuid)
          )
      )
    ORDER BY s.next_review_at, s.concept_id
    LIMIT :row_limit
    """
)

_WEAK_PREREQUISITE_QUERY = text(
    """
    WITH RECURSIVE roots AS (
        SELECT unnest(CAST(:concept_version_ids AS uuid[])) AS concept_version_id
    ),
    prereqs AS (
        SELECT
            r.concept_version_id AS root_id,
            e.from_concept_version_id,
            1 AS depth
        FROM roots r
        JOIN concept_edges e ON e.to_concept_version_id = r.concept_version_id
        WHERE e.edge_type = 'prerequisite_of'
          AND e.status = 'approved'
          AND e.valid_from <= CAST(:as_of AS timestamptz)
          AND (e.valid_to IS NULL OR e.valid_to > CAST(:as_of AS timestamptz))
        UNION ALL
        SELECT p.root_id, e.from_concept_version_id, p.depth + 1
        FROM prereqs p
        JOIN concept_edges e ON e.to_concept_version_id = p.from_concept_version_id
        WHERE e.edge_type = 'prerequisite_of'
          AND e.status = 'approved'
          AND e.valid_from <= CAST(:as_of AS timestamptz)
          AND (e.valid_to IS NULL OR e.valid_to > CAST(:as_of AS timestamptz))
          AND p.depth < :max_depth
    )
    SELECT DISTINCT
        p.root_id,
        c.id AS concept_id,
        s.stability_days,
        s.last_reviewed_at,
        s.first_exposed_at
    FROM prereqs p
    JOIN concept_versions cv ON cv.id = p.from_concept_version_id
    JOIN concepts c ON c.id = cv.concept_id
    JOIN learner_concept_states s
      ON s.user_id = CAST(:user_id AS uuid)
     AND s.concept_id = c.id
    ORDER BY p.root_id, c.id
    LIMIT :row_limit
    """
)


@dataclass(frozen=True)
class DueConceptCandidate:
    """One concept's due-selection inputs for the mission planner.

    Carries no ranking score: T13 combines these inputs with versioned
    weights and its own diversity, trust and workload constraints.
    """

    concept_id: UUID
    concept_version_id: UUID
    stable_code: str
    next_review_at: datetime
    urgency: str
    overdue_days: float
    retrievability: float
    retrievability_band: str
    forgetting_risk: float
    evidence_confidence: float
    recent_error_severity: float
    recent_error_count: int
    lapse_count: int
    exposure_count: int
    eligible_review_count: int
    is_new_concept: bool
    is_comeback: bool
    prerequisite_impact: int
    weak_prerequisite_concept_ids: tuple[UUID, ...]
    coverage_objective_ids: tuple[UUID, ...]
    selection_reason: str

    def __post_init__(self) -> None:
        if self.urgency not in URGENCY_BANDS:
            raise ValueError(f"urgency outside the allowlist: {self.urgency!r}")
        if self.selection_reason not in SELECTION_REASON_CODES:
            raise ValueError(f"selection reason outside the allowlist: {self.selection_reason!r}")
        if not 0.0 <= self.retrievability <= 1.0:
            raise ValueError("retrievability must be within [0, 1]")
        if not 0.0 <= self.forgetting_risk <= 1.0:
            raise ValueError("forgetting risk must be within [0, 1]")
        if not 0.0 <= self.recent_error_severity <= 1.0:
            raise ValueError("recent error severity must be within [0, 1]")
        if self.overdue_days < 0.0:
            raise ValueError("overdue days cannot be negative")


@dataclass(frozen=True)
class DueSelectionPage:
    """One bounded page of due-selection inputs."""

    subject_id: UUID
    as_of: datetime
    horizon_days: float
    candidates: tuple[DueConceptCandidate, ...]
    next_cursor: str | None
    selection_input_version: str = SELECTION_INPUT_VERSION
    engine_version: str = DEFAULT_ENGINE_CONFIG.engine_version
    policy_version: str = DEFAULT_ENGINE_CONFIG.policy_version


def list_due_candidates(
    connection: Connection,
    *,
    user_id: UUID | str,
    subject_id: UUID | str,
    as_of: datetime,
    horizon_days: float = DEFAULT_HORIZON_DAYS,
    limit: int = DEFAULT_SELECTION_LIMIT,
    cursor: str | None = None,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> DueSelectionPage:
    """Return one bounded page of due/near-due selection inputs.

    ``horizon_days`` bounds how far ahead near-due concepts are included;
    nothing beyond the horizon leaves the backend. ``cursor`` is the opaque
    value from a previous page's ``next_cursor``.
    """
    _require_aware(as_of, "as_of")
    if not 0.0 < horizon_days <= MAX_HORIZON_DAYS:
        raise ValueError(f"horizon_days must be within (0, {MAX_HORIZON_DAYS}]")
    if not 1 <= limit <= MAX_SELECTION_LIMIT:
        raise ValueError(f"limit must be within [1, {MAX_SELECTION_LIMIT}]")
    cursor_at, cursor_concept = decode_cursor(cursor) if cursor is not None else (None, None)

    rows = (
        connection.execute(
            _PAGE_QUERY,
            {
                "user_id": str(user_id),
                "subject_id": str(subject_id),
                "as_of": as_of,
                "horizon_end": as_of + timedelta(days=horizon_days),
                "error_window_start": as_of - timedelta(days=RECENT_ERROR_WINDOW_DAYS),
                "error_sample": RECENT_ERROR_SAMPLE,
                "max_objectives": MAX_COVERAGE_OBJECTIVES,
                "cursor_at": cursor_at,
                "cursor_concept": None if cursor_concept is None else str(cursor_concept),
                # One extra row distinguishes "page full" from "more pages".
                "row_limit": limit + 1,
            },
        )
        .mappings()
        .all()
    )

    has_more = len(rows) > limit
    page_rows = rows[:limit]
    weak_by_root = _weak_prerequisites(
        connection,
        user_id=user_id,
        as_of=as_of,
        concept_version_ids=[row["concept_version_id"] for row in page_rows],
        config=config,
    )

    candidates = tuple(
        _candidate(row, as_of=as_of, weak_by_root=weak_by_root, config=config) for row in page_rows
    )
    next_cursor = (
        encode_cursor(candidates[-1].next_review_at, candidates[-1].concept_id)
        if has_more and candidates
        else None
    )
    return DueSelectionPage(
        subject_id=UUID(str(subject_id)),
        as_of=as_of,
        horizon_days=horizon_days,
        candidates=candidates,
        next_cursor=next_cursor,
        engine_version=config.engine_version,
        policy_version=config.policy_version,
    )


def encode_cursor(next_review_at: datetime, concept_id: UUID) -> str:
    """Encode a keyset position; the value is opaque to clients."""
    _require_aware(next_review_at, "next_review_at")
    micros = int(next_review_at.timestamp() * 1_000_000)
    raw = f"{micros}:{concept_id}".encode()
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def decode_cursor(cursor: str) -> tuple[datetime, UUID]:
    """Decode a keyset cursor or raise ``ValueError`` for malformed input."""
    if not isinstance(cursor, str) or not cursor or len(cursor) > MAX_CURSOR_LENGTH:
        raise ValueError("invalid selection cursor")
    padded = cursor + "=" * (-len(cursor) % 4)
    try:
        raw = base64.urlsafe_b64decode(padded.encode()).decode()
        micros_text, concept_text = raw.split(":", 1)
        micros = int(micros_text)
        concept_id = UUID(concept_text)
    except (binascii.Error, UnicodeDecodeError, ValueError) as exc:
        raise ValueError("invalid selection cursor") from exc
    return (
        datetime.fromtimestamp(micros // 1_000_000, tz=UTC)
        + timedelta(microseconds=micros % 1_000_000)
    ), concept_id


def retrievability_band(retrievability: float) -> str:
    """Map a retrievability estimate onto the client-facing band."""
    if retrievability >= BAND_FRESH_FLOOR:
        return RETRIEVABILITY_BAND_FRESH
    if retrievability >= BAND_SETTLING_FLOOR:
        return RETRIEVABILITY_BAND_SETTLING
    if retrievability >= BAND_FADING_FLOOR:
        return RETRIEVABILITY_BAND_FADING
    return RETRIEVABILITY_BAND_CRITICAL


# ----------------------------------------------------------------------
# internals
# ----------------------------------------------------------------------


def _candidate(
    row: Mapping[str, Any],
    *,
    as_of: datetime,
    weak_by_root: dict[UUID, tuple[UUID, ...]],
    config: EngineConfig,
) -> DueConceptCandidate:
    next_review_at = _aware(row["next_review_at"])
    anchor = row["last_reviewed_at"] or row["first_exposed_at"]
    retrievability = fsrs.retrievability(
        float(row["stability_days"]), _aware(anchor), as_of, config=config
    )
    overdue_days = max((as_of - next_review_at).total_seconds() / 86400.0, 0.0)
    urgency = _urgency(next_review_at, as_of)
    recent_error_severity = float(row["recent_error_severity"])
    weak_ids = weak_by_root.get(UUID(str(row["concept_version_id"])), ())
    eligible_review_count = int(row["eligible_review_count"])

    return DueConceptCandidate(
        concept_id=UUID(str(row["concept_id"])),
        concept_version_id=UUID(str(row["concept_version_id"])),
        stable_code=str(row["stable_code"]),
        next_review_at=next_review_at,
        urgency=urgency,
        overdue_days=overdue_days,
        retrievability=retrievability,
        retrievability_band=retrievability_band(retrievability),
        forgetting_risk=1.0 - retrievability,
        evidence_confidence=float(row["evidence_confidence"]),
        recent_error_severity=recent_error_severity,
        recent_error_count=int(row["recent_error_count"]),
        lapse_count=int(row["lapse_count"]),
        exposure_count=int(row["exposure_count"]),
        eligible_review_count=eligible_review_count,
        is_new_concept=eligible_review_count == 0,
        is_comeback=is_comeback_elapsed(_aware(anchor), as_of, config=config),
        prerequisite_impact=int(row["prerequisite_impact"]),
        weak_prerequisite_concept_ids=weak_ids,
        coverage_objective_ids=tuple(UUID(str(v)) for v in row["coverage_objective_ids"]),
        selection_reason=_selection_reason(
            is_new=eligible_review_count == 0,
            recent_error_severity=recent_error_severity,
            weak_prerequisite_ids=weak_ids,
            urgency=urgency,
        ),
    )


def _selection_reason(
    *,
    is_new: bool,
    recent_error_severity: float,
    weak_prerequisite_ids: tuple[UUID, ...],
    urgency: str,
) -> str:
    """Pick the governing selection reason by documented precedence.

    Precedence: weak-prerequisite failure (needs recent failure evidence),
    recent error repair, overdue, new concept, then retention protection.
    """
    has_recent_errors = recent_error_severity >= RECENT_ERROR_SEVERITY_FLOOR
    if has_recent_errors and weak_prerequisite_ids:
        return SELECTION_REASON_WEAK_PREREQUISITE
    if has_recent_errors:
        return SELECTION_REASON_ERROR_REPAIR
    if urgency == URGENCY_OVERDUE:
        return SELECTION_REASON_OVERDUE
    if is_new:
        return SELECTION_REASON_NEW_CONCEPT
    return SELECTION_REASON_RETENTION


def _urgency(next_review_at: datetime, as_of: datetime) -> str:
    if next_review_at < as_of:
        return URGENCY_OVERDUE
    if next_review_at <= as_of + timedelta(days=DUE_WITHIN_DAYS):
        return URGENCY_DUE
    return URGENCY_NEAR_DUE


def _weak_prerequisites(
    connection: Connection,
    *,
    user_id: UUID | str,
    as_of: datetime,
    concept_version_ids: list[UUID],
    config: EngineConfig,
) -> dict[UUID, tuple[UUID, ...]]:
    """One bounded set query for the page's weak prerequisites."""
    if not concept_version_ids:
        return {}
    if not 1 <= DEFAULT_PREREQ_DEPTH <= MAX_PREREQ_DEPTH:  # pragma: no cover - constant guard
        raise ValueError("prerequisite depth outside the curriculum bound")
    rows = (
        connection.execute(
            _WEAK_PREREQUISITE_QUERY,
            {
                "user_id": str(user_id),
                "as_of": as_of,
                "concept_version_ids": [str(value) for value in concept_version_ids],
                "max_depth": DEFAULT_PREREQ_DEPTH,
                "row_limit": MAX_WEAK_PREREQUISITE_ROWS,
            },
        )
        .mappings()
        .all()
    )

    weak: dict[UUID, list[UUID]] = {}
    for row in rows:
        anchor = row["last_reviewed_at"] or row["first_exposed_at"]
        if not is_weak_prerequisite_state(
            float(row["stability_days"]), _aware(anchor), as_of, config=config
        ):
            continue
        weak.setdefault(UUID(str(row["root_id"])), []).append(UUID(str(row["concept_id"])))
    return {root: tuple(sorted(values)) for root, values in weak.items()}


def _require_aware(value: datetime, name: str) -> None:
    if value.tzinfo is None:
        raise ValueError(f"{name} must be timezone-aware")


def _aware(value: datetime) -> datetime:
    return value.astimezone(UTC)
