from __future__ import annotations

from decimal import Decimal
from uuid import UUID

import pytest

from memora.modules.questions.models import (
    ChoiceContent,
    ConceptMappingSnapshot,
    QuestionImportBundle,
    QuestionOptionSnapshot,
    QuestionRubricSnapshot,
    QuestionSnapshot,
    ValidatedQuestionImport,
)
from memora.modules.questions.models import (
    ExactRubricPayload as ExactRubric,
)
from memora.modules.questions.validation import (
    QuestionValidationError,
    parse_answer_payload,
    parse_question_content,
    source_precedence_rank,
    validate_answer_against_question,
    validate_question_import,
)

SUBJECT_ID = UUID("10000000-0000-0000-0000-000000000001")
CURRICULUM_ID = UUID("20000000-0000-0000-0000-000000000001")
CONCEPT_ID = UUID("30000000-0000-0000-0000-000000000001")
AUTHOR_ID = UUID("40000000-0000-0000-0000-000000000001")
REVIEWER_ID = UUID("40000000-0000-0000-0000-000000000002")


def bundle(**overrides: object) -> QuestionImportBundle:
    payload: dict[str, object] = {
        "question_code": "phy.mechanics.mcq.001",
        "subject_id": SUBJECT_ID,
        "curriculum_version_id": CURRICULUM_ID,
        "source_class": "expert_verified",
        "question_type": "mcq",
        "prompt": "Which quantity is a vector?",
        "explanation": "Velocity has magnitude and direction.",
        "validation_status": "approved",
        "author_principal": AUTHOR_ID,
        "reviewer_principal": REVIEWER_ID,
        "content": {"selection_mode": "single"},
        "options": [
            {
                "option_key": "a",
                "display_text": "Speed",
                "is_correct": False,
                "explanation": "Speed is a scalar.",
                "display_order": 0,
            },
            {
                "option_key": "b",
                "display_text": "Velocity",
                "is_correct": True,
                "explanation": "Velocity is a vector.",
                "display_order": 1,
            },
        ],
        "rubric": {
            "rubric_type": "exact",
            "max_score": Decimal("1"),
            "evidence_ceiling": Decimal("1"),
            "status": "approved",
            "payload": {"schema_version": "1"},
        },
        "concept_mappings": [
            {
                "concept_version_id": CONCEPT_ID,
                "mapping_role": "primary",
                "weight": Decimal("1"),
                "provenance_type": "review",
                "provenance_ref": "synthetic-review",
            }
        ],
    }
    payload.update(overrides)
    return QuestionImportBundle.model_validate(payload)


def test_valid_import_is_typed_and_has_stable_hash() -> None:
    first = validate_question_import(bundle())
    second = validate_question_import(bundle())

    assert isinstance(first, ValidatedQuestionImport)
    assert first.trust_label == "Expert verified"
    assert first.content.kind == "choice"
    assert first.rubric_payload.kind == "exact"
    assert first.content_hash == second.content_hash
    assert len(first.content_hash) == 64


def test_changed_content_creates_a_different_hash() -> None:
    first = validate_question_import(bundle())
    second = validate_question_import(bundle(prompt="Which quantity has direction?"))

    assert first.content_hash != second.content_hash


def content_hash(value: QuestionImportBundle) -> str:
    return validate_question_import(value).content_hash


def rubric(**overrides: object) -> dict[str, object]:
    payload: dict[str, object] = {
        "rubric_type": "exact",
        "max_score": Decimal("1"),
        "evidence_ceiling": Decimal("1"),
        "status": "approved",
        "payload": {"schema_version": "1"},
    }
    payload.update(overrides)
    return payload


def test_hash_covers_subject_and_curriculum() -> None:
    baseline = content_hash(bundle())

    assert baseline != content_hash(bundle(subject_id=UUID("10000000-0000-0000-0000-000000000002")))
    assert baseline != content_hash(
        bundle(curriculum_version_id=UUID("20000000-0000-0000-0000-000000000002"))
    )


def test_hash_covers_every_rubric_grading_field() -> None:
    baseline = content_hash(bundle())

    assert baseline != content_hash(bundle(rubric=rubric(max_score=Decimal("2"))))
    assert baseline != content_hash(bundle(rubric=rubric(evidence_ceiling=Decimal("0.5"))))
    assert baseline != content_hash(
        bundle(
            validation_status="draft",
            rubric=rubric(status="draft"),
        )
    )


