from __future__ import annotations

import base64
import hashlib
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
from memora.modules.ingestion.storage import MemoryObjectStorage, StorageUnavailable
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


def test_ingestion_worker_does_not_claim_memory_jobs(
    worker_context: dict[str, Any],
) -> None:
    engine: Engine = worker_context["engine"]
    worker: IngestionWorker = worker_context["worker"]
    subject = worker_context["auth"].context.subject
    resource_id = uuid4()

    with engine.begin() as connection:
        user_id = connection.scalar(
            text("SELECT id FROM users WHERE oidc_subject = :subject"),
            {"subject": subject},
        )
        job_id = connection.scalar(
            text("""
                INSERT INTO background_jobs(
                    job_type, owner_user_id, resource_type, resource_id,
                    dedupe_key, status, max_attempts, available_at, payload
                ) VALUES (
                    'memory.process_event', :user_id, 'outbox_event', :resource_id,
                    :dedupe_key, 'queued', 5, now(),
                    jsonb_build_object('schema_version', '1', 'outbox_event_id', :resource_id)
                )
                RETURNING id
                """),
            {
                "user_id": user_id,
                "resource_id": resource_id,
                "dedupe_key": f"memory-test:{resource_id}",
            },
        )

    assert worker.run_once() is False
    with engine.connect() as connection:
        job = (
            connection.execute(
                text("SELECT status, attempt_count FROM background_jobs WHERE id = :id"),
                {"id": job_id},
            )
            .mappings()
            .one()
        )
    assert dict(job) == {"status": "queued", "attempt_count": 0}


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


class RecordingExtractionProvider:
    """File-capable provider that returns one identifiable candidate per call."""

    model_key = "recording-test-provider"
    prompt_version = "v1"
    supports_files = True

    def __init__(self, *, empty_results: bool = False) -> None:
        self.calls: list[dict[str, Any]] = []
        self._empty_results = empty_results

    def extract(
        self,
        *,
        manual_text: str | None,
        file_bytes: bytes | None,
        media_type: str | None,
        declared_name: str | None,
        aliases: list[dict[str, Any]],
    ) -> list[ExtractedCandidate]:
        self.calls.append({"manual_text": manual_text, "declared_name": declared_name})
        if self._empty_results:
            raise NoExtractableContent("nothing extractable")
        title = declared_name or "manual-text"
        return [
            ExtractedCandidate(
                candidate_type="formula",
                payload={"schema_version": "1", "title": title, "statement": title},
                source_locator={"schema_version": "1", "kind": "page", "page": 1},
                confidence=0.9,
            )
        ]


class FailDeleteStorage(MemoryObjectStorage):
    """Storage mock that simulates a provider refusing the delete call."""

    def delete_object(self, object_key: str) -> None:
        raise StorageUnavailable("access denied")


def _unit_worker(
    extractor: Any,
    storage: MemoryObjectStorage | None = None,
    protector: ManualTextProtector | None = None,
) -> IngestionWorker:
    settings = Settings(
        _env_file=None,
        environment="local",
        database_url="postgresql+psycopg://memora:memora@127.0.0.1:5432/memora",
        upload_max_bytes=1048576,
    )
    return IngestionWorker(
        None,
        settings,
        extractor=extractor,
        storage=storage or MemoryObjectStorage(),
        protector=protector,
    )


def _upload_entry(key: str, payload: bytes, media_type: str, name: str) -> dict[str, Any]:
    return {
        "object_key": key,
        "declared_name": name,
        "declared_media_type": media_type,
        "content_sha256": hashlib.sha256(payload).hexdigest(),
    }


def _acceleration_alias() -> dict[str, Any]:
    return {
        "alias_text": "Acceleration",
        "is_preferred": True,
        "concept_id": uuid4(),
        "concept_version_id": uuid4(),
        "title": "Acceleration",
        "definition": "Rate of change of velocity.",
    }


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
# Unit tests for multi-upload extraction
# ---------------------------------------------------------------------------


def test_extract_candidates_processes_every_upload() -> None:
    first = b"%PDF-1.7\nsynthetic-one"
    second = b"\x89PNG\r\n\x1a\nsynthetic-two"
    storage = MemoryObjectStorage()
    storage.put_object("u/a.pdf", first, "application/pdf")
    storage.put_object("u/b.png", second, "image/png")
    provider = RecordingExtractionProvider()
    worker = _unit_worker(provider, storage)
    context = {
        "update": {"id": uuid4(), "manual_text_ciphertext": None},
        "uploads": [
            _upload_entry("u/a.pdf", first, "application/pdf", "a.pdf"),
            _upload_entry("u/b.png", second, "image/png", "b.png"),
        ],
        "aliases": [],
    }

    candidates, failure = worker._extract_candidates(context)

    assert failure is None
    assert [candidate.payload["title"] for candidate in candidates] == ["a.pdf", "b.png"]
    assert [call["declared_name"] for call in provider.calls] == ["a.pdf", "b.png"]
    assert provider.calls[0]["manual_text"] is None


