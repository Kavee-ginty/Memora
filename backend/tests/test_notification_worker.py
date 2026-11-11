"""Worker trigger-consumer contracts for push notifications (T19 Commit 4).

Proves the outbox-to-push path on a disposable database: one job per unseen
trigger event (reconcile never duplicates or resurrects), documented envelope
validation for all six trigger types, due-memories resource resolution
against the recipient's open mission, consume-once across duplicate triggers
and the worker role boundary. Skips unless MEMORA_TEST_DATABASE_URL targets a
disposable database.
"""

from __future__ import annotations

import json
import os
from collections.abc import Iterator
from datetime import UTC, datetime
from uuid import UUID, uuid4

import pytest
from alembic import command
from alembic.config import Config
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from sqlalchemy import Engine, create_engine, text
from sqlalchemy.engine import make_url

from memora.modules.notifications.constants import (
    CATEGORY_DUE_MEMORIES,
    CATEGORY_MISSION_READY,
    CATEGORY_PRIVACY_EXPORT_READY,
    CATEGORY_REWARD_READY,
    CATEGORY_VERIFICATION_REQUIRED,
)
from memora.modules.notifications.providers import ProviderResult
from memora.worker.memory import NonRetryableJobError
from memora.worker.notifications import (
    CODE_INVALID_EVENT_PAYLOAD,
    CODE_OUTBOX_EVENT_MISSING,
    CODE_UNKNOWN_TRIGGER,
    TRIGGER_EVENT_TYPES,
    NotificationDispatcher,
    enqueue_notification_backlog,
    handle_notification_job,
)

BACKEND_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DISPOSABLE_DATABASE_SUFFIXES = ("_test", "_ci")
ISSUER = "https://notification-worker.test"
NOW = datetime(2026, 11, 11, 12, 0, 0, tzinfo=UTC)
TOKEN_KEY = os.urandom(32)
PUSH_TOKEN = "synthetic-worker-push-token"
PHYSICS_SUBJECT_ID = "10000000-0000-0000-0000-000000000001"


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


@pytest.fixture(autouse=True)
def clean_worker_artifacts(database: Engine) -> Iterator[None]:
    """Remove this module's jobs after every test.

    The disposable database persists across tests and runs (T11 lesson:
    shared test databases are never assumed clean). Leftover unprocessed
    notification jobs would otherwise be claimed by unrelated tests that
    drive the shared worker loop. Synthetic trigger events persist too —
    outbox_events is append-only (memora_protect_outbox_event) — but they
    stay inert: only this module enqueues them into jobs, those jobs are
    removed here, and the backlog test scopes its assertion to the
    unseen-event count rather than absolute totals.
    """

    yield
    with database.begin() as connection:
        connection.execute(
            text(
                """
                DELETE FROM background_jobs
                WHERE job_type = 'notification.send'
                   OR dedupe_key LIKE 'notifications:outbox:%'
                """
            )
        )


class RecordingProvider:
    """Records push tokens; returns scripted or default outcomes."""

    def __init__(self) -> None:
        self.tokens: list[str] = []
        self.payloads: list[dict] = []

    def send(self, payload, push_token: str) -> ProviderResult:  # noqa: ANN001
        self.tokens.append(push_token)
        self.payloads.append(
            {
                "category": payload.category,
                "resource_type": payload.resource_type,
                "resource_id": payload.resource_id,
                "notification_id": payload.notification_id,
                "loc_key": payload.loc_key,
            }
        )
        return ProviderResult(outcome="sent", reason_code="sent")


def dispatcher(provider: RecordingProvider) -> NotificationDispatcher:
    return NotificationDispatcher(provider=provider, token_encryption_key=TOKEN_KEY)


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


def encrypt_token(token: str, *, issuer: str, subject: str) -> bytes:
    nonce = os.urandom(12)
    encrypted = AESGCM(TOKEN_KEY).encrypt(nonce, token.encode(), f"{issuer}\0{subject}".encode())
    return b"\x01" + nonce + encrypted


