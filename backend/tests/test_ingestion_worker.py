from __future__ import annotations

import base64
import json
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

from memora.api.security import AuthContext, AuthenticatedRequest
from memora.api.v1.schemas.ingestion import CreateLearningUpdateRequest
from memora.core.config import Settings
from memora.db.seed import seed_database
from memora.modules.ingestion.extraction import (
    DeterministicExtractionProvider,
    ExtractedCandidate,
    ExtractionUnavailable,
    NoExtractableContent,
    OpenRouterExtractionProvider,
)
from memora.modules.ingestion.repository import IngestionRepository
from memora.modules.ingestion.service import IngestionService, ManualTextProtector
from memora.modules.ingestion.storage import MemoryObjectStorage
from memora.worker.ingestion import IngestionWorker

BACKEND_ROOT = Path(__file__).resolve().parents[1]
PHYSICS_SUBJECT_ID = UUID("10000000-0000-0000-0000-000000000001")
INGESTION_KEY = "cGe/2UxRnTY3D17CPcFSnrHkGqBSwmcmJ+ehN4XFMxc="


@pytest.fixture(scope="module")
def worker_engine() -> Engine:
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


@pytest.fixture
def worker_context(worker_engine: Engine) -> dict[str, Any]:
    with worker_engine.begin() as connection:
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
    repository = IngestionRepository(worker_engine)
    service = IngestionService(repository, storage, settings, protector)
    worker = IngestionWorker(
        worker_engine,
        settings,
        storage=storage,
        protector=protector,
        worker_id=f"test-worker-{uuid4()}",
    )
    auth = _create_user(worker_engine)
    return {
        "engine": worker_engine,
        "settings": settings,
        "storage": storage,
        "protector": protector,
        "repository": repository,
        "service": service,
        "worker": worker,
        "auth": auth,
    }


class FixedExtractionProvider:
    model_key = "fixed-test-provider"
    prompt_version = "v1"

    def __init__(self, candidates: list[ExtractedCandidate]) -> None:
        self.candidates = candidates

    def extract(self, **_: Any) -> list[ExtractedCandidate]:
        return list(self.candidates)


class ErrorExtractionProvider:
    model_key = "error-test-provider"
    prompt_version = "v1"

    def __init__(self, exception: Exception) -> None:
        self.exception = exception

    def extract(self, **_: Any) -> list[ExtractedCandidate]:
        raise self.exception


# ---------------------------------------------------------------------------
# Unit tests for Extraction Providers
# ---------------------------------------------------------------------------


def test_deterministic_extraction_patterns() -> None:
    provider = DeterministicExtractionProvider()
    aliases = [
        {
            "alias_text": "Acceleration",
            "is_preferred": True,
            "concept_id": uuid4(),
            "concept_version_id": uuid4(),
            "title": "Acceleration",
            "definition": "Rate of change of velocity.",
        },
        {
            "alias_text": "Velocity",
            "is_preferred": False,
            "concept_id": uuid4(),
            "concept_version_id": uuid4(),
            "title": "Velocity",
            "definition": "Speed in a given direction.",
        },
    ]

    candidates = provider.extract(
        manual_text="Acceleration is key. Also F = m a and gravity is 9.8 m/s^2.",
        file_bytes=None,
        media_type=None,
        declared_name=None,
        aliases=aliases,
    )

    types = {c.candidate_type for c in candidates}
    assert "concept" in types
    assert "formula" in types
    assert "unit" in types

    concept_candidate = next(c for c in candidates if c.candidate_type == "concept")
    assert concept_candidate.confidence == 0.9  # is_preferred is True
    assert concept_candidate.payload["title"] == "Acceleration"

    formula_candidate = next(c for c in candidates if c.candidate_type == "formula")
    assert "F = m a" in formula_candidate.payload["statement"]
    assert formula_candidate.confidence == 0.68

    unit_candidate = next(c for c in candidates if c.candidate_type == "unit")
    assert "9.8 m/s^2" in unit_candidate.payload["statement"]
    assert unit_candidate.confidence == 0.7


