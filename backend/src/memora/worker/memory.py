"""Outbox-driven memory worker (T11).

Consumes producer events that carry memory evidence and turns them into
memory updates through :class:`memora.modules.memory.repository.MemoryRepository`.

Job type ``memory.process_event`` carries IDs only (Schema 13.3): the
``outbox_event_id`` of one producer event. The producer envelope contract
(decision D9 of the T11 implementation guide, reviewer acknowledgement
pending because the producers T09/T13 are not merged yet):

- ``learning_update.committed`` (aggregate ``learning_update``): exposure
  evidence for each committed concept. Payload requires ``user_id``,
  ``learning_update_id`` and ``committed_concepts`` - a list of objects with
  ``concept_id``, ``concept_version_id`` and ``confidence``.
- ``mission.attempt_graded`` (aggregate ``attempt``): scored evidence per
  mapped concept. Payload requires ``user_id``, ``attempt_id`` and
  ``concept_grades`` - a list of objects with ``concept_id``,
  ``concept_version_id``, ``score``, ``confidence`` and optional
  ``memory_event_type`` (``attempt``, ``repair``, ``regrade`` or
  ``manual_review``), ``is_eligible`` and ``ineligibility_reason``.

Envelope tolerance: events of unknown types are skipped successfully;
memory-relevant events with malformed payloads dead-letter immediately with
a safe code and never block the queue. A reconcile pass re-enqueues missed
evidence and recovers expired leases, so a crashed or restarted worker loses
nothing. Dead-lettered events are deliberately not re-enqueued: the poison
payload stays quarantined until an operator fixes it.

Transaction roles (migration 0004): the job lifecycle runs as
``memora_worker``, which can read and update ``background_jobs`` and read
``outbox_events`` but has no DML on user tables. The evidence transaction
runs as ``memora_api`` with ``memora.user_id`` set for the envelope's
learner, so the prerequisite lookup is RLS-scoped and the memory writes still
go through the SECURITY DEFINER functions. The worker's connection role must
therefore be able to assume both roles (the same requirement T09 documents
for its ingestion worker).
"""

from __future__ import annotations

import logging
import os
import time
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import Connection, Engine, text

from memora.modules.memory.constants import (
    EVENT_ATTEMPT,
    EVENT_EXPOSURE,
    SCORED_MEMORY_EVENT_TYPES,
)
from memora.modules.memory.engine.decide import EventFacts
from memora.modules.memory.prerequisites import collect_prerequisite_signal
from memora.modules.memory.repository import MemoryRepository

LOGGER = logging.getLogger(__name__)

JOB_TYPE_MEMORY_PROCESS_EVENT = "memory.process_event"

# Producer outbox events that carry memory evidence (D9 contract).
EXPOSURE_SOURCE_EVENT_TYPE = "learning_update.committed"
ATTEMPT_SOURCE_EVENT_TYPE = "mission.attempt_graded"
MEMORY_SOURCE_EVENT_TYPES = (EXPOSURE_SOURCE_EVENT_TYPE, ATTEMPT_SOURCE_EVENT_TYPE)

EXPOSURE_SOURCE_TYPE = "learning_update"
ATTEMPT_SOURCE_TYPE = "attempt"
SOURCE_AGGREGATE_TYPES = {
    EXPOSURE_SOURCE_EVENT_TYPE: EXPOSURE_SOURCE_TYPE,
    ATTEMPT_SOURCE_EVENT_TYPE: ATTEMPT_SOURCE_TYPE,
}

ENVELOPE_SCHEMA_VERSION = "1"

# Narrow job-lifecycle role and the RLS-scoped learner role.
WORKER_ROLE = "memora_worker"
LEARNER_ROLE = "memora_api"

POLL_SECONDS = 2.0
RECONCILE_SECONDS = 60.0
LEASE_SECONDS = 120.0
MAX_JOB_ATTEMPTS = 5
RETRY_BACKOFF_SECONDS = (15, 60, 180, 600, 1800)

