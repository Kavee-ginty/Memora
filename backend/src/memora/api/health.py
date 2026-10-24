from typing import Literal

from fastapi import APIRouter
from pydantic import BaseModel

from memora.api.operation_ids import OperationId

router = APIRouter(tags=["health"])


class HealthResponse(BaseModel):
    status: Literal["ok"] = "ok"


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