def test_deterministic_extraction_fails_closed_for_binary_and_empty() -> None:
    provider = DeterministicExtractionProvider()
    with pytest.raises(ExtractionUnavailable):
        provider.extract(
            manual_text=None,
            file_bytes=b"%PDF-1.7",
            media_type="application/pdf",
            declared_name="test.pdf",
            aliases=[],
        )

    with pytest.raises(NoExtractableContent):
        provider.extract(
            manual_text="    ",
            file_bytes=None,
            media_type=None,
            declared_name=None,
            aliases=[],
        )


def test_openrouter_extraction_provider_success_and_resilience() -> None:
    mock_response = {
        "choices": [
            {
                "message": {
                    "content": json.dumps(
                        {
                            "candidates": [
                                {
                                    "candidate_type": "concept",
                                    "payload": {"title": "Kinematics"},
                                    "source_locator": {"kind": "page", "page": 1},
                                    "confidence": 0.95,
                                },
                                {
                                    "candidate_type": "formula",
                                    "payload": {"title": "v = u + a t"},
                                    "confidence": 1.5,  # Needs clamping to 1.0
                                },
                                {
                                    "candidate_type": "unsupported_type",
                                    "payload": {"title": "Bad"},
                                    "confidence": 0.5,
                                },
                            ]
                        }
                    )
                }
            }
        ]
    }

    provider = OpenRouterExtractionProvider(
        api_key="test-key",
        model="openrouter/auto",
        post_json=lambda url, payload, api_key, timeout: mock_response,
    )

    candidates = provider.extract(
        manual_text="kinematics notes",
        file_bytes=None,
        media_type=None,
        declared_name=None,
        aliases=[],
    )

    assert len(candidates) == 2  # unsupported_type filtered out
    assert candidates[0].candidate_type == "concept"
    assert candidates[0].confidence == 0.95
    assert candidates[1].candidate_type == "formula"
    assert candidates[1].confidence == 1.0  # Clamped to 1.0
    assert candidates[1].source_locator == {"kind": "page", "page": 1}  # Fallback locator


def test_openrouter_extraction_provider_error_handling() -> None:
    def _failing_post(*args: Any, **kwargs: Any) -> Any:
        raise TimeoutError("Connection timed out")

    provider = OpenRouterExtractionProvider(
        api_key="test-key",
        model="openrouter/auto",
        post_json=_failing_post,
    )

    with pytest.raises(ExtractionUnavailable):
        provider.extract(
            manual_text="kinematics",
            file_bytes=None,
            media_type=None,
            declared_name=None,
            aliases=[],
        )


# ---------------------------------------------------------------------------
# Integration tests for Worker Lifecycle, Lease & Reconciler
# ---------------------------------------------------------------------------


def test_worker_retries_transient_provider_failure(worker_context: dict[str, Any]) -> None:
    service = worker_context["service"]
    auth = worker_context["auth"]
    engine = worker_context["engine"]

    update = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Transient failure test note.",
        ),
        idempotency_key=str(uuid4()),
    )

    worker = IngestionWorker(
        engine,
        worker_context["settings"],
        storage=worker_context["storage"],
        protector=worker_context["protector"],
        extractor=ErrorExtractionProvider(ExtractionUnavailable("API rate limit exceeded")),
        worker_id=f"worker-{uuid4()}",
    )

    assert worker.run_once() is True

    with engine.connect() as connection:
        job = (
            connection.execute(
                text(
                    "SELECT status, attempt_count, last_error_code FROM background_jobs "
                    "WHERE resource_id = :id"
                ),
                {"id": update.id},
            )
            .mappings()
            .first()
        )
        assert job["status"] == "retry_wait"
        assert job["attempt_count"] == 1
        assert job["last_error_code"] == "extraction_unavailable"

    # Update remains processing (not failed yet on first retry)
    assert service.get(auth, update.id).status == "processing"


