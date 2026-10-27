"""PostgreSQL contracts for question import, immutability, authorization and reports."""

from __future__ import annotations

import base64
import os
from collections.abc import Iterator
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from pathlib import Path
from typing import Any
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
from memora.api.v1.schemas.question_reports import QuestionReportCreateRequest
from memora.core.config import Settings
from memora.db.seed import seed_database
from memora.modules.questions.models import QuestionImportBundle
from memora.modules.questions.repository import (
    QuestionImportRepository,
    QuestionReportRepository,
)
from memora.modules.questions.service import QuestionService
from memora.modules.questions.validation import (
    QuestionValidationError,
    validate_question_import,
)

BACKEND_ROOT = Path(__file__).parents[1]
DISPOSABLE_DATABASE_SUFFIXES = ("_test", "_ci")
ISSUER = "https://question-db-contracts.test"
SUBJECT_ID = UUID("10000000-0000-0000-0000-000000000001")
CURRICULUM_ID = UUID("20000000-0000-0000-0000-000000000001")
CONCEPT_VERSION_ID = UUID("50000000-0000-0000-0000-000000000001")
AUTHOR_ID = UUID("40000000-0000-0000-0000-000000000011")
REVIEWER_ID = UUID("40000000-0000-0000-0000-000000000012")


def alembic_config(database_url: str) -> Config:
    config = Config(BACKEND_ROOT / "alembic.ini")
    config.set_main_option("script_location", str(BACKEND_ROOT / "migrations"))
    config.set_main_option("sqlalchemy.url", database_url.replace("%", "%%"))
    return config


@pytest.fixture
def database(monkeypatch: pytest.MonkeyPatch) -> Iterator[Engine]:
    """Use only a disposable database and move it to the reviewable schema head."""

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


def auth_context(subject: str) -> AuthContext:
    now = datetime.now(UTC)
    return AuthContext(
        issuer=ISSUER,
        subject=subject,
        session_id=uuid4(),
        role="authenticated",
        authenticated_at=now,
        expires_at=now + timedelta(minutes=5),
    )


def authenticated_request(subject: str) -> AuthenticatedRequest:
    return AuthenticatedRequest(
        context=auth_context(subject),
        access_token=SecretStr("synthetic-access-token"),
    )


def create_user(engine: Engine, subject: str | None = None) -> tuple[UUID, str]:
    resolved_subject = subject or f"synthetic-{uuid4()}"
    with engine.begin() as connection:
        user_id = connection.scalar(
            text(
                """
                INSERT INTO users(
                    oidc_issuer, oidc_subject, status, default_timezone, locale
                ) VALUES (:issuer, :subject, 'active', 'Asia/Colombo', 'en')
                RETURNING id
                """
            ),
            {"issuer": ISSUER, "subject": resolved_subject},
        )
    return UUID(str(user_id)), resolved_subject


def question_bundle(
    *,
    question_code: str | None = None,
    prompt: str = "Which quantity is a vector?",
    validation_status: str = "approved",
) -> QuestionImportBundle:
    return QuestionImportBundle.model_validate(
        {
            "question_code": question_code or f"synthetic-{uuid4().hex[:12]}",
            "subject_id": SUBJECT_ID,
            "curriculum_version_id": CURRICULUM_ID,
            "source_class": "expert_verified",
            "question_type": "mcq",
            "prompt": prompt,
            "explanation": "Velocity has magnitude and direction.",
            "validation_status": validation_status,
            "author_principal": AUTHOR_ID,
            "reviewer_principal": REVIEWER_ID,
            "content": {"schema_version": "1", "selection_mode": "single"},
            "options": [
                {
                    "option_key": "a",
                    "display_text": "Speed",
                    "is_correct": False,
                    "explanation": "Speed is a scalar.",
                    "display_order": 0,
                },
                {
                    "option_key": "b",
                    "display_text": "Velocity",
                    "is_correct": True,
                    "explanation": "Velocity is a vector.",
                    "display_order": 1,
                },
            ],
            "rubric": {
                "rubric_type": "exact",
                "max_score": Decimal("1"),
                "evidence_ceiling": Decimal("1"),
                "status": "approved",
                "payload": {"schema_version": "1"},
            },
            "concept_mappings": [
                {
                    "concept_version_id": CONCEPT_VERSION_ID,
                    "mapping_role": "primary",
                    "weight": Decimal("1"),
                    "provenance_type": "review",
                    "provenance_ref": "synthetic-review",
                }
            ],
        }
    )


def import_question(engine: Engine, bundle: QuestionImportBundle) -> dict[str, Any]:
    return QuestionImportRepository(engine).import_question(validate_question_import(bundle))


def generated_question_bundle(
    *,
    grounding_evidence_ids: list[UUID],
    question_code: str | None = None,
) -> QuestionImportBundle:
    payload = question_bundle(question_code=question_code).model_dump()
    payload.update(
        {
            "source_class": "ai_generated",
            "trust_label": "AI generated",
            "model_key": "synthetic-model",
            "prompt_version": "synthetic-prompt-v1",
            "grounding_evidence_ids": list(grounding_evidence_ids),
            "validator_version": "synthetic-validator-v1",
            "validation_score": Decimal("0.9"),
            "generation_trace_ref": "synthetic-trace",
        }
    )
    payload["rubric"] = {
        **payload["rubric"],
        "evidence_ceiling": Decimal("0.9"),
    }
    return QuestionImportBundle.model_validate(payload)


