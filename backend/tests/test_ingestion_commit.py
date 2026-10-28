from __future__ import annotations

import base64
import concurrent.futures
import hashlib
import logging
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
    UploadGrantRequest,
)
from memora.core.config import Settings
from memora.db.seed import seed_database
from memora.modules.ingestion.extraction import ExtractedCandidate
from memora.modules.ingestion.repository import IngestionRepository
from memora.modules.ingestion.service import IngestionService, ManualTextProtector
from memora.modules.ingestion.storage import MemoryObjectStorage
from memora.worker.ingestion import IngestionWorker

BACKEND_ROOT = Path(__file__).resolve().parents[1]
PHYSICS_SUBJECT_ID = UUID("10000000-0000-0000-0000-000000000001")
INGESTION_KEY = "cGe/2UxRnTY3D17CPcFSnrHkGqBSwmcmJ+ehN4XFMxc="
PDF_CONTENT = b"%PDF-1.7\nSynthetic notes for commit and deletion proof."


@pytest.fixture(scope="module")
def commit_engine() -> Engine:
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


class StubbornStorage(MemoryObjectStorage):
    """Storage mock that simulates deletion failure or lingering files."""

    def __init__(self, refuse_delete: bool = False) -> None:
        super().__init__()
        self.refuse_delete = refuse_delete

    def delete_object(self, object_key: str) -> None:
        if not self.refuse_delete:
            super().delete_object(object_key)


class FixedExtractionProvider:
    model_key = "fixed-test-provider"
    prompt_version = "v1"

    def __init__(self, candidates: list[ExtractedCandidate]) -> None:
        self.candidates = candidates

    def extract(self, **_: Any) -> list[ExtractedCandidate]:
        return list(self.candidates)


@pytest.fixture
def commit_context(commit_engine: Engine) -> dict[str, Any]:
    with commit_engine.begin() as connection:
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
    repository = IngestionRepository(commit_engine)
    service = IngestionService(repository, storage, settings, protector)
    auth = _create_user(commit_engine)
    other_auth = _create_user(commit_engine)
    return {
        "engine": commit_engine,
        "settings": settings,
        "storage": storage,
        "protector": protector,
        "repository": repository,
        "service": service,
        "auth": auth,
        "other_auth": other_auth,
    }


def _setup_verified_update(
    ctx: dict[str, Any],
    extra_candidates: list[ExtractedCandidate] | None = None,
) -> tuple[UUID, list[ExtractedCandidate]]:
    service = ctx["service"]
    auth = ctx["auth"]
    engine = ctx["engine"]

    # Approved concept from seeded physics database
    with engine.connect() as connection:
        alias = (
            connection.execute(
                text("""
                SELECT ca.concept_version_id, cv.concept_id, cv.title
                FROM concept_aliases ca
                JOIN concept_versions cv ON cv.id = ca.concept_version_id
                JOIN concepts c ON c.id = cv.concept_id
                WHERE c.subject_id = :subject_id AND c.status = 'approved'
                LIMIT 1
                """),
                {"subject_id": PHYSICS_SUBJECT_ID},
            )
            .mappings()
            .first()
        )

    candidates = [
        ExtractedCandidate(
            candidate_type="concept",
            payload={
                "title": alias["title"],
                "concept_id": str(alias["concept_id"]),
                "concept_version_id": str(alias["concept_version_id"]),
            },
            source_locator={"kind": "text_range", "start": 0, "end": 10},
            confidence=0.90,  # auto-accepted
        )
    ]
    if extra_candidates:
        candidates.extend(extra_candidates)

    update = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Verified update note for commit.",
        ),
        idempotency_key=str(uuid4()),
    )
    worker = IngestionWorker(
        engine,
        ctx["settings"],
        storage=ctx["storage"],
        protector=ctx["protector"],
        extractor=FixedExtractionProvider(candidates),
        worker_id=f"commit-worker-{uuid4()}",
    )
    assert worker.run_once() is True
    return update.id, candidates


# ---------------------------------------------------------------------------
# Idempotent Commit & Concurrency Tests
# ---------------------------------------------------------------------------