CODE_INVALID_EVENT_PAYLOAD = "invalid_event_payload"
CODE_SOURCE_EVENT_MISSING = "source_event_missing"
CODE_PROCESSING_FAILED = "processing_failed"
CODE_LEASE_EXPIRED = "lease_expired"

OUTCOME_IDLE = "idle"
OUTCOME_SUCCEEDED = "succeeded"
OUTCOME_RETRY_WAIT = "retry_wait"
OUTCOME_DEAD_LETTERED = "dead_lettered"
OUTCOME_LEASE_LOST = "lease_lost"

_CLAIM_QUERY = text(
    """
    UPDATE background_jobs
    SET status = 'leased',
        lease_owner = :lease_owner,
        lease_expires_at = :lease_expires_at,
        attempt_count = attempt_count + 1,
        updated_at = now(),
        row_version = row_version + 1
    WHERE id = (
        SELECT id FROM background_jobs
        WHERE job_type = ANY(CAST(:job_types AS text[]))
          AND status IN ('queued', 'retry_wait')
          AND available_at <= :now
        ORDER BY available_at
        FOR UPDATE SKIP LOCKED
        LIMIT 1
    )
    RETURNING id, job_type, payload, attempt_count, max_attempts
    """
)

_COMPLETE_QUERY = text(
    """
    UPDATE background_jobs
    SET status = 'succeeded',
        lease_owner = NULL,
        lease_expires_at = NULL,
        last_error_code = NULL,
        updated_at = now(),
        row_version = row_version + 1
    WHERE id = CAST(:job_id AS uuid)
      AND status = 'leased'
      AND lease_owner = :lease_owner
    """
)

_FAIL_QUERY = text(
    """
    UPDATE background_jobs
    SET status = CASE
            WHEN CAST(:retryable AS boolean) AND attempt_count < max_attempts
                THEN 'retry_wait'
            ELSE 'dead_lettered'
        END,
        lease_owner = NULL,
        lease_expires_at = NULL,
        last_error_code = :error_code,
        available_at = CASE
            WHEN CAST(:retryable AS boolean) AND attempt_count < max_attempts
                THEN CAST(:retry_at AS timestamptz)
            ELSE available_at
        END,
        updated_at = now(),
        row_version = row_version + 1
    WHERE id = CAST(:job_id AS uuid)
      AND status = 'leased'
      AND lease_owner = :lease_owner
    RETURNING status
    """
)

_LEASE_RECOVERY_QUERY = text(
    """
    UPDATE background_jobs
    SET status = CASE
            WHEN attempt_count >= max_attempts THEN 'dead_lettered'
            ELSE 'queued'
        END,
        lease_owner = NULL,
        lease_expires_at = NULL,
        available_at = :now,
        last_error_code = CASE
            WHEN attempt_count >= max_attempts THEN :lease_code
            ELSE last_error_code
        END,
        updated_at = now(),
        row_version = row_version + 1
    WHERE status = 'leased'
      AND lease_expires_at < :now
    RETURNING status
    """
)

_BACKLOG_ENQUEUE_QUERY = text(
    """
    INSERT INTO background_jobs(
        job_type, owner_user_id, resource_type, resource_id, dedupe_key,
        status, attempt_count, max_attempts, available_at, payload
    )
    SELECT
        :job_type,
        NULL,
        'outbox_event',
        e.id,
        'memory:outbox:' || e.id::text,
        'queued',
        0,
        :max_attempts,
        :now,
        jsonb_build_object(
            'schema_version', CAST(:schema_version AS text),
            'outbox_event_id', e.id
        )
    FROM outbox_events e
    WHERE e.event_type = ANY(CAST(:source_event_types AS text[]))
      AND NOT EXISTS (
          SELECT 1 FROM background_jobs j
          WHERE j.dedupe_key = 'memory:outbox:' || e.id::text
      )
    ON CONFLICT (dedupe_key) DO NOTHING
    RETURNING id
    """
)


class NonRetryableJobError(Exception):
    """A failure that retries can never fix; the job dead-letters."""

    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


