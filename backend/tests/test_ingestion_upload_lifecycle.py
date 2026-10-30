from __future__ import annotations

import base64
import concurrent.futures
import hashlib
import os
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any
from uuid import UUID, uuid4

import pytest
from alembic import command
from alembic.config import Config
from pydantic import SecretStr
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

from memora.api.errors import ApiError
from memora.api.security import AuthContext, AuthenticatedRequest
from memora.api.v1.schemas.ingestion import (
    CreateLearningUpdateRequest,
    DeclaredFile,
    FinalizeUploadRequest,
    LearningUpdateResponse,
    UploadGrantRequest,
)
from memora.core.config import Settings
from memora.db.seed import seed_database
from memora.modules.ingestion.repository import IngestionRepository
from memora.modules.ingestion.service import IngestionService, ManualTextProtector
from memora.modules.ingestion.storage import MemoryObjectStorage, StorageUnavailable

BACKEND_ROOT = Path(__file__).resolve().parents[1]
PHYSICS_SUBJECT_ID = UUID("10000000-0000-0000-0000-000000000001")
INGESTION_KEY = "cGe/2UxRnTY3D17CPcFSnrHkGqBSwmcmJ+ehN4XFMxc="
PDF_CONTENT = b"%PDF-1.7\nSynthetic Physics Ingestion Notes"


@pytest.fixture(scope="module")
def ingestion_engine() -> Engine:
    database_url = os.getenv("MEMORA_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("MEMORA_TEST_DATABASE_URL is not configured")
    monkeypatch = pytest.MonkeyPatch()
    monkeypatch.setenv("MEMORA_DATABASE_URL", database_url)
    config = Config(BACKEND_ROOT / "alembic.ini")
    config.set_main_option("script_location", str(BACKEND_ROOT / "migrations"))
    config.set_main_option("sqlalchemy.url", database_url.replace("%", "%%"))
    command.upgrade(config, "head")
    seed_database(database_url)
    engine = create_engine(database_url, connect_args={"connect_timeout": 10})
    yield engine
    engine.dispose()
    monkeypatch.undo()


def _create_user(engine: Engine) -> AuthenticatedRequest:
    now = datetime.now(UTC)
    subject = str(uuid4())
    with engine.begin() as connection:
        user_id = connection.scalar(
            text("""
                INSERT INTO users(
                    oidc_issuer, oidc_subject, status, default_timezone, locale
                ) VALUES ('https://synthetic.supabase.co/auth/v1', :subject, 'active',
                          'Asia/Colombo', 'en-LK')
                RETURNING id
                """),
            {"subject": subject},
        )
        for consent_type in ("terms", "privacy", "material_processing", "model_processing"):
            connection.execute(
                text("""
                    INSERT INTO consent_records(
                        user_id, consent_type, policy_version, decision, decided_at, evidence
                    ) VALUES (
                        :user_id, :consent_type, 'synthetic-v1', 'granted', now(),
                        '{"schema_version":"1"}'
                    )
                    """),
                {"user_id": user_id, "consent_type": consent_type},
            )
    return AuthenticatedRequest(
        context=AuthContext(
            issuer="https://synthetic.supabase.co/auth/v1",
            subject=subject,
            session_id=uuid4(),
            role="authenticated",
            authenticated_at=now,
            expires_at=now + timedelta(minutes=5),
        ),
        access_token=SecretStr("synthetic-token"),
    )


class OutageObjectStorage(MemoryObjectStorage):
    """Storage mock that simulates service downtime."""

    def __init__(self, fail_on_get: bool = True) -> None:
        super().__init__()
        self.fail_on_get = fail_on_get

    def get_object(self, object_key: str) -> bytes:
        if self.fail_on_get:
            raise StorageUnavailable("Storage service connection timeout")
        return super().get_object(object_key)


@pytest.fixture
def upload_context(ingestion_engine: Engine) -> dict[str, Any]:
    with ingestion_engine.begin() as connection:
        connection.execute(
            text(
                "TRUNCATE background_jobs, outbox_events, learning_updates, "
                "source_uploads, extraction_candidates, verification_requests, "
                "verification_decisions, knowledge_commits, private_knowledge_items, "
                "deletion_proofs, idempotency_records, audit_events CASCADE"
            )
        )
    settings = Settings(
        _env_file=None,
        environment="local",
        database_url=os.environ["MEMORA_TEST_DATABASE_URL"],
        ingestion_encryption_key=SecretStr(INGESTION_KEY),
        extraction_provider="deterministic",
        object_storage_provider="memory",
        upload_max_bytes=1048576,
        upload_grant_ttl_seconds=900,
        ingestion_expiry_hours=72,
        verification_expiry_hours=72,
    )
    storage = MemoryObjectStorage()
    protector = ManualTextProtector(base64.b64decode(INGESTION_KEY))
    repository = IngestionRepository(ingestion_engine)
    service = IngestionService(repository, storage, settings, protector)
    return {
        "engine": ingestion_engine,
        "service": service,
        "repository": repository,
        "storage": storage,
        "settings": settings,
        "auth": _create_user(ingestion_engine),
        "other_auth": _create_user(ingestion_engine),
    }


def _create_pdf_update(context: dict[str, Any]) -> tuple[Any, str]:
    digest = hashlib.sha256(PDF_CONTENT).hexdigest()
    service = context["service"]
    auth = context["auth"]
    created = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="pdf",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            files=[
                DeclaredFile(
                    declared_name="physics_notes.pdf",
                    declared_media_type="application/pdf",
                    byte_size=len(PDF_CONTENT),
                    content_sha256=digest,
                )
            ],
        ),
        idempotency_key=str(uuid4()),
    )
    return created, digest


