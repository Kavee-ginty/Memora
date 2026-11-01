from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Header, Request, Response, status

from memora.api.errors import ApiError
from memora.api.openapi import COMMON_ERROR_RESPONSES
from memora.api.operation_ids import OperationId
from memora.api.security import AuthenticatedRequest, get_authenticated_request
from memora.api.v1.schemas.headers import IdempotencyHeaders, RequestHeaders
from memora.api.v1.schemas.privacy import (
    PrivacyDeletionCancelRequest,
    PrivacyDeletionRequest,
    PrivacyDeletionResponse,
    PrivacyExportRequest,
    PrivacyExportResponse,
)
from memora.modules.privacy.service import PrivacyService, get_privacy_service

router = APIRouter()


@router.post(
    "/privacy/exports",
    response_model=PrivacyExportResponse,
    status_code=status.HTTP_202_ACCEPTED,
    operation_id=OperationId.CREATE_PRIVACY_EXPORT,
    tags=["privacy"],
    summary="Request account data export",
    description=(
        "Idempotently initiates an asynchronous data export job after recent authentication."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def create_privacy_export(
    body: PrivacyExportRequest,
    request: Request,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[PrivacyService, Depends(get_privacy_service)],
) -> PrivacyExportResponse:
    correlation_id = getattr(request.state, "correlation_id", None)
    return service.create_export(
        auth,
        body,
        idempotency_key=idempotency.idempotency_key,
        correlation_id=correlation_id,
    )


@router.get(
    "/privacy/exports/{request_id}",
    response_model=PrivacyExportResponse,
    operation_id=OperationId.GET_PRIVACY_EXPORT,
    tags=["privacy"],
    summary="Get privacy export status",
    description="Returns the status and ephemeral download link of an export request.",
    responses=COMMON_ERROR_RESPONSES,
)
def get_privacy_export(
    request_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[PrivacyService, Depends(get_privacy_service)],
) -> PrivacyExportResponse:
    return service.get_export(auth, request_id)


@router.get(
    "/privacy/exports/{request_id}/download",
    response_class=Response,
    include_in_schema=False,
)
def download_privacy_export(
    request_id: UUID,
    service: Annotated[PrivacyService, Depends(get_privacy_service)],
    token: str | None = None,
) -> Response:
    if not token:
        raise ApiError(
            401,
            "authentication_required",
            "A valid signed download token is required.",
            "authenticate",
        )
    content = service.get_export_download_archive(request_id, token)
    return Response(
        content=content,
        media_type="application/zip",
        headers={"Content-Disposition": f'attachment; filename="memora_export_{request_id}.zip"'},
    )


@router.post(
    "/privacy/deletions",
    response_model=PrivacyDeletionResponse,
    status_code=status.HTTP_202_ACCEPTED,
    operation_id=OperationId.CREATE_PRIVACY_DELETION,
    tags=["privacy"],
    summary="Request account deletion",
    description=(
        "Idempotently initiates verified durable account deletion after recent authentication."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def create_privacy_deletion(
    body: PrivacyDeletionRequest,
    request: Request,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[PrivacyService, Depends(get_privacy_service)],
) -> PrivacyDeletionResponse:
    correlation_id = getattr(request.state, "correlation_id", None)
    return service.create_deletion(
        auth,
        body,
        idempotency_key=idempotency.idempotency_key,
        correlation_id=correlation_id,
    )


@router.get(
    "/privacy/deletions/{request_id}",
    response_model=PrivacyDeletionResponse,
    operation_id=OperationId.GET_PRIVACY_DELETION,
    tags=["privacy"],
    summary="Get account deletion status",
    description=(
        "Returns deletion workflow progress and cryptographic deletion proofs upon completion."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def get_privacy_deletion(
    request_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[PrivacyService, Depends(get_privacy_service)],
) -> PrivacyDeletionResponse:
    return service.get_deletion(auth, request_id)


@router.post(
    "/privacy/deletions/{request_id}/cancel",
    response_model=PrivacyDeletionResponse,
    operation_id=OperationId.CANCEL_PRIVACY_DELETION,
    tags=["privacy"],
    summary="Cancel pending account deletion",
    description="Cancels a deletion request if processing has not yet commenced.",
    responses=COMMON_ERROR_RESPONSES,
)
def cancel_privacy_deletion(
    request_id: UUID,
    body: PrivacyDeletionCancelRequest,
    request: Request,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[PrivacyService, Depends(get_privacy_service)],
) -> PrivacyDeletionResponse:
    correlation_id = getattr(request.state, "correlation_id", None)
    return service.cancel_deletion(
        auth,
        request_id,
        body,
        idempotency_key=idempotency.idempotency_key,
        correlation_id=correlation_id,
    )
