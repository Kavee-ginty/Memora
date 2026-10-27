from __future__ import annotations

from decimal import Decimal
from uuid import UUID, uuid4

import pytest

from memora.modules.questions.grading import grade_answer
from memora.modules.questions.models import (
    ChoiceContent,
    ClaimRubricPayload,
    ConceptMappingSnapshot,
    ExactRubricPayload,
    NumericContent,
    NumericRubricPayload,
    QuestionOptionSnapshot,
    QuestionRubricSnapshot,
    QuestionSnapshot,
    ShortAnswerContent,
)
from memora.modules.questions.short_answer import ClaimMatch
from memora.modules.questions.validation import QuestionValidationError

CONCEPT_ID = UUID("30000000-0000-0000-0000-000000000001")


def snapshot(
    question_type: str,
    content: object,
    options: tuple[QuestionOptionSnapshot, ...],
    rubric_payload: object,
    *,
    rubric_type: str,
    evidence_ceiling: Decimal = Decimal("1"),
    explanation: str = "Synthetic explanation.",
) -> QuestionSnapshot:
    return QuestionSnapshot(
        question_version_id=uuid4(),
        question_code="phy.synthetic.001",
        source_class="expert_verified",
        validation_status="approved",
        question_type=question_type,
        prompt="Synthetic prompt.",
        explanation=explanation,
        trust_label="Expert verified",
        content=content,  # type: ignore[arg-type]
        options=options,
        rubric=QuestionRubricSnapshot(
            id=uuid4(),
            rubric_type=rubric_type,
            rubric_version=1,
            payload=rubric_payload,  # type: ignore[arg-type]
            max_score=Decimal("1"),
            evidence_ceiling=evidence_ceiling,
            status="approved",
        ),
        concept_mappings=(
            ConceptMappingSnapshot(
                concept_version_id=CONCEPT_ID,
                learning_objective_id=None,
                mapping_role="primary",
                weight=Decimal("1"),
            ),
        ),
    )


def mcq_snapshot() -> QuestionSnapshot:
    return snapshot(
        "mcq",
        ChoiceContent(selection_mode="single"),
        (
            QuestionOptionSnapshot(
                option_key="a",
                display_text="Speed",
                accessible_image_ref=None,
                is_correct=False,
                explanation="Speed is a scalar.",
                display_order=0,
            ),
            QuestionOptionSnapshot(
                option_key="b",
                display_text="Velocity",
                accessible_image_ref=None,
                is_correct=True,
                explanation="Velocity is a vector.",
                display_order=1,
            ),
        ),
        ExactRubricPayload(),
        rubric_type="exact",
    )


def numeric_snapshot(
    *,
    expected: str = "9.81",
    expected_unit: str | None = "m/s^2",
    unit_rule: str = "required",
    tolerance: str = "0.05",
    tolerance_mode: str = "absolute",
    partial_tolerance: str | None = None,
    significant_figures: int | None = None,
    evidence_ceiling: Decimal = Decimal("1"),
) -> QuestionSnapshot:
    payload = {
        "expected_value": Decimal(expected),
        "expected_unit": expected_unit,
        "unit_rule": unit_rule,
        "tolerance": {"mode": tolerance_mode, "value": Decimal(tolerance)},
        "partial_tolerance": (
            {"mode": tolerance_mode, "value": Decimal(partial_tolerance)}
            if partial_tolerance is not None
            else None
        ),
        "significant_figures": significant_figures,
    }
    return snapshot(
        "numeric",
        NumericContent(unit_affordance=True, unit_options=["m/s^2"]),
        (),
        NumericRubricPayload.model_validate(payload),
        rubric_type="numeric",
        evidence_ceiling=evidence_ceiling,
    )


def short_answer_snapshot(
    *,
    minimum_supported_coverage: str = "0.5",
    evidence_ceiling: Decimal = Decimal("1"),
) -> QuestionSnapshot:
    rubric = ClaimRubricPayload.model_validate(
        {
            "claims": [
                {
                    "claim_id": "direction",
                    "required": True,
                    "weight": "1",
                    "variants": ["velocity has direction", "direction of motion"],
                    "contradictions": ["velocity has no direction"],
                },
                {
                    "claim_id": "magnitude",
                    "required": True,
                    "weight": "1",
                    "variants": ["velocity has magnitude", "speed with direction"],
                },
            ],
            "minimum_supported_coverage": Decimal(minimum_supported_coverage),
        }
    )
    return snapshot(
        "short_answer",
        ShortAnswerContent(max_characters=400),
        (),
        rubric,
        rubric_type="claim",
        evidence_ceiling=evidence_ceiling,
    )


