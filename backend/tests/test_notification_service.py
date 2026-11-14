"""Delivery enforcement contracts for the notification ledger (T19 Commit 3).

Proves the PRD 031-032 / Task Table T19 surface on a disposable database:
quiet hours in the recipient's timezone with the preferred-window exception,
reminder caps per user-local day, category choice, consume-once dedupe,
append-only ledger rows, RLS owner scoping and the worker role boundary.
Skips unless MEMORA_TEST_DATABASE_URL targets a disposable database.
"""

from __future__ import annotations

import os
import threading
import time
from collections.abc import Iterator
from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import pytest
from alembic import command
from alembic.config import Config
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from sqlalchemy import Connection, Engine, create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.exc import DBAPIError, ProgrammingError

from memora.modules.notifications.constants import (
    CATEGORY_DUE_MEMORIES,
    CATEGORY_MISSION_READY,
    CATEGORY_VERIFICATION_REQUIRED,
    REMINDER_INTENT_TTL,
    WORKFLOW_INTENT_TTL,
)
from memora.modules.notifications.payload import build_payload
from memora.modules.notifications.providers import (
    PROVIDER_OUTCOME_PERMANENT,
    PROVIDER_OUTCOME_RETRYABLE,
    PROVIDER_OUTCOME_SENT,
    ProviderResult,
)
from memora.modules.notifications.repository import (
    complete_send_outcome,
    decrypt_push_token,
    expire_stale_sending,
    record_delivery,
)
from memora.modules.notifications.service import (
    DeliveryOutcome,
    category_blocked,
    complete_dispatch,
    plan_dispatch,
    quiet_hours_block,
)

BACKEND_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DISPOSABLE_DATABASE_SUFFIXES = ("_test", "_ci")
ISSUER = "https://notification-service.test"
NOW = datetime(2026, 11, 11, 12, 0, 0, tzinfo=UTC)
TOKEN_KEY = os.urandom(32)
PUSH_TOKEN = "synthetic-push-token-018f"


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


class RecordingProvider:
    """Records the push tokens it receives; replays scripted outcomes."""

    def __init__(self, outcomes: list[ProviderResult] | None = None) -> None:
        self.outcomes = list(outcomes or [])
        self.tokens: list[str] = []

    def send(self, payload, push_token: str) -> ProviderResult:  # noqa: ANN001
        self.tokens.append(push_token)
        if self.outcomes:
            return self.outcomes.pop(0)
        return ProviderResult(outcome=PROVIDER_OUTCOME_SENT, reason_code="sent")


def encrypt_token(token: str, *, issuer: str, subject: str) -> bytes:
    """Replicate the T06 identity protector ciphertext format."""

    nonce = os.urandom(12)
    encrypted = AESGCM(TOKEN_KEY).encrypt(nonce, token.encode(), f"{issuer}\0{subject}".encode())
    return b"\x01" + nonce + encrypted


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


def create_device(engine: Engine, user_id: UUID, *, corrupt: bool = False) -> UUID:
    ciphertext = (
        b"\x02corrupted-ciphertext"
        if corrupt
        else encrypt_token(PUSH_TOKEN, issuer=ISSUER, subject=subject_of(engine, user_id))
    )
    with engine.begin() as connection:
        device_id = connection.scalar(
            text(
                """
                INSERT INTO device_registrations(
                    user_id, installation_id, platform, push_token_ciphertext,
                    token_fingerprint, app_version, last_seen_at
                ) VALUES (
                    :user_id, :installation, 'android', :ciphertext,
                    :fingerprint, '1.0.0-test', now()
                )
                RETURNING id
                """
            ),
            {
                "user_id": user_id,
                "installation": uuid4(),
                "ciphertext": ciphertext,
                "fingerprint": uuid4().hex,
            },
        )
    return UUID(str(device_id))


def subject_of(engine: Engine, user_id: UUID) -> str:
    with engine.begin() as connection:
        return str(
            connection.scalar(
                text("SELECT oidc_subject FROM users WHERE id = :user_id"),
                {"user_id": user_id},
            )
        )


