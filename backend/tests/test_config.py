from pathlib import Path

from memora.core.config import Settings


def test_settings_load_repository_env(monkeypatch, tmp_path: Path) -> None:
    backend = tmp_path / "backend"
    backend.mkdir()
    (tmp_path / ".env").write_text("MEMORA_LOG_LEVEL=DEBUG\n", encoding="utf-8")
    monkeypatch.chdir(backend)

    assert Settings().log_level == "DEBUG"