def test_commit_idempotent_replay_and_snapshot_hash(commit_context: dict[str, Any]) -> None:
    service = commit_context["service"]
    auth = commit_context["auth"]
    engine = commit_context["engine"]

    update_id, _ = _setup_verified_update(commit_context)
    key = str(uuid4())

    first_commit = service.commit(auth, update_id, idempotency_key=key)
    second_commit = service.commit(auth, update_id, idempotency_key=key)

    # Replay returns identical commit payload
    assert first_commit.knowledge_commit_id == second_commit.knowledge_commit_id
    assert first_commit.commit_version == second_commit.commit_version == 1
    assert first_commit.learning_update.status == "committed"

    # Exactly one row in knowledge_commits and one event in outbox_events
    with engine.connect() as connection:
        commits = (
            connection.execute(
                text(
                    "SELECT count(*), candidate_snapshot_hash FROM knowledge_commits "
                    "WHERE learning_update_id = :id GROUP BY candidate_snapshot_hash"
                ),
                {"id": update_id},
            )
            .mappings()
            .all()
        )
        assert len(commits) == 1
        assert commits[0]["count"] == 1
        assert len(commits[0]["candidate_snapshot_hash"]) == 64  # valid SHA-256

        outbox_count = connection.scalar(
            text(
                "SELECT count(*) FROM outbox_events "
                "WHERE aggregate_id = :id AND event_type = 'learning_update.committed'"
            ),
            {"id": update_id},
        )
        assert outbox_count == 1


def test_concurrent_commit_converges_to_single_commit(
    commit_context: dict[str, Any],
) -> None:
    service = commit_context["service"]
    auth = commit_context["auth"]
    engine = commit_context["engine"]

    update_id, _ = _setup_verified_update(commit_context)
    key = str(uuid4())

    def _do_commit() -> Any:
        return service.commit(auth, update_id, idempotency_key=key)

    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        f1 = executor.submit(_do_commit)
        f2 = executor.submit(_do_commit)
        res1 = f1.result()
        res2 = f2.result()

    assert res1.knowledge_commit_id == res2.knowledge_commit_id
    assert res1.learning_update.status == "committed"

    with engine.connect() as connection:
        commit_rows = connection.scalar(
            text("SELECT count(*) FROM knowledge_commits WHERE learning_update_id = :id"),
            {"id": update_id},
        )
        assert commit_rows == 1


def test_reused_idempotency_key_with_different_body_fails_with_409(
    commit_context: dict[str, Any],
) -> None:
    service = commit_context["service"]
    auth = commit_context["auth"]

    update_1, _ = _setup_verified_update(commit_context)
    update_2, _ = _setup_verified_update(commit_context)

    key = str(uuid4())
    service.commit(auth, update_1, idempotency_key=key)

    # Reusing same idempotency key for update_2
    with pytest.raises(ApiError) as captured:
        service.commit(auth, update_2, idempotency_key=key)
    assert captured.value.status_code == 409
    assert captured.value.code == "idempotency_key_reused"


# ---------------------------------------------------------------------------
# Commit Guards & Unmapped Private Knowledge
# ---------------------------------------------------------------------------


def test_unmapped_candidates_become_private_knowledge_items(
    commit_context: dict[str, Any],
) -> None:
    service = commit_context["service"]
    auth = commit_context["auth"]
    engine = commit_context["engine"]

    formula_candidate = ExtractedCandidate(
        candidate_type="formula",
        payload={"title": "Private Formula", "statement": "F = m a"},
        source_locator={"kind": "text_range", "start": 0, "end": 10},
        confidence=0.85,
    )
    unit_candidate = ExtractedCandidate(
        candidate_type="unit",
        payload={"title": "Private Unit", "statement": "m/s^2"},
        source_locator={"kind": "text_range", "start": 12, "end": 20},
        confidence=0.85,
    )

    update_id, _ = _setup_verified_update(
        commit_context, extra_candidates=[formula_candidate, unit_candidate]
    )

    commit_res = service.commit(auth, update_id, idempotency_key=str(uuid4()))
    assert commit_res.committed_counts["concept"] == 1
    assert commit_res.committed_counts["private"] == 2
    assert commit_res.private_knowledge_count == 2

    # Check private_knowledge_items persisted
    with engine.connect() as connection:
        private_items = (
            connection.execute(
                text("""
                SELECT item_type, structured_content, provenance
                FROM private_knowledge_items
                WHERE learning_update_id = :id
                ORDER BY item_type
                """),
                {"id": update_id},
            )
            .mappings()
            .all()
        )
        assert len(private_items) == 2
        assert private_items[0]["item_type"] == "formula"
        assert private_items[1]["item_type"] == "unit"
        assert "extraction_candidate" in private_items[0]["provenance"]["source"]


