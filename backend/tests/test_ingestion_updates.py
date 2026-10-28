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
from cryptography.exceptions import InvalidTag
from pydantic import SecretStr
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

from memora.api.errors import ApiError
from memora.api.security import AuthContext, AuthenticatedRequest
from memora.api.v1.schemas.ingestion import (
    CreateLearningUpdateRequest,
    UpdateLearningUpdateRequest,
)
from memora.core.config import Settings
from memora.db.seed import seed_database
from memora.modules.ingestion.repository import IngestionRepository
from memora.modules.ingestion.service import IngestionService, ManualTextProtector
from memora.modules.ingestion.storage import MemoryObjectStorage

BACKEND_ROOT = Path(__file__).resolve().parents[1]
PHYSICS_SUBJECT_ID = UUID("10000000-0000-0000-0000-000000000001")
INGESTION_KEY = "cGe/2UxRnTY3D17CPcFSnrHkGqBSwmcmJ+ehN4XFMxc="


def test_manual_text_protector_lifecycle_and_tamper_detection() -> None:
    raw_key = base64.b64decode(INGESTION_KEY)
    protector = ManualTextProtector(raw_key)

    # Key length validation
    with pytest.raises(ValueError, match="exactly 32 bytes"):
        ManualTextProtector(b"short-key")

    update_id = uuid4()
    other_update_id = uuid4()
    secret_text = "F = m * a (Newton's second law)"

    encrypted = protector.encrypt(secret_text, update_id=update_id)
    assert secret_text.encode("utf-8") not in encrypted

    # Decrypt with matching update_id
    decrypted = protector.decrypt(encrypted, update_id=update_id)
    assert decrypted == secret_text

    # Decrypt with mismatched update_id (AAD verification fails)
    with pytest.raises(InvalidTag):
        protector.decrypt(encrypted, update_id=other_update_id)

    # Decrypt with invalid version prefix
    with pytest.raises(ValueError, match="Unsupported protected text version"):
        protector.decrypt(b"\x02" + encrypted[1:], update_id=update_id)

    # Decrypt with empty payload
    with pytest.raises(ValueError, match="Unsupported protected text version"):
        protector.decrypt(b"", update_id=update_id)


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
def update_context(ingestion_engine: Engine) -> dict[str, Any]:
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
    return {
        "engine": ingestion_engine,
        "service": service,
        "storage": storage,
        "settings": settings,
        "auth": _create_user_with_consent(ingestion_engine, has_material_consent=True),
        "no_consent_auth": _create_user_with_consent(ingestion_engine, has_material_consent=False),
        "other_auth": _create_user_with_consent(ingestion_engine, has_material_consent=True),
    }


def test_create_requires_material_processing_consent(update_context: dict[str, Any]) -> None:
    service = update_context["service"]
    auth = update_context["no_consent_auth"]

    with pytest.raises(ApiError) as captured:
        service.create(
            auth,
            CreateLearningUpdateRequest(
                subject_id=PHYSICS_SUBJECT_ID,
                input_type="manual_text",
                learned_at=datetime.now(UTC),
                client_operation_id=uuid4(),
                manual_text="Displacement is vector, distance is scalar.",
            ),
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 403
    assert captured.value.code == "consent_required"


def test_create_rejects_future_learned_at(update_context: dict[str, Any]) -> None:
    service = update_context["service"]
    auth = update_context["auth"]

    future_time = datetime.now(UTC) + timedelta(minutes=15)
    with pytest.raises(ApiError) as captured:
        service.create(
            auth,
            CreateLearningUpdateRequest(
                subject_id=PHYSICS_SUBJECT_ID,
                input_type="manual_text",
                learned_at=future_time,
                client_operation_id=uuid4(),
                manual_text="Work done equals force times displacement.",
            ),
            idempotency_key=str(uuid4()),
        )
    assert captured.value.status_code == 422
    assert captured.value.code == "validation_failed"


def test_create_same_day_multiples_are_independent(update_context: dict[str, Any]) -> None:
    service = update_context["service"]
    auth = update_context["auth"]
    now = datetime.now(UTC)

    first = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=now,
            client_operation_id=uuid4(),
            manual_text="Newton's first law: inertia.",
        ),
        idempotency_key=str(uuid4()),
    )

    second = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=now,
            client_operation_id=uuid4(),
            manual_text="Newton's second law: F = dp/dt.",
        ),
        idempotency_key=str(uuid4()),
    )

    assert first.id != second.id
    assert first.status == "processing"
    assert second.status == "processing"


