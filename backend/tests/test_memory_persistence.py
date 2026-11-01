"""PostgreSQL contracts for memory events, decisions and concept snapshots.

Proves the T11 persistence acceptance surface: append-only evidence, one
authoritative decision per trigger event, concept isolation, RLS owner
scoping, the worker role boundary, closed reason-code allowlists and the
migration round trip. Skips unless MEMORA_TEST_DATABASE_URL targets a
disposable database.
"""

from __future__ import annotations

import dataclasses
import json
import os
import threading
from collections.abc import Iterator
from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import Engine, create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.exc import DBAPIError, IntegrityError

from memora.modules.memory.constants import EVENT_ATTEMPT, EVENT_EXPOSURE, EVENT_INVALIDATION
from memora.modules.memory.engine.config import DEFAULT_ENGINE_CONFIG
from memora.modules.memory.engine.decide import EventFacts
from memora.modules.memory.engine.policy import decide_with_policy
from memora.modules.memory.engine.state import LearnerConceptState
from memora.modules.memory.repository import (
    BOOTSTRAP_PREVIOUS_STATE_SCHEMA,
    OUTBOX_EVENT_TYPE,
    MemoryRepository,
)

BACKEND_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DISPOSABLE_DATABASE_SUFFIXES = ("_test", "_ci")
ISSUER = "https://memory-persistence.test"
NOW = datetime(2026, 10, 29, 12, 0, 0, tzinfo=UTC)
DAY_0 = datetime(2026, 10, 28, 9, 0, 0, tzinfo=UTC)
DAY_1 = datetime(2026, 10, 29, 8, 0, 0, tzinfo=UTC)


def alembic_config(database_url: str) -> Config:
    config = Config(os.path.join(BACKEND_ROOT, "alembic.ini"))
    config.set_main_option("script_location", os.path.join(BACKEND_ROOT, "migrations"))
    config.set_main_option("sqlalchemy.url", database_url.replace("%", "%%"))
    return config


