from pathlib import Path

import pytest
from pydantic import SecretStr, ValidationError

from memora.core.config import LOCAL_DATABASE_URL, Settings

MANAGED_DATABASE_URL = "postgresql+psycopg://memora:managed-secret@db.staging.example:5432/memora"
DEPLOYED_IDENTITY_SETTINGS = {
    "supabase_url": "https://example.supabase.co",
    "supabase_publishable_key": "synthetic-publishable-key",
    "device_encryption_key": "YWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWE=",
    "device_fingerprint_key": "YmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmI=",
    "consent_terms_version": "test-v1",
    "consent_privacy_version": "test-v1",
    "consent_material_processing_version": "test-v1",
    "consent_model_processing_version": "test-v1",
    "consent_notifications_version": "test-v1",
}


@pytest.fixture(autouse=True)
def clear_memora_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    for name in (
        "MEMORA_ENVIRONMENT",
        "MEMORA_DATABASE_URL",
        "MEMORA_LOG_LEVEL",
        *(f"MEMORA_{name.upper()}" for name in DEPLOYED_IDENTITY_SETTINGS),
    ):
        monkeypatch.delenv(name, raising=False)


def test_settings_load_repository_env(monkeypatch, tmp_path: Path) -> None:
    backend = tmp_path / "backend"
    backend.mkdir()
    (tmp_path / ".env").write_text("MEMORA_LOG_LEVEL=DEBUG\n", encoding="utf-8")
    monkeypatch.setitem(Settings.model_config, "env_file", ("../.env", ".env"))
    monkeypatch.chdir(backend)

    assert Settings().log_level == "DEBUG"


def test_local_defaults_are_safe_for_development() -> None:
    settings = Settings(_env_file=None)

    assert settings.environment == "local"
    assert settings.database_url == LOCAL_DATABASE_URL
    assert settings.docs_enabled is True