@dataclass(frozen=True)
class ConceptEvidence:
    """Memory evidence for one concept, normalized from a producer envelope."""

    user_id: UUID
    concept_id: UUID
    concept_version_id: UUID
    memory_event_type: str
    source_type: str
    source_id: UUID
    score: float | None
    confidence: float
    is_eligible: bool
    ineligibility_reason: str | None
    event_payload: dict[str, Any]


# ----------------------------------------------------------------------
# producer envelope mapping
# ----------------------------------------------------------------------


def map_outbox_event(
    aggregate_type: str,
    event_type: str,
    payload: Any,
    *,
    outbox_event_id: UUID,
) -> list[ConceptEvidence]:
    """Map one producer outbox event to per-concept memory evidence.

    Unknown event types yield an empty list (the job succeeds as a skip).
    A known event type whose aggregate or payload breaks the documented
    envelope raises :class:`NonRetryableJobError`.
    """
    expected_aggregate = SOURCE_AGGREGATE_TYPES.get(event_type)
    if expected_aggregate is None:
        return []
    if aggregate_type != expected_aggregate:
        raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD)
    if not isinstance(payload, dict) or payload.get("schema_version") != ENVELOPE_SCHEMA_VERSION:
        raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD)

    try:
        user_id = UUID(str(payload["user_id"]))
        if event_type == EXPOSURE_SOURCE_EVENT_TYPE:
            source_id = UUID(str(payload["learning_update_id"]))
            source_type = EXPOSURE_SOURCE_TYPE
            entries = payload["committed_concepts"]
        else:
            source_id = UUID(str(payload["attempt_id"]))
            source_type = ATTEMPT_SOURCE_TYPE
            entries = payload["concept_grades"]
    except (KeyError, TypeError, ValueError) as exc:
        raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD) from exc

    if not isinstance(entries, list) or not entries:
        raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD)

    return [
        _map_concept_entry(
            entry,
            event_type=event_type,
            user_id=user_id,
            source_type=source_type,
            source_id=source_id,
            outbox_event_id=outbox_event_id,
        )
        for entry in entries
    ]


def _map_concept_entry(
    entry: Any,
    *,
    event_type: str,
    user_id: UUID,
    source_type: str,
    source_id: UUID,
    outbox_event_id: UUID,
) -> ConceptEvidence:
    if not isinstance(entry, dict):
        raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD)
    try:
        concept_id = UUID(str(entry["concept_id"]))
        concept_version_id = UUID(str(entry["concept_version_id"]))
    except (KeyError, TypeError, ValueError) as exc:
        raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD) from exc

    confidence = _bounded_number(entry.get("confidence"))
    if event_type == EXPOSURE_SOURCE_EVENT_TYPE:
        memory_event_type = EVENT_EXPOSURE
        score = None
    else:
        memory_event_type = str(entry.get("memory_event_type", EVENT_ATTEMPT))
        if memory_event_type not in SCORED_MEMORY_EVENT_TYPES:
            raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD)
        score = _bounded_number(entry.get("score"))

    is_eligible = entry.get("is_eligible", True)
    if not isinstance(is_eligible, bool):
        raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD)
    ineligibility_reason = entry.get("ineligibility_reason")
    if ineligibility_reason is not None and not isinstance(ineligibility_reason, str):
        raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD)

    return ConceptEvidence(
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=concept_version_id,
        memory_event_type=memory_event_type,
        source_type=source_type,
        source_id=source_id,
        score=score,
        confidence=confidence,
        is_eligible=is_eligible,
        ineligibility_reason=ineligibility_reason,
        event_payload={
            "schema_version": ENVELOPE_SCHEMA_VERSION,
            "outbox_event_id": str(outbox_event_id),
            "producer_event_type": event_type,
        },
    )


def _bounded_number(value: Any) -> float:
    """Accept a JSON number in ``[0, 1]``; reject booleans and strings."""
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD)
    number = float(value)
    if not 0.0 <= number <= 1.0:
        raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD)
    return number


# ----------------------------------------------------------------------
# transaction roles
# ----------------------------------------------------------------------


