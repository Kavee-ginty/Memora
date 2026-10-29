"""Shared API schemas."""

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

__all__ = [
    "ConsentAcceptanceRequest",
    "ConsentAcceptanceResponse",
    "ConsentResponse",
    "DeviceRegistrationRequest",
    "DeviceRegistrationResponse",
    "ProfilePreferencesResponse",
    "ProfilePreferencesUpdateRequest",
    "ProfileResponse",
    "ProfileUpdateRequest",
    "SessionBootstrapResponse",
    "SessionRevokeRequest",
]