def test_poison_doc_dead_letter_and_no_leak_in_logs(
    worker_context: dict[str, Any], caplog: pytest.LogCaptureFixture
) -> None:
    service = worker_context["service"]
    auth = worker_context["auth"]
    engine = worker_context["engine"]
    secret_note = "Secret student personal reflection on friction."

    update = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text=secret_note,
        ),
        idempotency_key=str(uuid4()),
    )

    worker = IngestionWorker(
        engine,
        worker_context["settings"],
        storage=worker_context["storage"],
        protector=worker_context["protector"],
        extractor=ErrorExtractionProvider(ExtractionUnavailable("Persistent provider outage")),
        worker_id=f"poison-worker-{uuid4()}",
    )

    with caplog.at_level(logging.INFO):
        # Run 5 times (max_attempts = 5)
        for _ in range(5):
            assert worker.run_once() is True
            with engine.begin() as connection:
                connection.execute(
                    text(
                        "UPDATE background_jobs SET status = 'retry_wait', available_at = now() "
                        "WHERE status = 'retry_wait'"
                    )
                )

    with engine.connect() as connection:
        job = (
            connection.execute(
                text("SELECT status, last_error_code FROM background_jobs WHERE resource_id = :id"),
                {"id": update.id},
            )
            .mappings()
            .first()
        )
        assert job["status"] == "dead_lettered"
        assert job["last_error_code"] == "extraction_unavailable"

    failed_update = service.get(auth, update.id)
    assert failed_update.status == "failed"
    assert failed_update.failure_code == "extraction_unavailable"

    # Rule 7: Never log learning text, answers, or source excerpts
    assert secret_note not in caplog.text


def test_lease_recovery_and_stale_worker_write_prevention(
    worker_context: dict[str, Any],
) -> None:
    service = worker_context["service"]
    auth = worker_context["auth"]
    engine = worker_context["engine"]

    update = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Lease recovery test note.",
        ),
        idempotency_key=str(uuid4()),
    )

    candidate_worker_1 = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Worker 1 Stale Concept"},
        source_locator={"kind": "text_range", "start": 0, "end": 10},
        confidence=0.9,
    )
    candidate_worker_2 = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Worker 2 Fresh Concept"},
        source_locator={"kind": "text_range", "start": 0, "end": 10},
        confidence=0.9,
    )

    worker_1 = IngestionWorker(
        engine,
        worker_context["settings"],
        storage=worker_context["storage"],
        protector=worker_context["protector"],
        extractor=FixedExtractionProvider([candidate_worker_1]),
        worker_id="worker-1-crashed",
    )
    worker_2 = IngestionWorker(
        engine,
        worker_context["settings"],
        storage=worker_context["storage"],
        protector=worker_context["protector"],
        extractor=FixedExtractionProvider([candidate_worker_2]),
        worker_id="worker-2-recovered",
    )

    # 1. Worker 1 claims the job and loads context before simulated crash/hang
    job_1 = worker_1._claim_job()
    assert job_1 is not None
    assert job_1["resource_id"] == update.id
    context_1 = worker_1._load_extraction_context(job_1)
    assert context_1 is not None

    # 2. Simulate Worker 1 crashing and its lease expiring
    with engine.begin() as connection:
        connection.execute(
            text(
                "UPDATE background_jobs SET lease_expires_at = now() - interval '10 seconds' "
                "WHERE id = :id"
            ),
            {"id": job_1["id"]},
        )

    # 3. Worker 2 performs lease recovery and completes successfully
    assert worker_2.run_once() is True

    with engine.connect() as connection:
        job_status = connection.scalar(
            text("SELECT status FROM background_jobs WHERE id = :id"),
            {"id": job_1["id"]},
        )
        assert job_status == "succeeded"

    # 4. Worker 1 wakes up and tries to persist candidates;
    # it must be rejected because its lease was lost
    worker_1._persist_candidates(job_1, context_1, [candidate_worker_1])

    # 5. Verify only Worker 2's candidate is stored
    candidates = service.candidates(auth, update.id, cursor=None, limit=20)
    assert len(candidates.items) == 1
    assert candidates.items[0].display_title == "Worker 2 Fresh Concept"


