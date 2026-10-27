"""Typed content, rubric, answer and snapshot models for the question domain.

Correctness never appears in a student-facing model. Option correctness is kept
in the internal snapshot and in `question_options.is_correct`; rubric payloads
contain grading rules only and are never returned by a public endpoint.
"""

from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator

from memora.modules.questions.constants import (
    DEFAULT_MINIMUM_SUPPORTED_COVERAGE,
    MAX_ABSOLUTE_TOLERANCE,
    MAX_CLAIM_VARIANTS,
    MAX_CONCEPT_MAPPINGS,
    MAX_EXPLANATION_LENGTH,
    MAX_MEDIA_ALT_TEXT_LENGTH,
    MAX_MEDIA_ID_LENGTH,
    MAX_MEDIA_REFERENCES,
    MAX_NUMERIC_ABSOLUTE_VALUE,
    MAX_OPTION_EXPLANATION_LENGTH,
    MAX_OPTION_KEY_LENGTH,
    MAX_OPTION_TEXT_LENGTH,
    MAX_OPTIONS,
    MAX_PROMPT_LENGTH,
    MAX_QUESTION_CODE_LENGTH,
    MAX_RELATIVE_TOLERANCE,
    MAX_RUBRIC_CLAIMS,
    MAX_RUBRIC_MAX_SCORE,
    MAX_SHORT_ANSWER_LENGTH,
    MAX_SIGNIFICANT_FIGURES,
    MAX_UNIT_LENGTH,
    MIN_SIGNIFICANT_FIGURES,
)

_STRICT = ConfigDict(extra="forbid", str_strip_whitespace=True)
_OPTION_KEY_PATTERN = r"^[a-z0-9][a-z0-9_-]*$"
_CODE_PATTERN = r"^[a-z0-9][a-z0-9._-]*$"
_CLAIM_ID_PATTERN = r"^[a-z0-9][a-z0-9_-]*$"
_MEDIA_ID_PATTERN = r"^[A-Za-z0-9][A-Za-z0-9._:-]*$"


def _finite(value: Decimal, *, field: str) -> Decimal:
    if not value.is_finite():
        raise ValueError(f"{field} must be a finite number")
    return value


class MediaReference(BaseModel):
    """Authorized media reference carried by question content."""

    model_config = _STRICT

    media_id: Annotated[
        str,
        Field(min_length=1, max_length=MAX_MEDIA_ID_LENGTH, pattern=_MEDIA_ID_PATTERN),
    ]
    alt_text: Annotated[str, Field(min_length=1, max_length=MAX_MEDIA_ALT_TEXT_LENGTH)]
    media_type: Literal["image", "diagram", "audio"]


class ChoiceContent(BaseModel):
    """Option-based question content. Correct keys live outside this payload."""

    model_config = _STRICT

    kind: Literal["choice"] = "choice"
    schema_version: Literal["1"] = "1"
    selection_mode: Literal["single", "multiple"]
    media: Annotated[list[MediaReference], Field(max_length=MAX_MEDIA_REFERENCES)] = Field(
        default_factory=list
    )
    input_hint: Annotated[str, Field(max_length=200)] | None = None


class NumericContent(BaseModel):
    """Numeric question content without the expected value or tolerance."""

    model_config = _STRICT

    kind: Literal["numeric"] = "numeric"
    schema_version: Literal["1"] = "1"
    media: Annotated[list[MediaReference], Field(max_length=MAX_MEDIA_REFERENCES)] = Field(
        default_factory=list
    )
    unit_affordance: bool = False
    unit_options: Annotated[list[str], Field(max_length=8)] = Field(default_factory=list)
    input_hint: Annotated[str, Field(max_length=200)] | None = None

    @model_validator(mode="after")
    def _validate_units(self) -> NumericContent:
        normalized = [unit.strip() for unit in self.unit_options]
        if any(not unit or len(unit) > MAX_UNIT_LENGTH for unit in normalized):
            raise ValueError("unit options must be non-empty and bounded")
        if len(set(normalized)) != len(normalized):
            raise ValueError("unit options must be unique")
        self.unit_options = normalized
        return self


