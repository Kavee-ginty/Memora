from __future__ import annotations

import base64
import hashlib
import os
from datetime import UTC, datetime, timedelta
from pathlib import Path
from uuid import uuid4

import pytest
from alembic import command
from alembic.config import Config
from pydantic import SecretStr
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine, make_url

from memora.api.errors import ApiError
from memora.api.security import AuthContext, AuthenticatedRequest
from memora.api.v1.schemas.identity import (
    DeviceRegistrationRequest,
    ProfilePreferencesUpdateRequest,
    ProfileUpdateRequest,
)
from memora.core.config import Settings
from memora.db.seed import seed_database
from memora.modules.identity.repository import IdentityRepository
from memora.modules.identity.service import IdentityService

BACKEND_ROOT = Path(__file__).parents[1]


@pytest.fixture
def profile_database(monkeypatch: pytest.MonkeyPatch) -> tuple[Engine, str]:
    database_url = os.getenv("MEMORA_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("MEMORA_TEST_DATABASE_URL is not configured")
    if not (make_url(database_url).database or "").endswith(("_test", "_ci")):
        pytest.fail(
            "MEMORA_TEST_DATABASE_URL must target a disposable test database", pytrace=False
        )
    monkeypatch.setenv("MEMORA_DATABASE_URL", database_url)
    config = Config(BACKEND_ROOT / "alembic.ini")
    config.set_main_option("script_location", str(BACKEND_ROOT / "migrations"))
    command.upgrade(config, "head")
    seed_database(database_url)
    engine = create_engine(database_url, connect_args={"connect_timeout": 10})
    yield engine, database_url
    engine.dispose()


def auth(subject: str) -> AuthContext:
    return AuthContext(
        issuer="https://profile.test/auth/v1",
        subject=subject,
        session_id=uuid4(),
        role="authenticated",
        authenticated_at=datetime.now(UTC),
        expires_at=datetime.now(UTC) + timedelta(minutes=5),
    )


def request(
    context: AuthContext, token: str = "synthetic-authorization-value"
) -> AuthenticatedRequest:
    return AuthenticatedRequest(context=context, access_token=SecretStr(token))


def test_profile_and_preferences_enforce_versions_idempotency_and_ownership(
    profile_database: tuple[Engine, str],
) -> None:
    engine, _ = profile_database
    repository = IdentityRepository(engine)
    owner = auth(f"owner-{uuid4()}")
    other = auth(f"other-{uuid4()}")
    owner_id = repository.bootstrap(owner, default_timezone="Asia/Colombo", default_locale="en-LK")[
        "user_id"
    ]
    other_id = repository.bootstrap(other, default_timezone="Asia/Colombo", default_locale="en-LK")[
        "user_id"
    ]

    profile = repository.profile(owner)
    profile_key = str(uuid4())
    updated = repository.update_profile(
        owner,
        version=profile["version"],
        idempotency_key=profile_key,
        values={"display_name": "Ada Student"},
    )
    assert updated["display_name"] == "Ada Student"
    assert updated["locale"] == "en-LK"
    assert (
        repository.update_profile(
            owner,
            version=profile["version"],
            idempotency_key=profile_key,
            values={"display_name": "Ada Student"},
        )
        == updated
    )
    with pytest.raises(ApiError, match="idempotency_key_reused"):
        repository.update_profile(
            owner,
            version=profile["version"],
            idempotency_key=profile_key,
            values={"display_name": "Changed Request"},
        )
    with pytest.raises(ApiError, match="version_conflict"):
        repository.update_profile(
            owner,
            version=profile["version"],
            idempotency_key=str(uuid4()),
            values={"locale": "en-US"},
        )

    defaults = repository.preferences(owner, default_reminders=1)
    assert defaults["notifications_enabled"] is False
    assert defaults["max_daily_reminders"] == 1
    preference_key = str(uuid4())
    preference_values = {
        "notifications_enabled": False,
        "mission_enabled": False,
        "reward_enabled": False,
        "streak_enabled": False,
        "quiet_start_local": "22:00:00",
        "quiet_end_local": "06:00:00",
        "preferred_window_start_local": "17:00:00",
        "preferred_window_end_local": "19:00:00",
        "timezone": "Asia/Colombo",
        "lock_screen_detail": "subject",
        "max_daily_reminders": 3,
        "accessibility": {
            "schema_version": "1",
            "reduced_motion": True,
            "sound_enabled": False,
            "haptics_enabled": False,
            "timer_visible": True,
            "high_contrast": True,
        },
    }
    preferences = repository.update_preferences(
        owner,
        version=defaults["version"],
        idempotency_key=preference_key,
        values=preference_values,
        default_reminders=1,
    )
    assert preferences["notifications_enabled"] is False
    assert preferences["accessibility"]["timer_visible"] is True
    assert (
        repository.update_preferences(
            owner,
            version=defaults["version"],
            idempotency_key=preference_key,
            values=preference_values,
            default_reminders=1,
        )
        == preferences
    )
    with pytest.raises(ApiError, match="idempotency_key_reused"):
        repository.update_preferences(
            owner,
            version=defaults["version"],
            idempotency_key=preference_key,
            values={**preference_values, "max_daily_reminders": 2},
            default_reminders=1,
        )
    with pytest.raises(ApiError, match="version_conflict"):
        repository.update_preferences(
            owner,
            version=defaults["version"],
            idempotency_key=str(uuid4()),
            values={"mission_enabled": True},
            default_reminders=1,
        )

    assert repository.profile(other)["user_id"] == other_id
    assert repository.preferences(other, default_reminders=1)["version"] == 1
    with engine.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_api"))
        connection.execute(
            text("SELECT set_config('memora.user_id', :user_id, true)"),
            {"user_id": str(other_id)},
        )
        assert (
            connection.scalar(
                text("SELECT count(*) FROM user_profiles WHERE user_id=:owner_id"),
                {"owner_id": owner_id},
            )
            == 0
        )
        assert (
            connection.scalar(
                text("SELECT count(*) FROM notification_preferences WHERE user_id=:owner_id"),
                {"owner_id": owner_id},
            )
            == 0
        )


def test_device_refresh_revocation_and_prohibited_values_stay_protected(
    profile_database: tuple[Engine, str], caplog: pytest.LogCaptureFixture
) -> None:
    engine, database_url = profile_database
    repository = IdentityRepository(engine)
    owner = auth(f"device-owner-{uuid4()}")
    other = auth(f"device-other-{uuid4()}")
    repository.bootstrap(owner, default_timezone="Asia/Colombo", default_locale="en-LK")
    repository.bootstrap(other, default_timezone="Asia/Colombo", default_locale="en-LK")
    settings = Settings(
        _env_file=None,
        database_url=database_url,
        device_encryption_key=base64.b64encode(b"e" * 32).decode(),
        device_fingerprint_key=base64.b64encode(b"f" * 32).decode(),
    )
    service = IdentityService(repository, settings)
    installation_id = uuid4()
    first_token = "synthetic-push-token-one"
    second_token = "synthetic-push-token-two"
    first, created = service.register_device(
        request(owner),
        DeviceRegistrationRequest(
            installation_id=installation_id,
            platform="android",
            push_token=first_token,
            locale="en-LK",
            timezone="Asia/Colombo",
            app_version="1.0.0",
        ),
        idempotency_key=str(uuid4()),
    )
    assert created is True
    assert first_token not in first.model_dump_json()
    with engine.connect() as connection:
        stored = (
            connection.execute(
                text(
                    "SELECT push_token_ciphertext, token_fingerprint FROM device_registrations "
                    "WHERE id=:device_id"
                ),
                {"device_id": first.id},
            )
            .mappings()
            .one()
        )
    assert bytes(stored["push_token_ciphertext"]) != first_token.encode()
    assert stored["token_fingerprint"] != first_token
    assert stored["token_fingerprint"] != hashlib.sha256(first_token.encode()).hexdigest()

    refreshed, created = service.register_device(
        request(owner),
        DeviceRegistrationRequest(
            installation_id=installation_id,
            platform="android",
            push_token=second_token,
            locale="en-LK",
            timezone="Asia/Colombo",
            app_version="1.1.0",
        ),
        idempotency_key=str(uuid4()),
    )
    assert created is False
    assert refreshed.id == first.id
    assert refreshed.app_version == "1.1.0"
    repository.delete_device(other, first.id)
    with engine.connect() as connection:
        assert connection.scalar(
            text("SELECT revoked_at IS NULL FROM device_registrations WHERE id=:id"),
            {"id": first.id},
        )
    repository.delete_device(owner, first.id)
    repository.delete_device(owner, first.id)
    with engine.connect() as connection:
        assert connection.scalar(
            text(
                "SELECT revoked_at IS NOT NULL AND push_token_ciphertext IS NULL "
                "AND token_fingerprint IS NULL FROM device_registrations WHERE id=:id"
            ),
            {"id": first.id},
        )
    captured = caplog.text
    assert first_token not in captured
    assert second_token not in captured
    assert "synthetic-authorization-value" not in captured


def test_profile_request_validation_is_strict() -> None:
    with pytest.raises(ValueError):
        ProfileUpdateRequest.model_validate({"version": 1, "display_name": "   "})
    with pytest.raises(ValueError):
        ProfileUpdateRequest.model_validate({"version": 1, "unknown": "value"})
    with pytest.raises(ValueError):
        ProfilePreferencesUpdateRequest.model_validate(
            {"version": 1, "preferred_window_start_local": "18:00:00"}
        )
