"""Allowlists and bounds for the question bank, grading and reports domain."""

from decimal import Decimal
from typing import Final

QUESTION_TYPES: Final[frozenset[str]] = frozenset(
    {"mcq", "numeric", "short_answer", "diagram_interpretation"}
)
OPTION_QUESTION_TYPES: Final[frozenset[str]] = frozenset({"mcq", "diagram_interpretation"})

SOURCE_CLASSES: Final[frozenset[str]] = frozenset(
    {"expert_verified", "teacher_authored", "ai_generated"}
)
SOURCE_PRECEDENCE: Final[dict[str, int]] = {
    "expert_verified": 0,
    "teacher_authored": 1,
    "ai_generated": 2,
}
# Schema 9.1: teacher-authored content is future-facing and may exist only behind a
# disabled workflow flag in the MVP. The flag is deliberately hard-disabled here.
TEACHER_CONTENT_ENABLED: Final[bool] = False

TRUST_LABELS: Final[dict[str, str]] = {
    "expert_verified": "Expert verified",
    "teacher_authored": "Teacher authored",
    "ai_generated": "AI generated",
}

REPORT_TYPES: Final[frozenset[str]] = frozenset(
    {
        "question_error",
        "answer_error",
        "explanation_error",
        "grading_dispute",
        "accessibility",
    }
)
REPORT_STATUSES: Final[frozenset[str]] = frozenset(
    {"submitted", "triaged", "under_review", "resolved", "dismissed"}
)
OPEN_REPORT_STATUSES: Final[frozenset[str]] = frozenset({"submitted", "triaged", "under_review"})
# These reports can suspend high-impact use of an attempt's evidence while review
# is open. T13 must call the attempt-evidence eligibility hook before consuming it.
LIMITING_REPORT_TYPES: Final[frozenset[str]] = frozenset({"grading_dispute", "answer_error"})
ATTEMPT_EVIDENCE_ELIGIBLE: Final[str] = "eligible"
ATTEMPT_EVIDENCE_LIMITED: Final[str] = "limited_pending_review"
MAPPING_ROLES: Final[frozenset[str]] = frozenset(
    {"primary", "supporting", "prerequisite", "misconception"}
)

CONTENT_SCHEMA_VERSION: Final[str] = "1"
RUBRIC_SCHEMA_VERSION: Final[str] = "1"

MIN_OPTIONS: Final[int] = 2
MAX_OPTIONS: Final[int] = 10
MAX_MEDIA_REFERENCES: Final[int] = 5
MAX_PROMPT_LENGTH: Final[int] = 5000
MAX_EXPLANATION_LENGTH: Final[int] = 5000
MAX_OPTION_TEXT_LENGTH: Final[int] = 1000
MAX_OPTION_EXPLANATION_LENGTH: Final[int] = 2000
MAX_SHORT_ANSWER_LENGTH: Final[int] = 4000
MAX_REPORT_DESCRIPTION_LENGTH: Final[int] = 2000
MAX_RUBRIC_CLAIMS: Final[int] = 20
MAX_CLAIM_VARIANTS: Final[int] = 20
MAX_CONCEPT_MAPPINGS: Final[int] = 20
MAX_QUESTION_CODE_LENGTH: Final[int] = 100
MAX_UNIT_LENGTH: Final[int] = 32
MAX_OPTION_KEY_LENGTH: Final[int] = 16
MAX_MEDIA_ID_LENGTH: Final[int] = 100
MAX_MEDIA_ALT_TEXT_LENGTH: Final[int] = 500
MIN_SIGNIFICANT_FIGURES: Final[int] = 1
MAX_SIGNIFICANT_FIGURES: Final[int] = 12

MAX_NUMERIC_ABSOLUTE_VALUE: Final[Decimal] = Decimal("1e12")
MAX_ABSOLUTE_TOLERANCE: Final[Decimal] = Decimal("1e12")
MAX_RELATIVE_TOLERANCE: Final[Decimal] = Decimal("1")
MAX_RUBRIC_MAX_SCORE: Final[Decimal] = Decimal("1000")

# Numeric column scales from the MVP schema. Values are quantized to these
# scales before hashing or bounds checks so PostgreSQL rounding cannot create a
# different canonical content hash or silently publish a zero value.
RUBRIC_MAX_SCORE_QUANTUM: Final[Decimal] = Decimal("0.001")
EVIDENCE_CEILING_QUANTUM: Final[Decimal] = Decimal("0.00001")
CONCEPT_WEIGHT_QUANTUM: Final[Decimal] = Decimal("0.00001")
VALIDATION_SCORE_QUANTUM: Final[Decimal] = Decimal("0.00001")

# Deterministic rubric grading cannot claim more confidence than this.
MAX_SHORT_ANSWER_CONFIDENCE: Final[Decimal] = Decimal("0.85")
MAX_SHORT_ANSWER_PARTIAL_CONFIDENCE: Final[Decimal] = Decimal("0.65")
MAX_SHORT_ANSWER_UNCERTAIN_CONFIDENCE: Final[Decimal] = Decimal("0.4")
MAX_SHORT_ANSWER_CONTRADICTION_CONFIDENCE: Final[Decimal] = Decimal("0.8")
LOW_CONFIDENCE_THRESHOLD: Final[Decimal] = Decimal("0.7")
AI_EVIDENCE_CEILING: Final[Decimal] = Decimal("0.9")
DEFAULT_MINIMUM_SUPPORTED_COVERAGE: Final[Decimal] = Decimal("0.5")

GRADER_VERSION_EXACT: Final[str] = "mcq-exact-v1"
GRADER_VERSION_NUMERIC: Final[str] = "numeric-v1"
GRADER_VERSION_SHORT_ANSWER: Final[str] = "short-answer-rubric-v1"

REPORT_CURSOR_VERSION: Final[int] = 1
REPORT_ENCRYPTION_CONTEXT: Final[bytes] = b"memora:question-report:v1"
