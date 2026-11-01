from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Header

from memora.api.openapi import COMMON_ERROR_RESPONSES
from memora.api.operation_ids import OperationId
from memora.api.security import AuthenticatedRequest, get_authenticated_request
from memora.api.v1.schemas.headers import IdempotencyHeaders, RequestHeaders
from memora.api.v1.schemas.missions import (
    AttemptResult,
    MissionCompletionResult,
    MissionItemResponse,
    MissionManifest,
    MissionSummary,
    SubmitAttemptRequest,
    TodayMissionResponse,
)
from memora.modules.missions.service import MissionService, get_mission_service

router = APIRouter()


@router.get(
    "/missions/today",
    response_model=TodayMissionResponse,
    operation_id=OperationId.GET_TODAY_MISSION,
    tags=["missions"],
    summary="Read or assemble today's bounded Daily Mission",
    description=(
        "Returns one persisted, owner-scoped mission ranked from authoritative memory "
        "state, or an explicit no-due state. Hidden candidates and scores are not returned."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def get_today_mission(
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[MissionService, Depends(get_mission_service)],
) -> TodayMissionResponse:
    return service.today(auth)


@router.get(
    "/missions/{mission_id}",
    response_model=MissionManifest,
    operation_id=OperationId.GET_MISSION,
    tags=["missions"],
    summary="Read a mission preview and authoritative progress",
    responses=COMMON_ERROR_RESPONSES,
)
def get_mission(
    mission_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[MissionService, Depends(get_mission_service)],
) -> MissionManifest:
    return service.get(auth, mission_id)


@router.post(
    "/missions/{mission_id}/start",
    response_model=MissionManifest,
    operation_id=OperationId.START_MISSION,
    tags=["missions"],
    summary="Start or resume a mission with pinned question versions",
    responses=COMMON_ERROR_RESPONSES,
)
def start_mission(
    mission_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[MissionService, Depends(get_mission_service)],
) -> MissionManifest:
    return service.start(auth, mission_id, idempotency_key=idempotency.idempotency_key)


@router.get(
    "/missions/{mission_id}/items/{item_id}",
    response_model=MissionItemResponse,
    operation_id=OperationId.GET_MISSION_ITEM,
    tags=["missions"],
    summary="Read the authorized current mission item",
    description="Returns the pinned question without an answer key or grading rubric.",
    responses=COMMON_ERROR_RESPONSES,
)
def get_mission_item(
    mission_id: UUID,
    item_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[MissionService, Depends(get_mission_service)],
) -> MissionItemResponse:
    return service.item(auth, mission_id, item_id)


@router.post(
    "/missions/{mission_id}/items/{item_id}/attempts",
    response_model=AttemptResult,
    operation_id=OperationId.SUBMIT_ATTEMPT,
    tags=["missions"],
    summary="Submit and grade one answer envelope",
    description=(
        "Uses client_operation_id as the stable retry identity, grades only the pinned "
        "question, and publishes bounded memory evidence through the transactional outbox."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def submit_attempt(
    mission_id: UUID,
    item_id: UUID,
    body: SubmitAttemptRequest,
    headers: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[MissionService, Depends(get_mission_service)],
) -> AttemptResult:
    return service.submit(auth, headers, mission_id, item_id, body)


@router.post(
    "/missions/{mission_id}/items/{item_id}/skip",
    response_model=AttemptResult,
    operation_id=OperationId.SKIP_MISSION_ITEM,
    tags=["missions"],
    summary="Record one permitted mission-item skip",
    responses=COMMON_ERROR_RESPONSES,
)
def skip_mission_item(
    mission_id: UUID,
    item_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[MissionService, Depends(get_mission_service)],
) -> AttemptResult:
    return service.skip(
        auth,
        mission_id,
        item_id,
        idempotency_key=idempotency.idempotency_key,
    )


@router.post(
    "/missions/{mission_id}/pause",
    response_model=MissionSummary,
    operation_id=OperationId.PAUSE_MISSION,
    tags=["missions"],
    summary="Pause an active mission without losing progress",
    responses=COMMON_ERROR_RESPONSES,
)
def pause_mission(
    mission_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[MissionService, Depends(get_mission_service)],
) -> MissionSummary:
    return service.pause(auth, mission_id, idempotency_key=idempotency.idempotency_key)


@router.post(
    "/missions/{mission_id}/complete",
    response_model=MissionCompletionResult,
    operation_id=OperationId.COMPLETE_MISSION,
    tags=["missions"],
    summary="Complete a mission from persisted eligible item states",
    description=(
        "Stores one stable learning result and emits mission.completed. XP, streak and reef "
        "projection are applied by the T15 idempotent engagement consumer."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def complete_mission(
    mission_id: UUID,
    headers: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[MissionService, Depends(get_mission_service)],
) -> MissionCompletionResult:
    return service.complete(
        auth,
        headers,
        mission_id,
        idempotency_key=idempotency.idempotency_key,
    )


@router.get(
    "/missions/{mission_id}/results",
    response_model=MissionCompletionResult,
    operation_id=OperationId.GET_MISSION_RESULTS,
    tags=["missions"],
    summary="Read stable mission completion results",
    responses=COMMON_ERROR_RESPONSES,
)
def get_mission_results(
    mission_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[MissionService, Depends(get_mission_service)],
) -> MissionCompletionResult:
    return service.results(auth, mission_id)
