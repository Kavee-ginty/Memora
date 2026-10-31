from __future__ import annotations

import hashlib
import json
from typing import Annotated, Any
from uuid import UUID, uuid4

from fastapi import Depends

from memora.api.errors import ApiError
from memora.api.security import AuthenticatedRequest, require_recent_authentication
from memora.api.v1.schemas.privacy import (
    DeletionProofSummary,
    PrivacyDeletionCancelRequest,
    PrivacyDeletionRequest,
    PrivacyDeletionResponse,
    PrivacyExportRequest,
    PrivacyExportResponse,
)
from memora.core.config import Settings, get_settings
from memora.db.runtime import database_engine
from memora.modules.privacy.repository import PrivacyRepository


def _request_hash(data: dict[str, Any]) -> str:
    serialized = json.dumps(data, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(serialized.encode("utf-8")).hexdigest()


class PrivacyService:
    def __init__(self, repository: PrivacyRepository, settings: Settings) -> None:
        self.repository = repository
        self.settings = settings

    def create_export(
        self,
        auth: AuthenticatedRequest,
        body: PrivacyExportRequest,
        *,
        idempotency_key: str,
        correlation_id: UUID | None = None,
    ) -> PrivacyExportResponse:
        require_recent_authentication(auth, self.settings)
        request_hash = _request_hash({"format": body.format})
        request_id = uuid4()
        record = self.repository.create_export_request(
            auth.context,
            idempotency_key=idempotency_key,
            request_hash=request_hash,
            request_id=request_id,
            format_choice=body.format,
            correlation_id=correlation_id,
        )
        return PrivacyExportResponse(**record)

    def get_export(
        self,
        auth: AuthenticatedRequest,
        request_id: UUID,
    ) -> PrivacyExportResponse:
        record = self.repository.get_export_request(auth.context, request_id)
        return PrivacyExportResponse(**record)

    def get_export_download_archive(
        self,
        request_id: UUID,
        token: str,
    ) -> bytes:
        return self.repository.get_export_archive_for_download(request_id, token)

    def create_deletion(
        self,
        auth: AuthenticatedRequest,
        body: PrivacyDeletionRequest,
        *,
        idempotency_key: str,
        correlation_id: UUID | None = None,
    ) -> PrivacyDeletionResponse:
        require_recent_authentication(auth, self.settings)
        if not body.confirmed:
            raise ApiError(
                400,
                "confirmation_required",
                "Account deletion requires explicit confirmation.",
                "correct_input",
            )
        request_hash = _request_hash({"confirmed": body.confirmed})
        request_id = uuid4()
        record = self.repository.create_deletion_request(
            auth.context,
            idempotency_key=idempotency_key,
            request_hash=request_hash,
            request_id=request_id,
            correlation_id=correlation_id,
        )
        return self._to_deletion_response(record)

    def get_deletion(
        self,
        auth: AuthenticatedRequest,
        request_id: UUID,
    ) -> PrivacyDeletionResponse:
        record = self.repository.get_deletion_request(auth.context, request_id)
        return self._to_deletion_response(record)

    def cancel_deletion(
        self,
        auth: AuthenticatedRequest,
        request_id: UUID,
        body: PrivacyDeletionCancelRequest,
        *,
        idempotency_key: str,
        correlation_id: UUID | None = None,
    ) -> PrivacyDeletionResponse:
        request_hash = _request_hash({"reason": body.reason})
        record = self.repository.cancel_deletion_request(
            auth.context,
            request_id=request_id,
            idempotency_key=idempotency_key,
            request_hash=request_hash,
            reason=body.reason,
            correlation_id=correlation_id,
        )
        return self._to_deletion_response(record)

    @staticmethod
    def _to_deletion_response(data: dict[str, Any]) -> PrivacyDeletionResponse:
        proofs = [DeletionProofSummary(**p) for p in data.get("proofs", [])]
        return PrivacyDeletionResponse(
            id=data["id"],
            request_type="delete",
            status=data["status"],
            requested_at=data["requested_at"],
            completed_at=data.get("completed_at"),
            proofs=proofs,
            retention_exceptions=data.get("retention_exceptions", []),
            failure_code=data.get("failure_code"),
        )


def get_privacy_service(
    settings: Annotated[Settings, Depends(get_settings)],
) -> PrivacyService:
    return PrivacyService(
        PrivacyRepository(database_engine(settings.database_url)),
        settings,
    )