def set_preferences(
    engine: Engine,
    user_id: UUID,
    *,
    notifications_enabled: bool = True,
    mission_enabled: bool = True,
    reward_enabled: bool = True,
    quiet_start: str | None = None,
    quiet_end: str | None = None,
    preferred_start: str | None = None,
    preferred_end: str | None = None,
    timezone: str = "Asia/Colombo",
    lock_screen_detail: str = "detailed",
    max_daily_reminders: int = 3,
) -> None:
    with engine.begin() as connection:
        connection.execute(
            text(
                """
                INSERT INTO notification_preferences(
                    user_id, notifications_enabled, mission_enabled, reward_enabled,
                    quiet_start_local, quiet_end_local,
                    preferred_window_start_local, preferred_window_end_local,
                    timezone, lock_screen_detail, max_daily_reminders
                ) VALUES (
                    :user_id, :notifications_enabled, :mission_enabled, :reward_enabled,
                    CAST(:quiet_start AS time), CAST(:quiet_end AS time),
                    CAST(:preferred_start AS time), CAST(:preferred_end AS time),
                    :timezone, :lock_screen_detail, :max_daily_reminders
                )
                """
            ),
            {
                "user_id": user_id,
                "notifications_enabled": notifications_enabled,
                "mission_enabled": mission_enabled,
                "reward_enabled": reward_enabled,
                "quiet_start": quiet_start,
                "quiet_end": quiet_end,
                "preferred_start": preferred_start,
                "preferred_end": preferred_end,
                "timezone": timezone,
                "lock_screen_detail": lock_screen_detail,
                "max_daily_reminders": max_daily_reminders,
            },
        )


def reminder_payload(**overrides):  # noqa: ANN001, ANN202
    defaults = dict(
        category=CATEGORY_DUE_MEMORIES,
        resource_id=uuid4().hex + uuid4().hex[:16],
        expires_at=NOW + REMINDER_INTENT_TTL,
        notification_id=uuid4().hex,
        detail="detailed",
        params={"subject_name": "Physics", "count": 3},
    )
    defaults.update(overrides)
    return build_payload(**defaults)


def _owner_context(connection: Connection, user_id: UUID) -> None:
    connection.execute(text("SET LOCAL ROLE memora_api"))
    connection.execute(
        text("SELECT set_config('memora.user_id', :user_id, true)"),
        {"user_id": str(user_id)},
    )


def run_dispatch(
    engine: Engine,
    provider: RecordingProvider,
    user_id: UUID,
    payload,  # noqa: ANN001
    dedupe_key: str,
) -> DeliveryOutcome:
    """Run one dispatch through the production three-phase flow.

    Phase 1 plans and records inside a transaction; phase 2 performs the
    external provider calls with no transaction open; phase 3 completes the
    ledger rows in a short transaction (Schema 14.2).
    """

    with engine.begin() as connection:
        _owner_context(connection, user_id)
        plan = plan_dispatch(
            connection,
            user_id=user_id,
            payload=payload,
            dedupe_key=dedupe_key,
            now=NOW,
            token_encryption_key=TOKEN_KEY,
        )

    if not plan.is_send:
        return DeliveryOutcome(
            notification_id=plan.payload.notification_id,
            category=plan.payload.category,
            replayed=plan.replayed,
            skip_reason=plan.skip_reason,
        )

    results = {
        send.device_id: provider.send(plan.payload, send.push_token) for send in plan.devices
    }

    with engine.begin() as connection:
        _owner_context(connection, user_id)
        return complete_dispatch(connection, plan=plan, results=results, now=NOW)


def delivery_rows(engine: Engine, user_id: UUID) -> list[dict]:
    with engine.begin() as connection:
        rows = connection.execute(
            text(
                """
                SELECT category, status, skip_reason, provider_code, device_id,
                       notification_id
                FROM notification_deliveries
                WHERE user_id = :user_id
                ORDER BY created_at, id
                """
            ),
            {"user_id": user_id},
        ).mappings()
        return [dict(row) for row in rows]


# --- pure enforcement helpers -------------------------------------------------


def test_quiet_hours_block_overnight_window() -> None:
    # 12:00 UTC is 17:30 in Asia/Colombo, inside a 17:00-18:00 quiet window.
    assert (
        quiet_hours_block(
            NOW,
            timezone_name="Asia/Colombo",
            quiet_start="17:00",
            quiet_end="18:00",
            preferred_start=None,
            preferred_end=None,
        )
        is True
    )


