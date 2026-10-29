from __future__ import annotations

import re
from datetime import date, datetime, time
from enum import StrEnum
from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, SecretStr, field_validator, model_validator

from memora.api.v1.schemas.common import Version

MAX_DAILY_REMINDERS = 3
_DISPLAY_NAME_WHITESPACE = re.compile(r"\s+")


class AccountStatus(StrEnum):
    ACTIVE = "active"
    SUSPENDED = "suspended"
    DELETION_PENDING = "deletion_pending"
    DELETED = "deleted"


class ConsentType(StrEnum):
    TERMS = "terms"
    PRIVACY = "privacy"
    MATERIAL_PROCESSING = "material_processing"
    MODEL_PROCESSING = "model_processing"
    NOTIFICATIONS = "notifications"


class ConsentDecision(StrEnum):
    GRANTED = "granted"
    DECLINED = "declined"
    WITHDRAWN = "withdrawn"


class SessionRevocationScope(StrEnum):
    CURRENT = "current"
    OTHER_SESSIONS = "other_sessions"
    ALL = "all"


class ProfileSummary(BaseModel):
    user_id: UUID
    display_name: str
    onboarding_completed: bool
    active_subject_id: UUID | None
    curriculum_version_id: UUID | None


class ConsentStatus(BaseModel):
    policy_id: ConsentType
    policy_version: str
    required: bool
    decision: ConsentDecision | None
    decided_at: datetime | None
    is_current: bool


class SubjectSummary(BaseModel):
    id: UUID
    code: str
    name: str
    curriculum_version_id: UUID
    curriculum_edition_code: str


class ActiveMissionSummary(BaseModel):
    id: UUID
    subject_id: UUID
    mission_date: date
    status: Literal["planned", "started", "paused"]


class PendingResourceSummary(BaseModel):
    id: UUID
    status: str
    updated_at: datetime


class CapabilityFlags(BaseModel):
    can_add_learning_material: bool
    can_start_mission: bool
    can_register_notifications: bool = True


class SessionBootstrapResponse(BaseModel):
    profile_summary: ProfileSummary
    account_status: AccountStatus
    consent_status: list[ConsentStatus]
    subjects: list[SubjectSummary]
    active_mission: ActiveMissionSummary | None
    pending_learning_updates: list[PendingResourceSummary]
    pending_privacy_requests: list[PendingResourceSummary]
    server_time: datetime
    capability_flags: CapabilityFlags


class SessionRevokeRequest(BaseModel):
    scope: SessionRevocationScope = SessionRevocationScope.CURRENT


class DeviceRegistrationRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    installation_id: UUID
    platform: Literal["android", "ios"]
    push_token: SecretStr = Field(
        min_length=16,
        max_length=4096,
        json_schema_extra={"writeOnly": True},
    )
    locale: Annotated[str, Field(min_length=2, max_length=35)]
    timezone: Annotated[str, Field(min_length=1, max_length=100)]
    app_version: Annotated[str, Field(min_length=1, max_length=50)]


class DeviceRegistrationResponse(BaseModel):
    id: UUID
    installation_id: UUID
    platform: Literal["android", "ios"]
    locale: str
    timezone: str
    app_version: str
    last_seen_at: datetime


class AccessibilityPreferences(BaseModel):
    model_config = ConfigDict(extra="forbid")

    schema_version: str = Field(default="1", pattern=r"^1$")
    reduced_motion: bool = False
    sound_enabled: bool = True
    haptics_enabled: bool = True
    timer_visible: bool = False
    high_contrast: bool = False


class ProfileResponse(BaseModel):
    user_id: UUID
    display_name: str
    locale: str
    timezone: str
    active_subject_id: UUID | None
    curriculum_version_id: UUID | None
    version: Version


class ProfileUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    version: Version
    display_name: Annotated[str, Field(min_length=1, max_length=100)] | None = None
    locale: Annotated[str, Field(min_length=2, max_length=35)] | None = None
    timezone: Annotated[str, Field(min_length=1, max_length=100)] | None = None

    @field_validator("display_name")
    @classmethod
    def normalize_display_name(cls, value: str | None) -> str | None:
        if value is None:
            return None
        normalized = _DISPLAY_NAME_WHITESPACE.sub(" ", value.strip())
        if not normalized or any(ord(character) < 32 for character in normalized):
            raise ValueError("display_name must contain visible characters")
        return normalized

    @model_validator(mode="after")
    def includes_change(self) -> ProfileUpdateRequest:
        if not ({"display_name", "locale", "timezone"} & self.model_fields_set):
            raise ValueError("At least one profile field is required")
        if any(getattr(self, field) is None for field in self.model_fields_set - {"version"}):
            raise ValueError("Profile fields cannot be null")
        return self


class ProfilePreferencesResponse(BaseModel):
    notifications_enabled: bool
    mission_enabled: bool
    reward_enabled: bool
    streak_enabled: bool
    quiet_start_local: time | None
    quiet_end_local: time | None
    preferred_window_start_local: time | None
    preferred_window_end_local: time | None
    timezone: str
    lock_screen_detail: Literal["minimal", "subject", "detailed"]
    max_daily_reminders: Annotated[int, Field(ge=0, le=MAX_DAILY_REMINDERS)]
    accessibility: AccessibilityPreferences
    version: Version


class ProfilePreferencesUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    version: Version
    notifications_enabled: bool | None = None
    mission_enabled: bool | None = None
    reward_enabled: bool | None = None
    streak_enabled: bool | None = None
    quiet_start_local: time | None = None
    quiet_end_local: time | None = None
    preferred_window_start_local: time | None = None
    preferred_window_end_local: time | None = None
    timezone: Annotated[str, Field(min_length=1, max_length=100)] | None = None
    lock_screen_detail: str | None = Field(default=None, pattern=r"^(minimal|subject|detailed)$")
    max_daily_reminders: Annotated[int, Field(ge=0, le=MAX_DAILY_REMINDERS)] | None = None
    accessibility: AccessibilityPreferences | None = None

    @model_validator(mode="after")
    def validate_patch(self) -> ProfilePreferencesUpdateRequest:
        changed = self.model_fields_set - {"version"}
        if not changed:
            raise ValueError("At least one preference field is required")
        for first, second in (
            ("quiet_start_local", "quiet_end_local"),
            ("preferred_window_start_local", "preferred_window_end_local"),
        ):
            present = {first, second} & self.model_fields_set
            if present and present != {first, second}:
                raise ValueError(f"{first} and {second} must be supplied together")
            if present and ((getattr(self, first) is None) != (getattr(self, second) is None)):
                raise ValueError(f"{first} and {second} must both be set or both be null")
        non_nullable = changed - {
            "quiet_start_local",
            "quiet_end_local",
            "preferred_window_start_local",
            "preferred_window_end_local",
        }
        if any(getattr(self, field) is None for field in non_nullable):
            raise ValueError("Non-nullable preferences cannot be null")
        return self


class ConsentResponse(BaseModel):
    policies: list[ConsentStatus]


class ConsentAcceptanceRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    policy_id: ConsentType
    policy_version: Annotated[str, Field(min_length=1, max_length=100)]
    accepted_scopes: Annotated[list[str], Field(min_length=1, max_length=20)]

    @model_validator(mode="after")
    def scopes_are_unique(self) -> ConsentAcceptanceRequest:
        if len(self.accepted_scopes) != len(set(self.accepted_scopes)):
            raise ValueError("accepted_scopes must not contain duplicates")
        return self


class ConsentAcceptanceResponse(BaseModel):
    id: UUID
    policy_id: ConsentType
    policy_version: str
    decision: ConsentDecision
    accepted_scopes: list[str]
    decided_at: datetime