def test_extract_candidates_mixed_update_fails_closed_for_text_only_provider() -> None:
    protector = ManualTextProtector(base64.b64decode(INGESTION_KEY))
    update_id = uuid4()
    storage = MemoryObjectStorage()
    storage.put_object("u/a.pdf", b"%PDF-1.7 synthetic", "application/pdf")
    worker = _unit_worker(DeterministicExtractionProvider(), storage, protector)
    context = {
        "update": {
            "id": update_id,
            "manual_text_ciphertext": protector.encrypt(
                "Acceleration is key.", update_id=update_id
            ),
        },
        "uploads": [_upload_entry("u/a.pdf", b"%PDF-1.7 synthetic", "application/pdf", "a.pdf")],
        "aliases": [_acceleration_alias()],
    }

    _, failure = worker._extract_candidates(context)

    assert failure == "extraction_unavailable"


def test_extract_candidates_file_only_update_fails_closed_for_text_only_provider() -> None:
    storage = MemoryObjectStorage()
    storage.put_object("u/a.pdf", b"%PDF-1.7 synthetic", "application/pdf")
    worker = _unit_worker(DeterministicExtractionProvider(), storage)
    context = {
        "update": {"id": uuid4(), "manual_text_ciphertext": None},
        "uploads": [_upload_entry("u/a.pdf", b"%PDF-1.7 synthetic", "application/pdf", "a.pdf")],
        "aliases": [],
    }

    _, failure = worker._extract_candidates(context)

    assert failure == "extraction_unavailable"


def test_extract_candidates_all_empty_sources_fail_as_no_extractable_content() -> None:
    first = b"%PDF-1.7\nsynthetic-one"
    second = b"\x89PNG\r\n\x1a\nsynthetic-two"
    storage = MemoryObjectStorage()
    storage.put_object("u/a.pdf", first, "application/pdf")
    storage.put_object("u/b.png", second, "image/png")
    worker = _unit_worker(RecordingExtractionProvider(empty_results=True), storage)
    context = {
        "update": {"id": uuid4(), "manual_text_ciphertext": None},
        "uploads": [
            _upload_entry("u/a.pdf", first, "application/pdf", "a.pdf"),
            _upload_entry("u/b.png", second, "image/png", "b.png"),
        ],
        "aliases": [],
    }

    _, failure = worker._extract_candidates(context)

    assert failure == "no_extractable_content"


def test_extract_candidates_provider_outage_stays_retryable() -> None:
    first = b"%PDF-1.7\nsynthetic-one"
    storage = MemoryObjectStorage()
    storage.put_object("u/a.pdf", first, "application/pdf")
    worker = _unit_worker(ErrorExtractionProvider(ExtractionUnavailable("API down")), storage)
    context = {
        "update": {"id": uuid4(), "manual_text_ciphertext": None},
        "uploads": [_upload_entry("u/a.pdf", first, "application/pdf", "a.pdf")],
        "aliases": [],
    }

    _, failure = worker._extract_candidates(context)

    assert failure == "extraction_unavailable"


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


def test_reconciler_expires_processing_upload_and_enqueues_deletion(
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
            manual_text="Processing expiry test note.",
        ),
        idempotency_key=str(uuid4()),
    )
    with engine.begin() as connection:
        user_id = connection.scalar(
            text("SELECT user_id FROM learning_updates WHERE id = :id"),
            {"id": update.id},
        )
        upload_id = uuid4()
        connection.execute(
            text("""
                INSERT INTO source_uploads(
                    id, learning_update_id, user_id, declared_name, declared_media_type,
                    byte_size, object_key, status, expires_at
                ) VALUES (
                    :id, :update_id, :user_id, 'stale.pdf', 'application/pdf',
                    100, 'uploads/stale-processing.pdf', 'processing',
                    now() - interval '1 hour'
                )
                """),
            {"id": upload_id, "update_id": update.id, "user_id": user_id},
        )
        connection.execute(
            text(
                "UPDATE learning_updates SET expires_at = now() - interval '1 hour' WHERE id = :id"
            ),
            {"id": update.id},
        )

    worker.reconcile()

    with engine.connect() as connection:
        upload_status = connection.scalar(
            text("SELECT status FROM source_uploads WHERE id = :id"),
            {"id": upload_id},
        )
        assert upload_status == "expired"
        del_job = (
            connection.execute(
                text(
                    "SELECT status FROM background_jobs "
                    "WHERE resource_id = :id AND job_type = 'ingestion.delete_upload'"
                ),
                {"id": upload_id},
            )
            .mappings()
            .first()
        )
        assert del_job is not None
        assert del_job["status"] == "queued"


