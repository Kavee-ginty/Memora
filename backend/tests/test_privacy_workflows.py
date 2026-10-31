from __future__ import annotations

import json
import zipfile
from uuid import uuid4

import pytest

from memora.modules.privacy.constants import (
    ALL_DELETION_SCOPES,
    ALLOWED_CANCELLATION_REASONS,
    EXPORT_DOWNLOAD_TTL_SECONDS,
    LEGAL_RETENTION_EXCEPTIONS,
    RECONCILER_VERSION,
    SCOPE_AUTH_PROVIDER,
    SCOPE_DATABASE,
    SCOPE_UPLOADS,
    WORKFLOW_VERSION,
)
from memora.modules.privacy.provider import (
    get_auth_provider,
    set_auth_provider,
)
from memora.modules.privacy.storage import (
    export_archive_exists,
    get_export_archive_path,
    purge_upload_object,
    write_export_archive,
)
from memora.worker.memory import (
    MAX_JOB_ATTEMPTS,
    RETRY_BACKOFF_SECONDS,
    NonRetryableJobError,
)


def test_export_archive_packaging_and_readability(
    tmp_path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setenv("MEMORA_EXPORT_STORAGE_DIR", str(tmp_path))
    request_id = uuid4()
    export_data = {
        "schema_version": "1.0",
        "request_id": str(request_id),
        "profile": {"display_name": "Ada Lovelace", "active_subject": "Physics"},
        "concept_progress": [{"concept_id": str(uuid4()), "stability": 4.5}],
    }
    raw_json = json.dumps(export_data, indent=2).encode("utf-8")
    summary = "Student: Ada Lovelace\nConcepts: 1\n"

    assert not export_archive_exists(request_id)

    path = write_export_archive(request_id, raw_json, summary)
    assert path.is_file()
    assert export_archive_exists(request_id)
    assert get_export_archive_path(request_id) == path

    # Inspect zip contents
    with zipfile.ZipFile(path, mode="r") as zf:
        namelist = zf.namelist()
        assert "export.json" in namelist
        assert "summary.txt" in namelist

        extracted_json = json.loads(zf.read("export.json").decode("utf-8"))
        assert extracted_json["schema_version"] == "1.0"
        assert extracted_json["profile"]["display_name"] == "Ada Lovelace"

        extracted_summary = zf.read("summary.txt").decode("utf-8")
        assert "Ada Lovelace" in extracted_summary


def test_allowed_cancellation_reasons_contain_known_codes() -> None:
    assert "user_requested" in ALLOWED_CANCELLATION_REASONS
    assert "accidental_request" in ALLOWED_CANCELLATION_REASONS
    assert "changed_mind" in ALLOWED_CANCELLATION_REASONS
    assert "retention_needed" in ALLOWED_CANCELLATION_REASONS
    assert "other" in ALLOWED_CANCELLATION_REASONS


def test_deletion_scopes_and_retention_exceptions_constants() -> None:
    assert SCOPE_DATABASE == "database_learner_state"
    assert SCOPE_UPLOADS == "temporary_uploads"
    assert SCOPE_AUTH_PROVIDER == "auth_provider"
    assert len(ALL_DELETION_SCOPES) == 3
    assert WORKFLOW_VERSION == "v1"
    assert RECONCILER_VERSION == "v1"
    assert EXPORT_DOWNLOAD_TTL_SECONDS == 86400
    assert len(LEGAL_RETENTION_EXCEPTIONS) >= 2


def test_auth_provider_interface_and_mocking() -> None:
    class MockAuthProvider:
        def __init__(self) -> None:
            self.deleted: list[tuple[str, str]] = []

        def delete_user(self, user_id, oidc_subject: str) -> bool:
            self.deleted.append((str(user_id), oidc_subject))
            return True

        def verify_user_absent(self, user_id, oidc_subject: str) -> bool:
            return True

    original = get_auth_provider()
    mock_prov = MockAuthProvider()
    set_auth_provider(mock_prov)
    try:
        uid = uuid4()
        assert get_auth_provider().delete_user(uid, "sub-123") is True
        assert mock_prov.deleted == [(str(uid), "sub-123")]
        assert get_auth_provider().verify_user_absent(uid, "sub-123") is True
    finally:
        set_auth_provider(original)


def test_retry_backoff_schedule() -> None:
    assert len(RETRY_BACKOFF_SECONDS) == 5
    assert RETRY_BACKOFF_SECONDS[0] == 15
    assert RETRY_BACKOFF_SECONDS[-1] == 1800
    assert MAX_JOB_ATTEMPTS == 5


def test_non_retryable_job_error_carries_code() -> None:
    err = NonRetryableJobError("invalid_payload")
    assert err.code == "invalid_payload"
    assert str(err) == "invalid_payload"


def test_purge_upload_object() -> None:
    assert purge_upload_object("uploads/temp/file-123.pdf") is True
