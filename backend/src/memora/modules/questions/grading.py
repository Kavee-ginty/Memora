"""Deterministic grading for MCQ, numeric and bounded short-answer questions.

The grader returns normalized evidence only. It never returns rubric internals,
hidden reasoning, expected values or raw student answers. Low-confidence and
unresolved outcomes carry an explicit influence limit for downstream memory
policy.
"""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from decimal import ROUND_HALF_UP, Decimal, InvalidOperation, localcontext
from typing import Any, Literal

from memora.modules.questions.constants import (
    GRADER_VERSION_EXACT,
    GRADER_VERSION_NUMERIC,
    GRADER_VERSION_SHORT_ANSWER,
    LOW_CONFIDENCE_THRESHOLD,
    MAX_SHORT_ANSWER_CONFIDENCE,
    MAX_SHORT_ANSWER_CONTRADICTION_CONFIDENCE,
    MAX_SHORT_ANSWER_PARTIAL_CONFIDENCE,
    MAX_SHORT_ANSWER_UNCERTAIN_CONFIDENCE,
    OPTION_QUESTION_TYPES,
)
from memora.modules.questions.models import (
    AnswerPayload,
    ChoiceContent,
    ClaimRubricPayload,
    ExactRubricPayload,
    MultipleChoiceAnswer,
    NumericAnswer,
    NumericContent,
    NumericRubricPayload,
    NumericTolerance,
    QuestionSnapshot,
    ShortAnswerContent,
    ShortAnswerText,
    SingleChoiceAnswer,
)
from memora.modules.questions.normalization import normalize_text
from memora.modules.questions.short_answer import ClaimEvaluator, evaluate_claims
from memora.modules.questions.validation import (
    QuestionValidationError,
    parse_answer_payload,
    validate_answer_against_question,
)

SCORE_QUANTUM = Decimal("0.00001")
ZERO = Decimal("0")
ONE = Decimal("1")
PARTIAL_NUMERIC_SCORE = Decimal("0.5")

Classification = Literal[
    "correct",
    "partial",
    "incorrect",
    "misconception",
    "ungradable",
    "invalidated",
]
PublicOutcome = Literal["recalled", "partial", "uncertain", "weak"]
RepairAction = Literal["none", "review_concept", "confirm_or_appeal"]
GraderType = Literal["exact", "numeric", "rubric_model"]


@dataclass(frozen=True, slots=True)
class GradeOutcome:
    score: Decimal
    classification: Classification
    confidence: Decimal
    grader_type: GraderType
    grader_version: str
    public_outcome: PublicOutcome
    feedback_code: str
    feedback: str
    explanation_available: bool
    repair_action: RepairAction
    influence_limited: bool
    evidence: dict[str, Any]


def grade_answer(
    snapshot: QuestionSnapshot,
    answer: Mapping[str, Any] | AnswerPayload,
    *,
    evaluator: ClaimEvaluator | None = None,
) -> GradeOutcome:
    """Grade one already-validated answer against its pinned version."""

    try:
        parsed = answer if _is_answer_model(answer) else parse_answer_payload(answer)
    except QuestionValidationError as exc:
        return _ungradable_outcome(snapshot, "answer_invalid", exc.message)
    try:
        validate_answer_against_question(
            snapshot.question_type,
            snapshot.content,
            parsed,
            {option.option_key for option in snapshot.options},
        )
    except QuestionValidationError as exc:
        return _ungradable_outcome(snapshot, "answer_invalid", exc.message)

    if snapshot.question_type in OPTION_QUESTION_TYPES:
        return _grade_choice(snapshot, parsed)
    if snapshot.question_type == "numeric":
        return _grade_numeric(snapshot, parsed)
    if snapshot.question_type == "short_answer":
        return _grade_short_answer(snapshot, parsed, evaluator)
    raise QuestionValidationError(
        "question_type_invalid",
        "The question type is not supported.",
        "question_type",
    )


def _is_answer_model(value: object) -> bool:
    return isinstance(
        value,
        (SingleChoiceAnswer, MultipleChoiceAnswer, NumericAnswer, ShortAnswerText),
    )