def _set_worker_role(connection: Connection) -> None:
    connection.execute(text(f"SET LOCAL ROLE {WORKER_ROLE}"))


def _set_learner_context(connection: Connection, user_id: UUID) -> None:
    connection.execute(text(f"SET LOCAL ROLE {LEARNER_ROLE}"))
    connection.execute(
        text("SELECT set_config('memora.user_id', :user_id, true)"),
        {"user_id": str(user_id)},
    )


def _validate_concept_version_pairs(
    connection: Connection, evidence_list: list[ConceptEvidence]
) -> None:
    """Reject envelopes that pair a concept with another concept's version.

    The composite foreign key added by migration ``20261030_0009`` enforces
    the same pair for every write path; this check converts the violation
    into a non-retryable dead-letter with a safe code so a malformed
    producer event never blocks the queue.
    """
    for evidence in evidence_list:
        found = connection.scalar(
            text(
                """
                SELECT 1 FROM concept_versions
                WHERE id = CAST(:version_id AS uuid)
                  AND concept_id = CAST(:concept_id AS uuid)
                """
            ),
            {
                "version_id": str(evidence.concept_version_id),
                "concept_id": str(evidence.concept_id),
            },
        )
        if not found:
            raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD)


# ----------------------------------------------------------------------
# job lifecycle
# ----------------------------------------------------------------------


def claim_job(
    connection: Connection,
    *,
    job_types: tuple[str, ...],
    now: datetime,
    lease_owner: str,
    lease_seconds: float = LEASE_SECONDS,
) -> dict[str, Any] | None:
    """Claim one runnable job with ``FOR UPDATE SKIP LOCKED``.

    The claim increments ``attempt_count``; a job is therefore attempted at
    most ``max_attempts`` times, including attempts lost to a crashed worker.
    """
    row = (
        connection.execute(
            _CLAIM_QUERY,
            {
                "job_types": list(job_types),
                "now": now,
                "lease_owner": lease_owner,
                "lease_expires_at": now + timedelta(seconds=lease_seconds),
            },
        )
        .mappings()
        .first()
    )
    return dict(row) if row else None


def complete_job(connection: Connection, *, job_id: Any, lease_owner: str) -> bool:
    """Mark a leased job succeeded; a lost lease silently declines."""
    result = connection.execute(
        _COMPLETE_QUERY, {"job_id": str(job_id), "lease_owner": lease_owner}
    )
    return result.rowcount > 0


def fail_job(
    connection: Connection,
    *,
    job_id: Any,
    lease_owner: str,
    error_code: str,
    retryable: bool,
    now: datetime,
    backoff: tuple[int, ...] = RETRY_BACKOFF_SECONDS,
) -> str | None:
    """Send a failed job back to the retry schedule or to the dead letter.

    Returns the resulting job status, or ``None`` when the lease was lost.
    """
    attempt = _claimed_attempt(connection, job_id=job_id, lease_owner=lease_owner)
    if attempt is None:
        return None
    delay = backoff[min(max(attempt - 1, 0), len(backoff) - 1)]
    return connection.execute(
        _FAIL_QUERY,
        {
            "job_id": str(job_id),
            "lease_owner": lease_owner,
            "error_code": error_code,
            "retryable": retryable,
            "retry_at": now + timedelta(seconds=delay),
        },
    ).scalar_one_or_none()


def _claimed_attempt(connection: Connection, *, job_id: Any, lease_owner: str) -> int | None:
    return connection.scalar(
        text(
            """
            SELECT attempt_count FROM background_jobs
            WHERE id = CAST(:job_id AS uuid)
              AND status = 'leased'
              AND lease_owner = :lease_owner
            """
        ),
        {"job_id": str(job_id), "lease_owner": lease_owner},
    )


def recover_expired_leases(connection: Connection, *, now: datetime) -> int:
    """Return expired jobs to the queue, or dead-letter exhausted ones."""
    rows = connection.execute(
        _LEASE_RECOVERY_QUERY, {"now": now, "lease_code": CODE_LEASE_EXPIRED}
    ).fetchall()
    return len(rows)


