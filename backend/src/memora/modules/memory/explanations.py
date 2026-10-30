"""Safe, plain-language explanations derived from allowlisted codes (PRD 016).

The engine persists reason codes and one explanation template key; the client
renders copy from the key. This module owns the server-authored fallback text
and the due-reason mapping so the API layer never composes prose inline.

Two hard rules:

* A message is derived only from an allowlisted code. There is no free text,
  no model output and no interpolation of stored evidence, so an explanation
  cannot leak learning text, scores or payload internals (D10, D12).
* A due reason explains *selection*; a decision template explains a *schedule
  change*. They are separate vocabularies on purpose.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Final

from memora.modules.memory.constants import (
    DUE_REASON_TEMPLATE_KEYS,
    MEMORY_EXPLANATION_TEMPLATE_KEYS,
    SELECTION_REASON_CODES,
    SELECTION_REASON_ERROR_REPAIR,
    SELECTION_REASON_NEW_CONCEPT,
    SELECTION_REASON_OVERDUE,
    SELECTION_REASON_RETENTION,
    SELECTION_REASON_WEAK_PREREQUISITE,
    TEMPLATE_COMEBACK,
    TEMPLATE_DUE_ERROR_REPAIR,
    TEMPLATE_DUE_NEW_CONCEPT,
    TEMPLATE_DUE_OVERDUE,
    TEMPLATE_DUE_RETENTION,
    TEMPLATE_DUE_WEAK_PREREQUISITE,
    TEMPLATE_EXPOSURE_RECORDED,
    TEMPLATE_FIRST_REVIEW,
    TEMPLATE_LOW_CONFIDENCE,
    TEMPLATE_RECALL_LAPSE,
    TEMPLATE_RECALL_SUCCESS,
    TEMPLATE_STATE_INITIALIZED,
    TEMPLATE_WEAK_PREREQUISITE,
)

# One template key per selection reason, in the same precedence order the
# selection module documents.
DUE_REASON_TEMPLATES: Final[dict[str, str]] = {
    SELECTION_REASON_WEAK_PREREQUISITE: TEMPLATE_DUE_WEAK_PREREQUISITE,
    SELECTION_REASON_ERROR_REPAIR: TEMPLATE_DUE_ERROR_REPAIR,
    SELECTION_REASON_OVERDUE: TEMPLATE_DUE_OVERDUE,
    SELECTION_REASON_NEW_CONCEPT: TEMPLATE_DUE_NEW_CONCEPT,
    SELECTION_REASON_RETENTION: TEMPLATE_DUE_RETENTION,
}

# Server-authored fallback copy. Short, neutral and free of scores, counts of
# failures or shaming language (PRD 015, UIX copy rules). T14 may replace the
# wording; the key is the contract.
TEMPLATE_MESSAGES: Final[dict[str, str]] = {
    TEMPLATE_STATE_INITIALIZED: "This concept joined your memory plan.",
    TEMPLATE_EXPOSURE_RECORDED: "This concept joined your memory plan.",
    TEMPLATE_RECALL_SUCCESS: "You recalled this concept, so the next review moved further out.",
    TEMPLATE_RECALL_LAPSE: "This review was missed, so the next review comes sooner.",
    TEMPLATE_FIRST_REVIEW: "The first review is planned for the next day.",
    TEMPLATE_COMEBACK: (
        "You were away for a while. Your progress is kept and the plan restarts gently."
    ),
    TEMPLATE_LOW_CONFIDENCE: (
        "The evidence for this update was limited, so the schedule changed only a little."
    ),
    TEMPLATE_WEAK_PREREQUISITE: (
        "A prerequisite concept needs repair, so this review is planned sooner."
    ),
    TEMPLATE_DUE_OVERDUE: "This review is overdue. A short review now brings it back on track.",
    TEMPLATE_DUE_RETENTION: "This review is due soon. A quick check keeps the memory strong.",
    TEMPLATE_DUE_ERROR_REPAIR: (
        "Recent answers on this concept missed more often than usual, so it is due for repair."
    ),
    TEMPLATE_DUE_WEAK_PREREQUISITE: (
        "A prerequisite concept needs attention, so this review is grouped with repair work."
    ),
    TEMPLATE_DUE_NEW_CONCEPT: "This concept is ready for its first review.",
}


@dataclass(frozen=True)
class DueReason:
    """The governing reason a concept is due, with renderable copy."""

    reason_code: str
    template_key: str
    message: str


def due_reason(reason_code: str) -> DueReason:
    """Map an allowlisted selection reason to its template key and message."""
    if reason_code not in SELECTION_REASON_CODES:
        raise ValueError(f"selection reason outside the allowlist: {reason_code!r}")
    template_key = DUE_REASON_TEMPLATES[reason_code]
    return DueReason(
        reason_code=reason_code,
        template_key=template_key,
        message=TEMPLATE_MESSAGES[template_key],
    )


def explanation_message(template_key: str) -> str:
    """Return the fallback copy for a persisted decision template key."""
    if template_key not in MEMORY_EXPLANATION_TEMPLATE_KEYS:
        raise ValueError(f"template key outside the allowlist: {template_key!r}")
    return TEMPLATE_MESSAGES[template_key]


def validate_explanations() -> None:
    """Fail fast if the vocabularies ever drift apart (import-time contract)."""
    if set(DUE_REASON_TEMPLATES) != set(SELECTION_REASON_CODES):
        raise RuntimeError("every selection reason needs exactly one due-reason template")
    if set(DUE_REASON_TEMPLATES.values()) != set(DUE_REASON_TEMPLATE_KEYS):
        raise RuntimeError("due-reason templates must match the published keys")
    if set(TEMPLATE_MESSAGES) != set(MEMORY_EXPLANATION_TEMPLATE_KEYS) | set(
        DUE_REASON_TEMPLATE_KEYS
    ):
        raise RuntimeError("every published template key needs exactly one message")


validate_explanations()