def test_duplicate_job_delivery_converges_to_one_candidate_set(
    worker_context: dict[str, Any],
) -> None:
    service = worker_context["service"]
    auth = worker_context["auth"]
    engine = worker_context["engine"]

    update = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Acceleration and Velocity in Mechanics.",
        ),
        idempotency_key=str(uuid4()),
    )

    candidate = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Idempotent Mechanics Concept"},
        source_locator={"kind": "text_range", "start": 0, "end": 10},
        confidence=0.80,  # requires verification
    )

    worker = IngestionWorker(
        engine,
        worker_context["settings"],
        storage=worker_context["storage"],
        protector=worker_context["protector"],
        extractor=FixedExtractionProvider([candidate]),
        worker_id=f"idemp-worker-{uuid4()}",
    )

    # First delivery
    assert worker.run_once() is True
    first_candidates = service.candidates(auth, update.id, cursor=None, limit=20)
    assert len(first_candidates.items) == 1

    # Simulate duplicate job delivery: requeue the job and reset update status
    with engine.begin() as connection:
        connection.execute(
            text(
                "UPDATE background_jobs SET status = 'queued', available_at = now(), "
                "lease_owner = NULL, lease_expires_at = NULL WHERE resource_id = :id"
            ),
            {"id": update.id},
        )
        connection.execute(
            text("UPDATE learning_updates SET status = 'processing' WHERE id = :id"),
            {"id": update.id},
        )

    # Second delivery
    assert worker.run_once() is True

    # Exactly one candidate row and one verification request exist
    second_candidates = service.candidates(auth, update.id, cursor=None, limit=20)
    assert len(second_candidates.items) == 1

    with engine.connect() as connection:
        req_count = connection.scalar(
            text("SELECT count(*) FROM verification_requests WHERE learning_update_id = :id"),
            {"id": update.id},
        )
        assert req_count == 1


def test_candidate_deduplication_of_equivalent_candidates(
    worker_context: dict[str, Any],
) -> None:
    service = worker_context["service"]
    auth = worker_context["auth"]
    engine = worker_context["engine"]

    update = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Duplicate concepts in single text.",
        ),
        idempotency_key=str(uuid4()),
    )

    # Two candidates with identical payload
    candidate_1 = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Momentum", "definition": "Mass times velocity."},
        source_locator={"kind": "text_range", "start": 0, "end": 8},
        confidence=0.9,
    )
    candidate_2 = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Momentum", "definition": "Mass times velocity."},
        source_locator={"kind": "text_range", "start": 10, "end": 18},
        confidence=0.9,
    )

    worker = IngestionWorker(
        engine,
        worker_context["settings"],
        storage=worker_context["storage"],
        protector=worker_context["protector"],
        extractor=FixedExtractionProvider([candidate_1, candidate_2]),
        worker_id=f"dedupe-worker-{uuid4()}",
    )

    assert worker.run_once() is True

    candidates = service.candidates(auth, update.id, cursor=None, limit=20)
    assert len(candidates.items) == 1
    assert candidates.items[0].display_title == "Momentum"


def test_confidence_boundary_and_verification_request_creation(
    worker_context: dict[str, Any],
) -> None:
    service = worker_context["service"]
    auth = worker_context["auth"]
    engine = worker_context["engine"]

    update = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Confidence boundary check.",
        ),
        idempotency_key=str(uuid4()),
    )

    # 0.85 is auto-accepted (no verification request)
    high_candidate = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "High Confidence Concept"},
        source_locator={"kind": "text_range", "start": 0, "end": 5},
        confidence=0.85,
    )
    # 0.84 requires verification (creates verification request)
    low_candidate = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Low Confidence Concept"},
        source_locator={"kind": "text_range", "start": 6, "end": 12},
        confidence=0.84,
    )

    worker = IngestionWorker(
        engine,
        worker_context["settings"],
        storage=worker_context["storage"],
        protector=worker_context["protector"],
        extractor=FixedExtractionProvider([high_candidate, low_candidate]),
        worker_id=f"boundary-worker-{uuid4()}",
    )

    assert worker.run_once() is True

    candidates = service.candidates(auth, update.id, cursor=None, limit=20)
    assert len(candidates.items) == 2

    high_item = next(c for c in candidates.items if c.display_title == "High Confidence Concept")
    low_item = next(c for c in candidates.items if c.display_title == "Low Confidence Concept")

    assert high_item.confidence == 0.85
    assert high_item.requires_verification is False
    assert high_item.status == "accepted"

    assert low_item.confidence == 0.84
    assert low_item.requires_verification is True
    assert low_item.status == "needs_verification"

    with engine.connect() as connection:
        requests = (
            connection.execute(
                text(
                    "SELECT candidate_id, reason_code, status FROM verification_requests "
                    "WHERE learning_update_id = :id"
                ),
                {"id": update.id},
            )
            .mappings()
            .all()
        )
        assert len(requests) == 1
        assert requests[0]["candidate_id"] == low_item.id
        assert requests[0]["reason_code"] == "low_confidence_extraction"
        assert requests[0]["status"] == "pending"