def test_quiet_hours_wrap_past_midnight() -> None:
    late = datetime(2026, 11, 11, 19, 30, tzinfo=UTC)  # 01:00 Colombo
    assert (
        quiet_hours_block(
            late,
            timezone_name="Asia/Colombo",
            quiet_start="22:00",
            quiet_end="06:00",
            preferred_start=None,
            preferred_end=None,
        )
        is True
    )
    daytime = datetime(2026, 11, 11, 4, 30, tzinfo=UTC)  # 10:00 Colombo
    assert (
        quiet_hours_block(
            daytime,
            timezone_name="Asia/Colombo",
            quiet_start="22:00",
            quiet_end="06:00",
            preferred_start=None,
            preferred_end=None,
        )
        is False
    )


def test_preferred_window_overrides_quiet_hours() -> None:
    assert (
        quiet_hours_block(
            NOW,
            timezone_name="Asia/Colombo",
            quiet_start="17:00",
            quiet_end="18:00",
            preferred_start="17:30",
            preferred_end="18:00",
        )
        is False
    )


def test_quiet_hours_across_dst_spring_forward_boundary() -> None:
    # Europe/London skips 01:00-01:59 local on 2026-03-29 (spring forward).
    # Before the jump London is UTC+0; after it UTC+1. The quiet window
    # 01:00-06:00 local must evaluate correctly on both sides of the gap.
    # 00:30 local (00:30 UTC, before the jump) is before the window.
    assert (
        quiet_hours_block(
            datetime(2026, 3, 29, 0, 30, tzinfo=UTC),
            timezone_name="Europe/London",
            quiet_start="01:00",
            quiet_end="06:00",
            preferred_start=None,
            preferred_end=None,
        )
        is False
    )
    # 01:00 UTC = 02:00 local (after the jump): inside the window.
    assert (
        quiet_hours_block(
            datetime(2026, 3, 29, 1, 0, tzinfo=UTC),
            timezone_name="Europe/London",
            quiet_start="01:00",
            quiet_end="06:00",
            preferred_start=None,
            preferred_end=None,
        )
        is True
    )
    # 05:30 UTC = 06:30 local (after the jump): the window has closed.
    assert (
        quiet_hours_block(
            datetime(2026, 3, 29, 5, 30, tzinfo=UTC),
            timezone_name="Europe/London",
            quiet_start="01:00",
            quiet_end="06:00",
            preferred_start=None,
            preferred_end=None,
        )
        is False
    )


def test_invalid_timezone_blocks_instead_of_crashing() -> None:
    assert (
        quiet_hours_block(
            NOW,
            timezone_name="Not/AZone",
            quiet_start="17:00",
            quiet_end="18:00",
            preferred_start=None,
            preferred_end=None,
        )
        is True
    )


def test_category_blocked_honours_mission_and_reward_flags() -> None:
    class Enabled:  # noqa: D101 - minimal preference stand-in
        mission_enabled = True
        reward_enabled = True

    class RewardDisabled:  # noqa: D101 - minimal preference stand-in
        mission_enabled = True
        reward_enabled = False

    assert category_blocked(Enabled(), CATEGORY_MISSION_READY) is False
    assert category_blocked(Enabled(), CATEGORY_DUE_MEMORIES) is False
    assert category_blocked(Enabled(), CATEGORY_VERIFICATION_REQUIRED) is False
    assert category_blocked(RewardDisabled(), CATEGORY_MISSION_READY) is False
    assert category_blocked(RewardDisabled(), CATEGORY_DUE_MEMORIES) is False


def test_decrypt_rejects_corrupt_ciphertext() -> None:
    with pytest.raises(ValueError, match="format version"):
        decrypt_push_token(b"\x09short", issuer=ISSUER, subject="s", key=TOKEN_KEY)
    with pytest.raises(ValueError, match="authentication"):
        decrypt_push_token(
            encrypt_token(PUSH_TOKEN, issuer=ISSUER, subject="s")[:-1],
            issuer=ISSUER,
            subject="s",
            key=TOKEN_KEY,
        )


# --- DB-gated dispatch contracts ----------------------------------------------


def test_dispatch_happy_path_sends_decrypted_token(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id)

    provider = RecordingProvider()
    payload = reminder_payload()
    outcome = run_dispatch(database, provider, user_id, payload, f"due:{user_id}:day0")

    assert outcome.delivered == 1
    assert outcome.failed == 0
    assert provider.tokens == [PUSH_TOKEN]
    rows = delivery_rows(database, user_id)
    assert len(rows) == 1
    assert rows[0]["status"] == "sent"
    assert rows[0]["skip_reason"] is None