def _grade_choice(
    snapshot: QuestionSnapshot,
    answer: SingleChoiceAnswer | MultipleChoiceAnswer | NumericAnswer | ShortAnswerText,
) -> GradeOutcome:
    if not isinstance(snapshot.content, ChoiceContent) or not isinstance(
        snapshot.rubric.payload, ExactRubricPayload
    ):
        raise QuestionValidationError(
            "rubric_invalid",
            "Stored grading rules do not match the question type.",
            "rubric",
        )
    if not isinstance(answer, (SingleChoiceAnswer, MultipleChoiceAnswer)):
        return _ungradable_outcome(snapshot, "answer_invalid", "The answer could not be graded.")

    correct_keys = snapshot.correct_option_keys()
    selected = frozenset(answer.option_keys)
    matched = selected == correct_keys
    confidence = _cap(snapshot.rubric.evidence_ceiling, ONE)
    evidence = {
        "schema_version": "1",
        "reason_code": "exact_match" if matched else "option_set_mismatch",
        "selected_option_count": len(selected),
        "correct_option_count": len(correct_keys),
    }
    if matched:
        return _outcome(
            snapshot,
            score=ONE,
            classification="correct",
            confidence=confidence,
            grader_type="exact",
            grader_version=GRADER_VERSION_EXACT,
            public_outcome="recalled",
            feedback_code="correct",
            feedback="Correct.",
            repair_action="none",
            evidence=evidence,
        )
    return _outcome(
        snapshot,
        score=ZERO,
        classification="incorrect",
        confidence=confidence,
        grader_type="exact",
        grader_version=GRADER_VERSION_EXACT,
        public_outcome="weak",
        feedback_code="incorrect",
        feedback="Not quite. Review this concept.",
        repair_action="review_concept",
        evidence=evidence,
    )


def _grade_numeric(
    snapshot: QuestionSnapshot,
    answer: SingleChoiceAnswer | MultipleChoiceAnswer | NumericAnswer | ShortAnswerText,
) -> GradeOutcome:
    if not isinstance(snapshot.content, NumericContent) or not isinstance(
        snapshot.rubric.payload, NumericRubricPayload
    ):
        raise QuestionValidationError(
            "rubric_invalid",
            "Stored grading rules do not match the question type.",
            "rubric",
        )
    if not isinstance(answer, NumericAnswer):
        return _ungradable_outcome(snapshot, "answer_invalid", "The answer could not be graded.")

    rubric = snapshot.rubric.payload
    unit_status = _unit_status(answer.unit, rubric)
    if unit_status in {"missing", "mismatch"}:
        reason = "unit_missing" if unit_status == "missing" else "unit_mismatch"
        return _outcome(
            snapshot,
            score=ZERO,
            classification="incorrect",
            confidence=_cap(snapshot.rubric.evidence_ceiling, ONE),
            grader_type="numeric",
            grader_version=GRADER_VERSION_NUMERIC,
            public_outcome="weak",
            feedback_code=reason,
            feedback=(
                "Include the expected unit, then try again."
                if reason == "unit_missing"
                else "Check the unit and try again."
            ),
            repair_action="review_concept",
            evidence={
                "schema_version": "1",
                "reason_code": reason,
                "unit_status": unit_status,
                "significant_figures": rubric.significant_figures,
            },
        )

    value = answer.value
    expected = rubric.expected_value
    if not rubric.allow_negative and value < 0:
        return _outcome(
            snapshot,
            score=ZERO,
            classification="incorrect",
            confidence=_cap(snapshot.rubric.evidence_ceiling, ONE),
            grader_type="numeric",
            grader_version=GRADER_VERSION_NUMERIC,
            public_outcome="weak",
            feedback_code="negative_not_allowed",
            feedback="This question expects a non-negative value.",
            repair_action="review_concept",
            evidence={
                "schema_version": "1",
                "reason_code": "negative_not_allowed",
                "unit_status": unit_status,
                "significant_figures": rubric.significant_figures,
            },
        )
    if rubric.significant_figures is not None:
        value = _round_significant(value, rubric.significant_figures)
        expected = _round_significant(expected, rubric.significant_figures)

    confidence = _cap(snapshot.rubric.evidence_ceiling, ONE)
    base_evidence = {
        "schema_version": "1",
        "unit_status": unit_status,
        "significant_figures": rubric.significant_figures,
    }
    if _within_tolerance(value, expected, rubric.tolerance):
        return _outcome(
            snapshot,
            score=ONE,
            classification="correct",
            confidence=confidence,
            grader_type="numeric",
            grader_version=GRADER_VERSION_NUMERIC,
            public_outcome="recalled",
            feedback_code="within_tolerance",
            feedback="Correct.",
            repair_action="none",
            evidence={**base_evidence, "reason_code": "within_tolerance"},
        )
    if rubric.partial_tolerance is not None and _within_tolerance(
        value, expected, rubric.partial_tolerance
    ):
        return _outcome(
            snapshot,
            score=PARTIAL_NUMERIC_SCORE,
            classification="partial",
            confidence=confidence,
            grader_type="numeric",
            grader_version=GRADER_VERSION_NUMERIC,
            public_outcome="partial",
            feedback_code="within_partial_tolerance",
            feedback="Partially correct. Check the precision or unit.",
            repair_action="review_concept",
            evidence={**base_evidence, "reason_code": "within_partial_tolerance"},
        )
    return _outcome(
        snapshot,
        score=ZERO,
        classification="incorrect",
        confidence=confidence,
        grader_type="numeric",
        grader_version=GRADER_VERSION_NUMERIC,
        public_outcome="weak",
        feedback_code="outside_tolerance",
        feedback="Not quite. Review this concept.",
        repair_action="review_concept",
        evidence={**base_evidence, "reason_code": "outside_tolerance"},
    )


