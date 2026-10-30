"""Read-endpoint contracts for concept progress and scheduling history (T11).

Covers the three layers that can leak or drift:

* explanation copy: every allowlisted code maps to safe, score-free text;
* service mapping: safe fields only, cursor scoping, 404 for absent state;
* HTTP surface: shared error envelope, bounds, ``no-store`` and no payloads.

Database tests prove owner-negative behaviour and pagination against the real
schema. They skip unless ``MEMORA_TEST_DATABASE_URL`` targets a disposable
database.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID, uuid4

import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr

from memora.api.errors import ApiError
from memora.api.security import AuthContext, AuthenticatedRequest, get_authenticated_request
from memora.api.v1.schemas.common import Page
from memora.api.v1.schemas.memory import (
    ConceptHistoryResponse,
    ConceptProgressItem,
    DueReasonExplanation,
    EvidenceSummary,
    SchedulingExplanation,
)
from memora.main import create_app
from memora.modules.memory import selection
from memora.modules.memory.constants import (
    DUE_REASON_TEMPLATE_KEYS,
    MEMORY_EXPLANATION_TEMPLATE_KEYS,
    MEMORY_REASON_CODES,
    SELECTION_REASON_CODES,
    TEMPLATE_RECALL_SUCCESS,
)
from memora.modules.memory.engine.config import DEFAULT_ENGINE_CONFIG
from memora.modules.memory.explanations import (
    DUE_REASON_TEMPLATES,
    TEMPLATE_MESSAGES,
    due_reason,
    explanation_message,
)
from memora.modules.memory.service import (
    HISTORY_CURSOR_SCOPE,
    PROGRESS_CURSOR_SCOPE,
    MemoryService,
    confidence_band,
    get_memory_service,
)

REQUEST_HEADERS = {
    "X-Correlation-ID": "80000000-0000-0000-0000-000000000001",
    "X-Client-Version": "1.0.0",
    "X-Platform": "android",
}
SUBJECT_ID = UUID("20000000-0000-0000-0000-000000000001")
CONCEPT_ID = UUID("40000000-0000-0000-0000-000000000001")
VERSION_ID = UUID("50000000-0000-0000-0000-000000000001")
NOW = datetime(2026, 10, 30, 12, 0, 0, tzinfo=UTC)


def authenticated_request(
    *, subject: str = "90000000-0000-0000-0000-000000000001"
) -> AuthenticatedRequest:
    return AuthenticatedRequest(
        context=AuthContext(
            issuer="https://test-project.supabase.co/auth/v1",
            subject=subject,
            session_id=uuid4(),
            role="authenticated",
            authenticated_at=NOW,
            expires_at=NOW + timedelta(minutes=5),
        ),
        access_token=SecretStr("synthetic-access-token"),
    )


# ---------------------------------------------------------------------------
# explanation copy
# ---------------------------------------------------------------------------


def test_every_selection_reason_maps_to_allowlisted_copy() -> None:
    assert set(DUE_REASON_TEMPLATES) == set(SELECTION_REASON_CODES)
    for reason_code in SELECTION_REASON_CODES:
        explanation = due_reason(reason_code)
        assert explanation.reason_code == reason_code
        assert explanation.template_key in DUE_REASON_TEMPLATE_KEYS
        assert explanation.message
        assert explanation.message == TEMPLATE_MESSAGES[explanation.template_key]


def test_every_decision_template_has_safe_copy() -> None:
    for template_key in MEMORY_EXPLANATION_TEMPLATE_KEYS:
        assert explanation_message(template_key)


def test_unknown_codes_are_rejected() -> None:
    with pytest.raises(ValueError):
        due_reason("model_says_so")
    with pytest.raises(ValueError):
        explanation_message("memory.explanation.invented")


@pytest.mark.parametrize("message", sorted(TEMPLATE_MESSAGES.values()))
def test_messages_avoid_scores_numbers_and_internal_terms(message: str) -> None:
    lowered = message.lower()
    assert not any(character.isdigit() for character in message)
    assert "%" not in message
    for internal in ("score", "stability", "difficulty", "payload", "engine", "model"):
        assert internal not in lowered


# ---------------------------------------------------------------------------
# service mapping (fake repository)
# ---------------------------------------------------------------------------


def candidate(
    *,
    concept_id: UUID = CONCEPT_ID,
    next_review_at: datetime = NOW - timedelta(days=2),
    urgency: str = "overdue",
    selection_reason: str = "forgetting_curve_overdue",
    retrievability: float = 0.42,
    evidence_confidence: float = 0.8,
) -> selection.DueConceptCandidate:
    return selection.DueConceptCandidate(
        concept_id=concept_id,
        concept_version_id=VERSION_ID,
        stable_code="PHYS-MEA-SI-UNITS",
        title="SI units",
        next_review_at=next_review_at,
        last_reviewed_at=next_review_at - timedelta(days=3),
        urgency=urgency,
        overdue_days=2.0,
        retrievability=retrievability,
        retrievability_band=selection.retrievability_band(retrievability),
        forgetting_risk=1.0 - retrievability,
        evidence_confidence=evidence_confidence,
        recent_error_severity=0.0,
        recent_error_count=0,
        lapse_count=0,
        exposure_count=2,
        eligible_review_count=1,
        is_new_concept=False,
        is_comeback=False,
        prerequisite_impact=2,
        weak_prerequisite_concept_ids=(),
        coverage_objective_ids=(),
        selection_reason=selection_reason,
    )


class FakeReadRepository:
    def __init__(self) -> None:
        self.subject_found = True
        self.state: dict[str, Any] | None = None
        self.candidates: tuple[selection.DueConceptCandidate, ...] = ()
        self.next_cursor: str | None = None
        self.decisions: list[dict[str, Any]] = []
        self.has_more = False
        self.evidence: list[dict[str, Any]] = []
        self.requested_cursor_scope: str | None = None

    def subject_exists(self, _: AuthContext, __: UUID) -> bool:
        return self.subject_found

    def due_page(self, _: AuthContext, **kwargs: Any) -> selection.DueSelectionPage:
        self.requested_cursor_scope = kwargs["cursor_scope"]
        return selection.DueSelectionPage(
            subject_id=SUBJECT_ID,
            as_of=NOW,
            horizon_days=kwargs["horizon_days"],
            candidates=self.candidates,
            next_cursor=self.next_cursor,
        )

    def concept_state(self, _: AuthContext, __: UUID) -> dict[str, Any] | None:
        return self.state

    def list_decisions(
        self,
        _: AuthContext,
        __: UUID,
        *,
        limit: int,
        before: tuple[datetime, UUID] | None,
    ) -> tuple[list[dict[str, Any]], bool]:
        return self.decisions[:limit], self.has_more

    def evidence_summary(
        self, auth: AuthContext, concept_id: UUID, **kwargs: Any
    ) -> list[dict[str, Any]]:
        return self.evidence


def state_row() -> dict[str, Any]:
    return {
        "concept_id": CONCEPT_ID,
        "concept_version_id": VERSION_ID,
        "stable_code": "PHYS-MEA-SI-UNITS",
        "title": "SI units",
        "stability_days": 4.0,
        "evidence_confidence": 0.82,
        "first_exposed_at": NOW - timedelta(days=30),
        "last_reviewed_at": NOW - timedelta(days=10),
        "next_review_at": NOW - timedelta(days=1),
        "exposure_count": 3,
        "eligible_review_count": 2,
        "lapse_count": 0,
    }


def decision_row(*, decision_id: UUID | None = None, decided_at: datetime | None = None) -> dict:
    return {
        "id": decision_id or uuid4(),
        "decided_at": decided_at or NOW - timedelta(days=1),
        "trigger_event_type": "attempt",
        "next_review_at": NOW + timedelta(days=3),
        "reason_codes": ["recall_success", "review_scheduled"],
        "explanation_template_key": TEMPLATE_RECALL_SUCCESS,
        "engine_version": DEFAULT_ENGINE_CONFIG.engine_version,
        "policy_version": DEFAULT_ENGINE_CONFIG.policy_version,
    }


def service_with(repository: FakeReadRepository) -> MemoryService:
    return MemoryService(repository, clock=lambda: NOW)


def test_progress_projects_safe_fields_and_due_reason() -> None:
    repository = FakeReadRepository()
    repository.candidates = (candidate(),)

    page = service_with(repository).list_concept_progress(
        authenticated_request(),
        SUBJECT_ID,
        horizon_days=3.0,
        limit=20,
        cursor=None,
    )

    item = page.items[0]
    assert page.has_more is False and page.next_cursor is None
    assert item.concept_id == CONCEPT_ID
    assert item.state_band == "fading"
    assert item.confidence_band == "high"
    assert item.review_window == "overdue"
    assert item.due_reason.reason_code == "forgetting_curve_overdue"
    assert item.due_reason.template_key == "memory.due_reason.overdue"
    assert repository.requested_cursor_scope == PROGRESS_CURSOR_SCOPE
    # Ranking inputs and raw state values never cross the boundary.
    dumped = item.model_dump()
    for hidden in (
        "forgetting_risk",
        "retrievability",
        "recent_error_severity",
        "recent_error_count",
        "prerequisite_impact",
        "weak_prerequisite_concept_ids",
        "stability_days",
    ):
        assert hidden not in dumped


def test_progress_unknown_subject_is_not_found() -> None:
    repository = FakeReadRepository()
    repository.subject_found = False

    with pytest.raises(ApiError) as raised:
        service_with(repository).list_concept_progress(
            authenticated_request(), SUBJECT_ID, horizon_days=3.0, limit=20, cursor=None
        )

    assert raised.value.status_code == 404
    assert raised.value.code == "resource_not_found"


def test_progress_rejects_a_cursor_from_another_scope() -> None:
    repository = FakeReadRepository()
    foreign = selection.encode_cursor(NOW, CONCEPT_ID, scope=f"{HISTORY_CURSOR_SCOPE}/{CONCEPT_ID}")

    with pytest.raises(ApiError) as raised:
        service_with(repository).list_concept_progress(
            authenticated_request(), SUBJECT_ID, horizon_days=3.0, limit=20, cursor=foreign
        )

    assert raised.value.status_code == 400
    assert raised.value.code == "invalid_cursor"


def test_history_is_not_found_for_an_unknown_concept() -> None:
    with pytest.raises(ApiError) as raised:
        service_with(FakeReadRepository()).get_concept_history(
            authenticated_request(), CONCEPT_ID, limit=20, cursor=None
        )

    assert raised.value.status_code == 404
    assert raised.value.code == "resource_not_found"


def test_history_folds_evidence_and_pages_explanations() -> None:
    repository = FakeReadRepository()
    repository.state = state_row()
    newest = decision_row(decided_at=NOW - timedelta(days=1))
    older = decision_row(decided_at=NOW - timedelta(days=8))
    repository.decisions = [newest, older]
    repository.has_more = True
    repository.evidence = [
        {
            "event_type": "attempt",
            "total_count": 4,
            "eligible_count": 4,
            "recent_count": 3,
            "last_observed_at": NOW - timedelta(days=1),
        },
        {
            "event_type": "exposure",
            "total_count": 1,
            "eligible_count": 1,
            "recent_count": 0,
            "last_observed_at": NOW - timedelta(days=30),
        },
    ]

    history = service_with(repository).get_concept_history(
        authenticated_request(), CONCEPT_ID, limit=1, cursor=None
    )

    assert history.has_more is True and history.next_cursor is not None
    assert history.state_band in {"fresh", "settling", "fading", "critical"}
    assert history.evidence.total_events == 5
    assert history.evidence.recent_events == 3
    assert history.evidence.eligible_events == 5
    assert history.evidence.counts_by_type == {"attempt": 4, "exposure": 1}
    assert history.evidence.total_events == sum(history.evidence.counts_by_type.values())
    assert history.evidence.last_observed_at == NOW - timedelta(days=1)
    assert history.evidence.confidence_band == "high"
    assert len(history.items) == 1
    assert history.items[0].decision_id == newest["id"]
    assert history.items[0].message
    assert "payload" not in history.model_dump_json()

    # The emitted cursor is bound to this concept and can be replayed.
    decoded_at, decoded_id = selection.decode_cursor(
        history.next_cursor, scope=f"{HISTORY_CURSOR_SCOPE}/{CONCEPT_ID}"
    )
    assert decoded_at == newest["decided_at"]
    assert decoded_id == newest["id"]


def test_history_rejects_a_cursor_from_another_concept() -> None:
    repository = FakeReadRepository()
    repository.state = state_row()
    foreign = selection.encode_cursor(NOW, CONCEPT_ID, scope=f"{HISTORY_CURSOR_SCOPE}/{uuid4()}")

    with pytest.raises(ApiError) as raised:
        service_with(repository).get_concept_history(
            authenticated_request(), CONCEPT_ID, limit=20, cursor=foreign
        )

    assert raised.value.status_code == 400
    assert raised.value.code == "invalid_cursor"


def test_confidence_bands_are_ordered() -> None:
    assert confidence_band(1.0) == "high"
    assert confidence_band(0.75) == "high"
    assert confidence_band(0.74) == "medium"
    assert confidence_band(0.5) == "medium"
    assert confidence_band(0.49) == "low"


# ---------------------------------------------------------------------------
# HTTP surface (fake service)
# ---------------------------------------------------------------------------


class FakeApiService:
    def __init__(self) -> None:
        self.error: ApiError | None = None
        self.progress_page = Page[ConceptProgressItem](items=[], next_cursor=None, has_more=False)
        self.history = ConceptHistoryResponse(
            concept_id=CONCEPT_ID,
            concept_version_id=VERSION_ID,
            stable_code="PHYS-MEA-SI-UNITS",
            title="SI units",
            state_band="fading",
            next_review_at=NOW - timedelta(days=1),
            evidence=EvidenceSummary(
                window_days=90,
                total_events=2,
                recent_events=2,
                eligible_events=2,
                counts_by_type={"exposure": 1, "attempt": 1},
                last_observed_at=NOW - timedelta(days=1),
                confidence_band="high",
            ),
            items=[
                SchedulingExplanation(
                    decision_id=uuid4(),
                    decided_at=NOW - timedelta(days=1),
                    trigger_event_type="attempt",
                    next_review_at=NOW + timedelta(days=3),
                    reason_codes=["recall_success"],
                    template_key=TEMPLATE_RECALL_SUCCESS,
                    message="You recalled this concept, so the next review moved further out.",
                    engine_version=DEFAULT_ENGINE_CONFIG.engine_version,
                    policy_version=DEFAULT_ENGINE_CONFIG.policy_version,
                )
            ],
            next_cursor=None,
            has_more=False,
        )

    def list_concept_progress(
        self, request: Any, subject_id: UUID, **kwargs: Any
    ) -> Page[ConceptProgressItem]:
        if self.error is not None:
            raise self.error
        return self.progress_page

    def get_concept_history(
        self, request: Any, concept_id: UUID, **kwargs: Any
    ) -> ConceptHistoryResponse:
        if self.error is not None:
            raise self.error
        return self.history


def client_for(fake: FakeApiService) -> TestClient:
    app = create_app()
    app.dependency_overrides[get_authenticated_request] = authenticated_request
    app.dependency_overrides[get_memory_service] = lambda: fake
    return TestClient(app)


def test_progress_route_returns_bounded_safe_payload() -> None:
    fake = FakeApiService()
    fake.progress_page = Page[ConceptProgressItem](
        items=[
            ConceptProgressItem(
                concept_id=CONCEPT_ID,
                concept_version_id=VERSION_ID,
                stable_code="PHYS-MEA-SI-UNITS",
                title="SI units",
                state_band="fading",
                confidence_band="medium",
                review_window="overdue",
                next_review_at=NOW - timedelta(days=2),
                last_reviewed_at=NOW - timedelta(days=5),
                exposure_count=2,
                eligible_review_count=1,
                lapse_count=0,
                is_new_concept=False,
                is_comeback=False,
                due_reason=DueReasonExplanation(
                    reason_code="forgetting_curve_overdue",
                    template_key="memory.due_reason.overdue",
                    message="This review is overdue. A short review now brings it back on track.",
                ),
            )
        ],
        next_cursor=None,
        has_more=False,
    )

    response = client_for(fake).get(
        f"/v1/subjects/{SUBJECT_ID}/concept-progress",
        headers=REQUEST_HEADERS,
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["has_more"] is False
    assert payload["items"][0]["due_reason"]["reason_code"] == "forgetting_curve_overdue"
    assert payload["items"][0]["next_review_at"].endswith("Z")
    for hidden in ("forgetting_risk", "retrievability", "event_payload", "stability_days"):
        assert hidden not in response.text


def test_progress_route_validates_limit_and_horizon() -> None:
    client = client_for(FakeApiService())

    for query in ("limit=0", "limit=51", "horizon_days=0", "horizon_days=31"):
        response = client.get(
            f"/v1/subjects/{SUBJECT_ID}/concept-progress?{query}",
            headers=REQUEST_HEADERS,
        )
        assert response.status_code == 422
        assert response.json()["error"]["code"] == "validation_failed"


def test_history_route_returns_not_found_envelope() -> None:
    fake = FakeApiService()
    fake.error = ApiError(404, "resource_not_found", "Concept was not found.")

    response = client_for(fake).get(
        f"/v1/concepts/{CONCEPT_ID}/history",
        headers=REQUEST_HEADERS,
    )

    assert response.status_code == 404
    assert response.json()["error"]["code"] == "resource_not_found"
    assert response.json()["error"]["request_id"]


def test_routes_are_private_no_store() -> None:
    client = client_for(FakeApiService())

    for path in (
        f"/v1/subjects/{SUBJECT_ID}/concept-progress",
        f"/v1/concepts/{CONCEPT_ID}/history",
    ):
        response = client.get(path, headers=REQUEST_HEADERS)
        assert response.status_code == 200
        assert response.headers["Cache-Control"] == "private, no-store"


# ---------------------------------------------------------------------------
# database-backed owner scoping and pagination
# ---------------------------------------------------------------------------

DISPOSABLE_DATABASE_SUFFIXES = ("_test", "_ci")
DAY = timedelta(days=1)


@pytest.fixture
def database(monkeypatch: pytest.MonkeyPatch):
    import os

    from alembic import command
    from sqlalchemy import create_engine
    from sqlalchemy.engine import make_url

    from test_memory_persistence import alembic_config

    database_url = os.getenv("MEMORA_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("MEMORA_TEST_DATABASE_URL is not configured")
    database_name = make_url(database_url).database or ""
    if not database_name.endswith(DISPOSABLE_DATABASE_SUFFIXES):
        pytest.fail(
            "MEMORA_TEST_DATABASE_URL must target a disposable database ending in "
            f"{' or '.join(DISPOSABLE_DATABASE_SUFFIXES)}",
            pytrace=False,
        )

    monkeypatch.setenv("MEMORA_DATABASE_URL", database_url)
    from memora.db.seed import seed_database

    command.upgrade(alembic_config(database_url), "head")
    seed_database(database_url)
    engine = create_engine(database_url, connect_args={"connect_timeout": 10})
    try:
        yield engine
    finally:
        engine.dispose()


@pytest.fixture
def now(database) -> datetime:
    return datetime.now(UTC).replace(microsecond=0)


def create_learner(engine, subject: str | None = None) -> tuple[UUID, AuthenticatedRequest]:
    from sqlalchemy import text

    oidc_subject = subject or f"synthetic-{uuid4()}"
    with engine.begin() as connection:
        user_id = connection.scalar(
            text(
                """
                INSERT INTO users(oidc_issuer, oidc_subject, status, default_timezone, locale)
                VALUES ('https://test-project.supabase.co/auth/v1', :subject, 'active',
                        'Asia/Colombo', 'en')
                RETURNING id
                """
            ),
            {"subject": oidc_subject},
        )
    return UUID(str(user_id)), authenticated_request(subject=oidc_subject)


def physics_subject(engine) -> UUID:
    from sqlalchemy import text

    with engine.begin() as connection:
        return UUID(str(connection.scalar(text("SELECT id FROM subjects WHERE code = 'physics'"))))


def concepts(engine, *, limit: int = 3) -> list[tuple[UUID, UUID, str]]:
    from sqlalchemy import text

    with engine.begin() as connection:
        rows = (
            connection.execute(
                text(
                    """
                    SELECT c.id AS concept_id, cv.id AS version_id, c.stable_code
                    FROM concepts c
                    JOIN concept_versions cv ON cv.concept_id = c.id AND cv.version_no = 1
                    WHERE c.status = 'approved'
                      AND c.subject_id = (SELECT id FROM subjects WHERE code = 'physics')
                    ORDER BY c.stable_code
                    LIMIT :limit
                    """
                ),
                {"limit": limit},
            )
            .mappings()
            .all()
        )
    return [
        (UUID(str(row["concept_id"])), UUID(str(row["version_id"])), row["stable_code"])
        for row in rows
    ]


def expose_and_score(engine, *, user_id: UUID, concept_id: UUID, version_id: UUID, at: datetime):
    from test_memory_persistence import apply, attempt, exposure

    event, source_id = exposure(observed_at=at)
    apply(
        engine,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=event,
        source_id=source_id,
        now=at,
    )
    event, source_id = attempt(score=0.4, observed_at=at)
    apply(
        engine,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=event,
        source_id=source_id,
        now=at,
    )


def db_service(engine, now: datetime) -> MemoryService:
    from memora.modules.memory.service import MemoryReadRepository

    return MemoryService(MemoryReadRepository(engine), clock=lambda: now)


def test_owner_cannot_read_another_learners_progress_or_history(database, now: datetime) -> None:
    subject_id = physics_subject(database)
    concept_id, version_id, _ = concepts(database, limit=1)[0]
    owner_id, owner = create_learner(database)
    _, stranger = create_learner(database)
    expose_and_score(
        database, user_id=owner_id, concept_id=concept_id, version_id=version_id, at=now
    )

    owner_page = db_service(database, now).list_concept_progress(
        owner, subject_id, horizon_days=3.0, limit=20, cursor=None
    )
    stranger_page = db_service(database, now).list_concept_progress(
        stranger, subject_id, horizon_days=3.0, limit=20, cursor=None
    )

    assert [item.concept_id for item in owner_page.items] == [concept_id]
    assert stranger_page.items == []

    with pytest.raises(ApiError) as raised:
        db_service(database, now).get_concept_history(stranger, concept_id, limit=20, cursor=None)
    assert raised.value.status_code == 404
    assert raised.value.code == "resource_not_found"


def test_unknown_subject_and_concept_return_404(database, now: datetime) -> None:
    _, learner = create_learner(database)
    service = db_service(database, now)

    with pytest.raises(ApiError) as subject_error:
        service.list_concept_progress(learner, uuid4(), horizon_days=3.0, limit=20, cursor=None)
    assert subject_error.value.status_code == 404

    with pytest.raises(ApiError) as concept_error:
        service.get_concept_history(learner, uuid4(), limit=20, cursor=None)
    assert concept_error.value.status_code == 404


def test_progress_pagination_covers_each_concept_once(database, now: datetime) -> None:
    subject_id = physics_subject(database)
    user_id, learner = create_learner(database)
    seeded = concepts(database, limit=5)
    for concept_id, version_id, _ in seeded:
        expose_and_score(
            database,
            user_id=user_id,
            concept_id=concept_id,
            version_id=version_id,
            at=now - 2 * DAY,
        )

    service = db_service(database, now)
    seen: list[UUID] = []
    cursor = None
    pages = 0
    while True:
        page = service.list_concept_progress(
            learner, subject_id, horizon_days=3.0, limit=2, cursor=cursor
        )
        assert len(page.items) <= 2
        seen.extend(item.concept_id for item in page.items)
        pages += 1
        cursor = page.next_cursor
        if cursor is None:
            break
        assert pages < 6

    assert pages == 3
    assert len(seen) == len(seeded)
    assert len(set(seen)) == len(seeded)


def test_history_returns_decisions_newest_first_without_payloads(database, now: datetime) -> None:
    user_id, learner = create_learner(database)
    concept_id, version_id, _ = concepts(database, limit=1)[0]
    expose_and_score(
        database, user_id=user_id, concept_id=concept_id, version_id=version_id, at=now - DAY
    )
    expose_and_score(
        database, user_id=user_id, concept_id=concept_id, version_id=version_id, at=now
    )

    history = db_service(database, now).get_concept_history(
        learner, concept_id, limit=20, cursor=None
    )

    assert history.concept_id == concept_id
    assert history.state_band in {"fresh", "settling", "fading", "critical"}
    assert history.evidence.total_events == 4
    assert history.evidence.eligible_events == 4
    assert history.evidence.total_events == sum(history.evidence.counts_by_type.values())
    assert set(history.evidence.counts_by_type) <= {
        "exposure",
        "attempt",
        "repair",
        "regrade",
        "invalidation",
        "manual_review",
    }
    assert len(history.items) == 4
    decided = [item.decided_at for item in history.items]
    assert decided == sorted(decided, reverse=True)
    for item in history.items:
        assert set(item.reason_codes) <= set(MEMORY_REASON_CODES)
        assert item.template_key in MEMORY_EXPLANATION_TEMPLATE_KEYS
        assert item.engine_version == DEFAULT_ENGINE_CONFIG.engine_version
        assert item.policy_version == DEFAULT_ENGINE_CONFIG.policy_version
    dumped = history.model_dump_json()
    for hidden in ("event_payload", "previous_state", "result_state", "stability_days"):
        assert hidden not in dumped
