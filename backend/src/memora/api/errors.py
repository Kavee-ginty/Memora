from __future__ import annotations

from dataclasses import dataclass
from uuid import uuid4

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError

from memora.api.v1.schemas.errors import ErrorDetail, ErrorEnvelope, FieldError


@dataclass(slots=True)
class ApiError(Exception):
    status_code: int
    code: str
    message: str
    action: str | None = None
    retryable: bool = False
    retry_after_seconds: int | None = None


def _request_id(request: Request) -> str:
    return str(getattr(request.state, "request_id", uuid4()))


def _response(request: Request, error: ApiError) -> JSONResponse:
    envelope = ErrorEnvelope(
        error=ErrorDetail(
            code=error.code,
            message=error.message,
            request_id=_request_id(request),
            field_errors=[],
            retryable=error.retryable,
            retry_after_seconds=error.retry_after_seconds,
            action=error.action,
        )
    )
    headers = {}
    if error.retry_after_seconds is not None:
        headers["Retry-After"] = str(error.retry_after_seconds)
    return JSONResponse(
        status_code=error.status_code,
        content=envelope.model_dump(mode="json"),
        headers=headers,
    )


def install_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(ApiError)
    async def handle_api_error(request: Request, error: ApiError) -> JSONResponse:
        return _response(request, error)

    @app.exception_handler(RequestValidationError)
    async def handle_validation_error(
        request: Request, error: RequestValidationError
    ) -> JSONResponse:
        field_errors = [
            FieldError(
                field=(".".join(str(part) for part in item["loc"] if part != "body") or "request"),
                code=str(item["type"]),
                message="Enter a valid value.",
            )
            for item in error.errors()
        ]
        envelope = ErrorEnvelope(
            error=ErrorDetail(
                code="validation_failed",
                message="Check the highlighted fields and try again.",
                request_id=_request_id(request),
                field_errors=field_errors,
                retryable=False,
                retry_after_seconds=None,
                action="correct_input",
            )
        )
        return JSONResponse(status_code=422, content=envelope.model_dump(mode="json"))

    @app.exception_handler(SQLAlchemyError)
    async def handle_database_error(request: Request, _: SQLAlchemyError) -> JSONResponse:
        return _response(
            request,
            ApiError(
                503,
                "temporarily_unavailable",
                "This action is temporarily unavailable.",
                "retry",
                retryable=True,
                retry_after_seconds=5,
            ),
        )