@pytest.fixture
def database(monkeypatch: pytest.MonkeyPatch) -> Iterator[Engine]:
    """Use only a disposable database and move it to the reviewable schema head."""

    database_url = os.getenv("MEMORA_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("MEMORA_TEST_DATABASE_URL is not configured")

    try:
        database_name = make_url(database_url).database or ""
    except Exception:
        pytest.fail("MEMORA_TEST_DATABASE_URL is not a valid SQLAlchemy URL", pytrace=False)

    if not database_name.endswith(DISPOSABLE_DATABASE_SUFFIXES):
        pytest.fail(
            "MEMORA_TEST_DATABASE_URL must target a disposable database ending in "
            f"{' or '.join(DISPOSABLE_DATABASE_SUFFIXES)}",
            pytrace=False,
        )

    monkeypatch.setenv("MEMORA_DATABASE_URL", database_url)
    command.upgrade(alembic_config(database_url), "head")
    from memora.db.seed import seed_database

    seed_database(database_url)
    engine = create_engine(database_url, connect_args={"connect_timeout": 10})
    try:
        yield engine
    finally:
        engine.dispose()


def create_user(engine: Engine) -> UUID:
    with engine.begin() as connection:
        user_id = connection.scalar(
            text(
                """
                INSERT INTO users(
                    oidc_issuer, oidc_subject, status, default_timezone, locale
                ) VALUES (:issuer, :subject, 'active', 'Asia/Colombo', 'en')
                RETURNING id
                """
            ),
            {"issuer": ISSUER, "subject": f"synthetic-{uuid4()}"},
        )
    return UUID(str(user_id))


def seed_concept(engine: Engine) -> tuple[UUID, UUID]:
    with engine.begin() as connection:
        row = (
            connection.execute(
                text(
                    """
                    SELECT c.id AS concept_id, cv.id AS version_id
                    FROM concepts c
                    JOIN concept_versions cv ON cv.concept_id = c.id
                    WHERE c.status = 'approved' AND cv.content_status = 'approved'
                    ORDER BY c.created_at, cv.version_no
                    LIMIT 1
                    """
                )
            )
            .mappings()
            .one()
        )
    return UUID(str(row["concept_id"])), UUID(str(row["version_id"]))


def exposure(
    source_id: UUID | None = None, observed_at: datetime = DAY_0
) -> tuple[EventFacts, UUID]:
    source = source_id or uuid4()
    return (
        EventFacts(
            event_type=EVENT_EXPOSURE,
            observed_at=observed_at,
            confidence=0.9,
        ),
        source,
    )


def attempt(
    score: float,
    source_id: UUID | None = None,
    observed_at: datetime = DAY_1,
    confidence: float = 0.9,
) -> tuple[EventFacts, UUID]:
    source = source_id or uuid4()
    return (
        EventFacts(
            event_type=EVENT_ATTEMPT,
            observed_at=observed_at,
            confidence=confidence,
            score=score,
        ),
        source,
    )


def apply(
    engine: Engine,
    *,
    user_id: UUID,
    concept_id: UUID,
    concept_version_id: UUID,
    event: EventFacts,
    source_id: UUID,
    source_type: str = "synthetic_source",
    now: datetime = NOW,
):
    repository = MemoryRepository(engine)
    return repository.apply_event(
        user_id=user_id,
        concept_id=concept_id,
        active_concept_version_id=concept_version_id,
        event=event,
        source_type=source_type,
        source_id=source_id,
        correlation_id=uuid4(),
        now=now,
    )


def state_row(engine: Engine, user_id: UUID, concept_id: UUID) -> dict:
    with engine.begin() as connection:
        row = (
            connection.execute(
                text(
                    """
                    SELECT * FROM learner_concept_states
                    WHERE user_id = :user_id AND concept_id = :concept_id
                    """
                ),
                {"user_id": str(user_id), "concept_id": str(concept_id)},
            )
            .mappings()
            .first()
        )
    return dict(row) if row else {}


# ---------------------------------------------------------------------------
# full flow: event + decision + snapshot + outbox in one transaction
# ---------------------------------------------------------------------------


def test_apply_event_bootstraps_exposure_decision(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    event, source_id = exposure()

    recorded, decision = apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=event,
        source_id=source_id,
    )

    assert not recorded.replayed
    assert not decision.replayed
    assert decision.trigger_event_id == recorded.event_id
    assert decision.outbox_event_id is not None
    assert decision.state_row_version == 1

    state = state_row(database, user_id, concept_id)
    assert state, "learner concept snapshot must exist after the first event"
    assert state["active_concept_version_id"] == version_id
    assert float(state["stability_days"]) == pytest.approx(
        DEFAULT_ENGINE_CONFIG.exposure_initial_stability_days, abs=1e-4
    )
    assert state["next_review_at"] == decision.next_review_at
    assert state["engine_version"] == DEFAULT_ENGINE_CONFIG.engine_version

    with database.begin() as connection:
        decision_row = (
            connection.execute(
                text("SELECT * FROM memory_decisions WHERE id = :id"),
                {"id": str(decision.decision_id)},
            )
            .mappings()
            .one()
        )
        outbox = (
            connection.execute(
                text(
                    """
                    SELECT domain_event_key, event_type, publication_status, payload
                    FROM outbox_events WHERE id = :id
                    """
                ),
                {"id": str(decision.outbox_event_id)},
            )
            .mappings()
            .one()
        )

    assert decision_row["previous_state"]["schema_version"] == BOOTSTRAP_PREVIOUS_STATE_SCHEMA
    assert decision_row["result_state"]["schema_version"] == "memora.memory_state/1"
    assert decision_row["next_review_at"] == decision.next_review_at
    assert outbox["event_type"] == OUTBOX_EVENT_TYPE
    assert outbox["publication_status"] == "pending"
    assert outbox["payload"]["user_id"] == str(user_id)
    assert outbox["payload"]["concept_id"] == str(concept_id)
    assert outbox["payload"]["reason_codes"] == list(decision.reason_codes)
    # Identifiers and safe scheduling facts only.
    assert "manual_text" not in outbox["payload"]


def test_scored_event_updates_the_snapshot_and_appends_history(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    exposure_event, exposure_source = exposure()
    attempt_event, attempt_source = attempt(0.9)

    _, first = apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=exposure_event,
        source_id=exposure_source,
    )
    _, second = apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=attempt_event,
        source_id=attempt_source,
    )

    assert second.state_row_version == first.state_row_version + 1
    state = state_row(database, user_id, concept_id)
    assert state["last_reviewed_at"] == attempt_event.observed_at
    assert state["eligible_review_count"] == 1

    with database.begin() as connection:
        decision_row = (
            connection.execute(
                text("SELECT previous_state, result_state FROM memory_decisions WHERE id = :id"),
                {"id": str(second.decision_id)},
            )
            .mappings()
            .one()
        )
    previous = LearnerConceptState.from_snapshot(dict(decision_row["previous_state"]))
    result = LearnerConceptState.from_snapshot(dict(decision_row["result_state"]))
    assert previous.next_review_at == first.next_review_at
    assert result.stability_days > previous.stability_days


