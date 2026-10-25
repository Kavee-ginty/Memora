from __future__ import annotations

from typing import Annotated, Final

from pydantic import BaseModel, ConfigDict, Field

ERROR_CODES: Final[tuple[str, ...]] = (
    "invalid_cursor",
    "invalid_state",
    "malformed_request",
    "token_missing",
    "token_invalid",
    "token_expired",
    "consent_required",
    "recent_authentication_required",
    "operation_not_allowed",
    "resource_not_found",
    "version_conflict",
    "idempotency_key_reused",
    "operation_in_progress",
    "mission_state_changed",
    "payload_too_large",
    "unsupported_media_type",
    "validation_failed",
    "rate_limited",
    "temporarily_unavailable",
)

ERROR_ACTIONS: Final[tuple[str, ...]] = (
    "correct_input",
    "refresh_state",
    "reauthenticate",
    "retry",
    "contact_support",
)


class FieldError(BaseModel):
    field: Annotated[str, Field(min_length=1, max_length=200)]
    code: Annotated[str, Field(min_length=1, max_length=64)]
    message: Annotated[str, Field(min_length=1, max_length=500)]


class ErrorDetail(BaseModel):
    code: Annotated[str, Field(min_length=1, max_length=64)]
    message: Annotated[str, Field(min_length=1, max_length=500)]
    request_id: Annotated[str, Field(min_length=1, max_length=128)]
    field_errors: list[FieldError]
    retryable: bool
    retry_after_seconds: Annotated[int, Field(ge=0)] | None
    action: Annotated[str, Field(min_length=1, max_length=64)] | None


class ErrorEnvelope(BaseModel):
    error: ErrorDetail
    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
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
            ]
        }
    )