def test_hash_covers_rubric_payload() -> None:
    first = content_hash(
        bundle(
            question_type="numeric",
            content={"unit_affordance": False},
            options=[],
            rubric={
                "rubric_type": "numeric",
                "max_score": Decimal("1"),
                "evidence_ceiling": Decimal("1"),
                "status": "approved",
                "payload": {
                    "expected_value": "9.81",
                    "unit_rule": "ignored",
                    "tolerance": {"mode": "absolute", "value": "0.05"},
                },
            },
        )
    )
    second = content_hash(
        bundle(
            question_type="numeric",
            content={"unit_affordance": False},
            options=[],
            rubric={
                "rubric_type": "numeric",
                "max_score": Decimal("1"),
                "evidence_ceiling": Decimal("1"),
                "status": "approved",
                "payload": {
                    "expected_value": "9.80",
                    "unit_rule": "ignored",
                    "tolerance": {"mode": "absolute", "value": "0.05"},
                },
            },
        )
    )

    assert first != second


def test_hash_covers_mapping_provenance() -> None:
    baseline = content_hash(bundle())
    mapping = {
        "concept_version_id": CONCEPT_ID,
        "mapping_role": "primary",
        "weight": Decimal("1"),
        "provenance_type": "review",
        "provenance_ref": "synthetic-review",
    }

    assert baseline != content_hash(
        bundle(
            concept_mappings=[
                {**mapping, "provenance_ref": "different-review"},
            ]
        )
    )
    assert baseline != content_hash(
        bundle(
            concept_mappings=[
                {**mapping, "provenance_type": "synthetic"},
            ]
        )
    )


def test_hash_covers_all_generated_provenance() -> None:
    baseline = content_hash(generated_bundle())

    assert baseline != content_hash(generated_bundle(model_key="other-model"))
    assert baseline != content_hash(generated_bundle(prompt_version="other-prompt"))
    assert baseline != content_hash(
        generated_bundle(grounding_evidence_ids=[UUID("70000000-0000-0000-0000-000000000001")])
    )
    assert baseline != content_hash(generated_bundle(validator_version="other-validator"))
    assert baseline != content_hash(generated_bundle(validation_score=Decimal("0.8")))
    assert baseline != content_hash(generated_bundle(generation_trace_ref="other-trace"))


def test_hash_normalizes_values_to_database_scale() -> None:
    first = content_hash(
        bundle(
            rubric=rubric(
                max_score=Decimal("1.2344"),
                evidence_ceiling=Decimal("0.912344"),
            ),
            concept_mappings=[
                {
                    "concept_version_id": CONCEPT_ID,
                    "mapping_role": "primary",
                    "weight": Decimal("0.500004"),
                    "provenance_type": "review",
                    "provenance_ref": "synthetic-review",
                }
            ],
        )
    )
    second = content_hash(
        bundle(
            rubric=rubric(
                max_score=Decimal("1.2341"),
                evidence_ceiling=Decimal("0.912341"),
            ),
            concept_mappings=[
                {
                    "concept_version_id": CONCEPT_ID,
                    "mapping_role": "primary",
                    "weight": Decimal("0.500001"),
                    "provenance_type": "review",
                    "provenance_ref": "synthetic-review",
                }
            ],
        )
    )

    assert first == second

    changed = content_hash(
        bundle(
            rubric=rubric(
                max_score=Decimal("1.235"),
                evidence_ceiling=Decimal("0.91235"),
            )
        )
    )
    assert first != changed


def test_import_rejects_teacher_content_until_enabled() -> None:
    with pytest.raises(QuestionValidationError) as captured:
        validate_question_import(
            bundle(
                source_class="teacher_authored",
                trust_label="Teacher authored",
            )
        )

    assert captured.value.code == "teacher_content_disabled"


def test_import_rejects_ai_content_without_grounding_evidence() -> None:
    with pytest.raises(QuestionValidationError) as captured:
        validate_question_import(
            bundle(
                source_class="ai_generated",
                trust_label="AI generated",
            )
        )

    assert captured.value.code == "ai_metadata_missing"


def generated_bundle(**overrides: object) -> QuestionImportBundle:
    metadata: dict[str, object] = {
        "source_class": "ai_generated",
        "trust_label": "AI generated",
        "model_key": "synthetic-model",
        "prompt_version": "synthetic-prompt-v1",
        "grounding_evidence_ids": [CONCEPT_ID],
        "validator_version": "synthetic-validator-v1",
        "validation_score": Decimal("0.9"),
        "generation_trace_ref": "synthetic-trace",
        "rubric": {
            "rubric_type": "exact",
            "max_score": Decimal("1"),
            "evidence_ceiling": Decimal("0.9"),
            "status": "approved",
            "payload": {"schema_version": "1"},
        },
    }
    metadata.update(overrides)
    return bundle(**metadata)