# ---------------------------------------------------------------------------
# duplicate delivery converges (D6)
# ---------------------------------------------------------------------------


def test_duplicate_delivery_replays_without_new_side_effects(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    event, source_id = exposure()

    _, first = apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=event,
        source_id=source_id,
    )
    # Redelivered producer event, different decision-time inputs.
    event_later, same_source = exposure(source_id=source_id, observed_at=DAY_1)
    recorded_second, second = apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=event_later,
        source_id=same_source,
    )

    assert recorded_second.replayed
    assert second.replayed
    assert second.decision_id == first.decision_id
    assert second.outbox_event_id is None
    assert second.state_row_version == first.state_row_version

    state = state_row(database, user_id, concept_id)
    assert state["next_review_at"] == first.next_review_at
    assert state["row_version"] == first.state_row_version

    with database.begin() as connection:
        events = connection.execute(
            text("SELECT count(*) FROM memory_events WHERE user_id = :user_id"),
            {"user_id": str(user_id)},
        ).scalar_one()
        decisions = connection.execute(
            text("SELECT count(*) FROM memory_decisions WHERE user_id = :user_id"),
            {"user_id": str(user_id)},
        ).scalar_one()
        outbox = connection.execute(
            text(
                """
                SELECT count(*) FROM outbox_events
                WHERE event_type = :event_type
                  AND aggregate_id = :aggregate_id
                  AND payload->>'user_id' = :user_id
                """
            ),
            {
                "event_type": OUTBOX_EVENT_TYPE,
                "aggregate_id": str(first.decision_id),
                "user_id": str(user_id),
            },
        ).scalar_one()
    assert (events, decisions, outbox) == (1, 1, 1)