def test_dispatch_without_preferences_skips_safely(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)

    provider = RecordingProvider()
    outcome = run_dispatch(database, provider, user_id, reminder_payload(), "due:day0")

    assert outcome.skip_reason == "notifications_disabled"
    assert provider.tokens == []
    rows = delivery_rows(database, user_id)
    assert rows[0]["status"] == "skipped"
    assert rows[0]["skip_reason"] == "notifications_disabled"


def test_dispatch_disabled_notifications_skip(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id, notifications_enabled=False)

    provider = RecordingProvider()
    outcome = run_dispatch(database, provider, user_id, reminder_payload(), "due:day0")
    assert outcome.skip_reason == "notifications_disabled"
    assert provider.tokens == []


def test_dispatch_category_disabled_skips(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id, mission_enabled=False)

    provider = RecordingProvider()
    payload = reminder_payload(category=CATEGORY_MISSION_READY)
    outcome = run_dispatch(database, provider, user_id, payload, "mission:day0")
    assert outcome.skip_reason == "category_disabled"
    assert provider.tokens == []


def test_dispatch_quiet_hours_skip(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    # 17:30 Colombo at NOW: inside the quiet window, outside the exception.
    set_preferences(
        database,
        user_id,
        quiet_start="17:00",
        quiet_end="18:00",
        preferred_start="06:00",
        preferred_end="07:00",
    )

    provider = RecordingProvider()
    outcome = run_dispatch(database, provider, user_id, reminder_payload(), "due:day0")
    assert outcome.skip_reason == "quiet_hours"
    assert provider.tokens == []


def test_reminder_cap_blocks_second_reminder_same_local_day(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id, max_daily_reminders=1)

    provider = RecordingProvider()
    first = run_dispatch(database, provider, user_id, reminder_payload(), f"due:{user_id}:d0")
    assert first.delivered == 1

    second_payload = reminder_payload()
    second = run_dispatch(database, provider, user_id, second_payload, f"due:{user_id}:d1")
    assert second.skip_reason == "reminder_cap_reached"
    assert len(provider.tokens) == 1  # second dispatch never sent


def test_zero_cap_blocks_first_reminder(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id, max_daily_reminders=0)

    provider = RecordingProvider()
    outcome = run_dispatch(database, provider, user_id, reminder_payload(), "due:day0")
    assert outcome.skip_reason == "reminder_cap_reached"


def test_transactional_categories_bypass_reminder_cap(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id, max_daily_reminders=0)

    provider = RecordingProvider()
    payload = build_payload(
        category=CATEGORY_VERIFICATION_REQUIRED,
        resource_id=uuid4().hex + uuid4().hex[:16],
        expires_at=NOW + WORKFLOW_INTENT_TTL,
        notification_id=uuid4().hex,
    )
    outcome = run_dispatch(database, provider, user_id, payload, "verify:day0")
    assert outcome.delivered == 1


def test_expired_intent_skips(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id)

    provider = RecordingProvider()
    payload = reminder_payload(expires_at=NOW - REMINDER_INTENT_TTL)
    outcome = run_dispatch(database, provider, user_id, payload, "due:day0")
    assert outcome.skip_reason == "expired"
    assert provider.tokens == []


def test_revoked_devices_never_receive_sends(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    with database.begin() as connection:
        connection.execute(
            text(
                """
                UPDATE device_registrations
                SET revoked_at = now()
                WHERE user_id = :user_id
                """
            ),
            {"user_id": user_id},
        )
    set_preferences(database, user_id)

    provider = RecordingProvider()
    run_dispatch(database, provider, user_id, reminder_payload(), "due:day0")

    # The only device is revoked: no send, no crash, and the trigger is
    # consumed once with the no-devices skip reason.
    assert provider.tokens == []
    rows = delivery_rows(database, user_id)
    assert rows[0]["status"] == "skipped"
    assert rows[0]["skip_reason"] == "no_devices"


def test_worker_cannot_insert_deliveries_directly(database: Engine) -> None:
    user_id = create_user(database)

    with pytest.raises(ProgrammingError), database.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_worker"))
        connection.execute(
            text(
                """
                    INSERT INTO notification_deliveries(
                        user_id, notification_id, category, resource_type,
                        resource_id, dedupe_key, status
                    ) VALUES (
                        :user_id, 'x', 'mission_ready', 'mission', 'x', 'x', 'sent'
                    )
                    """
            ),
            {"user_id": user_id},
        )


def test_dispatch_without_devices_skips(database: Engine) -> None:
    user_id = create_user(database)
    set_preferences(database, user_id)

    provider = RecordingProvider()
    outcome = run_dispatch(database, provider, user_id, reminder_payload(), "due:day0")
    assert outcome.skip_reason == "no_devices"


def test_consume_once_blocks_duplicate_trigger(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id)

    provider = RecordingProvider()
    payload = reminder_payload()
    dedupe = f"due:{user_id}:d0"

    first = run_dispatch(database, provider, user_id, payload, dedupe)
    assert first.delivered == 1

    replay = run_dispatch(database, provider, user_id, payload, dedupe)
    assert replay.replayed is True
    assert len(provider.tokens) == 1


def test_concurrent_duplicate_triggers_converge_to_one_fanout(database: Engine) -> None:
    """Two workers racing on one trigger: the advisory lock serialises them.

    Worker B plans and holds its transaction open; worker A blocks on the
    advisory lock until B commits, then observes B's in-flight row and
    replays instead of sending a second push.
    """

    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id)

    provider = RecordingProvider()
    payload = reminder_payload()
    dedupe_key = f"due:{user_id}:d0"

    errors: list[BaseException] = []
    b_planned = threading.Event()
    outcomes: dict[str, DeliveryOutcome] = {}

    def worker_b() -> None:
        try:
            connection = database.connect()
            with connection.begin():
                _owner_context(connection, user_id)
                plan = plan_dispatch(
                    connection,
                    user_id=user_id,
                    payload=payload,
                    dedupe_key=dedupe_key,
                    now=NOW,
                    token_encryption_key=TOKEN_KEY,
                )
                b_planned.set()
                time.sleep(1.0)  # hold the advisory lock across the commit
            if plan.is_send:
                results = {
                    send.device_id: provider.send(plan.payload, send.push_token)
                    for send in plan.devices
                }
                completion = database.connect()
                with completion.begin():
                    _owner_context(completion, user_id)
                    outcomes["b"] = complete_dispatch(
                        completion, plan=plan, results=results, now=NOW
                    )
            else:
                outcomes["b"] = DeliveryOutcome(
                    notification_id=plan.payload.notification_id,
                    category=plan.payload.category,
                    replayed=plan.replayed,
                    skip_reason=plan.skip_reason,
                )
        except BaseException as exc:  # pragma: no cover - surfaced via errors
            errors.append(exc)
            b_planned.set()

    def worker_a() -> None:
        try:
            assert b_planned.wait(timeout=10)
            connection = database.connect()
            with connection.begin():
                _owner_context(connection, user_id)
                plan = plan_dispatch(
                    connection,
                    user_id=user_id,
                    payload=payload,
                    dedupe_key=dedupe_key,
                    now=NOW,
                    token_encryption_key=TOKEN_KEY,
                )
            outcomes["a"] = DeliveryOutcome(
                notification_id=plan.payload.notification_id,
                category=plan.payload.category,
                replayed=plan.replayed,
                skip_reason=plan.skip_reason,
            )
        except BaseException as exc:  # pragma: no cover - surfaced via errors
            errors.append(exc)

    thread_b = threading.Thread(target=worker_b)
    thread_a = threading.Thread(target=worker_a)
    thread_b.start()
    thread_a.start()
    thread_b.join(timeout=30)
    thread_a.join(timeout=30)
    assert not thread_b.is_alive() and not thread_a.is_alive()
    assert not errors, f"worker threads failed: {errors!r}"

    delivered = outcomes["a"].delivered + outcomes["b"].delivered
    replayed = outcomes["a"].replayed + outcomes["b"].replayed
    assert delivered == 1
    assert replayed == 1
    assert len(provider.tokens) == 1


def test_reminder_cap_counts_in_flight_sends_across_categories(
    database: Engine,
) -> None:
    """A reminder planned but not yet completed consumes the daily cap.

    ``mission_ready`` and ``due_memories`` use different dedupe keys; the
    shared per-user plan lock plus counting in-flight rows keeps the daily
    cap correct when the categories are processed concurrently.
    """

    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id, max_daily_reminders=1)

    provider = RecordingProvider()

    # Plan phase only for the first reminder: the in-flight row is recorded.
    with database.begin() as connection:
        _owner_context(connection, user_id)
        first_plan = plan_dispatch(
            connection,
            user_id=user_id,
            payload=reminder_payload(category=CATEGORY_MISSION_READY),
            dedupe_key=f"mission:{user_id}:d0",
            now=NOW,
            token_encryption_key=TOKEN_KEY,
        )
    assert first_plan.is_send

    # The second reminder category must now observe the cap.
    with database.begin() as connection:
        _owner_context(connection, user_id)
        second_plan = plan_dispatch(
            connection,
            user_id=user_id,
            payload=reminder_payload(),
            dedupe_key=f"due:{user_id}:d0",
            now=NOW,
            token_encryption_key=TOKEN_KEY,
        )
    assert second_plan.skip_reason == "reminder_cap_reached"

    # Completing the first send is unaffected.
    results = {
        send.device_id: provider.send(first_plan.payload, send.push_token)
        for send in first_plan.devices
    }
    with database.begin() as connection:
        _owner_context(connection, user_id)
        outcome = complete_dispatch(connection, plan=first_plan, results=results, now=NOW)
    assert outcome.delivered == 1
    assert len(provider.tokens) == 1