def create_device(engine: Engine, user_id: UUID) -> UUID:
    with engine.begin() as connection:
        subject = connection.scalar(
            text("SELECT oidc_subject FROM users WHERE id = :user_id"), {"user_id": user_id}
        )
        device_id = connection.scalar(
            text(
                """
                INSERT INTO device_registrations(
                    user_id, installation_id, platform, push_token_ciphertext,
                    token_fingerprint, app_version, last_seen_at
                ) VALUES (:user_id, :installation, 'android', :ciphertext,
                          :fingerprint, '1.0.0-test', now())
                RETURNING id
                """
            ),
            {
                "user_id": user_id,
                "installation": uuid4(),
                "ciphertext": encrypt_token(PUSH_TOKEN, issuer=ISSUER, subject=str(subject)),
                "fingerprint": uuid4().hex,
            },
        )
    return UUID(str(device_id))


def set_preferences(engine: Engine, user_id: UUID) -> None:
    with engine.begin() as connection:
        connection.execute(
            text(
                """
                INSERT INTO notification_preferences(
                    user_id, notifications_enabled, mission_enabled, reward_enabled,
                    timezone, lock_screen_detail, max_daily_reminders
                ) VALUES (
                    :user_id, true, true, true, 'Asia/Colombo', 'detailed', 3
                )
                """
            ),
            {"user_id": user_id},
        )


def create_open_mission(engine: Engine, user_id: UUID) -> UUID:
    with engine.begin() as connection:
        mission_id = connection.scalar(
            text(
                """
                INSERT INTO missions(
                    user_id, subject_id, mission_date, mission_timezone, status,
                    engine_version, candidate_snapshot_hash, estimated_minutes,
                    planned_item_count, expires_at
                ) VALUES (
                    :user_id, CAST(:subject AS uuid), '2026-11-11', 'Asia/Colombo',
                    'planned', 'test-engine', 'snapshot', 5, 3, now() + interval '8 hours'
                )
                RETURNING id
                """
            ),
            {"user_id": user_id, "subject": PHYSICS_SUBJECT_ID},
        )
    return UUID(str(mission_id))


def insert_trigger_event(
    engine: Engine, event_type: str, payload: dict, *, aggregate: str = "workflow"
) -> UUID:
    with engine.begin() as connection:
        event_id = connection.scalar(
            text(
                """
                INSERT INTO outbox_events(
                    domain_event_key, aggregate_type, aggregate_id, event_type,
                    event_version, payload, correlation_id, publication_status
                ) VALUES (
                    :key, :aggregate, gen_random_uuid(), :event_type, 1,
                    CAST(:payload AS jsonb), gen_random_uuid(), 'pending'
                )
                RETURNING id
                """
            ),
            {
                "key": f"test:{event_type}:{uuid4()}",
                "aggregate": aggregate,
                "event_type": event_type,
                "payload": json.dumps(payload),
            },
        )
    return UUID(str(event_id))


def build_job(event_id: UUID) -> dict:
    return {
        "id": uuid4(),
        "job_type": "notification.send",
        "payload": {"schema_version": "1", "outbox_event_id": str(event_id)},
    }


def delivery_rows(engine: Engine, user_id: UUID) -> list[dict]:
    with engine.begin() as connection:
        rows = connection.execute(
            text(
                """
                SELECT category, status, skip_reason, resource_type, resource_id
                FROM notification_deliveries
                WHERE user_id = :user_id
                ORDER BY created_at, id
                """
            ),
            {"user_id": user_id},
        ).mappings()
        return [dict(row) for row in rows]