def test_concurrent_duplicate_delivery_converges(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    event, source_id = exposure()

    barrier = threading.Barrier(2)
    results: list[tuple] = []
    failures: list[BaseException] = []

    def deliver() -> None:
        try:
            barrier.wait(timeout=15)
            results.append(
                apply(
                    database,
                    user_id=user_id,
                    concept_id=concept_id,
                    concept_version_id=version_id,
                    event=event,
                    source_id=source_id,
                )
            )
        except BaseException as error:  # pragma: no cover - asserted below
            failures.append(error)

    threads = [threading.Thread(target=deliver) for _ in range(2)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join(timeout=30)

    assert not any(thread.is_alive() for thread in threads)
    assert failures == []
    assert len(results) == 2

    recorded = [result[0] for result in results]
    decisions = [result[1] for result in results]
    assert sorted(item.replayed for item in recorded) == [False, True]
    assert len({item.event_id for item in recorded}) == 1
    assert decisions[0].decision_id == decisions[1].decision_id
    assert sorted(item.replayed for item in decisions) == [False, True]
    outbox_ids = [item.outbox_event_id for item in decisions]
    assert sum(item is not None for item in outbox_ids) == 1

    with database.begin() as connection:
        counts = (
            connection.execute(
                text(
                    """
                    SELECT
                      (SELECT count(*) FROM memory_events WHERE user_id = :user_id) AS events,
                      (SELECT count(*) FROM memory_decisions WHERE user_id = :user_id) AS decisions,
                      (SELECT count(*) FROM outbox_events
                        WHERE event_type = :event_type
                          AND payload->>'user_id' = CAST(:user_id AS text)) AS outbox
                    """
                ),
                {"user_id": str(user_id), "event_type": OUTBOX_EVENT_TYPE},
            )
            .mappings()
            .one()
        )
    assert (counts["events"], counts["decisions"], counts["outbox"]) == (1, 1, 1)
    assert state_row(database, user_id, concept_id)["row_version"] == 1


def test_schedule_changed_domain_event_key_is_unique(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    event, source_id = exposure()
    _, decision = apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=event,
        source_id=source_id,
    )

    with database.begin() as connection:
        row = (
            connection.execute(
                text(
                    """
                    SELECT domain_event_key, aggregate_type, aggregate_id
                    FROM outbox_events
                    WHERE event_type = :event_type AND payload->>'user_id' = :user_id
                    """
                ),
                {"event_type": OUTBOX_EVENT_TYPE, "user_id": str(user_id)},
            )
            .mappings()
            .one()
        )

    assert row["domain_event_key"] == f"{OUTBOX_EVENT_TYPE}:{user_id}:{decision.decision_id}"
    assert row["aggregate_type"] == "memory_decision"
    assert UUID(str(row["aggregate_id"])) == decision.decision_id

    # Re-publishing the same decision identity cannot create a second event.
    with pytest.raises(IntegrityError), database.begin() as connection:
        connection.execute(
            text(
                """
                INSERT INTO outbox_events(
                    domain_event_key, aggregate_type, aggregate_id, event_type,
                    event_version, payload, correlation_id, publication_status
                ) VALUES (
                    :domain_event_key, 'memory_decision', :aggregate_id,
                    :event_type, 1, '{}'::jsonb, :correlation_id, 'pending'
                )
                """
            ),
            {
                "domain_event_key": row["domain_event_key"],
                "aggregate_id": str(decision.decision_id),
                "event_type": OUTBOX_EVENT_TYPE,
                "correlation_id": str(uuid4()),
            },
        )


# ---------------------------------------------------------------------------
# invalidation is metadata, never a transition
# ---------------------------------------------------------------------------


def test_invalidation_appends_evidence_without_a_decision(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    event, source_id = exposure()
    original, original_decision = apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=event,
        source_id=source_id,
    )
    original_state = state_row(database, user_id, concept_id)
    with database.begin() as connection:
        original_event_row = dict(
            connection.execute(
                text("SELECT * FROM memory_events WHERE id = :id"),
                {"id": str(original.event_id)},
            )
            .mappings()
            .one()
        )
        original_decision_row = dict(
            connection.execute(
                text("SELECT * FROM memory_decisions WHERE id = :id"),
                {"id": str(original_decision.decision_id)},
            )
            .mappings()
            .one()
        )

    invalidating = EventFacts(
        event_type=EVENT_INVALIDATION,
        observed_at=DAY_1,
        confidence=0.9,
    )
    invalidation_source = uuid4()
    recorded, decision = apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=invalidating,
        source_id=invalidation_source,
    )

    assert decision is None
    assert not recorded.replayed
    assert recorded.event_id != original.event_id

    # A redelivery of the same invalidation converges without another row.
    replayed, replayed_decision = apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=invalidating,
        source_id=invalidation_source,
    )
    assert replayed.replayed
    assert replayed.event_id == recorded.event_id
    assert replayed_decision is None

    # The snapshot, the original evidence and the original decision are intact.
    assert state_row(database, user_id, concept_id) == original_state
    with database.begin() as connection:
        kept_event = dict(
            connection.execute(
                text("SELECT * FROM memory_events WHERE id = :id"),
                {"id": str(original.event_id)},
            )
            .mappings()
            .one()
        )
        kept_decision = dict(
            connection.execute(
                text("SELECT * FROM memory_decisions WHERE id = :id"),
                {"id": str(original_decision.decision_id)},
            )
            .mappings()
            .one()
        )
        event_types = (
            connection.execute(
                text(
                    """
                    SELECT event_type FROM memory_events
                    WHERE user_id = :user_id
                    ORDER BY observed_at, id
                    """
                ),
                {"user_id": str(user_id)},
            )
            .scalars()
            .all()
        )
        decisions = connection.execute(
            text("SELECT count(*) FROM memory_decisions WHERE user_id = :user_id"),
            {"user_id": str(user_id)},
        ).scalar_one()
        outbox = connection.execute(
            text(
                """
                SELECT count(*) FROM outbox_events
                WHERE event_type = :event_type AND payload->>'user_id' = :user_id
                """
            ),
            {"event_type": OUTBOX_EVENT_TYPE, "user_id": str(user_id)},
        ).scalar_one()

    assert kept_event == original_event_row
    assert kept_decision == original_decision_row
    assert kept_event["event_type"] == EVENT_EXPOSURE
    assert kept_event["score"] is None
    assert kept_event["event_payload"]["schema_version"] == "1"
    assert event_types == [EVENT_EXPOSURE, EVENT_INVALIDATION]
    assert decisions == 1
    assert outbox == 1
    assert original_decision.outbox_event_id is not None


