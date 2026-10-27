"""Pure import, content and answer validation for the question domain.

Validation messages never echo prompt text, answers or rubric internals. The
database remains the final authority for publication invariants; these checks
fail before an immutable row is written.
"""

from __future__ import annotations

import hashlib
import json
from collections.abc import Collection, Iterable, Mapping
from decimal import ROUND_HALF_UP, Decimal
from typing import Any

from pydantic import TypeAdapter, ValidationError

from memora.modules.questions.constants import (
    AI_EVIDENCE_CEILING,
    CONCEPT_WEIGHT_QUANTUM,
    EVIDENCE_CEILING_QUANTUM,
    MAX_CONCEPT_MAPPINGS,
    MAX_OPTIONS,
    MIN_OPTIONS,
    OPTION_QUESTION_TYPES,
    RUBRIC_MAX_SCORE_QUANTUM,
    SOURCE_PRECEDENCE,
    TEACHER_CONTENT_ENABLED,
    TRUST_LABELS,
    VALIDATION_SCORE_QUANTUM,
)
from memora.modules.questions.models import (
    AnswerPayload,
    ChoiceContent,
    ClaimRubricPayload,
    NumericAnswer,
    NumericContent,
    NumericRubricPayload,
    QuestionContent,
    QuestionImportBundle,
    QuestionOptionImport,
    RubricPayload,
    ShortAnswerContent,
    ShortAnswerText,
    ValidatedQuestionImport,
)
from memora.modules.questions.normalization import normalize_text

_CONTENT_ADAPTER = TypeAdapter(QuestionContent)
_RUBRIC_ADAPTER = TypeAdapter(RubricPayload)
_ANSWER_ADAPTER = TypeAdapter(AnswerPayload)

# These quanta mirror the numeric column scales in the MVP schema. Import and
# stored-content hashing must agree even when PostgreSQL rounds an input value.
_MAX_SCORE_QUANTUM = RUBRIC_MAX_SCORE_QUANTUM
_EVIDENCE_CEILING_QUANTUM = EVIDENCE_CEILING_QUANTUM
_MAPPING_WEIGHT_QUANTUM = CONCEPT_WEIGHT_QUANTUM
_VALIDATION_SCORE_QUANTUM = VALIDATION_SCORE_QUANTUM

_EXPECTED_CONTENT_KIND = {
    "mcq": "choice",
    "diagram_interpretation": "choice",
    "numeric": "numeric",
    "short_answer": "short_answer",
}
_EXPECTED_RUBRIC_KIND = {
    "mcq": "exact",
    "diagram_interpretation": "exact",
    "numeric": "numeric",
    "short_answer": "claim",
}


class QuestionValidationError(ValueError):
    """Safe validation failure for imports, stored content and answers."""

    def __init__(self, code: str, message: str, field: str | None = None) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.field = field


def source_precedence_rank(source_class: str) -> int:
    """Lower ranks are selected before fallback content."""

    return SOURCE_PRECEDENCE.get(source_class, len(SOURCE_PRECEDENCE))


def trust_label_for(source_class: str) -> str:
    try:
        return TRUST_LABELS[source_class]
    except KeyError as exc:
        raise QuestionValidationError(
            "source_class_invalid",
            "The question source class is not supported.",
            "source_class",
        ) from exc


def parse_question_content(question_type: str, payload: Mapping[str, Any]) -> QuestionContent:
    expected = _EXPECTED_CONTENT_KIND.get(question_type)
    if expected is None:
        raise QuestionValidationError(
            "question_type_invalid",
            "The question type is not supported.",
            "question_type",
        )
    raw = dict(payload)
    if raw.get("kind", expected) != expected:
        raise QuestionValidationError(
            "content_type_mismatch",
            "Question content does not match its declared type.",
            "content",
        )
    raw["kind"] = expected
    try:
        content = _CONTENT_ADAPTER.validate_python(raw)
    except ValidationError as exc:
        raise QuestionValidationError(
            "content_invalid",
            "Question content does not match its declared type.",
            "content",
        ) from exc
    if content.kind != expected:
        raise QuestionValidationError(
            "content_type_mismatch",
            "Question content does not match its declared type.",
            "content",
        )
    return content


