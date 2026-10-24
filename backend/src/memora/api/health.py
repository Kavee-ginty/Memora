from enum import StrEnum

from fastapi import APIRouter
from pydantic import BaseModel

from memora.api.operation_ids import OperationId


class HealthStatus(StrEnum):
    OK = "ok"


router = APIRouter(tags=["health"])


class HealthResponse(BaseModel):
    status: HealthStatus = HealthStatus.OK


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
)
async def ready() -> HealthResponse:
    # T02 adds dependency checks once local services and CI are defined.
    return HealthResponse()
