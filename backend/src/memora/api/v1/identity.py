from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Header, Request, Response, status

from memora.api.openapi import COMMON_ERROR_RESPONSES
from memora.api.operation_ids import OperationId
from memora.api.security import AuthenticatedRequest, get_authenticated_request
from memora.api.v1.schemas.headers import IdempotencyHeaders, RequestHeaders
from memora.api.v1.schemas.identity import (
    ConsentAcceptanceRequest,
    ConsentAcceptanceResponse,
    ConsentResponse,
    DeviceRegistrationRequest,
    DeviceRegistrationResponse,
    ProfilePreferencesResponse,
    ProfilePreferencesUpdateRequest,
    ProfileResponse,
    ProfileUpdateRequest,
    SessionBootstrapResponse,
    SessionRevokeRequest,
)
from memora.modules.identity.service import IdentityService, get_identity_service

router = APIRouter()


@router.get(
    "/profile",
    response_model=ProfileResponse,
    operation_id=OperationId.GET_PROFILE,
    tags=["profile"],
    summary="Get the authenticated profile",
    description="Returns the owner-scoped profile with its optimistic concurrency version.",
    responses=COMMON_ERROR_RESPONSES,
)
def get_profile(
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IdentityService, Depends(get_identity_service)],
) -> ProfileResponse:
    return service.profile(auth)


@router.patch(
    "/profile",
    response_model=ProfileResponse,
    operation_id=OperationId.UPDATE_PROFILE,
    tags=["profile"],
    summary="Update the authenticated profile",
    description=(
        "Idempotently updates allowlisted profile fields when the supplied version is current."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def update_profile(
    body: ProfileUpdateRequest,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IdentityService, Depends(get_identity_service)],
) -> ProfileResponse:
    return service.update_profile(auth, body, idempotency_key=idempotency.idempotency_key)


@router.get(
    "/profile/preferences",
    response_model=ProfilePreferencesResponse,
    operation_id=OperationId.GET_PROFILE_PREFERENCES,
    tags=["profile"],
    summary="Get profile preferences",
    description="Returns confirmed notification, accessibility and mission settings.",
    responses=COMMON_ERROR_RESPONSES,
)
def get_profile_preferences(
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IdentityService, Depends(get_identity_service)],
) -> ProfilePreferencesResponse:
    return service.preferences(auth)


@router.patch(
    "/profile/preferences",
    response_model=ProfilePreferencesResponse,
    operation_id=OperationId.UPDATE_PROFILE_PREFERENCES,
    tags=["profile"],
    summary="Update profile preferences",
    description="Idempotently updates explicit settings when the supplied version is current.",
    responses=COMMON_ERROR_RESPONSES,
)
def update_profile_preferences(
    body: ProfilePreferencesUpdateRequest,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IdentityService, Depends(get_identity_service)],
) -> ProfilePreferencesResponse:
    return service.update_preferences(auth, body, idempotency_key=idempotency.idempotency_key)


@router.get(
    "/session/bootstrap",
    response_model=SessionBootstrapResponse,
    operation_id=OperationId.BOOTSTRAP_SESSION,
    tags=["session"],
    summary="Bootstrap the authenticated session",
    description="Returns the bounded account, consent, subject, mission and pending-state summary.",
    responses=COMMON_ERROR_RESPONSES,
)
def bootstrap_session(
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IdentityService, Depends(get_identity_service)],
) -> SessionBootstrapResponse:
    return service.bootstrap(auth)


@router.post(
    "/session/revoke",
    status_code=status.HTTP_204_NO_CONTENT,
    operation_id=OperationId.REVOKE_SESSION,
    tags=["session"],
    summary="Revoke authenticated sessions",
    description=(
        "Idempotently revokes the requested Supabase session scope after recent authentication."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def revoke_session(
    body: SessionRevokeRequest,
    request: Request,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IdentityService, Depends(get_identity_service)],
) -> Response:
    service.revoke(
        auth,
        body,
        idempotency_key=idempotency.idempotency_key,
        request_id=request.state.request_id,
        correlation_id=request.state.correlation_id,
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/devices",
    response_model=DeviceRegistrationResponse,
    operation_id=OperationId.REGISTER_DEVICE,
    tags=["session"],
    summary="Register or refresh a notification device",
    description="Idempotently stores an encrypted push token for the authenticated installation.",
    responses={
        status.HTTP_201_CREATED: {
            "model": DeviceRegistrationResponse,
            "description": "A new device registration was created.",
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def register_device(
    body: DeviceRegistrationRequest,
    response: Response,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IdentityService, Depends(get_identity_service)],
) -> DeviceRegistrationResponse:
    result, created = service.register_device(
        auth,
        body,
        idempotency_key=idempotency.idempotency_key,
    )
    response.status_code = status.HTTP_201_CREATED if created else status.HTTP_200_OK
    return result


@router.delete(
    "/devices/{device_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    operation_id=OperationId.DELETE_DEVICE,
    tags=["session"],
    summary="Remove a notification device",
    description="Idempotently revokes an authenticated user's device registration.",
    responses=COMMON_ERROR_RESPONSES,
)
def delete_device(
    device_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IdentityService, Depends(get_identity_service)],
) -> Response:
    service.delete_device(auth, device_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get(
    "/consent",
    response_model=ConsentResponse,
    operation_id=OperationId.GET_CONSENT,
    tags=["profile"],
    summary="Get current consent status",
    description="Returns configured policy versions and the authenticated user's latest decisions.",
    responses=COMMON_ERROR_RESPONSES,
)
def get_consent(
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IdentityService, Depends(get_identity_service)],
) -> ConsentResponse:
    return service.consent(auth)


@router.post(
    "/consent/acceptances",
    response_model=ConsentAcceptanceResponse,
    status_code=status.HTTP_201_CREATED,
    operation_id=OperationId.ACCEPT_CONSENT,
    tags=["profile"],
    summary="Accept a current consent policy",
    description=(
        "Idempotently appends evidence for the authenticated user's current policy version."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def accept_consent(
    body: ConsentAcceptanceRequest,
    headers: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[IdentityService, Depends(get_identity_service)],
) -> ConsentAcceptanceResponse:
    return service.accept_consent(
        auth,
        body,
        idempotency_key=idempotency.idempotency_key,
        locale=headers.accept_language,
    )