def test_expired_candidate_blocks_commit_with_409(
    commit_context: dict[str, Any],
) -> None:
    service = commit_context["service"]
    auth = commit_context["auth"]
    engine = commit_context["engine"]

    update_id, _ = _setup_verified_update(commit_context)

    # Force candidate to be expired
    with engine.begin() as connection:
        connection.execute(
            text(
                "UPDATE extraction_candidates SET status = 'expired' WHERE learning_update_id = :id"
            ),
            {"id": update_id},
        )

    with pytest.raises(ApiError) as captured:
        service.commit(auth, update_id, idempotency_key=str(uuid4()))
    assert captured.value.status_code == 409
    assert captured.value.code == "invalid_state"


def test_owner_isolation_on_commit(commit_context: dict[str, Any]) -> None:
    service = commit_context["service"]
    other_auth = commit_context["other_auth"]

    update_id, _ = _setup_verified_update(commit_context)

    with pytest.raises(ApiError) as captured:
        service.commit(other_auth, update_id, idempotency_key=str(uuid4()))
    assert captured.value.status_code == 404
    assert captured.value.code == "resource_not_found"


# ---------------------------------------------------------------------------
# Upload Deletion & Proven Absence Tests
# ---------------------------------------------------------------------------


def test_commit_enqueues_deletion_and_creates_deletion_proof_after_absence_confirmed(
    commit_context: dict[str, Any], caplog: pytest.LogCaptureFixture
) -> None:
    service = commit_context["service"]
    auth = commit_context["auth"]
    storage = commit_context["storage"]
    engine = commit_context["engine"]

    # 1. Create file update
    digest = hashlib.sha256(PDF_CONTENT).hexdigest()
    created = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="pdf",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            files=[
                DeclaredFile(
                    declared_name="test_notes.pdf",
                    declared_media_type="application/pdf",
                    byte_size=len(PDF_CONTENT),
                    content_sha256=digest,
                )
            ],
        ),
        idempotency_key=str(uuid4()),
    )
    grant = service.grant(
        auth,
        created.id,
        UploadGrantRequest(
            declared_name="test_notes.pdf",
            declared_media_type="application/pdf",
            byte_size=len(PDF_CONTENT),
            content_sha256=digest,
        ),
        idempotency_key=str(uuid4()),
    )
    upload = IngestionRepository(engine).get_upload(auth.context, created.id, grant.upload_id)
    storage.put_object(upload["object_key"], PDF_CONTENT, "application/pdf")
    finalize_body = FinalizeUploadRequest(
        observed_size=len(PDF_CONTENT),
        content_sha256=digest,
        client_operation_id=uuid4(),
    )
    service.finalize(auth, created.id, grant.upload_id, finalize_body, idempotency_key=str(uuid4()))

    # 2. Extract and auto-accept concept
    with engine.connect() as connection:
        alias = (
            connection.execute(
                text("""
                SELECT ca.concept_version_id, cv.concept_id, cv.title
                FROM concept_aliases ca
                JOIN concept_versions cv ON cv.id = ca.concept_version_id
                JOIN concepts c ON c.id = cv.concept_id
                WHERE c.subject_id = :subject_id AND c.status = 'approved'
                LIMIT 1
                """),
                {"subject_id": PHYSICS_SUBJECT_ID},
            )
            .mappings()
            .first()
        )

    concept_candidate = ExtractedCandidate(
        candidate_type="concept",
        payload={
            "title": alias["title"],
            "concept_id": str(alias["concept_id"]),
            "concept_version_id": str(alias["concept_version_id"]),
        },
        source_locator={"kind": "page", "page": 1},
        confidence=0.90,
    )

    worker = IngestionWorker(
        engine,
        commit_context["settings"],
        storage=storage,
        protector=None,
        extractor=FixedExtractionProvider([concept_candidate]),
        worker_id=f"worker-{uuid4()}",
    )
    assert worker.run_once() is True

    # 3. Commit update
    with caplog.at_level(logging.INFO):
        committed = service.commit(auth, created.id, idempotency_key=str(uuid4()))
    assert committed.learning_update.status == "committed"

    # Verify upload transitioned to deleting and delete job queued
    with engine.connect() as connection:
        up_status = connection.scalar(
            text("SELECT status FROM source_uploads WHERE id = :id"),
            {"id": grant.upload_id},
        )
        assert up_status == "deleting"

        del_job = connection.scalar(
            text(
                "SELECT count(*) FROM background_jobs "
                "WHERE resource_id = :id AND job_type = 'ingestion.delete_upload'"
            ),
            {"id": grant.upload_id},
        )
        assert del_job == 1

    # 4. Worker executes deletion job
    assert worker.run_once() is True

    # Absence confirmed: file removed from storage, proof created, status 'deleted'
    assert storage.head_object(upload["object_key"]) is None

    with engine.connect() as connection:
        proof = (
            connection.execute(
                text(
                    "SELECT result, target_fingerprint FROM deletion_proofs "
                    "WHERE source_upload_id = :id"
                ),
                {"id": grant.upload_id},
            )
            .mappings()
            .first()
        )
        assert proof is not None
        assert proof["result"] == "deleted"
        expected_fp = hashlib.sha256(upload["object_key"].encode()).hexdigest()
        assert proof["target_fingerprint"] == expected_fp

        final_status = connection.scalar(
            text("SELECT status FROM source_uploads WHERE id = :id"),
            {"id": grant.upload_id},
        )
        assert final_status == "deleted"

    # Ensure no file URL or note content in logs
    assert "test_notes.pdf" not in caplog.text


