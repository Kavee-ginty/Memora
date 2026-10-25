from datetime import UTC, date, datetime, timedelta, timezone
from uuid import uuid4

import pytest
from fastapi.security import HTTPBearer
from pydantic import TypeAdapter, ValidationError

from memora.api.security import bearer_auth
from memora.api.v1.schemas.common import (
    AsyncOperation,
    CalendarDate,
    Cursor,
    Page,
    PageMeta,
    PageParams,
    UtcDatetime,
    Version,
)
from memora.api.v1.schemas.errors import (
    ERROR_ACTIONS,
    ERROR_CODES,
    ErrorDetail,
    ErrorEnvelope,
    FieldError,
)
from memora.api.v1.schemas.headers import IdempotencyHeaders, RequestHeaders


def test_utc_datetime_serializes_with_z_and_seconds() -> None:
    adapter = TypeAdapter(UtcDatetime)
    value = datetime(2026, 1, 2, 3, 4, 5, 123456, tzinfo=UTC)

    assert adapter.dump_python(value, mode="json") == "2026-01-02T03:04:05Z"


def test_utc_datetime_normalizes_offset() -> None:
    adapter = TypeAdapter(UtcDatetime)
    value = datetime(2026, 1, 1, 12, 0, tzinfo=timezone(timedelta(hours=2)))

    assert adapter.dump_python(value, mode="json") == "2026-01-01T10:00:00Z"


def test_utc_datetime_rejects_naive_datetime() -> None:
    adapter = TypeAdapter(UtcDatetime)

    with pytest.raises(ValidationError):
        adapter.validate_python(datetime(2026, 1, 1))


def test_calendar_date_round_trip() -> None:
    adapter = TypeAdapter(CalendarDate)

    assert adapter.dump_python(date(2026, 1, 2), mode="json") == "2026-01-02"


def test_version_requires_positive_value() -> None:
    adapter = TypeAdapter(Version)

    assert adapter.validate_python(1) == 1
    with pytest.raises(ValidationError):
        adapter.validate_python(0)


def test_cursor_bounds() -> None:
    adapter = TypeAdapter(Cursor)

    assert adapter.validate_python("cursor") == "cursor"
    for value in ("", "x" * 513):
        with pytest.raises(ValidationError):
            adapter.validate_python(value)


def test_page_meta_consistency() -> None:
    assert PageMeta(next_cursor=None, has_more=False).has_more is False
    assert PageMeta(next_cursor="next", has_more=True).next_cursor == "next"

    for values in (
        {"next_cursor": None, "has_more": True},
        {"next_cursor": "next", "has_more": False},
    ):
        with pytest.raises(ValidationError):
            PageMeta(**values)


def test_page_meta_requires_next_cursor() -> None:
    with pytest.raises(ValidationError):
        PageMeta(has_more=False)


def test_page_items() -> None:
    page = Page[int](items=[1, 2], next_cursor=None, has_more=False)

    assert page.items == [1, 2]
    assert page.model_dump(mode="json") == {
        "next_cursor": None,
        "has_more": False,
        "items": [1, 2],
    }


def test_page_params_defaults_and_bounds() -> None:
    assert PageParams().limit == 20
    assert PageParams().cursor is None
    assert PageParams(cursor="next", limit=100).limit == 100

    for values in ({"limit": 0}, {"limit": 101}, {"cursor": ""}):
        with pytest.raises(ValidationError):
            PageParams(**values)


def test_async_operation_round_trip() -> None:
    resource_id = uuid4()
    operation = AsyncOperation(
        resource_id=resource_id,
        status="processing",
        status_url=f"/v1/learning-updates/{resource_id}",
        retry_after_seconds=None,
        updated_at=datetime(2026, 1, 2, 3, 4, 5, 999999, tzinfo=UTC),
    )

    assert operation.model_dump(mode="json") == {
        "resource_id": str(resource_id),
        "status": "processing",
        "status_url": f"/v1/learning-updates/{resource_id}",
        "retry_after_seconds": None,
        "updated_at": "2026-01-02T03:04:05Z",
    }


def test_async_operation_required_nullable_and_bounds() -> None:
    base = {
        "resource_id": uuid4(),
        "status": "processing",
        "status_url": "/v1/example",
        "updated_at": datetime(2026, 1, 1, tzinfo=UTC),
    }

    with pytest.raises(ValidationError):
        AsyncOperation(**base)
    with pytest.raises(ValidationError):
        AsyncOperation(**base, retry_after_seconds=-1)
    with pytest.raises(ValidationError):
        AsyncOperation(**{**base, "retry_after_seconds": None, "status_url": "relative"})
    with pytest.raises(ValidationError):
        AsyncOperation(
            **{
                **base,
                "retry_after_seconds": None,
                "updated_at": datetime(2026, 1, 1),
            }
        )


def test_field_error_bounds() -> None:
    with pytest.raises(ValidationError):
        FieldError(field="", code="invalid", message="message")
    with pytest.raises(ValidationError):
        FieldError(field="field", code="x" * 65, message="message")
    with pytest.raises(ValidationError):
        FieldError(field="field", code="invalid", message="x" * 501)


def test_error_detail_required_fields() -> None:
    detail = ErrorDetail(
        code="validation_failed",
        message="Check the highlighted fields and try again.",
        request_id="01J0000000000000000000000",
        field_errors=[],
        retryable=False,
        retry_after_seconds=None,
        action="correct_input",
    )

    assert detail.field_errors == []
    assert detail.action == "correct_input"

    for field in ("field_errors", "retry_after_seconds", "action"):
        payload = detail.model_dump(mode="json")
        payload.pop(field)
        with pytest.raises(ValidationError):
            ErrorDetail.model_validate(payload)