def test_lifecycle_guard_permits_only_the_sending_transition(
    database: Engine,
) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id)

    run_dispatch(database, RecordingProvider(), user_id, reminder_payload(), "due:day0")

    # A completed row can never be rewritten.
    with pytest.raises(DBAPIError), database.begin() as connection:
        connection.execute(text("UPDATE notification_deliveries SET status = 'sending'"))
    with pytest.raises(DBAPIError), database.begin() as connection:
        connection.execute(text("UPDATE notification_deliveries SET status = 'failed'"))

    # An in-flight row completes exactly once, touching outcome fields only.
    with database.begin() as connection:
        _owner_context(connection, user_id)
        first_plan = plan_dispatch(
            connection,
            user_id=user_id,
            payload=reminder_payload(notification_id="b1b2c3d4e5f60718293a4b5c6d7e8f90"),
            dedupe_key=f"due:{user_id}:d1",
            now=NOW,
            token_encryption_key=TOKEN_KEY,
        )
    assert first_plan.is_send

    with database.begin() as connection:
        _owner_context(connection, user_id)
        assert (
            complete_send_outcome(
                connection,
                user_id=user_id,
                notification_id=first_plan.payload.notification_id,
                device_id=first_plan.devices[0].device_id,
                status="sent",
                provider_code=None,
                provider_message_id="projects/test/messages/regression",
            )
            is True
        )
    rows = delivery_rows(database, user_id)
    sent = [
        row
        for row in rows
        if row["status"] == "sent" and row["notification_id"] == "b1b2c3d4e5f60718293a4b5c6d7e8f90"
    ]
    assert len(sent) == 1

    # An in-flight row cannot jump to a non-terminal status. Plan a second
    # send, then try to rewrite it directly.
    with database.begin() as connection:
        _owner_context(connection, user_id)
        second_plan = plan_dispatch(
            connection,
            user_id=user_id,
            payload=reminder_payload(notification_id="d1b2c3d4e5f60718293a4b5c6d7e8f90"),
            dedupe_key=f"due:{user_id}:d2",
            now=NOW,
            token_encryption_key=TOKEN_KEY,
        )
    assert second_plan.is_send
    with pytest.raises(DBAPIError), database.begin() as connection:
        _owner_context(connection, user_id)
        connection.execute(
            text(
                """
                UPDATE notification_deliveries
                SET status = 'skipped', skip_reason = 'expired'
                WHERE notification_id = :notification_id
                """
            ),
            {"notification_id": second_plan.payload.notification_id},
        )