def enqueue_outbox_backlog(
    connection: Connection,
    *,
    now: datetime,
    job_type: str = JOB_TYPE_MEMORY_PROCESS_EVENT,
    source_event_types: tuple[str, ...] = MEMORY_SOURCE_EVENT_TYPES,
    max_attempts: int = MAX_JOB_ATTEMPTS,
    schema_version: str = ENVELOPE_SCHEMA_VERSION,
) -> int:
    """Enqueue one job per memory-relevant producer event without a job.

    An event whose job already exists is left alone in every state, so a
    dead-lettered poison payload is never resurrected by reconciliation.
    """
    rows = connection.execute(
        _BACKLOG_ENQUEUE_QUERY,
        {
            "job_type": job_type,
            "now": now,
            "max_attempts": max_attempts,
            "schema_version": schema_version,
            "source_event_types": list(source_event_types),
        },
    ).fetchall()
    return len(rows)


# ----------------------------------------------------------------------
# job execution
# ----------------------------------------------------------------------


def process_next_job(
    engine: Engine,
    *,
    now: datetime,
    lease_owner: str,
    job_types: tuple[str, ...] = (JOB_TYPE_MEMORY_PROCESS_EVENT,),
) -> str:
    """Claim and process one job; returns an outcome for the run loop."""
    with engine.begin() as connection:
        _set_worker_role(connection)
        job = claim_job(connection, job_types=job_types, now=now, lease_owner=lease_owner)
    if job is None:
        return OUTCOME_IDLE

    try:
        processed = handle_job(engine, job, now=now)
    except NonRetryableJobError as exc:
        status = _fail(
            engine,
            job,
            lease_owner=lease_owner,
            error_code=exc.code,
            retryable=False,
            now=now,
        )
        LOGGER.warning("memory job dead-lettered: job_id=%s code=%s", job["id"], exc.code)
        return OUTCOME_DEAD_LETTERED if status == "dead_lettered" else OUTCOME_LEASE_LOST
    except Exception:  # noqa: BLE001 - the run loop owns error classification
        # Log identifiers only; never event payload content (D13).
        LOGGER.exception("memory job failed: job_id=%s", job["id"])
        status = _fail(
            engine,
            job,
            lease_owner=lease_owner,
            error_code=CODE_PROCESSING_FAILED,
            retryable=True,
            now=now,
        )
        if status is None:
            return OUTCOME_LEASE_LOST
        return OUTCOME_RETRY_WAIT if status == "retry_wait" else OUTCOME_DEAD_LETTERED

    with engine.begin() as connection:
        _set_worker_role(connection)
        completed = complete_job(connection, job_id=job["id"], lease_owner=lease_owner)
    if not completed:
        # The lease expired and the job was re-claimed; the processing was
        # idempotent, so the re-delivery converges (D6).
        LOGGER.info("memory job lease lost: job_id=%s", job["id"])
        return OUTCOME_LEASE_LOST
    LOGGER.info("memory job succeeded: job_id=%s concepts=%s", job["id"], processed)
    return OUTCOME_SUCCEEDED


def _fail(
    engine: Engine,
    job: dict[str, Any],
    *,
    lease_owner: str,
    error_code: str,
    retryable: bool,
    now: datetime,
) -> str | None:
    with engine.begin() as connection:
        _set_worker_role(connection)
        return fail_job(
            connection,
            job_id=job["id"],
            lease_owner=lease_owner,
            error_code=error_code,
            retryable=retryable,
            now=now,
        )


