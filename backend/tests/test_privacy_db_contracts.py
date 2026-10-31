from __future__ import annotations

import json
import os
import zipfile
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
from memora.modules.privacy.provider import (
    get_auth_provider,
    set_auth_provider,
)
from memora.modules.privacy.repository import PrivacyRepository
from memora.modules.privacy.service import PrivacyService
from memora.modules.privacy.storage import (
    export_archive_exists,
    get_export_archive_path,
)
from memora.worker.main import process_one_job, run_worker_once
from memora.worker.memory import recover_expired_leases

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


def test_privacy_export_end_to_end_with_worker_and_package_contents(
    database: Engine, tmp_path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setenv("MEMORA_EXPORT_STORAGE_DIR", str(tmp_path))
    user_id, auth = make_user(database, f"user-export-{uuid4()}")
    repo = PrivacyRepository(database)
    settings = Settings(recent_auth_window_seconds=600)
    service = PrivacyService(repo, settings)

    # Seed user preferences and consent
    with database.begin() as conn:
        conn.execute(
            text(
                """
                INSERT INTO notification_preferences(
                    user_id, mission_enabled, reward_enabled, timezone,
                    lock_screen_detail, max_daily_reminders
                )
                VALUES (:user_id, true, true, 'Asia/Colombo', 'minimal', 2)
                ON CONFLICT (user_id) DO UPDATE SET mission_enabled = true
                """
            ),
            {"user_id": user_id},
        )
        conn.execute(
            text(
                """
                INSERT INTO consent_records(
                    user_id, consent_type, policy_version, decision, decided_at, evidence
                )
                VALUES (
                    :user_id, 'terms', '1.0', 'granted', now(),
                    '{"schema_version": "1"}'::jsonb
                )
                """
            ),
            {"user_id": user_id},
        )

    # 1. Create Export
    key = f"exp-key-{uuid4()}"
    export = service.create_export(auth, PrivacyExportRequest(), idempotency_key=key)
    assert export.status == "requested"
    assert export.download_url is None

    # 2. Worker executes job
    processed = run_worker_once(database, limit=5)
    assert processed >= 1

    # 3. Read status after worker completion
    completed_export = service.get_export(auth, export.id)
    assert completed_export.status == "completed"
    assert completed_export.completed_at is not None
    assert completed_export.download_url is not None
    assert completed_export.download_expires_at is not None

    # 4. Verify Archive on Disk & Contents
    assert export_archive_exists(export.id)
    archive_path = get_export_archive_path(export.id)
    with zipfile.ZipFile(archive_path, mode="r") as zf:
        namelist = zf.namelist()
        assert "export.json" in namelist
        assert "summary.txt" in namelist

        pkg = json.loads(zf.read("export.json").decode("utf-8"))
        assert pkg["schema_version"] == "1.0"
        assert pkg["user_id"] == str(user_id)
        assert pkg["profile"]["display_name"] == "Test Student"
        assert pkg["notification_preferences"]["mission_enabled"] is True

        summary = zf.read("summary.txt").decode("utf-8")
        assert "Test Student" in summary
        assert "Memora Learner Data Export" in summary

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


def test_concurrent_duplicate_requests_converge(database: Engine) -> None:
    user_id, auth = make_user(database, f"user-converge-{uuid4()}")
    repo = PrivacyRepository(database)
    settings = Settings(recent_auth_window_seconds=600)
    service = PrivacyService(repo, settings)

    # Multiple create export requests with different idempotency keys converge
    key1 = f"key1-{uuid4()}"
    key2 = f"key2-{uuid4()}"
    exp1 = service.create_export(auth, PrivacyExportRequest(), idempotency_key=key1)
    exp2 = service.create_export(auth, PrivacyExportRequest(), idempotency_key=key2)

    assert exp1.id == exp2.id

    with database.begin() as conn:
        active_jobs = conn.scalar(
            text(
                """
                SELECT count(*) FROM background_jobs
                WHERE resource_id = :id AND job_type = 'privacy.export'
                """
            ),
            {"id": exp1.id},
        )
        assert active_jobs == 1

        active_reqs = conn.scalar(
            text(
                """
                SELECT count(*) FROM privacy_requests
                WHERE user_id = :user_id AND request_type = 'export'
                  AND status IN ('requested', 'verifying', 'processing')
                """
            ),
            {"user_id": user_id},
        )
        assert active_reqs == 1


def test_privacy_deletion_deletes_learner_data_and_verifies_absence(database: Engine) -> None:
    user_id, auth = make_user(database, f"user-full-del-{uuid4()}")
    repo = PrivacyRepository(database)
    settings = Settings(recent_auth_window_seconds=600)
    service = PrivacyService(repo, settings)

    # Seed private learner data across multiple tables
    from memora.modules.curriculum.seed_data import CONCEPTS_DATA

    concept = CONCEPTS_DATA[0]
    concept_id = concept["concept_id"]
    version_id = concept["version_id"]

    with database.begin() as conn:
        conn.execute(
            text(
                """
                INSERT INTO notification_preferences(
                    user_id, mission_enabled, reward_enabled, timezone,
                    lock_screen_detail, max_daily_reminders
                )
                VALUES (:user_id, true, true, 'Asia/Colombo', 'minimal', 2)
                ON CONFLICT (user_id) DO NOTHING
                """
            ),
            {"user_id": user_id},
        )
        conn.execute(
            text(
                """
                INSERT INTO device_registrations(
                    user_id, installation_id, platform, token_fingerprint,
                    push_token_ciphertext, app_version, last_seen_at
                )
                VALUES (
                    :user_id, gen_random_uuid(), 'android', :fp,
                    decode('deadbeef', 'hex'), '1.0.0', now()
                )
                """
            ),
            {"user_id": user_id, "fp": f"fp-{uuid4()}"},
        )
        conn.execute(
            text(
                """
                INSERT INTO learner_concept_states(
                    user_id, concept_id, active_concept_version_id,
                    difficulty, stability_days, last_retrievability,
                    evidence_confidence, first_exposed_at, next_review_at,
                    exposure_count, eligible_review_count, lapse_count,
                    engine_version
                )
                VALUES (
                    :user_id, :concept_id, :version_id,
                    2.5, 1.0, 0.9,
                    0.8, now(), now() + interval '1 day',
                    1, 1, 0,
                    'v1'
                )
                """
            ),
            {"user_id": user_id, "concept_id": concept_id, "version_id": version_id},
        )

    # Create deletion
    del_key = f"del-full-{uuid4()}"
    deletion = service.create_deletion(
        auth, PrivacyDeletionRequest(confirmed=True), idempotency_key=del_key
    )
    assert deletion.status == "requested"

    # Worker executes deletion
    processed = run_worker_once(database, limit=5)
    assert processed >= 1

    # Verify completed response
    completed = service.get_deletion(auth, deletion.id)
    assert completed.status == "completed"
    assert len(completed.proofs) == 3
    scopes = {p.scope for p in completed.proofs}
    assert scopes == {SCOPE_DATABASE, SCOPE_UPLOADS, SCOPE_AUTH_PROVIDER}

    # Verify all private learner states are deleted in PostgreSQL
    with database.begin() as conn:
        assert (
            conn.scalar(
                text("SELECT count(*) FROM learner_concept_states WHERE user_id = :u"),
                {"u": user_id},
            )
            == 0
        )
        assert (
            conn.scalar(
                text("SELECT count(*) FROM private_knowledge_items WHERE user_id = :u"),
                {"u": user_id},
            )
            == 0
        )
        assert (
            conn.scalar(
                text("SELECT count(*) FROM device_registrations WHERE user_id = :u"), {"u": user_id}
            )
            == 0
        )
        assert (
            conn.scalar(
                text("SELECT count(*) FROM notification_preferences WHERE user_id = :u"),
                {"u": user_id},
            )
            == 0
        )

        # Profile is anonymized
        prof = (
            conn.execute(
                text("SELECT display_name FROM user_profiles WHERE user_id = :u"),
                {"u": user_id},
            )
            .mappings()
            .one()
        )
        assert prof["display_name"] == "Deleted Learner"

        # User is deleted
        user_row = (
            conn.execute(
                text("SELECT status, deleted_at FROM users WHERE id = :u"),
                {"u": user_id},
            )
            .mappings()
            .one()
        )
        assert user_row["status"] == "deleted"
        assert user_row["deleted_at"] is not None


def test_cancellation_sanitizes_audit_metadata_and_cancels_job(database: Engine) -> None:
    user_id, auth = make_user(database, f"user-cancel-{uuid4()}")
    repo = PrivacyRepository(database)
    settings = Settings(recent_auth_window_seconds=600)
    service = PrivacyService(repo, settings)

    key = f"del-canc-{uuid4()}"
    del_req = service.create_deletion(
        auth, PrivacyDeletionRequest(confirmed=True), idempotency_key=key
    )

    # Cancel with arbitrary unallowlisted text
    sensitive_input = "My private note: password123, formula E=mc^2"
    cancel_key = f"canc-{uuid4()}"
    cancelled = service.cancel_deletion(
        auth,
        del_req.id,
        PrivacyDeletionCancelRequest(reason=sensitive_input),
        idempotency_key=cancel_key,
    )
    assert cancelled.status == "cancelled"

    with database.begin() as conn:
        # User reverted to active
        u_status = conn.scalar(text("SELECT status FROM users WHERE id = :u"), {"u": user_id})
        assert u_status == "active"

        # Background job was marked cancelled
        job_status = conn.scalar(
            text("SELECT status FROM background_jobs WHERE resource_id = :id"),
            {"id": del_req.id},
        )
        assert job_status == "cancelled"

        # Audit event has sanitized reason code (never raw user text)
        audit = (
            conn.execute(
                text(
                    """
                    SELECT safe_metadata FROM audit_events
                    WHERE resource_id = :id AND action = 'privacy.deletion.cancelled'
                    """
                ),
                {"id": del_req.id},
            )
            .mappings()
            .one()
        )
        metadata = audit["safe_metadata"]
        assert metadata["reason"] == "user_requested"
        assert sensitive_input not in str(metadata)


def test_worker_job_retry_backoff_and_outage_recovery(database: Engine) -> None:
    user_id, auth = make_user(database, f"user-retry-{uuid4()}")
    repo = PrivacyRepository(database)
    settings = Settings(recent_auth_window_seconds=600)
    service = PrivacyService(repo, settings)

    class FailingAuthProvider:
        def __init__(self) -> None:
            self.should_fail = True

        def delete_user(self, user_id, oidc_subject: str) -> bool:
            if self.should_fail:
                raise RuntimeError("Simulated provider outage / timeout")
            return True

        def verify_user_absent(self, user_id, oidc_subject: str) -> bool:
            return not self.should_fail

    prov = FailingAuthProvider()
    original_prov = get_auth_provider()
    set_auth_provider(prov)

    try:
        key = f"del-outage-{uuid4()}"
        del_req = service.create_deletion(
            auth, PrivacyDeletionRequest(confirmed=True), idempotency_key=key
        )

        # 1. First execution fails due to provider outage
        processed = process_one_job(database)
        assert processed is True

        # Job enters retry_wait with attempt_count = 1
        with database.begin() as conn:
            job = (
                conn.execute(
                    text(
                        """
                        SELECT status, attempt_count, max_attempts, available_at
                        FROM background_jobs WHERE resource_id = :id
                        """
                    ),
                    {"id": del_req.id},
                )
                .mappings()
                .one()
            )
            assert job["status"] == "retry_wait"
            assert job["attempt_count"] == 1
            assert job["available_at"] > datetime.now(UTC)

        # 2. Simulate provider recovery
        prov.should_fail = False

        # Fast forward available_at to now so worker can claim it
        with database.begin() as conn:
            conn.execute(
                text(
                    """
                    UPDATE background_jobs
                    SET available_at = now() - interval '1 second'
                    WHERE resource_id = :id
                    """
                ),
                {"id": del_req.id},
            )

        # 3. Worker re-claims and succeeds
        processed2 = process_one_job(database)
        assert processed2 is True

        with database.begin() as conn:
            job = (
                conn.execute(
                    text("SELECT status FROM background_jobs WHERE resource_id = :id"),
                    {"id": del_req.id},
                )
                .mappings()
                .one()
            )
            assert job["status"] == "succeeded"

        finished = service.get_deletion(auth, del_req.id)
        assert finished.status == "completed"

    finally:
        set_auth_provider(original_prov)


def test_expired_lease_reconciliation(database: Engine) -> None:
    now = datetime.now(UTC)
    with database.begin() as conn:
        job_id = uuid4()
        conn.execute(
            text(
                """
                INSERT INTO background_jobs(
                    id, job_type, resource_type, resource_id, dedupe_key,
                    status, attempt_count, max_attempts, available_at,
                    lease_owner, lease_expires_at, payload
                ) VALUES (
                    :id, 'privacy.export', 'privacy_request', :res_id, :dedupe,
                    'leased', 1, 3, :now, 'crashed_worker', :expired,
                    '{"schema_version":"1"}'::jsonb
                )
                """
            ),
            {
                "id": job_id,
                "res_id": uuid4(),
                "dedupe": f"lease-test-{job_id}",
                "now": now,
                "expired": now - timedelta(minutes=10),
            },
        )

        recovered = recover_expired_leases(conn, now=now)
        assert recovered >= 1

        new_status = conn.scalar(
            text("SELECT status FROM background_jobs WHERE id = :id"),
            {"id": job_id},
        )
        assert new_status == "queued"


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
