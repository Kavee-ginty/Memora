from __future__ import annotations

import base64
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

from memora.api.security import AuthContext, AuthenticatedRequest
from memora.api.v1.schemas.ingestion import (
    CreateLearningUpdateRequest,
    DeclaredFile,
    FinalizeUploadRequest,
    SubmitVerificationDecisionsRequest,
    UploadGrantRequest,
    VerificationDecision,
)
from memora.core.config import Settings
from memora.db.seed import seed_database
from memora.modules.ingestion.extraction import ExtractedCandidate
from memora.modules.ingestion.repository import IngestionRepository
from memora.modules.ingestion.service import IngestionService, ManualTextProtector
from memora.modules.ingestion.storage import MemoryObjectStorage
from memora.worker.ingestion import IngestionWorker

BACKEND_ROOT = Path(__file__).parents[1]
PHYSICS_SUBJECT_ID = UUID("10000000-0000-0000-0000-000000000001")
PDF = b"%PDF-1.7\nsynthetic notes about acceleration"
INGESTION_KEY = base64.b64encode(b"ssssssssssssssssssssssssssssssss").decode()


class FakeFileProvider:
    model_key = "fake-provider"
    prompt_version = "test-v1"

    def extract(
        self,
        *,
        manual_text: str | None,
        file_bytes: bytes | None,
        media_type: str | None,
        declared_name: str | None,
        aliases: list[dict[str, Any]],
    ) -> list[ExtractedCandidate]:
        assert file_bytes is not None
        return [
            ExtractedCandidate(
                candidate_type="concept",
                payload={
                    "schema_version": "1",
                    "title": "Acceleration",
                    "concept_id": aliases[0]["concept_id"],
                    "concept_version_id": aliases[0]["concept_version_id"],
                },
                source_locator={"schema_version": "1", "kind": "page", "page": 1},
                confidence=0.5,
            )
        ]


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


@pytest.fixture
def context(ingestion_engine: Engine) -> dict[str, Any]:
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
        ingestion_expiry_hours=72,
        verification_expiry_hours=72,
    )
    storage = MemoryObjectStorage()
    protector = ManualTextProtector(base64.b64decode(INGESTION_KEY))
    service = IngestionService(IngestionRepository(ingestion_engine), storage, settings, protector)
    worker = IngestionWorker(
        ingestion_engine,
        settings,
        storage=storage,
        protector=protector,
        worker_id=f"test-{uuid4()}",
    )
    return {
        "engine": ingestion_engine,
        "service": service,
        "storage": storage,
        "worker": worker,
        "settings": settings,
        "auth": _create_user(ingestion_engine, "manual"),
        "other": _create_user(ingestion_engine, "other"),
    }


def _create_user(engine: Engine, label: str) -> AuthContext:
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
        access_token=SecretStr("synthetic-access-token"),
    )


def _create_manual(context: dict[str, Any]) -> UUID:
    service = context["service"]
    update = service.create(
        context["auth"],
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Acceleration is the rate of change of velocity. F = m a",
        ),
        idempotency_key=str(uuid4()),
    )
    return update.id


