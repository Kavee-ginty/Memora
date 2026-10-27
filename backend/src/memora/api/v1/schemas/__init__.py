"""Shared API schemas."""

from memora.api.v1.schemas.identity import (
    ConsentAcceptanceRequest,
    ConsentAcceptanceResponse,
    ConsentResponse,
    DeviceRegistrationRequest,
    DeviceRegistrationResponse,
    SessionBootstrapResponse,
    SessionRevokeRequest,
)

__all__ = [
    "ConsentAcceptanceRequest",
    "ConsentAcceptanceResponse",
    "ConsentResponse",
    "DeviceRegistrationRequest",
    "DeviceRegistrationResponse",
    "SessionBootstrapResponse",
    "SessionRevokeRequest",
]