# ---------------------------------------------------------------------------
# engine versioning keeps history immutable and readable
# ---------------------------------------------------------------------------


def test_engine_version_bump_never_mutates_history(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    event, source_id = exposure()
    _, first = apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=event,
        source_id=source_id,
    )

    with database.begin() as connection:
        first_row = dict(
            connection.execute(
                text("SELECT * FROM memory_decisions WHERE id = :id"),
                {"id": str(first.decision_id)},
            )
            .mappings()
            .one()
        )

    bumped_version = "fsrs-mvp-1.0.1"
    bumped_config = dataclasses.replace(
        DEFAULT_ENGINE_CONFIG,
        engine_version=bumped_version,
        # A real behavioural change must travel with the version bump.
        recall_gain=1.0,
    )
    bumped_config.validate()
    attempt_event, attempt_source = attempt(0.9)
    _, second = MemoryRepository(database, config=bumped_config).apply_event(
        user_id=user_id,
        concept_id=concept_id,
        active_concept_version_id=version_id,
        event=attempt_event,
        source_type="synthetic_source",
        source_id=attempt_source,
        correlation_id=uuid4(),
        now=NOW,
    )

    assert second.engine_version == bumped_version
    assert second.decision_id != first.decision_id

    baseline_state = LearnerConceptState.from_snapshot(dict(first_row["result_state"]))
    baseline = decide_with_policy(
        baseline_state, attempt_event, now=NOW, config=DEFAULT_ENGINE_CONFIG
    )
    assert second.next_review_at != baseline.next_review_at

    with database.begin() as connection:
        kept = dict(
            connection.execute(
                text("SELECT * FROM memory_decisions WHERE id = :id"),
                {"id": str(first.decision_id)},
            )
            .mappings()
            .one()
        )
        state_engine_version = connection.execute(
            text(
                """
                SELECT engine_version FROM learner_concept_states
                WHERE user_id = :user_id AND concept_id = :concept_id
                """
            ),
            {"user_id": str(user_id), "concept_id": str(concept_id)},
        ).scalar_one()
        second_row = (
            connection.execute(
                text(
                    """
                    SELECT previous_state, result_state
                    FROM memory_decisions WHERE id = :id
                    """
                ),
                {"id": str(second.decision_id)},
            )
            .mappings()
            .one()
        )
        historical = (
            connection.execute(
                text(
                    """
                    SELECT previous_state, result_state
                    FROM memory_decisions WHERE id = :id
                    """
                ),
                {"id": str(first.decision_id)},
            )
            .mappings()
            .one()
        )

    # The older decision row is byte-identical after the version bump.
    assert kept == first_row
    assert kept["engine_version"] == DEFAULT_ENGINE_CONFIG.engine_version
    # New writes carry the bumped identity, including the stored state row.
    assert state_engine_version == bumped_version
    assert second_row["result_state"]["engine_version"] == bumped_version
    # The previous snapshot keeps the identity of the engine that produced it.
    assert second_row["previous_state"]["engine_version"] == (DEFAULT_ENGINE_CONFIG.engine_version)
    # Historical snapshots stay readable under the same schema.
    assert LearnerConceptState.from_snapshot(dict(historical["result_state"]))
    assert LearnerConceptState.from_snapshot(dict(second_row["previous_state"]))
    assert LearnerConceptState.from_snapshot(dict(second_row["result_state"]))


# ---------------------------------------------------------------------------
# concept and learner isolation (PRD 011)
# ---------------------------------------------------------------------------