def create_subject(engine: Engine, *, status: str = "approved") -> UUID:
    subject_id = uuid4()
    with engine.begin() as connection:
        connection.execute(
            text(
                """
                INSERT INTO subjects(id, code, name, status)
                VALUES (:id, :code, 'Synthetic subject', :status)
                """
            ),
            {"id": subject_id, "code": f"synthetic-{uuid4().hex[:12]}", "status": status},
        )
    return subject_id


def create_curriculum(
    engine: Engine,
    *,
    subject_id: UUID,
    status: str = "approved",
) -> UUID:
    curriculum_id = uuid4()
    with engine.begin() as connection:
        connection.execute(
            text(
                """
                INSERT INTO curriculum_versions(
                    id, subject_id, authority, edition_code, language_medium, status
                ) VALUES (
                    :id, :subject_id, 'Synthetic authority', :edition_code, 'en', :status
                )
                """
            ),
            {
                "id": curriculum_id,
                "subject_id": subject_id,
                "edition_code": f"SYNTHETIC-{uuid4().hex[:12]}",
                "status": status,
            },
        )
    return curriculum_id


def create_objective(
    engine: Engine,
    *,
    curriculum_id: UUID,
    status: str = "approved",
) -> UUID:
    objective_id = uuid4()
    with engine.begin() as connection:
        connection.execute(
            text(
                """
                INSERT INTO learning_objectives(
                    id, curriculum_version_id, objective_code, title, description,
                    sequence_no, status
                ) VALUES (
                    :id, :curriculum_id, :objective_code, 'Synthetic objective',
                    'Synthetic objective description.', 90, :status
                )
                """
            ),
            {
                "id": objective_id,
                "curriculum_id": curriculum_id,
                "objective_code": f"LO-SYN-{uuid4().hex[:12]}",
                "status": status,
            },
        )
    return objective_id


def create_concept_version(
    engine: Engine,
    *,
    subject_id: UUID,
    concept_status: str = "approved",
    content_status: str = "approved",
) -> UUID:
    concept_id = uuid4()
    version_id = uuid4()
    with engine.begin() as connection:
        connection.execute(
            text(
                """
                INSERT INTO concepts(id, subject_id, stable_code, status)
                VALUES (:id, :subject_id, :stable_code, :status)
                """
            ),
            {
                "id": concept_id,
                "subject_id": subject_id,
                "stable_code": f"SYN-{uuid4().hex[:12]}",
                "status": concept_status,
            },
        )
        connection.execute(
            text(
                """
                INSERT INTO concept_versions(
                    id, concept_id, version_no, kind, title, definition,
                    content_status, reviewed_at
                ) VALUES (
                    :id, :concept_id, 1, 'concept', 'Synthetic concept',
                    'Synthetic concept definition.', :content_status, now()
                )
                """
            ),
            {
                "id": version_id,
                "concept_id": concept_id,
                "content_status": content_status,
            },
        )
    return version_id


def create_claim(
    engine: Engine,
    *,
    concept_version_id: UUID,
    status: str = "approved",
) -> UUID:
    claim_id = uuid4()
    with engine.begin() as connection:
        connection.execute(
            text(
                """
                INSERT INTO knowledge_claims(
                    id, claim_group_id, concept_version_id, version_no, claim_type,
                    statement, status, provenance_type, provenance_ref, reviewed_at
                ) VALUES (
                    :id, :group_id, :concept_version_id, 1, 'definition',
                    'Synthetic claim statement.', :status, 'synthetic', 'synthetic', now()
                )
                """
            ),
            {
                "id": claim_id,
                "group_id": uuid4(),
                "concept_version_id": concept_version_id,
                "status": status,
            },
        )
    return claim_id


def map_concept_to_objective(
    engine: Engine,
    *,
    concept_version_id: UUID,
    objective_id: UUID,
) -> None:
    with engine.begin() as connection:
        connection.execute(
            text(
                """
                INSERT INTO concept_objective_maps(
                    concept_version_id, learning_objective_id, mapping_type,
                    coverage_weight, provenance_type, provenance_ref
                ) VALUES (
                    :concept_version_id, :objective_id, 'primary', 1,
                    'synthetic', 'synthetic'
                )
                """
            ),
            {"concept_version_id": concept_version_id, "objective_id": objective_id},
        )


def _encryption_key() -> str:
    return base64.b64encode(b"q" * 32).decode("ascii")


def concept_id(engine: Engine) -> UUID:
    with engine.connect() as connection:
        resolved = connection.scalar(
            text("SELECT concept_id FROM concept_versions WHERE id = :id"),
            {"id": CONCEPT_VERSION_ID},
        )
    assert resolved is not None
    return UUID(str(resolved))