def test_backlog_enqueues_one_job_per_unseen_trigger(database: Engine) -> None:
    for event_type, extra in (
        ("memory.schedule_changed", {"user_id": str(uuid4()), "concept_id": str(uuid4())}),
        ("mission.ready", {"user_id": str(uuid4()), "mission_id": str(uuid4())}),
        ("reward.granted", {"user_id": str(uuid4()), "grant_id": str(uuid4())}),
        (
            "ingestion.verification_required",
            {"user_id": str(uuid4()), "update_id": str(uuid4())},
        ),
        (
            "ingestion.learning_path_committed",
            {"user_id": str(uuid4()), "update_id": str(uuid4())},
        ),
        ("privacy.export_ready", {"user_id": str(uuid4()), "request_id": str(uuid4())}),
        ("unrelated.event", {"user_id": str(uuid4())}),
    ):
        insert_trigger_event(database, event_type, extra)

    with database.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_worker"))
        unseen = connection.scalar(
            text(
                """
                SELECT count(*) FROM outbox_events e
                WHERE e.event_type = ANY(CAST(:triggers AS text[]))
                  AND NOT EXISTS (
                      SELECT 1 FROM background_jobs j
                      WHERE j.dedupe_key = 'notifications:outbox:' || e.id::text
                  )
                """
            ),
            {"triggers": list(TRIGGER_EVENT_TYPES)},
        )
        enqueued_first = enqueue_notification_backlog(connection, now=NOW)
        enqueued_second = enqueue_notification_backlog(connection, now=NOW)

    # The disposable database persists across runs; assert the invariant
    # (one job per unseen trigger event) and that this test's six trigger
    # events were covered.
    assert enqueued_first == unseen
    assert enqueued_first >= 6
    assert enqueued_second == 0


def test_mission_ready_trigger_sends_push(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id)
    mission_id = create_open_mission(database, user_id)

    event_id = insert_trigger_event(
        database,
        "mission.ready",
        {
            "schema_version": "1",
            "user_id": str(user_id),
            "mission_id": str(mission_id),
            "subject_name": "Physics",
        },
        aggregate="mission",
    )
    provider = RecordingProvider()
    handle_notification_job(database, build_job(event_id), now=NOW, dispatcher=dispatcher(provider))

    assert len(provider.tokens) == 1
    assert provider.tokens[0] == PUSH_TOKEN
    sent = provider.payloads[0]
    assert sent["category"] == CATEGORY_MISSION_READY
    assert sent["resource_id"] == str(mission_id)
    rows = delivery_rows(database, user_id)
    assert rows[0]["status"] == "sent"
    assert rows[0]["resource_type"] == "mission"


def test_due_memories_trigger_resolves_open_mission(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id)
    mission_id = create_open_mission(database, user_id)

    event_id = insert_trigger_event(
        database,
        "memory.schedule_changed",
        {
            "schema_version": "1",
            "user_id": str(user_id),
            "concept_id": str(uuid4()),
        },
        aggregate="memory_decision",
    )
    provider = RecordingProvider()
    handle_notification_job(database, build_job(event_id), now=NOW, dispatcher=dispatcher(provider))

    assert provider.payloads[0]["category"] == CATEGORY_DUE_MEMORIES
    assert provider.payloads[0]["resource_id"] == str(mission_id)


def test_due_memories_without_open_mission_consumes_trigger(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id)

    event_id = insert_trigger_event(
        database,
        "memory.schedule_changed",
        {"schema_version": "1", "user_id": str(user_id), "concept_id": str(uuid4())},
        aggregate="memory_decision",
    )
    provider = RecordingProvider()
    handle_notification_job(database, build_job(event_id), now=NOW, dispatcher=dispatcher(provider))

    assert provider.tokens == []
    rows = delivery_rows(database, user_id)
    assert rows[0]["status"] == "skipped"
    assert rows[0]["skip_reason"] == "resource_unavailable"