def test_one_concept_update_never_touches_another(database: Engine) -> None:
    user_id = create_user(database)
    concept_a, version_a = seed_concept(database)
    with database.begin() as connection:
        concept_b = connection.scalar(
            text(
                """
                SELECT c.id FROM concepts c
                JOIN concept_versions cv ON cv.concept_id = c.id
                WHERE c.status = 'approved' AND cv.content_status = 'approved'
                  AND c.id <> :excluded
                ORDER BY c.created_at
                LIMIT 1
                """
            ),
            {"excluded": str(concept_a)},
        )
        version_b = connection.scalar(
            text(
                """
                SELECT id FROM concept_versions
                WHERE concept_id = :concept_id AND content_status = 'approved'
                ORDER BY version_no LIMIT 1
                """
            ),
            {"concept_id": str(concept_b)},
        )
    concept_b, version_b = UUID(str(concept_b)), UUID(str(version_b))

    event_a, source_a = exposure()
    apply(
        database,
        user_id=user_id,
        concept_id=concept_a,
        concept_version_id=version_a,
        event=event_a,
        source_id=source_a,
    )
    event_b, source_b = exposure()
    apply(
        database,
        user_id=user_id,
        concept_id=concept_b,
        concept_version_id=version_b,
        event=event_b,
        source_id=source_b,
    )
    attempt_a, attempt_source_a = attempt(0.9)
    apply(
        database,
        user_id=user_id,
        concept_id=concept_a,
        concept_version_id=version_a,
        event=attempt_a,
        source_id=attempt_source_a,
    )

    state_a = state_row(database, user_id, concept_a)
    state_b = state_row(database, user_id, concept_b)
    # Concept B keeps its bootstrap state: concept A's review never leaked.
    assert state_b["row_version"] == 1
    assert state_b["eligible_review_count"] == 0
    assert state_a["eligible_review_count"] == 1


def test_learners_are_isolated_for_the_same_concept(database: Engine) -> None:
    user_a = create_user(database)
    user_b = create_user(database)
    concept_id, version_id = seed_concept(database)

    event_a, source_a = exposure()
    _, decision_a = apply(
        database,
        user_id=user_a,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=event_a,
        source_id=source_a,
    )
    event_b, source_b = exposure()
    _, decision_b = apply(
        database,
        user_id=user_b,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=event_b,
        source_id=source_b,
    )

    assert decision_a.decision_id != decision_b.decision_id
    assert state_row(database, user_a, concept_id)["row_version"] == 1
    assert state_row(database, user_b, concept_id)["row_version"] == 1


# ---------------------------------------------------------------------------
# append-only evidence and closed allowlists
# ---------------------------------------------------------------------------


def test_memory_evidence_is_append_only(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    event, source_id = exposure()
    apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=event,
        source_id=source_id,
    )

    with pytest.raises(DBAPIError), database.begin() as connection:
        connection.execute(
            text("UPDATE memory_events SET confidence = 0.1 WHERE user_id = :user_id"),
            {"user_id": str(user_id)},
        )
    with pytest.raises(DBAPIError), database.begin() as connection:
        connection.execute(
            text("DELETE FROM memory_events WHERE user_id = :user_id"),
            {"user_id": str(user_id)},
        )


def test_reason_code_allowlist_is_enforced_in_the_database(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    event, source_id = exposure()
    _, decision = apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=event,
        source_id=source_id,
    )

    with database.begin() as connection:
        base = (
            connection.execute(
                text("SELECT * FROM memory_decisions WHERE id = :id"),
                {"id": str(decision.decision_id)},
            )
            .mappings()
            .one()
        )

    def mutated(change: dict) -> dict:
        row = dict(base)
        # A distinct engine version keeps the decision-uniqueness arbiter
        # out of the way so only the allowlist CHECK can fire.
        row["engine_version"] = "allowlist-probe-1.0.0"
        row["id"] = str(uuid4())
        row.update(change)
        return row

    def insert_row(row: dict) -> None:
        with database.begin() as connection:
            connection.execute(
                text(
                    """
                    INSERT INTO memory_decisions(
                        id, user_id, concept_id, trigger_event_id, previous_state,
                        result_state, retrievability_at_decision, next_review_at,
                        reason_codes, explanation_template_key, engine_version,
                        policy_version, decided_at
                    ) VALUES (
                        :id, :user_id, :concept_id, :trigger_event_id,
                        :previous_state, :result_state, :retrievability_at_decision,
                        :next_review_at, :reason_codes, :explanation_template_key,
                        :engine_version, :policy_version, :decided_at
                    )
                    """
                ),
                {
                    "id": str(uuid4()),
                    "user_id": str(row["user_id"]),
                    "concept_id": str(row["concept_id"]),
                    "trigger_event_id": str(row["trigger_event_id"]),
                    "previous_state": json.dumps(row["previous_state"]),
                    "result_state": json.dumps(row["result_state"]),
                    "retrievability_at_decision": row["retrievability_at_decision"],
                    "next_review_at": row["next_review_at"],
                    "reason_codes": row["reason_codes"],
                    "explanation_template_key": row["explanation_template_key"],
                    "engine_version": row["engine_version"],
                    "policy_version": row["policy_version"],
                    "decided_at": row["decided_at"],
                },
            )

    bogus_codes = mutated({"reason_codes": ["totally_unexplained"]})
    with pytest.raises(IntegrityError):
        insert_row(bogus_codes)

    empty_codes = mutated({"reason_codes": []})
    with pytest.raises(IntegrityError):
        insert_row(empty_codes)

    bogus_template = mutated({"explanation_template_key": "memory.explanation.made_up"})
    with pytest.raises(IntegrityError):
        insert_row(bogus_template)