def test_import_accepts_complete_generated_metadata() -> None:
    imported = validate_question_import(generated_bundle())

    assert imported.trust_label == "AI generated"


@pytest.mark.parametrize(
    "field",
    ["model_key", "prompt_version", "validator_version", "generation_trace_ref"],
)
def test_import_rejects_empty_generated_metadata(field: str) -> None:
    with pytest.raises(QuestionValidationError) as captured:
        validate_question_import(generated_bundle(**{field: ""}))

    assert captured.value.code == "ai_metadata_missing"


def test_import_rejects_generated_content_above_evidence_ceiling() -> None:
    payload = generated_bundle()
    rubric = payload.rubric.model_copy(update={"evidence_ceiling": Decimal("0.95")})

    with pytest.raises(QuestionValidationError) as captured:
        validate_question_import(payload.model_copy(update={"rubric": rubric}))

    assert captured.value.code == "rubric_invalid"


def test_import_rejects_publication_without_primary_mapping() -> None:
    with pytest.raises(QuestionValidationError) as captured:
        validate_question_import(bundle(concept_mappings=[]))

    assert captured.value.code == "concept_mapping_missing"


def test_import_rejects_supporting_only_mapping_for_publication() -> None:
    supporting = {
        "concept_version_id": CONCEPT_ID,
        "mapping_role": "supporting",
        "weight": Decimal("1"),
        "provenance_type": "review",
        "provenance_ref": "synthetic-review",
    }

    with pytest.raises(QuestionValidationError) as captured:
        validate_question_import(bundle(concept_mappings=[supporting]))

    assert captured.value.code == "concept_mapping_missing"


def test_import_rejects_approved_question_without_required_principals() -> None:
    without_reviewer = {
        "reviewer_principal": None,
    }
    without_author = {
        "author_principal": None,
    }

    with pytest.raises(QuestionValidationError) as reviewer_error:
        validate_question_import(bundle(**without_reviewer))
    with pytest.raises(QuestionValidationError) as author_error:
        validate_question_import(bundle(**without_author))

    assert reviewer_error.value.code == "reviewer_required"
    assert author_error.value.code == "author_required"


def test_import_accepts_ai_generated_question_without_author_principal() -> None:
    imported = validate_question_import(generated_bundle(author_principal=None))

    assert imported.trust_label == "AI generated"


def test_import_rejects_approved_question_without_explanation() -> None:
    with pytest.raises(QuestionValidationError) as captured:
        validate_question_import(bundle(explanation="   "))

    assert captured.value.code == "publish_requirements_missing"
    assert captured.value.field == "explanation"


def test_import_rejects_approved_question_with_draft_rubric() -> None:
    with pytest.raises(QuestionValidationError) as captured:
        validate_question_import(bundle(rubric=rubric(status="draft")))

    assert captured.value.code == "publish_requirements_missing"
    assert captured.value.field == "rubric.status"


def test_import_rejects_approved_question_with_zero_evidence_ceiling() -> None:
    with pytest.raises(QuestionValidationError) as captured:
        validate_question_import(bundle(rubric=rubric(evidence_ceiling=Decimal("0"))))

    assert captured.value.code == "publish_requirements_missing"
    assert captured.value.field == "rubric.evidence_ceiling"


def test_source_metadata_cannot_be_smuggled_into_question_content() -> None:
    with pytest.raises(QuestionValidationError) as captured:
        parse_question_content(
            "mcq",
            {
                "selection_mode": "single",
                "source_ref": "SL-DOE-AL-PHYS-2025-P1",
                "licence": "claimed-in-content",
            },
        )

    assert captured.value.code == "content_invalid"
    assert captured.value.field == "content"


def test_import_rejects_single_choice_with_two_correct_options() -> None:
    options = [
        {
            "option_key": "a",
            "display_text": "Speed",
            "is_correct": True,
            "explanation": "Incorrect synthetic key.",
            "display_order": 0,
        },
        {
            "option_key": "b",
            "display_text": "Velocity",
            "is_correct": True,
            "explanation": "Velocity is a vector.",
            "display_order": 1,
        },
    ]

    with pytest.raises(QuestionValidationError) as captured:
        validate_question_import(bundle(options=options))

    assert captured.value.code == "options_invalid"