def test_create_idempotent_replay_and_conflict(update_context: dict[str, Any]) -> None:
    service = update_context["service"]
    auth = update_context["auth"]
    now = datetime.now(UTC)
    client_op_id = uuid4()
    idempotency_key = str(uuid4())

    body1 = CreateLearningUpdateRequest(
        subject_id=PHYSICS_SUBJECT_ID,
        input_type="manual_text",
        learned_at=now,
        client_operation_id=client_op_id,
        manual_text="Conservation of momentum.",
    )

    # First call succeeds
    first = service.create(auth, body1, idempotency_key=idempotency_key)

    # Replay with same idempotency key and same body returns identical update
    replay = service.create(auth, body1, idempotency_key=idempotency_key)
    assert first.id == replay.id

    # Same idempotency key with different body raises 409 conflict
    body2 = CreateLearningUpdateRequest(
        subject_id=PHYSICS_SUBJECT_ID,
        input_type="manual_text",
        learned_at=now,
        client_operation_id=uuid4(),
        manual_text="Different text under same idempotency key.",
    )
    with pytest.raises(ApiError) as conflict:
        service.create(auth, body2, idempotency_key=idempotency_key)
    assert conflict.value.status_code == 409
    assert conflict.value.code == "idempotency_key_reused"


def test_update_never_exposes_raw_manual_text_in_response(
    update_context: dict[str, Any],
) -> None:
    service = update_context["service"]
    auth = update_context["auth"]
    secret_note = "SECRET_PHYSICS_NOTE_NEVER_IN_RESPONSE"

    created = service.create(
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

    assert created.has_manual_text is True
    assert not hasattr(created, "manual_text")
    assert secret_note not in created.model_dump_json()

    fetched = service.get(auth, created.id)
    assert fetched.has_manual_text is True
    assert not hasattr(fetched, "manual_text")
    assert secret_note not in fetched.model_dump_json()


def test_list_updates_and_cursor_pagination(update_context: dict[str, Any]) -> None:
    service = update_context["service"]
    auth = update_context["auth"]
    now = datetime.now(UTC)

    ids = []
    for i in range(3):
        res = service.create(
            auth,
            CreateLearningUpdateRequest(
                subject_id=PHYSICS_SUBJECT_ID,
                input_type="manual_text",
                learned_at=now + timedelta(seconds=i),
                client_operation_id=uuid4(),
                manual_text=f"Note number {i}",
            ),
            idempotency_key=str(uuid4()),
        )
        ids.append(res.id)

    # First page with limit=2
    page1 = service.list(auth, cursor=None, limit=2)
    assert len(page1.items) == 2
    assert page1.has_more is True
    assert page1.next_cursor is not None

    # Second page using cursor
    page2 = service.list(auth, cursor=page1.next_cursor, limit=2)
    assert len(page2.items) == 1
    assert page2.has_more is False


def test_patch_draft_success_and_version_conflict(update_context: dict[str, Any]) -> None:
    service = update_context["service"]
    auth = update_context["auth"]

    # Insert a draft directly
    engine = update_context["engine"]
    update_id = uuid4()
    with engine.begin() as connection:
        user_row = (
            connection.execute(
                text("SELECT id FROM users WHERE oidc_subject = :sub"),
                {"sub": auth.context.subject},
            )
            .mappings()
            .one()
        )
        connection.execute(
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
                "id": update_id,
                "user_id": user_row["id"],
                "subject_id": PHYSICS_SUBJECT_ID,
                "op_id": uuid4(),
            },
        )

    # Successful patch with matching version=1
    patched = service.update(
        auth,
        update_id,
        UpdateLearningUpdateRequest(
            version=1,
            manual_text="Updated text for draft",
        ),
        idempotency_key=str(uuid4()),
    )
    assert patched.row_version == 2

    # Patch with stale version=1 raises 409 version_conflict
    with pytest.raises(ApiError) as conflict:
        service.update(
            auth,
            update_id,
            UpdateLearningUpdateRequest(
                version=1,
                manual_text="Stale version edit",
            ),
            idempotency_key=str(uuid4()),
        )
    assert conflict.value.status_code == 409
    assert conflict.value.code == "version_conflict"


def test_discard_update_lifecycle_and_owner_isolation(
    update_context: dict[str, Any],
) -> None:
    service = update_context["service"]
    auth = update_context["auth"]
    other_auth = update_context["other_auth"]

    created = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Energy cannot be created or destroyed.",
        ),
        idempotency_key=str(uuid4()),
    )

    # Cross-user get fails with 404
    with pytest.raises(ApiError) as captured:
        service.get(other_auth, created.id)
    assert captured.value.status_code == 404

    # Cross-user discard fails with 404
    with pytest.raises(ApiError) as captured:
        service.discard(other_auth, created.id, idempotency_key=str(uuid4()))
    assert captured.value.status_code == 404

    # Owner discard marks update deleted
    discarded, cleanup_needed = service.discard(auth, created.id, idempotency_key=str(uuid4()))
    assert discarded.status == "deleted"
    assert cleanup_needed is False
