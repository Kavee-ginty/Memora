from __future__ import annotations

import io
import json
import zipfile
from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest

from memora.core.config import Settings
from memora.modules.ingestion.storage import MemoryObjectStorage
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
    AuthProviderError,
    MemoryAuthProvider,
    SupabaseAuthProvider,
)
from memora.modules.privacy.storage import (
    delete_export_archive,
    export_archive_exists,
    generate_export_download_token,
    get_export_archive_bytes,
    get_privacy_object_storage,
    purge_upload_object,
    set_privacy_object_storage,
    verify_export_download_token,
    write_export_archive,
)
from memora.worker.memory import (
    MAX_JOB_ATTEMPTS,
    RETRY_BACKOFF_SECONDS,
    NonRetryableJobError,
)


def test_export_archive_packaging_and_readability() -> None:
    mem_storage = MemoryObjectStorage()
    set_privacy_object_storage(mem_storage)
    try:
        request_id = uuid4()
        user_id = uuid4()
        export_data = {
            "schema_version": "1.0",
            "request_id": str(request_id),
            "profile": {"display_name": "Ada Lovelace", "active_subject": "Physics"},
            "concept_progress": [{"concept_id": str(uuid4()), "stability": 4.5}],
        }
        raw_json = json.dumps(export_data, indent=2).encode("utf-8")
        summary = "Student: Ada Lovelace\nConcepts: 1\n"

        assert not export_archive_exists(request_id)

        key = write_export_archive(request_id, user_id, raw_json, summary)
        assert key == f"exports/{request_id}.zip"
        assert export_archive_exists(request_id)

        archive_bytes = get_export_archive_bytes(request_id)
        assert len(archive_bytes) > 0

        # Inspect zip contents
        with zipfile.ZipFile(io.BytesIO(archive_bytes), mode="r") as zf:
            namelist = zf.namelist()
            assert "export.json" in namelist
            assert "summary.txt" in namelist

            extracted_json = json.loads(zf.read("export.json").decode("utf-8"))
            assert extracted_json["schema_version"] == "1.0"
            assert extracted_json["profile"]["display_name"] == "Ada Lovelace"

            extracted_summary = zf.read("summary.txt").decode("utf-8")
            assert "Ada Lovelace" in extracted_summary

        delete_export_archive(request_id)
        assert not export_archive_exists(request_id)
    finally:
        set_privacy_object_storage(None)


def test_local_privacy_storage_is_shared_between_calls() -> None:
    set_privacy_object_storage(None)
    assert get_privacy_object_storage() is get_privacy_object_storage()


def test_export_download_tokens_and_expiry() -> None:
    request_id = uuid4()
    user_id = uuid4()
    now = datetime.now(UTC)

    # Valid token
    valid_exp = now + timedelta(hours=1)
    token = generate_export_download_token(request_id, user_id, valid_exp)
    assert verify_export_download_token(request_id, user_id, token) is True

    # Reject different user or request
    other_user = uuid4()
    assert verify_export_download_token(request_id, other_user, token) is False
    assert verify_export_download_token(uuid4(), user_id, token) is False

    # Reject tampered token
    tampered = token[:-2] + "00"
    assert verify_export_download_token(request_id, user_id, tampered) is False

    # Reject expired token
    past_exp = now - timedelta(seconds=10)
    expired_token = generate_export_download_token(request_id, user_id, past_exp)
    assert verify_export_download_token(request_id, user_id, expired_token) is False


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
    assert len(LEGAL_RETENTION_EXCEPTIONS) >= 1


def test_auth_provider_interface_and_memory_provider() -> None:
    provider = MemoryAuthProvider(initial_users={"sub-123", "sub-456"})
    uid = uuid4()

    assert provider.verify_user_absent(uid, "sub-123") is False
    assert provider.delete_user(uid, "sub-123") is True
    assert provider.verify_user_absent(uid, "sub-123") is True


def test_supabase_provider_fails_closed_without_admin_credentials() -> None:
    provider = SupabaseAuthProvider(Settings(_env_file=None, supabase_url=None))

    with pytest.raises(AuthProviderError, match="URL is not configured"):
        provider.delete_user(uuid4(), "provider-user-id")
    with pytest.raises(AuthProviderError, match="URL is not configured"):
        provider.verify_user_absent(uuid4(), "provider-user-id")


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
    mem_storage = MemoryObjectStorage()
    set_privacy_object_storage(mem_storage)
    try:
        key = "uploads/temp/file-123.pdf"
        mem_storage.put_object(key, b"file-content")
        assert mem_storage.head_object(key) is not None

        assert purge_upload_object(key) is True
        assert mem_storage.head_object(key) is None
    finally:
        set_privacy_object_storage(None)