def parse_rubric_payload(
    question_type: str, rubric_type: str, payload: Mapping[str, Any]
) -> RubricPayload:
    expected = _EXPECTED_RUBRIC_KIND.get(question_type)
    if expected is None or rubric_type != expected:
        raise QuestionValidationError(
            "rubric_type_mismatch",
            "The grading rubric does not match the question type.",
            "rubric.rubric_type",
        )
    raw = dict(payload)
    if raw.get("kind", expected) != expected:
        raise QuestionValidationError(
            "rubric_type_mismatch",
            "The grading rubric does not match the question type.",
            "rubric.payload",
        )
    raw["kind"] = expected
    try:
        rubric = _RUBRIC_ADAPTER.validate_python(raw)
    except ValidationError as exc:
        raise QuestionValidationError(
            "rubric_invalid",
            "The grading rubric is invalid.",
            "rubric.payload",
        ) from exc
    if rubric.kind != expected:
        raise QuestionValidationError(
            "rubric_type_mismatch",
            "The grading rubric does not match the question type.",
            "rubric.payload",
        )
    return rubric


def parse_answer_payload(payload: Mapping[str, Any]) -> AnswerPayload:
    try:
        return _ANSWER_ADAPTER.validate_python(dict(payload))
    except ValidationError as exc:
        raise QuestionValidationError(
            "answer_invalid",
            "The answer does not match the question format.",
            "answer",
        ) from exc


def validate_answer_against_question(
    question_type: str,
    content: QuestionContent,
    answer: AnswerPayload,
    option_keys: Collection[str],
) -> None:
    """Cross-check a parsed answer against immutable question content."""

    if question_type in OPTION_QUESTION_TYPES:
        if not isinstance(content, ChoiceContent):
            raise QuestionValidationError(
                "answer_type_mismatch",
                "The answer does not match the question format.",
                "answer.type",
            )
        expected_type = "single_choice" if content.selection_mode == "single" else "multiple_choice"
        if answer.type != expected_type:
            raise QuestionValidationError(
                "answer_type_mismatch",
                "The answer does not match the question format.",
                "answer.type",
            )
        unknown = set(answer.option_keys) - set(option_keys)
        if unknown:
            raise QuestionValidationError(
                "answer_option_unknown",
                "The answer contains an option that is not part of this question.",
                "answer.option_keys",
            )
        return

    if question_type == "numeric":
        if not isinstance(content, NumericContent) or not isinstance(answer, NumericAnswer):
            raise QuestionValidationError(
                "answer_type_mismatch",
                "The answer does not match the question format.",
                "answer.type",
            )
        return

    if question_type == "short_answer":
        if not isinstance(content, ShortAnswerContent) or not isinstance(answer, ShortAnswerText):
            raise QuestionValidationError(
                "answer_type_mismatch",
                "The answer does not match the question format.",
                "answer.type",
            )
        if len(answer.text) > content.max_characters:
            raise QuestionValidationError(
                "answer_too_long",
                "The answer is longer than this question accepts.",
                "answer.text",
            )
        return

    raise QuestionValidationError(
        "question_type_invalid",
        "The question type is not supported.",
        "question_type",
    )


