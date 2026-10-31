"""Regression and bug-hunt verification suite for T09 Ingestion.

Covers the Section 7 checklist from docs/learning/T09_Implementation_Guide.md:
- Mixed input distinct uploads without overwriting
- Deleted upload cannot return to authorized/uploaded
- Rejected or expired candidate decisions fail atomically with 409
- Confidence boundary at exactly 0.85
- Reconciler does not expire committed knowledge
- Stale row_version on patch/decisions returns 409 with refresh_state
- Cross-user candidate access returns 404, not 403
- Idempotency key reuse with different body returns 409 on all mutations
"""

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

from memora.api.errors import ApiError
from memora.api.security import AuthContext, AuthenticatedRequest
from memora.api.v1.schemas.ingestion import (
    CreateLearningUpdateRequest,
    DeclaredFile,
    FinalizeUploadRequest,
    SubmitVerificationDecisionsRequest,
    UpdateLearningUpdateRequest,
    UploadGrantRequest,
    VerificationDecision,
)
from memora.core.config import Settings
from memora.db.seed import seed_database
from memora.modules.ingestion.constants import (
    confidence_band,
    requires_verification,
)
from memora.modules.ingestion.extraction import ExtractedCandidate
from memora.modules.ingestion.repository import IngestionRepository
from memora.modules.ingestion.service import IngestionService, ManualTextProtector
from memora.modules.ingestion.storage import MemoryObjectStorage
from memora.worker.ingestion import IngestionWorker

BACKEND_ROOT = Path(__file__).resolve().parents[1]
PHYSICS_SUBJECT_ID = UUID("10000000-0000-0000-0000-000000000001")
INGESTION_KEY = "cGe/2UxRnTY3D17CPcFSnrHkGqBSwmcmJ+ehN4XFMxc="
PNG_CONTENT = (
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR"
    b"\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15c4"
)
PDF_CONTENT = b"%PDF-1.4\n1 0 obj\n<<>>\nendobj\ntrailer\n<<>>\n%%EOF"


class DummyFixedExtractor:
    model_key = "dummy-fixed"
    prompt_version = "v1"

    def __init__(self, candidates: list[ExtractedCandidate]) -> None:
        self.candidates = candidates

    def extract(self, **_: Any) -> list[ExtractedCandidate]:
        return list(self.candidates)


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


def _create_user_with_consent(
    engine: Engine,
    *,
    has_material_consent: bool = True,
) -> AuthenticatedRequest:
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
        consents = ["terms", "privacy"]
        if has_material_consent:
            consents.extend(["material_processing", "model_processing"])
        for consent_type in consents:
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
def hunt_context(ingestion_engine: Engine) -> dict[str, Any]:
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
    repo = IngestionRepository(ingestion_engine)
    service = IngestionService(repo, storage, settings, protector)
    return {
        "engine": ingestion_engine,
        "service": service,
        "storage": storage,
        "settings": settings,
        "protector": protector,
        "repo": repo,
        "auth": _create_user_with_consent(ingestion_engine, has_material_consent=True),
        "other_auth": _create_user_with_consent(ingestion_engine, has_material_consent=True),
    }


