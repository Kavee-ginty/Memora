from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Header, Query, Response, status

from memora.api.openapi import COMMON_ERROR_RESPONSES
from memora.api.operation_ids import OperationId
from memora.api.security import AuthenticatedRequest, get_authenticated_request
from memora.api.v1.schemas.headers import IdempotencyHeaders, RequestHeaders
from memora.api.v1.schemas.ingestion import (
    CandidateListResponse,
    CreateLearningUpdateRequest,
    FinalizeUploadRequest,
    KnowledgeCommitResponse,
    LearningPathPreviewResponse,
    LearningUpdateListResponse,
    LearningUpdateResponse,
    RetryLearningUpdateRequest,
    SubmitVerificationDecisionsRequest,
    SubmitVerificationDecisionsResponse,
    UpdateLearningUpdateRequest,
    UploadGrantRequest,
    UploadGrantResponse,
)
from memora.modules.ingestion.service import IngestionService, get_ingestion_service

router = APIRouter()
CursorQuery = Annotated[str | None, Query(max_length=512)]
LimitQuery = Annotated[int, Query(ge=1, le=100)]


@router.post(
    "/learning-updates",
    response_model=LearningUpdateResponse,
    status_code=status.HTTP_201_CREATED,
    operation_id=OperationId.CREATE_LEARNING_UPDATE,
    tags=["learning-updates"],
    summary="Create a text or upload-backed learning update",
    description="Creates one independent learning update for the authenticated student.",
    responses=COMMON_ERROR_RESPONSES,
)
def create_learning_update(
    body: CreateLearningUpdateRequest,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IngestionService, Depends(get_ingestion_service)],
) -> LearningUpdateResponse:
    return service.create(auth, body, idempotency_key=idempotency.idempotency_key)


@router.get(
    "/learning-updates",
    response_model=LearningUpdateListResponse,
    operation_id=OperationId.LIST_LEARNING_UPDATES,
    tags=["learning-updates"],
    summary="List the authenticated student's learning updates",
    responses=COMMON_ERROR_RESPONSES,
)
def list_learning_updates(
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IngestionService, Depends(get_ingestion_service)],
    cursor: CursorQuery = None,
    limit: LimitQuery = 20,
) -> LearningUpdateListResponse:
    return service.list(auth, cursor=cursor, limit=limit)


@router.get(
    "/learning-updates/{update_id}",
    response_model=LearningUpdateResponse,
    operation_id=OperationId.GET_LEARNING_UPDATE,
    tags=["learning-updates"],
    summary="Read processing and deletion status",
    responses=COMMON_ERROR_RESPONSES,
)
def get_learning_update(
    update_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IngestionService, Depends(get_ingestion_service)],
) -> LearningUpdateResponse:
    return service.get(auth, update_id)


@router.patch(
    "/learning-updates/{update_id}",
    response_model=LearningUpdateResponse,
    operation_id=OperationId.UPDATE_LEARNING_UPDATE,
    tags=["learning-updates"],
    summary="Edit an eligible draft update",
    responses=COMMON_ERROR_RESPONSES,
)
def update_learning_update(
    update_id: UUID,
    body: UpdateLearningUpdateRequest,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IngestionService, Depends(get_ingestion_service)],
) -> LearningUpdateResponse:
    return service.update(auth, update_id, body, idempotency_key=idempotency.idempotency_key)


@router.delete(
    "/learning-updates/{update_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    operation_id=OperationId.DELETE_LEARNING_UPDATE,
    tags=["learning-updates"],
    summary="Discard a draft or cancel an unfinished workflow",
    responses={
        status.HTTP_202_ACCEPTED: {"description": "Temporary source cleanup was accepted."},
        **COMMON_ERROR_RESPONSES,
    },
)
def delete_learning_update(
    update_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IngestionService, Depends(get_ingestion_service)],
) -> Response:
    _, cleanup = service.discard(auth, update_id, idempotency_key=idempotency.idempotency_key)
    if cleanup:
        return Response(status_code=status.HTTP_202_ACCEPTED)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/learning-updates/{update_id}/uploads",
    response_model=UploadGrantResponse,
    status_code=status.HTTP_201_CREATED,
    operation_id=OperationId.CREATE_UPLOAD_GRANT,
    tags=["learning-updates"],
    summary="Request a temporary signed upload grant",
    responses=COMMON_ERROR_RESPONSES,
)
def create_upload_grant(
    update_id: UUID,
    body: UploadGrantRequest,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IngestionService, Depends(get_ingestion_service)],
) -> UploadGrantResponse:
    return service.grant(auth, update_id, body, idempotency_key=idempotency.idempotency_key)


