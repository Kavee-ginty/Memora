"""Transactional persistence for Daily Mission planning and lifecycle."""

from __future__ import annotations

import hashlib
import json
import math
from collections.abc import Iterator
from contextlib import contextmanager
from datetime import UTC, date, datetime, time, timedelta
from typing import Any
from uuid import UUID, uuid4
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from sqlalchemy import Connection, Engine, text

from memora.api.errors import ApiError
from memora.api.security import AuthContext
from memora.modules.memory.constants import (
    SELECTION_REASON_ERROR_REPAIR,
    SELECTION_REASON_NEW_CONCEPT,
    SELECTION_REASON_OVERDUE,
    SELECTION_REASON_RETENTION,
    SELECTION_REASON_WEAK_PREREQUISITE,
)
from memora.modules.memory.selection import list_due_candidates
from memora.modules.missions.constants import (
    ATTEMPT_GRADED_EVENT,
    CANDIDATE_SNAPSHOT_VERSION,
    MAX_REPAIR_ITEMS,
    MAX_TOTAL_ITEMS,
    MISSION_COMPLETED_EVENT,
    MISSION_POLICY_VERSION,
    MISSION_RANKING_VERSION,
    OUTBOX_SCHEMA_VERSION,
    QUESTION_ESTIMATED_SECONDS,
    REPAIR_CONFIDENCE_FLOOR,
    REPETITION_LOOKBACK_DAYS,
)
from memora.modules.missions.ranking import (
    PlannedQuestion,
    RankedCandidate,
    apply_workload_cap,
    rank_candidates,
)
from memora.modules.questions.grading import GradeOutcome, grade_answer
from memora.modules.questions.models import AnswerPayload, QuestionSnapshot
from memora.modules.questions.repository import QuestionReportRepository
from memora.modules.questions.validation import QuestionValidationError

_DUE_REASON_COPY = {
    SELECTION_REASON_OVERDUE: "This memory is overdue and worth protecting now.",
    SELECTION_REASON_RETENTION: "This memory is approaching its review window.",
    SELECTION_REASON_ERROR_REPAIR: "Recent evidence suggests this memory needs repair.",
    SELECTION_REASON_WEAK_PREREQUISITE: "A supporting memory needs attention first.",
    SELECTION_REASON_NEW_CONCEPT: "This is the first retrieval for a recently learned concept.",
}