def create_mission_attempt(
    engine: Engine,
    *,
    user_id: UUID,
    question_version_id: UUID,
    position: int = 0,
) -> tuple[UUID, UUID]:
    with engine.begin() as connection:
        mission_id = connection.scalar(
            text(
                """
                INSERT INTO missions(
                    user_id, subject_id, mission_date, mission_timezone, status,
                    engine_version, candidate_snapshot_hash, estimated_minutes,
                    planned_item_count, expires_at
                ) VALUES (
                    :user_id, :subject_id, CURRENT_DATE, 'Asia/Colombo', 'started',
                    'test', :snapshot_hash, 1, 1, now() + interval '1 day'
                ) RETURNING id
                """
            ),
            {
                "user_id": user_id,
                "subject_id": SUBJECT_ID,
                "snapshot_hash": uuid4().hex,
            },
        )
        item_id = connection.scalar(
            text(
                """
                INSERT INTO mission_items(
                    mission_id, user_id, position, mission_type, question_version_id,
                    primary_concept_id, selection_reason_codes, priority_snapshot, status
                ) VALUES (
                    :mission_id, :user_id, :position, 'protect', :question_version_id,
                    :concept_id, ARRAY['synthetic'], '{"schema_version":"1"}', 'answered'
                ) RETURNING id
                """
            ),
            {
                "mission_id": mission_id,
                "user_id": user_id,
                "position": position,
                "question_version_id": question_version_id,
                "concept_id": concept_id(engine),
            },
        )
        attempt_id = connection.scalar(
            text(
                """
                INSERT INTO attempts(
                    user_id, mission_item_id, attempt_no, client_operation_id,
                    answer_payload, submitted_at, app_version
                ) VALUES (
                    :user_id, :mission_item_id, 1, :client_operation_id,
                    '{"type":"single_choice","option_keys":["b"]}', now(), 'test'
                ) RETURNING id
                """
            ),
            {
                "user_id": user_id,
                "mission_item_id": item_id,
                "client_operation_id": uuid4(),
            },
        )
    return UUID(str(attempt_id)), UUID(str(item_id))


def test_import_is_idempotent_and_versions_are_immutable(database: Engine) -> None:
    question_code = f"synthetic-{uuid4().hex[:12]}"
    first = import_question(database, question_bundle(question_code=question_code))
    replay = import_question(database, question_bundle(question_code=question_code))

    assert first["created"] is True
    assert first["version_no"] == 1
    assert replay["created"] is False
    assert replay["question_version_id"] == first["question_version_id"]

    second = import_question(
        database,
        question_bundle(
            question_code=question_code,
            prompt="Which quantity has both magnitude and direction?",
        ),
    )
    assert second["created"] is True
    assert second["version_no"] == 2
    assert second["question_version_id"] != first["question_version_id"]

    with database.connect() as connection:
        versions = (
            connection.execute(
                text(
                    """
                    SELECT version_no, prompt, validation_status
                    FROM question_versions
                    WHERE question_id = :question_id
                    ORDER BY version_no
                    """
                ),
                {"question_id": first["question_id"]},
            )
            .mappings()
            .all()
        )
    assert [row["version_no"] for row in versions] == [1, 2]
    assert versions[0]["prompt"] == "Which quantity is a vector?"
    assert versions[0]["validation_status"] == "approved"
    assert versions[1]["validation_status"] == "approved"

    version_id = first["question_version_id"]
    prohibited = [
        (
            "UPDATE question_versions SET prompt = 'Changed?' WHERE id = :version_id",
            {"version_id": version_id},
        ),
        (
            "DELETE FROM question_versions WHERE id = :version_id",
            {"version_id": version_id},
        ),
        (
            "INSERT INTO question_options("
            "question_version_id, option_key, display_text, is_correct, explanation, display_order"
            ") VALUES (:version_id, 'c', 'Acceleration', false, 'Synthetic.', 2)",
            {"version_id": version_id},
        ),
        (
            "UPDATE question_options SET display_text = 'Changed' "
            "WHERE question_version_id = :version_id AND option_key = 'a'",
            {"version_id": version_id},
        ),
        (
            "DELETE FROM question_rubrics WHERE question_version_id = :version_id",
            {"version_id": version_id},
        ),
        (
            "UPDATE question_concept_maps SET weight = 0.5 WHERE question_version_id = :version_id",
            {"version_id": version_id},
        ),
        (
            "UPDATE questions SET question_code = 'changed.code' WHERE id = :question_id",
            {"question_id": first["question_id"]},
        ),
        (
            "DELETE FROM questions WHERE id = :question_id",
            {"question_id": first["question_id"]},
        ),
    ]
    for statement, parameters in prohibited:
        with pytest.raises(DBAPIError), database.begin() as connection:
            connection.execute(text(statement), parameters)