class ShortAnswerContent(BaseModel):
    """Bounded short-answer input configuration."""

    model_config = _STRICT

    kind: Literal["short_answer"] = "short_answer"
    schema_version: Literal["1"] = "1"
    media: Annotated[list[MediaReference], Field(max_length=MAX_MEDIA_REFERENCES)] = Field(
        default_factory=list
    )
    max_characters: Annotated[int, Field(ge=1, le=MAX_SHORT_ANSWER_LENGTH)] = 800
    input_hint: Annotated[str, Field(max_length=200)] | None = None


type QuestionContent = Annotated[
    ChoiceContent | NumericContent | ShortAnswerContent,
    Field(discriminator="kind"),
]


class ExactRubricPayload(BaseModel):
    """Option correctness is stored on `question_options.is_correct`."""

    model_config = _STRICT

    kind: Literal["exact"] = "exact"
    schema_version: Literal["1"] = "1"


class NumericTolerance(BaseModel):
    model_config = _STRICT

    mode: Literal["absolute", "relative"]
    value: Decimal

    @model_validator(mode="after")
    def _bounded(self) -> NumericTolerance:
        _finite(self.value, field="tolerance")
        if self.value < 0:
            raise ValueError("tolerance must not be negative")
        if self.mode == "relative":
            if self.value > MAX_RELATIVE_TOLERANCE:
                raise ValueError("relative tolerance must be between 0 and 1")
        elif self.value > MAX_ABSOLUTE_TOLERANCE:
            raise ValueError("absolute tolerance is too large")
        return self


class NumericRubricPayload(BaseModel):
    """Deterministic numeric grading rules for one question version."""

    model_config = _STRICT

    kind: Literal["numeric"] = "numeric"
    schema_version: Literal["1"] = "1"
    expected_value: Decimal
    expected_unit: Annotated[str, Field(max_length=MAX_UNIT_LENGTH)] | None = None
    unit_rule: Literal["required", "optional", "ignored"]
    tolerance: NumericTolerance
    partial_tolerance: NumericTolerance | None = None
    significant_figures: (
        Annotated[int, Field(ge=MIN_SIGNIFICANT_FIGURES, le=MAX_SIGNIFICANT_FIGURES)] | None
    ) = None
    allow_negative: bool = True

    @model_validator(mode="after")
    def _validate_rules(self) -> NumericRubricPayload:
        _finite(self.expected_value, field="expected_value")
        if abs(self.expected_value) > MAX_NUMERIC_ABSOLUTE_VALUE:
            raise ValueError("expected value is out of bounds")
        if not self.allow_negative and self.expected_value < 0:
            raise ValueError("expected value cannot be negative")
        if self.unit_rule in {"required", "optional"} and not self.expected_unit:
            raise ValueError("an expected unit is required for this unit rule")
        if self.unit_rule == "ignored" and self.expected_unit is not None:
            raise ValueError("an ignored unit rule cannot declare an expected unit")
        if self.tolerance.mode == "relative" and self.expected_value == 0:
            raise ValueError("relative tolerance cannot be used with a zero expected value")
        if self.partial_tolerance is not None:
            if self.partial_tolerance.mode != self.tolerance.mode:
                raise ValueError("partial tolerance must use the same mode")
            if self.partial_tolerance.value < self.tolerance.value:
                raise ValueError("partial tolerance must not be narrower than tolerance")
            if self.partial_tolerance.mode == "relative" and self.expected_value == 0:
                raise ValueError("relative tolerance cannot be used with a zero expected value")
        return self