@router.post(
    "/learning-updates/{update_id}/uploads/{upload_id}/finalize",
    response_model=LearningUpdateResponse,
    status_code=status.HTTP_202_ACCEPTED,
    operation_id=OperationId.FINALIZE_UPLOAD,
    tags=["learning-updates"],
    summary="Verify an uploaded object and queue processing once",
    responses=COMMON_ERROR_RESPONSES,
)
def finalize_upload(
    update_id: UUID,
    upload_id: UUID,
    body: FinalizeUploadRequest,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IngestionService, Depends(get_ingestion_service)],
) -> LearningUpdateResponse:
    return service.finalize(
        auth, update_id, upload_id, body, idempotency_key=idempotency.idempotency_key
    )


@router.post(
    "/learning-updates/{update_id}/retry",
    response_model=LearningUpdateResponse,
    status_code=status.HTTP_202_ACCEPTED,
    operation_id=OperationId.RETRY_LEARNING_UPDATE,
    tags=["learning-updates"],
    summary="Retry an eligible failed stage",
    responses=COMMON_ERROR_RESPONSES,
)
def retry_learning_update(
    update_id: UUID,
    body: RetryLearningUpdateRequest,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IngestionService, Depends(get_ingestion_service)],
) -> LearningUpdateResponse:
    return service.retry(
        auth, update_id, stage=body.stage, idempotency_key=idempotency.idempotency_key
    )


@router.get(
    "/learning-updates/{update_id}/candidates",
    response_model=CandidateListResponse,
    operation_id=OperationId.LIST_EXTRACTION_CANDIDATES,
    tags=["verification"],
    summary="List authorized extraction candidates",
    responses=COMMON_ERROR_RESPONSES,
)
def list_extraction_candidates(
    update_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IngestionService, Depends(get_ingestion_service)],
    cursor: CursorQuery = None,
    limit: LimitQuery = 20,
) -> CandidateListResponse:
    return service.candidates(auth, update_id, cursor=cursor, limit=limit)


@router.post(
    "/learning-updates/{update_id}/verification-decisions",
    response_model=SubmitVerificationDecisionsResponse,
    operation_id=OperationId.SUBMIT_VERIFICATION_DECISIONS,
    tags=["verification"],
    summary="Submit versioned concept verification decisions",
    responses=COMMON_ERROR_RESPONSES,
)
def submit_verification_decisions(
    update_id: UUID,
    body: SubmitVerificationDecisionsRequest,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IngestionService, Depends(get_ingestion_service)],
) -> SubmitVerificationDecisionsResponse:
    return service.decide(auth, update_id, body, idempotency_key=idempotency.idempotency_key)


@router.get(
    "/learning-updates/{update_id}/preview",
    response_model=LearningPathPreviewResponse,
    operation_id=OperationId.PREVIEW_LEARNING_PATH,
    tags=["verification"],
    summary="Preview the validated learning path",
    responses=COMMON_ERROR_RESPONSES,
)
def preview_learning_path(
    update_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IngestionService, Depends(get_ingestion_service)],
) -> LearningPathPreviewResponse:
    return service.preview(auth, update_id)


@router.post(
    "/learning-updates/{update_id}/commit",
    response_model=KnowledgeCommitResponse,
    operation_id=OperationId.COMMIT_LEARNING_UPDATE,
    tags=["verification"],
    summary="Commit accepted knowledge and exposure once",
    responses={
        status.HTTP_201_CREATED: {
            "model": KnowledgeCommitResponse,
            "description": "A new commit version was created.",
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def commit_learning_update(
    update_id: UUID,
    response: Response,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IngestionService, Depends(get_ingestion_service)],
) -> KnowledgeCommitResponse:
    result = service.commit(auth, update_id, idempotency_key=idempotency.idempotency_key)
    if result.commit_version == 1:
        response.status_code = status.HTTP_201_CREATED
        return result
    response.status_code = status.HTTP_200_OK
    return result


# WARNING: Decompyle incomplete