def test_publication_guard_validates_the_complete_content_set(database: Engine) -> None:
    with database.begin() as connection:
        question_id = connection.scalar(
            text(
                """
                INSERT INTO questions(subject_id, question_code, source_class, status,
                                      author_principal)
                VALUES (:subject_id, :question_code, 'expert_verified', 'approved', :author)
                RETURNING id
                """
            ),
            {
                "subject_id": SUBJECT_ID,
                "question_code": f"synthetic-{uuid4().hex[:12]}",
                "author": AUTHOR_ID,
            },
        )
        version_id = connection.scalar(
            text(
                """
                INSERT INTO question_versions(
                    question_id, version_no, question_type, prompt, explanation,
                    content_payload, trust_label, curriculum_version_id, validation_status
                ) VALUES (
                    :question_id, 1, 'mcq', 'Synthetic?', 'Synthetic explanation.',
                    '{"schema_version":"1","selection_mode":"single"}', 'Expert verified',
                    :curriculum_id, 'draft'
                ) RETURNING id
                """
            ),
            {"question_id": question_id, "curriculum_id": CURRICULUM_ID},
        )
        connection.execute(
            text(
                """
                INSERT INTO question_options(
                    question_version_id, option_key, display_text, is_correct,
                    explanation, display_order
                ) VALUES
                    (:version_id, 'a', 'First', false, 'Synthetic.', 0),
                    (:version_id, 'b', 'Second', true, 'Synthetic.', 1)
                """
            ),
            {"version_id": version_id},
        )
        connection.execute(
            text(
                """
                INSERT INTO question_rubrics(
                    question_version_id, rubric_type, rubric_version, rubric_payload,
                    max_score, evidence_ceiling, status
                ) VALUES (
                    :version_id, 'exact', 1, '{"schema_version":"1"}', 1, 1, 'approved'
                )
                """
            ),
            {"version_id": version_id},
        )
        connection.execute(
            text(
                """
                INSERT INTO question_concept_maps(
                    question_version_id, concept_version_id, mapping_role, weight,
                    provenance_type, provenance_ref
                ) VALUES (
                    :version_id, :concept_version_id, 'primary', 1,
                    'synthetic', 'synthetic-review'
                )
                """
            ),
            {"version_id": version_id, "concept_version_id": CONCEPT_VERSION_ID},
        )

    with pytest.raises(DBAPIError), database.begin() as connection:
        connection.execute(
            text(
                "UPDATE question_versions SET validation_status = 'approved' WHERE id = :version_id"
            ),
            {"version_id": version_id},
        )

    with database.begin() as connection:
        connection.execute(
            text("UPDATE questions SET reviewer_principal = :reviewer WHERE id = :question_id"),
            {"reviewer": REVIEWER_ID, "question_id": question_id},
        )

    with database.begin() as connection:
        connection.execute(
            text(
                "UPDATE question_versions SET validation_status = 'approved' WHERE id = :version_id"
            ),
            {"version_id": version_id},
        )

    with database.connect() as connection:
        assert (
            connection.scalar(
                text("SELECT validation_status FROM question_versions WHERE id = :version_id"),
                {"version_id": version_id},
            )
            == "approved"
        )


def test_pinned_draft_content_cannot_change_after_use(database: Engine) -> None:
    user_id, _ = create_user(database)
    with database.begin() as connection:
        question_id = connection.scalar(
            text(
                """
                INSERT INTO questions(subject_id, question_code, source_class, status)
                VALUES (:subject_id, :question_code, 'expert_verified', 'draft')
                RETURNING id
                """
            ),
            {"subject_id": SUBJECT_ID, "question_code": f"synthetic-{uuid4().hex[:12]}"},
        )
        version_id = connection.scalar(
            text(
                """
                INSERT INTO question_versions(
                    question_id, version_no, question_type, prompt, explanation,
                    content_payload, trust_label, curriculum_version_id, validation_status
                ) VALUES (
                    :question_id, 1, 'numeric', 'Synthetic?', 'Synthetic explanation.',
                    '{"schema_version":"1","unit_affordance": true}', 'Expert verified',
                    :curriculum_id, 'draft'
                ) RETURNING id
                """
            ),
            {"question_id": question_id, "curriculum_id": CURRICULUM_ID},
        )
        mission_id = connection.scalar(
            text(
                """
                INSERT INTO missions(
                    user_id, subject_id, mission_date, mission_timezone, status,
                    engine_version, candidate_snapshot_hash, estimated_minutes,
                    planned_item_count, expires_at
                ) VALUES (
                    :user_id, :subject_id, CURRENT_DATE, 'Asia/Colombo', 'started',
                    'test', :snapshot_hash, 1, 1, now() + interval '1 day'
                ) RETURNING id
                """
            ),
            {
                "user_id": user_id,
                "subject_id": SUBJECT_ID,
                "snapshot_hash": uuid4().hex,
            },
        )
        connection.execute(
            text(
                """
                INSERT INTO mission_items(
                    mission_id, user_id, position, mission_type, question_version_id,
                    primary_concept_id, selection_reason_codes, priority_snapshot, status
                ) VALUES (
                    :mission_id, :user_id, 0, 'protect', :version_id,
                    :concept_id, ARRAY['synthetic'], '{"schema_version":"1"}', 'pending'
                )
                """
            ),
            {
                "mission_id": mission_id,
                "user_id": user_id,
                "version_id": version_id,
                "concept_id": concept_id(database),
            },
        )

    prohibited = [
        (
            "UPDATE question_versions SET prompt = 'Changed?' WHERE id = :version_id",
            {"version_id": version_id},
        ),
        (
            "DELETE FROM question_versions WHERE id = :version_id",
            {"version_id": version_id},
        ),
        (
            "INSERT INTO question_rubrics("
            "question_version_id, rubric_type, rubric_version, rubric_payload, "
            "max_score, evidence_ceiling, status"
            ") VALUES (:version_id, 'numeric', 1, '{}', 1, 1, 'draft')",
            {"version_id": version_id},
        ),
    ]
    for statement, parameters in prohibited:
        with pytest.raises(DBAPIError), database.begin() as connection:
            connection.execute(text(statement), parameters)