def test_upload_grant_structure_and_transition(upload_context: dict[str, Any]) -> None:
    service = upload_context["service"]
    auth = upload_context["auth"]
    created, digest = _create_pdf_update(upload_context)

    assert created.status == "uploading"

    grant = service.grant(
        auth,
        created.id,
        UploadGrantRequest(
            declared_name="physics_notes.pdf",
            declared_media_type="application/pdf",
            byte_size=len(PDF_CONTENT),
            content_sha256=digest,
        ),
        idempotency_key=str(uuid4()),
    )

    assert grant.upload_id is not None
    assert grant.method == "PUT"
    assert grant.url.startswith("memory://uploads/")
    assert grant.required_headers == {"Content-Type": "application/pdf"}
    assert grant.max_bytes == upload_context["settings"].upload_max_bytes
    assert grant.checksum_rule == "SHA-256 hex digest of the exact uploaded bytes"
    assert grant.expires_at > datetime.now(UTC)


def test_finalize_verifies_checksum_and_size_bounds(upload_context: dict[str, Any]) -> None:
    service = upload_context["service"]
    auth = upload_context["auth"]
    storage = upload_context["storage"]
    created, digest = _create_pdf_update(upload_context)

    grant = service.grant(
        auth,
        created.id,
        UploadGrantRequest(
            declared_name="physics_notes.pdf",
            declared_media_type="application/pdf",
            byte_size=len(PDF_CONTENT),
            content_sha256=digest,
        ),
        idempotency_key=str(uuid4()),
    )

    upload = upload_context["repository"].get_upload(auth.context, created.id, grant.upload_id)
    storage.put_object(upload["object_key"], PDF_CONTENT, "application/pdf")

    # Mismatched observed size fails
    with pytest.raises(ApiError) as size_err:
        service.finalize(
            auth,
            created.id,
            grant.upload_id,
            FinalizeUploadRequest(
                observed_size=len(PDF_CONTENT) + 50,
                content_sha256=digest,
                client_operation_id=uuid4(),
            ),
            idempotency_key=str(uuid4()),
        )
    assert size_err.value.status_code == 422
    assert size_err.value.code == "validation_failed"

    # Mismatched checksum fails
    with pytest.raises(ApiError) as hash_err:
        service.finalize(
            auth,
            created.id,
            grant.upload_id,
            FinalizeUploadRequest(
                observed_size=len(PDF_CONTENT),
                content_sha256="0" * 64,
                client_operation_id=uuid4(),
            ),
            idempotency_key=str(uuid4()),
        )
    assert hash_err.value.status_code == 422
    assert hash_err.value.code == "validation_failed"


