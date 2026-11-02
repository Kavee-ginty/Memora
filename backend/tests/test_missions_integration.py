"""PostgreSQL lifecycle, ownership, idempotency and outbox tests for T13."""

from __future__ import annotations

import json
import os
import threading
from collections.abc import Iterator
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from pathlib import Path
from uuid import UUID, uuid4

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import Engine, create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.exc import DBAPIError

from memora.api.errors import ApiError
from memora.api.security import AuthContext
from memora.db.seed import seed_database
from memora.modules.missions.repository import MissionRepository
from memora.modules.questions.models import QuestionImportBundle, SingleChoiceAnswer
from memora.modules.questions.repository import QuestionImportRepository
from memora.modules.questions.validation import validate_question_import
from memora.worker.memory import map_outbox_event, process_next_job

BACKEND_ROOT = Path(__file__).parents[1]
ISSUER = "https://missions.test"
SUBJECT_ID = UUID("10000000-0000-0000-0000-000000000001")
CURRICULUM_ID = UUID("20000000-0000-0000-0000-000000000001")
NOW = datetime(2026, 11, 1, 6, tzinfo=UTC)


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
    database_name = make_url(database_url).database or ""
    if not database_name.endswith(("_test", "_ci")):
        pytest.fail("MEMORA_TEST_DATABASE_URL must target a disposable _test or _ci database")

    monkeypatch.setenv("MEMORA_DATABASE_URL", database_url)
    command.upgrade(alembic_config(database_url), "head")
    seed_database(database_url)
    engine = create_engine(database_url, connect_args={"connect_timeout": 10})
    try:
        yield engine
    finally:
        engine.dispose()


def auth(subject: str) -> AuthContext:
    return AuthContext(
        issuer=ISSUER,
        subject=subject,
        session_id=uuid4(),
        role="authenticated",
        authenticated_at=NOW,
        expires_at=NOW + timedelta(hours=1),
    )


def create_user(engine: Engine, subject: str) -> UUID:
    with engine.begin() as connection:
        return UUID(
            str(
                connection.scalar(
                    text(
                        """
                        INSERT INTO users(
                            oidc_issuer, oidc_subject, status, default_timezone, locale
                        ) VALUES (
                            :issuer, :subject, 'active', 'Asia/Colombo', 'en'
                        ) RETURNING id
                        """
                    ),
                    {"issuer": ISSUER, "subject": subject},
                )
            )
        )


def first_concept(engine: Engine) -> tuple[UUID, UUID]:
    with engine.connect() as connection:
        row = (
            connection.execute(
                text(
                    """
                    SELECT c.id AS concept_id, cv.id AS version_id
                    FROM concepts c
                    JOIN concept_versions cv ON cv.concept_id = c.id
                    WHERE c.subject_id=:subject_id AND c.status='approved'
                      AND cv.content_status='approved'
                    ORDER BY c.stable_code, cv.version_no DESC LIMIT 1
                    """
                ),
                {"subject_id": SUBJECT_ID},
            )
            .mappings()
            .one()
        )
    return UUID(str(row["concept_id"])), UUID(str(row["version_id"]))


def question_bundle(concept_version_id: UUID, code: str) -> QuestionImportBundle:
    return QuestionImportBundle.model_validate(
        {
            "question_code": code,
            "subject_id": SUBJECT_ID,
            "curriculum_version_id": CURRICULUM_ID,
            "source_class": "expert_verified",
            "question_type": "mcq",
            "prompt": "Which option protects this synthetic memory?",
            "explanation": "Option B is the reviewed answer.",
            "validation_status": "approved",
            "author_principal": uuid4(),
            "reviewer_principal": uuid4(),
            "content": {"schema_version": "1", "selection_mode": "single"},
            "options": [
                {
                    "option_key": "a",
                    "display_text": "Option A",
                    "is_correct": False,
                    "explanation": "This is not the reviewed answer.",
                    "display_order": 0,
                },
                {
                    "option_key": "b",
                    "display_text": "Option B",
                    "is_correct": True,
                    "explanation": "This is the reviewed answer.",
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
                    "concept_version_id": concept_version_id,
                    "mapping_role": "primary",
                    "weight": Decimal("1"),
                    "provenance_type": "review",
                    "provenance_ref": "synthetic-mission-review",
                }
            ],
        }
    )