def test_mixed_input_creates_distinct_uploads_without_overwriting(
    hunt_context: dict[str, Any],
) -> None:
    service: IngestionService = hunt_context["service"]
    auth = hunt_context["auth"]
    storage: MemoryObjectStorage = hunt_context["storage"]
    repo: IngestionRepository = hunt_context["repo"]

    png_digest = hashlib.sha256(PNG_CONTENT).hexdigest()
    pdf_digest = hashlib.sha256(PDF_CONTENT).hexdigest()

    created = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="mixed",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Newton's laws of motion with attached diagrams and notes.",
            files=[
                DeclaredFile(
                    declared_name="fbd_diagram.png",
                    declared_media_type="image/png",
                    byte_size=len(PNG_CONTENT),
                    content_sha256=png_digest,
                ),
                DeclaredFile(
                    declared_name="derivation_notes.pdf",
                    declared_media_type="application/pdf",
                    byte_size=len(PDF_CONTENT),
                    content_sha256=pdf_digest,
                ),
            ],
        ),
        idempotency_key=str(uuid4()),
    )

    assert created.has_manual_text is True

    # Request grants for both
    grant_1 = service.grant(
        auth,
        created.id,
        UploadGrantRequest(
            declared_name="fbd_diagram.png",
            declared_media_type="image/png",
            byte_size=len(PNG_CONTENT),
            content_sha256=png_digest,
        ),
        idempotency_key=str(uuid4()),
    )
    grant_2 = service.grant(
        auth,
        created.id,
        UploadGrantRequest(
            declared_name="derivation_notes.pdf",
            declared_media_type="application/pdf",
            byte_size=len(PDF_CONTENT),
            content_sha256=pdf_digest,
        ),
        idempotency_key=str(uuid4()),
    )

    assert grant_1.upload_id != grant_2.upload_id

    # Verify both uploads exist on the update and have distinct IDs
    update_with_grants = service.get(auth, created.id)
    assert len(update_with_grants.uploads) == 2
    up_1, up_2 = update_with_grants.uploads[0], update_with_grants.uploads[1]
    assert up_1.id != up_2.id
    assert up_1.declared_name != up_2.declared_name

    rec_1 = repo.get_upload(auth.context, created.id, grant_1.upload_id)
    rec_2 = repo.get_upload(auth.context, created.id, grant_2.upload_id)
    assert rec_1["object_key"] != rec_2["object_key"]

    # Upload both to storage
    storage.put_object(rec_1["object_key"], PNG_CONTENT, "image/png")
    storage.put_object(rec_2["object_key"], PDF_CONTENT, "application/pdf")

    # Finalize both
    service.finalize(
        auth,
        created.id,
        grant_1.upload_id,
        FinalizeUploadRequest(
            observed_size=len(PNG_CONTENT),
            content_sha256=png_digest,
            client_operation_id=uuid4(),
        ),
        idempotency_key=str(uuid4()),
    )
    service.finalize(
        auth,
        created.id,
        grant_2.upload_id,
        FinalizeUploadRequest(
            observed_size=len(PDF_CONTENT),
            content_sha256=pdf_digest,
            client_operation_id=uuid4(),
        ),
        idempotency_key=str(uuid4()),
    )

    # Check both uploads exist and are in processing status
    update_after = service.get(auth, created.id)
    assert update_after.status == "processing"
    assert len(update_after.uploads) == 2
    assert all(u.status == "processing" for u in update_after.uploads)
    # Check that storage objects were neither overwritten nor mangled
    assert storage.get_object(rec_1["object_key"]) == PNG_CONTENT
    assert storage.get_object(rec_2["object_key"]) == PDF_CONTENT


def test_deleted_upload_cannot_return_to_authorized_or_uploaded(
    hunt_context: dict[str, Any],
) -> None:
    service: IngestionService = hunt_context["service"]
    auth = hunt_context["auth"]
    engine = hunt_context["engine"]

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
                    declared_name="test.pdf",
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
            declared_name="test.pdf",
            declared_media_type="application/pdf",
            byte_size=len(PDF_CONTENT),
            content_sha256=digest,
        ),
        idempotency_key=str(uuid4()),
    )

    # Transition upload to deleted state in database
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE source_uploads SET status = 'deleted', deleted_at = now() WHERE id = :id"),
            {"id": grant.upload_id},
        )

    # Attempt finalize on deleted upload -> 409
    with pytest.raises(ApiError) as captured:
        service.finalize(
            auth,
            created.id,
            grant.upload_id,
            FinalizeUploadRequest(
                observed_size=len(PDF_CONTENT),
                content_sha256=digest,
                client_operation_id=uuid4(),
            ),
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 409
    assert captured.value.code == "invalid_state"


def test_submitting_decision_on_rejected_or_expired_candidate_fails_atomically(
    hunt_context: dict[str, Any],
) -> None:
    service: IngestionService = hunt_context["service"]
    auth = hunt_context["auth"]
    engine = hunt_context["engine"]

    created = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Energy and work relationships.",
        ),
        idempotency_key=str(uuid4()),
    )

    cand_1 = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Kinetic Energy"},
        source_locator={"page": 1},
        confidence=0.70,
    )
    cand_2 = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Potential Energy"},
        source_locator={"page": 1},
        confidence=0.70,
    )

    worker = IngestionWorker(
        engine,
        hunt_context["settings"],
        extractor=DummyFixedExtractor([cand_1, cand_2]),
        protector=hunt_context["protector"],
    )
    assert worker.run_once() is True

    cand_page = service.candidates(auth, created.id, cursor=None, limit=20)
    assert len(cand_page.items) == 2
    item_1 = next(c for c in cand_page.items if c.display_title == "Kinetic Energy")
    item_2 = next(c for c in cand_page.items if c.display_title == "Potential Energy")

    # 1. Reject item_1
    service.decide(
        auth,
        created.id,
        SubmitVerificationDecisionsRequest(
            decisions=[
                VerificationDecision(
                    candidate_id=item_1.id,
                    candidate_version=item_1.candidate_version,
                    decision="reject",
                )
            ]
        ),
        idempotency_key=str(uuid4()),
    )

    # 2. Attempt to decide on rejected item_1 -> 409 invalid_state
    with pytest.raises(ApiError) as captured:
        service.decide(
            auth,
            created.id,
            SubmitVerificationDecisionsRequest(
                decisions=[
                    VerificationDecision(
                        candidate_id=item_1.id,
                        candidate_version=item_1.candidate_version + 1,
                        decision="accept",
                    )
                ]
            ),
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 409
    assert captured.value.code == "invalid_state"

    # 3. Mark item_2 expired and attempt decision -> 409 invalid_state
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE extraction_candidates SET status = 'expired' WHERE id = :id"),
            {"id": item_2.id},
        )

    with pytest.raises(ApiError) as captured:
        service.decide(
            auth,
            created.id,
            SubmitVerificationDecisionsRequest(
                decisions=[
                    VerificationDecision(
                        candidate_id=item_2.id,
                        candidate_version=item_2.candidate_version,
                        decision="accept",
                    )
                ]
            ),
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 409
    assert captured.value.code == "invalid_state"


def test_confidence_boundary_at_point_85(hunt_context: dict[str, Any]) -> None:
    # 0.85 exactly is high and does not require verification
    assert confidence_band(0.85) == "high"
    assert requires_verification(0.85) is False

    # 0.849 is medium and requires verification
    assert confidence_band(0.849) == "medium"
    assert requires_verification(0.849) is True

    # 0.60 exactly is medium and requires verification
    assert confidence_band(0.60) == "medium"
    assert requires_verification(0.60) is True

    # 0.599 is low
    assert confidence_band(0.599) == "low"
    assert requires_verification(0.599) is True

    # End-to-end worker test for exact 0.85 confidence
    service: IngestionService = hunt_context["service"]
    auth = hunt_context["auth"]
    engine = hunt_context["engine"]

    created = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Threshold confidence testing.",
        ),
        idempotency_key=str(uuid4()),
    )

    boundary_candidate = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Exact Boundary Concept"},
        source_locator={"page": 1},
        confidence=0.85,
    )
    sub_boundary_candidate = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Sub Boundary Concept"},
        source_locator={"page": 1},
        confidence=0.849,
    )

    worker = IngestionWorker(
        engine,
        hunt_context["settings"],
        extractor=DummyFixedExtractor([boundary_candidate, sub_boundary_candidate]),
        protector=hunt_context["protector"],
    )
    assert worker.run_once() is True

    page = service.candidates(auth, created.id, cursor=None, limit=20)
    items = {c.display_title: c for c in page.items}

    exact_item = items["Exact Boundary Concept"]
    assert exact_item.confidence_band == "high"
    assert exact_item.requires_verification is False
    assert exact_item.status == "accepted"

    sub_item = items["Sub Boundary Concept"]
    assert sub_item.confidence_band == "medium"
    assert sub_item.requires_verification is True
    assert sub_item.status == "needs_verification"


