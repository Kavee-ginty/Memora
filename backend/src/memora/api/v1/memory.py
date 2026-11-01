from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Header, Query

from memora.api.openapi import COMMON_ERROR_RESPONSES
from memora.api.operation_ids import OperationId
from memora.api.security import AuthenticatedRequest, get_authenticated_request
from memora.api.v1.schemas.common import Page
from memora.api.v1.schemas.headers import RequestHeaders
from memora.api.v1.schemas.memory import ConceptHistoryResponse, ConceptProgressItem
from memora.modules.memory.selection import (
    DEFAULT_HORIZON_DAYS,
    DEFAULT_SELECTION_LIMIT,
    MAX_HORIZON_DAYS,
    MAX_SELECTION_LIMIT,
)
from memora.modules.memory.service import (
    DEFAULT_HISTORY_LIMIT,
    MAX_HISTORY_LIMIT,
    MemoryService,
    get_memory_service,
)

router = APIRouter()


@router.get(
    "/subjects/{subject_id}/concept-progress",
    response_model=Page[ConceptProgressItem],
    operation_id=OperationId.LIST_CONCEPT_PROGRESS,
    tags=["curriculum"],
    summary="List due and near-due concept progress for a subject",
    description=(
        "Returns the authenticated student's concept states in next-review order for the "
        "requested horizon, with a retrievability band, a review window and a "
        "plain-language due reason. Hidden ranking scores and event payloads are never "
        "returned."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def list_concept_progress(
    subject_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[MemoryService, Depends(get_memory_service)],
    limit: Annotated[int, Query(ge=1, le=MAX_SELECTION_LIMIT)] = DEFAULT_SELECTION_LIMIT,
    cursor: Annotated[str | None, Query(min_length=1, max_length=200)] = None,
    horizon_days: Annotated[float, Query(gt=0, le=MAX_HORIZON_DAYS)] = DEFAULT_HORIZON_DAYS,
) -> Page[ConceptProgressItem]:
    return service.list_concept_progress(
        auth,
        subject_id,
        horizon_days=horizon_days,
        limit=limit,
        cursor=cursor,
    )


@router.get(
    "/concepts/{concept_id}/history",
    response_model=ConceptHistoryResponse,
    operation_id=OperationId.GET_CONCEPT_HISTORY,
    tags=["curriculum"],
    summary="Read a concept's evidence summary and scheduling history",
    description=(
        "Returns the authenticated student's bounded evidence summary and paginated "
        "scheduling decisions for one concept, each with allowlisted reason codes, a "
        "template key and safe copy. Another learner's concept returns 404."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def get_concept_history(
    concept_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[MemoryService, Depends(get_memory_service)],
    limit: Annotated[int, Query(ge=1, le=MAX_HISTORY_LIMIT)] = DEFAULT_HISTORY_LIMIT,
    cursor: Annotated[str | None, Query(min_length=1, max_length=200)] = None,
) -> ConceptHistoryResponse:
    return service.get_concept_history(auth, concept_id, limit=limit, cursor=cursor)
