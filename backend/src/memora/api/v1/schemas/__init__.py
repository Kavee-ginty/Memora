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
from memora.api.v1.schemas.privacy import (
    DeletionProofSummary,
    PrivacyDeletionCancelRequest,
    PrivacyDeletionRequest,
    PrivacyDeletionResponse,
    PrivacyExportRequest,
    PrivacyExportResponse,
    PrivacyRequestStatus,
)

__all__ = [
    "ConsentAcceptanceRequest",
    "ConsentAcceptanceResponse",
    "ConsentResponse",
    "DeletionProofSummary",
    "DeviceRegistrationRequest",
    "DeviceRegistrationResponse",
    "PrivacyDeletionCancelRequest",
    "PrivacyDeletionRequest",
    "PrivacyDeletionResponse",
    "PrivacyExportRequest",
    "PrivacyExportResponse",
    "PrivacyRequestStatus",
    "ProfilePreferencesResponse",
    "ProfilePreferencesUpdateRequest",
    "ProfileResponse",
    "ProfileUpdateRequest",
    "SessionBootstrapResponse",
    "SessionRevokeRequest",
]
