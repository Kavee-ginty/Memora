"""Shared constants for the memory engine domain.

The reason-code and template-key sets are closed (Schema §10.3): every value
that can be persisted in ``memory_decisions`` must appear here. Producers of
new codes extend these tuples in the commit that needs them.
"""

from __future__ import annotations

from typing import Final

# Memory event types, mirroring the ``memory_events.event_type`` CHECK.
EVENT_EXPOSURE: Final = "exposure"
EVENT_ATTEMPT: Final = "attempt"
EVENT_REPAIR: Final = "repair"
EVENT_REGRADE: Final = "regrade"
EVENT_INVALIDATION: Final = "invalidation"
EVENT_MANUAL_REVIEW: Final = "manual_review"

MEMORY_EVENT_TYPES: Final[tuple[str, ...]] = (
    EVENT_EXPOSURE,
    EVENT_ATTEMPT,
    EVENT_REPAIR,
    EVENT_REGRADE,
    EVENT_INVALIDATION,
    EVENT_MANUAL_REVIEW,
)

# Scored event types drive a state transition; ``invalidation`` is metadata
# about a prior event and is recorded without a decision (the corrective
# state change arrives as a later ``manual_review`` event).
SCORED_MEMORY_EVENT_TYPES: Final[tuple[str, ...]] = (
    EVENT_ATTEMPT,
    EVENT_REPAIR,
    EVENT_REGRADE,
    EVENT_MANUAL_REVIEW,
)

# Allowlisted reason codes. Versioned with the policy; a decision must be
# explainable from its codes alone. The policy layer (TRD §9.3) appends the
# codes below; the engine core contributes the first block.
REASON_STATE_INITIALIZED: Final = "state_initialized"
REASON_EXPOSURE_RECORDED: Final = "exposure_recorded"
REASON_RECALL_SUCCESS: Final = "recall_success"
REASON_RECALL_LAPSE: Final = "recall_lapse"
REASON_REVIEW_SCHEDULED: Final = "review_scheduled"
REASON_OUT_OF_ORDER_EVIDENCE: Final = "out_of_order_evidence"
REASON_FIRST_REVIEW_BOUNDED: Final = "first_review_bounded"
REASON_EVIDENCE_JUSTIFIED_SCHEDULE: Final = "evidence_justified_schedule"
REASON_COMEBACK_ELAPSED: Final = "comeback_elapsed"
REASON_LOW_CONFIDENCE_DAMPED: Final = "low_confidence_damped"
REASON_WEAK_PREREQUISITE_RECOVER: Final = "weak_prerequisite_recover"
REASON_INTERVAL_BOUNDED: Final = "interval_bounded"

MEMORY_REASON_CODES: Final[tuple[str, ...]] = (
    REASON_STATE_INITIALIZED,
    REASON_EXPOSURE_RECORDED,
    REASON_RECALL_SUCCESS,
    REASON_RECALL_LAPSE,
    REASON_REVIEW_SCHEDULED,
    REASON_OUT_OF_ORDER_EVIDENCE,
    REASON_FIRST_REVIEW_BOUNDED,
    REASON_EVIDENCE_JUSTIFIED_SCHEDULE,
    REASON_COMEBACK_ELAPSED,
    REASON_LOW_CONFIDENCE_DAMPED,
    REASON_WEAK_PREREQUISITE_RECOVER,
    REASON_INTERVAL_BOUNDED,
)

# Explanation template keys rendered by the mobile client (T14). One key per
# user-facing scheduling explanation; the policy layer picks the governing
# key by precedence: weak prerequisite, comeback, low confidence, then the
# core outcome key.
TEMPLATE_STATE_INITIALIZED: Final = "memory.explanation.state_initialized"
TEMPLATE_EXPOSURE_RECORDED: Final = "memory.explanation.exposure_recorded"
TEMPLATE_RECALL_SUCCESS: Final = "memory.explanation.recall_success"
TEMPLATE_RECALL_LAPSE: Final = "memory.explanation.recall_lapse"
TEMPLATE_FIRST_REVIEW: Final = "memory.explanation.first_review_scheduled"
TEMPLATE_COMEBACK: Final = "memory.explanation.comeback"
TEMPLATE_LOW_CONFIDENCE: Final = "memory.explanation.low_confidence"
TEMPLATE_WEAK_PREREQUISITE: Final = "memory.explanation.weak_prerequisite"

MEMORY_EXPLANATION_TEMPLATE_KEYS: Final[tuple[str, ...]] = (
    TEMPLATE_STATE_INITIALIZED,
    TEMPLATE_EXPOSURE_RECORDED,
    TEMPLATE_RECALL_SUCCESS,
    TEMPLATE_RECALL_LAPSE,
    TEMPLATE_FIRST_REVIEW,
    TEMPLATE_COMEBACK,
    TEMPLATE_LOW_CONFIDENCE,
    TEMPLATE_WEAK_PREREQUISITE,
)

# Retrievability bands for client-facing summaries. The engine returns exact
# values internally, but the API reports bands only (TRD §9.4: clients never
# receive hidden candidate scores).
RETRIEVABILITY_BAND_FRESH: Final = "fresh"
RETRIEVABILITY_BAND_SETTLING: Final = "settling"
RETRIEVABILITY_BAND_FADING: Final = "fading"
RETRIEVABILITY_BAND_CRITICAL: Final = "critical"

RETRIEVABILITY_BAND_FRESH_MAX: Final = 1.0
RETRIEVABILITY_BAND_SETTLING_MAX: Final = 0.8
RETRIEVABILITY_BAND_FADING_MAX: Final = 0.5
