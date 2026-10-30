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

# Due-selection vocabulary (TRD §9.4, PRD 013). These are inputs to T13's
# mission planner, not persisted decision codes: ``memory_decisions`` keeps
# its own closed allowlist above.
URGENCY_OVERDUE: Final = "overdue"
URGENCY_DUE: Final = "due"
URGENCY_NEAR_DUE: Final = "near_due"

URGENCY_BANDS: Final[tuple[str, ...]] = (
    URGENCY_OVERDUE,
    URGENCY_DUE,
    URGENCY_NEAR_DUE,
)

# The subset of the mission reason codes (TRD §9.5) that T11 can justify from
# memory state, graph signals and recent evidence. ``misconception_detected``
# and ``streak_preservation`` are added by the owning tasks (T13/T15).
SELECTION_REASON_OVERDUE: Final = "forgetting_curve_overdue"
SELECTION_REASON_RETENTION: Final = "daily_retention_protect"
SELECTION_REASON_ERROR_REPAIR: Final = "high_error_rate_repair"
SELECTION_REASON_WEAK_PREREQUISITE: Final = "weak_prerequisite_failure"
SELECTION_REASON_NEW_CONCEPT: Final = "new_concept_introduction"

SELECTION_REASON_CODES: Final[tuple[str, ...]] = (
    SELECTION_REASON_OVERDUE,
    SELECTION_REASON_RETENTION,
    SELECTION_REASON_ERROR_REPAIR,
    SELECTION_REASON_WEAK_PREREQUISITE,
    SELECTION_REASON_NEW_CONCEPT,
)

# Identity of the due-selection input contract. Bump when a field changes
# meaning so consumers (T13) can refuse mismatched inputs.
SELECTION_INPUT_VERSION: Final = "memory-selection-inputs/1"

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

# Confidence bands for evidence summaries (D12: the client receives bands,
# never raw state values). Floors mirror the retrievability band style so the
# mobile client can render one visual language for "how sure" and "how fresh".
CONFIDENCE_BAND_HIGH: Final = "high"
CONFIDENCE_BAND_MEDIUM: Final = "medium"
CONFIDENCE_BAND_LOW: Final = "low"

CONFIDENCE_BANDS: Final[tuple[str, ...]] = (
    CONFIDENCE_BAND_HIGH,
    CONFIDENCE_BAND_MEDIUM,
    CONFIDENCE_BAND_LOW,
)

CONFIDENCE_BAND_HIGH_FLOOR: Final = 0.75
CONFIDENCE_BAND_MEDIUM_FLOOR: Final = 0.5

# Copy keys for the plain-language due reason (PRD 016). T14 renders the key;
# ``message`` is the server-authored accessible fallback. Kept separate from
# the decision templates above because a due reason explains *selection* while
# a decision template explains a *schedule change*.
TEMPLATE_DUE_OVERDUE: Final = "memory.due_reason.overdue"
TEMPLATE_DUE_RETENTION: Final = "memory.due_reason.retention"
TEMPLATE_DUE_ERROR_REPAIR: Final = "memory.due_reason.error_repair"
TEMPLATE_DUE_WEAK_PREREQUISITE: Final = "memory.due_reason.weak_prerequisite"
TEMPLATE_DUE_NEW_CONCEPT: Final = "memory.due_reason.new_concept"

DUE_REASON_TEMPLATE_KEYS: Final[tuple[str, ...]] = (
    TEMPLATE_DUE_OVERDUE,
    TEMPLATE_DUE_RETENTION,
    TEMPLATE_DUE_ERROR_REPAIR,
    TEMPLATE_DUE_WEAK_PREREQUISITE,
    TEMPLATE_DUE_NEW_CONCEPT,
)

# History is bounded: evidence older than the window is summarised by the
# stored state, not replayed. The client never receives the raw event stream.
HISTORY_EVIDENCE_WINDOW_DAYS: Final = 90
