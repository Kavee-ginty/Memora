from __future__ import annotations

import base64
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
    SubmitVerificationDecisionsRequest,
    VerificationDecision,
    VerificationDecisionValue,
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


@pytest.fixture(scope="module")
def verification_engine() -> Engine:
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


class FixedExtractionProvider:
    model_key = "fixed-test-provider"
    prompt_version = "v1"

    def __init__(self, candidates: list[ExtractedCandidate]) -> None:
        self.candidates = candidates

    def extract(self, **_: Any) -> list[ExtractedCandidate]:
        return list(self.candidates)


@pytest.fixture
def verification_context(verification_engine: Engine) -> dict[str, Any]:
    with verification_engine.begin() as connection:
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
    repository = IngestionRepository(verification_engine)
    service = IngestionService(repository, storage, settings, protector)
    auth = _create_user(verification_engine)
    other_auth = _create_user(verification_engine)
    return {
        "engine": verification_engine,
        "settings": settings,
        "storage": storage,
        "protector": protector,
        "repository": repository,
        "service": service,
        "auth": auth,
        "other_auth": other_auth,
    }


def _create_update_with_candidates(
    ctx: dict[str, Any], candidates: list[ExtractedCandidate]
) -> UUID:
    service = ctx["service"]
    auth = ctx["auth"]
    update = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Verification and Preview Test Note.",
        ),
        idempotency_key=str(uuid4()),
    )
    worker = IngestionWorker(
        ctx["engine"],
        ctx["settings"],
        storage=ctx["storage"],
        protector=ctx["protector"],
        extractor=FixedExtractionProvider(candidates),
        worker_id=f"verif-worker-{uuid4()}",
    )
    assert worker.run_once() is True
    return update.id


# ---------------------------------------------------------------------------
# Test Candidate Listing & Pagination
# ---------------------------------------------------------------------------


def test_list_candidates_pagination_and_confidence_bands(
    verification_context: dict[str, Any],
) -> None:
    service = verification_context["service"]
    auth = verification_context["auth"]

    candidates = [
        ExtractedCandidate(
            candidate_type="concept",
            payload={"title": "High Confidence Concept"},
            source_locator={"kind": "text_range", "start": 0, "end": 10},
            confidence=0.90,
        ),
        ExtractedCandidate(
            candidate_type="formula",
            payload={"title": "Medium Confidence Formula", "statement": "F = m a"},
            source_locator={"kind": "text_range", "start": 12, "end": 20},
            confidence=0.75,
        ),
        ExtractedCandidate(
            candidate_type="unit",
            payload={"title": "Low Confidence Unit", "statement": "9.8 m/s^2"},
            source_locator={"kind": "text_range", "start": 22, "end": 30},
            confidence=0.45,
        ),
    ]

    update_id = _create_update_with_candidates(verification_context, candidates)

    # First page: limit 2
    page_1 = service.candidates(auth, update_id, cursor=None, limit=2)
    assert len(page_1.items) == 2
    assert page_1.has_more is True
    assert page_1.next_cursor is not None

    # Second page
    page_2 = service.candidates(auth, update_id, cursor=page_1.next_cursor, limit=2)
    assert len(page_2.items) == 1
    assert page_2.has_more is False

    all_items = page_1.items + page_2.items
    assert len(all_items) == 3
    by_title = {c.display_title: c for c in all_items}

    high_c = by_title["High Confidence Concept"]
    assert high_c.confidence_band == "high"
    assert high_c.requires_verification is False
    assert high_c.status == "accepted"

    med_c = by_title["Medium Confidence Formula"]
    assert med_c.confidence_band == "medium"
    assert med_c.requires_verification is True
    assert med_c.status == "needs_verification"

    low_c = by_title["Low Confidence Unit"]
    assert low_c.confidence_band == "low"
    assert low_c.requires_verification is True
    assert low_c.status == "needs_verification"


# ---------------------------------------------------------------------------
# Test Decision Semantics (accept, edit, merge, reject)
# ---------------------------------------------------------------------------