def test_mcq_correct_answer_returns_full_confident_credit() -> None:
    outcome = grade_answer(mcq_snapshot(), {"type": "single_choice", "option_keys": ["b"]})

    assert outcome.score == Decimal("1.00000")
    assert outcome.classification == "correct"
    assert outcome.confidence == Decimal("1.00000")
    assert outcome.public_outcome == "recalled"
    assert outcome.influence_limited is False
    assert "expected_option_keys" not in outcome.evidence
    assert "option_keys" not in outcome.evidence


def test_mcq_wrong_answer_is_weak_but_not_misconception() -> None:
    outcome = grade_answer(mcq_snapshot(), {"type": "single_choice", "option_keys": ["a"]})

    assert outcome.score == Decimal("0.00000")
    assert outcome.classification == "incorrect"
    assert outcome.public_outcome == "weak"
    assert outcome.explanation_available is True
    assert outcome.evidence["reason_code"] == "option_set_mismatch"


def test_invalid_choice_key_is_ungradable_and_influence_limited() -> None:
    outcome = grade_answer(mcq_snapshot(), {"type": "single_choice", "option_keys": ["z"]})

    assert outcome.classification == "ungradable"
    assert outcome.public_outcome == "uncertain"
    assert outcome.confidence == Decimal("0.00000")
    assert outcome.influence_limited is True
    assert outcome.explanation_available is False
    assert outcome.feedback_code == "answer_invalid"


def test_numeric_answer_within_absolute_tolerance() -> None:
    outcome = grade_answer(
        numeric_snapshot(), {"type": "numeric", "value": "9.84", "unit": "m/s^2"}
    )

    assert outcome.classification == "correct"
    assert outcome.score == Decimal("1.00000")
    assert outcome.evidence["unit_status"] == "matches"


def test_numeric_answer_outside_tolerance_is_incorrect() -> None:
    outcome = grade_answer(
        numeric_snapshot(), {"type": "numeric", "value": "10.2", "unit": "m/s^2"}
    )

    assert outcome.classification == "incorrect"
    assert outcome.score == Decimal("0.00000")
    assert outcome.evidence["reason_code"] == "outside_tolerance"


def test_numeric_partial_tolerance_returns_bounded_partial_credit() -> None:
    outcome = grade_answer(
        numeric_snapshot(tolerance="0.1", partial_tolerance="1.0"),
        {"type": "numeric", "value": "10.5", "unit": "m/s^2"},
    )

    assert outcome.classification == "partial"
    assert outcome.score == Decimal("0.50000")
    assert outcome.public_outcome == "partial"
    assert outcome.evidence["reason_code"] == "within_partial_tolerance"


def test_numeric_required_unit_missing_is_incorrect_without_guessing() -> None:
    outcome = grade_answer(numeric_snapshot(), {"type": "numeric", "value": "9.81"})

    assert outcome.classification == "incorrect"
    assert outcome.feedback_code == "unit_missing"
    assert outcome.evidence["reason_code"] == "unit_missing"


def test_numeric_optional_unit_can_be_absent() -> None:
    outcome = grade_answer(
        numeric_snapshot(unit_rule="optional"),
        {"type": "numeric", "value": "9.81"},
    )

    assert outcome.classification == "correct"
    assert outcome.evidence["unit_status"] == "absent_optional"


def test_numeric_unit_mismatch_is_incorrect() -> None:
    outcome = grade_answer(
        numeric_snapshot(), {"type": "numeric", "value": "9.81", "unit": "cm/s^2"}
    )

    assert outcome.classification == "incorrect"
    assert outcome.feedback_code == "unit_mismatch"


def test_numeric_significant_figures_are_applied_before_tolerance() -> None:
    outcome = grade_answer(
        numeric_snapshot(
            expected="0.00981",
            expected_unit="m",
            tolerance="0.00001",
            significant_figures=2,
        ),
        {"type": "numeric", "value": "0.0098", "unit": "m"},
    )

    assert outcome.classification == "correct"
    assert outcome.evidence["significant_figures"] == 2