def test_manual_text_verification_commit_and_replay(context: dict[str, Any]) -> None:
    service = context["service"]
    worker = context["worker"]
    update_id = _create_manual(context)
    assert service.get(context["auth"], update_id).status == "processing"
    assert worker.run_once() is True
    update = service.get(context["auth"], update_id)
    assert update.status == "verification_required"
    candidates = service.candidates(context["auth"], update_id, cursor=None, limit=20)
    assert candidates.items
    assert any(not item.requires_verification for item in candidates.items)
    pending = [item for item in candidates.items if item.requires_verification]
    assert pending
    preview = service.preview(context["auth"], update_id)
    assert preview.can_commit is False
    assert preview.blocked_reason == "verification_pending"
    service.decide(
        context["auth"],
        update_id,
        SubmitVerificationDecisionsRequest(
            decisions=[
                VerificationDecision(
                    candidate_id=item.id,
                    candidate_version=item.candidate_version,
                    decision="accept",
                )
                for item in pending
            ]
        ),
        idempotency_key=str(uuid4()),
    )
    preview = service.preview(context["auth"], update_id)
    assert preview.can_commit is True
    assert preview.blocked_reason is None
    key = str(uuid4())
    first = service.commit(context["auth"], update_id, idempotency_key=key)
    replay = service.commit(context["auth"], update_id, idempotency_key=key)
    assert first.knowledge_commit_id == replay.knowledge_commit_id
    assert first.commit_version == 1
    assert first.learning_update.status == "committed"
    with context["engine"].connect() as connection:
        assert (
            connection.scalar(
                text("SELECT count(*) FROM knowledge_commits WHERE learning_update_id=:id"),
                {"id": update_id},
            )
            == 1
        )
        assert (
            connection.scalar(
                text(
                    "SELECT count(*) FROM outbox_events "
                    "WHERE event_type='learning_update.committed' AND aggregate_id=:id"
                ),
                {"id": update_id},
            )
            == 1
        )


def test_owner_cannot_read_or_mutate_another_users_update(context: dict[str, Any]) -> None:
    service = context["service"]
    update_id = _create_manual(context)
    from memora.api.errors import ApiError

    with pytest.raises(ApiError) as captured:
        service.get(context["other"], update_id)
    assert captured.value.status_code == 404
    with pytest.raises(ApiError):
        service.preview(context["other"], update_id)


class FailingProvider:
    model_key = "failing-provider"
    prompt_version = "test-v1"

    def extract(self, **_: Any) -> list[ExtractedCandidate]:
        from memora.modules.ingestion.extraction import ExtractionUnavailable

        raise ExtractionUnavailable("Synthetic provider outage.")


def test_duplicate_finalize_queues_one_job(context: dict[str, Any]) -> None:
    service = context["service"]
    storage = context["storage"]
    digest = hashlib.sha256(PDF).hexdigest()
    created = service.create(
        context["auth"],
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="pdf",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            files=[
                DeclaredFile(
                    declared_name="notes.pdf",
                    declared_media_type="application/pdf",
                    byte_size=len(PDF),
                    content_sha256=digest,
                )
            ],
        ),
        idempotency_key=str(uuid4()),
    )
    grant = service.grant(
        context["auth"],
        created.id,
        UploadGrantRequest(
            declared_name="notes.pdf",
            declared_media_type="application/pdf",
            byte_size=len(PDF),
            content_sha256=digest,
        ),
        idempotency_key=str(uuid4()),
    )
    upload = IngestionRepository(context["engine"]).get_upload(
        context["auth"].context, created.id, grant.upload_id
    )
    storage.put_object(upload["object_key"], PDF, "application/pdf")
    body = FinalizeUploadRequest(
        observed_size=len(PDF), content_sha256=digest, client_operation_id=uuid4()
    )
    key = str(uuid4())
    first = service.finalize(
        context["auth"], created.id, grant.upload_id, body, idempotency_key=key
    )
    replay = service.finalize(
        context["auth"], created.id, grant.upload_id, body, idempotency_key=key
    )
    assert first.status == "processing"
    assert replay.status == "processing"
    with context["engine"].connect() as connection:
        assert (
            connection.scalar(
                text("SELECT count(*) FROM background_jobs WHERE dedupe_key = :key"),
                {"key": f"extract:{created.id}"},
            )
            == 1
        )
        assert (
            connection.scalar(
                text("SELECT count(*) FROM source_uploads WHERE learning_update_id = :update_id"),
                {"update_id": created.id},
            )
            == 1
        )