def test_decide_accept_and_edit_and_merge(verification_context: dict[str, Any]) -> None:
    service = verification_context["service"]
    auth = verification_context["auth"]
    engine = verification_context["engine"]

    c_accept = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Concept To Accept"},
        source_locator={"kind": "text_range", "start": 0, "end": 10},
        confidence=0.5,
    )
    c_edit = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Concept To Edit"},
        source_locator={"kind": "text_range", "start": 12, "end": 20},
        confidence=0.5,
    )
    c_merge = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Concept To Merge"},
        source_locator={"kind": "text_range", "start": 22, "end": 30},
        confidence=0.5,
    )

    update_id = _create_update_with_candidates(verification_context, [c_accept, c_edit, c_merge])

    items = service.candidates(auth, update_id, cursor=None, limit=10).items
    by_title = {c.display_title: c for c in items}

    target_merge_id = uuid4()
    response = service.decide(
        auth,
        update_id,
        SubmitVerificationDecisionsRequest(
            decisions=[
                VerificationDecision(
                    candidate_id=by_title["Concept To Accept"].id,
                    candidate_version=by_title["Concept To Accept"].candidate_version,
                    decision=VerificationDecisionValue.ACCEPT,
                ),
                VerificationDecision(
                    candidate_id=by_title["Concept To Edit"].id,
                    candidate_version=by_title["Concept To Edit"].candidate_version,
                    decision=VerificationDecisionValue.EDIT,
                    corrected_payload={"title": "Corrected Concept Title", "definition": "New def"},
                ),
                VerificationDecision(
                    candidate_id=by_title["Concept To Merge"].id,
                    candidate_version=by_title["Concept To Merge"].candidate_version,
                    decision=VerificationDecisionValue.MERGE,
                    corrected_payload={"merge_into_candidate_id": str(target_merge_id)},
                ),
            ]
        ),
        idempotency_key=str(uuid4()),
    )

    assert len(response.results) == 3
    assert all(r.candidate_status == "accepted" for r in response.results)
    assert all(not r.requires_verification for r in response.results)

    # Verify database persistence of decisions
    with engine.connect() as connection:
        decisions = (
            connection.execute(
                text("""
                    SELECT vd.decision, vd.corrected_payload
                    FROM verification_decisions vd
                    JOIN verification_requests vr ON vr.id = vd.verification_request_id
                    WHERE vr.learning_update_id = :id
                    ORDER BY vr.created_at
                    """),
                {"id": update_id},
            )
            .mappings()
            .all()
        )
        assert len(decisions) == 3
        # D8 mapping check: edit -> correct, merge -> correct with merge id
        assert decisions[0]["decision"] == "accept"
        assert decisions[1]["decision"] == "correct"
        assert decisions[1]["corrected_payload"]["payload"]["title"] == "Corrected Concept Title"
        assert decisions[2]["decision"] == "correct"
        assert decisions[2]["corrected_payload"]["merge_into_candidate_id"] == str(target_merge_id)

    # Check updated display title of edited candidate
    updated_items = service.candidates(auth, update_id, cursor=None, limit=10).items
    edited_item = next(c for c in updated_items if c.id == by_title["Concept To Edit"].id)
    assert edited_item.display_title == "Corrected Concept Title"


def test_decide_reject_excludes_from_preview(verification_context: dict[str, Any]) -> None:
    service = verification_context["service"]
    auth = verification_context["auth"]

    c1 = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Rejected Concept"},
        source_locator={"kind": "text_range", "start": 0, "end": 10},
        confidence=0.5,
    )
    c2 = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Accepted Concept"},
        source_locator={"kind": "text_range", "start": 12, "end": 20},
        confidence=0.5,
    )

    update_id = _create_update_with_candidates(verification_context, [c1, c2])
    items = service.candidates(auth, update_id, cursor=None, limit=10).items
    by_title = {c.display_title: c for c in items}

    service.decide(
        auth,
        update_id,
        SubmitVerificationDecisionsRequest(
            decisions=[
                VerificationDecision(
                    candidate_id=by_title["Rejected Concept"].id,
                    candidate_version=by_title["Rejected Concept"].candidate_version,
                    decision=VerificationDecisionValue.REJECT,
                ),
                VerificationDecision(
                    candidate_id=by_title["Accepted Concept"].id,
                    candidate_version=by_title["Accepted Concept"].candidate_version,
                    decision=VerificationDecisionValue.ACCEPT,
                ),
            ]
        ),
        idempotency_key=str(uuid4()),
    )

    preview = service.preview(auth, update_id)
    assert preview.can_commit is True
    assert preview.concept_count == 1
    assert len(preview.first_concepts) == 1
    assert preview.first_concepts[0].title == "Accepted Concept"


# ---------------------------------------------------------------------------
# Test Decision Error Handlers & Invariants
# ---------------------------------------------------------------------------