def test_duplicate_finalize_converges_and_queues_one_job(
    upload_context: dict[str, Any],
) -> None:
    service = upload_context["service"]
    auth = upload_context["auth"]
    storage = upload_context["storage"]
    engine = upload_context["engine"]
    created, digest = _create_pdf_update(upload_context)

    grant = service.grant(
        auth,
        created.id,
        UploadGrantRequest(
            declared_name="physics_notes.pdf",
            declared_media_type="application/pdf",
            byte_size=len(PDF_CONTENT),
            content_sha256=digest,
        ),
        idempotency_key=str(uuid4()),
    )

    upload = upload_context["repository"].get_upload(auth.context, created.id, grant.upload_id)
    storage.put_object(upload["object_key"], PDF_CONTENT, "application/pdf")

    finalize_body = FinalizeUploadRequest(
        observed_size=len(PDF_CONTENT),
        content_sha256=digest,
        client_operation_id=uuid4(),
    )

    # First finalize
    first_res = service.finalize(
        auth,
        created.id,
        grant.upload_id,
        finalize_body,
        idempotency_key=str(uuid4()),
    )
    assert first_res.status == "processing"

    # Duplicate finalize converges to same processing status
    second_res = service.finalize(
        auth,
        created.id,
        grant.upload_id,
        finalize_body,
        idempotency_key=str(uuid4()),
    )
    assert second_res.status == "processing"

    # Exactly one background job enqueued
    with engine.connect() as connection:
        job_count = connection.scalar(
            text(
                "SELECT count(*) FROM background_jobs "
                "WHERE dedupe_key = :key AND job_type = 'ingestion.extract'"
            ),
            {"key": f"extract:{created.id}"},
        )
        assert job_count == 1


def test_concurrent_duplicate_finalize_converges(
    upload_context: dict[str, Any],
) -> None:
    service = upload_context["service"]
    auth = upload_context["auth"]
    storage = upload_context["storage"]
    engine = upload_context["engine"]
    created, digest = _create_pdf_update(upload_context)

    grant = service.grant(
        auth,
        created.id,
        UploadGrantRequest(
            declared_name="physics_notes.pdf",
            declared_media_type="application/pdf",
            byte_size=len(PDF_CONTENT),
            content_sha256=digest,
        ),
        idempotency_key=str(uuid4()),
    )

    upload = upload_context["repository"].get_upload(auth.context, created.id, grant.upload_id)
    storage.put_object(upload["object_key"], PDF_CONTENT, "application/pdf")

    finalize_body = FinalizeUploadRequest(
        observed_size=len(PDF_CONTENT),
        content_sha256=digest,
        client_operation_id=uuid4(),
    )

    def _call() -> LearningUpdateResponse:
        return service.finalize(
            auth,
            created.id,
            grant.upload_id,
            finalize_body,
            idempotency_key=str(uuid4()),
        )

    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        f1 = executor.submit(_call)
        f2 = executor.submit(_call)
        res1 = f1.result()
        res2 = f2.result()

    assert res1.status == "processing"
    assert res2.status == "processing"

    with engine.connect() as connection:
        job_count = connection.scalar(
            text(
                "SELECT count(*) FROM background_jobs "
                "WHERE dedupe_key = :key AND job_type = 'ingestion.extract'"
            ),
            {"key": f"extract:{created.id}"},
        )
        assert job_count == 1