def test_reconciler_leaves_dead_lettered_deletion_jobs_terminal(
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
            manual_text="Deletion revival test note.",
        ),
        idempotency_key=str(uuid4()),
    )
    with engine.begin() as connection:
        user_id = connection.scalar(
            text("SELECT user_id FROM learning_updates WHERE id = :id"),
            {"id": update.id},
        )
        dead_upload = uuid4()
        connection.execute(
            text("""
                INSERT INTO source_uploads(
                    id, learning_update_id, user_id, declared_name, declared_media_type,
                    byte_size, object_key, status, expires_at
                ) VALUES (
                    :id, :update_id, :user_id, 'dead.pdf', 'application/pdf',
                    100, 'uploads/dead.pdf', 'expired', now() - interval '1 hour'
                )
                """),
            {"id": dead_upload, "update_id": update.id, "user_id": user_id},
        )
        connection.execute(
            text("""
                INSERT INTO background_jobs(
                    job_type, owner_user_id, resource_type, resource_id,
                    dedupe_key, status, attempt_count, max_attempts, available_at,
                    last_error_code, payload
                ) VALUES (
                    'ingestion.delete_upload', :user_id, 'source_upload', :upload_id,
                    :dedupe_key, 'dead_lettered', 5, 5, now() - interval '2 hours',
                    'deletion_failed', '{"schema_version":"1"}'::jsonb
                )
                """),
            {
                "user_id": user_id,
                "upload_id": dead_upload,
                "dedupe_key": f"delete_upload:{dead_upload}",
            },
        )
        active_upload = uuid4()
        connection.execute(
            text("""
                INSERT INTO source_uploads(
                    id, learning_update_id, user_id, declared_name, declared_media_type,
                    byte_size, object_key, status, expires_at
                ) VALUES (
                    :id, :update_id, :user_id, 'active.pdf', 'application/pdf',
                    100, 'uploads/active.pdf', 'deleting', now() + interval '1 hour'
                )
                """),
            {"id": active_upload, "update_id": update.id, "user_id": user_id},
        )
        connection.execute(
            text("""
                INSERT INTO background_jobs(
                    job_type, owner_user_id, resource_type, resource_id,
                    dedupe_key, status, attempt_count, max_attempts, available_at,
                    lease_owner, lease_expires_at, payload
                ) VALUES (
                    'ingestion.delete_upload', :user_id, 'source_upload', :upload_id,
                    :dedupe_key, 'leased', 1, 5, now(),
                    'other-worker', now() + interval '60 seconds',
                    '{"schema_version":"1"}'::jsonb
                )
                """),
            {
                "user_id": user_id,
                "upload_id": active_upload,
                "dedupe_key": f"delete_upload:{active_upload}",
            },
        )

    worker.reconcile()

    with engine.connect() as connection:
        dead_job = (
            connection.execute(
                text(
                    "SELECT status, attempt_count, last_error_code FROM background_jobs "
                    "WHERE dedupe_key = :key"
                ),
                {"key": f"delete_upload:{dead_upload}"},
            )
            .mappings()
            .first()
        )
        assert dead_job is not None
        assert dead_job["status"] == "dead_lettered"
        assert dead_job["attempt_count"] == 5
        assert dead_job["last_error_code"] == "deletion_failed"

        active_job = (
            connection.execute(
                text(
                    "SELECT status, attempt_count, lease_owner FROM background_jobs "
                    "WHERE dedupe_key = :key"
                ),
                {"key": f"delete_upload:{active_upload}"},
            )
            .mappings()
            .first()
        )
        assert active_job is not None
        assert active_job["status"] == "leased"
        assert active_job["attempt_count"] == 1
        assert active_job["lease_owner"] == "other-worker"