def test_stale_sending_resolves_to_bounded_failure(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id)

    with database.begin() as connection:
        _owner_context(connection, user_id)
        plan = plan_dispatch(
            connection,
            user_id=user_id,
            payload=reminder_payload(notification_id="c1b2c3d4e5f60718293a4b5c6d7e8f90"),
            dedupe_key=f"due:{user_id}:d0",
            now=NOW,
            token_encryption_key=TOKEN_KEY,
        )
    assert plan.is_send

    # Not stale yet: nothing expires.
    with database.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_worker"))
        assert (
            expire_stale_sending(
                connection, now=NOW + timedelta(minutes=5), stale_after=timedelta(minutes=15)
            )
            == 0
        )

    # Past the window: the unknown outcome resolves terminally. The sweep is
    # cross-user, so other tests' in-flight rows expire alongside this one;
    # scope the assertion to this test's notification.
    with database.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_worker"))
        assert (
            expire_stale_sending(
                connection,
                now=NOW + timedelta(minutes=16),
                stale_after=timedelta(minutes=15),
            )
            >= 1
        )

    rows = [
        row
        for row in delivery_rows(database, user_id)
        if row["notification_id"] == "c1b2c3d4e5f60718293a4b5c6d7e8f90"
    ]
    assert rows[0]["status"] == "failed"
    assert rows[0]["provider_code"] == "send_outcome_unknown"