def validate_question_import(bundle: QuestionImportBundle) -> ValidatedQuestionImport:
    if bundle.source_class == "teacher_authored" and not TEACHER_CONTENT_ENABLED:
        raise QuestionValidationError(
            "teacher_content_disabled",
            "Teacher-authored content is not enabled for this environment.",
            "source_class",
        )

    trust_label = trust_label_for(bundle.source_class)
    if bundle.trust_label is not None and bundle.trust_label != trust_label:
        raise QuestionValidationError(
            "trust_label_mismatch",
            "The trust label does not match the question source class.",
            "trust_label",
        )

    content = parse_question_content(bundle.question_type, bundle.content)
    rubric = parse_rubric_payload(
        bundle.question_type,
        bundle.rubric.rubric_type,
        bundle.rubric.payload,
    )
    _validate_options(bundle.question_type, content, bundle.options)
    _validate_claim_phrases(rubric)
    _validate_mappings(bundle)
    _validate_publication(bundle, content, rubric)
    _validate_generated_metadata(bundle)

    return ValidatedQuestionImport(
        bundle=bundle,
        content=content,
        rubric_payload=rubric,
        trust_label=trust_label,
        content_hash=canonical_content_hash(
            subject_id=bundle.subject_id,
            curriculum_version_id=bundle.curriculum_version_id,
            question_type=bundle.question_type,
            source_class=bundle.source_class,
            trust_label=trust_label,
            prompt=bundle.prompt,
            explanation=bundle.explanation,
            content=content.model_dump(mode="json"),
            options=(option.model_dump(mode="json") for option in bundle.options),
            rubric_type=bundle.rubric.rubric_type,
            rubric_version=1,
            rubric_payload=rubric.model_dump(mode="json"),
            rubric_max_score=bundle.rubric.max_score,
            rubric_evidence_ceiling=bundle.rubric.evidence_ceiling,
            rubric_status=bundle.rubric.status,
            mappings=(
                {
                    "concept_version_id": mapping.concept_version_id,
                    "learning_objective_id": mapping.learning_objective_id,
                    "mapping_role": mapping.mapping_role,
                    "weight": mapping.weight,
                    "provenance_type": mapping.provenance_type,
                    "provenance_ref": mapping.provenance_ref,
                }
                for mapping in bundle.concept_mappings
            ),
            model_key=bundle.model_key,
            prompt_version=bundle.prompt_version,
            grounding_evidence_ids=bundle.grounding_evidence_ids,
            validator_version=bundle.validator_version,
            validation_score=bundle.validation_score,
            generation_trace_ref=bundle.generation_trace_ref,
        ),
    )


def _validate_options(
    question_type: str,
    content: QuestionContent,
    options: list[QuestionOptionImport],
) -> None:
    if question_type not in OPTION_QUESTION_TYPES:
        if options:
            raise QuestionValidationError(
                "options_not_allowed",
                "This question type cannot carry answer options.",
                "options",
            )
        return

    if not isinstance(content, ChoiceContent):
        raise QuestionValidationError(
            "content_type_mismatch",
            "Question content does not match its declared type.",
            "content",
        )
    if not MIN_OPTIONS <= len(options) <= MAX_OPTIONS:
        raise QuestionValidationError(
            "options_invalid",
            "The number of answer options is invalid.",
            "options",
        )
    keys = [option.option_key for option in options]
    if len(set(keys)) != len(keys):
        raise QuestionValidationError(
            "options_invalid",
            "Answer option keys must be unique.",
            "options",
        )
    orders = sorted(option.display_order for option in options)
    if orders != list(range(len(options))):
        raise QuestionValidationError(
            "options_invalid",
            "Answer option display order must be contiguous.",
            "options",
        )
    correct = [option for option in options if option.is_correct]
    if not correct:
        raise QuestionValidationError(
            "options_invalid",
            "At least one answer option must be correct.",
            "options",
        )
    if content.selection_mode == "single" and len(correct) != 1:
        raise QuestionValidationError(
            "options_invalid",
            "A single-choice question must have exactly one correct option.",
            "options",
        )


def _validate_claim_phrases(rubric: RubricPayload) -> None:
    if not isinstance(rubric, ClaimRubricPayload):
        return

    seen: dict[str, str] = {}
    for claim in rubric.claims:
        for phrase in [*claim.variants, *claim.contradictions]:
            normalized = normalize_text(phrase)
            if not normalized:
                raise QuestionValidationError(
                    "rubric_invalid",
                    "Rubric phrases must contain readable text.",
                    "rubric.payload.claims",
                )
            owner = seen.get(normalized)
            if owner is not None:
                raise QuestionValidationError(
                    "rubric_invalid",
                    "Rubric phrases must be unique across claims.",
                    "rubric.payload.claims",
                )
            seen[normalized] = claim.claim_id


