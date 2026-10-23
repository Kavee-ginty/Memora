from typing import Literal

from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(tags=["health"])


class HealthResponse(BaseModel):
    status: Literal["ok"] = "ok"


@router.get("/health/live", response_model=HealthResponse, operation_id="healthLive")
async def live() -> HealthResponse:
    return HealthResponse()


@router.get("/health/ready", response_model=HealthResponse, operation_id="healthReady")
async def ready() -> HealthResponse:
    # T02 adds dependency checks once local services and CI are defined.
    return HealthResponse()
