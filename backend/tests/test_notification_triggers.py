"""Producer-emission contracts for notification trigger events (T19 Commit 5).

Drives each merged producer through its real entry point and proves the
trigger event lands in the outbox within the same committed transaction,
carrying identifiers and safe bounded parameters only:

* ``mission.ready`` — materialized by ``MissionRepository.today`` (T13);
* ``ingestion.learning_path_committed`` — written by the learning-path
  commit (T09) next to ``learning_update.committed``;
* ``ingestion.verification_required`` — written when extraction finishes
  with pending verification requests (T09 worker);
* ``privacy.export_ready`` — written when the export job completes (T20).

Skips unless MEMORA_TEST_DATABASE_URL targets a disposable database.
"""

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

from memora.api.security import AuthContext, AuthenticatedRequest
from memora.api.v1.schemas.ingestion import CreateLearningUpdateRequest
from memora.api.v1.schemas.privacy import PrivacyExportRequest
from memora.core.config import Settings
from memora.db.seed import seed_database
from memora.modules.ingestion.extraction import ExtractedCandidate
from memora.modules.ingestion.repository import IngestionRepository
from memora.modules.ingestion.service import IngestionService, ManualTextProtector
from memora.modules.ingestion.storage import MemoryObjectStorage
from memora.modules.missions.repository import MissionRepository
from memora.modules.privacy.repository import PrivacyRepository
from memora.modules.privacy.service import PrivacyService
from memora.modules.questions.models import QuestionImportBundle
from memora.modules.questions.repository import QuestionImportRepository
from memora.modules.questions.validation import validate_question_import
from memora.worker.ingestion import IngestionWorker
from memora.worker.main import run_worker_once

BACKEND_ROOT = Path(__file__).resolve().parents[1]
PHYSICS_SUBJECT_ID = UUID("10000000-0000-0000-0000-000000000001")
CURRICULUM_ID = UUID("20000000-0000-0000-0000-000000000001")
INGESTION_KEY = "cGe/2UxRnTY3D17CPcFSnrHkGqBSwmcmJ+ehN4XFMxc="
ISSUER = "https://notification-triggers.test"
MISSION_NOW = datetime(2026, 11, 1, 6, tzinfo=UTC)


def alembic_config(database_url: str) -> Config:
    config = Config(os.path.join(BACKEND_ROOT, "alembic.ini"))
    config.set_main_option("script_location", os.path.join(BACKEND_ROOT, "migrations"))
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

    if not database_name.endswith(("_test", "_ci")):
        pytest.fail("MEMORA_TEST_DATABASE_URL must target a disposable database", pytrace=False)

    monkeypatch.setenv("MEMORA_DATABASE_URL", database_url)
    command.upgrade(alembic_config(database_url), "head")
    seed_database(database_url)
    engine = create_engine(database_url, connect_args={"connect_timeout": 10})
    try:
        yield engine
    finally:
        engine.dispose()


@pytest.fixture(autouse=True)
def clean_workflow_tables(database: Engine) -> Iterator[None]:
    """Start every trigger test from a clean workflow slate (T09 convention)."""

    with database.begin() as connection:
        connection.execute(
            text(
                "TRUNCATE background_jobs, outbox_events, learning_updates, "
                "source_uploads, extraction_candidates, verification_requests, "
                "verification_decisions, knowledge_commits, private_knowledge_items, "
                "deletion_proofs, idempotency_records, audit_events, missions, "
                "mission_items, attempts, grading_results CASCADE"
            )
        )
    yield


def auth_context(subject: str) -> AuthenticatedRequest:
    now = datetime.now(UTC)
    return AuthenticatedRequest(
        context=AuthContext(
            issuer=ISSUER,
            subject=subject,
            session_id=uuid4(),
            role="authenticated",
            authenticated_at=now,
            expires_at=now + timedelta(minutes=10),
        ),
        access_token=SecretStr("synthetic-token"),
    )


def create_user(engine: Engine, subject: str) -> UUID:
    with engine.begin() as connection:
        user_id = connection.scalar(
            text(
                """
                INSERT INTO users(
                    oidc_issuer, oidc_subject, status, default_timezone, locale
                ) VALUES (:issuer, :subject, 'active', 'Asia/Colombo', 'en-LK')
                RETURNING id
                """
            ),
            {"issuer": ISSUER, "subject": subject},
        )
        for consent_type in ("terms", "privacy", "material_processing", "model_processing"):
            connection.execute(
                text(
                    """
                    INSERT INTO consent_records(
                        user_id, consent_type, policy_version, decision, decided_at, evidence
                    ) VALUES (
                        :user_id, :consent_type, 'synthetic-v1', 'granted', now(),
                        '{"schema_version":"1"}'
                    )
                    """
                ),
                {"user_id": user_id, "consent_type": consent_type},
            )
    return UUID(str(user_id))