def test_error_envelope_serialization() -> None:
    detail = ErrorDetail(
        code="validation_failed",
        message="Check the highlighted fields and try again.",
        request_id="01J0000000000000000000000",
        field_errors=[
            FieldError(
                field="preferred_time",
                code="invalid_time",
                message="Enter a valid local time.",
            )
        ],
        retryable=False,
        retry_after_seconds=None,
        action="correct_input",
    )

    assert ErrorEnvelope(error=detail).model_dump(mode="json") == {
        "error": {
            "code": "validation_failed",
            "message": "Check the highlighted fields and try again.",
            "request_id": "01J0000000000000000000000",
            "field_errors": [
                {
                    "field": "preferred_time",
                    "code": "invalid_time",
                    "message": "Enter a valid local time.",
                }
            ],
            "retryable": False,
            "retry_after_seconds": None,
            "action": "correct_input",
        }
    }


def test_error_envelope_schema_example() -> None:
    schema = ErrorEnvelope.model_json_schema()

    example = schema["examples"][0]
    assert example["error"]["code"] == "validation_failed"
    assert example["error"]["field_errors"][0]["field"] == "preferred_time"


def test_error_envelope_tolerates_and_ignores_unknown_fields() -> None:
    """API §21 requires clients to tolerate and ignore unknown additive response fields.

    Unknown fields deserialize successfully without treating them as authoritative
    and are intentionally omitted when reserialized.
    """
    payload = {
        "error": {
            "code": "validation_failed",
            "message": "Check the highlighted fields and try again.",
            "request_id": "01J0000000000000000000000",
            "field_errors": [],
            "retryable": False,
            "retry_after_seconds": None,
            "action": "correct_input",
            "extra": "ignored",
        },
        "extra": "ignored",
    }

    envelope = ErrorEnvelope.model_validate(payload)

    assert not hasattr(envelope, "extra")
    assert not hasattr(envelope.error, "extra")

    dumped = envelope.model_dump(mode="json")
    assert "extra" not in dumped
    assert "extra" not in dumped["error"]


def test_error_codes_and_actions_are_documented() -> None:
    assert "validation_failed" in ERROR_CODES
    assert "idempotency_key_reused" in ERROR_CODES
    assert "correct_input" in ERROR_ACTIONS


def test_request_headers_accept_aliases() -> None:
    correlation_id = uuid4()
    headers = RequestHeaders.model_validate(
        {
            "X-Correlation-ID": str(correlation_id),
            "X-Client-Version": "1.2.3",
            "X-Platform": "android",
            "Accept-Language": "en-US",
        }
    )

    assert headers.correlation_id == correlation_id
    assert headers.client_version == "1.2.3"
    assert headers.platform == "android"
    assert headers.accept_language == "en-US"


def test_request_headers_accept_field_names_and_default_optional() -> None:
    correlation_id = uuid4()
    headers = RequestHeaders(
        correlation_id=correlation_id,
        client_version="1.2.3",
        platform="ios",
    )

    assert headers.accept_language is None
    assert headers.model_dump(by_alias=True, mode="json") == {
        "X-Correlation-ID": str(correlation_id),
        "X-Client-Version": "1.2.3",
        "X-Platform": "ios",
        "Accept-Language": None,
    }


def test_request_headers_require_required_headers() -> None:
    payload = {
        "X-Correlation-ID": str(uuid4()),
        "X-Client-Version": "1.2.3",
        "X-Platform": "android",
    }

    for header in ("X-Correlation-ID", "X-Client-Version", "X-Platform"):
        missing = {key: value for key, value in payload.items() if key != header}
        with pytest.raises(ValidationError):
            RequestHeaders.model_validate(missing)


def test_request_headers_validate_values() -> None:
    valid = {
        "X-Correlation-ID": str(uuid4()),
        "X-Client-Version": "1.2.3",
        "X-Platform": "android",
    }

    for values in (
        {**valid, "X-Correlation-ID": "not-a-uuid"},
        {**valid, "X-Client-Version": ""},
        {**valid, "X-Client-Version": "x" * 51},
        {**valid, "X-Platform": "web"},
        {**valid, "Accept-Language": "x" * 36},
    ):
        with pytest.raises(ValidationError):
            RequestHeaders.model_validate(values)

    assert (
        RequestHeaders.model_validate({**valid, "Accept-Language": "x" * 35}).accept_language
        == "x" * 35
    )


def test_idempotency_headers_alias_and_bounds() -> None:
    key = "x" * 16
    headers = IdempotencyHeaders.model_validate({"Idempotency-Key": key})

    assert headers.idempotency_key == key
    assert IdempotencyHeaders(idempotency_key="y" * 255).idempotency_key == "y" * 255
    assert headers.model_dump(by_alias=True) == {"Idempotency-Key": key}

    for value in ("x" * 15, "x" * 256):
        with pytest.raises(ValidationError):
            IdempotencyHeaders.model_validate({"Idempotency-Key": value})
    with pytest.raises(ValidationError):
        IdempotencyHeaders.model_validate({})


def test_bearer_auth_scheme() -> None:
    assert isinstance(bearer_auth, HTTPBearer)
    assert bearer_auth.scheme_name == "bearerAuth"
    assert bearer_auth.auto_error is False