def test_deletion_proof_not_created_if_absence_not_confirmed(
    commit_context: dict[str, Any],
) -> None:
    engine = commit_context["engine"]
    settings = commit_context["settings"]
    auth = commit_context["auth"]

    # Use stubborn storage that refuses to delete
    stubborn_storage = StubbornStorage(refuse_delete=True)
    stubborn_service = IngestionService(
        IngestionRepository(engine), stubborn_storage, settings, commit_context["protector"]
    )

    digest = hashlib.sha256(PDF_CONTENT).hexdigest()
    created = stubborn_service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="pdf",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            files=[
                DeclaredFile(
                    declared_name="lingering.pdf",
                    declared_media_type="application/pdf",
                    byte_size=len(PDF_CONTENT),
                    content_sha256=digest,
                )
            ],
        ),
        idempotency_key=str(uuid4()),
    )
    grant = stubborn_service.grant(
        auth,
        created.id,
        UploadGrantRequest(
            declared_name="lingering.pdf",
            declared_media_type="application/pdf",
            byte_size=len(PDF_CONTENT),
            content_sha256=digest,
        ),
        idempotency_key=str(uuid4()),
    )
    upload = IngestionRepository(engine).get_upload(auth.context, created.id, grant.upload_id)
    stubborn_storage.put_object(upload["object_key"], PDF_CONTENT, "application/pdf")

    stubborn_service.finalize(
        auth,
        created.id,
        grant.upload_id,
        FinalizeUploadRequest(
            observed_size=len(PDF_CONTENT), content_sha256=digest, client_operation_id=uuid4()
        ),
        idempotency_key=str(uuid4()),
    )

    with engine.connect() as connection:
        alias = (
            connection.execute(
                text("""
                SELECT ca.concept_version_id, cv.concept_id, cv.title
                FROM concept_aliases ca
                JOIN concept_versions cv ON cv.id = ca.concept_version_id
                JOIN concepts c ON c.id = cv.concept_id
                WHERE c.subject_id = :subject_id AND c.status = 'approved'
                LIMIT 1
                """),
                {"subject_id": PHYSICS_SUBJECT_ID},
            )
            .mappings()
            .first()
        )

    concept_candidate = ExtractedCandidate(
        candidate_type="concept",
        payload={
            "title": alias["title"],
            "concept_id": str(alias["concept_id"]),
            "concept_version_id": str(alias["concept_version_id"]),
        },
        source_locator={"kind": "page", "page": 1},
        confidence=0.90,
    )

    worker = IngestionWorker(
        engine,
        settings,
        storage=stubborn_storage,
        protector=None,
        extractor=FixedExtractionProvider([concept_candidate]),
        worker_id=f"worker-{uuid4()}",
    )
    assert worker.run_once() is True
    stubborn_service.commit(auth, created.id, idempotency_key=str(uuid4()))

    # Worker executes delete job on stubborn storage: absence check fails
    assert worker.run_once() is True

    # Verify no deletion proof created and job moved to retry_wait
    with engine.connect() as connection:
        proof_count = connection.scalar(
            text("SELECT count(*) FROM deletion_proofs WHERE source_upload_id = :id"),
            {"id": grant.upload_id},
        )
        assert proof_count == 0

        job = (
            connection.execute(
                text(
                    "SELECT status, last_error_code FROM background_jobs "
                    "WHERE resource_id = :id AND job_type = 'ingestion.delete_upload'"
                ),
                {"id": grant.upload_id},
            )
            .mappings()
            .first()
        )
        assert job["status"] == "retry_wait"
        assert job["last_error_code"] == "deletion_failed"