def test_worker_retries_then_dead_letters_without_logging_text(
    context: dict[str, Any], caplog: pytest.LogCaptureFixture
) -> None:
    service = context["service"]
    note = "Acceleration is the rate of change of velocity."
    update = service.create(
        context["auth"],
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text=note,
        ),
        idempotency_key=str(uuid4()),
    )
    worker = IngestionWorker(
        context["engine"],
        context["settings"],
        storage=context["storage"],
        protector=ManualTextProtector(base64.b64decode(INGESTION_KEY)),
        extractor=FailingProvider(),
        worker_id=f"failing-{uuid4()}",
    )
    for _ in range(5):
        assert worker.run_once() is True
        with context["engine"].begin() as connection:
            connection.execute(
                text(
                    "UPDATE background_jobs SET status='retry_wait', available_at=now() "
                    "WHERE status='retry_wait'"
                )
            )
    with context["engine"].connect() as connection:
        assert (
            connection.scalar(
                text("SELECT status FROM background_jobs WHERE resource_id=:update_id"),
                {"update_id": update.id},
            )
            == "dead_lettered"
        )
    assert service.get(context["auth"], update.id).status == "failed"
    assert service.get(context["auth"], update.id).failure_code == "extraction_unavailable"
    assert note not in caplog.text


def test_file_upload_finalize_verify_commit_and_deletion_proof(context: dict[str, Any]) -> None:
    service = context["service"]
    storage = context["storage"]
    file_worker = IngestionWorker(
        context["engine"],
        context["settings"],
        storage=storage,
        protector=None,
        extractor=FakeFileProvider(),
        worker_id=f"file-{uuid4()}",
    )
    digest = hashlib.sha256(PDF).hexdigest()
    created = service.create(
        context["auth"],
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="pdf",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            files=[
                DeclaredFile(
                    declared_name="notes.pdf",
                    declared_media_type="application/pdf",
                    byte_size=len(PDF),
                    content_sha256=digest,
                )
            ],
        ),
        idempotency_key=str(uuid4()),
    )
    assert created.status == "uploading"
    assert created.source_deletion_status == "not_required"
    grant = service.grant(
        context["auth"],
        created.id,
        UploadGrantRequest(
            declared_name="notes.pdf",
            declared_media_type="application/pdf",
            byte_size=len(PDF),
            content_sha256=digest,
        ),
        idempotency_key=str(uuid4()),
    )
    upload = IngestionRepository(context["engine"]).get_upload(
        context["auth"].context, created.id, grant.upload_id
    )
    storage.put_object(upload["object_key"], PDF, "application/pdf")
    finalize_body = FinalizeUploadRequest(
        observed_size=len(PDF), content_sha256=digest, client_operation_id=uuid4()
    )
    finalized = service.finalize(
        context["auth"], created.id, grant.upload_id, finalize_body, idempotency_key=str(uuid4())
    )
    assert finalized.status == "processing"
    assert file_worker.run_once() is True
    update = service.get(context["auth"], created.id)
    assert update.status == "verification_required"
    candidates = service.candidates(context["auth"], created.id, cursor=None, limit=20)
    assert len(candidates.items) == 1
    candidate = candidates.items[0]
    assert candidate.requires_verification is True
    service.decide(
        context["auth"],
        created.id,
        SubmitVerificationDecisionsRequest(
            decisions=[
                VerificationDecision(
                    candidate_id=candidate.id,
                    candidate_version=candidate.candidate_version,
                    decision="accept",
                )
            ]
        ),
        idempotency_key=str(uuid4()),
    )
    committed = service.commit(context["auth"], created.id, idempotency_key=str(uuid4()))
    assert committed.learning_update.status == "committed"
    assert file_worker.run_once() is True
    update = service.get(context["auth"], created.id)
    assert update.uploads[0].status == "deleted"
    assert update.source_deletion_status == "deleted"
    with context["engine"].connect() as connection:
        assert (
            connection.scalar(
                text(
                    "SELECT count(*) FROM deletion_proofs "
                    "WHERE source_upload_id=:id AND result='deleted'"
                ),
                {"id": grant.upload_id},
            )
            == 1
        )
