"""Public Daily Mission API models."""

from __future__ import annotations

from typing import Annotated, Any, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from memora.api.v1.schemas.common import CalendarDate, UtcDatetime, Version
from memora.modules.questions.models import AnswerPayload, PublicQuestion

MissionStatus = Literal["planned", "started", "paused", "completed", "expired", "abandoned"]
MissionType = Literal["protect", "repair", "recover", "discover", "challenge"]
MissionItemStatus = Literal["pending", "presented", "answered", "skipped", "cancelled"]
AttemptOutcome = Literal["recalled", "partial", "uncertain", "weak", "skipped"]


class MissionSummary(BaseModel):
    id: UUID
    subject_id: UUID
    mission_date: CalendarDate
    mission_timezone: str
    status: MissionStatus
    estimated_minutes: Annotated[int, Field(ge=1, le=7)]
    planned_item_count: Annotated[int, Field(ge=1, le=7)]
    completed_item_count: Annotated[int, Field(ge=0, le=7)]
    current_item_id: UUID | None
    due_reason: str
    expires_at: UtcDatetime
    version: Version


class TodayMissionResponse(BaseModel):
    state: Literal["no_due", "mission_ready", "mission_in_progress", "mission_complete"]
    mission: MissionSummary | None


class MissionManifestItem(BaseModel):
    id: UUID
    position: Annotated[int, Field(ge=0, le=6)]
    mission_type: MissionType
    question_type: Literal["single_choice", "multiple_choice", "numeric"]
    status: MissionItemStatus


class MissionManifest(BaseModel):
    mission: MissionSummary
    items: list[MissionManifestItem]


class AttemptResult(BaseModel):
    attempt_id: UUID | None
    grading_status: Literal["graded", "skipped"]
    outcome: AttemptOutcome
    feedback: str
    explanation: str | None
    explanation_available: bool
    repair_action: Literal["none", "repair_inserted", "review_concept", "confirm_or_appeal"]
    influence_limited: bool
    next_item_id: UUID | None
    can_complete: bool


class MissionItemResponse(BaseModel):
    id: UUID
    mission_id: UUID
    position: Annotated[int, Field(ge=0, le=6)]
    mission_type: MissionType
    status: MissionItemStatus
    selection_reason_codes: list[str]
    due_reason: str
    question: PublicQuestion
    result: AttemptResult | None


class SubmitAttemptRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    client_operation_id: UUID
    question_version_id: UUID
    response: AnswerPayload
    answered_at: UtcDatetime
    offline_submission: bool = False
    elapsed_ms: Annotated[int, Field(ge=0, le=86_400_000)] | None = None


class MissionCompletionResult(BaseModel):
    mission_id: UUID
    status: Literal["completed"]
    protected_count: Annotated[int, Field(ge=0, le=7)]
    repaired_count: Annotated[int, Field(ge=0, le=7)]
    skipped_count: Annotated[int, Field(ge=0, le=7)]
    completed_at: UtcDatetime
    engagement_status: Literal["pending"]
    next_suggested_action: Literal["home", "progress"]


class EmptyMutationRequest(BaseModel):
    """Explicit empty body keeps retry hashes stable across clients."""

    model_config = ConfigDict(extra="forbid")


def canonical_payload(value: BaseModel | dict[str, Any]) -> dict[str, Any]:
    if isinstance(value, BaseModel):
        return value.model_dump(mode="json")
    return value