def outbox_rows(engine: Engine, event_type: str, *, aggregate_id: UUID | None = None) -> list[dict]:
    with engine.connect() as connection:
        rows = connection.execute(
            text(
                """
                SELECT payload, domain_event_key
                FROM outbox_events
                WHERE event_type = :event_type
                  AND (CAST(:aggregate_id AS uuid) IS NULL OR aggregate_id = CAST(:aggregate_id AS uuid))
                """
            ),
            {"event_type": event_type, "aggregate_id": aggregate_id},
        ).mappings()
        return [dict(row) for row in rows]


# ---------------------------------------------------------------------------
# missions.today -> mission.ready
# ---------------------------------------------------------------------------


def first_concept(engine: Engine) -> tuple[UUID, UUID]:
    with engine.connect() as connection:
        row = (
            connection.execute(
                text(
                    """
                    SELECT c.id AS concept_id, cv.id AS version_id
                    FROM concepts c
                    JOIN concept_versions cv ON cv.concept_id = c.id
                    WHERE c.subject_id = :subject_id AND c.status = 'approved'
                      AND cv.content_status = 'approved'
                    ORDER BY c.stable_code, cv.version_no DESC LIMIT 1
                    """
                ),
                {"subject_id": PHYSICS_SUBJECT_ID},
            )
            .mappings()
            .one()
        )
    return UUID(str(row["concept_id"])), UUID(str(row["version_id"]))


def question_bundle(concept_version_id: UUID, code: str) -> QuestionImportBundle:
    return QuestionImportBundle.model_validate(
        {
            "question_code": code,
            "subject_id": PHYSICS_SUBJECT_ID,
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
                    "provenance_ref": "synthetic-trigger-review",
                }
            ],
        }
    )


def prepare_due_work(engine: Engine, user_id: UUID) -> None:
    concept_id, concept_version_id = first_concept(engine)
    importer = QuestionImportRepository(engine)
    for suffix in ("primary", "repair"):
        importer.import_question(
            validate_question_import(
                question_bundle(concept_version_id, f"trigger-{suffix}-{uuid4().hex[:8]}")
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
                "first_exposed": MISSION_NOW - timedelta(days=2),
                "next_review": MISSION_NOW - timedelta(hours=1),
            },
        )


def test_today_materialization_emits_mission_ready_trigger(database: Engine) -> None:
    subject = f"trigger-mission-{uuid4()}"
    user_id = create_user(database, subject)
    prepare_due_work(database, user_id)
    repository = MissionRepository(database)

    planned = repository.today(auth_context(subject).context, now=MISSION_NOW)
    assert planned is not None

    events = outbox_rows(database, "mission.ready", aggregate_id=UUID(str(planned["id"])))
    assert len(events) == 1
    payload = events[0]["payload"]
    assert payload["schema_version"] == "1"
    assert payload["user_id"] == str(user_id)
    assert payload["mission_id"] == str(planned["id"])
    assert payload["count"] == planned["estimated_minutes"]

    # Replay materializes nothing new: same mission, same single event.
    replayed = repository.today(auth_context(subject).context, now=MISSION_NOW)
    assert replayed is not None
    assert replayed["id"] == planned["id"]
    assert len(outbox_rows(database, "mission.ready")) == 1


# ---------------------------------------------------------------------------
# ingestion commit -> ingestion.learning_path_committed
# ---------------------------------------------------------------------------


class FixedExtractionProvider:
    model_key = "fixed-trigger-provider"
    prompt_version = "v1"

    def __init__(self, candidates: list[ExtractedCandidate]) -> None:
        self.candidates = candidates

    def extract(self, **_: Any) -> list[ExtractedCandidate]:
        return list(self.candidates)


def build_ingestion_harness(database: Engine) -> dict[str, Any]:
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
    return {
        "settings": settings,
        "storage": storage,
        "protector": protector,
        "repository": IngestionRepository(database),
        "service": IngestionService(IngestionRepository(database), storage, settings, protector),
    }


def create_manual_update(
    harness: dict[str, Any], subject: str
) -> tuple[AuthenticatedRequest, UUID]:
    service = harness["service"]
    auth = auth_context(subject)
    update = service.create(
        auth,
        CreateLearningUpdateRequest(
            subject_id=PHYSICS_SUBJECT_ID,
            input_type="manual_text",
            learned_at=datetime.now(UTC),
            client_operation_id=uuid4(),
            manual_text="Trigger emission synthetic note.",
        ),
        idempotency_key=str(uuid4()),
    )
    return auth, update.id