def test_pinned_question_history_stays_readable_only_to_its_owner(database: Engine) -> None:
    imported = import_question(database, question_bundle())
    question_id = imported["question_id"]
    version_id = imported["question_version_id"]
    owner_id, owner_subject = create_user(database)
    other_id, other_subject = create_user(database)
    create_mission_attempt(
        database,
        user_id=owner_id,
        question_version_id=version_id,
    )

    with database.begin() as connection:
        connection.execute(
            text("UPDATE questions SET status = 'retired' WHERE id = :question_id"),
            {"question_id": question_id},
        )

    with database.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_api"))
        connection.execute(
            text("SELECT set_config('memora.user_id', :user_id, true)"),
            {"user_id": str(owner_id)},
        )
        assert (
            connection.scalar(
                text("SELECT count(*) FROM questions WHERE id = :question_id"),
                {"question_id": question_id},
            )
            == 1
        )

    with database.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_api"))
        connection.execute(
            text("SELECT set_config('memora.user_id', :user_id, true)"),
            {"user_id": str(other_id)},
        )
        assert (
            connection.scalar(
                text("SELECT count(*) FROM questions WHERE id = :question_id"),
                {"question_id": question_id},
            )
            == 0
        )

    repository = QuestionReportRepository(database)
    snapshot = repository.load_snapshot(auth_context(owner_subject), question_version_id=version_id)
    assert snapshot.question_version_id == version_id
    assert snapshot.prompt == "Which quantity is a vector?"

    with pytest.raises(QuestionValidationError) as captured:
        repository.load_snapshot(auth_context(other_subject), question_version_id=version_id)
    assert captured.value.code == "question_not_found"


def test_reports_are_idempotent_owner_scoped_and_paginated(database: Engine) -> None:
    imported = import_question(database, question_bundle())
    question_version_id = imported["question_version_id"]
    owner_id, owner_subject = create_user(database)
    other_id, other_subject = create_user(database)
    attempt_id, _ = create_mission_attempt(
        database,
        user_id=owner_id,
        question_version_id=question_version_id,
    )
    service = QuestionService(
        QuestionReportRepository(database),
        Settings(_env_file=None, device_encryption_key=_encryption_key()),
    )
    owner_request = authenticated_request(owner_subject)
    other_request = authenticated_request(other_subject)
    body = QuestionReportCreateRequest(
        report_type="question_error",
        description="The synthetic wording is ambiguous.",
    )
    idempotency_key = f"synthetic-{uuid4()}"

    first, created = service.create_report(
        owner_request,
        question_version_id,
        body,
        idempotency_key=idempotency_key,
    )
    replay, replayed = service.create_report(
        owner_request,
        question_version_id,
        body,
        idempotency_key=idempotency_key,
    )

    assert created is True
    assert replayed is False
    assert replay.id == first.id
    assert first.description_present is True
    assert first.evidence_state == "recorded"

    with pytest.raises(ApiError) as captured:
        service.create_report(
            owner_request,
            question_version_id,
            QuestionReportCreateRequest(report_type="answer_error"),
            idempotency_key=idempotency_key,
        )
    assert captured.value.code == "idempotency_key_reused"

    repository = QuestionReportRepository(database)
    for offset, report_type in enumerate(
        ("question_error", "explanation_error", "accessibility"), start=1
    ):
        repository.create_report(
            owner_request.context,
            idempotency_key=f"synthetic-{uuid4()}",
            request_hash=f"synthetic-hash-{offset}",
            report_id=uuid4(),
            question_version_id=question_version_id,
            attempt_id=None,
            report_type=report_type,
            description_ciphertext=None,
            submitted_at=datetime.now(UTC) - timedelta(minutes=3 - offset),
        )

    page = service.list_reports(owner_request, cursor=None, limit=2)
    assert len(page.items) == 2
    assert page.has_more is True
    assert page.next_cursor is not None

    rest = service.list_reports(owner_request, cursor=page.next_cursor, limit=2)
    assert len(rest.items) == 2
    assert rest.has_more is False
    assert all(item.id not in {entry.id for entry in page.items} for item in rest.items)

    assert service.list_reports(other_request, cursor=None, limit=20).items == []
    with pytest.raises(ApiError) as captured:
        service.get_report(other_request, first.id)
    assert captured.value.status_code == 404
    assert captured.value.code == "resource_not_found"

    with pytest.raises(ApiError) as captured:
        service.create_report(
            other_request,
            question_version_id,
            QuestionReportCreateRequest(
                report_type="grading_dispute",
                attempt_id=attempt_id,
            ),
            idempotency_key=f"synthetic-{uuid4()}",
        )
    assert captured.value.status_code == 404

    with database.connect() as connection:
        stored = (
            connection.execute(
                text(
                    "SELECT user_id, description_ciphertext FROM question_reports "
                    "WHERE id = :report_id"
                ),
                {"report_id": first.id},
            )
            .mappings()
            .one()
        )
    assert stored["user_id"] == owner_id
    assert stored["description_ciphertext"] is not None
    assert b"ambiguous" not in bytes(stored["description_ciphertext"])

    with database.connect() as connection:
        assert (
            connection.scalar(
                text(
                    "SELECT count(*) FROM idempotency_records "
                    "WHERE user_id = :user_id AND operation = 'createQuestionReport' "
                    "AND idempotency_key = :key"
                ),
                {"user_id": owner_id, "key": idempotency_key},
            )
            == 1
        )


