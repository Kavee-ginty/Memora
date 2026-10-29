"""Transactional persistence for memory events, decisions and snapshots.

One memory update is one database transaction (Schema §14.2): read the
current snapshot under the per-concept advisory lock, decide in Python,
append-or-confirm the evidence event, write the decision with both state
snapshots, upsert the learner-concept snapshot and publish exactly one
``memory.schedule_changed`` outbox event.

All writes execute through the SECURITY DEFINER functions of migration
``20261029_0006``. The ``memora_worker`` role has no direct DML on user
tables; it only executes these functions. The API role can additionally use
the same functions inside an authenticated transaction, which keeps T13's
in-transaction event recording on the identical code path.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import Connection, Engine, text

from memora.modules.memory.engine.config import (
    DEFAULT_ENGINE_CONFIG,
    STATE_SNAPSHOT_SCHEMA_VERSION,
    EngineConfig,
)
from memora.modules.memory.engine.decide import Decision, EventFacts
from memora.modules.memory.engine.policy import PrerequisiteSignal, decide_with_policy
from memora.modules.memory.engine.state import LearnerConceptState

# Bootstrap decisions have no previous state; the stored marker is a
# schema-versioned bootstrap envelope, never restored as engine state.
BOOTSTRAP_PREVIOUS_STATE_SCHEMA = "memora.memory_state.bootstrap"

OUTBOX_EVENT_TYPE = "memory.schedule_changed"
OUTBOX_EVENT_VERSION = 1
OUTBOX_AGGREGATE_TYPE = "memory_decision"
OUTBOX_PAYLOAD_SCHEMA_VERSION = "1"

_DEFAULT_EVENT_PAYLOAD_SCHEMA_VERSION = "1"


@dataclass(frozen=True)
class RecordedMemoryEvent:
    """One evidence event: appended now, or confirmed from a prior delivery."""

    event_id: UUID
    replayed: bool


@dataclass(frozen=True)
class PersistedDecision:
    """The authoritative decision row plus its side effects."""

    decision_id: UUID
    trigger_event_id: UUID
    next_review_at: datetime
    reason_codes: tuple[str, ...]
    explanation_template_key: str
    engine_version: str
    policy_version: str
    state_row_version: int | None
    outbox_event_id: UUID | None
    replayed: bool


class MemoryRepository:
    def __init__(self, engine: Engine, *, config: EngineConfig = DEFAULT_ENGINE_CONFIG) -> None:
        self.engine = engine
        self.config = config

    # ------------------------------------------------------------------
    # public API
    # ------------------------------------------------------------------

    def apply_event(
        self,
        *,
        user_id: UUID,
        concept_id: UUID,
        active_concept_version_id: UUID,
        event: EventFacts,
        source_type: str,
        source_id: UUID,
        correlation_id: UUID,
        now: datetime,
        is_eligible: bool = True,
        ineligibility_reason: str | None = None,
        event_payload: dict[str, Any] | None = None,
        prerequisite_signal: PrerequisiteSignal | None = None,
    ) -> tuple[RecordedMemoryEvent, PersistedDecision]:
        """Record evidence and apply the policy decision in one transaction."""
        with self.engine.begin() as connection:
            recorded = self.record_event(
                connection,
                user_id=user_id,
                concept_id=concept_id,
                event=event,
                source_type=source_type,
                source_id=source_id,
                is_eligible=is_eligible,
                ineligibility_reason=ineligibility_reason,
                event_payload=event_payload,
            )
            decision = self.decide_and_persist(
                connection,
                user_id=user_id,
                concept_id=concept_id,
                active_concept_version_id=active_concept_version_id,
                trigger_event_id=recorded.event_id,
                event=event,
                source_type=source_type,
                source_id=source_id,
                correlation_id=correlation_id,
                now=now,
                prerequisite_signal=prerequisite_signal,
            )
        return recorded, decision

    def record_event(
        self,
        connection: Connection,
        *,
        user_id: UUID,
        concept_id: UUID,
        event: EventFacts,
        source_type: str,
        source_id: UUID,
        is_eligible: bool = True,
        ineligibility_reason: str | None = None,
        event_payload: dict[str, Any] | None = None,
    ) -> RecordedMemoryEvent:
        """Append one evidence event or confirm an identical prior delivery.

        Accepts an open connection so callers such as T13 can record the
        event inside their own grading transaction (Schema §14.2).
        """
        payload = event_payload or {
            "schema_version": _DEFAULT_EVENT_PAYLOAD_SCHEMA_VERSION,
            "source_type": source_type,
            "source_id": str(source_id),
        }
        row = (
            connection.execute(
                text(
                    """
                    SELECT event_id, replayed
                    FROM public.memora_memory_record_event(
                        CAST(:p_user_id AS uuid),
                        CAST(:p_concept_id AS uuid),
                        :p_event_type,
                        :p_source_type,
                        CAST(:p_source_id AS uuid),
                        CAST(:p_observed_at AS timestamptz),
                        CAST(:p_score AS numeric),
                        CAST(:p_confidence AS numeric),
                        :p_is_eligible,
                        :p_ineligibility_reason,
                        CAST(:p_event_payload AS jsonb)
                    )
                    """
                ),
                {
                    "p_user_id": str(user_id),
                    "p_concept_id": str(concept_id),
                    "p_event_type": event.event_type,
                    "p_source_type": source_type,
                    "p_source_id": str(source_id),
                    "p_observed_at": event.observed_at,
                    "p_score": event.score,
                    "p_confidence": event.confidence,
                    "p_is_eligible": is_eligible,
                    "p_ineligibility_reason": ineligibility_reason,
                    "p_event_payload": json.dumps(payload),
                },
            )
            .mappings()
            .one()
        )
        return RecordedMemoryEvent(
            event_id=UUID(str(row["event_id"])),
            replayed=bool(row["replayed"]),
        )

    def decide_and_persist(
        self,
        connection: Connection,
        *,
        user_id: UUID,
        concept_id: UUID,
        active_concept_version_id: UUID,
        trigger_event_id: UUID,
        event: EventFacts,
        source_type: str,
        source_id: UUID,
        correlation_id: UUID,
        now: datetime,
        prerequisite_signal: PrerequisiteSignal | None = None,
    ) -> PersistedDecision:
        """Decide from the locked current state and persist the outcome.

        Reads the snapshot through ``memora_memory_context`` (which also
        takes the per-pair advisory lock), computes the policy decision and
        writes decision, snapshot and outbox event through
        ``memora_memory_apply_decision``. Replays return the stored
        decision without a second outbox row.
        """
        state = self._current_state(connection, user_id=user_id, concept_id=concept_id)
        decision = decide_with_policy(
            state,
            event,
            now=now,
            prerequisite_signal=prerequisite_signal,
            config=self.config,
        )

        decision_id = uuid4()
        previous_snapshot = (
            state.to_snapshot()
            if state is not None
            else {"schema_version": BOOTSTRAP_PREVIOUS_STATE_SCHEMA}
        )
        result_snapshot = decision.result_state.to_snapshot()
        payload = self._outbox_payload(
            user_id=user_id,
            concept_id=concept_id,
            active_concept_version_id=active_concept_version_id,
            trigger_event_id=trigger_event_id,
            event=event,
            source_type=source_type,
            source_id=source_id,
            decision=decision,
        )
        domain_event_key = f"{OUTBOX_EVENT_TYPE}:{user_id}:{decision_id}"

        row = (
            connection.execute(
                text(
                    """
                    SELECT decision_id, state_row_version, outbox_event_id, replayed
                    FROM public.memora_memory_apply_decision(
                        CAST(:p_decision_id AS uuid),
                        CAST(:p_user_id AS uuid),
                        CAST(:p_concept_id AS uuid),
                        CAST(:p_active_concept_version_id AS uuid),
                        CAST(:p_trigger_event_id AS uuid),
                        CAST(:p_previous_state AS jsonb),
                        CAST(:p_result_state AS jsonb),
                        CAST(:p_retrievability AS numeric),
                        CAST(:p_next_review_at AS timestamptz),
                        CAST(:p_reason_codes AS text[]),
                        :p_explanation_template_key,
                        :p_engine_version,
                        :p_policy_version,
                        CAST(:p_decided_at AS timestamptz),
                        :p_domain_event_key,
                        CAST(:p_outbox_payload AS jsonb),
                        CAST(:p_correlation_id AS uuid)
                    )
                    """
                ),
                {
                    "p_decision_id": str(decision_id),
                    "p_user_id": str(user_id),
                    "p_concept_id": str(concept_id),
                    "p_active_concept_version_id": str(active_concept_version_id),
                    "p_trigger_event_id": str(trigger_event_id),
                    "p_previous_state": json.dumps(previous_snapshot),
                    "p_result_state": json.dumps(result_snapshot),
                    "p_retrievability": decision.retrievability_at_decision,
                    "p_next_review_at": decision.next_review_at,
                    "p_reason_codes": list(decision.reason_codes),
                    "p_explanation_template_key": decision.explanation_template_key,
                    "p_engine_version": decision.engine_version,
                    "p_policy_version": decision.policy_version,
                    "p_decided_at": now,
                    "p_domain_event_key": domain_event_key,
                    "p_outbox_payload": json.dumps(payload),
                    "p_correlation_id": str(correlation_id),
                },
            )
            .mappings()
            .one()
        )
        return PersistedDecision(
            decision_id=UUID(str(row["decision_id"])),
            trigger_event_id=trigger_event_id,
            next_review_at=decision.next_review_at,
            reason_codes=decision.reason_codes,
            explanation_template_key=decision.explanation_template_key,
            engine_version=decision.engine_version,
            policy_version=decision.policy_version,
            state_row_version=(
                None if row["state_row_version"] is None else int(row["state_row_version"])
            ),
            outbox_event_id=(
                None if row["outbox_event_id"] is None else UUID(str(row["outbox_event_id"]))
            ),
            replayed=bool(row["replayed"]),
        )

    # ------------------------------------------------------------------
    # helpers
    # ------------------------------------------------------------------

    def _current_state(
        self,
        connection: Connection,
        *,
        user_id: UUID,
        concept_id: UUID,
    ) -> LearnerConceptState | None:
        state_json = connection.scalar(
            text(
                """
                SELECT public.memora_memory_context(
                    CAST(:p_user_id AS uuid), CAST(:p_concept_id AS uuid)
                )
                """
            ),
            {"p_user_id": str(user_id), "p_concept_id": str(concept_id)},
        )
        if state_json is None:
            return None
        snapshot = dict(state_json)
        snapshot["schema_version"] = STATE_SNAPSHOT_SCHEMA_VERSION
        return LearnerConceptState.from_snapshot(snapshot, config=self.config)

    @staticmethod
    def _outbox_payload(
        *,
        user_id: UUID,
        concept_id: UUID,
        active_concept_version_id: UUID,
        trigger_event_id: UUID,
        event: EventFacts,
        source_type: str,
        source_id: UUID,
        decision: Decision,
    ) -> dict[str, Any]:
        """Identifiers and safe scheduling facts only; never learning text."""
        return {
            "schema_version": OUTBOX_PAYLOAD_SCHEMA_VERSION,
            "user_id": str(user_id),
            "concept_id": str(concept_id),
            "concept_version_id": str(active_concept_version_id),
            "trigger_event_id": str(trigger_event_id),
            "event_type": event.event_type,
            "source_type": source_type,
            "source_id": str(source_id),
            "next_review_at": decision.next_review_at.isoformat(),
            "reason_codes": list(decision.reason_codes),
            "explanation_template_key": decision.explanation_template_key,
            "engine_version": decision.engine_version,
            "policy_version": decision.policy_version,
        }