class MissionRepository:
    def __init__(self, engine: Engine) -> None:
        self.engine = engine

    @contextmanager
    def _connection(self, auth: AuthContext) -> Iterator[tuple[Connection, UUID]]:
        with self.engine.begin() as connection:
            connection.execute(text("SET LOCAL ROLE memora_api"))
            user_id = connection.scalar(
                text("SELECT memora_resolve_user_id(:issuer, :subject)"),
                {"issuer": auth.issuer, "subject": auth.subject},
            )
            if user_id is None:
                raise ApiError(401, "token_invalid", "Your account could not be resolved.")
            connection.execute(
                text("SELECT set_config('memora.user_id', :user_id, true)"),
                {"user_id": str(user_id)},
            )
            yield connection, UUID(str(user_id))

    def today(self, auth: AuthContext, *, now: datetime) -> dict[str, Any] | None:
        with self._connection(auth) as (connection, user_id):
            timezone_name = self._timezone(connection, user_id)
            local_date = now.astimezone(ZoneInfo(timezone_name)).date()
            self._expire_missions(connection, user_id, now)
            existing = self._current_mission(connection, user_id, local_date)
            if existing is not None:
                return existing
            return self._plan_mission(
                connection,
                user_id=user_id,
                timezone_name=timezone_name,
                local_date=local_date,
                now=now,
            )

    def get_mission(self, auth: AuthContext, mission_id: UUID) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            return self._mission(connection, user_id, mission_id)

    def manifest(self, auth: AuthContext, mission_id: UUID) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            mission = self._mission(connection, user_id, mission_id)
            return {"mission": mission, "items": self._manifest_items(connection, mission_id)}

    def start(
        self,
        auth: AuthContext,
        mission_id: UUID,
        *,
        idempotency_key: str,
        request_hash: str,
        now: datetime,
    ) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection, user_id, "startMission", idempotency_key, request_hash
            )
            mission = self._lock_mission(connection, user_id, mission_id)
            if mission["status"] == "completed":
                raise self._state_changed("This mission is already complete.")
            if mission["status"] not in {"planned", "started", "paused"}:
                raise self._state_changed("This mission can no longer be started.")
            if mission["expires_at"] <= now:
                self._set_expired(connection, mission_id)
                raise self._state_changed("This mission has expired.")
            if replay is None:
                connection.execute(
                    text(
                        """
                        UPDATE missions
                        SET status = 'started', started_at = COALESCE(started_at, :now),
                            updated_at = :now, row_version = row_version + 1
                        WHERE id = :mission_id AND user_id = :user_id
                        """
                    ),
                    {"mission_id": mission_id, "user_id": user_id, "now": now},
                )
                self._present_next(connection, mission_id, now)
                self._complete_idempotency(
                    connection, user_id, "startMission", idempotency_key, str(mission_id)
                )
            return {
                "mission": self._mission(connection, user_id, mission_id),
                "items": self._manifest_items(connection, mission_id),
            }

    def get_item(self, auth: AuthContext, mission_id: UUID, item_id: UUID) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            mission = self._mission(connection, user_id, mission_id)
            item = self._item(connection, user_id, mission_id, item_id)
            if mission["status"] == "planned":
                raise self._state_changed("Start this mission before opening a question.")
            current = self._current_item_id(connection, mission_id)
            if item["status"] in {"pending", "presented"} and current != item_id:
                raise self._state_changed("Refresh the mission to continue from its current item.")
            return self._item_payload(connection, mission, item)

    def submit_attempt(
        self,
        auth: AuthContext,
        mission_id: UUID,
        item_id: UUID,
        *,
        question_version_id: UUID,
        answer: AnswerPayload,
        client_operation_id: UUID,
        request_hash: str,
        answered_at: datetime,
        offline_submission: bool,
        elapsed_ms: int | None,
        app_version: str,
        correlation_id: UUID,
        now: datetime,
    ) -> dict[str, Any]:
        del answered_at  # Client time is evidence only and cannot decide mission state.
        with self._connection(auth) as (connection, user_id):
            mission = self._lock_mission(connection, user_id, mission_id)
            existing = self._attempt_by_operation(connection, user_id, client_operation_id)
            if existing is not None:
                if existing["request_hash"] != request_hash:
                    raise ApiError(
                        409,
                        "idempotency_key_reused",
                        "Use a new client operation ID for this answer.",
                        "correct_input",
                    )
                if existing["mission_item_id"] != item_id:
                    raise ApiError(
                        409,
                        "idempotency_key_reused",
                        "Use a new client operation ID for this answer.",
                        "correct_input",
                    )
                return self._attempt_result(connection, mission_id, item_id, existing["id"])

            if mission["status"] != "started":
                raise self._state_changed("Start or resume this mission before answering.")
            item = self._lock_item(connection, user_id, mission_id, item_id)
            if self._current_item_id(connection, mission_id) != item_id or item["status"] not in {
                "pending",
                "presented",
            }:
                raise self._state_changed("Refresh the mission to continue from its current item.")
            if UUID(str(item["question_version_id"])) != UUID(str(question_version_id)):
                raise self._state_changed("The pinned question changed. Refresh the mission.")

            snapshot = QuestionReportRepository.load_snapshot_from_connection(
                connection, question_version_id
            )
            try:
                outcome = grade_answer(snapshot, answer)
            except QuestionValidationError as exc:
                raise ApiError(422, "validation_failed", exc.message, "correct_input") from exc
            if outcome.classification == "ungradable" and outcome.feedback_code == "answer_invalid":
                raise ApiError(
                    422,
                    "validation_failed",
                    "The answer does not match this question.",
                    "correct_input",
                )

            attempt_id = uuid4()
            connection.execute(
                text(
                    """
                    INSERT INTO attempts(
                        id, user_id, mission_item_id, attempt_no, client_operation_id,
                        answer_payload, submitted_at, elapsed_ms, app_version,
                        is_offline_submission, request_hash
                    ) VALUES (
                        :id, :user_id, :item_id, 1, :operation_id,
                        CAST(:answer AS jsonb), :submitted_at, :elapsed_ms, :app_version,
                        :offline_submission, :request_hash
                    )
                    """
                ),
                {
                    "id": attempt_id,
                    "user_id": user_id,
                    "item_id": item_id,
                    "operation_id": client_operation_id,
                    "answer": self._json(answer.model_dump(mode="json")),
                    "submitted_at": now,
                    "elapsed_ms": elapsed_ms,
                    "app_version": app_version,
                    "offline_submission": offline_submission,
                    "request_hash": request_hash,
                },
            )
            self._insert_grade(connection, attempt_id, snapshot, outcome, now)
            connection.execute(
                text(
                    """
                    UPDATE mission_items
                    SET status = 'answered', updated_at = :now, row_version = row_version + 1
                    WHERE id = :item_id AND user_id = :user_id
                    """
                ),
                {"item_id": item_id, "user_id": user_id, "now": now},
            )
            self._insert_attempt_outbox(
                connection,
                user_id=user_id,
                attempt_id=attempt_id,
                snapshot=snapshot,
                outcome=outcome,
                mission_type=str(item["mission_type"]),
                correlation_id=correlation_id,
            )
            self._maybe_insert_repair(
                connection,
                user_id=user_id,
                mission=mission,
                item=item,
                snapshot=snapshot,
                outcome=outcome,
                now=now,
            )
            self._present_next(connection, mission_id, now)
            return self._attempt_result(connection, mission_id, item_id, attempt_id)

    def skip(
        self,
        auth: AuthContext,
        mission_id: UUID,
        item_id: UUID,
        *,
        idempotency_key: str,
        request_hash: str,
        now: datetime,
    ) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection, user_id, "skipMissionItem", idempotency_key, request_hash
            )
            mission = self._lock_mission(connection, user_id, mission_id)
            item = self._lock_item(connection, user_id, mission_id, item_id)
            if replay is None:
                if mission["status"] != "started":
                    raise self._state_changed("Start or resume this mission before skipping.")
                if self._current_item_id(connection, mission_id) != item_id or item[
                    "status"
                ] not in {"pending", "presented"}:
                    raise self._state_changed(
                        "Refresh the mission to continue from its current item."
                    )
                connection.execute(
                    text(
                        """
                        UPDATE mission_items
                        SET status = 'skipped', updated_at = :now, row_version = row_version + 1
                        WHERE id = :item_id AND user_id = :user_id
                        """
                    ),
                    {"item_id": item_id, "user_id": user_id, "now": now},
                )
                self._present_next(connection, mission_id, now)
                self._complete_idempotency(
                    connection, user_id, "skipMissionItem", idempotency_key, str(item_id)
                )
            next_item = self._current_item_id(connection, mission_id)
            return {
                "attempt_id": None,
                "grading_status": "skipped",
                "outcome": "skipped",
                "feedback": "Question skipped. No correctness was recorded.",
                "explanation": None,
                "explanation_available": False,
                "repair_action": "none",
                "influence_limited": True,
                "next_item_id": next_item,
                "can_complete": next_item is None,
            }

    def pause(
        self,
        auth: AuthContext,
        mission_id: UUID,
        *,
        idempotency_key: str,
        request_hash: str,
        now: datetime,
    ) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection, user_id, "pauseMission", idempotency_key, request_hash
            )
            mission = self._lock_mission(connection, user_id, mission_id)
            if replay is None:
                if mission["status"] not in {"started", "paused"}:
                    raise self._state_changed("Only an active mission can be paused.")
                if mission["status"] == "started":
                    connection.execute(
                        text(
                            """
                            UPDATE missions
                            SET status = 'paused', updated_at = :now,
                                row_version = row_version + 1
                            WHERE id = :mission_id AND user_id = :user_id
                            """
                        ),
                        {"mission_id": mission_id, "user_id": user_id, "now": now},
                    )
                self._complete_idempotency(
                    connection, user_id, "pauseMission", idempotency_key, str(mission_id)
                )
            return self._mission(connection, user_id, mission_id)

    def complete(
        self,
        auth: AuthContext,
        mission_id: UUID,
        *,
        idempotency_key: str,
        request_hash: str,
        correlation_id: UUID,
        now: datetime,
    ) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection, user_id, "completeMission", idempotency_key, request_hash
            )
            mission = self._lock_mission(connection, user_id, mission_id)
            if mission["status"] == "completed":
                result = mission["completion_summary"]
                if replay is None:
                    self._complete_idempotency(
                        connection, user_id, "completeMission", idempotency_key, str(mission_id)
                    )
                return dict(result)
            if mission["status"] not in {"started", "paused"}:
                raise self._state_changed("This mission is not ready to complete.")
            remaining = connection.scalar(
                text(
                    """
                    SELECT count(*) FROM mission_items
                    WHERE mission_id = :mission_id
                      AND status NOT IN ('answered', 'skipped', 'cancelled')
                    """
                ),
                {"mission_id": mission_id},
            )
            if remaining:
                raise self._state_changed("Finish or skip every mission item before completing.")
            if replay is not None:
                refreshed = self._mission(connection, user_id, mission_id)
                return dict(refreshed["completion_summary"])

            counts = (
                connection.execute(
                    text(
                        """
                        SELECT
                          count(*) FILTER (
                            WHERE mi.status = 'answered' AND mi.mission_type <> 'repair'
                              AND gr.classification = 'correct'
                          ) AS protected_count,
                          count(*) FILTER (
                            WHERE mi.status = 'answered' AND mi.mission_type = 'repair'
                              AND gr.classification IN ('correct', 'partial')
                          ) AS repaired_count,
                          count(*) FILTER (WHERE mi.status = 'skipped') AS skipped_count
                        FROM mission_items mi
                        LEFT JOIN attempts a ON a.mission_item_id = mi.id
                        LEFT JOIN grading_results gr
                          ON gr.attempt_id = a.id AND gr.is_authoritative
                        WHERE mi.mission_id = :mission_id
                        """
                    ),
                    {"mission_id": mission_id},
                )
                .mappings()
                .one()
            )
            result = {
                "mission_id": str(mission_id),
                "status": "completed",
                "protected_count": int(counts["protected_count"] or 0),
                "repaired_count": int(counts["repaired_count"] or 0),
                "skipped_count": int(counts["skipped_count"] or 0),
                "completed_at": now.isoformat(),
                "engagement_status": "pending",
                "reward_grants": [],
                "next_suggested_action": "home",
            }
            connection.execute(
                text(
                    """
                    UPDATE missions
                    SET status = 'completed', completed_at = :now,
                        completion_summary = CAST(:summary AS jsonb), updated_at = :now,
                        row_version = row_version + 1
                    WHERE id = :mission_id AND user_id = :user_id
                    """
                ),
                {
                    "mission_id": mission_id,
                    "user_id": user_id,
                    "now": now,
                    "summary": self._json(result),
                },
            )
            connection.execute(
                text(
                    """
                    INSERT INTO outbox_events(
                        domain_event_key, aggregate_type, aggregate_id, event_type,
                        event_version, payload, correlation_id, publication_status
                    ) VALUES (
                        :key, 'mission', :mission_id, :event_type, 1,
                        CAST(:payload AS jsonb), :correlation_id, 'pending'
                    )
                    """
                ),
                {
                    "key": f"{MISSION_COMPLETED_EVENT}:{mission_id}",
                    "mission_id": mission_id,
                    "event_type": MISSION_COMPLETED_EVENT,
                    "payload": self._json(
                        {
                            "schema_version": OUTBOX_SCHEMA_VERSION,
                            "user_id": str(user_id),
                            **result,
                        }
                    ),
                    "correlation_id": correlation_id,
                },
            )
            self._complete_idempotency(
                connection, user_id, "completeMission", idempotency_key, str(mission_id)
            )
            return result

    def results(self, auth: AuthContext, mission_id: UUID) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            mission = self._mission(connection, user_id, mission_id)
            if mission["status"] != "completed" or mission["completion_summary"] is None:
                raise self._state_changed("Mission results are available after completion.")
            return dict(mission["completion_summary"])

    # Planning ---------------------------------------------------------

    def _plan_mission(
        self,
        connection: Connection,
        *,
        user_id: UUID,
        timezone_name: str,
        local_date: date,
        now: datetime,
    ) -> dict[str, Any] | None:
        subject_id = connection.scalar(
            text(
                """
                SELECT c.subject_id
                FROM learner_concept_states s
                JOIN concepts c ON c.id = s.concept_id
                WHERE s.user_id = :user_id AND c.status = 'approved'
                  AND s.next_review_at <= :horizon
                GROUP BY c.subject_id
                ORDER BY min(s.next_review_at), c.subject_id
                LIMIT 1
                """
            ),
            {"user_id": user_id, "horizon": now + timedelta(days=3)},
        )
        if subject_id is None:
            return None
        page = list_due_candidates(
            connection,
            user_id=user_id,
            subject_id=subject_id,
            as_of=now,
            limit=50,
        )
        ranked = rank_candidates(page.candidates)
        questions: list[PlannedQuestion] = []
        used_questions: list[UUID] = []
        for candidate in ranked:
            target_id, target_version = self._target_concept(connection, user_id, candidate)
            question = self._eligible_question(
                connection,
                user_id=user_id,
                subject_id=UUID(str(subject_id)),
                concept_version_id=target_version,
                excluded=used_questions,
                now=now,
            )
            if question is None:
                continue
            question_id = UUID(str(question["id"]))
            used_questions.append(question_id)
            questions.append(
                PlannedQuestion(
                    ranked=candidate,
                    target_concept_id=target_id,
                    target_concept_version_id=target_version,
                    question_version_id=question_id,
                    question_type=str(question["question_type"]),
                    estimated_seconds=QUESTION_ESTIMATED_SECONDS[str(question["question_type"])],
                    source_class=str(question["source_class"]),
                )
            )
        selected = apply_workload_cap(questions)
        if not selected:
            if ranked:
                raise ApiError(
                    503,
                    "temporarily_unavailable",
                    "A safe question is not available for the due memories yet.",
                    "retry",
                    retryable=True,
                    retry_after_seconds=300,
                )
            return None

        snapshot = [self._candidate_snapshot(item) for item in selected]
        snapshot_hash = hashlib.sha256(self._json(snapshot).encode()).hexdigest()
        mission_id = uuid4()
        estimated_seconds = sum(item.estimated_seconds for item in selected)
        estimated_minutes = max(1, math.ceil(estimated_seconds / 60))
        local_zone = ZoneInfo(timezone_name)
        expires_at = datetime.combine(
            local_date + timedelta(days=1), time.min, local_zone
        ).astimezone(UTC)
        inserted = connection.scalar(
            text(
                """
                INSERT INTO missions(
                    id, user_id, subject_id, mission_date, mission_timezone,
                    sequence_no, status, engine_version, candidate_snapshot_hash,
                    estimated_minutes, planned_item_count, expires_at
                ) VALUES (
                    :id, :user_id, :subject_id, :mission_date, :timezone,
                    1, 'planned', :engine_version, :snapshot_hash,
                    :estimated_minutes, :item_count, :expires_at
                )
                ON CONFLICT (user_id, subject_id, mission_date, sequence_no) DO NOTHING
                RETURNING id
                """
            ),
            {
                "id": mission_id,
                "user_id": user_id,
                "subject_id": subject_id,
                "mission_date": local_date,
                "timezone": timezone_name,
                "engine_version": MISSION_POLICY_VERSION,
                "snapshot_hash": snapshot_hash,
                "estimated_minutes": estimated_minutes,
                "item_count": len(selected),
                "expires_at": expires_at,
            },
        )
        if inserted is None:
            existing = self._current_mission(connection, user_id, local_date)
            if existing is None:
                raise ApiError(
                    409,
                    "mission_state_changed",
                    "The mission changed. Refresh and try again.",
                    "refresh_state",
                )
            return existing
        for position, planned in enumerate(selected):
            reason_codes = [planned.ranked.candidate.selection_reason]
            connection.execute(
                text(
                    """
                    INSERT INTO mission_items(
                        mission_id, user_id, position, mission_type, question_version_id,
                        primary_concept_id, selection_reason_codes, priority_snapshot, status
                    ) VALUES (
                        :mission_id, :user_id, :position, :mission_type,
                        :question_version_id, :concept_id, CAST(:reason_codes AS text[]),
                        CAST(:priority AS jsonb), 'pending'
                    )
                    """
                ),
                {
                    "mission_id": mission_id,
                    "user_id": user_id,
                    "position": position,
                    "mission_type": planned.ranked.mission_type,
                    "question_version_id": planned.question_version_id,
                    "concept_id": planned.target_concept_id,
                    "reason_codes": reason_codes,
                    "priority": self._json(self._candidate_snapshot(planned)),
                },
            )
        return self._mission(connection, user_id, mission_id)

    @staticmethod
    def _candidate_snapshot(item: PlannedQuestion) -> dict[str, Any]:
        candidate = item.ranked.candidate
        return {
            "schema_version": CANDIDATE_SNAPSHOT_VERSION,
            "ranking_version": MISSION_RANKING_VERSION,
            "concept_id": str(item.target_concept_id),
            "concept_version_id": str(item.target_concept_version_id),
            "source_concept_id": str(candidate.concept_id),
            "question_version_id": str(item.question_version_id),
            "question_type": item.question_type,
            "source_class": item.source_class,
            "mission_type": item.ranked.mission_type,
            "selection_reason": candidate.selection_reason,
            "priority_score": item.ranked.score,
            "estimated_seconds": item.estimated_seconds,
        }

    @staticmethod
    def _target_concept(
        connection: Connection, user_id: UUID, ranked: RankedCandidate
    ) -> tuple[UUID, UUID]:
        candidate = ranked.candidate
        if ranked.mission_type != "recover" or not candidate.weak_prerequisite_concept_ids:
            return candidate.concept_id, candidate.concept_version_id
        target_id = candidate.weak_prerequisite_concept_ids[0]
        target_version = connection.scalar(
            text(
                """
                SELECT active_concept_version_id
                FROM learner_concept_states
                WHERE user_id = :user_id AND concept_id = :concept_id
                """
            ),
            {"user_id": user_id, "concept_id": target_id},
        )
        if target_version is None:
            return candidate.concept_id, candidate.concept_version_id
        return target_id, UUID(str(target_version))

    @staticmethod
    def _eligible_question(
        connection: Connection,
        *,
        user_id: UUID,
        subject_id: UUID,
        concept_version_id: UUID,
        excluded: list[UUID],
        now: datetime,
    ) -> dict[str, Any] | None:
        row = (
            connection.execute(
                text(
                    """
                    SELECT qv.id, qv.question_type, q.source_class,
                           recent.last_attempt_at
                    FROM question_concept_maps qcm
                    JOIN question_versions qv ON qv.id = qcm.question_version_id
                    JOIN questions q ON q.id = qv.question_id
                    JOIN question_rubrics qr ON qr.question_version_id = qv.id
                    LEFT JOIN LATERAL (
                        SELECT max(a.submitted_at) AS last_attempt_at
                        FROM mission_items mi
                        JOIN attempts a ON a.mission_item_id = mi.id
                        WHERE mi.user_id = :user_id
                          AND mi.question_version_id = qv.id
                          AND a.submitted_at >= :lookback
                    ) recent ON true
                    WHERE qcm.concept_version_id = :concept_version_id
                      AND qcm.mapping_role IN ('primary', 'supporting', 'prerequisite')
                      AND q.subject_id = :subject_id
                      AND q.status = 'approved'
                      AND q.source_class IN ('expert_verified', 'ai_generated')
                      AND qv.validation_status = 'approved'
                      AND qr.status = 'approved'
                      AND qv.question_type IN ('mcq', 'numeric', 'diagram_interpretation')
                      AND NOT (qv.id = ANY(CAST(:excluded AS uuid[])))
                      AND NOT EXISTS (
                        SELECT 1 FROM question_reports report
                        WHERE report.question_version_id = qv.id
                          AND report.status IN ('submitted', 'triaged', 'under_review')
                          AND report.report_type IN (
                            'question_error', 'answer_error', 'grading_dispute'
                          )
                      )
                    ORDER BY
                      (recent.last_attempt_at IS NOT NULL),
                      CASE q.source_class
                        WHEN 'expert_verified' THEN 0
                        WHEN 'teacher_authored' THEN 1
                        ELSE 2
                      END,
                      recent.last_attempt_at NULLS FIRST,
                      qv.id
                    LIMIT 1
                    """
                ),
                {
                    "user_id": user_id,
                    "concept_version_id": concept_version_id,
                    "subject_id": subject_id,
                    "excluded": excluded,
                    "lookback": now - timedelta(days=REPETITION_LOOKBACK_DAYS),
                },
            )
            .mappings()
            .first()
        )
        return dict(row) if row is not None else None

    # Attempt helpers --------------------------------------------------

    @staticmethod
    def _insert_grade(
        connection: Connection,
        attempt_id: UUID,
        snapshot: QuestionSnapshot,
        outcome: GradeOutcome,
        now: datetime,
    ) -> None:
        connection.execute(
            text(
                """
                INSERT INTO grading_results(
                    attempt_id, result_version, grader_type, score, classification,
                    confidence, rubric_id, grader_version, evidence_payload,
                    is_authoritative, graded_at
                ) VALUES (
                    :attempt_id, 1, :grader_type, :score, :classification,
                    :confidence, :rubric_id, :grader_version, CAST(:evidence AS jsonb),
                    true, :graded_at
                )
                """
            ),
            {
                "attempt_id": attempt_id,
                "grader_type": outcome.grader_type,
                "score": outcome.score,
                "classification": outcome.classification,
                "confidence": outcome.confidence,
                "rubric_id": snapshot.rubric.id,
                "grader_version": outcome.grader_version,
                "evidence": MissionRepository._json(outcome.evidence),
                "graded_at": now,
            },
        )

    @staticmethod
    def _insert_attempt_outbox(
        connection: Connection,
        *,
        user_id: UUID,
        attempt_id: UUID,
        snapshot: QuestionSnapshot,
        outcome: GradeOutcome,
        mission_type: str,
        correlation_id: UUID,
    ) -> None:
        concept_grades = []
        for mapping in snapshot.concept_mappings:
            concept_id = connection.scalar(
                text("SELECT concept_id FROM concept_versions WHERE id = :version_id"),
                {"version_id": mapping.concept_version_id},
            )
            if concept_id is None:
                continue
            concept_grades.append(
                {
                    "concept_id": str(concept_id),
                    "concept_version_id": str(mapping.concept_version_id),
                    "score": float(outcome.score),
                    "confidence": float(outcome.confidence),
                    "memory_event_type": "repair" if mission_type == "repair" else "attempt",
                    "is_eligible": outcome.classification != "ungradable",
                    "ineligibility_reason": (
                        "grading_uncertain" if outcome.classification == "ungradable" else None
                    ),
                }
            )
        payload = {
            "schema_version": OUTBOX_SCHEMA_VERSION,
            "user_id": str(user_id),
            "attempt_id": str(attempt_id),
            "concept_grades": concept_grades,
        }
        connection.execute(
            text(
                """
                INSERT INTO outbox_events(
                    domain_event_key, aggregate_type, aggregate_id, event_type,
                    event_version, payload, correlation_id, publication_status
                ) VALUES (
                    :key, 'attempt', :attempt_id, :event_type, 1,
                    CAST(:payload AS jsonb), :correlation_id, 'pending'
                )
                """
            ),
            {
                "key": f"{ATTEMPT_GRADED_EVENT}:{attempt_id}",
                "attempt_id": attempt_id,
                "event_type": ATTEMPT_GRADED_EVENT,
                "payload": MissionRepository._json(payload),
                "correlation_id": correlation_id,
            },
        )

    def _maybe_insert_repair(
        self,
        connection: Connection,
        *,
        user_id: UUID,
        mission: dict[str, Any],
        item: dict[str, Any],
        snapshot: QuestionSnapshot,
        outcome: GradeOutcome,
        now: datetime,
    ) -> None:
        if (
            outcome.classification not in {"incorrect", "misconception"}
            or float(outcome.confidence) < REPAIR_CONFIDENCE_FLOOR
            or int(mission["planned_item_count"]) >= MAX_TOTAL_ITEMS
        ):
            return
        repair_count = connection.scalar(
            text(
                """
                SELECT count(*) FROM mission_items
                WHERE mission_id = :id AND mission_type = 'repair'
                  AND priority_snapshot ? 'repair_for_item_id'
                """
            ),
            {"id": mission["id"]},
        )
        if int(repair_count or 0) >= MAX_REPAIR_ITEMS:
            return
        active_version = connection.scalar(
            text(
                """
                SELECT active_concept_version_id FROM learner_concept_states
                WHERE user_id = :user_id AND concept_id = :concept_id
                """
            ),
            {"user_id": user_id, "concept_id": item["primary_concept_id"]},
        )
        if active_version is None:
            return
        used = [
            UUID(str(value))
            for value in connection.scalars(
                text("SELECT question_version_id FROM mission_items WHERE mission_id = :id"),
                {"id": mission["id"]},
            ).all()
        ]
        question = self._eligible_question(
            connection,
            user_id=user_id,
            subject_id=UUID(str(mission["subject_id"])),
            concept_version_id=UUID(str(active_version)),
            excluded=used,
            now=now,
        )
        if question is None:
            return
        position = int(
            connection.scalar(
                text(
                    """
                    SELECT COALESCE(max(position), -1) + 1
                    FROM mission_items WHERE mission_id=:id
                    """
                ),
                {"id": mission["id"]},
            )
        )
        connection.execute(
            text(
                """
                INSERT INTO mission_items(
                    mission_id, user_id, position, mission_type, question_version_id,
                    primary_concept_id, selection_reason_codes, priority_snapshot, status
                ) VALUES (
                    :mission_id, :user_id, :position, 'repair', :question_version_id,
                    :concept_id, CAST(:reason_codes AS text[]), CAST(:priority AS jsonb),
                    'pending'
                )
                """
            ),
            {
                "mission_id": mission["id"],
                "user_id": user_id,
                "position": position,
                "question_version_id": question["id"],
                "concept_id": item["primary_concept_id"],
                "reason_codes": [SELECTION_REASON_ERROR_REPAIR],
                "priority": self._json(
                    {
                        "schema_version": CANDIDATE_SNAPSHOT_VERSION,
                        "ranking_version": MISSION_RANKING_VERSION,
                        "repair_for_item_id": str(item["id"]),
                        "question_type": question["question_type"],
                        "source_class": question["source_class"],
                        "estimated_seconds": QUESTION_ESTIMATED_SECONDS[
                            str(question["question_type"])
                        ],
                    }
                ),
            },
        )
        connection.execute(
            text(
                """
                UPDATE missions SET planned_item_count = planned_item_count + 1,
                    estimated_minutes = LEAST(
                        7,
                        CEIL((estimated_minutes * 60 + :seconds)::numeric / 60)::smallint
                    ),
                    updated_at = :now, row_version = row_version + 1
                WHERE id = :mission_id
                """
            ),
            {
                "mission_id": mission["id"],
                "seconds": QUESTION_ESTIMATED_SECONDS[str(question["question_type"])],
                "now": now,
            },
        )

    # Read models ------------------------------------------------------

    @staticmethod
    def _mission(connection: Connection, user_id: UUID, mission_id: UUID) -> dict[str, Any]:
        row = (
            connection.execute(
                text(
                    """
                    SELECT m.*,
                      (SELECT count(*) FROM mission_items i
                       WHERE i.mission_id = m.id
                         AND i.status IN ('answered', 'skipped', 'cancelled'))
                        AS completed_item_count,
                      (SELECT id FROM mission_items i
                       WHERE i.mission_id = m.id
                         AND i.status IN ('presented', 'pending')
                       ORDER BY (i.status = 'presented') DESC, i.position LIMIT 1)
                        AS current_item_id
                      ,(SELECT selection_reason_codes FROM mission_items i
                        WHERE i.mission_id = m.id ORDER BY i.position LIMIT 1)
                        AS first_reason_codes
                    FROM missions m
                    WHERE m.id = :mission_id AND m.user_id = :user_id
                    """
                ),
                {"mission_id": mission_id, "user_id": user_id},
            )
            .mappings()
            .first()
        )
        if row is None:
            raise ApiError(404, "resource_not_found", "Mission was not found.")
        result = dict(row)
        reason_codes = list(result.pop("first_reason_codes") or [])
        result["due_reason"] = MissionRepository._due_reason(reason_codes)
        return result

    @staticmethod
    def _lock_mission(connection: Connection, user_id: UUID, mission_id: UUID) -> dict[str, Any]:
        row = (
            connection.execute(
                text("SELECT * FROM missions WHERE id=:id AND user_id=:user_id FOR UPDATE"),
                {"id": mission_id, "user_id": user_id},
            )
            .mappings()
            .first()
        )
        if row is None:
            raise ApiError(404, "resource_not_found", "Mission was not found.")
        return dict(row)

    @staticmethod
    def _item(
        connection: Connection, user_id: UUID, mission_id: UUID, item_id: UUID
    ) -> dict[str, Any]:
        row = (
            connection.execute(
                text(
                    """
                    SELECT * FROM mission_items
                    WHERE id=:item_id AND mission_id=:mission_id AND user_id=:user_id
                    """
                ),
                {"item_id": item_id, "mission_id": mission_id, "user_id": user_id},
            )
            .mappings()
            .first()
        )
        if row is None:
            raise ApiError(404, "resource_not_found", "Mission item was not found.")
        return dict(row)

    @staticmethod
    def _lock_item(
        connection: Connection, user_id: UUID, mission_id: UUID, item_id: UUID
    ) -> dict[str, Any]:
        row = (
            connection.execute(
                text(
                    """
                    SELECT * FROM mission_items
                    WHERE id=:item_id AND mission_id=:mission_id AND user_id=:user_id
                    FOR UPDATE
                    """
                ),
                {"item_id": item_id, "mission_id": mission_id, "user_id": user_id},
            )
            .mappings()
            .first()
        )
        if row is None:
            raise ApiError(404, "resource_not_found", "Mission item was not found.")
        return dict(row)

    def _item_payload(
        self, connection: Connection, mission: dict[str, Any], item: dict[str, Any]
    ) -> dict[str, Any]:
        snapshot = QuestionReportRepository.load_snapshot_from_connection(
            connection, UUID(str(item["question_version_id"]))
        )
        attempt = (
            connection.execute(
                text(
                    """
                    SELECT id FROM attempts WHERE mission_item_id=:item_id
                    ORDER BY attempt_no DESC LIMIT 1
                    """
                ),
                {"item_id": item["id"]},
            )
            .mappings()
            .first()
        )
        result = (
            self._attempt_result(connection, mission["id"], item["id"], attempt["id"])
            if attempt is not None
            else None
        )
        reason_codes = list(item["selection_reason_codes"])
        return {
            "id": item["id"],
            "mission_id": mission["id"],
            "position": item["position"],
            "mission_type": item["mission_type"],
            "status": item["status"],
            "selection_reason_codes": reason_codes,
            "due_reason": self._due_reason(reason_codes),
            "question": snapshot.public_question().model_dump(mode="json"),
            "result": result,
        }

    def _attempt_result(
        self, connection: Connection, mission_id: UUID, item_id: UUID, attempt_id: UUID
    ) -> dict[str, Any]:
        row = (
            connection.execute(
                text(
                    """
                    SELECT gr.classification, gr.confidence, gr.evidence_payload,
                           qv.explanation
                    FROM grading_results gr
                    JOIN attempts a ON a.id = gr.attempt_id
                    JOIN mission_items mi ON mi.id = a.mission_item_id
                    JOIN question_versions qv ON qv.id = mi.question_version_id
                    WHERE gr.attempt_id=:attempt_id AND gr.is_authoritative
                    """
                ),
                {"attempt_id": attempt_id},
            )
            .mappings()
            .one()
        )
        classification = str(row["classification"])
        outcome = {
            "correct": "recalled",
            "partial": "partial",
            "incorrect": "weak",
            "misconception": "weak",
            "ungradable": "uncertain",
            "invalidated": "uncertain",
        }[classification]
        repair_exists = connection.scalar(
            text(
                """
                SELECT EXISTS(
                  SELECT 1 FROM mission_items
                  WHERE mission_id=:mission_id AND mission_type='repair'
                    AND priority_snapshot->>'repair_for_item_id' = :item_id
                )
                """
            ),
            {"mission_id": mission_id, "item_id": str(item_id)},
        )
        next_item = self._current_item_id(connection, mission_id)
        confidence = float(row["confidence"])
        evidence = row["evidence_payload"] or {}
        feedback_code = evidence.get("reason_code") if isinstance(evidence, dict) else None
        feedback = {
            "recalled": "Memory protected.",
            "partial": "Partly recalled. Review the feedback before continuing.",
            "weak": "Weak memory found. Let's repair it now.",
            "uncertain": "This answer could not be graded confidently.",
        }[outcome]
        if feedback_code == "unit_missing":
            feedback = "Include the expected unit, then try again."
        elif feedback_code == "unit_mismatch":
            feedback = "Check the unit and try again."
        if repair_exists:
            repair_action = "repair_inserted"
        elif outcome == "uncertain":
            repair_action = "confirm_or_appeal"
        elif outcome == "weak":
            repair_action = "review_concept"
        else:
            repair_action = "none"
        explanation = str(row["explanation"]).strip()
        return {
            "attempt_id": attempt_id,
            "grading_status": "graded",
            "outcome": outcome,
            "feedback": feedback,
            "explanation": explanation or None,
            "explanation_available": bool(explanation),
            "repair_action": repair_action,
            "influence_limited": confidence < 0.7 or outcome == "uncertain",
            "next_item_id": next_item,
            "can_complete": next_item is None,
        }

    @staticmethod
    def _manifest_items(connection: Connection, mission_id: UUID) -> list[dict[str, Any]]:
        rows = (
            connection.execute(
                text(
                    """
                    SELECT mi.id, mi.position, mi.mission_type, mi.status,
                           qv.question_type, qv.content_payload
                    FROM mission_items mi
                    JOIN question_versions qv ON qv.id = mi.question_version_id
                    WHERE mi.mission_id=:mission_id
                    ORDER BY mi.position
                    """
                ),
                {"mission_id": mission_id},
            )
            .mappings()
            .all()
        )
        result = []
        for row in rows:
            question_type = str(row["question_type"])
            if question_type == "mcq":
                mode = (row["content_payload"] or {}).get("selection_mode", "single")
                public_type = "multiple_choice" if mode == "multiple" else "single_choice"
            elif question_type == "diagram_interpretation":
                public_type = "single_choice"
            else:
                public_type = question_type
            result.append(
                {
                    "id": row["id"],
                    "position": row["position"],
                    "mission_type": row["mission_type"],
                    "question_type": public_type,
                    "status": row["status"],
                }
            )
        return result

    @staticmethod
    def _current_item_id(connection: Connection, mission_id: UUID) -> UUID | None:
        value = connection.scalar(
            text(
                """
                SELECT id FROM mission_items
                WHERE mission_id=:mission_id AND status IN ('presented', 'pending')
                ORDER BY (status='presented') DESC, position LIMIT 1
                """
            ),
            {"mission_id": mission_id},
        )
        return UUID(str(value)) if value is not None else None

    @staticmethod
    def _present_next(connection: Connection, mission_id: UUID, now: datetime) -> None:
        if connection.scalar(
            text(
                """
                SELECT EXISTS(
                  SELECT 1 FROM mission_items
                  WHERE mission_id=:id AND status='presented'
                )
                """
            ),
            {"id": mission_id},
        ):
            return
        connection.execute(
            text(
                """
                UPDATE mission_items SET status='presented', presented_at=:now,
                    updated_at=:now, row_version=row_version+1
                WHERE id = (
                    SELECT id FROM mission_items
                    WHERE mission_id=:mission_id AND status='pending'
                    ORDER BY position LIMIT 1 FOR UPDATE
                )
                """
            ),
            {"mission_id": mission_id, "now": now},
        )

    @staticmethod
    def _current_mission(
        connection: Connection, user_id: UUID, local_date: date
    ) -> dict[str, Any] | None:
        mission_id = connection.scalar(
            text(
                """
                SELECT id FROM missions
                WHERE user_id=:user_id
                  AND (status IN ('started','paused') OR mission_date=:mission_date)
                  AND status <> 'expired' AND status <> 'abandoned'
                ORDER BY
                  CASE status WHEN 'started' THEN 0 WHEN 'paused' THEN 1 ELSE 2 END,
                  mission_date DESC, sequence_no DESC
                LIMIT 1
                """
            ),
            {"user_id": user_id, "mission_date": local_date},
        )
        return (
            MissionRepository._mission(connection, user_id, UUID(str(mission_id)))
            if mission_id is not None
            else None
        )

    @staticmethod
    def _timezone(connection: Connection, user_id: UUID) -> str:
        value = connection.scalar(
            text("SELECT default_timezone FROM users WHERE id=:user_id"),
            {"user_id": user_id},
        )
        timezone_name = str(value or "UTC")
        try:
            ZoneInfo(timezone_name)
        except ZoneInfoNotFoundError:
            timezone_name = "UTC"
        return timezone_name

    @staticmethod
    def _expire_missions(connection: Connection, user_id: UUID, now: datetime) -> None:
        connection.execute(
            text(
                """
                UPDATE missions SET status='expired', updated_at=:now,
                    row_version=row_version+1
                WHERE user_id=:user_id AND status IN ('planned','started','paused')
                  AND expires_at <= :now
                """
            ),
            {"user_id": user_id, "now": now},
        )

    @staticmethod
    def _set_expired(connection: Connection, mission_id: UUID) -> None:
        connection.execute(
            text(
                """
                UPDATE missions SET status='expired', updated_at=now(),
                    row_version=row_version+1 WHERE id=:id
                """
            ),
            {"id": mission_id},
        )

    @staticmethod
    def _attempt_by_operation(
        connection: Connection, user_id: UUID, operation_id: UUID
    ) -> dict[str, Any] | None:
        row = (
            connection.execute(
                text(
                    """
                    SELECT id, mission_item_id, request_hash FROM attempts
                    WHERE user_id=:user_id AND client_operation_id=:operation_id
                    """
                ),
                {"user_id": user_id, "operation_id": operation_id},
            )
            .mappings()
            .first()
        )
        return dict(row) if row is not None else None

    @staticmethod
    def _due_reason(reason_codes: list[str]) -> str:
        for code in reason_codes:
            if code in _DUE_REASON_COPY:
                return _DUE_REASON_COPY[code]
        return "This memory is ready for a useful review."

    @staticmethod
    def _claim_idempotency(
        connection: Connection,
        user_id: UUID,
        operation: str,
        key: str,
        request_hash: str,
    ) -> str | None:
        inserted = connection.scalar(
            text(
                """
                INSERT INTO idempotency_records(
                    user_id, scope, operation, idempotency_key,
                    request_hash, status, expires_at
                ) VALUES (
                    :user_id, :scope, :operation, :key,
                    :request_hash, 'processing', now() + interval '24 hours'
                )
                ON CONFLICT (scope, operation, idempotency_key) DO NOTHING
                RETURNING id
                """
            ),
            {
                "user_id": user_id,
                "scope": str(user_id),
                "operation": operation,
                "key": key,
                "request_hash": request_hash,
            },
        )
        if inserted is not None:
            return None
        record = (
            connection.execute(
                text(
                    """
                    SELECT request_hash, status, response_reference
                    FROM idempotency_records
                    WHERE scope=:scope AND operation=:operation AND idempotency_key=:key
                    FOR UPDATE
                    """
                ),
                {"scope": str(user_id), "operation": operation, "key": key},
            )
            .mappings()
            .one()
        )
        if record["request_hash"] != request_hash:
            raise ApiError(
                409,
                "idempotency_key_reused",
                "Use a new idempotency key for this request.",
                "correct_input",
            )
        if record["status"] != "completed" or not record["response_reference"]:
            raise ApiError(
                409,
                "operation_in_progress",
                "This operation is still in progress.",
                "retry",
                retryable=True,
                retry_after_seconds=1,
            )
        return str(record["response_reference"])

    @staticmethod
    def _complete_idempotency(
        connection: Connection,
        user_id: UUID,
        operation: str,
        key: str,
        response_reference: str,
    ) -> None:
        connection.execute(
            text(
                """
                UPDATE idempotency_records
                SET status='completed', response_reference=:reference,
                    updated_at=now(), row_version=row_version+1
                WHERE user_id=:user_id AND operation=:operation
                  AND idempotency_key=:key AND status='processing'
                """
            ),
            {
                "user_id": user_id,
                "operation": operation,
                "key": key,
                "reference": response_reference,
            },
        )

    @staticmethod
    def _state_changed(message: str) -> ApiError:
        return ApiError(409, "mission_state_changed", message, "refresh_state")

    @staticmethod
    def _json(value: Any) -> str:
        return json.dumps(value, sort_keys=True, separators=(",", ":"), default=str)