def test_report_provenance_is_immutable_and_does_not_rewrite_grading(
    database: Engine,
) -> None:
    imported = import_question(database, question_bundle())
    question_version_id = imported["question_version_id"]
    owner_id, owner_subject = create_user(database)
    attempt_id, _ = create_mission_attempt(
        database,
        user_id=owner_id,
        question_version_id=question_version_id,
    )
    with database.connect() as connection:
        rubric_id = connection.scalar(
            text("SELECT id FROM question_rubrics WHERE question_version_id = :version_id"),
            {"version_id": question_version_id},
        )
    with database.begin() as connection:
        grading_result_id = connection.scalar(
            text(
                """
                INSERT INTO grading_results(
                    attempt_id, result_version, grader_type, score, classification,
                    confidence, rubric_id, grader_version, evidence_payload,
                    is_authoritative, graded_at
                ) VALUES (
                    :attempt_id, 1, 'exact', 1, 'correct', 1, :rubric_id, 'mcq-exact-v1',
                    '{"schema_version":"1"}', true, now()
                ) RETURNING id
                """
            ),
            {"attempt_id": attempt_id, "rubric_id": rubric_id},
        )

    service = QuestionService(
        QuestionReportRepository(database),
        Settings(_env_file=None, device_encryption_key=_encryption_key()),
    )
    report, created = service.create_report(
        authenticated_request(owner_subject),
        question_version_id,
        QuestionReportCreateRequest(
            report_type="grading_dispute",
            attempt_id=attempt_id,
            description="I think the answer key is wrong.",
        ),
        idempotency_key=f"synthetic-{uuid4()}",
    )
    assert created is True
    assert report.attempt_id == attempt_id
    assert report.evidence_state == "limited_pending_review"
    assert report.review_required is True

    prohibited = [
        (
            "UPDATE question_reports SET report_type = 'answer_error' WHERE id = :report_id",
            {"report_id": report.id},
        ),
        (
            "UPDATE question_reports SET attempt_id = NULL WHERE id = :report_id",
            {"report_id": report.id},
        ),
        (
            "UPDATE question_reports SET description_ciphertext = NULL WHERE id = :report_id",
            {"report_id": report.id},
        ),
        (
            "UPDATE question_reports SET status = 'resolved' WHERE id = :report_id",
            {"report_id": report.id},
        ),
    ]
    for statement, parameters in prohibited:
        with pytest.raises(DBAPIError), database.begin() as connection:
            connection.execute(text(statement), parameters)

    with database.begin() as connection:
        connection.execute(
            text(
                "UPDATE question_reports SET status = 'resolved', resolution_code = 'upheld', "
                "resolved_at = now() WHERE id = :report_id"
            ),
            {"report_id": report.id},
        )

    with database.connect() as connection:
        grading = (
            connection.execute(
                text(
                    "SELECT score, classification, is_authoritative, grader_version "
                    "FROM grading_results WHERE id = :result_id"
                ),
                {"result_id": grading_result_id},
            )
            .mappings()
            .one()
        )
        question = (
            connection.execute(
                text(
                    "SELECT prompt, validation_status, row_version FROM question_versions "
                    "WHERE id = :version_id"
                ),
                {"version_id": question_version_id},
            )
            .mappings()
            .one()
        )
        report_row = (
            connection.execute(
                text("SELECT status, resolution_code FROM question_reports WHERE id = :report_id"),
                {"report_id": report.id},
            )
            .mappings()
            .one()
        )
    assert Decimal(grading["score"]) == Decimal("1")
    assert grading["classification"] == "correct"
    assert grading["is_authoritative"] is True
    assert grading["grader_version"] == "mcq-exact-v1"
    assert question["prompt"] == "Which quantity is a vector?"
    assert question["validation_status"] == "approved"
    assert report_row["status"] == "resolved"
    assert report_row["resolution_code"] == "upheld"