def prepare_due_work(engine: Engine, user_id: UUID) -> tuple[UUID, UUID]:
    concept_id, concept_version_id = first_concept(engine)
    importer = QuestionImportRepository(engine)
    for suffix in ("primary", "repair"):
        importer.import_question(
            validate_question_import(
                question_bundle(concept_version_id, f"mission-{suffix}-{uuid4().hex[:8]}")
            )
        )
    with engine.begin() as connection:
        connection.execute(
            text(
                """
                INSERT INTO learner_concept_states(
                    user_id, concept_id, active_concept_version_id, difficulty,
                    stability_days, last_retrievability, evidence_confidence,
                    first_exposed_at, last_reviewed_at, next_review_at,
                    exposure_count, eligible_review_count, lapse_count, engine_version
                ) VALUES (
                    :user_id, :concept_id, :version_id, 5, 1, 0.4, 1,
                    :first_exposed, NULL, :next_review, 1, 0, 0, 'fsrs-v1'
                )
                """
            ),
            {
                "user_id": user_id,
                "concept_id": concept_id,
                "version_id": concept_version_id,
                "first_exposed": NOW - timedelta(days=2),
                "next_review": NOW - timedelta(hours=1),
            },
        )
    return concept_id, concept_version_id


def run_concurrently(action):
    barrier = threading.Barrier(2)

    def synchronized():
        barrier.wait(timeout=10)
        return action()

    with ThreadPoolExecutor(max_workers=2) as executor:
        futures = [executor.submit(synchronized) for _ in range(2)]
        return [future.result(timeout=20) for future in futures]