def test_extraction_covers_every_upload_in_one_job(
    worker_context: dict[str, Any],
) -> None:
    service = worker_context["service"]
    auth = worker_context["auth"]
    engine = worker_context["engine"]
    storage = worker_context["storage"]
    worker = worker_context["worker"]

    update = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Multi file extraction note.",
        ),
        idempotency_key=str(uuid4()),
    )
    pdf_bytes = b"%PDF-1.7\nsynthetic page one"
    png_bytes = b"\x89PNG\r\n\x1a\nsynthetic-image"
    storage.put_object(f"{update.id}/first.pdf", pdf_bytes, "application/pdf")
    storage.put_object(f"{update.id}/second.png", png_bytes, "image/png")
    provider = RecordingExtractionProvider()
    worker.extractor = provider

    with engine.begin() as connection:
        user_id = connection.scalar(
            text("SELECT user_id FROM learning_updates WHERE id = :id"),
            {"id": update.id},
        )
        for upload_id, name, media, payload in (
            (uuid4(), "first.pdf", "application/pdf", pdf_bytes),
            (uuid4(), "second.png", "image/png", png_bytes),
        ):
            connection.execute(
                text("""
                    INSERT INTO source_uploads(
                        id, learning_update_id, user_id, declared_name,
                        declared_media_type, byte_size, object_key,
                        content_sha256, status, expires_at
                    ) VALUES (
                        :id, :update_id, :user_id, :name, :media,
                        :byte_size, :object_key, :content_sha256, 'processing',
                        now() + interval '1 hour'
                    )
                    """),
                {
                    "id": upload_id,
                    "update_id": update.id,
                    "user_id": user_id,
                    "name": name,
                    "media": media,
                    "byte_size": len(payload),
                    "object_key": f"{update.id}/{name}",
                    "content_sha256": hashlib.sha256(payload).hexdigest(),
                },
            )

    processed = 0
    while worker.run_once():
        processed += 1
        assert processed < 10

    assert provider.calls[0]["manual_text"] == "Multi file extraction note."
    assert [call["declared_name"] for call in provider.calls] == ["first.pdf", "second.png"]
    with engine.connect() as connection:
        upload_statuses = set(
            connection.execute(
                text(
                    "SELECT status FROM source_uploads "
                    "WHERE learning_update_id = :id AND user_id = :user_id"
                ),
                {"id": update.id, "user_id": user_id},
            ).scalars()
        )
        assert upload_statuses == {"validated"}
        candidate_titles = set(
            connection.execute(
                text(
                    "SELECT candidate_payload ->> 'title' FROM extraction_candidates "
                    "WHERE learning_update_id = :id AND user_id = :user_id"
                ),
                {"id": update.id, "user_id": user_id},
            ).scalars()
        )
        assert candidate_titles == {"first.pdf", "second.png"}
        update_status = connection.scalar(
            text("SELECT status FROM learning_updates WHERE id = :id"),
            {"id": update.id},
        )
        assert update_status == "verification_required"


def test_delete_failure_records_no_proof(worker_context: dict[str, Any]) -> None:
    service = worker_context["service"]
    auth = worker_context["auth"]
    engine = worker_context["engine"]
    storage = worker_context["storage"]
    worker = worker_context["worker"]

    update = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Delete proof outage test note.",
        ),
        idempotency_key=str(uuid4()),
    )
    storage.put_object("uploads/stuck.pdf", b"%PDF-1.7\nstuck object", "application/pdf")
    worker.storage = FailDeleteStorage()

    with engine.begin() as connection:
        user_id = connection.scalar(
            text("SELECT user_id FROM learning_updates WHERE id = :id"),
            {"id": update.id},
        )
        upload_id = uuid4()
        connection.execute(
            text("""
                INSERT INTO source_uploads(
                    id, learning_update_id, user_id, declared_name, declared_media_type,
                    byte_size, object_key, status, expires_at
                ) VALUES (
                    :id, :update_id, :user_id, 'stuck.pdf', 'application/pdf',
                    100, 'uploads/stuck.pdf', 'deleting', now() + interval '1 hour'
                )
                """),
            {"id": upload_id, "update_id": update.id, "user_id": user_id},
        )
        connection.execute(
            text("""
                INSERT INTO background_jobs(
                    job_type, owner_user_id, resource_type, resource_id,
                    dedupe_key, status, max_attempts, available_at, payload
                ) VALUES (
                    'ingestion.delete_upload', :user_id, 'source_upload', :upload_id,
                    :dedupe_key, 'queued', 5, now(), '{"schema_version":"1"}'::jsonb
                )
                """),
            {
                "user_id": user_id,
                "upload_id": upload_id,
                "dedupe_key": f"delete_upload:{upload_id}",
            },
        )

    processed = 0
    while worker.run_once():
        processed += 1
        assert processed < 10

    with engine.connect() as connection:
        upload_status = connection.scalar(
            text("SELECT status FROM source_uploads WHERE id = :id"),
            {"id": upload_id},
        )
        assert upload_status == "deleting"
        proof_count = connection.scalar(
            text("SELECT count(*) FROM deletion_proofs WHERE source_upload_id = :id"),
            {"id": upload_id},
        )
        assert proof_count == 0
        del_job = (
            connection.execute(
                text("SELECT status, last_error_code FROM background_jobs WHERE dedupe_key = :key"),
                {"key": f"delete_upload:{upload_id}"},
            )
            .mappings()
            .first()
        )
        assert del_job is not None
        assert del_job["status"] == "retry_wait"
        assert del_job["last_error_code"] == "deletion_failed"