def _validate_mappings(bundle: QuestionImportBundle) -> None:
    if len(bundle.concept_mappings) > MAX_CONCEPT_MAPPINGS:
        raise QuestionValidationError(
            "concept_mapping_invalid",
            "Too many concept mappings were supplied.",
            "concept_mappings",
        )
    pairs = [
        (mapping.concept_version_id, mapping.mapping_role) for mapping in bundle.concept_mappings
    ]
    if len(set(pairs)) != len(pairs):
        raise QuestionValidationError(
            "concept_mapping_invalid",
            "Concept mappings must be unique per concept and role.",
            "concept_mappings",
        )
    for mapping in bundle.concept_mappings:
        if (
            mapping.mapping_role == "primary"
            and mapping.weight.quantize(CONCEPT_WEIGHT_QUANTUM, rounding=ROUND_HALF_UP) <= 0
        ):
            raise QuestionValidationError(
                "concept_mapping_invalid",
                "A primary concept mapping must have a positive weight.",
                "concept_mappings",
            )


def _validate_publication(
    bundle: QuestionImportBundle,
    content: QuestionContent,
    rubric: RubricPayload,
) -> None:
    if bundle.validation_status != "approved":
        return

    if not bundle.explanation.strip():
        raise QuestionValidationError(
            "publish_requirements_missing",
            "An approved question needs an explanation.",
            "explanation",
        )
    if bundle.reviewer_principal is None:
        raise QuestionValidationError(
            "reviewer_required",
            "An approved question needs a reviewer identity.",
            "reviewer_principal",
        )
    if bundle.source_class != "ai_generated" and bundle.author_principal is None:
        raise QuestionValidationError(
            "author_required",
            "An approved question needs an author identity.",
            "author_principal",
        )
    if bundle.rubric.status != "approved":
        raise QuestionValidationError(
            "publish_requirements_missing",
            "An approved question needs an approved rubric.",
            "rubric.status",
        )
    if (
        bundle.rubric.evidence_ceiling.quantize(EVIDENCE_CEILING_QUANTUM, rounding=ROUND_HALF_UP)
        <= 0
    ):
        raise QuestionValidationError(
            "publish_requirements_missing",
            "An approved rubric needs a positive evidence ceiling.",
            "rubric.evidence_ceiling",
        )
    if not any(mapping.mapping_role == "primary" for mapping in bundle.concept_mappings):
        raise QuestionValidationError(
            "concept_mapping_missing",
            "An approved question needs a primary concept mapping.",
            "concept_mappings",
        )
    if (
        isinstance(content, NumericContent)
        and isinstance(rubric, NumericRubricPayload)
        and rubric.unit_rule == "required"
        and not content.unit_affordance
    ):
        raise QuestionValidationError(
            "content_invalid",
            "A numeric question with a required unit needs a unit affordance.",
            "content.unit_affordance",
        )


def _validate_generated_metadata(bundle: QuestionImportBundle) -> None:
    if bundle.source_class != "ai_generated":
        return
    missing = (
        not bundle.model_key
        or not bundle.prompt_version
        or not bundle.grounding_evidence_ids
        or not bundle.validator_version
        or bundle.validation_score is None
        or not bundle.generation_trace_ref
    )
    if missing:
        raise QuestionValidationError(
            "ai_metadata_missing",
            "Generated content needs grounding and validation evidence.",
            "model_key",
        )
    if (
        bundle.rubric.evidence_ceiling.quantize(EVIDENCE_CEILING_QUANTUM, rounding=ROUND_HALF_UP)
        > AI_EVIDENCE_CEILING
    ):
        raise QuestionValidationError(
            "rubric_invalid",
            "Generated content has a lower evidence ceiling.",
            "rubric.evidence_ceiling",
        )


