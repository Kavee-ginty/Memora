"""Application service for the T13 Daily Mission API."""

from __future__ import annotations

import hashlib
import json
from datetime import UTC, datetime
from typing import Annotated, Any
from uuid import UUID

from fastapi import Depends

from memora.api.security import AuthenticatedRequest
from memora.api.v1.schemas.headers import RequestHeaders
from memora.api.v1.schemas.missions import (
    AttemptResult,
    MissionCompletionResult,
    MissionItemResponse,
    MissionManifest,
    MissionSummary,
    SubmitAttemptRequest,
    TodayMissionResponse,
)
from memora.core.config import Settings, get_settings
from memora.db.runtime import database_engine
from memora.modules.missions.repository import MissionRepository


class MissionService:
    def __init__(self, repository: MissionRepository) -> None:
        self.repository = repository

    def today(self, request: AuthenticatedRequest) -> TodayMissionResponse:
        row = self.repository.today(request.context, now=self._now())
        if row is None:
            return TodayMissionResponse(state="no_due", mission=None)
        summary = self._summary(row)
        state = {
            "planned": "mission_ready",
            "started": "mission_in_progress",
            "paused": "mission_in_progress",
            "completed": "mission_complete",
        }.get(summary.status, "no_due")
        return TodayMissionResponse(state=state, mission=summary)

    def get(self, request: AuthenticatedRequest, mission_id: UUID) -> MissionManifest:
        return self._manifest(self.repository.manifest(request.context, mission_id))

    def start(
        self,
        request: AuthenticatedRequest,
        mission_id: UUID,
        *,
        idempotency_key: str,
    ) -> MissionManifest:
        row = self.repository.start(
            request.context,
            mission_id,
            idempotency_key=idempotency_key,
            request_hash=self._hash("start", mission_id),
            now=self._now(),
        )
        return self._manifest(row)

    def item(
        self, request: AuthenticatedRequest, mission_id: UUID, item_id: UUID
    ) -> MissionItemResponse:
        return MissionItemResponse.model_validate(
            self.repository.get_item(request.context, mission_id, item_id)
        )

    def submit(
        self,
        request: AuthenticatedRequest,
        headers: RequestHeaders,
        mission_id: UUID,
        item_id: UUID,
        body: SubmitAttemptRequest,
    ) -> AttemptResult:
        request_hash = self._hash(
            "attempt",
            mission_id,
            item_id,
            body.model_dump(mode="json"),
        )
        row = self.repository.submit_attempt(
            request.context,
            mission_id,
            item_id,
            question_version_id=body.question_version_id,
            answer=body.response,
            client_operation_id=body.client_operation_id,
            request_hash=request_hash,
            answered_at=body.answered_at,
            offline_submission=body.offline_submission,
            elapsed_ms=body.elapsed_ms,
            app_version=headers.client_version,
            correlation_id=headers.correlation_id,
            now=self._now(),
        )
        return AttemptResult.model_validate(row)

    def skip(
        self,
        request: AuthenticatedRequest,
        mission_id: UUID,
        item_id: UUID,
        *,
        idempotency_key: str,
    ) -> AttemptResult:
        row = self.repository.skip(
            request.context,
            mission_id,
            item_id,
            idempotency_key=idempotency_key,
            request_hash=self._hash("skip", mission_id, item_id),
            now=self._now(),
        )
        return AttemptResult.model_validate(row)

    def pause(
        self,
        request: AuthenticatedRequest,
        mission_id: UUID,
        *,
        idempotency_key: str,
    ) -> MissionSummary:
        row = self.repository.pause(
            request.context,
            mission_id,
            idempotency_key=idempotency_key,
            request_hash=self._hash("pause", mission_id),
            now=self._now(),
        )
        return self._summary(row)

    def complete(
        self,
        request: AuthenticatedRequest,
        headers: RequestHeaders,
        mission_id: UUID,
        *,
        idempotency_key: str,
    ) -> MissionCompletionResult:
        row = self.repository.complete(
            request.context,
            mission_id,
            idempotency_key=idempotency_key,
            request_hash=self._hash("complete", mission_id),
            correlation_id=headers.correlation_id,
            now=self._now(),
        )
        return MissionCompletionResult.model_validate(row)

    def results(self, request: AuthenticatedRequest, mission_id: UUID) -> MissionCompletionResult:
        return MissionCompletionResult.model_validate(
            self.repository.results(request.context, mission_id)
        )

    @staticmethod
    def _summary(row: dict[str, Any]) -> MissionSummary:
        return MissionSummary(
            id=row["id"],
            subject_id=row["subject_id"],
            mission_date=row["mission_date"],
            mission_timezone=row["mission_timezone"],
            status=row["status"],
            estimated_minutes=row["estimated_minutes"],
            planned_item_count=row["planned_item_count"],
            completed_item_count=row["completed_item_count"],
            current_item_id=row["current_item_id"],
            due_reason=row["due_reason"],
            expires_at=row["expires_at"],
            version=row["row_version"],
        )

    @classmethod
    def _manifest(cls, row: dict[str, Any]) -> MissionManifest:
        return MissionManifest(mission=cls._summary(row["mission"]), items=row["items"])

    @staticmethod
    def _hash(*parts: Any) -> str:
        payload = json.dumps(parts, sort_keys=True, separators=(",", ":"), default=str)
        return hashlib.sha256(payload.encode()).hexdigest()

    @staticmethod
    def _now() -> datetime:
        return datetime.now(UTC)


def get_mission_service(
    settings: Annotated[Settings, Depends(get_settings)],
) -> MissionService:
    if settings.database_url is None:
        raise RuntimeError("MEMORA_DATABASE_URL is required")
    return MissionService(MissionRepository(database_engine(settings.database_url)))