def test_numeric_relative_tolerance_uses_expected_magnitude() -> None:
    accepted = grade_answer(
        numeric_snapshot(
            expected="100",
            expected_unit="m",
            tolerance="0.01",
            tolerance_mode="relative",
        ),
        {"type": "numeric", "value": "100.5", "unit": "m"},
    )
    rejected = grade_answer(
        numeric_snapshot(
            expected="100",
            expected_unit="m",
            tolerance="0.01",
            tolerance_mode="relative",
        ),
        {"type": "numeric", "value": "102", "unit": "m"},
    )

    assert accepted.classification == "correct"
    assert rejected.classification == "incorrect"


def test_numeric_confidence_is_capped_for_lower_trust_content() -> None:
    outcome = grade_answer(
        numeric_snapshot(evidence_ceiling=Decimal("0.6")),
        {"type": "numeric", "value": "9.81", "unit": "m/s^2"},
    )

    assert outcome.confidence == Decimal("0.60000")
    assert outcome.influence_limited is True


def test_short_answer_all_required_claims_is_bounded_confident() -> None:
    outcome = grade_answer(
        short_answer_snapshot(),
        {
            "type": "short_answer",
            "text": "Velocity has magnitude and the direction of motion.",
        },
    )

    assert outcome.classification == "correct"
    assert outcome.score == Decimal("1.00000")
    assert outcome.confidence == Decimal("0.85000")
    assert outcome.influence_limited is False
    assert set(outcome.evidence["matched_claim_ids"]) == {"direction", "magnitude"}


def test_short_answer_partial_claim_coverage_is_limited() -> None:
    outcome = grade_answer(
        short_answer_snapshot(),
        {"type": "short_answer", "text": "Velocity has direction."},
    )

    assert outcome.classification == "partial"
    assert outcome.score == Decimal("0.50000")
    assert outcome.public_outcome == "partial"
    assert outcome.confidence == Decimal("0.65000")
    assert outcome.influence_limited is True
    assert outcome.evidence["missing_required_claim_ids"] == ["magnitude"]


def test_short_answer_contradiction_is_explicit_misconception() -> None:
    outcome = grade_answer(
        short_answer_snapshot(),
        {"type": "short_answer", "text": "Velocity has no direction at all."},
    )

    assert outcome.classification == "misconception"
    assert outcome.score == Decimal("0.00000")
    assert outcome.confidence == Decimal("0.80000")
    assert outcome.evidence["contradiction_claim_ids"] == ["direction"]


def test_short_answer_unrecognized_response_stays_uncertain() -> None:
    outcome = grade_answer(
        short_answer_snapshot(),
        {"type": "short_answer", "text": "It is a quantity in physics."},
    )

    assert outcome.classification == "ungradable"
    assert outcome.public_outcome == "uncertain"
    assert outcome.confidence == Decimal("0.40000")
    assert outcome.influence_limited is True
    assert outcome.explanation_available is False
    assert outcome.repair_action == "confirm_or_appeal"


def test_short_answer_uses_pluggable_evaluator_boundary() -> None:
    class AlwaysMatched:
        version = "synthetic-evaluator-v1"

        def evaluate(self, claim: object, normalized_response: str) -> ClaimMatch:
            return ClaimMatch(
                claim_id=claim.claim_id,  # type: ignore[attr-defined]
                required=claim.required,  # type: ignore[attr-defined]
                weight=claim.weight,  # type: ignore[attr-defined]
                matched=True,
                matched_variant="synthetic",
                contradiction_phrase=None,
            )

    outcome = grade_answer(
        short_answer_snapshot(),
        {"type": "short_answer", "text": "Anything."},
        evaluator=AlwaysMatched(),
    )

    assert outcome.classification == "correct"
    assert outcome.evidence["evaluator_version"] == "synthetic-evaluator-v1"


def test_stored_rubric_type_mismatch_is_a_server_data_error() -> None:
    invalid = snapshot(
        "mcq",
        ChoiceContent(selection_mode="single"),
        (
            QuestionOptionSnapshot(
                option_key="a",
                display_text="A",
                accessible_image_ref=None,
                is_correct=True,
                explanation="",
                display_order=0,
            ),
            QuestionOptionSnapshot(
                option_key="b",
                display_text="B",
                accessible_image_ref=None,
                is_correct=False,
                explanation="",
                display_order=1,
            ),
        ),
        ClaimRubricPayload.model_validate({"claims": [{"claim_id": "x", "variants": ["a"]}]}),
        rubric_type="claim",
    )

    with pytest.raises(QuestionValidationError) as captured:
        grade_answer(invalid, {"type": "single_choice", "option_keys": ["a"]})

    assert captured.value.code == "rubric_invalid"