class ClaimRule(BaseModel):
    model_config = _STRICT

    claim_id: Annotated[str, Field(min_length=1, max_length=64, pattern=_CLAIM_ID_PATTERN)]
    claim_text: Annotated[str, Field(min_length=1, max_length=500)] | None = None
    required: bool = True
    weight: Decimal = Decimal("1")
    variants: Annotated[
        list[Annotated[str, Field(min_length=1, max_length=200)]],
        Field(min_length=1, max_length=MAX_CLAIM_VARIANTS),
    ]
    contradictions: Annotated[
        list[Annotated[str, Field(min_length=1, max_length=200)]],
        Field(max_length=MAX_CLAIM_VARIANTS),
    ] = Field(default_factory=list)

    @model_validator(mode="after")
    def _bounded(self) -> ClaimRule:
        _finite(self.weight, field="claim weight")
        if self.weight <= 0:
            raise ValueError("claim weight must be positive")
        if len(set(self.variants)) != len(self.variants):
            raise ValueError("claim variants must be unique")
        if len(set(self.contradictions)) != len(self.contradictions):
            raise ValueError("claim contradictions must be unique")
        if set(self.variants) & set(self.contradictions):
            raise ValueError("a phrase cannot be both a variant and a contradiction")
        return self


class ClaimRubricPayload(BaseModel):
    """Bounded deterministic claim criteria for short-answer grading."""

    model_config = _STRICT

    kind: Literal["claim"] = "claim"
    schema_version: Literal["1"] = "1"
    claims: Annotated[list[ClaimRule], Field(min_length=1, max_length=MAX_RUBRIC_CLAIMS)]
    minimum_supported_coverage: Annotated[Decimal, Field(ge=0, le=1)] = (
        DEFAULT_MINIMUM_SUPPORTED_COVERAGE
    )

    @model_validator(mode="after")
    def _validate_claims(self) -> ClaimRubricPayload:
        if not any(claim.required for claim in self.claims):
            raise ValueError("at least one required claim is needed")
        if len({claim.claim_id for claim in self.claims}) != len(self.claims):
            raise ValueError("claim identifiers must be unique")
        return self


type RubricPayload = Annotated[
    ExactRubricPayload | NumericRubricPayload | ClaimRubricPayload,
    Field(discriminator="kind"),
]


class QuestionOptionImport(BaseModel):
    model_config = _STRICT

    option_key: Annotated[
        str,
        Field(min_length=1, max_length=MAX_OPTION_KEY_LENGTH, pattern=_OPTION_KEY_PATTERN),
    ]
    display_text: Annotated[str, Field(min_length=1, max_length=MAX_OPTION_TEXT_LENGTH)]
    accessible_image_ref: Annotated[str, Field(max_length=500)] | None = None
    is_correct: bool
    explanation: Annotated[str, Field(max_length=MAX_OPTION_EXPLANATION_LENGTH)] = ""
    display_order: Annotated[int, Field(ge=0, le=MAX_OPTIONS - 1)]


class RubricImport(BaseModel):
    model_config = _STRICT

    rubric_type: Literal["exact", "numeric", "claim"]
    max_score: Decimal
    evidence_ceiling: Annotated[Decimal, Field(ge=0, le=1)]
    status: Literal["draft", "approved"] = "approved"
    payload: dict[str, object]

    @model_validator(mode="after")
    def _bounded(self) -> RubricImport:
        _finite(self.max_score, field="max_score")
        if self.max_score <= 0 or self.max_score > MAX_RUBRIC_MAX_SCORE:
            raise ValueError("max_score is out of bounds")
        return self


class ConceptMappingImport(BaseModel):
    model_config = _STRICT

    concept_version_id: UUID
    learning_objective_id: UUID | None = None
    mapping_role: Literal["primary", "supporting", "prerequisite", "misconception"]
    weight: Annotated[Decimal, Field(ge=0, le=1)]
    provenance_type: Annotated[str, Field(min_length=1, max_length=50)]
    provenance_ref: Annotated[str, Field(min_length=1, max_length=200)]


