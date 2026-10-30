"""Expert-reviewed policy layer wrapped around the core engine (TRD §9.3).

The policy takes the deterministic transition from :mod:`.decide` and applies
the educational constraints the core must not know about:

- **First-review window** (PRD 012): the first retrieval is scheduled near
  the next day unless strong first-attempt evidence justifies a later start.
- **Low-confidence damping** (D4, TRD §9.5): events below the confidence
  floor move stability and difficulty only proportionally; at the floor the
  influence is full. Confidence is never treated as a calibrated probability.
- **Comeback handling** (PRD 015): after an absence longer than the
  threshold the actual elapsed time still drives retrievability, but the
  next review is capped to a welcoming, manageable interval. Progress is
  never erased.
- **Weak-prerequisite recovery** (TRD §9.3): a lapse on a concept whose
  prerequisite is currently weak pulls the next review earlier and flags
  Recover evidence for mission selection (T13 owns the mission itself).
- **Interval cap** (TRD §9.5): no scheduled interval exceeds the policy cap,
  so overdue work never compounds.

The layer is pure: same inputs and configuration versions reproduce the same
decision, and every emitted reason code and template key is validated against
the closed allowlists in :mod:`memora.modules.memory.constants`.
"""

from __future__ import annotations

import dataclasses
from dataclasses import dataclass
from datetime import datetime, timedelta

from memora.modules.memory.constants import (
    EVENT_EXPOSURE,
    MEMORY_EXPLANATION_TEMPLATE_KEYS,
    MEMORY_REASON_CODES,
    REASON_COMEBACK_ELAPSED,
    REASON_EVIDENCE_JUSTIFIED_SCHEDULE,
    REASON_FIRST_REVIEW_BOUNDED,
    REASON_INTERVAL_BOUNDED,
    REASON_LOW_CONFIDENCE_DAMPED,
    REASON_OUT_OF_ORDER_EVIDENCE,
    REASON_RECALL_LAPSE,
    REASON_WEAK_PREREQUISITE_RECOVER,
    SCORED_MEMORY_EVENT_TYPES,
    TEMPLATE_COMEBACK,
    TEMPLATE_FIRST_REVIEW,
    TEMPLATE_LOW_CONFIDENCE,
    TEMPLATE_WEAK_PREREQUISITE,
)
from memora.modules.memory.engine import fsrs
from memora.modules.memory.engine.config import DEFAULT_ENGINE_CONFIG, EngineConfig
from memora.modules.memory.engine.decide import (
    Decision,
    EventFacts,
    decide,
    schedule_next_review,
)
from memora.modules.memory.engine.state import LearnerConceptState, require_utc


@dataclass(frozen=True)
class PrerequisiteSignal:
    """Read-only graph/state signal about a concept's prerequisites.

    Computed by :mod:`memora.modules.memory.prerequisites`; the policy only
    reacts to it. A weak prerequisite never receives state writes here —
    Recover selection is T13's responsibility.
    """

    weak_prerequisite_concept_ids: tuple[str, ...] = ()

    @property
    def has_weak_prerequisites(self) -> bool:
        return bool(self.weak_prerequisite_concept_ids)