def test_full_lifecycle_is_owner_scoped_idempotent_and_outbox_driven(
    database: Engine,
) -> None:
    owner_subject = f"owner-{uuid4()}"
    other_subject = f"other-{uuid4()}"
    owner_id = create_user(database, owner_subject)
    create_user(database, other_subject)
    prepare_due_work(database, owner_id)
    repository = MissionRepository(database)

    planned = repository.today(auth(owner_subject), now=NOW)
    replayed_plan = repository.today(auth(owner_subject), now=NOW)
    assert planned is not None
    assert replayed_plan is not None
    assert replayed_plan["id"] == planned["id"]
    assert planned["planned_item_count"] == 1
    assert planned["estimated_minutes"] <= 7

    with pytest.raises(ApiError) as not_owned:
        repository.get_mission(auth(other_subject), planned["id"])
    assert not_owned.value.status_code == 404
    assert repository.today(auth(other_subject), now=NOW) is None

    start_key = f"start-{uuid4()}"
    started = repository.start(
        auth(owner_subject),
        planned["id"],
        idempotency_key=start_key,
        request_hash="1" * 64,
        now=NOW,
    )
    replayed_start = repository.start(
        auth(owner_subject),
        planned["id"],
        idempotency_key=start_key,
        request_hash="1" * 64,
        now=NOW,
    )
    assert started["mission"]["status"] == "started"
    assert replayed_start["mission"]["id"] == planned["id"]
    first_item = started["items"][0]

    private_calls = [
        lambda: repository.start(
            auth(other_subject),
            planned["id"],
            idempotency_key=f"private-start-{uuid4()}",
            request_hash="5" * 64,
            now=NOW,
        ),
        lambda: repository.get_item(auth(other_subject), planned["id"], first_item["id"]),
        lambda: repository.submit_attempt(
            auth(other_subject),
            planned["id"],
            first_item["id"],
            question_version_id=uuid4(),
            answer=SingleChoiceAnswer(type="single_choice", option_keys=["a"]),
            client_operation_id=uuid4(),
            request_hash="6" * 64,
            answered_at=NOW,
            offline_submission=False,
            elapsed_ms=None,
            app_version="test",
            correlation_id=uuid4(),
            now=NOW,
        ),
        lambda: repository.skip(
            auth(other_subject),
            planned["id"],
            first_item["id"],
            idempotency_key=f"private-skip-{uuid4()}",
            request_hash="7" * 64,
            now=NOW,
        ),
        lambda: repository.pause(
            auth(other_subject),
            planned["id"],
            idempotency_key=f"private-pause-{uuid4()}",
            request_hash="8" * 64,
            now=NOW,
        ),
        lambda: repository.complete(
            auth(other_subject),
            planned["id"],
            idempotency_key=f"private-complete-{uuid4()}",
            request_hash="9" * 64,
            correlation_id=uuid4(),
            now=NOW,
        ),
        lambda: repository.results(auth(other_subject), planned["id"]),
    ]
    for private_call in private_calls:
        with pytest.raises(ApiError) as hidden:
            private_call()
        assert hidden.value.status_code == 404

    item_payload = repository.get_item(auth(owner_subject), planned["id"], first_item["id"])
    assert all("is_correct" not in option for option in item_payload["question"]["options"])

    operation_id = uuid4()
    wrong_hash = "2" * 64
    wrong = repository.submit_attempt(
        auth(owner_subject),
        planned["id"],
        first_item["id"],
        question_version_id=item_payload["question"]["question_version_id"],
        answer=SingleChoiceAnswer(type="single_choice", option_keys=["a"]),
        client_operation_id=operation_id,
        request_hash=wrong_hash,
        answered_at=NOW,
        offline_submission=False,
        elapsed_ms=1200,
        app_version="test",
        correlation_id=uuid4(),
        now=NOW,
    )
    duplicate = repository.submit_attempt(
        auth(owner_subject),
        planned["id"],
        first_item["id"],
        question_version_id=item_payload["question"]["question_version_id"],
        answer=SingleChoiceAnswer(type="single_choice", option_keys=["a"]),
        client_operation_id=operation_id,
        request_hash=wrong_hash,
        answered_at=NOW,
        offline_submission=False,
        elapsed_ms=1200,
        app_version="test",
        correlation_id=uuid4(),
        now=NOW,
    )
    assert wrong["outcome"] == "weak"
    assert wrong["repair_action"] == "repair_inserted"
    assert duplicate["attempt_id"] == wrong["attempt_id"]
    assert wrong["next_item_id"] is not None
    with pytest.raises(ApiError) as changed_answer:
        repository.submit_attempt(
            auth(owner_subject),
            planned["id"],
            first_item["id"],
            question_version_id=item_payload["question"]["question_version_id"],
            answer=SingleChoiceAnswer(type="single_choice", option_keys=["b"]),
            client_operation_id=operation_id,
            request_hash="9" * 64,
            answered_at=NOW,
            offline_submission=False,
            elapsed_ms=1200,
            app_version="test",
            correlation_id=uuid4(),
            now=NOW,
        )
    assert changed_answer.value.code == "idempotency_key_reused"

    repair = repository.get_item(
        auth(owner_subject), planned["id"], UUID(str(wrong["next_item_id"]))
    )
    repaired = repository.submit_attempt(
        auth(owner_subject),
        planned["id"],
        repair["id"],
        question_version_id=repair["question"]["question_version_id"],
        answer=SingleChoiceAnswer(type="single_choice", option_keys=["b"]),
        client_operation_id=uuid4(),
        request_hash="3" * 64,
        answered_at=NOW,
        offline_submission=True,
        elapsed_ms=None,
        app_version="test",
        correlation_id=uuid4(),
        now=NOW,
    )
    assert repaired["outcome"] == "recalled"
    assert repaired["can_complete"] is True

    complete_key = f"complete-{uuid4()}"
    completed = repository.complete(
        auth(owner_subject),
        planned["id"],
        idempotency_key=complete_key,
        request_hash="4" * 64,
        correlation_id=uuid4(),
        now=NOW,
    )
    replayed_completion = repository.complete(
        auth(owner_subject),
        planned["id"],
        idempotency_key=complete_key,
        request_hash="4" * 64,
        correlation_id=uuid4(),
        now=NOW,
    )
    assert completed == replayed_completion
    assert completed["repaired_count"] == 1
    assert completed["engagement_status"] == "pending"

    with database.connect() as connection:
        rows = (
            connection.execute(
                text(
                    """
                    SELECT aggregate_type, event_type, aggregate_id, payload
                    FROM outbox_events
                    WHERE (event_type='mission.attempt_graded' AND payload->>'user_id'=:user_id)
                       OR (event_type='mission.completed' AND aggregate_id=:mission_id)
                    ORDER BY created_at
                    """
                ),
                {"user_id": str(owner_id), "mission_id": planned["id"]},
            )
            .mappings()
            .all()
        )
    attempt_events = [row for row in rows if row["event_type"] == "mission.attempt_graded"]
    completion_events = [row for row in rows if row["event_type"] == "mission.completed"]
    assert len(attempt_events) == 2
    assert len(completion_events) == 1
    evidence = map_outbox_event(
        str(attempt_events[0]["aggregate_type"]),
        str(attempt_events[0]["event_type"]),
        attempt_events[0]["payload"],
        outbox_event_id=uuid4(),
    )
    assert len(evidence) == 1

    attempt_id = UUID(str(attempt_events[0]["aggregate_id"]))
    with database.connect() as connection:
        outbox_id = connection.scalar(
            text(
                "SELECT id FROM outbox_events WHERE event_type='mission.attempt_graded' "
                "AND aggregate_id=:attempt_id"
            ),
            {"attempt_id": attempt_id},
        )
    assert outbox_id is not None
    with database.begin() as connection:
        for suffix in ("first", "replay"):
            connection.execute(
                text(
                    """
                    INSERT INTO background_jobs(
                        job_type, resource_type, resource_id, dedupe_key, status,
                        attempt_count, max_attempts, available_at, payload
                    ) VALUES (
                        'memory.process_event', 'outbox_event', :outbox_id, :dedupe_key,
                        'queued', 0, 5, :available_at, CAST(:payload AS jsonb)
                    )
                    """
                ),
                {
                    "outbox_id": outbox_id,
                    "dedupe_key": f"t13-replay:{outbox_id}:{suffix}",
                    "available_at": NOW,
                    "payload": json.dumps(
                        {"schema_version": "1", "outbox_event_id": str(outbox_id)}
                    ),
                },
            )
    assert process_next_job(database, now=NOW, lease_owner="t13-first") == "succeeded"
    assert process_next_job(database, now=NOW, lease_owner="t13-replay") == "succeeded"
    with database.connect() as connection:
        assert (
            connection.scalar(
                text(
                    "SELECT count(*) FROM memory_events "
                    "WHERE source_type='attempt' AND source_id=:attempt_id"
                ),
                {"attempt_id": attempt_id},
            )
            == 1
        )