class QuestionImportBundle(BaseModel):
    """A reviewed, self-contained import for one new immutable version."""

    model_config = _STRICT

    question_code: Annotated[
        str,
        Field(min_length=1, max_length=MAX_QUESTION_CODE_LENGTH, pattern=_CODE_PATTERN),
    ]
    subject_id: UUID
    curriculum_version_id: UUID
    source_class: Literal["expert_verified", "teacher_authored", "ai_generated"]
    question_type: Literal["mcq", "numeric", "short_answer", "diagram_interpretation"]
    prompt: Annotated[str, Field(min_length=1, max_length=MAX_PROMPT_LENGTH)]
    explanation: Annotated[str, Field(max_length=MAX_EXPLANATION_LENGTH)]
    trust_label: Annotated[str, Field(max_length=50)] | None = None
    validation_status: Literal["draft", "approved"]
    author_principal: UUID | None = None
    reviewer_principal: UUID | None = None
    model_key: Annotated[str, Field(max_length=100)] | None = None
    prompt_version: Annotated[str, Field(max_length=100)] | None = None
    grounding_evidence_ids: Annotated[list[UUID], Field(max_length=50)] = Field(
        default_factory=list
    )
    validator_version: Annotated[str, Field(max_length=100)] | None = None
    validation_score: Annotated[Decimal, Field(ge=0, le=1)] | None = None
    generation_trace_ref: Annotated[str, Field(max_length=200)] | None = None
    content: dict[str, object]
    options: Annotated[list[QuestionOptionImport], Field(max_length=MAX_OPTIONS)] = Field(
        default_factory=list
    )
    rubric: RubricImport
    concept_mappings: Annotated[
        list[ConceptMappingImport], Field(max_length=MAX_CONCEPT_MAPPINGS)
    ] = Field(default_factory=list)


class ValidatedQuestionImport(BaseModel):
    """Import bundle plus parsed typed payloads and a canonical content hash."""

    model_config = ConfigDict(extra="forbid", frozen=True)

    bundle: QuestionImportBundle
    content: QuestionContent
    rubric_payload: RubricPayload
    trust_label: str
    content_hash: str


class SingleChoiceAnswer(BaseModel):
    model_config = _STRICT

    type: Literal["single_choice"]
    option_keys: Annotated[
        list[
            Annotated[
                str,
                Field(
                    min_length=1,
                    max_length=MAX_OPTION_KEY_LENGTH,
                    pattern=_OPTION_KEY_PATTERN,
                ),
            ]
        ],
        Field(min_length=1, max_length=1),
    ]


class MultipleChoiceAnswer(BaseModel):
    model_config = _STRICT

    type: Literal["multiple_choice"]
    option_keys: Annotated[
        list[
            Annotated[
                str,
                Field(
                    min_length=1,
                    max_length=MAX_OPTION_KEY_LENGTH,
                    pattern=_OPTION_KEY_PATTERN,
                ),
            ]
        ],
        Field(min_length=1, max_length=MAX_OPTIONS),
    ]

    @model_validator(mode="after")
    def _unique_options(self) -> MultipleChoiceAnswer:
        if len(set(self.option_keys)) != len(self.option_keys):
            raise ValueError("option keys must be unique")
        return self


class NumericAnswer(BaseModel):
    model_config = _STRICT

    type: Literal["numeric"]
    value: Decimal
    unit: Annotated[str, Field(max_length=MAX_UNIT_LENGTH)] | None = None

    @model_validator(mode="after")
    def _bounded(self) -> NumericAnswer:
        _finite(self.value, field="answer value")
        if abs(self.value) > MAX_NUMERIC_ABSOLUTE_VALUE:
            raise ValueError("answer value is out of bounds")
        return self


class ShortAnswerText(BaseModel):
    model_config = _STRICT

    type: Literal["short_answer"]
    text: Annotated[str, Field(min_length=1, max_length=MAX_SHORT_ANSWER_LENGTH)]


