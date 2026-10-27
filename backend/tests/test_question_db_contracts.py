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
