"""The pure decision function of the memory engine.

``decide`` is the only place a due date is ever produced (TRD §4: no model
output may set due dates — and nothing but this deterministic function does).
It takes the current state, one event's facts and an explicit ``now``, and
returns the next state plus the reason codes and explanation key that
describe the decision.

Policy bounds (first-review window, overdue caps, comeback handling,
low-confidence damping) layer on top of this function; this module performs
the core FSRS-style transition only.
"""

from __future__ import annotations

import dataclasses
from dataclasses import dataclass
from datetime import datetime

from memora.modules.memory.constants import (
    EVENT_EXPOSURE,
    MEMORY_EVENT_TYPES,
    REASON_EXPOSURE_RECORDED,
    REASON_OUT_OF_ORDER_EVIDENCE,
    REASON_RECALL_LAPSE,
    REASON_RECALL_SUCCESS,
    REASON_REVIEW_SCHEDULED,
    REASON_STATE_INITIALIZED,
    SCORED_MEMORY_EVENT_TYPES,
    TEMPLATE_EXPOSURE_RECORDED,
    TEMPLATE_RECALL_LAPSE,
    TEMPLATE_RECALL_SUCCESS,
    TEMPLATE_STATE_INITIALIZED,
)
from memora.modules.memory.engine import fsrs
from memora.modules.memory.engine.config import DEFAULT_ENGINE_CONFIG, EngineConfig
from memora.modules.memory.engine.state import LearnerConceptState, require_utc


@dataclass(frozen=True)
class EventFacts:
    """Normalised evidence for one memory event of one concept.

    ``score`` is required for scored event types and must be ``None`` for
    ``exposure``. ``observed_at`` anchors elapsed-time math; ``now`` anchors
    scheduling.
    """

    event_type: str
    observed_at: datetime
    confidence: float
    score: float | None = None

    def __post_init__(self) -> None:
        if self.event_type not in MEMORY_EVENT_TYPES:
            raise ValueError(f"unknown memory event type: {self.event_type!r}")
        require_utc(self.observed_at, "observed_at")
        if not 0.0 <= self.confidence <= 1.0:
            raise ValueError("confidence must be within [0, 1]")
        if self.event_type == EVENT_EXPOSURE:
            if self.score is not None:
                raise ValueError("exposure events carry no score")
        elif self.event_type in SCORED_MEMORY_EVENT_TYPES:
            if self.score is None:
                raise ValueError(f"event type {self.event_type!r} requires a score")
            if not 0.0 <= self.score <= 1.0:
                raise ValueError("score must be within [0, 1]")


@dataclass(frozen=True)
class Decision:
    """The authoritative output for one trigger event.

    ``previous_state`` is ``None`` when the event establishes the concept's
    first state; the persistence layer records that bootstrap explicitly.
    """

    previous_state: LearnerConceptState | None
    result_state: LearnerConceptState
    retrievability_at_decision: float
    next_review_at: datetime
    reason_codes: tuple[str, ...]
    explanation_template_key: str
    engine_version: str
    policy_version: str