def test_import_replay_survives_database_numeric_rounding(database: Engine) -> None:
    question_code = f"synthetic-{uuid4().hex[:12]}"
    original = question_bundle(question_code=question_code)
    bundle = original.model_copy(
        update={
            "rubric": original.rubric.model_copy(
                update={
                    "max_score": Decimal("1.2344"),
                    "evidence_ceiling": Decimal("0.912344"),
                }
            ),
            "concept_mappings": [
                original.concept_mappings[0].model_copy(update={"weight": Decimal("0.500004")})
            ],
        }
    )

    first = import_question(database, bundle)
    replay = import_question(database, bundle)

    assert first["created"] is True
    assert replay["created"] is False
    assert replay["question_version_id"] == first["question_version_id"]
    assert replay["version_no"] == 1

    with database.connect() as connection:
        stored = (
            connection.execute(
                text(
                    """
                    SELECT r.max_score, r.evidence_ceiling, m.weight
                    FROM question_rubrics r
                    JOIN question_concept_maps m
                      ON m.question_version_id = r.question_version_id
                    WHERE r.question_version_id = :version_id
                    """
                ),
                {"version_id": first["question_version_id"]},
            )
            .mappings()
            .one()
        )
    assert Decimal(stored["max_score"]) == Decimal("1.234")
    assert Decimal(stored["evidence_ceiling"]) == Decimal("0.91234")
    assert Decimal(stored["weight"]) == Decimal("0.50000")

    changed = bundle.model_copy(
        update={"rubric": bundle.rubric.model_copy(update={"max_score": Decimal("1.235")})}
    )
    second = import_question(database, changed)

    assert second["created"] is True
    assert second["version_no"] == 2


def test_generated_import_accepts_approved_grounding_in_curriculum(database: Engine) -> None:
    claim_id = UUID("70000000-0000-0000-0000-000000000001")
    bundle = generated_question_bundle(grounding_evidence_ids=[claim_id])

    imported = import_question(database, bundle)
    replay = import_question(database, bundle)

    assert imported["created"] is True
    assert replay["created"] is False
    assert replay["question_version_id"] == imported["question_version_id"]

    with database.connect() as connection:
        stored = connection.scalar(
            text("SELECT grounding_evidence_ids FROM question_versions WHERE id = :id"),
            {"id": imported["question_version_id"]},
        )
    assert [UUID(str(value)) for value in stored] == [claim_id]


def test_generated_import_rejects_missing_disputed_or_draft_grounding(
    database: Engine,
) -> None:
    claim_ids = [
        uuid4(),
        create_claim(database, concept_version_id=CONCEPT_VERSION_ID, status="disputed"),
        create_claim(database, concept_version_id=CONCEPT_VERSION_ID, status="draft"),
    ]

    for claim_id in claim_ids:
        with pytest.raises(QuestionValidationError) as captured:
            import_question(
                database,
                generated_question_bundle(grounding_evidence_ids=[claim_id]),
            )
        assert captured.value.code == "grounding_evidence_invalid"


def test_generated_import_rejects_grounding_from_another_subject(database: Engine) -> None:
    other_subject = create_subject(database)
    foreign_version = create_concept_version(database, subject_id=other_subject)
    map_concept_to_objective(
        database,
        concept_version_id=foreign_version,
        objective_id=UUID("30000000-0000-0000-0000-000000000002"),
    )
    claim_id = create_claim(database, concept_version_id=foreign_version)

    with pytest.raises(QuestionValidationError) as captured:
        import_question(
            database,
            generated_question_bundle(grounding_evidence_ids=[claim_id]),
        )
    assert captured.value.code == "grounding_evidence_invalid"


def test_generated_import_rejects_grounding_from_another_curriculum(
    database: Engine,
) -> None:
    other_curriculum = create_curriculum(database, subject_id=SUBJECT_ID)
    other_objective = create_objective(database, curriculum_id=other_curriculum)
    foreign_version = create_concept_version(database, subject_id=SUBJECT_ID)
    map_concept_to_objective(
        database,
        concept_version_id=foreign_version,
        objective_id=other_objective,
    )
    claim_id = create_claim(database, concept_version_id=foreign_version)

    with pytest.raises(QuestionValidationError) as captured:
        import_question(
            database,
            generated_question_bundle(grounding_evidence_ids=[claim_id]),
        )
    assert captured.value.code == "grounding_evidence_invalid"


def test_import_rejects_foreign_or_draft_curriculum(database: Engine) -> None:
    other_subject = create_subject(database)
    foreign_curriculum = create_curriculum(database, subject_id=other_subject)
    draft_curriculum = create_curriculum(
        database,
        subject_id=SUBJECT_ID,
        status="draft",
    )

    for curriculum_id in (foreign_curriculum, draft_curriculum):
        with pytest.raises(QuestionValidationError) as captured:
            import_question(
                database,
                question_bundle().model_copy(update={"curriculum_version_id": curriculum_id}),
            )
        assert captured.value.code == "curriculum_invalid"


def test_import_rejects_foreign_or_unapproved_concept_mapping(database: Engine) -> None:
    other_subject = create_subject(database)
    concept_versions = (
        create_concept_version(database, subject_id=other_subject),
        create_concept_version(database, subject_id=SUBJECT_ID, concept_status="draft"),
        create_concept_version(database, subject_id=SUBJECT_ID, content_status="draft"),
    )
    original = question_bundle()

    for concept_version_id in concept_versions:
        bundle = original.model_copy(
            update={
                "concept_mappings": [
                    original.concept_mappings[0].model_copy(
                        update={"concept_version_id": concept_version_id}
                    )
                ]
            }
        )
        with pytest.raises(QuestionValidationError) as captured:
            import_question(database, bundle)
        assert captured.value.code == "concept_mapping_invalid"


