"""Application services for authoritative T15 read models and placement."""

from __future__ import annotations

import hashlib
import json
from datetime import UTC, date, datetime
from typing import Annotated
from uuid import UUID
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from fastapi import Depends

from memora.api.errors import ApiError
from memora.api.security import AuthenticatedRequest
from memora.api.v1.schemas.engagement import (
    HomeResponse,
    ProgressStatisticsResponse,
    ReefDetail,
    RewardGrant,
    RewardInventoryResponse,
    SeabedResponse,
)
from memora.core.config import Settings, get_settings
from memora.db.runtime import database_engine
from memora.modules.engagement.constants import REEF_POLICY_VERSION
from memora.modules.engagement.repository import EngagementRepository


class EngagementService:
    def __init__(self, repository: EngagementRepository) -> None:
        self.repository = repository

    def home(self, request: AuthenticatedRequest) -> HomeResponse:
        return HomeResponse.model_validate(self.repository.home(request.context, now=self._now()))

    def seabed(self, request: AuthenticatedRequest) -> SeabedResponse:
        return SeabedResponse(
            projection_version=REEF_POLICY_VERSION,
            reefs=self.repository.seabed(request.context, now=self._now()),
        )

    def reef(self, request: AuthenticatedRequest, subject_id: UUID) -> ReefDetail:
        return ReefDetail.model_validate(self.repository.reef(request.context, subject_id))

    def rewards(
        self, request: AuthenticatedRequest, grant_id: UUID | None
    ) -> RewardInventoryResponse:
        return RewardInventoryResponse(items=self.repository.rewards(request.context, grant_id))

    def update_placement(
        self,
        request: AuthenticatedRequest,
        grant_id: UUID,
        *,
        subject_id: UUID | None,
        placement_slot: str | None,
        version: int,
        idempotency_key: str,
    ) -> RewardGrant:
        return RewardGrant.model_validate(
            self.repository.update_placement(
                request.context,
                grant_id,
                subject_id=subject_id,
                placement_slot=placement_slot,
                version=version,
                idempotency_key=idempotency_key,
                request_hash=hashlib.sha256(
                    json.dumps(
                        [str(grant_id), str(subject_id), placement_slot, version],
                        separators=(",", ":"),
                    ).encode()
                ).hexdigest(),
                now=self._now(),
            )
        )

    def statistics(
        self,
        request: AuthenticatedRequest,
        *,
        start: date,
        end: date,
        timezone: str,
    ) -> ProgressStatisticsResponse:
        try:
            ZoneInfo(timezone)
        except (ValueError, ZoneInfoNotFoundError) as exc:
            raise ApiError(422, "validation_failed", "Enter a valid timezone.") from exc
        return ProgressStatisticsResponse.model_validate(
            self.repository.statistics(
                request.context,
                start=start,
                end=end,
                timezone=timezone,
            )
        )

    @staticmethod
    def _now() -> datetime:
        return datetime.now(UTC)


def get_engagement_service(
    settings: Annotated[Settings, Depends(get_settings)],
) -> EngagementService:
    if settings.database_url is None:
        raise RuntimeError("MEMORA_DATABASE_URL is required")
    return EngagementService(EngagementRepository(database_engine(settings.database_url)))