def test_workflow_triggers_send_with_resolved_resources(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id)

    update_id = uuid4()
    for event_type, payload, expected_category, resource in (
        (
            "ingestion.verification_required",
            {"schema_version": "1", "user_id": str(user_id), "update_id": str(update_id)},
            CATEGORY_VERIFICATION_REQUIRED,
            str(update_id),
        ),
        (
            "ingestion.learning_path_committed",
            {
                "schema_version": "1",
                "user_id": str(user_id),
                "update_id": str(update_id),
                "subject_name": "Physics",
                "count": 4,
            },
            "learning_path_ready",
            str(update_id),
        ),
        (
            "reward.granted",
            {"schema_version": "1", "user_id": str(user_id), "grant_id": str(uuid4())},
            CATEGORY_REWARD_READY,
            None,
        ),
        (
            "privacy.export_ready",
            {"schema_version": "1", "user_id": str(user_id), "request_id": str(uuid4())},
            CATEGORY_PRIVACY_EXPORT_READY,
            None,
        ),
    ):
        event_id = insert_trigger_event(database, event_type, payload)
        provider = RecordingProvider()
        handle_notification_job(
            database, build_job(event_id), now=NOW, dispatcher=dispatcher(provider)
        )
        assert provider.payloads[0]["category"] == expected_category
        if resource is not None:
            assert provider.payloads[0]["resource_id"] == resource


def test_duplicate_resource_triggers_converge_to_one_send(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id)

    update_id = uuid4()
    provider = RecordingProvider()
    for _ in range(2):
        event_id = insert_trigger_event(
            database,
            "ingestion.verification_required",
            {"schema_version": "1", "user_id": str(user_id), "update_id": str(update_id)},
        )
        handle_notification_job(
            database, build_job(event_id), now=NOW, dispatcher=dispatcher(provider)
        )

    assert len(provider.tokens) == 1
    rows = delivery_rows(database, user_id)
    assert sum(1 for row in rows if row["status"] == "sent") == 1


def test_rerunning_the_same_job_is_replayed(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id)

    event_id = insert_trigger_event(
        database,
        "mission.ready",
        {"schema_version": "1", "user_id": str(user_id), "mission_id": str(uuid4())},
        aggregate="mission",
    )
    job = build_job(event_id)
    provider = RecordingProvider()
    handle_notification_job(database, job, now=NOW, dispatcher=dispatcher(provider))
    handle_notification_job(database, job, now=NOW, dispatcher=dispatcher(provider))
    assert len(provider.tokens) == 1


def test_unknown_trigger_event_dead_letters(database: Engine) -> None:
    event_id = insert_trigger_event(
        database, "totally.unknown", {"schema_version": "1", "user_id": str(uuid4())}
    )
    with pytest.raises(NonRetryableJobError) as excinfo:
        handle_notification_job(
            database, build_job(event_id), now=NOW, dispatcher=dispatcher(RecordingProvider())
        )
    assert excinfo.value.code == CODE_UNKNOWN_TRIGGER


def test_malformed_envelope_dead_letters(database: Engine) -> None:
    event_id = insert_trigger_event(
        database,
        "mission.ready",
        {"schema_version": "1", "user_id": str(uuid4())},  # mission_id missing
        aggregate="mission",
    )
    with pytest.raises(NonRetryableJobError) as excinfo:
        handle_notification_job(
            database, build_job(event_id), now=NOW, dispatcher=dispatcher(RecordingProvider())
        )
    assert excinfo.value.code == CODE_INVALID_EVENT_PAYLOAD


def test_wrong_envelope_version_dead_letters(database: Engine) -> None:
    event_id = insert_trigger_event(
        database,
        "mission.ready",
        {"schema_version": "2", "user_id": str(uuid4()), "mission_id": str(uuid4())},
        aggregate="mission",
    )
    with pytest.raises(NonRetryableJobError) as excinfo:
        handle_notification_job(
            database, build_job(event_id), now=NOW, dispatcher=dispatcher(RecordingProvider())
        )
    assert excinfo.value.code == CODE_INVALID_EVENT_PAYLOAD


def test_missing_outbox_event_dead_letters(database: Engine) -> None:
    with pytest.raises(NonRetryableJobError) as excinfo:
        handle_notification_job(
            database,
            build_job(uuid4()),
            now=NOW,
            dispatcher=dispatcher(RecordingProvider()),
        )
    assert excinfo.value.code == CODE_OUTBOX_EVENT_MISSING
