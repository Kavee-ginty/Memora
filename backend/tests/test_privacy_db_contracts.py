from __future__ import annotations

import os
from collections.abc import Iterator
from datetime import UTC, datetime, timedelta
from pathlib import Path
from uuid import UUID, uuid4

import pytest
from alembic import command
from alembic.config import Config
from pydantic import SecretStr
from sqlalchemy import Engine, create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.exc import DBAPIError

from memora.api.errors import ApiError
from memora.api.security import AuthContext, AuthenticatedRequest
from memora.api.v1.schemas.privacy import (
    PrivacyDeletionCancelRequest,
    PrivacyDeletionRequest,
    PrivacyExportRequest,
)
from memora.core.config import Settings
from memora.db.seed import seed_database
from memora.modules.privacy.constants import (
    SCOPE_AUTH_PROVIDER,
    SCOPE_DATABASE,
    SCOPE_UPLOADS,
)
from memora.modules.privacy.repository import PrivacyRepository
from memora.modules.privacy.service import PrivacyService
from memora.worker.main import run_worker_once

BACKEND_ROOT = Path(__file__).parents[1]
DISPOSABLE_DATABASE_SUFFIXES = ("_test", "_ci")
ISSUER = "https://privacy-test.supabase.co/auth/v1"


def alembic_config(database_url: str) -> Config:
    config = Config(BACKEND_ROOT / "alembic.ini")
    config.set_main_option("script_location", str(BACKEND_ROOT / "migrations"))
    config.set_main_option("sqlalchemy.url", database_url.replace("%", "%%"))
    return config