def handle_job(engine: Engine, job: dict[str, Any], *, now: datetime) -> int:
    """Apply all memory evidence carried by one job's producer event.

    Returns the number of concept updates applied; zero means the producer
    event was not memory-relevant and the job succeeded as a skip.
    """
    payload = job.get("payload")
    if not isinstance(payload, dict):
        raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD)
    try:
        outbox_event_id = UUID(str(payload["outbox_event_id"]))
    except (KeyError, TypeError, ValueError) as exc:
        raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD) from exc

    with engine.begin() as connection:
        _set_worker_role(connection)
        event = (
            connection.execute(
                text(
                    """
                    SELECT aggregate_type, event_type, payload, correlation_id, created_at
                    FROM outbox_events
                    WHERE id = CAST(:event_id AS uuid)
                    """
                ),
                {"event_id": str(outbox_event_id)},
            )
            .mappings()
            .first()
        )
    if event is None:
        raise NonRetryableJobError(CODE_SOURCE_EVENT_MISSING)

    evidence_list = map_outbox_event(
        str(event["aggregate_type"]),
        str(event["event_type"]),
        event["payload"],
        outbox_event_id=outbox_event_id,
    )
    if not evidence_list:
        return 0
    if len({evidence.user_id for evidence in evidence_list}) != 1:
        raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD)

    with engine.begin() as connection:
        _set_worker_role(connection)
        _validate_concept_version_pairs(connection, evidence_list)

    correlation_id = UUID(str(event["correlation_id"])) if event["correlation_id"] else uuid4()
    # The producer event's commit time is the evidence observation time.
    observed_at = event["created_at"].astimezone(UTC)
    repository = MemoryRepository(engine)

    with engine.begin() as connection:
        _set_learner_context(connection, evidence_list[0].user_id)
        for evidence in evidence_list:
            facts = EventFacts(
                event_type=evidence.memory_event_type,
                observed_at=observed_at,
                confidence=evidence.confidence,
                score=evidence.score,
            )
            if not evidence.is_eligible:
                # Ineligible evidence is appended for the audit trail but
                # never drives a decision or a schedule change.
                repository.record_event(
                    connection,
                    user_id=evidence.user_id,
                    concept_id=evidence.concept_id,
                    event=facts,
                    source_type=evidence.source_type,
                    source_id=evidence.source_id,
                    is_eligible=False,
                    ineligibility_reason=evidence.ineligibility_reason,
                    event_payload=evidence.event_payload,
                )
                continue
            signal = collect_prerequisite_signal(
                connection,
                user_id=evidence.user_id,
                concept_version_id=evidence.concept_version_id,
                now=now,
            )
            repository.apply_event(
                user_id=evidence.user_id,
                concept_id=evidence.concept_id,
                active_concept_version_id=evidence.concept_version_id,
                event=facts,
                source_type=evidence.source_type,
                source_id=evidence.source_id,
                correlation_id=correlation_id,
                now=now,
                is_eligible=evidence.is_eligible,
                ineligibility_reason=evidence.ineligibility_reason,
                event_payload=evidence.event_payload,
                prerequisite_signal=signal,
                connection=connection,
            )
    return len(evidence_list)


# ----------------------------------------------------------------------
# run loop
# ----------------------------------------------------------------------


def run_worker(
    engine: Engine,
    *,
    poll_seconds: float = POLL_SECONDS,
    reconcile_seconds: float = RECONCILE_SECONDS,
    lease_owner: str | None = None,
    stop_after_cycles: int | None = None,
) -> None:
    """Poll for memory jobs forever; reconcile leases and backlog periodically."""
    owner = lease_owner or f"memory-worker:{os.getpid()}:{uuid4().hex[:8]}"
    LOGGER.info("memory worker started: owner=%s", owner)
    last_reconcile = 0.0
    cycles = 0
    while True:
        now = datetime.now(UTC)
        if time.monotonic() - last_reconcile >= reconcile_seconds:
            with engine.begin() as connection:
                _set_worker_role(connection)
                recovered = recover_expired_leases(connection, now=now)
                enqueued = enqueue_outbox_backlog(connection, now=now)
            if recovered or enqueued:
                LOGGER.info("memory reconcile: recovered=%s enqueued=%s", recovered, enqueued)
            last_reconcile = time.monotonic()

        outcome = process_next_job(engine, now=datetime.now(UTC), lease_owner=owner)
        if outcome == OUTCOME_IDLE:
            time.sleep(poll_seconds)
        cycles += 1
        if stop_after_cycles is not None and cycles >= stop_after_cycles:
            return