# ---------------------------------------------------------------------------
# role boundaries and RLS
# ---------------------------------------------------------------------------


def test_worker_role_can_execute_functions_but_not_tables(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    event, source_id = exposure()

    for table in ("memory_events", "learner_concept_states"):
        with pytest.raises(DBAPIError), database.begin() as connection:
            connection.execute(text("SET LOCAL ROLE memora_worker"))
            connection.execute(text(f"SELECT count(*) FROM {table}"))

    with database.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_worker"))

        # The worker write surface is the SECURITY DEFINER path only.
        context = connection.scalar(
            text("SELECT memora_memory_context(CAST(:user_id AS uuid), CAST(:concept_id AS uuid))"),
            {"user_id": str(user_id), "concept_id": str(concept_id)},
        )
        assert context is None

        event_row = (
            connection.execute(
                text(
                    """
                    SELECT event_id, replayed FROM memora_memory_record_event(
                        CAST(:user_id AS uuid), CAST(:concept_id AS uuid), :event_type,
                        :source_type, CAST(:source_id AS uuid), CAST(:observed_at AS timestamptz),
                        CAST(NULL AS numeric), CAST(:confidence AS numeric), true, NULL,
                        CAST(:payload AS jsonb)
                    )
                    """
                ),
                {
                    "user_id": str(user_id),
                    "concept_id": str(concept_id),
                    "event_type": event.event_type,
                    "source_type": "synthetic_source",
                    "source_id": str(source_id),
                    "observed_at": event.observed_at,
                    "confidence": event.confidence,
                    "payload": '{"schema_version": "1"}',
                },
            )
            .mappings()
            .one()
        )
        assert not event_row["replayed"]


def test_rls_scopes_memory_rows_to_the_transaction_owner(database: Engine) -> None:
    user_a = create_user(database)
    user_b = create_user(database)
    concept_id, version_id = seed_concept(database)

    for user in (user_a, user_b):
        event, source_id = exposure()
        apply(
            database,
            user_id=user,
            concept_id=concept_id,
            concept_version_id=version_id,
            event=event,
            source_id=source_id,
        )

    with database.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_api"))
        connection.execute(
            text("SELECT set_config('memora.user_id', :user_id, true)"),
            {"user_id": str(user_a)},
        )
        visible_events = connection.execute(text("SELECT count(*) FROM memory_events")).scalar_one()
        visible_states = connection.execute(
            text("SELECT count(*) FROM learner_concept_states")
        ).scalar_one()
        visible_decisions = connection.execute(
            text("SELECT count(*) FROM memory_decisions")
        ).scalar_one()

    assert visible_events == 1
    assert visible_states == 1
    assert visible_decisions == 1


def test_transaction_local_user_context_does_not_leak(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    event, source_id = exposure()
    apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=event,
        source_id=source_id,
    )

    # One physical connection, two transactions: SET LOCAL must not survive
    # the first commit and re-scope the second transaction.
    with database.connect() as connection:
        with connection.begin():
            connection.execute(text("SET LOCAL ROLE memora_api"))
            connection.execute(
                text("SELECT set_config('memora.user_id', :user_id, true)"),
                {"user_id": str(user_id)},
            )
            assert connection.execute(text("SELECT count(*) FROM memory_events")).scalar_one() == 1
            assert connection.execute(text("SELECT current_user")).scalar_one() == "memora_api"

        with connection.begin():
            leaked_context = connection.execute(
                text("SELECT current_setting('memora.user_id', true)")
            ).scalar_one()
            assert leaked_context in (None, "")
            assert connection.execute(text("SELECT current_user")).scalar_one() != "memora_api"
            connection.execute(text("SET LOCAL ROLE memora_api"))
            # No owner context in this transaction means no visible rows.
            assert connection.execute(text("SELECT count(*) FROM memory_events")).scalar_one() == 0
            assert (
                connection.execute(text("SELECT count(*) FROM learner_concept_states")).scalar_one()
                == 0
            )


# ---------------------------------------------------------------------------
# migration round trip
# ---------------------------------------------------------------------------


def test_migration_down_and_up_retains_evidence_and_functions(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    event, source_id = exposure()
    _, decision = apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=event,
        source_id=source_id,
    )

    command.downgrade(alembic_config(str(database.url)), "-1")
    command.upgrade(alembic_config(str(database.url)), "head")

    with database.begin() as connection:
        kept = connection.execute(
            text("SELECT count(*) FROM memory_decisions WHERE id = :id"),
            {"id": str(decision.decision_id)},
        ).scalar_one()
        context = connection.scalar(
            text("SELECT memora_memory_context(CAST(:user_id AS uuid), CAST(:concept_id AS uuid))"),
            {"user_id": str(user_id), "concept_id": str(concept_id)},
        )
    assert kept == 1
    assert context is not None
    assert context["engine_version"] == DEFAULT_ENGINE_CONFIG.engine_version

    # The surface keeps working after the round trip.
    attempt_event, attempt_source = attempt(0.9, observed_at=DAY_1)
    recorded, second = apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=attempt_event,
        source_id=attempt_source,
    )
    assert not recorded.replayed
    assert not second.replayed
    assert second.state_row_version == 2


