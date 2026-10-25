from pathlib import Path

import pytest
from pydantic import ValidationError

from memora.core.config import LOCAL_DATABASE_URL, Settings

MANAGED_DATABASE_URL = "postgresql+psycopg://memora:managed-secret@db.staging.example:5432/memora"


@pytest.fixture(autouse=True)
def clear_memora_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    for name in ("MEMORA_ENVIRONMENT", "MEMORA_DATABASE_URL", "MEMORA_LOG_LEVEL"):
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
@pytest.mark.parametrize("host", ["localhost", "127.0.0.1", "postgres", "host.docker.internal"])
def test_deployed_environments_reject_local_database_hosts(
    environment: str,
    host: str,
) -> None:
    database_url = f"postgresql+psycopg://memora:secret@{host}:5432/memora"

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
    )

    assert settings.database_url == MANAGED_DATABASE_URL
    assert settings.docs_enabled is False


def test_production_disables_api_documentation() -> None:
    settings = Settings(
        _env_file=None,
        environment="production",
        database_url=MANAGED_DATABASE_URL,
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
    )

    assert "managed-secret" not in repr(settings)


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
    )
    monkeypatch.setattr("memora.main.get_settings", lambda: settings)

    app = create_app()

    assert app.docs_url == expected_docs_url
    assert app.redoc_url is None