def test_environment_is_read_from_process_environment(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("MEMORA_ENVIRONMENT", "staging")
    monkeypatch.setenv("MEMORA_DATABASE_URL", MANAGED_DATABASE_URL)
    for name, value in DEPLOYED_IDENTITY_SETTINGS.items():
        monkeypatch.setenv(f"MEMORA_{name.upper()}", value)

    settings = Settings(_env_file=None)

    assert settings.environment == "staging"
    assert settings.docs_enabled is False


@pytest.mark.parametrize("environment", ["development", "staging", "production"])
def test_non_local_environment_requires_explicit_database_url(
    environment: str,
) -> None:
    with pytest.raises(ValidationError, match="MEMORA_DATABASE_URL is required"):
        Settings(_env_file=None, environment=environment, database_url=None)


@pytest.mark.parametrize("environment", ["staging", "production"])
@pytest.mark.parametrize(
    "host",
    [
        "localhost",
        "LOCALHOST",
        "localhost.",
        "127.0.0.1",
        "127.0.0.2",
        "0.0.0.0",
        "::1",
        "::ffff:127.0.0.1",
        "postgres",
        "host.docker.internal",
    ],
)
def test_deployed_environments_reject_local_database_hosts(
    environment: str,
    host: str,
) -> None:
    url_host = f"[{host}]" if ":" in host else host
    database_url = f"postgresql+psycopg://memora:secret@{url_host}:5432/memora"

    with pytest.raises(ValidationError, match="non-local host"):
        Settings(
            _env_file=None,
            environment=environment,
            database_url=database_url,
        )


def test_development_may_use_a_local_database() -> None:
    settings = Settings(
        _env_file=None,
        environment="development",
        database_url=LOCAL_DATABASE_URL,
    )

    assert settings.docs_enabled is True


@pytest.mark.parametrize("environment", ["staging", "production"])
def test_deployed_environments_accept_managed_database(environment: str) -> None:
    settings = Settings(
        _env_file=None,
        environment=environment,
        database_url=MANAGED_DATABASE_URL,
        **DEPLOYED_IDENTITY_SETTINGS,
    )

    assert settings.database_url == MANAGED_DATABASE_URL
    assert settings.docs_enabled is False


def test_deployed_environment_requires_identity_settings() -> None:
    with pytest.raises(ValidationError, match="MEMORA_SUPABASE_URL"):
        Settings(
            _env_file=None,
            environment="production",
            database_url=MANAGED_DATABASE_URL,
        )


@pytest.mark.parametrize(
    "field",
    [
        "supabase_url",
        "supabase_publishable_key",
        "device_encryption_key",
        "device_fingerprint_key",
        "consent_terms_version",
        "consent_privacy_version",
        "consent_material_processing_version",
        "consent_model_processing_version",
        "consent_notifications_version",
    ],
)
def test_production_rejects_blank_identity_settings(field: str) -> None:
    with pytest.raises(ValidationError, match="Missing required identity settings"):
        Settings(
            _env_file=None,
            environment="production",
            database_url=MANAGED_DATABASE_URL,
            **{**DEPLOYED_IDENTITY_SETTINGS, field: "   "},
        )


def test_production_rejects_invalid_device_keys_and_unapproved_policies() -> None:
    with pytest.raises(ValidationError, match="decode to exactly 32 bytes"):
        Settings(
            _env_file=None,
            environment="production",
            database_url=MANAGED_DATABASE_URL,
            **{**DEPLOYED_IDENTITY_SETTINGS, "device_encryption_key": "c2hvcnQ="},
        )

    with pytest.raises(ValidationError, match="Unapproved consent policy versions"):
        Settings(
            _env_file=None,
            environment="production",
            database_url=MANAGED_DATABASE_URL,
            **{**DEPLOYED_IDENTITY_SETTINGS, "consent_terms_version": "unapproved-local-v1"},
        )


def test_production_disables_api_documentation() -> None:
    settings = Settings(
        _env_file=None,
        environment="production",
        database_url=MANAGED_DATABASE_URL,
        **DEPLOYED_IDENTITY_SETTINGS,
    )

    assert settings.docs_enabled is False


def test_invalid_environment_is_rejected() -> None:
    with pytest.raises(ValidationError):
        Settings(
            _env_file=None,
            environment="qa",
            database_url=LOCAL_DATABASE_URL,
        )


@pytest.mark.parametrize(
    "database_url",
    [
        "sqlite:///memora.db",
        "postgresql://memora:secret@localhost:5432/memora",
        "postgresql+psycopg2://memora:secret@localhost:5432/memora",
        "postgresql+asyncpg://memora:secret@localhost:5432/memora",
    ],
)
def test_unsupported_database_driver_is_rejected(database_url: str) -> None:
    with pytest.raises(ValidationError, match="psycopg driver"):
        Settings(
            _env_file=None,
            environment="local",
            database_url=database_url,
        )


def test_deployed_environment_requires_database_name() -> None:
    with pytest.raises(ValidationError, match="database name"):
        Settings(
            _env_file=None,
            environment="staging",
            database_url="postgresql+psycopg://memora:secret@db.staging.example:5432",
        )


def test_database_url_is_not_exposed_in_repr() -> None:
    settings = Settings(
        _env_file=None,
        environment="staging",
        database_url=MANAGED_DATABASE_URL,
        **DEPLOYED_IDENTITY_SETTINGS,
    )

    assert "managed-secret" not in repr(settings)
    assert "synthetic-publishable-key" not in repr(settings)


@pytest.mark.parametrize(
    ("environment", "database_url", "expected_docs_url"),
    [
        ("local", LOCAL_DATABASE_URL, "/docs"),
        ("development", LOCAL_DATABASE_URL, "/docs"),
        ("staging", MANAGED_DATABASE_URL, None),
        ("production", MANAGED_DATABASE_URL, None),
    ],
)
def test_app_docs_follow_environment_boundary(
    monkeypatch: pytest.MonkeyPatch,
    environment: str,
    database_url: str,
    expected_docs_url: str | None,
) -> None:
    from memora.main import create_app

    settings = Settings(
        _env_file=None,
        environment=environment,
        database_url=database_url,
        **(DEPLOYED_IDENTITY_SETTINGS if environment in {"staging", "production"} else {}),
    )
    monkeypatch.setattr("memora.main.get_settings", lambda: settings)

    app = create_app()

    assert app.docs_url == expected_docs_url
    assert app.redoc_url is None


def test_storage_and_ingestion_secrets_are_not_exposed_in_repr() -> None:
    settings = Settings(
        _env_file=None,
        environment="local",
        database_url=LOCAL_DATABASE_URL,
        ingestion_encryption_key=SecretStr("super-secret-ingestion-key"),
        openrouter_api_key=SecretStr("super-secret-openrouter-key"),
        object_storage_access_key=SecretStr("super-secret-s3-access"),
        object_storage_secret_key=SecretStr("super-secret-s3-secret"),
    )

    text_repr = repr(settings)
    assert "super-secret-ingestion-key" not in text_repr
    assert "super-secret-openrouter-key" not in text_repr
    assert "super-secret-s3-access" not in text_repr
    assert "super-secret-s3-secret" not in text_repr


def test_upload_and_storage_bounds() -> None:
    # Valid bounds
    settings = Settings(
        _env_file=None,
        environment="local",
        database_url=LOCAL_DATABASE_URL,
        upload_max_files=10,
        upload_max_bytes=50 * 1024 * 1024,
        upload_grant_ttl_seconds=1800,
        object_storage_provider="memory",
    )
    assert settings.upload_max_files == 10
    assert settings.upload_max_bytes == 50 * 1024 * 1024
    assert settings.upload_grant_ttl_seconds == 1800
    assert settings.object_storage_provider == "memory"

    # Out of bounds
    with pytest.raises(ValidationError):
        Settings(_env_file=None, database_url=LOCAL_DATABASE_URL, upload_max_files=0)
    with pytest.raises(ValidationError):
        Settings(_env_file=None, database_url=LOCAL_DATABASE_URL, upload_max_files=25)
    with pytest.raises(ValidationError):
        Settings(_env_file=None, database_url=LOCAL_DATABASE_URL, upload_max_bytes=500)
    with pytest.raises(ValidationError):
        Settings(_env_file=None, database_url=LOCAL_DATABASE_URL, upload_grant_ttl_seconds=30)