# ---------------------------------------------------------------------------
# review fix 2: stale evidence persists as a no-op decision
# ---------------------------------------------------------------------------


def test_stale_event_persists_without_moving_the_state(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, version_id = seed_concept(database)
    exposure_event, exposure_source = exposure()
    apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=exposure_event,
        source_id=exposure_source,
    )
    attempt_event, attempt_source = attempt(0.9)
    _, newer = apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=attempt_event,
        source_id=attempt_source,
    )
    before = state_row(database, user_id, concept_id)

    stale_event, stale_source = attempt(0.4, observed_at=DAY_0 + timedelta(hours=1))
    recorded, stale_decision = apply(
        database,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=stale_event,
        source_id=stale_source,
    )

    assert not recorded.replayed
    assert stale_decision.reason_codes == ("out_of_order_evidence",)
    assert stale_decision.explanation_template_key == "memory.explanation.evidence_recorded"
    assert stale_decision.next_review_at == newer.next_review_at

    after = state_row(database, user_id, concept_id)
    # The snapshot is untouched apart from the optimistic row_version bump.
    for column in (
        "difficulty",
        "stability_days",
        "last_retrievability",
        "evidence_confidence",
        "first_exposed_at",
        "last_reviewed_at",
        "next_review_at",
        "exposure_count",
        "eligible_review_count",
        "lapse_count",
        "engine_version",
    ):
        assert after[column] == before[column], column
    assert after["row_version"] == before["row_version"] + 1

    with database.begin() as connection:
        decision_row = (
            connection.execute(
                text(
                    "SELECT previous_state, result_state FROM memory_decisions"
                    " WHERE id = CAST(:id AS uuid)"
                ),
                {"id": str(stale_decision.decision_id)},
            )
            .mappings()
            .one()
        )
    assert dict(decision_row["result_state"]) == dict(decision_row["previous_state"])


# ---------------------------------------------------------------------------
# review fix 3: a concept can never be paired with another concept's version
# ---------------------------------------------------------------------------


def test_persistence_rejects_mismatched_concept_version_pair(database: Engine) -> None:
    user_id = create_user(database)
    concept_id, _version_id = seed_concept(database)
    other_concept_id, other_version_id = seed_concept(database)
    assert other_concept_id != concept_id

    event, source_id = exposure()
    with pytest.raises(DBAPIError):
        apply(
            database,
            user_id=user_id,
            concept_id=concept_id,
            concept_version_id=other_version_id,
            event=event,
            source_id=source_id,
        )

    assert state_row(database, user_id, concept_id) == {}
    with database.begin() as connection:
        events = connection.execute(
            text("SELECT count(*) FROM memory_events WHERE user_id = :u"),
            {"u": str(user_id)},
        ).scalar_one()
        decisions = connection.execute(
            text("SELECT count(*) FROM memory_decisions WHERE user_id = :u"),
            {"u": str(user_id)},
        ).scalar_one()
    assert (events, decisions) == (0, 0)
