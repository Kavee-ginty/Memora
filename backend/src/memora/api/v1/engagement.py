"""T15 Home, seabed, statistics and permanent reward API."""

from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Header, Query

from memora.api.openapi import COMMON_ERROR_RESPONSES
from memora.api.operation_ids import OperationId
from memora.api.security import AuthenticatedRequest, get_authenticated_request
from memora.api.v1.schemas.engagement import (
    HomeResponse,
    ProgressStatisticsResponse,
    ReefDetail,
    RewardGrant,
    RewardInventoryResponse,
    RewardPlacementRequest,
    SeabedResponse,
)
from memora.api.v1.schemas.headers import IdempotencyHeaders, RequestHeaders
from memora.modules.engagement.service import EngagementService, get_engagement_service

router = APIRouter()


@router.get(
    "/home",
    response_model=HomeResponse,
    operation_id=OperationId.GET_HOME,
    tags=["home"],
    responses=COMMON_ERROR_RESPONSES,
)
def get_home(
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[EngagementService, Depends(get_engagement_service)],
) -> HomeResponse:
    return service.home(auth)


@router.get(
    "/seabed",
    response_model=SeabedResponse,
    operation_id=OperationId.GET_SEABED,
    tags=["progress"],
    responses=COMMON_ERROR_RESPONSES,
)
def get_seabed(
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[EngagementService, Depends(get_engagement_service)],
) -> SeabedResponse:
    return service.seabed(auth)


@router.get(
    "/seabed/reefs/{subject_id}",
    response_model=ReefDetail,
    operation_id=OperationId.GET_REEF,
    tags=["progress"],
    responses=COMMON_ERROR_RESPONSES,
)
def get_reef(
    subject_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[EngagementService, Depends(get_engagement_service)],
) -> ReefDetail:
    return service.reef(auth, subject_id)


@router.get(
    "/progress/statistics",
    response_model=ProgressStatisticsResponse,
    operation_id=OperationId.GET_PROGRESS_STATISTICS,
    tags=["progress"],
    responses=COMMON_ERROR_RESPONSES,
)
def get_progress_statistics(
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[EngagementService, Depends(get_engagement_service)],
    start: Annotated[date, Query()],
    end: Annotated[date, Query()],
    timezone: Annotated[str, Query(min_length=1, max_length=64)],
) -> ProgressStatisticsResponse:
    return service.statistics(auth, start=start, end=end, timezone=timezone)


@router.get(
    "/rewards",
    response_model=RewardInventoryResponse,
    operation_id=OperationId.LIST_REWARDS,
    tags=["rewards"],
    responses=COMMON_ERROR_RESPONSES,
)
def list_rewards(
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[EngagementService, Depends(get_engagement_service)],
    grant_id: Annotated[UUID | None, Query()] = None,
) -> RewardInventoryResponse:
    return service.rewards(auth, grant_id)


@router.patch(
    "/rewards/{reward_grant_id}",
    response_model=RewardGrant,
    operation_id=OperationId.UPDATE_REWARD_PLACEMENT,
    tags=["rewards"],
    responses=COMMON_ERROR_RESPONSES,
)
def update_reward_placement(
    reward_grant_id: UUID,
    body: RewardPlacementRequest,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[EngagementService, Depends(get_engagement_service)],
) -> RewardGrant:
    return service.update_placement(
        auth,
        reward_grant_id,
        subject_id=body.subject_id,
        placement_slot=body.placement_slot,
        version=body.version,
        idempotency_key=idempotency.idempotency_key,
    )