def test_import_rejects_rubric_that_does_not_match_question_type() -> None:
    with pytest.raises(QuestionValidationError) as captured:
        validate_question_import(
            bundle(
                rubric={
                    "rubric_type": "numeric",
                    "max_score": Decimal("1"),
                    "evidence_ceiling": Decimal("1"),
                    "status": "approved",
                    "payload": {
                        "expected_value": "1",
                        "unit_rule": "ignored",
                        "tolerance": {"mode": "absolute", "value": "0.1"},
                    },
                }
            )
        )

    assert captured.value.code == "rubric_type_mismatch"


def test_claim_rubric_rejects_duplicate_normalized_phrases_across_claims() -> None:
    rubric = {
        "rubric_type": "claim",
        "max_score": Decimal("1"),
        "evidence_ceiling": Decimal("0.8"),
        "status": "approved",
        "payload": {
            "claims": [
                {
                    "claim_id": "first",
                    "variants": ["Velocity changes"],
                },
                {
                    "claim_id": "second",
                    "variants": ["velocity   changes"],
                },
            ]
        },
    }

    with pytest.raises(QuestionValidationError) as captured:
        validate_question_import(
            bundle(
                question_type="short_answer",
                content={"max_characters": 400},
                options=[],
                rubric=rubric,
            )
        )

    assert captured.value.code == "rubric_invalid"


def test_numeric_rubric_requires_consistent_unit_rule() -> None:
    with pytest.raises(QuestionValidationError) as captured:
        validate_question_import(
            bundle(
                question_type="numeric",
                content={"unit_affordance": True, "unit_options": ["m/s"]},
                options=[],
                rubric={
                    "rubric_type": "numeric",
                    "max_score": Decimal("1"),
                    "evidence_ceiling": Decimal("1"),
                    "payload": {
                        "expected_value": "9.81",
                        "unit_rule": "required",
                        "tolerance": {"mode": "absolute", "value": "0.05"},
                    },
                },
            )
        )

    assert captured.value.code == "rubric_invalid"


def test_answer_validation_rejects_unknown_option_and_wrong_type() -> None:
    content = ChoiceContent(selection_mode="single")
    answer = parse_answer_payload({"type": "single_choice", "option_keys": ["a"]})

    with pytest.raises(QuestionValidationError) as captured:
        validate_answer_against_question("mcq", content, answer, {"b"})
    assert captured.value.code == "answer_option_unknown"

    numeric_answer = parse_answer_payload({"type": "numeric", "value": "9.81"})
    with pytest.raises(QuestionValidationError) as captured:
        validate_answer_against_question("mcq", content, numeric_answer, {"a", "b"})
    assert captured.value.code == "answer_type_mismatch"


def test_answer_validation_bounds_short_answer_to_content_limit() -> None:
    from memora.modules.questions.models import ShortAnswerContent

    content = ShortAnswerContent(max_characters=5)
    answer = parse_answer_payload({"type": "short_answer", "text": "too long"})

    with pytest.raises(QuestionValidationError) as captured:
        validate_answer_against_question("short_answer", content, answer, set())
    assert captured.value.code == "answer_too_long"


def test_public_question_never_contains_correctness_or_explanation() -> None:
    snapshot = QuestionSnapshot(
        question_version_id=UUID("50000000-0000-0000-0000-000000000001"),
        question_code="phy.mechanics.mcq.001",
        source_class="expert_verified",
        validation_status="approved",
        question_type="mcq",
        prompt="Which quantity is a vector?",
        explanation="Velocity has magnitude and direction.",
        trust_label="Expert verified",
        content=ChoiceContent(selection_mode="single"),
        options=(
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
        rubric=QuestionRubricSnapshot(
            id=UUID("60000000-0000-0000-0000-000000000001"),
            rubric_type="exact",
            rubric_version=1,
            payload=ExactRubric(),
            max_score=Decimal("1"),
            evidence_ceiling=Decimal("1"),
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

    public = snapshot.public_question()
    serialized = public.model_dump_json()

    assert "is_correct" not in serialized
    assert "Velocity has magnitude" not in serialized
    assert "correct" not in serialized
    assert [option.option_key for option in public.options] == ["a", "b"]
    assert public.question_type == "single_choice"


def test_source_precedence_prefers_expert_then_teacher_then_generated() -> None:
    assert source_precedence_rank("expert_verified") < source_precedence_rank("teacher_authored")
    assert source_precedence_rank("teacher_authored") < source_precedence_rank("ai_generated")
    assert source_precedence_rank("unknown") > source_precedence_rank("ai_generated")