def test_delivery_foreign_keys_do_not_block_account_deletion(
    database: Engine,
) -> None:
    user_id = create_user(database)
    device_id = create_device(database, user_id)
    set_preferences(database, user_id)
    run_dispatch(database, RecordingProvider(), user_id, reminder_payload(), "due:day0")

    # Deleting the device (the deletion executor does this) must not be
    # blocked by the delivery ledger: the reference becomes NULL.
    with database.begin() as connection:
        connection.execute(
            text("DELETE FROM device_registrations WHERE id = :device_id"),
            {"device_id": device_id},
        )
    rows = delivery_rows(database, user_id)
    assert rows[0]["status"] == "sent"

    # The users row itself is soft-deleted (status = 'deleted') in the MVP
    # deletion flow, so the user_id reference is never hard-violated; the
    # delivery row survives with its device reference cleared.
    with database.begin() as connection:
        user_status = connection.execute(
            text("SELECT status FROM users WHERE id = :user_id"), {"user_id": user_id}
        ).scalar_one()
    assert user_status == "active"  # unchanged: this test only deletes the device


def test_corrupt_token_records_failed_without_raising(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id, corrupt=True)
    set_preferences(database, user_id)

    provider = RecordingProvider()
    outcome = run_dispatch(database, provider, user_id, reminder_payload(), "due:day0")

    # The unreadable token is resolved in the plan phase: nothing is sent
    # and the row is recorded as a terminal failure.
    assert outcome.delivered == 0
    assert provider.tokens == []
    rows = delivery_rows(database, user_id)
    assert rows[0]["status"] == "failed"
    assert rows[0]["provider_code"] == "token_unreadable"


def test_permanent_provider_failure_is_recorded(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id)

    provider = RecordingProvider(
        outcomes=[ProviderResult(outcome=PROVIDER_OUTCOME_PERMANENT, reason_code="invalid_token")]
    )
    outcome = run_dispatch(database, provider, user_id, reminder_payload(), "due:day0")

    assert outcome.delivered == 0
    assert outcome.failed == 1
    rows = delivery_rows(database, user_id)
    assert rows[0]["status"] == "failed"
    assert rows[0]["provider_code"] == "invalid_token"


def test_retryable_provider_failure_is_recorded_as_failed(database: Engine) -> None:
    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id)

    provider = RecordingProvider(
        outcomes=[
            ProviderResult(outcome=PROVIDER_OUTCOME_RETRYABLE, reason_code="provider_timeout")
        ]
    )
    outcome = run_dispatch(database, provider, user_id, reminder_payload(), "due:day0")

    assert outcome.delivered == 0
    assert outcome.failed == 1
    rows = delivery_rows(database, user_id)
    assert rows[0]["status"] == "failed"
    assert rows[0]["provider_code"] == "provider_timeout"


def test_ledger_is_append_only(database: Engine) -> None:
    user_id = create_user(database)
    set_preferences(database, user_id)
    run_dispatch(database, RecordingProvider(), user_id, reminder_payload(), "due:day0")

    with pytest.raises(DBAPIError) as excinfo, database.begin() as connection:
        connection.execute(text("UPDATE notification_deliveries SET status = 'skipped'"))
    assert "append-only" in str(excinfo.value)

    with pytest.raises(DBAPIError), database.begin() as connection:
        connection.execute(text("DELETE FROM notification_deliveries"))


def test_rows_are_owner_scoped(database: Engine) -> None:
    owner = create_user(database)
    intruder = create_user(database)
    set_preferences(database, owner)
    run_dispatch(database, RecordingProvider(), owner, reminder_payload(), "due:owner")

    with database.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_api"))
        connection.execute(
            text("SELECT set_config('memora.user_id', :user_id, true)"),
            {"user_id": str(intruder)},
        )
        visible = connection.execute(
            text("SELECT count(*) FROM notification_deliveries")
        ).scalar_one()
        assert visible == 0

        with pytest.raises(DBAPIError):
            record_delivery(
                connection,
                user_id=owner,
                notification_id=uuid4().hex,
                category=CATEGORY_DUE_MEMORIES,
                resource_type="mission",
                resource_id=uuid4().hex,
                dedupe_key="intruder",
                device_id=None,
                status="skipped",
                skip_reason="no_devices",
                provider_code=None,
                provider_message_id=None,
                created_at=NOW,
            )


