from __future__ import annotations

from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from memora.api.v1.schemas.common import UtcDatetime

PrivacyRequestStatus = Literal[
    "requested",
    "verifying",
    "processing",
    "completed",
    "failed",
    "cancelled",
]


class PrivacyExportRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    format: Literal["json"] = "json"


class PrivacyExportResponse(BaseModel):
    id: UUID
    request_type: Literal["export"] = "export"
    status: PrivacyRequestStatus
    requested_at: UtcDatetime
    completed_at: UtcDatetime | None = None
    download_url: str | None = None
    download_expires_at: UtcDatetime | None = None
    failure_code: str | None = None


class PrivacyDeletionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    confirmed: bool = True


class DeletionProofSummary(BaseModel):
    id: UUID
    scope: str
    provider: str
    target_fingerprint: str
    result: str
    verified_at: UtcDatetime


class PrivacyDeletionResponse(BaseModel):
    id: UUID
    request_type: Literal["delete"] = "delete"
    status: PrivacyRequestStatus
    requested_at: UtcDatetime
    completed_at: UtcDatetime | None = None
    proofs: list[DeletionProofSummary] = Field(default_factory=list)
    retention_exceptions: list[str] = Field(default_factory=list)
    failure_code: str | None = None


class PrivacyDeletionCancelRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    reason: Annotated[str, Field(max_length=256)] | None = None
