"""Response models for the memory read endpoints (API §10, D12).

Every field is a band, a stable identifier, a count or an allowlisted code.
Raw state values (stability, difficulty, forgetting risk, candidate scores),
event payloads and model internals never appear here.
"""

from __future__ import annotations

from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field

from memora.api.v1.schemas.common import PageMeta, UtcDatetime

RetrievabilityBand = Literal["fresh", "settling", "fading", "critical"]
ConfidenceBand = Literal["high", "medium", "low"]
ReviewWindow = Literal["overdue", "due", "near_due"]
MemoryEventType = Literal[
    "exposure",
    "attempt",
    "repair",
    "regrade",
    "invalidation",
    "manual_review",
]
SelectionReasonCode = Literal[
    "forgetting_curve_overdue",
    "daily_retention_protect",
    "high_error_rate_repair",
    "weak_prerequisite_failure",
    "new_concept_introduction",
]
DueReasonTemplateKey = Literal[
    "memory.due_reason.overdue",
    "memory.due_reason.retention",
    "memory.due_reason.error_repair",
    "memory.due_reason.weak_prerequisite",
    "memory.due_reason.new_concept",
]
DecisionReasonCode = Literal[
    "state_initialized",
    "exposure_recorded",
    "recall_success",
    "recall_lapse",
    "review_scheduled",
    "out_of_order_evidence",
    "first_review_bounded",
    "evidence_justified_schedule",
    "comeback_elapsed",
    "low_confidence_damped",
    "weak_prerequisite_recover",
    "interval_bounded",
]
DecisionTemplateKey = Literal[
    "memory.explanation.state_initialized",
    "memory.explanation.exposure_recorded",
    "memory.explanation.recall_success",
    "memory.explanation.recall_lapse",
    "memory.explanation.first_review_scheduled",
    "memory.explanation.comeback",
    "memory.explanation.low_confidence",
    "memory.explanation.weak_prerequisite",
]


class DueReasonExplanation(BaseModel):
    """Why this concept is due, in plain language (PRD 016)."""

    reason_code: SelectionReasonCode
    template_key: DueReasonTemplateKey
    message: str


class ConceptProgressItem(BaseModel):
    """One concept's progress and due reason for a subject."""

    concept_id: UUID
    concept_version_id: UUID
    stable_code: str
    title: str
    state_band: RetrievabilityBand
    confidence_band: ConfidenceBand
    review_window: ReviewWindow
    next_review_at: UtcDatetime
    last_reviewed_at: UtcDatetime | None
    exposure_count: int = Field(ge=0)
    eligible_review_count: int = Field(ge=0)
    lapse_count: int = Field(ge=0)
    is_new_concept: bool
    is_comeback: bool
    due_reason: DueReasonExplanation


class EvidenceSummary(BaseModel):
    """Bounded evidence summary; counts only, never payloads or scores.

    All counts are lifetime counts, so ``total_events`` always equals
    ``sum(counts_by_type.values())``. ``recent_events`` is the subset inside
    ``window_days``; per-type counts are deliberately not windowed so the
    summary stays additive and cheap to verify.
    """

    window_days: int = Field(ge=1, description="Length of the recency window in days.")
    total_events: int = Field(ge=0, description="Lifetime recorded evidence events.")
    recent_events: int = Field(
        ge=0, description="Evidence events observed inside the recency window."
    )
    eligible_events: int = Field(
        ge=0, description="Lifetime events that were eligible for scheduling."
    )
    counts_by_type: dict[MemoryEventType, int] = Field(
        description="Lifetime event counts per type; sums to total_events."
    )
    last_observed_at: UtcDatetime | None = Field(
        description="Most recent evidence timestamp, or null when none is recorded."
    )
    confidence_band: ConfidenceBand = Field(
        description="Banded evidence confidence; raw values are never returned."
    )


class SchedulingExplanation(BaseModel):
    """One stored scheduling decision and its allowlisted explanation."""

    decision_id: UUID
    decided_at: UtcDatetime
    trigger_event_type: MemoryEventType
    next_review_at: UtcDatetime
    reason_codes: list[DecisionReasonCode]
    template_key: DecisionTemplateKey
    message: str
    engine_version: str
    policy_version: str


class ConceptHistoryResponse(PageMeta):
    """Concept state, bounded evidence summary and paginated explanations."""

    concept_id: UUID
    concept_version_id: UUID
    stable_code: str
    title: str
    state_band: RetrievabilityBand
    next_review_at: UtcDatetime
    evidence: EvidenceSummary
    items: list[SchedulingExplanation]