def _grade_short_answer(
    snapshot: QuestionSnapshot,
    answer: SingleChoiceAnswer | MultipleChoiceAnswer | NumericAnswer | ShortAnswerText,
    evaluator: ClaimEvaluator | None,
) -> GradeOutcome:
    if not isinstance(snapshot.content, ShortAnswerContent) or not isinstance(
        snapshot.rubric.payload, ClaimRubricPayload
    ):
        raise QuestionValidationError(
            "rubric_invalid",
            "Stored grading rules do not match the question type.",
            "rubric",
        )
    if not isinstance(answer, ShortAnswerText):
        return _ungradable_outcome(snapshot, "answer_invalid", "The answer could not be graded.")
    if not normalize_text(answer.text):
        return _ungradable_outcome(snapshot, "empty_response", "The answer was empty.")

    rubric = snapshot.rubric.payload
    evaluation = evaluate_claims(rubric, answer.text, evaluator=evaluator)
    base_evidence = {
        "schema_version": "1",
        "evaluator_version": (
            evaluator.version if evaluator is not None else "deterministic-claim-v1"
        ),
        "matched_claim_ids": list(evaluation.matched_claim_ids),
        "missing_required_claim_ids": list(evaluation.missing_required_claim_ids),
        "contradiction_claim_ids": list(evaluation.contradiction_claim_ids),
        "evaluator_evidence_rejected": bool(evaluation.rejected_claim_ids),
        "coverage": _decimal_text(evaluation.coverage),
    }
    ceiling = snapshot.rubric.evidence_ceiling

    if evaluation.contradiction_claim_ids:
        return _outcome(
            snapshot,
            score=ZERO,
            classification="misconception",
            confidence=_cap(ceiling, MAX_SHORT_ANSWER_CONTRADICTION_CONFIDENCE),
            grader_type="rubric_model",
            grader_version=GRADER_VERSION_SHORT_ANSWER,
            public_outcome="weak",
            feedback_code="contradiction",
            feedback="This matches a common misconception. Review the concept.",
            repair_action="review_concept",
            evidence={**base_evidence, "reason_code": "contradiction"},
        )

    if evaluation.matched_required_weight >= evaluation.total_required_weight > 0:
        return _outcome(
            snapshot,
            score=ONE,
            classification="correct",
            confidence=_cap(ceiling, MAX_SHORT_ANSWER_CONFIDENCE),
            grader_type="rubric_model",
            grader_version=GRADER_VERSION_SHORT_ANSWER,
            public_outcome="recalled",
            feedback_code="correct",
            feedback="Correct.",
            repair_action="none",
            evidence={**base_evidence, "reason_code": "all_required_claims"},
        )

    if evaluation.coverage >= rubric.minimum_supported_coverage and evaluation.coverage > 0:
        return _outcome(
            snapshot,
            score=_quantize(evaluation.coverage),
            classification="partial",
            confidence=_cap(ceiling, MAX_SHORT_ANSWER_PARTIAL_CONFIDENCE),
            grader_type="rubric_model",
            grader_version=GRADER_VERSION_SHORT_ANSWER,
            public_outcome="partial",
            feedback_code="partial_claims",
            feedback="Partially correct. Review the missing idea.",
            repair_action="review_concept",
            evidence={**base_evidence, "reason_code": "partial_claims"},
        )

    return _outcome(
        snapshot,
        score=ZERO,
        classification="ungradable",
        confidence=_cap(ceiling, MAX_SHORT_ANSWER_UNCERTAIN_CONFIDENCE),
        grader_type="rubric_model",
        grader_version=GRADER_VERSION_SHORT_ANSWER,
        public_outcome="uncertain",
        feedback_code="uncertain",
        feedback="This answer is ambiguous, so it has limited influence. Confirm or appeal.",
        repair_action="confirm_or_appeal",
        evidence={**base_evidence, "reason_code": "unsupported_answer"},
    )