def test_reconciler_expires_stale_items_and_enqueues_deletion(
    worker_context: dict[str, Any],
) -> None:
    service = worker_context["service"]
    auth = worker_context["auth"]
    engine = worker_context["engine"]
    worker = worker_context["worker"]

    update = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Reconciler expiry test note.",
        ),
        idempotency_key=str(uuid4()),
    )

    # Force candidate and update to be past expiry
    with engine.begin() as connection:
        user_id = connection.scalar(
            text("SELECT user_id FROM learning_updates WHERE id = :id"),
            {"id": update.id},
        )
        candidate_id = uuid4()
        connection.execute(
            text("""
                INSERT INTO extraction_candidates(
                    id, learning_update_id, user_id, candidate_type,
                    candidate_payload, source_locator, confidence,
                    model_key, prompt_version, schema_version, status, expires_at
                ) VALUES (
                    :id, :update_id, :user_id, 'concept',
                    '{"title": "Stale Concept"}'::jsonb, '{"kind": "page"}'::jsonb,
                    0.5, 'test', 'v1', '1', 'needs_verification', now() - interval '1 hour'
                )
                """),
            {
                "id": candidate_id,
                "update_id": update.id,
                "user_id": user_id,
            },
        )
        connection.execute(
            text("""
                INSERT INTO verification_requests(
                    learning_update_id, candidate_id, user_id, reason_code,
                    question_text, options, status, expires_at
                ) VALUES (
                    :update_id, :candidate_id, :user_id, 'low_confidence',
                    'Check', '{}'::jsonb, 'pending', now() - interval '1 hour'
                )
                """),
            {
                "update_id": update.id,
                "candidate_id": candidate_id,
                "user_id": user_id,
            },
        )
        # Create an expired source upload to verify deletion job enqueue
        upload_id = uuid4()
        connection.execute(
            text("""
                INSERT INTO source_uploads(
                    id, learning_update_id, user_id, declared_name, declared_media_type,
                    byte_size, object_key, status, expires_at
                ) VALUES (
                    :id, :update_id, :user_id, 'stale.pdf', 'application/pdf',
                    100, 'uploads/stale.pdf', 'uploaded', now() - interval '1 hour'
                )
                """),
            {
                "id": upload_id,
                "update_id": update.id,
                "user_id": user_id,
            },
        )
        connection.execute(
            text(
                "UPDATE learning_updates SET expires_at = now() - interval '1 hour' WHERE id = :id"
            ),
            {"id": update.id},
        )

    # Run reconciler
    worker.reconcile()

    with engine.connect() as connection:
        cand_status = connection.scalar(
            text("SELECT status FROM extraction_candidates WHERE id = :id"),
            {"id": candidate_id},
        )
        assert cand_status == "expired"

        req_status = connection.scalar(
            text("SELECT status FROM verification_requests WHERE candidate_id = :id"),
            {"id": candidate_id},
        )
        assert req_status == "expired"

        upload_status = connection.scalar(
            text("SELECT status FROM source_uploads WHERE id = :id"),
            {"id": upload_id},
        )
        assert upload_status == "expired"

        update_status = connection.scalar(
            text("SELECT status FROM learning_updates WHERE id = :id"),
            {"id": update.id},
        )
        assert update_status == "expired"

        # Verify deletion background job was enqueued for the expired upload
        del_job = (
            connection.execute(
                text(
                    "SELECT job_type, dedupe_key, status FROM background_jobs "
                    "WHERE resource_id = :id AND job_type = 'ingestion.delete_upload'"
                ),
                {"id": upload_id},
            )
            .mappings()
            .first()
        )
        assert del_job is not None
        assert del_job["status"] == "queued"
        assert del_job["dedupe_key"] == f"delete_upload:{upload_id}"
