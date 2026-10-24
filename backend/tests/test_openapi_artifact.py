import json
from pathlib import Path

from memora.api.export_openapi import (
    canonical_document,
    document_is_current,
    main,
    write_document,
)

ARTIFACT_PATH = Path(__file__).resolve().parents[2] / "contracts" / "openapi" / "memora-v1.json"


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
    assert set(schema["paths"]) == {"/health/live", "/health/ready"}
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