def _ungradable_outcome(snapshot: QuestionSnapshot, reason: str, message: str) -> GradeOutcome:
    grader_type: GraderType
    grader_version: str
    if snapshot.question_type in OPTION_QUESTION_TYPES:
        grader_type, grader_version = "exact", GRADER_VERSION_EXACT
    elif snapshot.question_type == "numeric":
        grader_type, grader_version = "numeric", GRADER_VERSION_NUMERIC
    else:
        grader_type, grader_version = "rubric_model", GRADER_VERSION_SHORT_ANSWER
    return _outcome(
        snapshot,
        score=ZERO,
        classification="ungradable",
        confidence=ZERO,
        grader_type=grader_type,
        grader_version=grader_version,
        public_outcome="uncertain",
        feedback_code=reason,
        feedback="This answer could not be graded safely. Confirm or appeal.",
        repair_action="confirm_or_appeal",
        evidence={"schema_version": "1", "reason_code": reason, "message": message},
    )


def _outcome(
    snapshot: QuestionSnapshot,
    *,
    score: Decimal,
    classification: Classification,
    confidence: Decimal,
    grader_type: GraderType,
    grader_version: str,
    public_outcome: PublicOutcome,
    feedback_code: str,
    feedback: str,
    repair_action: RepairAction,
    evidence: dict[str, Any],
) -> GradeOutcome:
    normalized_score = _quantize(score)
    normalized_confidence = _quantize(confidence)
    influence_limited = normalized_confidence < LOW_CONFIDENCE_THRESHOLD or classification in {
        "ungradable",
        "invalidated",
    }
    return GradeOutcome(
        score=normalized_score,
        classification=classification,
        confidence=normalized_confidence,
        grader_type=grader_type,
        grader_version=grader_version,
        public_outcome=public_outcome,
        feedback_code=feedback_code,
        feedback=feedback,
        explanation_available=(
            bool(snapshot.explanation.strip()) and classification != "ungradable"
        ),
        repair_action=repair_action,
        influence_limited=influence_limited,
        evidence={**evidence, "grader_version": grader_version},
    )


def _cap(ceiling: Decimal, maximum: Decimal) -> Decimal:
    return _quantize(min(ceiling, maximum))


def _quantize(value: Decimal) -> Decimal:
    clamped = max(ZERO, min(ONE, value))
    return clamped.quantize(SCORE_QUANTUM, rounding=ROUND_HALF_UP)


def _decimal_text(value: Decimal) -> str:
    return format(_quantize(value), "f")


def _round_significant(value: Decimal, digits: int) -> Decimal:
    if value == 0:
        return ZERO
    try:
        with localcontext() as context:
            context.prec = 40
            exponent = value.adjusted() - digits + 1
            return value.quantize(Decimal(1).scaleb(exponent), rounding=ROUND_HALF_UP)
    except (InvalidOperation, OverflowError):
        # An extreme exponent must not turn a malformed answer into a server error.
        return value


def _within_tolerance(value: Decimal, expected: Decimal, tolerance: NumericTolerance) -> bool:
    difference = abs(value - expected)
    if tolerance.mode == "absolute":
        return difference <= tolerance.value
    return difference <= abs(expected) * tolerance.value


def _unit_status(unit: str | None, rubric: NumericRubricPayload) -> str:
    if rubric.unit_rule == "ignored":
        return "ignored"
    if unit is None or not unit.strip():
        return "absent_optional" if rubric.unit_rule == "optional" else "missing"
    if rubric.expected_unit is None or _normalize_unit(unit) != _normalize_unit(
        rubric.expected_unit
    ):
        return "mismatch"
    return "matches"


def _normalize_unit(unit: str) -> str:
    return normalize_text(unit).replace(" ", "").replace("·", "*").replace("⋅", "*")
