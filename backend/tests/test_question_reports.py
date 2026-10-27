from __future__ import annotations

import base64
import json
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID, uuid4

import pytest
from cryptography.exceptions import InvalidTag
from fastapi.testclient import TestClient
from pydantic import SecretStr, ValidationError

from memora.api.errors import ApiError
from memora.api.security import AuthContext, AuthenticatedRequest, get_authenticated_request
from memora.api.v1.schemas.common import Page
from memora.api.v1.schemas.question_reports import (
    QuestionReportCreateRequest,
    QuestionReportResponse,
    QuestionReportSummary,
)
from memora.core.config import Settings
from memora.main import create_app
from memora.modules.questions.service import (
    QuestionService,
    ReportDescriptionProtector,
    _decode_report_cursor,
    _encode_report_cursor,
    _report_owner,
    get_question_service,
)

QUESTION_VERSION_ID = UUID("50000000-0000-0000-0000-000000000001")
ATTEMPT_ID = UUID("70000000-0000-0000-0000-000000000001")
CORRELATION_ID = "80000000-0000-0000-0000-000000000001"
IDEMPOTENCY_KEY = "test-key-test-key"
REQUEST_HEADERS = {
    "X-Correlation-ID": CORRELATION_ID,
    "X-Client-Version": "1.0.0",
    "X-Platform": "android",
}


def authenticated_request() -> AuthenticatedRequest:
    now = datetime.now(UTC)
    return AuthenticatedRequest(
        context=AuthContext(
            issuer="https://test-project.supabase.co/auth/v1",
            subject="90000000-0000-0000-0000-000000000001",
            session_id=uuid4(),
            role="authenticated",
            authenticated_at=now,
            expires_at=now + timedelta(minutes=5),
        ),
        access_token=SecretStr("synthetic-access-token"),
    )


def report_row(
    *,
    report_id: UUID | None = None,
    report_type: str = "question_error",
    status: str = "submitted",
    attempt_id: UUID | None = None,
    description_present: bool = False,
    submitted_at: datetime | None = None,
) -> dict[str, Any]:
    return {
        "id": report_id or uuid4(),
        "question_version_id": QUESTION_VERSION_ID,
        "attempt_id": attempt_id,
        "report_type": report_type,
        "status": status,
        "resolution_code": None,
        "submitted_at": submitted_at or datetime.now(UTC),
        "resolved_at": None,
        "description_present": description_present,
    }


class FakeReportRepository:
    def __init__(self) -> None:
        self.created: dict[str, Any] | None = None
        self.before: tuple[datetime, UUID] | None = None
        self.rows: list[dict[str, Any]] = []
        self.has_more = False
        self.missing = False

    def create_report(self, _: AuthContext, **values: Any) -> tuple[dict[str, Any], bool]:
        self.created = values
        return (
            report_row(
                report_id=values["report_id"],
                report_type=values["report_type"],
                attempt_id=values["attempt_id"],
                description_present=values["description_ciphertext"] is not None,
                submitted_at=values["submitted_at"],
            ),
            True,
        )

    def list_reports(
        self,
        _: AuthContext,
        *,
        limit: int,
        before: tuple[datetime, UUID] | None,
    ) -> tuple[list[dict[str, Any]], bool]:
        self.before = before
        return self.rows[:limit], self.has_more

    def get_report(self, _: AuthContext, *, report_id: UUID) -> dict[str, Any] | None:
        if self.missing:
            return None
        return report_row(report_id=report_id)


def service_settings() -> Settings:
    key = base64.b64encode(b"k" * 32).decode("ascii")
    return Settings(_env_file=None, device_encryption_key=key)


def test_report_description_encryption_is_random_and_owner_bound() -> None:
    protector = ReportDescriptionProtector(b"k" * 32)
    owner = b"synthetic-owner"

    first = protector.protect("private synthetic description", owner=owner)
    second = protector.protect("private synthetic description", owner=owner)

    assert first != second
    assert b"private synthetic description" not in first
    assert protector.reveal(first, owner=owner) == "private synthetic description"
    with pytest.raises(InvalidTag):
        protector.reveal(first, owner=b"other-owner")


def test_report_encryption_key_must_be_32_bytes() -> None:
    with pytest.raises(ValueError):
        ReportDescriptionProtector(b"short")


def test_cursor_round_trip_and_invalid_cursor_are_safe() -> None:
    submitted_at = datetime.now(UTC).replace(microsecond=123456)
    report_id = uuid4()

    def cursor_for(payload: object) -> str:
        encoded = json.dumps(payload).encode("utf-8")
        return base64.urlsafe_b64encode(encoded).decode("ascii").rstrip("=")

    nested = base64.urlsafe_b64encode(b"[" * 5000 + b"]" * 5000).decode("ascii").rstrip("=")

    cursor = _encode_report_cursor(submitted_at, report_id)

    assert "=" not in cursor
    decoded_at, decoded_id = _decode_report_cursor(cursor)
    assert decoded_at == submitted_at
    assert decoded_id == report_id

    for invalid in (
        "not-a-cursor",
        "e30",
        cursor[:-4],
        cursor_for([]),
        cursor_for("value"),
        nested,
        cursor_for(
            {
                "v": 1,
                "t": "0001-01-01T00:00:00+14:00",
                "id": str(report_id),
            }
        ),
    ):
        with pytest.raises(ApiError) as captured:
            _decode_report_cursor(invalid)
        assert captured.value.status_code == 400
        assert captured.value.code == "invalid_cursor"