def test_import_rejects_objective_from_another_curriculum(database: Engine) -> None:
    other_curriculum = create_curriculum(database, subject_id=SUBJECT_ID)
    other_objective = create_objective(database, curriculum_id=other_curriculum)
    original = question_bundle()
    bundle = original.model_copy(
        update={
            "concept_mappings": [
                original.concept_mappings[0].model_copy(
                    update={"learning_objective_id": other_objective}
                )
            ]
        }
    )

    with pytest.raises(QuestionValidationError) as captured:
        import_question(database, bundle)
    assert captured.value.code == "concept_mapping_invalid"


def test_import_rejects_objective_not_aligned_to_concept(database: Engine) -> None:
    original = question_bundle()
    dimensions_objective = UUID("30000000-0000-0000-0000-000000000003")
    bundle = original.model_copy(
        update={
            "concept_mappings": [
                original.concept_mappings[0].model_copy(
                    update={"learning_objective_id": dimensions_objective}
                )
            ]
        }
    )

    with pytest.raises(QuestionValidationError) as captured:
        import_question(database, bundle)
    assert captured.value.code == "concept_mapping_invalid"


def test_import_rejects_draft_objective(database: Engine) -> None:
    curriculum_id = create_curriculum(database, subject_id=SUBJECT_ID)
    objective_id = create_objective(
        database,
        curriculum_id=curriculum_id,
        status="draft",
    )
    map_concept_to_objective(
        database,
        concept_version_id=CONCEPT_VERSION_ID,
        objective_id=objective_id,
    )
    original = question_bundle()
    bundle = original.model_copy(
        update={
            "curriculum_version_id": curriculum_id,
            "concept_mappings": [
                original.concept_mappings[0].model_copy(
                    update={"learning_objective_id": objective_id}
                )
            ],
        }
    )

    with pytest.raises(QuestionValidationError) as captured:
        import_question(database, bundle)
    assert captured.value.code == "concept_mapping_invalid"


def test_approved_import_requires_a_curriculum_aligned_mapping(database: Engine) -> None:
    concept_version_id = create_concept_version(database, subject_id=SUBJECT_ID)
    original = question_bundle()
    bundle = original.model_copy(
        update={
            "concept_mappings": [
                original.concept_mappings[0].model_copy(
                    update={"concept_version_id": concept_version_id}
                )
            ]
        }
    )

    with pytest.raises(QuestionValidationError) as captured:
        import_question(database, bundle)
    assert captured.value.code == "curriculum_mapping_missing"


def test_attempt_evidence_eligibility_tracks_linked_open_reports(database: Engine) -> None:
    imported = import_question(database, question_bundle())
    owner_id, owner_subject = create_user(database)
    _, other_subject = create_user(database)
    attempt_id, _ = create_mission_attempt(
        database,
        user_id=owner_id,
        question_version_id=imported["question_version_id"],
    )
    repository = QuestionReportRepository(database)
    service = QuestionService(
        repository,
        Settings(_env_file=None, device_encryption_key=_encryption_key()),
    )
    owner_request = authenticated_request(owner_subject)

    assert (
        repository.attempt_evidence_eligibility(
            owner_request.context,
            attempt_id=attempt_id,
        )
        == "eligible"
    )

    answer_error, _ = service.create_report(
        owner_request,
        imported["question_version_id"],
        QuestionReportCreateRequest(
            report_type="answer_error",
            description="The displayed answer looked wrong.",
        ),
        idempotency_key=f"synthetic-{uuid4()}",
    )
    assert answer_error.attempt_id is None
    assert answer_error.evidence_state == "recorded"
    assert (
        repository.attempt_evidence_eligibility(
            owner_request.context,
            attempt_id=attempt_id,
        )
        == "eligible"
    )

    dispute, _ = service.create_report(
        owner_request,
        imported["question_version_id"],
        QuestionReportCreateRequest(
            report_type="grading_dispute",
            attempt_id=attempt_id,
        ),
        idempotency_key=f"synthetic-{uuid4()}",
    )
    assert dispute.evidence_state == "limited_pending_review"
    assert (
        repository.attempt_evidence_eligibility(
            owner_request.context,
            attempt_id=attempt_id,
        )
        == "limited_pending_review"
    )

    with database.begin() as connection:
        connection.execute(
            text(
                "UPDATE question_reports SET status = 'resolved', resolution_code = 'upheld', "
                "resolved_at = now() WHERE id = :report_id"
            ),
            {"report_id": dispute.id},
        )

    assert (
        repository.attempt_evidence_eligibility(
            owner_request.context,
            attempt_id=attempt_id,
        )
        == "eligible"
    )

    with pytest.raises(ApiError) as captured:
        repository.attempt_evidence_eligibility(
            auth_context(other_subject),
            attempt_id=attempt_id,
        )
    assert captured.value.status_code == 404
    assert captured.value.code == "resource_not_found"