def test_pause_resume_skip_and_completion_recover_safely(database: Engine) -> None:
    subject = f"pause-{uuid4()}"
    user_id = create_user(database, subject)
    prepare_due_work(database, user_id)
    repository = MissionRepository(database)
    planned = repository.today(auth(subject), now=NOW)
    assert planned is not None

    started = repository.start(
        auth(subject),
        planned["id"],
        idempotency_key=f"start-{uuid4()}",
        request_hash="a" * 64,
        now=NOW,
    )
    item_id = started["items"][0]["id"]
    pause_key = f"pause-{uuid4()}"
    paused = repository.pause(
        auth(subject),
        planned["id"],
        idempotency_key=pause_key,
        request_hash="b" * 64,
        now=NOW,
    )
    replayed_pause = repository.pause(
        auth(subject),
        planned["id"],
        idempotency_key=pause_key,
        request_hash="b" * 64,
        now=NOW,
    )
    assert paused["status"] == replayed_pause["status"] == "paused"

    resumed = repository.start(
        auth(subject),
        planned["id"],
        idempotency_key=f"resume-{uuid4()}",
        request_hash="c" * 64,
        now=NOW,
    )
    assert resumed["mission"]["status"] == "started"
    skip_key = f"skip-{uuid4()}"
    skipped = repository.skip(
        auth(subject),
        planned["id"],
        item_id,
        idempotency_key=skip_key,
        request_hash="d" * 64,
        now=NOW,
    )
    replayed_skip = repository.skip(
        auth(subject),
        planned["id"],
        item_id,
        idempotency_key=skip_key,
        request_hash="d" * 64,
        now=NOW,
    )
    assert skipped == replayed_skip
    assert skipped["outcome"] == "skipped"
    assert skipped["can_complete"] is True

    completed = repository.complete(
        auth(subject),
        planned["id"],
        idempotency_key=f"complete-{uuid4()}",
        request_hash="e" * 64,
        correlation_id=uuid4(),
        now=NOW,
    )
    assert completed["skipped_count"] == 1
    assert completed["protected_count"] == 0


def test_concurrent_start_answer_and_completion_converge(database: Engine) -> None:
    subject = f"concurrent-{uuid4()}"
    user_id = create_user(database, subject)
    prepare_due_work(database, user_id)
    repository = MissionRepository(database)
    planned = repository.today(auth(subject), now=NOW)
    assert planned is not None

    start_key = f"start-{uuid4()}"
    starts = run_concurrently(
        lambda: repository.start(
            auth(subject),
            planned["id"],
            idempotency_key=start_key,
            request_hash="1" * 64,
            now=NOW,
        )
    )
    assert len({result["mission"]["id"] for result in starts}) == 1
    item_id = starts[0]["items"][0]["id"]
    question = repository.get_item(auth(subject), planned["id"], item_id)["question"]

    operation_id = uuid4()
    answers = run_concurrently(
        lambda: repository.submit_attempt(
            auth(subject),
            planned["id"],
            item_id,
            question_version_id=question["question_version_id"],
            answer=SingleChoiceAnswer(type="single_choice", option_keys=["b"]),
            client_operation_id=operation_id,
            request_hash="2" * 64,
            answered_at=NOW,
            offline_submission=False,
            elapsed_ms=500,
            app_version="test",
            correlation_id=uuid4(),
            now=NOW,
        )
    )
    assert len({result["attempt_id"] for result in answers}) == 1

    complete_key = f"complete-{uuid4()}"
    completions = run_concurrently(
        lambda: repository.complete(
            auth(subject),
            planned["id"],
            idempotency_key=complete_key,
            request_hash="3" * 64,
            correlation_id=uuid4(),
            now=NOW,
        )
    )
    assert completions[0] == completions[1]
    with database.connect() as connection:
        counts = (
            connection.execute(
                text(
                    """
                SELECT
                  (SELECT count(*) FROM attempts WHERE client_operation_id=:operation_id)
                    AS attempts,
                  (SELECT count(*) FROM outbox_events
                   WHERE event_type='mission.attempt_graded'
                     AND aggregate_id=:attempt_id) AS attempt_events,
                  (SELECT count(*) FROM outbox_events
                   WHERE event_type='mission.completed'
                     AND aggregate_id=:mission_id) AS completion_events
                """
                ),
                {
                    "operation_id": operation_id,
                    "attempt_id": answers[0]["attempt_id"],
                    "mission_id": planned["id"],
                },
            )
            .mappings()
            .one()
        )
    assert (counts["attempts"], counts["attempt_events"], counts["completion_events"]) == (
        1,
        1,
        1,
    )