def test_create_report_encrypts_description_and_returns_safe_fields() -> None:
    repository = FakeReportRepository()
    service = QuestionService(repository, service_settings())  # type: ignore[arg-type]
    request = authenticated_request()
    body = QuestionReportCreateRequest(
        report_type="grading_dispute",
        description="Synthetic private description.",
        attempt_id=ATTEMPT_ID,
    )

    response, created = service.create_report(
        request,
        QUESTION_VERSION_ID,
        body,
        idempotency_key=IDEMPOTENCY_KEY,
    )

    assert created is True
    assert repository.created is not None
    ciphertext = repository.created["description_ciphertext"]
    assert ciphertext is not None
    assert b"Synthetic private description" not in ciphertext
    owner = _report_owner(
        request,
        question_version_id=QUESTION_VERSION_ID,
        report_id=repository.created["report_id"],
    )
    assert (
        ReportDescriptionProtector(b"k" * 32).reveal(ciphertext, owner=owner)
        == "Synthetic private description."
    )
    assert response.description_present is True
    assert response.evidence_state == "limited_pending_review"
    assert response.review_required is True
    serialized = response.model_dump_json()
    assert "Synthetic private description" not in serialized
    assert '"description"' not in serialized


def test_grading_dispute_without_attempt_is_rejected_before_persistence() -> None:
    repository = FakeReportRepository()
    service = QuestionService(repository, service_settings())  # type: ignore[arg-type]

    with pytest.raises(ApiError) as captured:
        service.create_report(
            authenticated_request(),
            QUESTION_VERSION_ID,
            QuestionReportCreateRequest.model_construct(
                report_type="grading_dispute",
                attempt_id=None,
                description=None,
            ),
            idempotency_key=IDEMPOTENCY_KEY,
        )

    assert captured.value.status_code == 422
    assert captured.value.code == "validation_failed"
    assert repository.created is None


def test_answer_error_without_attempt_is_recorded_not_limiting() -> None:
    repository = FakeReportRepository()
    service = QuestionService(repository, service_settings())  # type: ignore[arg-type]

    response, created = service.create_report(
        authenticated_request(),
        QUESTION_VERSION_ID,
        QuestionReportCreateRequest(
            report_type="answer_error",
            description="Synthetic private description.",
        ),
        idempotency_key=IDEMPOTENCY_KEY,
    )

    assert created is True
    assert response.attempt_id is None
    assert response.evidence_state == "recorded"
    assert response.review_required is True


def test_create_report_without_description_does_not_require_encryption_key() -> None:
    repository = FakeReportRepository()
    service = QuestionService(
        repository,
        Settings(_env_file=None),
    )  # type: ignore[arg-type]

    response, created = service.create_report(
        authenticated_request(),
        QUESTION_VERSION_ID,
        QuestionReportCreateRequest(report_type="question_error"),
        idempotency_key=IDEMPOTENCY_KEY,
    )

    assert created is True
    assert repository.created is not None
    assert repository.created["description_ciphertext"] is None
    assert response.description_present is False


def test_report_request_hash_changes_with_description() -> None:
    from memora.modules.questions.service import _request_hash

    first = _request_hash(
        QuestionReportCreateRequest(report_type="question_error", description="First."),
        QUESTION_VERSION_ID,
    )
    second = _request_hash(
        QuestionReportCreateRequest(report_type="question_error", description="Second."),
        QUESTION_VERSION_ID,
    )

    assert first != second


def test_list_reports_uses_stable_cursor_and_reports_more() -> None:
    repository = FakeReportRepository()
    now = datetime.now(UTC)
    repository.rows = [
        report_row(submitted_at=now, description_present=False),
        report_row(submitted_at=now - timedelta(seconds=1), description_present=True),
    ]
    repository.has_more = True
    service = QuestionService(repository, service_settings())  # type: ignore[arg-type]

    page = service.list_reports(authenticated_request(), cursor=None, limit=2)

    assert page.has_more is True
    assert page.next_cursor is not None
    decoded_at, decoded_id = _decode_report_cursor(page.next_cursor)
    assert decoded_at == repository.rows[-1]["submitted_at"]
    assert decoded_id == repository.rows[-1]["id"]

    second_page = service.list_reports(authenticated_request(), cursor=page.next_cursor, limit=2)
    assert second_page.has_more is True
    assert repository.before == (
        repository.rows[-1]["submitted_at"],
        repository.rows[-1]["id"],
    )


