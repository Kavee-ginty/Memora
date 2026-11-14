import os
from datetime import UTC, datetime, timedelta
from pathlib import Path
from uuid import UUID, uuid4

import pytest
from alembic import command
from alembic.config import Config
from alembic.script import ScriptDirectory
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine, make_url
from sqlalchemy.exc import DBAPIError

from memora.api.errors import ApiError
from memora.api.security import AuthContext
from memora.db.seed import seed_database
from memora.modules.identity.repository import IdentityRepository

BACKEND_ROOT = Path(__file__).parents[1]
CONNECT_TIMEOUT_SECONDS = 10
DISPOSABLE_DATABASE_SUFFIXES = ("_test", "_ci")
MIGRATION_SQL = (
    BACKEND_ROOT / "migrations" / "versions" / "20261023_0001_mvp_schema.up.sql"
).read_text(encoding="utf-8")

EXPECTED_TABLES = {
    "users",
    "user_profiles",
    "consent_records",
    "device_registrations",
    "notification_preferences",
    "subjects",
    "curriculum_versions",
    "learning_objectives",
    "concepts",
    "concept_versions",
    "concept_aliases",
    "knowledge_claims",
    "concept_edges",
    "concept_objective_maps",
    "concept_embeddings",
    "claim_embeddings",
    "question_embeddings",
    "learning_updates",
    "source_uploads",
    "extraction_candidates",
    "verification_requests",
    "verification_decisions",
    "knowledge_commits",
    "private_knowledge_items",
    "questions",
    "question_versions",
    "question_options",
    "question_rubrics",
    "question_concept_maps",
    "question_reports",
    "learner_concept_states",
    "memory_events",
    "memory_decisions",
    "missions",
    "mission_items",
    "attempts",
    "grading_results",
    "xp_ledger",
    "streak_days",
    "reward_definitions",
    "reward_grants",
    "reef_projections",
    "idempotency_records",
    "outbox_events",
    "background_jobs",
    "audit_events",
    "privacy_requests",
    "deletion_proofs",
}

OWNER_RLS_TABLES = {
    "users",
    "user_profiles",
    "consent_records",
    "device_registrations",
    "notification_preferences",
    "learning_updates",
    "source_uploads",
    "extraction_candidates",
    "verification_requests",
    "verification_decisions",
    "private_knowledge_items",
    "knowledge_commits",
    "learner_concept_states",
    "memory_events",
    "memory_decisions",
    "missions",
    "mission_items",
    "attempts",
    "grading_results",
    "question_reports",
    "xp_ledger",
    "streak_days",
    "reward_grants",
    "reef_projections",
    "privacy_requests",
    "deletion_proofs",
    "idempotency_records",
}

STATUS_VALUES = {
    "subjects": {"draft", "approved", "retired"},
    "curriculum_versions": {"draft", "approved", "retired", "superseded"},
    "users": {"active", "suspended", "deletion_pending", "deleted"},
    "concepts": {"draft", "approved", "retired"},
    "concept_versions": {"draft", "approved", "retired"},
    "knowledge_claims": {"draft", "approved", "disputed", "retired"},
    "concept_edges": {"candidate", "approved", "rejected", "retired"},
    "questions": {"draft", "approved", "retired"},
    "question_versions": {"draft", "approved", "rejected", "retired"},
    "question_rubrics": {"draft", "approved", "retired"},
    "learning_updates": {
        "draft",
        "uploading",
        "processing",
        "verification_required",
        "committed",
        "failed",
        "expired",
        "deleted",
    },
    "source_uploads": {
        "authorized",
        "uploaded",
        "validated",
        "processing",
        "deleting",
        "deleted",
        "rejected",
        "expired",
    },
    "extraction_candidates": {
        "candidate",
        "needs_verification",
        "accepted",
        "rejected",
        "committed",
        "expired",
    },
    "verification_requests": {"pending", "answered", "expired", "cancelled"},
    "private_knowledge_items": {"active", "disputed", "retired", "deleted"},
    "missions": {"planned", "started", "paused", "completed", "expired", "abandoned"},
    "mission_items": {"pending", "presented", "answered", "skipped", "cancelled"},
    "question_reports": {"submitted", "triaged", "under_review", "resolved", "dismissed"},
    "reward_definitions": {"draft", "approved", "retired"},
    "idempotency_records": {"processing", "completed", "failed"},
    "outbox_events": {"pending", "published", "failed"},
    "background_jobs": {
        "queued",
        "leased",
        "retry_wait",
        "succeeded",
        "failed",
        "dead_lettered",
        "cancelled",
    },
    "privacy_requests": {
        "requested",
        "verifying",
        "processing",
        "completed",
        "failed",
        "cancelled",
    },
}