def _canonical_decimal_text(value: object, quantum: Decimal) -> str:
    decimal_value = value if isinstance(value, Decimal) else Decimal(str(value))
    decimal_value = decimal_value.quantize(quantum, rounding=ROUND_HALF_UP)
    if decimal_value == 0:
        return "0"
    return format(decimal_value.normalize(), "f")


def canonical_content_hash(
    *,
    subject_id: object,
    curriculum_version_id: object,
    question_type: str,
    source_class: str,
    trust_label: str,
    prompt: str,
    explanation: str,
    content: Mapping[str, Any],
    options: Iterable[Mapping[str, Any]],
    rubric_type: str,
    rubric_version: int,
    rubric_payload: Mapping[str, Any],
    rubric_max_score: object,
    rubric_evidence_ceiling: object,
    rubric_status: str,
    mappings: Iterable[Mapping[str, Any]],
    model_key: str | None,
    prompt_version: str | None,
    grounding_evidence_ids: Iterable[object],
    validator_version: str | None,
    validation_score: object | None,
    generation_trace_ref: str | None,
) -> str:
    """Hash every immutable content, grading and provenance field of a version.

    Numeric fields that live in fixed-scale PostgreSQL columns are quantized to
    that scale before hashing. This keeps an import replay stable after the
    database has rounded the stored value, while still detecting any real change.
    """

    normalized_mappings = sorted(
        (
            {
                "concept_version_id": str(mapping["concept_version_id"]),
                "learning_objective_id": (
                    str(mapping["learning_objective_id"])
                    if mapping.get("learning_objective_id") is not None
                    else None
                ),
                "mapping_role": str(mapping["mapping_role"]),
                "weight": _canonical_decimal_text(mapping["weight"], _MAPPING_WEIGHT_QUANTUM),
                "provenance_type": str(mapping["provenance_type"]),
                "provenance_ref": str(mapping["provenance_ref"]),
            }
            for mapping in mappings
        ),
        key=lambda item: (item["concept_version_id"], item["mapping_role"]),
    )
    normalized_options = sorted(
        (
            {
                "option_key": str(option["option_key"]),
                "display_text": str(option["display_text"]),
                "accessible_image_ref": option.get("accessible_image_ref"),
                "is_correct": bool(option["is_correct"]),
                "explanation": str(option["explanation"]),
                "display_order": int(option["display_order"]),
            }
            for option in options
        ),
        key=lambda item: item["display_order"],
    )
    payload = {
        "subject_id": str(subject_id),
        "curriculum_version_id": str(curriculum_version_id),
        "question_type": question_type,
        "source_class": source_class,
        "trust_label": trust_label,
        "prompt": prompt,
        "explanation": explanation,
        "content": dict(content),
        "options": normalized_options,
        "rubric": {
            "type": rubric_type,
            "version": int(rubric_version),
            "payload": dict(rubric_payload),
            "max_score": _canonical_decimal_text(rubric_max_score, _MAX_SCORE_QUANTUM),
            "evidence_ceiling": _canonical_decimal_text(
                rubric_evidence_ceiling, _EVIDENCE_CEILING_QUANTUM
            ),
            "status": rubric_status,
        },
        "concept_mappings": normalized_mappings,
        "generated_provenance": {
            "model_key": model_key,
            "prompt_version": prompt_version,
            "grounding_evidence_ids": [str(claim_id) for claim_id in grounding_evidence_ids],
            "validator_version": validator_version,
            "validation_score": (
                _canonical_decimal_text(validation_score, _VALIDATION_SCORE_QUANTUM)
                if validation_score is not None
                else None
            ),
            "generation_trace_ref": generation_trace_ref,
        },
    }
    canonical = json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


__all__ = [
    "QuestionValidationError",
    "canonical_content_hash",
    "parse_answer_payload",
    "parse_question_content",
    "parse_rubric_payload",
    "source_precedence_rank",
    "trust_label_for",
    "validate_answer_against_question",
    "validate_question_import",
]
