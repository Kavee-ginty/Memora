"""Worker contracts for outbox-driven memory updates (T11).

Covers the Commit-4 acceptance surface: both producer envelopes (D9),
duplicate delivery convergence, envelope tolerance, dead-lettering,
retry/backoff, lease recovery, reconcile-once backlog enqueueing, the
learner-scoped apply transaction and the worker role boundary. Database
tests skip unless MEMORA_TEST_DATABASE_URL targets a disposable database.
"""

from __future__ import annotations

import json
import logging
from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import pytest
from sqlalchemy import Engine, text

from memora.modules.memory.engine.policy import PrerequisiteSignal
from memora.worker import memory as worker_memory
from memora.worker.memory import (
    JOB_TYPE_MEMORY_PROCESS_EVENT,
    NonRetryableJobError,
    claim_job,
    enqueue_outbox_backlog,
    map_outbox_event,
    process_next_job,
    recover_expired_leases,
)
from test_memory_persistence import alembic_config, create_user, seed_concept

NOW = datetime(2026, 10, 30, 12, 0, 0, tzinfo=UTC)
OBSERVED_AT = NOW - timedelta(hours=1)
OWNER = "test-memory-worker"

DISPOSABLE_DATABASE_SUFFIXES = ("_test", "_ci")


@pytest.fixture
def database(monkeypatch: pytest.MonkeyPatch):
    """Same disposable-database contract as the persistence suite."""
    import os

    from sqlalchemy import create_engine
    from sqlalchemy.engine import make_url

    database_url = os.getenv("MEMORA_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("MEMORA_TEST_DATABASE_URL is not configured")
    database_name = make_url(database_url).database or ""
    if not database_name.endswith(DISPOSABLE_DATABASE_SUFFIXES):
        pytest.fail(
            "MEMORA_TEST_DATABASE_URL must target a disposable database ending in "
            f"{' or '.join(DISPOSABLE_DATABASE_SUFFIXES)}",
            pytrace=False,
        )

    monkeypatch.setenv("MEMORA_DATABASE_URL", database_url)
    from alembic import command

    from memora.db.seed import seed_database

    command.upgrade(alembic_config(database_url), "head")
    seed_database(database_url)
    engine = create_engine(database_url, connect_args={"connect_timeout": 10})
    # Outbox events are append-only, so isolate each test by truncating the
    # mutable queue/evidence tables (TRUNCATE bypasses row-level triggers).
    with engine.begin() as connection:
        connection.execute(
            text(
                "TRUNCATE background_jobs, outbox_events, memory_events,"
                " memory_decisions, learner_concept_states CASCADE"
            )
        )
    try:
        yield engine
    finally:
        engine.dispose()


# ---------------------------------------------------------------------------
# envelope mapping (pure, no database)
# ---------------------------------------------------------------------------


def test_unknown_event_type_maps_to_no_evidence() -> None:
    evidence = map_outbox_event(
        "curriculum",
        "curriculum.concept_approved",
        {"schema_version": "1", "concept_id": str(uuid4())},
        outbox_event_id=uuid4(),
    )
    assert evidence == []


def test_known_event_type_with_wrong_aggregate_is_malformed() -> None:
    with pytest.raises(NonRetryableJobError) as raised:
        map_outbox_event(
            "curriculum",
            "learning_update.committed",
            {"schema_version": "1"},
            outbox_event_id=uuid4(),
        )
    assert raised.value.code == "invalid_event_payload"


@pytest.mark.parametrize(
    "entry",
    [
        {"concept_id": str(uuid4()), "concept_version_id": str(uuid4()), "confidence": 1.5},
        {"concept_id": str(uuid4()), "concept_version_id": str(uuid4()), "confidence": True},
        {"concept_id": str(uuid4()), "confidence": 0.5},
    ],
)
def test_exposure_entry_outside_the_envelope_is_malformed(entry: dict) -> None:
    with pytest.raises(NonRetryableJobError):
        map_outbox_event(
            "learning_update",
            "learning_update.committed",
            {
                "schema_version": "1",
                "user_id": str(uuid4()),
                "learning_update_id": str(uuid4()),
                "committed_concepts": [entry],
            },
            outbox_event_id=uuid4(),
        )


def test_attempt_entry_with_unknown_event_type_is_malformed() -> None:
    with pytest.raises(NonRetryableJobError):
        map_outbox_event(
            "attempt",
            "mission.attempt_graded",
            {
                "schema_version": "1",
                "user_id": str(uuid4()),
                "attempt_id": str(uuid4()),
                "concept_grades": [
                    {
                        "concept_id": str(uuid4()),
                        "concept_version_id": str(uuid4()),
                        "score": 0.9,
                        "confidence": 0.9,
                        "memory_event_type": "invalidation",
                    }
                ],
            },
            outbox_event_id=uuid4(),
        )


# ---------------------------------------------------------------------------
# synthetic fixtures
# ---------------------------------------------------------------------------


def enqueue_producer_event(
    engine: Engine,
    *,
    aggregate_type: str,
    event_type: str,
    payload: dict,
    correlation_id: str | None = None,
    observed_at: datetime = OBSERVED_AT,
) -> UUID:
    with engine.begin() as connection:
        event_id = connection.scalar(
            text(
                """
                INSERT INTO outbox_events(
                    domain_event_key, aggregate_type, aggregate_id, event_type,
                    event_version, payload, correlation_id, publication_status,
                    created_at
                ) VALUES (
                    :domain_event_key, :aggregate_type, :aggregate_id, :event_type,
                    1, CAST(:payload AS jsonb), CAST(:correlation_id AS uuid),
                    'pending', CAST(:created_at AS timestamptz)
                ) RETURNING id
                """
            ),
            {
                "domain_event_key": f"test:{uuid4()}",
                "aggregate_type": aggregate_type,
                "aggregate_id": str(uuid4()),
                "event_type": event_type,
                "payload": json.dumps(payload),
                "correlation_id": correlation_id or str(uuid4()),
                "created_at": observed_at,
            },
        )
    return UUID(str(event_id))


def enqueue_job(
    engine: Engine,
    *,
    outbox_event_id: UUID,
    dedupe_key: str | None = None,
    status: str = "queued",
    payload: dict | None = None,
    max_attempts: int = 5,
    attempt_count: int = 0,
    available_at: datetime | None = None,
) -> UUID:
    with engine.begin() as connection:
        job_id = connection.scalar(
            text(
                """
                INSERT INTO background_jobs(
                    job_type, owner_user_id, resource_type, resource_id,
                    dedupe_key, status, attempt_count, max_attempts,
                    available_at, payload
                ) VALUES (
                    :job_type, NULL, 'outbox_event', CAST(:resource_id AS uuid),
                    :dedupe_key, :status, :attempt_count, :max_attempts,
                    CAST(:available_at AS timestamptz), CAST(:payload AS jsonb)
                ) RETURNING id
                """
            ),
            {
                "job_type": JOB_TYPE_MEMORY_PROCESS_EVENT,
                "resource_id": str(outbox_event_id),
                "dedupe_key": dedupe_key or f"memory:outbox:{outbox_event_id}",
                "status": status,
                "attempt_count": attempt_count,
                "max_attempts": max_attempts,
                "available_at": available_at or (NOW - timedelta(seconds=1)),
                "payload": json.dumps(
                    payload or {"schema_version": "1", "outbox_event_id": str(outbox_event_id)}
                ),
            },
        )
    return UUID(str(job_id))


def exposure_payload(
    user_id: UUID,
    concepts: list[dict],
    *,
    learning_update_id: UUID | None = None,
    **overrides: object,
) -> dict:
    payload = {
        "schema_version": "1",
        "user_id": str(user_id),
        "learning_update_id": str(learning_update_id or uuid4()),
        "committed_concepts": concepts,
    }
    payload.update(overrides)
    return payload


def attempt_payload(
    user_id: UUID,
    concepts: list[dict],
    *,
    attempt_id: UUID | None = None,
    **overrides: object,
) -> dict:
    payload = {
        "schema_version": "1",
        "user_id": str(user_id),
        "attempt_id": str(attempt_id or uuid4()),
        "concept_grades": concepts,
    }
    payload.update(overrides)
    return payload


def run_one(engine: Engine, *, now: datetime = NOW) -> str:
    return process_next_job(engine, now=now, lease_owner=OWNER)


def seed_concepts(engine: Engine, count: int = 2) -> list[tuple[UUID, UUID]]:
    """Distinct approved ``(concept_id, version_id)`` pairs."""
    with engine.begin() as connection:
        rows = (
            connection.execute(
                text(
                    """
                    SELECT DISTINCT ON (c.id) c.id AS concept_id, cv.id AS version_id
                    FROM concepts c
                    JOIN concept_versions cv ON cv.concept_id = c.id
                    WHERE c.status = 'approved' AND cv.content_status = 'approved'
                    ORDER BY c.id, cv.version_no
                    LIMIT :count
                    """
                ),
                {"count": count},
            )
            .mappings()
            .all()
        )
    return [(UUID(str(row["concept_id"])), UUID(str(row["version_id"]))) for row in rows]


def counts(engine: Engine, user_id: UUID) -> tuple[int, int, int]:
    with engine.begin() as connection:
        events = connection.execute(
            text("SELECT count(*) FROM memory_events WHERE user_id = :u"),
            {"u": str(user_id)},
        ).scalar_one()
        decisions = connection.execute(
            text("SELECT count(*) FROM memory_decisions WHERE user_id = :u"),
            {"u": str(user_id)},
        ).scalar_one()
        states = connection.execute(
            text("SELECT count(*) FROM learner_concept_states WHERE user_id = :u"),
            {"u": str(user_id)},
        ).scalar_one()
    return int(events), int(decisions), int(states)


def job_status(engine: Engine, job_id: UUID) -> dict:
    with engine.begin() as connection:
        row = (
            connection.execute(
                text(
                    "SELECT status, last_error_code, attempt_count, max_attempts,"
                    " available_at FROM background_jobs WHERE id = CAST(:id AS uuid)"
                ),
                {"id": str(job_id)},
            )
            .mappings()
            .one()
        )
    return dict(row)


def scheduled_outbox_count(engine: Engine, user_id: UUID) -> int:
    with engine.begin() as connection:
        return int(
            connection.execute(
                text(
                    "SELECT count(*) FROM outbox_events WHERE event_type ="
                    " 'memory.schedule_changed' AND payload->>'user_id' = :u"
                ),
                {"u": str(user_id)},
            ).scalar_one()
        )


# ---------------------------------------------------------------------------
# producer envelopes
# ---------------------------------------------------------------------------


def test_exposure_envelope_creates_updates_for_every_committed_concept(
    database: Engine,
) -> None:
    user_id = create_user(database)
    (concept_a, version_a), (concept_b, version_b) = seed_concepts(database, 2)
    payload = exposure_payload(
        user_id,
        [
            {
                "concept_id": str(concept_a),
                "concept_version_id": str(version_a),
                "confidence": 0.9,
            },
            {
                "concept_id": str(concept_b),
                "concept_version_id": str(version_b),
                "confidence": 0.8,
            },
        ],
    )
    event_id = enqueue_producer_event(
        database,
        aggregate_type="learning_update",
        event_type="learning_update.committed",
        payload=payload,
    )
    enqueue_job(database, outbox_event_id=event_id)

    assert run_one(database) == "succeeded"

    events, decisions, states = counts(database, user_id)
    assert (events, decisions, states) == (2, 2, 2)
    with database.begin() as connection:
        event_types = [
            row[0]
            for row in connection.execute(
                text("SELECT event_type FROM memory_events WHERE user_id = :u"),
                {"u": str(user_id)},
            ).fetchall()
        ]
    assert set(event_types) == {"exposure"}
    assert scheduled_outbox_count(database, user_id) == 2


def test_attempt_envelope_records_scored_review(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)

    exposure_event = enqueue_producer_event(
        database,
        aggregate_type="learning_update",
        event_type="learning_update.committed",
        payload=exposure_payload(
            user_id,
            [
                {
                    "concept_id": str(concept_id),
                    "concept_version_id": str(version_id),
                    "confidence": 0.9,
                }
            ],
        ),
    )
    enqueue_job(database, outbox_event_id=exposure_event)
    assert run_one(database) == "succeeded"

    attempt_event = enqueue_producer_event(
        database,
        aggregate_type="attempt",
        event_type="mission.attempt_graded",
        payload=attempt_payload(
            user_id,
            [
                {
                    "concept_id": str(concept_id),
                    "concept_version_id": str(version_id),
                    "score": 0.9,
                    "confidence": 0.85,
                }
            ],
        ),
        observed_at=NOW - timedelta(minutes=30),
    )
    enqueue_job(database, outbox_event_id=attempt_event)
    assert run_one(database) == "succeeded"

    with database.begin() as connection:
        row = (
            connection.execute(
                text(
                    """
                    SELECT event_type, source_type, score, is_eligible
                    FROM memory_events
                    WHERE user_id = :u AND event_type = 'attempt'
                    """
                ),
                {"u": str(user_id)},
            )
            .mappings()
            .one()
        )
        review_count = connection.execute(
            text(
                "SELECT eligible_review_count FROM learner_concept_states"
                " WHERE user_id = :u AND concept_id = CAST(:c AS uuid)"
            ),
            {"u": str(user_id), "c": str(concept_id)},
        ).scalar_one()
    assert row["source_type"] == "attempt"
    assert float(row["score"]) == pytest.approx(0.9)
    assert row["is_eligible"]
    assert review_count == 1


def test_ineligible_evidence_is_recorded_without_a_decision(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    payload = attempt_payload(
        user_id,
        [
            {
                "concept_id": str(concept_id),
                "concept_version_id": str(version_id),
                "score": 1.0,
                "confidence": 0.9,
                "is_eligible": False,
                "ineligibility_reason": "rapid_guess",
            }
        ],
    )
    event_id = enqueue_producer_event(
        database,
        aggregate_type="attempt",
        event_type="mission.attempt_graded",
        payload=payload,
    )
    enqueue_job(database, outbox_event_id=event_id)

    assert run_one(database) == "succeeded"

    assert counts(database, user_id) == (1, 0, 0)
    with database.begin() as connection:
        row = (
            connection.execute(
                text(
                    "SELECT is_eligible, ineligibility_reason FROM memory_events WHERE user_id = :u"
                ),
                {"u": str(user_id)},
            )
            .mappings()
            .one()
        )
    assert not row["is_eligible"]
    assert row["ineligibility_reason"] == "rapid_guess"


def test_unknown_event_type_is_skipped_successfully(database: Engine) -> None:
    user_id = create_user(database)
    event_id = enqueue_producer_event(
        database,
        aggregate_type="curriculum",
        event_type="curriculum.concept_approved",
        payload={"schema_version": "1", "concept_id": str(uuid4())},
    )
    job_id = enqueue_job(database, outbox_event_id=event_id)

    assert run_one(database) == "succeeded"
    assert job_status(database, job_id)["status"] == "succeeded"
    assert counts(database, user_id) == (0, 0, 0)


# ---------------------------------------------------------------------------
# failure handling
# ---------------------------------------------------------------------------


def test_malformed_envelope_dead_letters_and_queue_keeps_moving(
    database: Engine,
) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    broken_event = enqueue_producer_event(
        database,
        aggregate_type="learning_update",
        event_type="learning_update.committed",
        payload={"schema_version": "1", "user_id": str(user_id)},
    )
    broken_job = enqueue_job(database, outbox_event_id=broken_event)

    assert run_one(database) == "dead_lettered"
    status = job_status(database, broken_job)
    assert status["status"] == "dead_lettered"
    assert status["last_error_code"] == "invalid_event_payload"
    assert counts(database, user_id) == (0, 0, 0)

    good_event = enqueue_producer_event(
        database,
        aggregate_type="learning_update",
        event_type="learning_update.committed",
        payload=exposure_payload(
            user_id,
            [
                {
                    "concept_id": str(concept_id),
                    "concept_version_id": str(version_id),
                    "confidence": 0.9,
                }
            ],
        ),
    )
    enqueue_job(database, outbox_event_id=good_event)
    assert run_one(database) == "succeeded"
    assert counts(database, user_id) == (1, 1, 1)


def test_poison_job_payload_dead_letters_immediately(database: Engine) -> None:
    job_id = enqueue_job(database, outbox_event_id=uuid4(), payload={"schema_version": "1"})
    assert run_one(database) == "dead_lettered"
    assert job_status(database, job_id)["last_error_code"] == "invalid_event_payload"


def test_missing_source_event_dead_letters(database: Engine) -> None:
    job_id = enqueue_job(database, outbox_event_id=uuid4())
    assert run_one(database) == "dead_lettered"
    assert job_status(database, job_id)["last_error_code"] == "source_event_missing"


def test_malformed_payload_content_is_never_logged(
    database: Engine, caplog: pytest.LogCaptureFixture
) -> None:
    user_id = create_user(database)
    sentinel = "LEARNING-TEXT-MUST-NOT-APPEAR"
    event_id = enqueue_producer_event(
        database,
        aggregate_type="learning_update",
        event_type="learning_update.committed",
        payload={"schema_version": "1", "user_id": str(user_id), "note": sentinel},
    )
    enqueue_job(database, outbox_event_id=event_id)

    # Running the migration fixture calls logging.config.fileConfig with the
    # default disable_existing_loggers=True, so re-enable the worker logger.
    worker_logger = logging.getLogger("memora.worker.memory")
    worker_logger.disabled = False
    with caplog.at_level(logging.WARNING, logger="memora.worker.memory"):
        assert run_one(database) == "dead_lettered"
    assert sentinel not in caplog.text
    assert "invalid_event_payload" in caplog.text


def test_retryable_failure_backs_off_then_dead_letters(database: Engine) -> None:
    # A valid envelope for a learner that does not exist fails inside the
    # memory write (FK violation), which is a retryable processing failure.
    concept_id, version_id = seed_concept(database)
    event_id = enqueue_producer_event(
        database,
        aggregate_type="learning_update",
        event_type="learning_update.committed",
        payload=exposure_payload(
            uuid4(),
            [
                {
                    "concept_id": str(concept_id),
                    "concept_version_id": str(version_id),
                    "confidence": 0.9,
                }
            ],
        ),
    )
    job_id = enqueue_job(database, outbox_event_id=event_id, max_attempts=2)

    assert run_one(database) == "retry_wait"
    first = job_status(database, job_id)
    assert first["status"] == "retry_wait"
    assert first["attempt_count"] == 1
    assert first["last_error_code"] == "processing_failed"
    assert first["available_at"] > NOW

    # The backoff keeps the job out of the claim window.
    assert run_one(database) == "idle"

    assert run_one(database, now=first["available_at"]) == "dead_lettered"
    final = job_status(database, job_id)
    assert final["status"] == "dead_lettered"
    assert final["attempt_count"] == 2


# ---------------------------------------------------------------------------
# duplicate delivery, leases and reconcile
# ---------------------------------------------------------------------------


def test_duplicate_job_delivery_converges(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    event_id = enqueue_producer_event(
        database,
        aggregate_type="learning_update",
        event_type="learning_update.committed",
        payload=exposure_payload(
            user_id,
            [
                {
                    "concept_id": str(concept_id),
                    "concept_version_id": str(version_id),
                    "confidence": 0.9,
                }
            ],
        ),
    )
    enqueue_job(database, outbox_event_id=event_id, dedupe_key=f"memory:outbox:{event_id}:a")
    assert run_one(database) == "succeeded"

    enqueue_job(database, outbox_event_id=event_id, dedupe_key=f"memory:outbox:{event_id}:b")
    assert run_one(database) == "succeeded"

    assert counts(database, user_id) == (1, 1, 1)
    assert scheduled_outbox_count(database, user_id) == 1


def test_reconcile_enqueues_each_event_once_and_processes(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    enqueue_producer_event(
        database,
        aggregate_type="learning_update",
        event_type="learning_update.committed",
        payload=exposure_payload(
            user_id,
            [
                {
                    "concept_id": str(concept_id),
                    "concept_version_id": str(version_id),
                    "confidence": 0.9,
                }
            ],
        ),
    )

    with database.begin() as connection:
        assert enqueue_outbox_backlog(connection, now=NOW) == 1
        assert enqueue_outbox_backlog(connection, now=NOW) == 0

    assert run_one(database) == "succeeded"
    assert counts(database, user_id) == (1, 1, 1)


def test_reconcile_does_not_resurrect_dead_lettered_events(database: Engine) -> None:
    user_id = create_user(database)
    event_id = enqueue_producer_event(
        database,
        aggregate_type="learning_update",
        event_type="learning_update.committed",
        payload={"schema_version": "1", "user_id": str(user_id)},
    )
    job_id = enqueue_job(database, outbox_event_id=event_id)
    assert run_one(database) == "dead_lettered"

    with database.begin() as connection:
        assert enqueue_outbox_backlog(connection, now=NOW) == 0
    assert job_status(database, job_id)["status"] == "dead_lettered"


def test_expired_lease_is_recovered_and_reclaimed(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    event_id = enqueue_producer_event(
        database,
        aggregate_type="learning_update",
        event_type="learning_update.committed",
        payload=exposure_payload(
            user_id,
            [
                {
                    "concept_id": str(concept_id),
                    "concept_version_id": str(version_id),
                    "confidence": 0.9,
                }
            ],
        ),
    )
    job_id = enqueue_job(database, outbox_event_id=event_id, status="leased")
    with database.begin() as connection:
        connection.execute(
            text(
                "UPDATE background_jobs SET lease_owner = 'ghost',"
                " lease_expires_at = CAST(:expired_at AS timestamptz)"
                " WHERE id = CAST(:id AS uuid)"
            ),
            {"id": str(job_id), "expired_at": NOW - timedelta(minutes=1)},
        )

    with database.begin() as connection:
        assert recover_expired_leases(connection, now=NOW) == 1
    assert job_status(database, job_id)["status"] == "queued"

    # The recovered job is claimable again and completes exactly once.
    assert run_one(database) == "succeeded"
    assert counts(database, user_id) == (1, 1, 1)


def test_expired_lease_at_max_attempts_dead_letters(database: Engine) -> None:
    event_id = enqueue_producer_event(
        database,
        aggregate_type="learning_update",
        event_type="learning_update.committed",
        payload={"schema_version": "1", "user_id": str(uuid4())},
    )
    job_id = enqueue_job(
        database,
        outbox_event_id=event_id,
        status="leased",
        attempt_count=5,
        max_attempts=5,
    )
    with database.begin() as connection:
        connection.execute(
            text(
                "UPDATE background_jobs SET lease_owner = 'ghost',"
                " lease_expires_at = CAST(:expired_at AS timestamptz)"
                " WHERE id = CAST(:id AS uuid)"
            ),
            {"id": str(job_id), "expired_at": NOW - timedelta(minutes=1)},
        )
        assert recover_expired_leases(connection, now=NOW) == 1

    status = job_status(database, job_id)
    assert status["status"] == "dead_lettered"
    assert status["last_error_code"] == "lease_expired"


def test_run_loop_reconciles_then_processes(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    enqueue_producer_event(
        database,
        aggregate_type="learning_update",
        event_type="learning_update.committed",
        payload=exposure_payload(
            user_id,
            [
                {
                    "concept_id": str(concept_id),
                    "concept_version_id": str(version_id),
                    "confidence": 0.9,
                }
            ],
        ),
    )

    worker_memory.run_worker(database, poll_seconds=0, reconcile_seconds=0, stop_after_cycles=2)

    assert counts(database, user_id) == (1, 1, 1)


# ---------------------------------------------------------------------------
# role boundaries
# ---------------------------------------------------------------------------


def test_worker_role_can_enqueue_and_claim(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    enqueue_producer_event(
        database,
        aggregate_type="learning_update",
        event_type="learning_update.committed",
        payload=exposure_payload(
            user_id,
            [
                {
                    "concept_id": str(concept_id),
                    "concept_version_id": str(version_id),
                    "confidence": 0.9,
                }
            ],
        ),
    )

    with database.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_worker"))
        assert connection.scalar(text("SELECT current_user")) == "memora_worker"
        assert enqueue_outbox_backlog(connection, now=NOW) == 1
        claimed = claim_job(
            connection,
            job_types=(JOB_TYPE_MEMORY_PROCESS_EVENT,),
            now=NOW,
            lease_owner=OWNER,
        )
    assert claimed is not None


def test_apply_transaction_uses_learner_scoped_role(
    database: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    event_id = enqueue_producer_event(
        database,
        aggregate_type="learning_update",
        event_type="learning_update.committed",
        payload=exposure_payload(
            user_id,
            [
                {
                    "concept_id": str(concept_id),
                    "concept_version_id": str(version_id),
                    "confidence": 0.9,
                }
            ],
        ),
    )
    enqueue_job(database, outbox_event_id=event_id)

    seen: dict[str, object] = {}

    def spy(connection, **kwargs):  # type: ignore[no-untyped-def]
        seen["role"] = connection.scalar(text("SELECT current_user"))
        seen["user"] = connection.scalar(text("SELECT current_setting('memora.user_id', true)"))
        seen["visible_states"] = connection.scalar(
            text("SELECT count(*) FROM learner_concept_states")
        )
        return PrerequisiteSignal()

    monkeypatch.setattr(worker_memory, "collect_prerequisite_signal", spy)

    assert run_one(database) == "succeeded"
    assert seen["role"] == "memora_api"
    assert seen["user"] == str(user_id)
    # RLS scopes the session to the envelope's learner.
    assert seen["visible_states"] == 0


# ---------------------------------------------------------------------------
# review fix 3: a concept can never be paired with another concept's version
# ---------------------------------------------------------------------------


def test_mismatched_concept_version_pair_dead_letters_and_queue_moves(
    database: Engine,
) -> None:
    user_id = create_user(database)
    concept_id, _version_id = seed_concept(database)
    payload = exposure_payload(
        user_id,
        [
            {
                "concept_id": str(concept_id),
                "concept_version_id": str(uuid4()),
                "confidence": 0.9,
            }
        ],
    )
    broken_event = enqueue_producer_event(
        database,
        aggregate_type="learning_update",
        event_type="learning_update.committed",
        payload=payload,
    )
    broken_job = enqueue_job(database, outbox_event_id=broken_event)

    assert run_one(database) == "dead_lettered"
    status = job_status(database, broken_job)
    assert status["status"] == "dead_lettered"
    assert status["last_error_code"] == "invalid_event_payload"
    assert counts(database, user_id) == (0, 0, 0)

    good_event = enqueue_producer_event(
        database,
        aggregate_type="learning_update",
        event_type="learning_update.committed",
        payload=exposure_payload(
            user_id,
            [
                {
                    "concept_id": str(concept_id),
                    "concept_version_id": str(seed_concept(database)[1]),
                    "confidence": 0.9,
                }
            ],
        ),
    )
    enqueue_job(database, outbox_event_id=good_event)
    assert run_one(database) == "succeeded"
    assert counts(database, user_id) == (1, 1, 1)
