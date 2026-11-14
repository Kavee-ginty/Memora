"""Pure, deterministic T15 engagement policies."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime

from memora.modules.engagement.constants import (
    DORMANT_AFTER_DAYS,
    DUE_WEIGHT,
    HEALTHY_DUE_RATIO_MAX,
    HEALTHY_SCORE_MIN,
    PREREQUISITE_WEIGHT,
    RECENT_EVIDENCE_WEIGHT,
    REEF_DORMANT,
    REEF_HEALTHY,
    REEF_NEEDS_CARE,
    REEF_NEW,
    REEF_THRIVING,
    RETRIEVABILITY_WEIGHT,
    THRIVING_DUE_RATIO_MAX,
    THRIVING_PREREQUISITE_RISK_MAX,
    THRIVING_SCORE_MIN,
    XP_COMEBACK_CAP,
    XP_COMEBACK_COMPLETION,
    XP_MISSION_COMPLETION,
    XP_NORMAL_CAP,
    XP_PER_PROTECTED_MEMORY,
    XP_PER_REPAIRED_MEMORY,
)


def calculate_xp(protected: int, repaired: int, *, comeback: bool) -> int:
    """Award only authoritative protected/repaired outcomes plus completion."""
    if protected < 0 or repaired < 0:
        raise ValueError("Outcome counts cannot be negative")
    if protected + repaired == 0:
        return 0
    amount = (
        protected * XP_PER_PROTECTED_MEMORY
        + repaired * XP_PER_REPAIRED_MEMORY
        + XP_MISSION_COMPLETION
        + (XP_COMEBACK_COMPLETION if comeback else 0)
    )
    return min(amount, XP_COMEBACK_CAP if comeback else XP_NORMAL_CAP)


def streak_qualification(
    mission_date: date,
    prior_dates: list[date],
    prior_grace_dates: list[date] | None = None,
) -> tuple[str, date | None]:
    """Return today's qualification and an optional immediately preceding grace date."""
    prior = sorted({value for value in prior_dates if value < mission_date})
    if not prior:
        return "mission_completed", None
    gap = (mission_date - prior[-1]).days
    if gap == 1:
        return "mission_completed", None
    if gap == 2:
        missing = mission_date.fromordinal(mission_date.toordinal() - 1)
        window_start = mission_date.fromordinal(mission_date.toordinal() - 7)
        grace_already_used = any(
            window_start <= value < mission_date for value in (prior_grace_dates or [])
        )
        if not grace_already_used:
            return "mission_completed", missing
    return "comeback_completed", None


@dataclass(frozen=True, slots=True)
class ReefInputs:
    evidence_count: int
    mean_retrievability: float
    due_ratio: float
    prerequisite_risk: float
    recent_evidence_score: float
    last_activity_at: datetime | None
    projected_at: datetime


@dataclass(frozen=True, slots=True)
class ReefDecision:
    condition: str
    health_score: float


def project_reef(inputs: ReefInputs) -> ReefDecision:
    """Project one canonical reef condition from authoritative bounded inputs."""
    if inputs.evidence_count < 0:
        raise ValueError("Evidence count cannot be negative")
    values = (
        inputs.mean_retrievability,
        inputs.due_ratio,
        inputs.prerequisite_risk,
        inputs.recent_evidence_score,
    )
    if any(value < 0 or value > 1 for value in values):
        raise ValueError("Reef inputs must be between zero and one")
    if inputs.evidence_count == 0:
        return ReefDecision(REEF_NEW, 0.5)

    score = round(
        RETRIEVABILITY_WEIGHT * inputs.mean_retrievability
        + DUE_WEIGHT * (1 - inputs.due_ratio)
        + PREREQUISITE_WEIGHT * (1 - inputs.prerequisite_risk)
        + RECENT_EVIDENCE_WEIGHT * inputs.recent_evidence_score,
        5,
    )
    if (
        inputs.last_activity_at is None
        or (inputs.projected_at.date() - inputs.last_activity_at.date()).days >= DORMANT_AFTER_DAYS
    ):
        return ReefDecision(REEF_DORMANT, score)
    if (
        score >= THRIVING_SCORE_MIN
        and inputs.due_ratio <= THRIVING_DUE_RATIO_MAX
        and inputs.prerequisite_risk <= THRIVING_PREREQUISITE_RISK_MAX
    ):
        return ReefDecision(REEF_THRIVING, score)
    if score >= HEALTHY_SCORE_MIN and inputs.due_ratio <= HEALTHY_DUE_RATIO_MAX:
        return ReefDecision(REEF_HEALTHY, score)
    return ReefDecision(REEF_NEEDS_CARE, score)