def verified_candidate(database: Engine) -> ExtractedCandidate:
    with database.connect() as connection:
        alias = (
            connection.execute(
                text(
                    """
                    SELECT ca.concept_version_id, cv.concept_id, cv.title
                    FROM concept_aliases ca
                    JOIN concept_versions cv ON cv.id = ca.concept_version_id
                    JOIN concepts c ON c.id = cv.concept_id
                    WHERE c.subject_id = :subject_id AND c.status = 'approved'
                    LIMIT 1
                    """
                ),
                {"subject_id": PHYSICS_SUBJECT_ID},
            )
            .mappings()
            .first()
        )
    return ExtractedCandidate(
        candidate_type="concept",
        payload={
            "title": alias["title"],
            "concept_id": str(alias["concept_id"]),
            "concept_version_id": str(alias["concept_version_id"]),
        },
        source_locator={"kind": "text_range", "start": 0, "end": 10},
        confidence=0.90,
    )


def test_commit_emits_learning_path_ready_trigger(database: Engine) -> None:
    harness = build_ingestion_harness(database)
    subject = f"trigger-commit-{uuid4()}"
    user_id = create_user(database, subject)
    auth, update_id = create_manual_update(harness, subject)

    worker = IngestionWorker(
        database,
        harness["settings"],
        storage=harness["storage"],
        protector=harness["protector"],
        extractor=FixedExtractionProvider([verified_candidate(database)]),
        worker_id=f"trigger-worker-{uuid4()}",
    )
    assert worker.run_once() is True

    service = harness["service"]
    committed = service.commit(auth, update_id, idempotency_key=str(uuid4()))
    assert committed.learning_update.status == "committed"

    events = outbox_rows(database, "ingestion.learning_path_committed", aggregate_id=update_id)
    assert len(events) == 1
    payload = events[0]["payload"]
    assert payload["schema_version"] == "1"
    assert payload["user_id"] == str(user_id)
    assert payload["update_id"] == str(update_id)
    assert payload["count"] == 1  # one committed concept

    # The pre-existing T09 event still fires alongside.
    assert len(outbox_rows(database, "learning_update.committed", aggregate_id=update_id)) == 1


def test_extraction_emits_verification_required_trigger(database: Engine) -> None:
    harness = build_ingestion_harness(database)
    subject = f"trigger-verify-{uuid4()}"
    create_user(database, subject)
    auth, update_id = create_manual_update(harness, subject)

    low_confidence = ExtractedCandidate(
        candidate_type="concept",
        payload={
            "title": "Synthetic low-confidence concept",
            "concept_id": str(uuid4()),
            "concept_version_id": str(uuid4()),
        },
        source_locator={"kind": "text_range", "start": 0, "end": 10},
        confidence=0.30,  # below the review floor: needs verification
    )
    worker = IngestionWorker(
        database,
        harness["settings"],
        storage=harness["storage"],
        protector=harness["protector"],
        extractor=FixedExtractionProvider([low_confidence]),
        worker_id=f"trigger-worker-{uuid4()}",
    )
    assert worker.run_once() is True

    events = outbox_rows(database, "ingestion.verification_required", aggregate_id=update_id)
    assert len(events) == 1
    payload = events[0]["payload"]
    assert payload["schema_version"] == "1"
    assert payload["update_id"] == str(update_id)
    assert UUID(payload["user_id"])
    assert set(payload) == {"schema_version", "user_id", "update_id"}


# ---------------------------------------------------------------------------
# privacy export completion -> privacy.export_ready
# ---------------------------------------------------------------------------


def test_export_completion_emits_export_ready_trigger(
    database: Engine, tmp_path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setenv("MEMORA_EXPORT_STORAGE_DIR", str(tmp_path))
    subject = f"trigger-export-{uuid4()}"
    user_id = create_user(database, subject)
    with database.begin() as connection:
        connection.execute(
            text(
                """
                INSERT INTO user_profiles(user_id, display_name)
                VALUES (:user_id, 'Trigger Student')
                """
            ),
            {"user_id": user_id},
        )
        connection.execute(
            text(
                """
                INSERT INTO consent_records(
                    user_id, consent_type, policy_version, decision, decided_at, evidence
                ) VALUES (:user_id, 'terms', '1.0', 'granted', now(),
                          '{"schema_version": "1"}'::jsonb)
                """
            ),
            {"user_id": user_id},
        )

    auth = auth_context(subject)
    service = PrivacyService(PrivacyRepository(database), Settings(recent_auth_window_seconds=600))
    export = service.create_export(auth, PrivacyExportRequest(), idempotency_key=str(uuid4()))

    processed = run_worker_once(database, limit=5)
    assert processed >= 1

    events = outbox_rows(database, "privacy.export_ready", aggregate_id=export.id)
    assert len(events) == 1
    payload = events[0]["payload"]
    assert payload["schema_version"] == "1"
    assert payload["user_id"] == str(user_id)
    assert payload["request_id"] == str(export.id)

    # Remove this test's completed request so shared-database runs do not
    # accumulate expired exports for the privacy suite's reconcile counts.
    with database.begin() as connection:
        connection.execute(
            text("DELETE FROM privacy_requests WHERE id = :id"), {"id": export.id}
        )