@pytest.fixture
def database(monkeypatch: pytest.MonkeyPatch) -> Iterator[Engine]:
    database_url = os.getenv("MEMORA_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("MEMORA_TEST_DATABASE_URL is not configured")

    try:
        database_name = make_url(database_url).database or ""
    except Exception:
        pytest.fail("MEMORA_TEST_DATABASE_URL is not a valid SQLAlchemy URL", pytrace=False)

    if not database_name.endswith(DISPOSABLE_DATABASE_SUFFIXES):
        pytest.fail(
            "MEMORA_TEST_DATABASE_URL must target a disposable database ending in "
            f"{' or '.join(DISPOSABLE_DATABASE_SUFFIXES)}",
            pytrace=False,
        )

    monkeypatch.setenv("MEMORA_DATABASE_URL", database_url)
    command.upgrade(alembic_config(database_url), "head")
    seed_database(database_url)
    engine = create_engine(database_url, connect_args={"connect_timeout": 10})
    try:
        yield engine
    finally:
        engine.dispose()


def make_user(engine: Engine, subject: str) -> tuple[UUID, AuthenticatedRequest]:
    user_id = uuid4()
    with engine.begin() as connection:
        connection.execute(
            text(
                """
                INSERT INTO users(id, oidc_issuer, oidc_subject, status, default_timezone, locale)
                VALUES (:id, :issuer, :subject, 'active', 'Asia/Colombo', 'en-LK')
                """
            ),
            {"id": user_id, "issuer": ISSUER, "subject": subject},
        )
        connection.execute(
            text(
                """
                INSERT INTO user_profiles(user_id, display_name)
                VALUES (:id, 'Test Student')
                """
            ),
            {"id": user_id},
        )

    auth = AuthenticatedRequest(
        context=AuthContext(
            issuer=ISSUER,
            subject=subject,
            session_id=uuid4(),
            role="authenticated",
            authenticated_at=datetime.now(UTC),
            expires_at=datetime.now(UTC) + timedelta(minutes=10),
        ),
        access_token=SecretStr("token"),
    )
    return user_id, auth


def test_privacy_export_end_to_end_with_worker(database: Engine) -> None:
    user_id, auth = make_user(database, f"user-export-{uuid4()}")
    repo = PrivacyRepository(database)
    settings = Settings(recent_auth_window_seconds=600)
    service = PrivacyService(repo, settings)

    # 1. Create Export
    key = f"exp-key-{uuid4()}"
    export = service.create_export(auth, PrivacyExportRequest(), idempotency_key=key)
    assert export.status == "requested"
    assert export.download_url is None

    # Idempotent retry returns same export
    retry_export = service.create_export(
        auth,
        PrivacyExportRequest(),
        idempotency_key=f"exp-key2-{uuid4()}",
    )
    # Convergence rule: active export returned
    assert retry_export.id == export.id

    # 2. Worker executes job
    processed = run_worker_once(database, limit=5)
    assert processed >= 1

    # 3. Read status after worker completion
    completed_export = service.get_export(auth, export.id)
    assert completed_export.status == "completed"
    assert completed_export.completed_at is not None
    assert completed_export.download_url is not None
    assert completed_export.download_expires_at is not None

    # Verify audit event recorded
    with database.begin() as conn:
        audits = (
            conn.execute(
                text("SELECT action FROM audit_events WHERE resource_id = :id"),
                {"id": export.id},
            )
            .scalars()
            .all()
        )
        assert "privacy.export.requested" in audits
        assert "privacy.export.completed" in audits


def test_privacy_deletion_cancellation_and_proofs(database: Engine) -> None:
    user_id, auth = make_user(database, f"user-del-{uuid4()}")
    repo = PrivacyRepository(database)
    settings = Settings(recent_auth_window_seconds=600)
    service = PrivacyService(repo, settings)

    # 1. Create Deletion Request
    key = f"del-key-{uuid4()}"
    req_body = PrivacyDeletionRequest(confirmed=True)
    deletion = service.create_deletion(auth, req_body, idempotency_key=key)
    assert deletion.status == "requested"

    # Verify user marked deletion_pending
    with database.begin() as conn:
        status = conn.execute(
            text("SELECT status FROM users WHERE id = :user_id"),
            {"user_id": user_id},
        ).scalar_one()
        assert status == "deletion_pending"

    # 2. Cancel while requested
    cancel_key = f"cancel-key-{uuid4()}"
    cancelled = service.cancel_deletion(
        auth,
        deletion.id,
        PrivacyDeletionCancelRequest(reason="User cancelled"),
        idempotency_key=cancel_key,
    )
    assert cancelled.status == "cancelled"

    # Verify user reverted to active
    with database.begin() as conn:
        status = conn.execute(
            text("SELECT status FROM users WHERE id = :user_id"),
            {"user_id": user_id},
        ).scalar_one()
        assert status == "active"

    # 3. Create a second deletion and let worker execute it
    key2 = f"del-key2-{uuid4()}"
    deletion2 = service.create_deletion(auth, req_body, idempotency_key=key2)
    assert deletion2.status == "requested"

    processed = run_worker_once(database, limit=5)
    assert processed >= 1

    # 4. Check completed deletion state
    finished = service.get_deletion(auth, deletion2.id)
    assert finished.status == "completed"
    assert len(finished.proofs) == 3
    scopes = {p.scope for p in finished.proofs}
    assert scopes == {SCOPE_DATABASE, SCOPE_UPLOADS, SCOPE_AUTH_PROVIDER}
    assert len(finished.retention_exceptions) > 0

    # 5. Verify user is now deleted
    with database.begin() as conn:
        user_row = (
            conn.execute(
                text("SELECT status, deleted_at FROM users WHERE id = :user_id"),
                {"user_id": user_id},
            )
            .mappings()
            .one()
        )
        assert user_row["status"] == "deleted"
        assert user_row["deleted_at"] is not None

        # Verify deletion_proofs append-only trigger
        proof_id = finished.proofs[0].id
        with pytest.raises(DBAPIError):
            conn.execute(
                text("DELETE FROM deletion_proofs WHERE id = :id"),
                {"id": proof_id},
            )


def test_cross_user_isolation(database: Engine) -> None:
    _, auth1 = make_user(database, f"user1-{uuid4()}")
    _, auth2 = make_user(database, f"user2-{uuid4()}")
    repo = PrivacyRepository(database)
    settings = Settings(recent_auth_window_seconds=600)
    service = PrivacyService(repo, settings)

    export = service.create_export(auth1, PrivacyExportRequest(), idempotency_key=f"k1-{uuid4()}")

    # User 2 cannot access User 1's export
    with pytest.raises(ApiError) as exc:
        service.get_export(auth2, export.id)
    assert exc.value.status_code == 404

    del_body = PrivacyDeletionRequest(confirmed=True)
    deletion = service.create_deletion(auth1, del_body, idempotency_key=f"k2-{uuid4()}")

    # User 2 cannot cancel User 1's deletion
    with pytest.raises(ApiError) as exc_cancel:
        cancel_body = PrivacyDeletionCancelRequest()
        service.cancel_deletion(auth2, deletion.id, cancel_body, idempotency_key=f"k3-{uuid4()}")
    assert exc_cancel.value.status_code == 404
