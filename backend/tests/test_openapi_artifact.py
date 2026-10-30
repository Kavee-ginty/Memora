import importlib
import json
import shutil
import sys
from pathlib import Path

from memora.api.export_openapi import (
    canonical_document,
    document_is_current,
    main,
    write_document,
)

REPO_ROOT = Path(__file__).resolve().parents[2]
ARTIFACT_PATH = REPO_ROOT / "contracts" / "openapi" / "memora-v1.json"


def _load_contract_tool():
    if str(REPO_ROOT) not in sys.path:
        sys.path.insert(0, str(REPO_ROOT))
    return importlib.import_module("tools.contracts.generate_contracts")


def test_artifact_is_current() -> None:
    assert document_is_current(ARTIFACT_PATH)


def test_artifact_is_canonical_and_environment_free() -> None:
    raw = ARTIFACT_PATH.read_bytes()
    text = raw.decode("utf-8")
    schema = json.loads(text)

    assert text == json.dumps(schema, sort_keys=True, indent=2, ensure_ascii=False) + "\n"
    assert text == canonical_document()
    assert raw.endswith(b"\n")
    assert not raw.endswith(b"\n\n")
    assert b"\r" not in raw
    assert "localhost" not in text
    assert "127.0.0.1" not in text
    assert "servers" not in schema
    assert schema["openapi"] == "3.1.0"
    assert set(schema["paths"]) == {
        "/health/live",
        "/health/ready",
        "/v1/concepts/{concept_id}/history",
        "/v1/consent",
        "/v1/consent/acceptances",
        "/v1/devices",
        "/v1/devices/{device_id}",
        "/v1/question-reports",
        "/v1/question-reports/{report_id}",
        "/v1/questions/{question_version_id}/reports",
        "/v1/session/bootstrap",
        "/v1/session/revoke",
        "/v1/subjects/{subject_id}/concept-progress",
    }
    assert "bearerAuth" in schema["components"]["securitySchemes"]
    assert {
        "ErrorEnvelope",
        "PageMeta",
        "RequestHeaders",
        "IdempotencyHeaders",
    } <= set(schema["components"]["schemas"])


def test_write_document_is_deterministic(tmp_path: Path) -> None:
    output = tmp_path / "nested" / "memora-v1.json"

    write_document(output)

    assert output.read_text(encoding="utf-8") == canonical_document()
    assert document_is_current(output)


def test_document_is_current_rejects_missing_file(tmp_path: Path) -> None:
    assert not document_is_current(tmp_path / "missing.json")


def test_document_is_current_rejects_crlf(tmp_path: Path) -> None:
    output = tmp_path / "memora-v1.json"
    output.write_bytes(canonical_document().replace("\n", "\r\n").encode("utf-8"))

    assert not document_is_current(output)


def test_document_is_current_rejects_stale_content(tmp_path: Path) -> None:
    output = tmp_path / "memora-v1.json"
    output.write_text(
        canonical_document().replace("Memora API", "Stale API"),
        encoding="utf-8",
        newline="\n",
    )

    assert not document_is_current(output)


def test_cli_check_accepts_current_artifact(capsys) -> None:
    assert main(["--check", "--output", str(ARTIFACT_PATH)]) == 0
    assert capsys.readouterr().err == ""


def test_cli_check_rejects_stale_artifact(tmp_path: Path, capsys) -> None:
    output = tmp_path / "stale.json"
    output.write_text("{}\n", encoding="utf-8", newline="\n")

    assert main(["--check", "--output", str(output)]) == 1
    assert "stale or invalid" in capsys.readouterr().err


def test_write_client_restores_lockfile(tmp_path: Path, monkeypatch) -> None:
    gen_tool = _load_contract_tool()

    client_dir = tmp_path / "memora_api_client"
    client_dir.mkdir()
    lockfile = client_dir / "pubspec.lock"
    lockfile_content = b"# Simulated pubspec.lock\npackages: {}\n"
    lockfile.write_bytes(lockfile_content)

    events: list[str] = []

    def mock_generate_client(jar: Path, output: Path) -> None:
        events.append("generate")
        # Generator wipes directory output
        shutil.rmtree(output)
        output.mkdir(parents=True, exist_ok=True)
        (output / "pubspec.yaml").write_text("name: memora_api_client\n")
        assert not (output / "pubspec.lock").exists()

    def mock_build_client(output: Path, *, enforce_lockfile: bool) -> None:
        events.append(f"build:enforce={enforce_lockfile}")
        # At build time, pubspec.lock must already have been restored
        assert (output / "pubspec.lock").read_bytes() == lockfile_content

    monkeypatch.setattr(gen_tool, "generate_client", mock_generate_client)
    monkeypatch.setattr(gen_tool, "_build_client", mock_build_client)

    dummy_jar = tmp_path / "fake-generator.jar"
    dummy_jar.write_text("jar")

    gen_tool.write_client(dummy_jar, client_dir=client_dir)

    assert events == ["generate", "build:enforce=True"]
    assert lockfile.read_bytes() == lockfile_content


def test_write_client_handles_absent_lockfile(tmp_path: Path, monkeypatch) -> None:
    gen_tool = _load_contract_tool()

    client_dir = tmp_path / "memora_api_client"
    client_dir.mkdir()

    events: list[str] = []

    def mock_generate_client(jar: Path, output: Path) -> None:
        events.append("generate")
        (output / "pubspec.yaml").write_text("name: memora_api_client\n")

    def mock_build_client(output: Path, *, enforce_lockfile: bool) -> None:
        events.append(f"build:enforce={enforce_lockfile}")
        assert not (output / "pubspec.lock").exists()

    monkeypatch.setattr(gen_tool, "generate_client", mock_generate_client)
    monkeypatch.setattr(gen_tool, "_build_client", mock_build_client)

    dummy_jar = tmp_path / "fake-generator.jar"
    dummy_jar.write_text("jar")

    gen_tool.write_client(dummy_jar, client_dir=client_dir)

    assert events == ["generate", "build:enforce=False"]