type AnswerPayload = Annotated[
    SingleChoiceAnswer | MultipleChoiceAnswer | NumericAnswer | ShortAnswerText,
    Field(discriminator="type"),
]


class PublicQuestionOption(BaseModel):
    option_key: str
    display_text: str
    accessible_image_ref: str | None
    display_order: int


class PublicResponseConfig(BaseModel):
    type: Literal["single_choice", "multiple_choice", "numeric", "short_answer"]
    min_selections: int | None = None
    max_selections: int | None = None
    unit_affordance: bool | None = None
    unit_options: list[str] | None = None
    max_characters: int | None = None
    input_hint: str | None = None


class PublicQuestion(BaseModel):
    """Pre-submission payload with no correctness or rubric data."""

    question_version_id: UUID
    question_type: Literal["single_choice", "multiple_choice", "numeric", "short_answer"]
    prompt: str
    media: list[MediaReference]
    options: list[PublicQuestionOption]
    response_config: PublicResponseConfig
    trust_label: str


@dataclass(frozen=True, slots=True)
class QuestionOptionSnapshot:
    option_key: str
    display_text: str
    accessible_image_ref: str | None
    is_correct: bool
    explanation: str
    display_order: int


@dataclass(frozen=True, slots=True)
class QuestionRubricSnapshot:
    id: UUID
    rubric_type: str
    rubric_version: int
    payload: RubricPayload
    max_score: Decimal
    evidence_ceiling: Decimal
    status: str


@dataclass(frozen=True, slots=True)
class ConceptMappingSnapshot:
    concept_version_id: UUID
    learning_objective_id: UUID | None
    mapping_role: str
    weight: Decimal


@dataclass(frozen=True, slots=True)
class QuestionSnapshot:
    question_version_id: UUID
    question_code: str
    source_class: str
    validation_status: str
    question_type: str
    prompt: str
    explanation: str
    trust_label: str
    content: QuestionContent
    options: tuple[QuestionOptionSnapshot, ...]
    rubric: QuestionRubricSnapshot
    concept_mappings: tuple[ConceptMappingSnapshot, ...]

    @property
    def selection_mode(self) -> Literal["single", "multiple"] | None:
        if isinstance(self.content, ChoiceContent):
            return self.content.selection_mode
        return None

    def correct_option_keys(self) -> frozenset[str]:
        return frozenset(option.option_key for option in self.options if option.is_correct)

    def public_question(self) -> PublicQuestion:
        content = self.content
        if isinstance(content, ChoiceContent):
            question_type: Literal[
                "single_choice", "multiple_choice", "numeric", "short_answer"
            ] = "single_choice" if content.selection_mode == "single" else "multiple_choice"
            response_config = PublicResponseConfig(
                type=question_type,
                min_selections=1,
                max_selections=(
                    1 if content.selection_mode == "single" else max(1, len(self.options))
                ),
                input_hint=content.input_hint,
            )
        elif isinstance(content, NumericContent):
            question_type = "numeric"
            response_config = PublicResponseConfig(
                type="numeric",
                unit_affordance=content.unit_affordance,
                unit_options=list(content.unit_options),
                input_hint=content.input_hint,
            )
        else:
            question_type = "short_answer"
            response_config = PublicResponseConfig(
                type="short_answer",
                max_characters=content.max_characters,
                input_hint=content.input_hint,
            )
        return PublicQuestion(
            question_version_id=self.question_version_id,
            question_type=question_type,
            prompt=self.prompt,
            media=list(content.media),
            options=[
                PublicQuestionOption(
                    option_key=option.option_key,
                    display_text=option.display_text,
                    accessible_image_ref=option.accessible_image_ref,
                    display_order=option.display_order,
                )
                for option in sorted(self.options, key=lambda item: item.display_order)
            ],
            response_config=response_config,
            trust_label=self.trust_label,
        )
