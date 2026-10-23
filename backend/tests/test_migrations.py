import os
from pathlib import Path
from uuid import uuid4

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, text
from sqlalchemy.exc import DBAPIError

from memora.db.seed import seed_database

BACKEND_ROOT = Path(__file__).parents[1]
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


def test_initial_migration_declares_every_contract_table() -> None:
    declared = {
        line.split()[2] for line in MIGRATION_SQL.splitlines() if line.startswith("CREATE TABLE ")
    }
    assert declared == EXPECTED_TABLES
    assert MIGRATION_SQL.count("vector(2048)") == 3
    assert "ENABLE ROW LEVEL SECURITY" in MIGRATION_SQL
    assert "memora_forbid_mutation" in MIGRATION_SQL


def test_upgrade_downgrade_upgrade_against_postgres() -> None:
    database_url = os.getenv("MEMORA_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("MEMORA_TEST_DATABASE_URL is not configured")

    config = alembic_config(database_url)
    os.environ["MEMORA_DATABASE_URL"] = database_url

    command.upgrade(config, "head")
    seed_database(database_url)
    seed_database(database_url)
    engine = create_engine(database_url)
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


def test_rls_and_append_only_guards_against_postgres() -> None:
    database_url = os.getenv("MEMORA_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("MEMORA_TEST_DATABASE_URL is not configured")

    os.environ["MEMORA_DATABASE_URL"] = database_url
    command.upgrade(alembic_config(database_url), "head")

    engine = create_engine(database_url)
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


def test_role_grants_rls_coverage_and_status_checks_against_postgres() -> None:
    database_url = os.getenv("MEMORA_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("MEMORA_TEST_DATABASE_URL is not configured")

    os.environ["MEMORA_DATABASE_URL"] = database_url
    command.upgrade(alembic_config(database_url), "head")
    engine = create_engine(database_url)
    with engine.connect() as connection:
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
    engine.dispose()