def test_lock_timeout_rolls_back_and_same_start_retry_succeeds(database: Engine) -> None:
    subject = f"timeout-{uuid4()}"
    user_id = create_user(database, subject)
    prepare_due_work(database, user_id)
    repository = MissionRepository(database)
    planned = repository.today(auth(subject), now=NOW)
    assert planned is not None
    key = f"timeout-{uuid4()}"

    timeout_engine = create_engine(
        database.url,
        connect_args={"connect_timeout": 10, "options": "-c lock_timeout=250ms"},
    )
    try:
        timeout_repository = MissionRepository(timeout_engine)
        with database.begin() as connection:
            connection.execute(
                text("SELECT id FROM missions WHERE id=:id FOR UPDATE"),
                {"id": planned["id"]},
            )
            with pytest.raises(DBAPIError):
                timeout_repository.start(
                    auth(subject),
                    planned["id"],
                    idempotency_key=key,
                    request_hash="4" * 64,
                    now=NOW,
                )
    finally:
        timeout_engine.dispose()

    started = repository.start(
        auth(subject),
        planned["id"],
        idempotency_key=key,
        request_hash="4" * 64,
        now=NOW,
    )
    assert started["mission"]["status"] == "started"


def test_outbox_dependency_failure_rolls_back_attempt_and_retry_succeeds(
    database: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    subject = f"dependency-{uuid4()}"
    user_id = create_user(database, subject)
    prepare_due_work(database, user_id)
    repository = MissionRepository(database)
    planned = repository.today(auth(subject), now=NOW)
    assert planned is not None
    started = repository.start(
        auth(subject),
        planned["id"],
        idempotency_key=f"start-{uuid4()}",
        request_hash="5" * 64,
        now=NOW,
    )
    item_id = started["items"][0]["id"]
    question = repository.get_item(auth(subject), planned["id"], item_id)["question"]
    operation_id = uuid4()

    def fail_outbox(*_args, **_kwargs) -> None:
        raise RuntimeError("synthetic outbox dependency failure")

    with monkeypatch.context() as patch:
        patch.setattr(MissionRepository, "_insert_attempt_outbox", fail_outbox)
        with pytest.raises(RuntimeError, match="synthetic outbox dependency failure"):
            repository.submit_attempt(
                auth(subject),
                planned["id"],
                item_id,
                question_version_id=question["question_version_id"],
                answer=SingleChoiceAnswer(type="single_choice", option_keys=["b"]),
                client_operation_id=operation_id,
                request_hash="6" * 64,
                answered_at=NOW,
                offline_submission=False,
                elapsed_ms=500,
                app_version="test",
                correlation_id=uuid4(),
                now=NOW,
            )

    with database.connect() as connection:
        assert (
            connection.scalar(
                text("SELECT count(*) FROM attempts WHERE client_operation_id=:id"),
                {"id": operation_id},
            )
            == 0
        )
        assert (
            connection.scalar(
                text("SELECT status FROM mission_items WHERE id=:id"), {"id": item_id}
            )
            == "presented"
        )

    retried = repository.submit_attempt(
        auth(subject),
        planned["id"],
        item_id,
        question_version_id=question["question_version_id"],
        answer=SingleChoiceAnswer(type="single_choice", option_keys=["b"]),
        client_operation_id=operation_id,
        request_hash="6" * 64,
        answered_at=NOW,
        offline_submission=False,
        elapsed_ms=500,
        app_version="test",
        correlation_id=uuid4(),
        now=NOW,
    )
    assert retried["outcome"] == "recalled"