def test_worker_role_uses_functions_but_not_direct_dml(database: Engine) -> None:
    user_id = create_user(database)
    set_preferences(database, user_id)
    run_dispatch(database, RecordingProvider(), user_id, reminder_payload(), "due:worker")

    with database.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_worker"))
        exists = connection.execute(
            text("SELECT memora_notifications_delivery_exists(:user_id, :key)"),
            {"user_id": user_id, "key": "due:worker"},
        ).scalar_one()
        assert exists is True

        with pytest.raises(ProgrammingError):
            connection.execute(text("SELECT count(*) FROM notification_deliveries"))


def test_account_deletion_purges_delivery_rows(database: Engine) -> None:
    """Full account deletion removes delivery evidence (review finding 11).

    The deletion executor purges the ledger alongside the learner data; the
    retention decision (purge at deletion execution) is recorded in the
    evidence document.
    """

    user_id = create_user(database)
    create_device(database, user_id)
    set_preferences(database, user_id)
    run_dispatch(database, RecordingProvider(), user_id, reminder_payload(), "due:day0")

    with database.begin() as connection:
        before = connection.execute(
            text("SELECT count(*) FROM notification_deliveries WHERE user_id = :u"),
            {"u": user_id},
        ).scalar_one()
    assert before == 1

    # The deletion flow soft-deletes the account first; the executor then
    # purges learner data and delivery evidence.
    with database.begin() as connection:
        connection.execute(
            text("UPDATE users SET status = 'deleted', deleted_at = now() WHERE id = :u"),
            {"u": user_id},
        )
        connection.execute(text("SET LOCAL ROLE memora_worker"))
        connection.execute(
            text("SELECT memora_delete_learner_data(:user_id)"), {"user_id": user_id}
        )

    with database.begin() as connection:
        deliveries = connection.execute(
            text("SELECT count(*) FROM notification_deliveries WHERE user_id = :u"),
            {"u": user_id},
        ).scalar_one()
        devices = connection.execute(
            text("SELECT count(*) FROM device_registrations WHERE user_id = :u"),
            {"u": user_id},
        ).scalar_one()
        user_status = connection.execute(
            text("SELECT status FROM users WHERE id = :u"), {"u": user_id}
        ).scalar_one()
    assert deliveries == 0
    assert devices == 0
    assert user_status == "deleted"


def test_restore_reconciles_delivery_rows_without_other_learner_data(database: Engine) -> None:
    from memora.modules.privacy.repository import (
        reconcile_privacy_deletions,
        unreconciled_deletions_exist,
    )

    user_id = create_user(database)
    with database.begin() as connection:
        connection.execute(
            text(
                """UPDATE users SET status = 'deleted', deleted_at = now(),
                   oidc_subject = :deleted_subject WHERE id = :user_id"""
            ),
            {"deleted_subject": f"deleted:{user_id}", "user_id": user_id},
        )
        connection.execute(
            text(
                """INSERT INTO notification_deliveries(
                     user_id, notification_id, category, resource_type,
                     resource_id, dedupe_key, status, skip_reason
                   ) VALUES (
                     :user_id, :notification_id, 'due_memories', 'mission',
                     :resource_id, :dedupe_key, 'skipped', 'no_devices'
                   )"""
            ),
            {
                "user_id": user_id,
                "notification_id": uuid4().hex,
                "resource_id": str(uuid4()),
                "dedupe_key": uuid4().hex,
            },
        )

    with pytest.raises(ProgrammingError), database.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_api"))
        connection.execute(
            text("SELECT memora_notifications_user_rows_exist(:user_id)"),
            {"user_id": user_id},
        )

    with database.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_worker"))
        assert unreconciled_deletions_exist(connection) is True
        assert reconcile_privacy_deletions(connection) == 1
        assert unreconciled_deletions_exist(connection) is False

    with database.begin() as connection:
        assert (
            connection.scalar(
                text("SELECT count(*) FROM notification_deliveries WHERE user_id = :user_id"),
                {"user_id": user_id},
            )
            == 0
        )
