from enum import StrEnum
from functools import lru_cache
from uuid import uuid4

from fastapi import APIRouter
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.exc import SQLAlchemyError

from memora.api.openapi import COMMON_ERROR_RESPONSES
from memora.api.operation_ids import OperationId
from memora.api.v1.schemas.errors import ErrorDetail, ErrorEnvelope
from memora.core.config import get_settings


class HealthStatus(StrEnum):
    OK = "ok"


router = APIRouter(tags=["health"])


class HealthResponse(BaseModel):
    status: HealthStatus = HealthStatus.OK


@lru_cache(maxsize=1)
def readiness_engine(database_url: str) -> Engine:
    return create_engine(
        database_url,
        pool_pre_ping=True,
        connect_args={"connect_timeout": 2},
    )


def database_is_ready() -> bool:
    try:
        with readiness_engine(get_settings().database_url).connect() as connection:
            return connection.scalar(text("SELECT 1")) == 1
    except SQLAlchemyError:
        return False


@router.get(
    "/health/live",
    response_model=HealthResponse,
    operation_id=OperationId.HEALTH_LIVE,
)
async def live() -> HealthResponse:
    return HealthResponse()


@router.get(
    "/health/ready",
    response_model=HealthResponse,
    operation_id=OperationId.HEALTH_READY,
    responses={503: COMMON_ERROR_RESPONSES[503]},
)
def ready() -> HealthResponse | JSONResponse:
    if not database_is_ready():
        error = ErrorEnvelope(
            error=ErrorDetail(
                code="temporarily_unavailable",
                message="The service is not ready.",
                request_id=str(uuid4()),
                field_errors=[],
                retryable=True,
                retry_after_seconds=5,
                action="retry",
            )
        )
        return JSONResponse(status_code=503, content=error.model_dump(mode="json"))
    return HealthResponse()
