"""Public T15 Home, progress, reward and statistics models."""

from __future__ import annotations

from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator

from memora.api.v1.schemas.common import CalendarDate, UtcDatetime, Version
from memora.api.v1.schemas.missions import MissionCompletionResult

ReefCondition = Literal["new", "thriving", "healthy", "needs_care", "dormant"]


class ReefSummary(BaseModel):
    subject_id: UUID
    condition: ReefCondition
    health_score: Annotated[float, Field(ge=0, le=1)]
    due_memory_count: Annotated[int, Field(ge=0)]
    projection_version: str
    source_watermark: str
    projected_at: UtcDatetime


class HomeMission(BaseModel):
    id: UUID
    subject_id: UUID
    status: Literal["planned", "started", "paused", "completed", "expired", "abandoned"]
    mission_date: CalendarDate
    estimated_minutes: Annotated[int, Field(ge=1, le=7)]
    planned_item_count: Annotated[int, Field(ge=1, le=7)]
    completion_summary: MissionCompletionResult | None = None


class HomeResponse(BaseModel):
    state: Literal["setup", "mission_ready", "mission_in_progress", "mission_complete", "cared_for"]
    mission: HomeMission | None
    reef: ReefSummary | None
    xp_balance: Annotated[int, Field(ge=0)]
    streak_days: Annotated[int, Field(ge=0)]
    server_time: UtcDatetime


class SeabedReef(ReefSummary):
    subject_name: str
    prerequisite_risk: Annotated[float, Field(ge=0, le=1)]
    recent_evidence_score: Annotated[float, Field(ge=0, le=1)]


class SeabedResponse(BaseModel):
    projection_version: str
    reefs: list[SeabedReef]


class RewardGrant(BaseModel):
    grant_id: UUID
    reward_code: str
    reward_type: Literal["decoration", "mora_cosmetic"]
    title: str
    asset_key: str
    granted_at: UtcDatetime
    placement_state: Literal["unplaced", "placed"]
    placed_subject_id: UUID | None
    placement_slot: str | None
    version: Version
    permitted_actions: list[Literal["place", "move", "remove"]]


class ReefDetail(SeabedReef):
    rewards: list[RewardGrant]


class RewardInventoryResponse(BaseModel):
    items: list[RewardGrant]


class RewardPlacementRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    subject_id: UUID | None = None
    placement_slot: Annotated[str | None, Field(min_length=1, max_length=50)] = None
    version: Version

    @model_validator(mode="after")
    def complete_placement(self) -> RewardPlacementRequest:
        if (self.subject_id is None) != (self.placement_slot is None):
            raise ValueError("subject_id and placement_slot must be supplied together")
        return self


class XpSeriesPoint(BaseModel):
    day: CalendarDate
    xp: int


class ProgressStatisticsResponse(BaseModel):
    period_start: CalendarDate
    period_end: CalendarDate
    timezone: str
    xp_earned: int
    missions_completed: Annotated[int, Field(ge=0)]
    memories_protected: Annotated[int, Field(ge=0)]
    memories_repaired: Annotated[int, Field(ge=0)]
    active_days: Annotated[int, Field(ge=0)]
    xp_series: list[XpSeriesPoint]
    summary: str