def decide_with_policy(
    state: LearnerConceptState | None,
    event: EventFacts,
    *,
    now: datetime,
    prerequisite_signal: PrerequisiteSignal | None = None,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> Decision:
    """Produce the authoritative, policy-bounded decision for one event."""
    now_utc = require_utc(now, "now")
    core = decide(state, event, now=now_utc, config=config)
    if REASON_OUT_OF_ORDER_EVIDENCE in core.reason_codes:
        # Stale evidence is a strict no-op: every policy bound guards new
        # schedules, and rescheduling from a stale event could only move a
        # decision the newer evidence already owns.
        return core
    result = core.result_state
    reason_codes = list(core.reason_codes)
    template_key = core.explanation_template_key

    if event.event_type in SCORED_MEMORY_EVENT_TYPES:
        result, next_review_at, damped = _apply_confidence_damping(
            state, event, result, now_utc, config
        )
        if damped:
            reason_codes.append(REASON_LOW_CONFIDENCE_DAMPED)
    else:
        next_review_at = core.next_review_at

    if core.previous_state is None:
        next_review_at, bounded_reason = _apply_first_review_window(
            event, next_review_at, now_utc, config
        )
        if bounded_reason is not None:
            reason_codes.append(bounded_reason)
            if event.event_type == EVENT_EXPOSURE:
                template_key = TEMPLATE_FIRST_REVIEW

    if state is not None:
        next_review_at, comeback = _apply_comeback_cap(
            state, event, next_review_at, now_utc, config
        )
        if comeback:
            reason_codes.append(REASON_COMEBACK_ELAPSED)

    if (
        prerequisite_signal is not None
        and prerequisite_signal.has_weak_prerequisites
        and REASON_RECALL_LAPSE in core.reason_codes
    ):
        reason_codes.append(REASON_WEAK_PREREQUISITE_RECOVER)
        next_review_at = _cap_at(
            next_review_at, now_utc + timedelta(days=config.recover_interval_max_days)
        )

    bounded_next, capped = _apply_interval_cap(next_review_at, now_utc, config)
    if capped:
        reason_codes.append(REASON_INTERVAL_BOUNDED)
    next_review_at = bounded_next

    template_key = _governing_template(reason_codes, template_key)
    result = dataclasses.replace(result, next_review_at=next_review_at)

    return Decision(
        previous_state=core.previous_state,
        result_state=result,
        retrievability_at_decision=core.retrievability_at_decision,
        next_review_at=next_review_at,
        reason_codes=_validated_reason_codes(reason_codes),
        explanation_template_key=_validated_template_key(template_key),
        engine_version=core.engine_version,
        policy_version=core.policy_version,
    )


# --------------------------------------------------------------------------
# policy steps
# --------------------------------------------------------------------------


def _apply_confidence_damping(
    state: LearnerConceptState | None,
    event: EventFacts,
    result: LearnerConceptState,
    now: datetime,
    config: EngineConfig,
) -> tuple[LearnerConceptState, datetime, bool]:
    """Scale a scored transition's stability/difficulty delta by confidence.

    Returns the damped state, the rescheduled review time, and whether
    damping actually reduced the influence. The schedule is always
    recomputed from the (possibly unchanged) stability so the damped and
    undamped paths stay identical when the influence is full.
    """
    scale = _influence_scale(event.confidence, config)
    if state is None:
        stability_anchor = config.stability_probe_days
        difficulty_anchor = config.difficulty_default
    else:
        stability_anchor = state.stability_days
        difficulty_anchor = state.difficulty

    damped_stability = fsrs.clamp(
        stability_anchor + (result.stability_days - stability_anchor) * scale,
        config.stability_min_days,
        config.stability_max_days,
    )
    damped_difficulty = fsrs.clamp(
        difficulty_anchor + (result.difficulty - difficulty_anchor) * scale,
        config.difficulty_min,
        config.difficulty_max,
    )
    damped_state = dataclasses.replace(
        result, stability_days=damped_stability, difficulty=damped_difficulty
    )
    return (
        damped_state,
        schedule_next_review(now, damped_stability, config),
        scale < 1.0,
    )


def _apply_first_review_window(
    event: EventFacts,
    next_review_at: datetime,
    now: datetime,
    config: EngineConfig,
) -> tuple[datetime, str | None]:
    """Clamp the first retrieval into the PRD 012 window.

    Strong first-attempt evidence may justify a later start; nothing
    justifies a start before the window floor.
    """
    floor = now + timedelta(hours=config.first_review_min_hours)
    ceiling = now + timedelta(hours=config.first_review_max_hours)
    strong_evidence = (
        event.event_type in SCORED_MEMORY_EVENT_TYPES
        and event.score is not None
        and event.score >= config.strong_evidence_score
    )
    if next_review_at < floor:
        return floor, REASON_FIRST_REVIEW_BOUNDED
    if next_review_at > ceiling:
        if strong_evidence:
            return next_review_at, REASON_EVIDENCE_JUSTIFIED_SCHEDULE
        return ceiling, REASON_FIRST_REVIEW_BOUNDED
    return next_review_at, None


def _apply_comeback_cap(
    state: LearnerConceptState,
    event: EventFacts,
    next_review_at: datetime,
    now: datetime,
    config: EngineConfig,
) -> tuple[datetime, bool]:
    """Cap the schedule after an absence; elapsed evidence stays untouched."""
    anchor = state.last_reviewed_at or state.first_exposed_at
    if not is_comeback_elapsed(anchor, event.observed_at, config=config):
        return next_review_at, False
    ceiling = now + timedelta(days=config.comeback_interval_max_days)
    return _cap_at(next_review_at, ceiling), True


def is_comeback_elapsed(
    anchor: datetime,
    at: datetime,
    *,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> bool:
    """Whether the gap between ``anchor`` and ``at`` is a comeback (PRD 015).

    Shared by the scheduling policy and the due-selection inputs so the flag
    a learner sees and the flag the planner ranks on cannot drift.
    """
    elapsed = (require_utc(at, "at") - require_utc(anchor, "anchor")).total_seconds() / 86400.0
    return elapsed > config.comeback_threshold_days


def _apply_interval_cap(
    next_review_at: datetime,
    now: datetime,
    config: EngineConfig,
) -> tuple[datetime, bool]:
    ceiling = now + timedelta(days=config.interval_max_days)
    if next_review_at > ceiling:
        return ceiling, True
    return next_review_at, False


def _governing_template(reason_codes: list[str], core_key: str) -> str:
    """Pick the client explanation key by policy precedence."""
    if REASON_WEAK_PREREQUISITE_RECOVER in reason_codes:
        return TEMPLATE_WEAK_PREREQUISITE
    if REASON_COMEBACK_ELAPSED in reason_codes:
        return TEMPLATE_COMEBACK
    if REASON_LOW_CONFIDENCE_DAMPED in reason_codes:
        return TEMPLATE_LOW_CONFIDENCE
    return core_key


# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------


def _influence_scale(confidence: float, config: EngineConfig) -> float:
    """1.0 at or above the floor, proportionally damped below it (D4)."""
    if confidence >= config.confidence_floor:
        return 1.0
    return fsrs.clamp(confidence / config.confidence_floor, 0.0, 1.0)


def _cap_at(value: datetime, ceiling: datetime) -> datetime:
    return ceiling if value > ceiling else value


def _validated_reason_codes(reason_codes: list[str]) -> tuple[str, ...]:
    for code in reason_codes:
        if code not in MEMORY_REASON_CODES:
            raise ValueError(f"reason code outside the allowlist: {code!r}")
    return tuple(reason_codes)


def _validated_template_key(template_key: str) -> str:
    if template_key not in MEMORY_EXPLANATION_TEMPLATE_KEYS:
        raise ValueError(f"template key outside the allowlist: {template_key!r}")
    return template_key