def test_decide_stale_candidate_version_fails_with_409(
    verification_context: dict[str, Any],
) -> None:
    service = verification_context["service"]
    auth = verification_context["auth"]

    c = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Stale Version Check"},
        source_locator={"kind": "text_range", "start": 0, "end": 10},
        confidence=0.5,
    )
    update_id = _create_update_with_candidates(verification_context, [c])
    item = service.candidates(auth, update_id, cursor=None, limit=10).items[0]

    with pytest.raises(ApiError) as captured:
        service.decide(
            auth,
            update_id,
            SubmitVerificationDecisionsRequest(
                decisions=[
                    VerificationDecision(
                        candidate_id=item.id,
                        candidate_version=item.candidate_version + 99,  # Stale version
                        decision=VerificationDecisionValue.ACCEPT,
                    )
                ]
            ),
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 409
    assert captured.value.code == "version_conflict"


def test_decide_cross_update_or_cross_user_candidate_fails_with_404(
    verification_context: dict[str, Any],
) -> None:
    service = verification_context["service"]
    auth = verification_context["auth"]
    other_auth = verification_context["other_auth"]

    c1 = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "User 1 Concept"},
        source_locator={"kind": "text_range", "start": 0, "end": 10},
        confidence=0.5,
    )
    update_1 = _create_update_with_candidates(verification_context, [c1])
    item_1 = service.candidates(auth, update_1, cursor=None, limit=10).items[0]

    # Another update
    update_2 = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Update 2 note.",
        ),
        idempotency_key=str(uuid4()),
    )

    # Cross-update candidate reference fails with 404
    with pytest.raises(ApiError) as captured:
        service.decide(
            auth,
            update_2.id,
            SubmitVerificationDecisionsRequest(
                decisions=[
                    VerificationDecision(
                        candidate_id=item_1.id,
                        candidate_version=item_1.candidate_version,
                        decision=VerificationDecisionValue.ACCEPT,
                    )
                ]
            ),
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 404
    assert captured.value.code == "resource_not_found"

    # Cross-user candidate reference fails with 404
    with pytest.raises(ApiError) as captured:
        service.decide(
            other_auth,
            update_1,
            SubmitVerificationDecisionsRequest(
                decisions=[
                    VerificationDecision(
                        candidate_id=item_1.id,
                        candidate_version=item_1.candidate_version,
                        decision=VerificationDecisionValue.ACCEPT,
                    )
                ]
            ),
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 404
    assert captured.value.code == "resource_not_found"


def test_decide_double_decision_fails_with_409(
    verification_context: dict[str, Any],
) -> None:
    service = verification_context["service"]
    auth = verification_context["auth"]

    c = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Double Decision Check"},
        source_locator={"kind": "text_range", "start": 0, "end": 10},
        confidence=0.5,
    )
    update_id = _create_update_with_candidates(verification_context, [c])
    item = service.candidates(auth, update_id, cursor=None, limit=10).items[0]

    # First decision succeeds
    service.decide(
        auth,
        update_id,
        SubmitVerificationDecisionsRequest(
            decisions=[
                VerificationDecision(
                    candidate_id=item.id,
                    candidate_version=item.candidate_version,
                    decision=VerificationDecisionValue.ACCEPT,
                )
            ]
        ),
        idempotency_key=str(uuid4()),
    )

    # Second decision with fresh idempotency key fails with 409 invalid_state
    with pytest.raises(ApiError) as captured:
        service.decide(
            auth,
            update_id,
            SubmitVerificationDecisionsRequest(
                decisions=[
                    VerificationDecision(
                        candidate_id=item.id,
                        candidate_version=item.candidate_version + 1,
                        decision=VerificationDecisionValue.ACCEPT,
                    )
                ]
            ),
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 409
    assert captured.value.code == "invalid_state"


# ---------------------------------------------------------------------------
# Test Preview Boundaries & Commit Guards
# ---------------------------------------------------------------------------


def test_preview_blocked_when_verification_pending(
    verification_context: dict[str, Any],
) -> None:
    service = verification_context["service"]
    auth = verification_context["auth"]

    c = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Pending Concept"},
        source_locator={"kind": "text_range", "start": 0, "end": 10},
        confidence=0.5,
    )
    update_id = _create_update_with_candidates(verification_context, [c])

    preview = service.preview(auth, update_id)
    assert preview.can_commit is False
    assert preview.blocked_reason == "verification_pending"


def test_preview_blocked_when_all_rejected_no_valid_concept(
    verification_context: dict[str, Any],
) -> None:
    service = verification_context["service"]
    auth = verification_context["auth"]

    c = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "To Reject"},
        source_locator={"kind": "text_range", "start": 0, "end": 10},
        confidence=0.5,
    )
    update_id = _create_update_with_candidates(verification_context, [c])
    item = service.candidates(auth, update_id, cursor=None, limit=10).items[0]

    service.decide(
        auth,
        update_id,
        SubmitVerificationDecisionsRequest(
            decisions=[
                VerificationDecision(
                    candidate_id=item.id,
                    candidate_version=item.candidate_version,
                    decision=VerificationDecisionValue.REJECT,
                )
            ]
        ),
        idempotency_key=str(uuid4()),
    )

    preview = service.preview(auth, update_id)
    assert preview.can_commit is False
    assert preview.blocked_reason == "no_valid_concept"
    assert preview.concept_count == 0
    assert preview.first_concepts == []
    assert preview.estimated_first_mission_minutes is None


def test_cannot_commit_with_pending_verifications(
    verification_context: dict[str, Any],
) -> None:
    service = verification_context["service"]
    auth = verification_context["auth"]

    c = ExtractedCandidate(
        candidate_type="concept",
        payload={"title": "Pending Concept"},
        source_locator={"kind": "text_range", "start": 0, "end": 10},
        confidence=0.5,
    )
    update_id = _create_update_with_candidates(verification_context, [c])

    # Attempting to commit before verifying fails with 409
    with pytest.raises(ApiError) as captured:
        service.commit(auth, update_id, idempotency_key=str(uuid4()))
    assert captured.value.status_code == 409
    assert captured.value.code == "invalid_state"
    assert "remaining concepts" in captured.value.message.lower()