def test_migration_graph_has_one_head() -> None:
    config = Config(BACKEND_ROOT / "alembic.ini")
    config.set_main_option("script_location", str(BACKEND_ROOT / "migrations"))

    assert len(ScriptDirectory.from_config(config).get_heads()) == 1


INSERT_UPDATE_SQL = text(
    """
    INSERT INTO learning_updates(
        id, user_id, subject_id, curriculum_version_id, input_type, status,
        learned_at, client_operation_id, expires_at
    ) VALUES (
        :id, :user_id, '10000000-0000-0000-0000-000000000001',
        '20000000-0000-0000-0000-000000000001', 'manual_text', 'processing',
        now(), gen_random_uuid(), now() + interval '1 day'
    )
    """
)


def alembic_config(database_url: str) -> Config:
    config = Config(BACKEND_ROOT / "alembic.ini")
    config.set_main_option("script_location", str(BACKEND_ROOT / "migrations"))
    config.set_main_option("sqlalchemy.url", database_url.replace("%", "%%"))
    return config


@pytest.fixture
def migration_database_url(monkeypatch: pytest.MonkeyPatch) -> str:
    """Provide a disposable database and stop a downgrade from reaching real data."""
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
            f"{' or '.join(DISPOSABLE_DATABASE_SUFFIXES)}; these tests downgrade to base",
            pytrace=False,
        )

    # Alembic's env.py reads this variable, so scope it to the test and restore it afterwards.
    monkeypatch.setenv("MEMORA_DATABASE_URL", database_url)
    return database_url


def create_test_engine(database_url: str) -> Engine:
    """Create an engine that cannot wait forever for an unreachable server."""
    return create_engine(
        database_url,
        connect_args={"connect_timeout": CONNECT_TIMEOUT_SECONDS},
    )


