from pathlib import Path

import pytest

from memora.db.env_file import database_url_from_env_file, read_dotenv


def test_read_dotenv_handles_comments_quotes_and_export(tmp_path: Path) -> None:
    env_file = tmp_path / ".env"
    env_file.write_text(
        "\n".join(
            [
                "# local only",
                "",
                "MEMORA_DATABASE_URL=postgresql+psycopg://memora:secret@127.0.0.1:5432/memora",
                "export POSTGRES_PASSWORD='quoted value'",
                'POSTGRES_USER="memora"',
                "IGNORED",
            ]
        ),
        encoding="utf-8",
    )

    values = read_dotenv(env_file)

    assert values["MEMORA_DATABASE_URL"].endswith("@127.0.0.1:5432/memora")
    assert values["POSTGRES_PASSWORD"] == "quoted value"
    assert values["POSTGRES_USER"] == "memora"
    assert "IGNORED" not in values


def test_database_url_from_env_file_uses_override(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path
) -> None:
    env_file = tmp_path / "local.env"
    env_file.write_text("MEMORA_DATABASE_URL=postgresql+psycopg://memora@127.0.0.1/memora\n")
    monkeypatch.setenv("MEMORA_ENV_FILE", str(env_file))

    assert database_url_from_env_file() == "postgresql+psycopg://memora@127.0.0.1/memora"


def test_database_url_from_env_file_returns_none_when_missing(tmp_path: Path) -> None:
    assert database_url_from_env_file(str(tmp_path / "missing.env")) is None


def test_database_url_from_env_file_returns_none_for_blank_value(tmp_path: Path) -> None:
    env_file = tmp_path / "blank.env"
    env_file.write_text("MEMORA_DATABASE_URL=\n", encoding="utf-8")

    assert database_url_from_env_file(str(env_file)) is None