def decide(
    state: LearnerConceptState | None,
    event: EventFacts,
    *,
    now: datetime,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> Decision:
    """Compute the next memory state and schedule from one event.

    Raises ``ValueError`` on inputs outside the engine contract. The result
    is a pure function of ``(state, event, now, config)``: same inputs and
    configuration versions reproduce the identical decision.
    """
    now_utc = require_utc(now, "now")
    if state is None:
        return _decide_bootstrap(event, now_utc, config)
    if event.event_type == EVENT_EXPOSURE:
        return _decide_exposure(state, event, now_utc, config)
    return _decide_scored(state, event, now_utc, config)


# --------------------------------------------------------------------------
# bootstrap: the event establishes the concept's first state
# --------------------------------------------------------------------------


def _decide_bootstrap(
    event: EventFacts,
    now: datetime,
    config: EngineConfig,
) -> Decision:
    first_exposed_at = event.observed_at
    reason_codes: list[str] = [REASON_STATE_INITIALIZED]
    confidence = fsrs.clamp(event.confidence, 0.0, 1.0)

    if event.event_type == EVENT_EXPOSURE:
        stability = config.exposure_initial_stability_days
        difficulty = config.difficulty_default
        retrievability_at_decision = 1.0
        result = LearnerConceptState(
            difficulty=difficulty,
            stability_days=stability,
            last_retrievability=retrievability_at_decision,
            evidence_confidence=confidence,
            first_exposed_at=first_exposed_at,
            last_reviewed_at=None,
            next_review_at=_schedule(now, stability, config),
            exposure_count=1,
        )
        reason_codes.extend([REASON_EXPOSURE_RECORDED, REASON_REVIEW_SCHEDULED])
        template_key = TEMPLATE_STATE_INITIALIZED
    else:
        grade = fsrs.map_score_to_grade(_require_score(event), config=config)
        # Without a prior review the elapsed retrievability is derived from
        # the probe stability so the first attempt still sits on the curve.
        retrievability_at_decision = fsrs.retrievability(
            config.stability_probe_days, first_exposed_at, first_exposed_at, config=config
        )
        stability = _transition_stability(
            config.stability_probe_days,
            config.difficulty_default,
            grade,
            retrievability_at_decision,
            config=config,
        )
        difficulty = fsrs.initial_difficulty(grade, config=config)
        is_lapse = not grade.is_recall
        result = LearnerConceptState(
            difficulty=difficulty,
            stability_days=stability,
            last_retrievability=retrievability_at_decision,
            evidence_confidence=confidence,
            first_exposed_at=first_exposed_at,
            last_reviewed_at=event.observed_at,
            next_review_at=_schedule(now, stability, config),
            eligible_review_count=1,
            lapse_count=1 if is_lapse else 0,
        )
        reason_codes.append(REASON_RECALL_LAPSE if is_lapse else REASON_RECALL_SUCCESS)
        reason_codes.append(REASON_REVIEW_SCHEDULED)
        template_key = TEMPLATE_RECALL_LAPSE if is_lapse else TEMPLATE_RECALL_SUCCESS

    return Decision(
        previous_state=None,
        result_state=result,
        retrievability_at_decision=retrievability_at_decision,
        next_review_at=result.next_review_at,
        reason_codes=tuple(reason_codes),
        explanation_template_key=template_key,
        engine_version=config.engine_version,
        policy_version=config.policy_version,
    )


# --------------------------------------------------------------------------
# exposure on an existing state: record evidence, keep the schedule
# --------------------------------------------------------------------------


def _decide_exposure(
    state: LearnerConceptState,
    event: EventFacts,
    now: datetime,
    config: EngineConfig,
) -> Decision:
    anchor = state.last_reviewed_at or state.first_exposed_at
    retrievability_at_decision = fsrs.retrievability(
        state.stability_days, anchor, event.observed_at, config=config
    )
    reason_codes: list[str] = [REASON_EXPOSURE_RECORDED]
    if event.observed_at < anchor:
        reason_codes.append(REASON_OUT_OF_ORDER_EVIDENCE)

    result = state.with_counts(exposure_delta=1)
    result = _replace(
        result,
        evidence_confidence=fsrs.blend_confidence(
            state.evidence_confidence, event.confidence, config=config
        ),
        last_retrievability=retrievability_at_decision,
    )

    return Decision(
        previous_state=state,
        result_state=result,
        retrievability_at_decision=retrievability_at_decision,
        next_review_at=result.next_review_at,
        reason_codes=tuple(reason_codes),
        explanation_template_key=TEMPLATE_EXPOSURE_RECORDED,
        engine_version=config.engine_version,
        policy_version=config.policy_version,
    )


# --------------------------------------------------------------------------
# scored event on an existing state: the core review transition
# --------------------------------------------------------------------------


def _decide_scored(
    state: LearnerConceptState,
    event: EventFacts,
    now: datetime,
    config: EngineConfig,
) -> Decision:
    grade = fsrs.map_score_to_grade(_require_score(event), config=config)
    anchor = state.last_reviewed_at or state.first_exposed_at
    reason_codes: list[str] = []
    if event.observed_at < anchor:
        reason_codes.append(REASON_OUT_OF_ORDER_EVIDENCE)

    retrievability_at_review = fsrs.retrievability(
        state.stability_days, anchor, event.observed_at, config=config
    )
    stability = _transition_stability(
        state.stability_days, state.difficulty, grade, retrievability_at_review, config=config
    )
    difficulty = fsrs.next_difficulty(state.difficulty, grade, config=config)
    confidence = fsrs.blend_confidence(state.evidence_confidence, event.confidence, config=config)

    result = _replace(
        state,
        difficulty=difficulty,
        stability_days=stability,
        last_retrievability=retrievability_at_review,
        evidence_confidence=confidence,
        last_reviewed_at=event.observed_at,
        next_review_at=_schedule(now, stability, config),
    ).with_counts(
        review_delta=1,
        lapse_delta=0 if grade.is_recall else 1,
    )

    reason_codes.append(REASON_RECALL_LAPSE if not grade.is_recall else REASON_RECALL_SUCCESS)
    reason_codes.append(REASON_REVIEW_SCHEDULED)
    template_key = TEMPLATE_RECALL_LAPSE if not grade.is_recall else TEMPLATE_RECALL_SUCCESS

    return Decision(
        previous_state=state,
        result_state=result,
        retrievability_at_decision=retrievability_at_review,
        next_review_at=result.next_review_at,
        reason_codes=tuple(reason_codes),
        explanation_template_key=template_key,
        engine_version=config.engine_version,
        policy_version=config.policy_version,
    )


# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------


def _transition_stability(
    stability_days: float,
    difficulty: float,
    grade: fsrs.Grade,
    retrievability_at_review: float,
    *,
    config: EngineConfig,
) -> float:
    if grade.is_recall:
        return fsrs.stability_after_recall(
            stability_days, grade, retrievability_at_review, config=config
        )
    return fsrs.stability_after_lapse(
        stability_days, difficulty, retrievability_at_review, config=config
    )


def _schedule(now: datetime, stability_days: float, config: EngineConfig) -> datetime:
    interval_seconds = fsrs.interval_for_retention(stability_days, config=config) * 86400.0
    return datetime.fromtimestamp(now.timestamp() + interval_seconds, tz=now.tzinfo)


def _require_score(event: EventFacts) -> float:
    if event.score is None:
        raise ValueError(f"event type {event.event_type!r} requires a score")
    return event.score


def _replace(state: LearnerConceptState, **changes: float | datetime | None) -> LearnerConceptState:
    return dataclasses.replace(state, **changes)  # type: ignore[arg-type]