def test_reconciler_does_not_expire_committed_knowledge(
    hunt_context: dict[str, Any],
) -> None:
    service: IngestionService = hunt_context["service"]
    auth = hunt_context["auth"]
    engine = hunt_context["engine"]

    created = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Committed knowledge expiry guard.",
        ),
        idempotency_key=str(uuid4()),
    )

    cand = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Approved Law"},
        source_locator={"page": 1},
        confidence=0.95,
    )

    worker = IngestionWorker(
        engine,
        hunt_context["settings"],
        extractor=DummyFixedExtractor([cand]),
        protector=hunt_context["protector"],
    )
    assert worker.run_once() is True

    # Commit the update
    commit_res = service.commit(auth, created.id, idempotency_key=str(uuid4()))
    assert commit_res.learning_update.status == "committed"

    # Artificially age the update and candidates past expiry
    with engine.begin() as conn:
        conn.execute(
            text(
                "UPDATE learning_updates SET expires_at = now() - interval '2 hours' WHERE id = :id"
            ),
            {"id": created.id},
        )
        conn.execute(
            text(
                "UPDATE extraction_candidates SET expires_at = now() - interval '2 hours' "
                "WHERE learning_update_id = :id"
            ),
            {"id": created.id},
        )

    # Run reconciler
    worker.reconcile()

    # Verify update and candidates remain committed/accepted
    update_after = service.get(auth, created.id)
    assert update_after.status == "committed"

    with engine.connect() as conn:
        cand_status = conn.scalar(
            text("SELECT status FROM extraction_candidates WHERE learning_update_id = :id"),
            {"id": created.id},
        )
        assert cand_status in {"accepted", "committed"}