def test_cross_user_upload_returns_404(upload_context: dict[str, Any]) -> None:
    service = upload_context["service"]
    auth = upload_context["auth"]
    other_auth = upload_context["other_auth"]
    created, digest = _create_pdf_update(upload_context)

    grant = service.grant(
        auth,
        created.id,
        UploadGrantRequest(
            declared_name="physics_notes.pdf",
            declared_media_type="application/pdf",
            byte_size=len(PDF_CONTENT),
            content_sha256=digest,
        ),
        idempotency_key=str(uuid4()),
    )

    finalize_body = FinalizeUploadRequest(
        observed_size=len(PDF_CONTENT),
        content_sha256=digest,
        client_operation_id=uuid4(),
    )

    with pytest.raises(ApiError) as captured:
        service.finalize(
            other_auth,
            created.id,
            grant.upload_id,
            finalize_body,
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 404
    assert captured.value.code == "resource_not_found"


def test_expired_grant_fails_with_safe_code(upload_context: dict[str, Any]) -> None:
    service = upload_context["service"]
    auth = upload_context["auth"]
    storage = upload_context["storage"]
    engine = upload_context["engine"]
    created, digest = _create_pdf_update(upload_context)

    grant = service.grant(
        auth,
        created.id,
        UploadGrantRequest(
            declared_name="physics_notes.pdf",
            declared_media_type="application/pdf",
            byte_size=len(PDF_CONTENT),
            content_sha256=digest,
        ),
        idempotency_key=str(uuid4()),
    )

    upload = upload_context["repository"].get_upload(auth.context, created.id, grant.upload_id)
    storage.put_object(upload["object_key"], PDF_CONTENT, "application/pdf")

    # Force grant to expire
    with engine.begin() as connection:
        connection.execute(
            text("UPDATE source_uploads SET expires_at = now() - interval '1 hour' WHERE id = :id"),
            {"id": grant.upload_id},
        )

    finalize_body = FinalizeUploadRequest(
        observed_size=len(PDF_CONTENT),
        content_sha256=digest,
        client_operation_id=uuid4(),
    )

    with pytest.raises(ApiError) as captured:
        service.finalize(
            auth,
            created.id,
            grant.upload_id,
            finalize_body,
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 409
    assert captured.value.code == "invalid_state"
    assert "expired" in captured.value.message.lower()


def test_retry_rejected_for_non_failed_updates(upload_context: dict[str, Any]) -> None:
    service = upload_context["service"]
    auth = upload_context["auth"]
    created, _ = _create_pdf_update(upload_context)

    # Created update is uploading (non-failed), retry must fail with 409
    with pytest.raises(ApiError) as captured:
        service.retry(
            auth,
            created.id,
            stage="extraction",
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 409
    assert captured.value.code == "invalid_state"


def test_retry_after_commit_fails_with_409(upload_context: dict[str, Any]) -> None:
    service = upload_context["service"]
    auth = upload_context["auth"]
    engine = upload_context["engine"]
    created, _ = _create_pdf_update(upload_context)

    with engine.begin() as connection:
        connection.execute(
            text("UPDATE learning_updates SET status = 'committed' WHERE id = :id"),
            {"id": created.id},
        )

    with pytest.raises(ApiError) as captured:
        service.retry(
            auth,
            created.id,
            stage="extraction",
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 409
    assert captured.value.code == "invalid_state"


def test_retry_succeeds_for_failed_update(upload_context: dict[str, Any]) -> None:
    service = upload_context["service"]
    auth = upload_context["auth"]
    engine = upload_context["engine"]
    created, _ = _create_pdf_update(upload_context)

    # Mark update as failed
    with engine.begin() as connection:
        connection.execute(
            text(
                "UPDATE learning_updates SET status = 'failed', failure_code = 'extraction_failed' "
                "WHERE id = :id"
            ),
            {"id": created.id},
        )

    retried = service.retry(
        auth,
        created.id,
        stage="extraction",
        idempotency_key=str(uuid4()),
    )
    assert retried.status == "processing"
    assert retried.failure_code is None


def test_retry_deletion_revives_dead_lettered_job_for_committed_update(
    upload_context: dict[str, Any],
) -> None:
    service = upload_context["service"]
    auth = upload_context["auth"]
    engine = upload_context["engine"]
    created, digest = _create_pdf_update(upload_context)

    grant = service.grant(
        auth,
        created.id,
        UploadGrantRequest(
            declared_name="physics_notes.pdf",
            declared_media_type="application/pdf",
            byte_size=len(PDF_CONTENT),
            content_sha256=digest,
        ),
        idempotency_key=str(uuid4()),
    )

    with engine.begin() as connection:
        user_id = connection.scalar(
            text("SELECT user_id FROM learning_updates WHERE id = :id"),
            {"id": created.id},
        )
        connection.execute(
            text("UPDATE source_uploads SET status = 'deleting' WHERE id = :id"),
            {"id": grant.upload_id},
        )
        connection.execute(
            text("UPDATE learning_updates SET status = 'committed' WHERE id = :id"),
            {"id": created.id},
        )
        connection.execute(
            text("""
                INSERT INTO background_jobs(
                    job_type, owner_user_id, resource_type, resource_id,
                    dedupe_key, status, attempt_count, max_attempts, available_at,
                    last_error_code, payload
                ) VALUES (
                    'ingestion.delete_upload', :user_id, 'source_upload', :upload_id,
                    :dedupe_key, 'dead_lettered', 5, 5, now() - interval '1 hour',
                    'deletion_failed', '{"schema_version":"1"}'::jsonb
                )
                """),
            {
                "user_id": user_id,
                "upload_id": grant.upload_id,
                "dedupe_key": f"delete_upload:{grant.upload_id}",
            },
        )

    retried = service.retry(
        auth,
        created.id,
        stage="deletion",
        idempotency_key=str(uuid4()),
    )
    assert retried.status == "committed"

    with engine.connect() as connection:
        job = (
            connection.execute(
                text(
                    "SELECT status, attempt_count, last_error_code FROM background_jobs "
                    "WHERE dedupe_key = :key"
                ),
                {"key": f"delete_upload:{grant.upload_id}"},
            )
            .mappings()
            .first()
        )
        assert job is not None
        assert job["status"] == "queued"
        assert job["attempt_count"] == 0
        assert job["last_error_code"] is None


def test_retry_deletion_without_pending_source_rejected(
    upload_context: dict[str, Any],
) -> None:
    service = upload_context["service"]
    auth = upload_context["auth"]
    engine = upload_context["engine"]
    created, digest = _create_pdf_update(upload_context)

    grant = service.grant(
        auth,
        created.id,
        UploadGrantRequest(
            declared_name="physics_notes.pdf",
            declared_media_type="application/pdf",
            byte_size=len(PDF_CONTENT),
            content_sha256=digest,
        ),
        idempotency_key=str(uuid4()),
    )

    with engine.begin() as connection:
        connection.execute(
            text("UPDATE source_uploads SET status = 'deleted', deleted_at = now() WHERE id = :id"),
            {"id": grant.upload_id},
        )
        connection.execute(
            text("UPDATE learning_updates SET status = 'committed' WHERE id = :id"),
            {"id": created.id},
        )

    with pytest.raises(ApiError) as captured:
        service.retry(
            auth,
            created.id,
            stage="deletion",
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 409
    assert captured.value.code == "invalid_state"


def test_storage_outage_mapped_to_503(upload_context: dict[str, Any]) -> None:
    outage_storage = OutageObjectStorage(fail_on_get=True)
    outage_service = IngestionService(
        upload_context["repository"],
        outage_storage,
        upload_context["settings"],
        ManualTextProtector(base64.b64decode(INGESTION_KEY)),
    )
    auth = upload_context["auth"]
    created, digest = _create_pdf_update(upload_context)

    grant = outage_service.grant(
        auth,
        created.id,
        UploadGrantRequest(
            declared_name="physics_notes.pdf",
            declared_media_type="application/pdf",
            byte_size=len(PDF_CONTENT),
            content_sha256=digest,
        ),
        idempotency_key=str(uuid4()),
    )

    upload = upload_context["repository"].get_upload(auth.context, created.id, grant.upload_id)
    outage_storage.put_object(upload["object_key"], PDF_CONTENT, "application/pdf")

    finalize_body = FinalizeUploadRequest(
        observed_size=len(PDF_CONTENT),
        content_sha256=digest,
        client_operation_id=uuid4(),
    )

    with pytest.raises(ApiError) as captured:
        outage_service.finalize(
            auth,
            created.id,
            grant.upload_id,
            finalize_body,
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 503
    assert captured.value.code == "temporarily_unavailable"