def test_alembic_requires_database_url(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.delenv("MEMORA_DATABASE_URL", raising=False)
    # A developer .env must not make this negative test pass by accident.
    monkeypatch.setenv("MEMORA_ENV_FILE", str(tmp_path / "missing.env"))
    with pytest.raises(RuntimeError, match="MEMORA_DATABASE_URL is required"):
        command.current(Config(BACKEND_ROOT / "alembic.ini"))


def test_initial_migration_declares_every_contract_table() -> None:
    declared = {
        line.split()[2] for line in MIGRATION_SQL.splitlines() if line.startswith("CREATE TABLE ")
    }
    assert declared == EXPECTED_TABLES
    assert MIGRATION_SQL.count("vector(2048)") == 3
    assert "ENABLE ROW LEVEL SECURITY" in MIGRATION_SQL
    assert "memora_forbid_mutation" in MIGRATION_SQL


def test_upgrade_downgrade_upgrade_against_postgres(migration_database_url: str) -> None:
    config = alembic_config(migration_database_url)

    command.upgrade(config, "head")
    seed_database(migration_database_url)
    seed_database(migration_database_url)
    engine = create_test_engine(migration_database_url)
    with engine.connect() as connection:
        tables = set(
            connection.execute(
                text("SELECT tablename FROM pg_tables WHERE schemaname='public'")
            ).scalars()
        )
        assert tables >= EXPECTED_TABLES
        assert connection.scalar(text("SELECT count(*) FROM subjects WHERE code='physics'")) == 1
        assert (
            connection.scalar(
                text(
                    "SELECT count(*) FROM pg_policies "
                    "WHERE schemaname='public' AND tablename='learning_updates'"
                )
            )
            == 1
        )
    engine.dispose()

    command.downgrade(config, "base")
    command.upgrade(config, "head")


def test_rls_and_append_only_guards_against_postgres(migration_database_url: str) -> None:
    command.upgrade(alembic_config(migration_database_url), "head")

    engine = create_test_engine(migration_database_url)
    user_one = str(uuid4())
    user_two = str(uuid4())
    update_id = str(uuid4())
    with engine.begin() as connection:
        connection.execute(
            text(
                "INSERT INTO users(id,oidc_issuer,oidc_subject,status,default_timezone,locale) "
                "VALUES (:u1,'test','one','active','Asia/Colombo','en'),"
                "(:u2,'test','two','active','Asia/Colombo','en') ON CONFLICT DO NOTHING"
            ),
            {"u1": user_one, "u2": user_two},
        )
        connection.execute(text("SET LOCAL ROLE memora_api"))
        assert (
            str(
                connection.scalar(
                    text("SELECT memora_resolve_user_id(:issuer, :subject)"),
                    {"issuer": "test", "subject": "one"},
                )
            )
            == user_one
        )
        assert (
            connection.scalar(
                text("SELECT memora_resolve_user_id(:issuer, :subject)"),
                {"issuer": "test", "subject": "missing"},
            )
            is None
        )
        connection.execute(
            text("SELECT set_config('memora.user_id', :user_id, true)"), {"user_id": user_one}
        )
        connection.execute(
            INSERT_UPDATE_SQL,
            {"id": update_id, "user_id": user_one},
        )

    with engine.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_api"))
        connection.execute(
            text("SELECT set_config('memora.user_id', :user_id, true)"), {"user_id": user_two}
        )
        assert connection.scalar(text("SELECT count(*) FROM learning_updates")) == 0

    with pytest.raises(DBAPIError), engine.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_api"))
        connection.execute(
            text("SELECT set_config('memora.user_id', :user_id, true)"), {"user_id": user_two}
        )
        connection.execute(
            INSERT_UPDATE_SQL,
            {"id": str(uuid4()), "user_id": user_one},
        )

    with pytest.raises(DBAPIError), engine.begin() as connection:
        consent_id = connection.scalar(
            text(
                """
                INSERT INTO consent_records(
                    user_id, consent_type, policy_version, decision, decided_at, evidence
                ) VALUES (:user_id, 'privacy', '1', 'granted', now(), '{}')
                RETURNING id
                """
            ),
            {"user_id": user_one},
        )
        connection.execute(
            text("UPDATE consent_records SET decision='withdrawn' WHERE id=:id"),
            {"id": consent_id},
        )

    with pytest.raises(DBAPIError), engine.begin() as connection:
        connection.execute(
            text(
                """
                INSERT INTO users(oidc_issuer, oidc_subject, status, default_timezone, locale)
                VALUES ('test', 'invalid-status', 'unknown', 'Asia/Colombo', 'en')
                """
            )
        )

    with pytest.raises(DBAPIError), engine.begin() as connection:
        parent_id = connection.scalar(
            text(
                """
                INSERT INTO learning_objectives(
                    curriculum_version_id, objective_code, title, description,
                    sequence_no, status
                ) VALUES (
                    '20000000-0000-0000-0000-000000000001', 'cycle-parent',
                    'Parent', 'Synthetic cycle test', 1, 'draft'
                ) RETURNING id
                """
            )
        )
        child_id = connection.scalar(
            text(
                """
                INSERT INTO learning_objectives(
                    curriculum_version_id, objective_code, parent_objective_id,
                    title, description, sequence_no, status
                ) VALUES (
                    '20000000-0000-0000-0000-000000000001', 'cycle-child', :parent_id,
                    'Child', 'Synthetic cycle test', 2, 'draft'
                ) RETURNING id
                """
            ),
            {"parent_id": parent_id},
        )
        connection.execute(
            text("UPDATE learning_objectives SET parent_objective_id=:child WHERE id=:parent"),
            {"child": child_id, "parent": parent_id},
        )
    engine.dispose()


def test_device_registration_is_owner_scoped(migration_database_url: str) -> None:
    command.upgrade(alembic_config(migration_database_url), "head")
    engine = create_test_engine(migration_database_url)
    user_one = str(uuid4())
    user_two = str(uuid4())
    device_id = str(uuid4())
    installation_id = str(uuid4())

    with engine.begin() as connection:
        connection.execute(
            text(
                """
                INSERT INTO users(
                    id, oidc_issuer, oidc_subject, status, default_timezone, locale
                ) VALUES
                    (:u1, 'test', 'device-one', 'active', 'Asia/Colombo', 'en'),
                    (:u2, 'test', 'device-two', 'active', 'Asia/Colombo', 'en')
                """
            ),
            {"u1": user_one, "u2": user_two},
        )
        connection.execute(
            text(
                """
                INSERT INTO device_registrations(
                    id, user_id, installation_id, platform, app_version, last_seen_at
                ) VALUES (:id, :user_id, :installation_id, 'android', '1.0.0', now())
                """
            ),
            {"id": device_id, "user_id": user_one, "installation_id": installation_id},
        )

    with engine.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_api"))
        connection.execute(
            text("SELECT set_config('memora.user_id', :user_id, true)"),
            {"user_id": user_two},
        )
        assert connection.scalar(text("SELECT count(*) FROM device_registrations")) == 0
        updated = connection.execute(
            text(
                "UPDATE device_registrations SET revoked_at = now() "
                "WHERE id = :device_id RETURNING id"
            ),
            {"device_id": device_id},
        ).scalar()
        assert updated is None

    engine.dispose()


def test_identity_repository_bootstrap_idempotency_and_ownership(
    migration_database_url: str,
) -> None:
    command.upgrade(alembic_config(migration_database_url), "head")
    seed_database(migration_database_url)
    engine = create_test_engine(migration_database_url)
    repository = IdentityRepository(engine)
    now = datetime.now(UTC)

    def auth(subject: str) -> AuthContext:
        return AuthContext(
            issuer="https://synthetic.supabase.co/auth/v1",
            subject=subject,
            session_id=uuid4(),
            role="authenticated",
            authenticated_at=now,
            expires_at=now + timedelta(minutes=5),
        )

    user_one = auth(str(uuid4()))
    user_two = auth(str(uuid4()))
    bootstrap = repository.bootstrap(
        user_one,
        default_timezone="Asia/Colombo",
        default_locale="en-LK",
    )
    repository.bootstrap(
        user_two,
        default_timezone="Asia/Colombo",
        default_locale="en-LK",
    )
    assert bootstrap["account"]["status"] == "active"
    assert bootstrap["subjects"][0]["code"] == "physics"

    email_confirmation_context = AuthContext(
        issuer=user_one.issuer,
        subject=user_one.subject,
        session_id=uuid4(),
        role="authenticated",
        authenticated_at=None,
        expires_at=now + timedelta(minutes=5),
    )
    assert repository.consent_records(email_confirmation_context) == []

    consent_key = str(uuid4())
    consent = repository.accept_consent(
        user_one,
        idempotency_key=consent_key,
        policy_id="privacy",
        policy_version="privacy-v1",
        accepted_scopes=["privacy"],
        locale="en-LK",
    )
    replay = repository.accept_consent(
        user_one,
        idempotency_key=consent_key,
        policy_id="privacy",
        policy_version="privacy-v1",
        accepted_scopes=["privacy"],
        locale="en-LK",
    )
    assert replay["id"] == consent["id"]
    with pytest.raises(ApiError, match="idempotency_key_reused"):
        repository.accept_consent(
            user_one,
            idempotency_key=consent_key,
            policy_id="terms",
            policy_version="terms-v1",
            accepted_scopes=["terms"],
            locale="en-LK",
        )

    revoke_key = str(uuid4())
    assert not repository.claim_revocation(
        user_one,
        idempotency_key=revoke_key,
        scope="current",
    )
    assert not repository.claim_revocation(
        user_one,
        idempotency_key=revoke_key,
        scope="current",
    )
    with pytest.raises(ApiError, match="idempotency_key_reused"):
        repository.claim_revocation(
            user_one,
            idempotency_key=revoke_key,
            scope="all",
        )
    repository.complete_revocation(
        user_one,
        idempotency_key=revoke_key,
        scope="current",
        request_id=uuid4(),
        correlation_id=uuid4(),
    )
    repository.complete_revocation(
        user_one,
        idempotency_key=revoke_key,
        scope="current",
        request_id=uuid4(),
        correlation_id=uuid4(),
    )
    assert repository.claim_revocation(
        user_one,
        idempotency_key=revoke_key,
        scope="current",
    )
    with engine.connect() as connection:
        assert (
            connection.scalar(
                text(
                    "SELECT count(*) FROM audit_events "
                    "WHERE action='session.revoke' AND actor_id=:actor_id"
                ),
                {"actor_id": str(bootstrap["user_id"])},
            )
            == 1
        )

    device_id = repository.register_device(
        user_one,
        idempotency_key=str(uuid4()),
        body_hash="synthetic-device-body",
        installation_id=uuid4(),
        platform="android",
        ciphertext=b"synthetic-ciphertext",
        fingerprint="synthetic-fingerprint",
        locale="en-LK",
        timezone="Asia/Colombo",
        app_version="1.0.0",
    )[0]["id"]
    repository.delete_device(user_two, UUID(str(device_id)))
    with engine.connect() as connection:
        assert connection.scalar(
            text("SELECT revoked_at IS NULL FROM device_registrations WHERE id=:id"),
            {"id": device_id},
        )
    repository.delete_device(user_one, UUID(str(device_id)))
    with engine.connect() as connection:
        assert connection.scalar(
            text(
                "SELECT revoked_at IS NOT NULL AND push_token_ciphertext IS NULL "
                "FROM device_registrations WHERE id=:id"
            ),
            {"id": device_id},
        )

    engine.dispose()


def test_role_grants_rls_coverage_and_status_checks_against_postgres(
    migration_database_url: str,
) -> None:
    command.upgrade(alembic_config(migration_database_url), "head")
    engine = create_test_engine(migration_database_url)
    with engine.connect() as connection:
        assert connection.scalar(
            text(
                "SELECT am.set_option FROM pg_auth_members am "
                "JOIN pg_roles role ON role.oid=am.roleid "
                "JOIN pg_roles member ON member.oid=am.member "
                "WHERE role.rolname='memora_api' AND member.rolname=current_user"
            )
        )
        assert connection.scalar(
            text("SELECT has_table_privilege('memora_api', 'subjects', 'SELECT')")
        )
        assert not connection.scalar(
            text("SELECT has_table_privilege('memora_api', 'subjects', 'INSERT')")
        )
        assert not connection.scalar(
            text("SELECT has_table_privilege('memora_api', 'outbox_events', 'SELECT')")
        )
        assert connection.scalar(
            text("SELECT has_table_privilege('memora_api', 'outbox_events', 'INSERT')")
        )
        assert not connection.scalar(
            text("SELECT has_table_privilege('memora_worker', 'users', 'SELECT')")
        )
        assert not connection.scalar(
            text("SELECT has_table_privilege('memora_worker', 'learning_updates', 'SELECT')")
        )
        assert not connection.scalar(
            text("SELECT has_table_privilege('memora_worker', 'learning_updates', 'UPDATE')")
        )
        assert connection.scalar(
            text(
                "SELECT has_function_privilege("
                "'memora_api', 'memora_resolve_user_id(text,text)', 'EXECUTE'"
                ")"
            )
        )
        assert connection.scalar(
            text(
                "SELECT has_function_privilege("
                "'memora_api', 'memora_transfer_device_token(text)', 'EXECUTE'"
                ")"
            )
        )
        assert not connection.scalar(
            text(
                "SELECT has_function_privilege("
                "'memora_worker', 'memora_resolve_user_id(text,text)', 'EXECUTE'"
                ")"
            )
        )

        protected_tables = set(
            connection.execute(
                text(
                    "SELECT c.relname FROM pg_class c "
                    "JOIN pg_namespace n ON n.oid=c.relnamespace "
                    "WHERE n.nspname='public' AND c.relrowsecurity AND c.relforcerowsecurity"
                )
            ).scalars()
        )
        assert protected_tables >= OWNER_RLS_TABLES

        for table_name, expected_values in STATUS_VALUES.items():
            definitions = " ".join(
                connection.execute(
                    text(
                        "SELECT pg_get_constraintdef(c.oid) FROM pg_constraint c "
                        "JOIN pg_class t ON t.oid=c.conrelid "
                        "JOIN pg_namespace n ON n.oid=t.relnamespace "
                        "WHERE n.nspname='public' AND t.relname=:table_name AND c.contype='c'"
                    ),
                    {"table_name": table_name},
                ).scalars()
            )
            assert all(f"'{value}'" in definitions for value in expected_values), table_name

        connection.execute(text("SET LOCAL ROLE memora_api"))
        assert connection.scalar(text("SELECT count(*) FROM subjects WHERE status='draft'")) == 0
        assert connection.scalar(text("SELECT count(*) FROM subjects WHERE status='approved'")) == 1

    with pytest.raises(DBAPIError), engine.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_worker"))
        connection.execute(
            text("SELECT set_config('memora.user_id', gen_random_uuid()::text, true)")
        )
        connection.execute(text("SELECT count(*) FROM learning_updates"))
    engine.dispose()


def test_worker_can_publish_outbox_and_use_service_idempotency(
    migration_database_url: str,
) -> None:
    command.upgrade(alembic_config(migration_database_url), "head")
    engine = create_test_engine(migration_database_url)
    event_id = str(uuid4())
    event_key = str(uuid4())
    service_key = str(uuid4())

    with pytest.raises(DBAPIError), engine.begin() as connection:
        connection.execute(
            text(
                "INSERT INTO outbox_events("
                "domain_event_key, aggregate_type, aggregate_id, event_type, "
                "event_version, payload, correlation_id, publication_status"
                ") VALUES ("
                ":event_key, 'mission', gen_random_uuid(), 'completed', "
                "1, '{\"schema_version\":\"1\"}', gen_random_uuid(), 'published'"
                ")"
            ),
            {"event_key": str(uuid4())},
        )

    with pytest.raises(DBAPIError), engine.begin() as connection:
        connection.execute(
            text(
                "INSERT INTO outbox_events("
                "domain_event_key, aggregate_type, aggregate_id, event_type, "
                "event_version, payload, correlation_id, publication_status, published_at"
                ") VALUES ("
                ":event_key, 'mission', gen_random_uuid(), 'completed', "
                "1, '{\"schema_version\":\"1\"}', gen_random_uuid(), 'pending', now()"
                ")"
            ),
            {"event_key": str(uuid4())},
        )

    with engine.begin() as connection:
        connection.execute(
            text(
                "INSERT INTO outbox_events("
                "id, domain_event_key, aggregate_type, aggregate_id, event_type, "
                "event_version, payload, correlation_id, publication_status"
                ") VALUES ("
                ":id, :event_key, 'mission', gen_random_uuid(), 'completed', "
                "1, '{\"schema_version\":\"1\"}', gen_random_uuid(), 'pending'"
                ")"
            ),
            {"id": event_id, "event_key": event_key},
        )
        connection.execute(text("SET LOCAL ROLE memora_worker"))
        connection.execute(
            text(
                "UPDATE outbox_events SET publication_status='published', published_at=now() "
                "WHERE id=:id"
            ),
            {"id": event_id},
        )
        connection.execute(
            text(
                "INSERT INTO idempotency_records("
                "scope, operation, idempotency_key, request_hash, status, expires_at"
                ") VALUES ("
                "'worker', 'publish', :key, 'hash', 'processing', now() + interval '1 day'"
                ")"
            ),
            {"key": service_key},
        )
        assert (
            connection.scalar(
                text(
                    "SELECT count(*) FROM idempotency_records "
                    "WHERE user_id IS NULL AND idempotency_key=:key"
                ),
                {"key": service_key},
            )
            == 1
        )

    with pytest.raises(DBAPIError), engine.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_worker"))
        connection.execute(
            text("UPDATE outbox_events SET payload=CAST(:payload AS jsonb) WHERE id=:id"),
            {"id": event_id, "payload": '{"changed":true}'},
        )

    with pytest.raises(DBAPIError), engine.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_worker"))
        connection.execute(text("DELETE FROM outbox_events WHERE id=:id"), {"id": event_id})

    engine.dispose()


def test_grading_authority_can_move_without_rewriting_evidence(
    migration_database_url: str,
) -> None:
    command.upgrade(alembic_config(migration_database_url), "head")
    engine = create_test_engine(migration_database_url)

    with engine.begin() as connection:
        fixture = (
            connection.execute(
                text(
                    """
                WITH new_user AS (
                  INSERT INTO users(
                    oidc_issuer, oidc_subject, status, default_timezone, locale
                  ) VALUES ('test', gen_random_uuid()::text, 'active', 'Asia/Colombo', 'en')
                  RETURNING id
                ), new_concept AS (
                  INSERT INTO concepts(subject_id, stable_code, status)
                  VALUES (
                    '10000000-0000-0000-0000-000000000001', gen_random_uuid()::text, 'draft'
                  ) RETURNING id
                ), new_question AS (
                  INSERT INTO questions(
                    subject_id, question_code, source_class, status
                  ) VALUES (
                    '10000000-0000-0000-0000-000000000001', gen_random_uuid()::text,
                    'expert_verified', 'draft'
                  ) RETURNING id
                ), new_question_version AS (
                  INSERT INTO question_versions(
                    question_id, version_no, question_type, prompt, explanation,
                    content_payload, trust_label, curriculum_version_id, validation_status
                  ) SELECT id, 1, 'mcq', 'Synthetic?', 'Synthetic.',
                    '{"schema_version":"1"}', 'verified',
                    '20000000-0000-0000-0000-000000000001', 'draft'
                  FROM new_question RETURNING id
                ), new_rubric AS (
                  INSERT INTO question_rubrics(
                    question_version_id, rubric_type, rubric_version, rubric_payload,
                    max_score, evidence_ceiling, status
                  ) SELECT id, 'exact', 1, '{"schema_version":"1"}', 1, 1, 'draft'
                  FROM new_question_version RETURNING id
                )
                SELECT u.id AS user_id, c.id AS concept_id,
                       qv.id AS question_version_id, r.id AS rubric_id
                FROM new_user u, new_concept c, new_question_version qv, new_rubric r
                """
                )
            )
            .mappings()
            .one()
        )
        attempt = (
            connection.execute(
                text(
                    """
                WITH new_mission AS (
                  INSERT INTO missions(
                    user_id, subject_id, mission_date, mission_timezone, status,
                    engine_version, candidate_snapshot_hash, estimated_minutes,
                    planned_item_count, expires_at
                  ) VALUES (
                    :user_id, '10000000-0000-0000-0000-000000000001', CURRENT_DATE,
                    'Asia/Colombo', 'started', 'test', gen_random_uuid()::text, 1, 1,
                    now() + interval '1 day'
                  ) RETURNING id, user_id
                ), new_item AS (
                  INSERT INTO mission_items(
                    mission_id, user_id, position, mission_type, question_version_id,
                    primary_concept_id, selection_reason_codes, priority_snapshot, status
                  ) SELECT m.id, m.user_id, 0, 'protect', :question_version_id, :concept_id,
                    ARRAY['test'], '{"schema_version":"1"}', 'answered'
                  FROM new_mission m
                  RETURNING id, user_id
                ), new_attempt AS (
                  INSERT INTO attempts(
                    user_id, mission_item_id, attempt_no, client_operation_id,
                    answer_payload, submitted_at, app_version
                  ) SELECT user_id, id, 1, gen_random_uuid(), '{"schema_version":"1"}',
                    now(), 'test'
                  FROM new_item RETURNING id
                )
                SELECT id AS attempt_id FROM new_attempt
                """
                ),
                fixture,
            )
            .mappings()
            .one()
        )
        fixture = {**fixture, **attempt}
        first_result_id = connection.scalar(
            text(
                """
                INSERT INTO grading_results(
                  attempt_id, result_version, grader_type, score, classification,
                  confidence, rubric_id, grader_version, evidence_payload,
                  is_authoritative, graded_at
                ) VALUES (
                  :attempt_id, 1, 'exact', 1, 'correct', 1, :rubric_id, 'test',
                  '{"schema_version":"1"}', true, now()
                ) RETURNING id
                """
            ),
            fixture,
        )
        connection.execute(
            text("UPDATE grading_results SET is_authoritative=false WHERE id=:result_id"),
            {"result_id": first_result_id},
        )
        second_result_id = connection.scalar(
            text(
                """
                INSERT INTO grading_results(
                  attempt_id, result_version, grader_type, score, classification,
                  confidence, rubric_id, grader_version, evidence_payload,
                  is_authoritative, graded_at
                ) VALUES (
                  :attempt_id, 2, 'human_review', 0.5, 'partial', 1, :rubric_id, 'test',
                  '{"schema_version":"1"}', true, now()
                ) RETURNING id
                """
            ),
            fixture,
        )
        assert (
            connection.scalar(
                text(
                    "SELECT count(*) FROM grading_results "
                    "WHERE attempt_id=:attempt_id AND is_authoritative"
                ),
                fixture,
            )
            == 1
        )

    with pytest.raises(DBAPIError), engine.begin() as connection:
        connection.execute(
            text("UPDATE grading_results SET score=0 WHERE id=:result_id"),
            {"result_id": second_result_id},
        )

    with pytest.raises(DBAPIError), engine.begin() as connection:
        connection.execute(
            text("DELETE FROM grading_results WHERE id=:result_id"),
            {"result_id": first_result_id},
        )

    engine.dispose()


def test_ingestion_operations_migration_grants_and_indexes(
    migration_database_url: str,
) -> None:
    command.upgrade(alembic_config(migration_database_url), "head")
    engine = create_test_engine(migration_database_url)
    with engine.connect() as connection:
        # Worker table privileges
        assert connection.scalar(
            text("SELECT has_table_privilege('memora_worker', 'source_uploads', 'SELECT')")
        )
        assert connection.scalar(
            text("SELECT has_table_privilege('memora_worker', 'source_uploads', 'UPDATE')")
        )
        assert connection.scalar(
            text("SELECT has_table_privilege('memora_worker', 'extraction_candidates', 'INSERT')")
        )
        assert connection.scalar(
            text("SELECT has_table_privilege('memora_worker', 'verification_requests', 'INSERT')")
        )
        assert connection.scalar(
            text("SELECT has_table_privilege('memora_worker', 'deletion_proofs', 'INSERT')")
        )
        assert connection.scalar(
            text("SELECT has_table_privilege('memora_worker', 'privacy_requests', 'SELECT')")
        )
        assert not connection.scalar(
            text("SELECT has_table_privilege('memora_worker', 'learning_updates', 'SELECT')")
        )
        assert not connection.scalar(
            text("SELECT has_table_privilege('memora_worker', 'learning_updates', 'UPDATE')")
        )

        # API background_jobs privileges
        assert connection.scalar(
            text("SELECT has_table_privilege('memora_api', 'background_jobs', 'INSERT')")
        )
        assert connection.scalar(
            text("SELECT has_table_privilege('memora_api', 'background_jobs', 'UPDATE')")
        )

        # Worker security-definer function privileges
        assert connection.scalar(
            text(
                "SELECT has_function_privilege("
                "'memora_worker', 'memora_ingestion_context(uuid,uuid)', 'EXECUTE'"
                ")"
            )
        )
        assert connection.scalar(
            text(
                "SELECT has_function_privilege("
                "'memora_worker', 'memora_ingestion_mark_update(uuid,uuid,text,text)', 'EXECUTE'"
                ")"
            )
        )
        assert connection.scalar(
            text(
                "SELECT has_function_privilege("
                "'memora_worker', 'memora_expire_ingestion(timestamptz)', 'EXECUTE'"
                ")"
            )
        )
        assert not connection.scalar(
            text(
                "SELECT has_function_privilege("
                "'public', 'memora_ingestion_context(uuid,uuid)', 'EXECUTE'"
                ")"
            )
        )
        assert not connection.scalar(
            text(
                "SELECT has_function_privilege("
                "'public', 'memora_ingestion_mark_update(uuid,uuid,text,text)', 'EXECUTE'"
                ")"
            )
        )
        assert not connection.scalar(
            text(
                "SELECT has_function_privilege("
                "'public', 'memora_expire_ingestion(timestamptz)', 'EXECUTE'"
                ")"
            )
        )

        # Indexes created by migration 0005
        indexes = set(
            connection.execute(
                text("SELECT indexname FROM pg_indexes WHERE schemaname = 'public'")
            ).scalars()
        )
        assert {
            "ix_learning_updates_owner_updated",
            "ix_source_uploads_update",
            "ix_extraction_candidates_expiry",
            "ix_verification_requests_update",
            "ix_knowledge_commits_owner",
            "uq_deletion_proofs_source_scope",
        } <= indexes

    # Verify uq_deletion_proofs_source_scope guard
    with engine.begin() as connection:
        user_id = connection.scalar(
            text(
                "INSERT INTO users(oidc_issuer, oidc_subject, default_timezone, locale, status) "
                "VALUES ('test-iss-proof', 'test-sub-proof', 'Asia/Colombo', 'en-LK', 'active') "
                "RETURNING id"
            )
        )
        update_id = uuid4()
        connection.execute(
            INSERT_UPDATE_SQL,
            {"id": update_id, "user_id": user_id},
        )
        upload_id = connection.scalar(
            text(
                "INSERT INTO source_uploads(learning_update_id, user_id, object_key, "
                "declared_name, declared_media_type, byte_size, status, expires_at) "
                "VALUES (:update_id, :user_id, 'proof-test-key', 'test.pdf', "
                "'application/pdf', 100, 'uploaded', now() + interval '1 day') "
                "RETURNING id"
            ),
            {"update_id": update_id, "user_id": user_id},
        )
        connection.execute(
            text(
                "INSERT INTO deletion_proofs("
                "source_upload_id, scope, provider, target_fingerprint, "
                "result, verified_at, reconciler_version"
                ") VALUES ("
                ":upload_id, 'temporary_raw', 's3', 'sha256-fingerprint', "
                "'deleted', now(), 'v1'"
                ")"
            ),
            {"upload_id": upload_id},
        )

    # Duplicate deletion proof with same source_upload_id, scope, and provider must fail
    with pytest.raises(DBAPIError), engine.begin() as connection:
        connection.execute(
            text(
                "INSERT INTO deletion_proofs("
                "source_upload_id, scope, provider, target_fingerprint, "
                "result, verified_at, reconciler_version"
                ") VALUES ("
                ":upload_id, 'temporary_raw', 's3', 'sha256-fingerprint', "
                "'deleted', now(), 'v1'"
                ")"
            ),
            {"upload_id": upload_id},
        )

    engine.dispose()


def test_engagement_migration_contract(migration_database_url: str) -> None:
    command.upgrade(alembic_config(migration_database_url), "head")
    engine = create_test_engine(migration_database_url)
    with engine.connect() as connection:
        columns = {
            (row["table_name"], row["column_name"])
            for row in connection.execute(
                text(
                    """
                    SELECT table_name,column_name FROM information_schema.columns
                    WHERE table_schema='public'
                      AND ((table_name='xp_ledger' AND column_name='policy_version')
                        OR (table_name='streak_days' AND column_name='policy_version')
                        OR table_name='reward_placements')
                    """
                )
            ).mappings()
        }
        assert ("xp_ledger", "policy_version") in columns
        assert ("streak_days", "policy_version") in columns
        assert {
            ("reward_placements", "reward_grant_id"),
            ("reward_placements", "user_id"),
            ("reward_placements", "subject_id"),
            ("reward_placements", "placement_slot"),
            ("reward_placements", "row_version"),
        } <= columns
        assert connection.scalar(
            text(
                """
                SELECT relrowsecurity AND relforcerowsecurity
                FROM pg_class WHERE oid='reward_placements'::regclass
                """
            )
        )
        assert (
            connection.scalar(
                text(
                    """
                SELECT count(*) FROM pg_policies
                WHERE schemaname='public' AND tablename='reward_placements'
                  AND policyname='reward_placements_owner'
                """
                )
            )
            == 1
        )
        assert connection.scalar(
            text(
                "SELECT has_table_privilege("
                "'memora_api','reward_placements','SELECT,INSERT,UPDATE,DELETE')"
            )
        )
        assert not connection.scalar(
            text("SELECT has_table_privilege('memora_worker','reward_placements','SELECT')")
        )
        index_definition = connection.scalar(
            text(
                """
                SELECT indexdef FROM pg_indexes
                WHERE schemaname='public' AND indexname='ix_xp_ledger_balance'
                """
            )
        )
        assert "created_at DESC" in index_definition
    engine.dispose()