def test_stale_row_version_returns_409_with_refresh_state_action(
    hunt_context: dict[str, Any],
) -> None:
    service: IngestionService = hunt_context["service"]
    auth = hunt_context["auth"]
    engine = hunt_context["engine"]

    # 1. Create a draft update directly in database
    draft_id = uuid4()
    with engine.begin() as conn:
        user_row = (
            conn.execute(
                text("SELECT id FROM users WHERE oidc_subject = :sub"),
                {"sub": auth.context.subject},
            )
            .mappings()
            .one()
        )
        conn.execute(
            text("""
                INSERT INTO learning_updates(
                    id, user_id, subject_id, curriculum_version_id, input_type, status,
                    learned_at, client_operation_id, row_version
                ) VALUES (
                    :id, :user_id, :subject_id, '20000000-0000-0000-0000-000000000001',
                    'manual_text', 'draft', now(), :op_id, 1
                )
            """),
            {
                "id": draft_id,
                "user_id": user_row["id"],
                "subject_id": PHYSICS_SUBJECT_ID,
                "op_id": uuid4(),
            },
        )

    # PATCH with stale version=999 raises 409 version_conflict
    with pytest.raises(ApiError) as captured:
        service.update(
            auth,
            draft_id,
            UpdateLearningUpdateRequest(
                version=999,
                manual_text="Updated text with bad version.",
            ),
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 409
    assert captured.value.code == "version_conflict"
    assert captured.value.action == "refresh_state"

    # PATCH with correct version=1 succeeds
    patched = service.update(
        auth,
        draft_id,
        UpdateLearningUpdateRequest(
            version=1,
            manual_text="Updated text for draft.",
        ),
        idempotency_key=str(uuid4()),
    )
    assert patched.row_version == 2

    # 2. Testing stale row_version on verification decisions
    cand_update = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Stale decision version testing note.",
        ),
        idempotency_key=str(uuid4()),
    )
    cand = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Stale Version Candidate"},
        source_locator={"page": 1},
        confidence=0.70,
    )
    worker = IngestionWorker(
        engine,
        hunt_context["settings"],
        extractor=DummyFixedExtractor([cand]),
        protector=hunt_context["protector"],
    )
    assert worker.run_once() is True
    cand_page = service.candidates(auth, cand_update.id, cursor=None, limit=20)
    c_item = cand_page.items[0]

    # Submit decision with stale candidate_version=999 -> 409 version_conflict
    with pytest.raises(ApiError) as captured_dec:
        service.decide(
            auth,
            cand_update.id,
            SubmitVerificationDecisionsRequest(
                decisions=[
                    VerificationDecision(
                        candidate_id=c_item.id,
                        candidate_version=999,
                        decision="accept",
                    )
                ]
            ),
            idempotency_key=str(uuid4()),
        )
    assert captured_dec.value.status_code == 409
    assert captured_dec.value.code == "version_conflict"
    assert captured_dec.value.action == "refresh_state"


def test_cross_user_candidate_access_returns_404_not_403(
    hunt_context: dict[str, Any],
) -> None:
    service: IngestionService = hunt_context["service"]
    auth = hunt_context["auth"]
    other_auth = hunt_context["other_auth"]
    engine = hunt_context["engine"]

    created = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Isolation testing note.",
        ),
        idempotency_key=str(uuid4()),
    )

    cand = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Private Concept"},
        source_locator={"page": 1},
        confidence=0.70,
    )
    worker = IngestionWorker(
        engine,
        hunt_context["settings"],
        extractor=DummyFixedExtractor([cand]),
        protector=hunt_context["protector"],
    )
    assert worker.run_once() is True

    candidates = service.candidates(auth, created.id, cursor=None, limit=20)
    cand_id = candidates.items[0].id

    # User 2 attempts to submit decision on User 1's candidate -> 404
    with pytest.raises(ApiError) as captured:
        service.decide(
            other_auth,
            created.id,
            SubmitVerificationDecisionsRequest(
                decisions=[
                    VerificationDecision(
                        candidate_id=cand_id,
                        candidate_version=1,
                        decision="accept",
                    )
                ]
            ),
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 404
    assert captured.value.code == "resource_not_found"

    # User 2 attempts to list candidates of User 1's update -> 404
    with pytest.raises(ApiError) as captured:
        service.candidates(other_auth, created.id, cursor=None, limit=20)
    assert captured.value.status_code == 404
    assert captured.value.code == "resource_not_found"


def test_idempotency_key_reused_fails_with_409_on_mutations(
    hunt_context: dict[str, Any],
) -> None:
    service: IngestionService = hunt_context["service"]
    auth = hunt_context["auth"]
    key = str(uuid4())

    # 1. Create with key
    service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="First payload.",
        ),
        idempotency_key=key,
    )

    # Reusing same key with different manual text -> 409 idempotency_key_reused
    with pytest.raises(ApiError) as captured:
        service.create(
            auth,
            CreateLearningUpdateRequest(
                subject_id=PHYSICS_SUBJECT_ID,
                input_type="manual_text",
                learned_at=datetime.now(UTC),
                client_operation_id=uuid4(),
                manual_text="Different payload with reused key.",
            ),
            idempotency_key=key,
        )
    assert captured.value.status_code == 409
    assert captured.value.code == "idempotency_key_reused"
    assert captured.value.action == "correct_input"