def test_get_report_missing_returns_safe_not_found() -> None:
    repository = FakeReportRepository()
    repository.missing = True
    service = QuestionService(repository, service_settings())  # type: ignore[arg-type]

    with pytest.raises(ApiError) as captured:
        service.get_report(authenticated_request(), uuid4())

    assert captured.value.status_code == 404
    assert captured.value.code == "resource_not_found"


def test_report_schema_requires_attempt_for_dispute_and_bounds_description() -> None:
    with pytest.raises(ValidationError):
        QuestionReportCreateRequest(report_type="grading_dispute")
    with pytest.raises(ValidationError):
        QuestionReportCreateRequest(report_type="question_error", description="x" * 2001)
    with pytest.raises(ValidationError):
        QuestionReportCreateRequest(
            report_type="question_error",
            unexpected="field",
        )


class FakeApiQuestionService:
    def __init__(self) -> None:
        self.response = QuestionReportResponse(
            id=uuid4(),
            question_version_id=QUESTION_VERSION_ID,
            attempt_id=ATTEMPT_ID,
            report_type="grading_dispute",
            status="submitted",
            submitted_at=datetime.now(UTC),
            resolved_at=None,
            description_present=True,
            evidence_state="limited_pending_review",
            resolution_code=None,
            review_required=True,
        )
        self.created_body: QuestionReportCreateRequest | None = None

    def create_report(
        self,
        _: AuthenticatedRequest,
        question_version_id: UUID,
        body: QuestionReportCreateRequest,
        *,
        idempotency_key: str,
    ) -> tuple[QuestionReportResponse, bool]:
        assert question_version_id == QUESTION_VERSION_ID
        assert idempotency_key == IDEMPOTENCY_KEY
        self.created_body = body
        return self.response, True

    def list_reports(
        self,
        _: AuthenticatedRequest,
        *,
        cursor: str | None,
        limit: int,
    ) -> Page[QuestionReportSummary]:
        assert cursor is None
        assert limit == 20
        return Page[QuestionReportSummary](
            items=[QuestionReportSummary.model_validate(self.response.model_dump())],
            next_cursor=None,
            has_more=False,
        )

    def get_report(self, _: AuthenticatedRequest, report_id: UUID) -> QuestionReportResponse:
        assert report_id == self.response.id
        return self.response


def test_report_routes_create_list_and_get_safe_payloads() -> None:
    app = create_app()
    fake = FakeApiQuestionService()
    app.dependency_overrides[get_authenticated_request] = authenticated_request
    app.dependency_overrides[get_question_service] = lambda: fake
    client = TestClient(app)

    created = client.post(
        f"/v1/questions/{QUESTION_VERSION_ID}/reports",
        json={
            "report_type": "grading_dispute",
            "description": "Synthetic private description.",
            "attempt_id": str(ATTEMPT_ID),
        },
        headers={**REQUEST_HEADERS, "Idempotency-Key": IDEMPOTENCY_KEY},
    )
    assert created.status_code == 201
    payload = created.json()
    assert payload["report_type"] == "grading_dispute"
    assert payload["evidence_state"] == "limited_pending_review"
    assert payload["review_required"] is True
    assert "description" not in payload
    assert "description_present" in payload
    assert fake.created_body is not None

    listed = client.get("/v1/question-reports", headers=REQUEST_HEADERS)
    assert listed.status_code == 200
    assert listed.json()["has_more"] is False
    assert listed.json()["items"][0]["id"] == str(fake.response.id)

    detail = client.get(
        f"/v1/question-reports/{fake.response.id}",
        headers=REQUEST_HEADERS,
    )
    assert detail.status_code == 200
    assert detail.json()["resolution_code"] is None
    assert "reviewer" not in detail.text
    assert '"description"' not in detail.text


def test_report_routes_require_idempotency_key_and_reject_extra_fields() -> None:
    app = create_app()
    fake = FakeApiQuestionService()
    app.dependency_overrides[get_authenticated_request] = authenticated_request
    app.dependency_overrides[get_question_service] = lambda: fake
    client = TestClient(app)

    missing_key = client.post(
        f"/v1/questions/{QUESTION_VERSION_ID}/reports",
        json={"report_type": "question_error"},
        headers=REQUEST_HEADERS,
    )
    assert missing_key.status_code == 422
    assert missing_key.json()["error"]["code"] == "validation_failed"

    extra = client.post(
        f"/v1/questions/{QUESTION_VERSION_ID}/reports",
        json={"report_type": "question_error", "unexpected": "value"},
        headers={**REQUEST_HEADERS, "Idempotency-Key": IDEMPOTENCY_KEY},
    )
    assert extra.status_code == 422
    assert extra.json()["error"]["code"] == "validation_failed"

    invalid_limit = client.get(
        "/v1/question-reports?limit=101",
        headers=REQUEST_HEADERS,
    )
    assert invalid_limit.status_code == 422
