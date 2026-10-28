"""Draft-only validation gates for the T24 Physics pilot envelope.

The pilot envelope is deliberately not a T12 import bundle. A draft has
``question.source_class = null`` and ``question.target_source_class =
"expert_verified"``. Drafts are validated offline and must never be persisted.
Only an approved envelope with a completed review, a content hash, and every
source/review gate may be converted to a T12 ``QuestionImportBundle``.

This module checks the recorded fields, not whether an author or reviewer exists,
holds the claimed qualification, or is independent. A real principal,
qualification record, reproduction decision and approval remain project
responsibilities.
"""

from __future__ import annotations

import re
from collections.abc import Mapping
from datetime import datetime
from typing import Any
from uuid import UUID

from memora.modules.curriculum.seed_data import CONCEPTS_DATA, LEARNING_OBJECTIVES
from memora.modules.questions.models import QuestionImportBundle, ValidatedQuestionImport
from memora.modules.questions.validation import validate_question_import

PILOT_SCHEMA_VERSION = "1.0"
PILOT_SOURCE_TYPES = frozenset({"past_paper", "synthetic"})
PILOT_TARGET_SOURCE_CLASS = "expert_verified"
PILOT_PROVENANCE_TYPES = frozenset({"analyst_mapping", "source_analysis", "pilot_review"})
PILOT_DRAFT_PROVENANCE_TYPES = frozenset({"analyst_mapping", "source_analysis"})
PILOT_REVIEW_SCOPES = frozenset({"derivation", "ambiguity", "curriculum_mapping"})
PILOT_PAST_PAPER_REVIEW_SCOPES = PILOT_REVIEW_SCOPES | {"transcription"}

_PILOT_ID_PATTERN = re.compile(r"^PILOT-PHYS-[0-9]{4}-P1-Q[0-9]{1,2}$")
_QUESTION_CODE_PATTERN = re.compile(r"^[a-z0-9][a-z0-9._-]*$")
_OPTION_KEY_PATTERN = re.compile(r"^[a-z0-9][a-z0-9_-]*$")
_SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")
_SOURCE_ID_PATTERNS = {
    "past_paper": re.compile(r"^SL-DOE-AL-PHYS-[0-9]{4}-P1$"),
    "synthetic": re.compile(r"^SYNTHETIC-[A-Z0-9-]+$"),
}

_OBJECTIVE_IDS_BY_CODE = {
    str(objective["objective_code"]): UUID(str(objective["id"]))
    for objective in LEARNING_OBJECTIVES
}
_CONCEPT_OBJECTIVE_IDS = {
    UUID(str(concept["version_id"])): _OBJECTIVE_IDS_BY_CODE[str(concept["objective_code"])]
    for concept in CONCEPTS_DATA
}


class PilotEnvelopeError(ValueError):
    """A pilot envelope failed a semantic gate."""

    def __init__(self, code: str, message: str, field: str) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.field = field

    def as_dict(self) -> dict[str, str]:
        return {"code": self.code, "message": self.message, "field": self.field}


def _fail(code: str, message: str, field: str) -> None:
    raise PilotEnvelopeError(code, message, field)


def _mapping(value: Any, field: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        _fail("pilot_envelope_invalid", "Expected an object.", field)
    return value


def _text(
    value: Any,
    field: str,
    *,
    allow_none: bool = False,
    pattern: re.Pattern[str] | None = None,
    max_length: int | None = None,
) -> str | None:
    if value is None and allow_none:
        return None
    if not isinstance(value, str) or not value.strip():
        _fail("pilot_envelope_invalid", "Expected a non-empty string.", field)
    if pattern is not None and pattern.fullmatch(value) is None:
        _fail("pilot_envelope_invalid", "Value has an invalid format.", field)
    if max_length is not None and len(value) > max_length:
        _fail("pilot_envelope_invalid", "Value is too long.", field)
    return value


def _uuid_text(value: Any, field: str, *, allow_none: bool = False) -> str | None:
    if value is None and allow_none:
        return None
    try:
        parsed = UUID(str(value))
    except (TypeError, ValueError):
        _fail("pilot_envelope_invalid", "Expected a UUID.", field)
    return str(parsed)


def _bool(value: Any, field: str) -> bool:
    if not isinstance(value, bool):
        _fail("pilot_envelope_invalid", "Expected a boolean.", field)
    return value


def _int(
    value: Any,
    field: str,
    *,
    minimum: int | None = None,
    maximum: int | None = None,
) -> int:
    if not isinstance(value, int) or isinstance(value, bool):
        _fail("pilot_envelope_invalid", "Expected an integer.", field)
    if minimum is not None and value < minimum:
        _fail("pilot_envelope_invalid", "Integer is below its minimum.", field)
    if maximum is not None and value > maximum:
        _fail("pilot_envelope_invalid", "Integer is above its maximum.", field)
    return value


def _number(value: Any, field: str) -> float:
    if not isinstance(value, (int, float)) or isinstance(value, bool):
        _fail("pilot_envelope_invalid", "Expected a number.", field)
    return float(value)


def _datetime_text(value: Any, field: str) -> str:
    text = _text(value, field)
    try:
        datetime.fromisoformat(text.replace("Z", "+00:00"))
    except ValueError:
        _fail("pilot_envelope_invalid", "Expected an ISO-8601 date-time.", field)
    return text


def _datetime_value(value: Any, field: str) -> datetime:
    text = _datetime_text(value, field)
    parsed = datetime.fromisoformat(text.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        _fail(
            "pilot_envelope_invalid",
            "Expected a timezone-aware ISO-8601 date-time.",
            field,
        )
    return parsed


def _list(value: Any, field: str, *, minimum: int = 0, maximum: int | None = None) -> list[Any]:
    if not isinstance(value, list):
        _fail("pilot_envelope_invalid", "Expected a list.", field)
    if len(value) < minimum:
        _fail("pilot_envelope_invalid", "List has too few items.", field)
    if maximum is not None and len(value) > maximum:
        _fail("pilot_envelope_invalid", "List has too many items.", field)
    return value


def source_reference(source: Mapping[str, Any]) -> str:
    """Return the canonical reference a reviewer signs."""

    if source["source_type"] == "synthetic":
        return str(source["source_id"])
    return "|".join(
        (
            str(source["source_id"]),
            str(source["document_sha256"]),
            str(source["pdf_page"]),
            str(source["question_number"]),
        )
    )


def _validate_source(source: Mapping[str, Any], *, approved: bool) -> None:
    source_type = _text(source.get("source_type"), "source.source_type")
    if source_type not in PILOT_SOURCE_TYPES:
        _fail("pilot_source_invalid", "Unsupported source type.", "source.source_type")
    source_id = _text(source.get("source_id"), "source.source_id", max_length=200)
    if (
        source_type in _SOURCE_ID_PATTERNS
        and _SOURCE_ID_PATTERNS[source_type].fullmatch(source_id) is None
    ):
        _fail(
            "pilot_source_invalid",
            "The source identifier has an invalid format.",
            "source.source_id",
        )
    _text(source.get("licence_note"), "source.licence_note", max_length=500)
    if source.get("medium") != "English":
        _fail(
            "pilot_source_invalid",
            "The pilot accepts English-medium content only.",
            "source.medium",
        )

    if source_type == "past_paper":
        _text(source.get("document_filename"), "source.document_filename", max_length=300)
        _text(
            source.get("document_sha256"),
            "source.document_sha256",
            pattern=_SHA256_PATTERN,
        )
        exam_year = _int(source.get("exam_year"), "source.exam_year", minimum=2017, maximum=2025)
        source_year = int(str(source_id).rsplit("-", 2)[1])
        if source_year != exam_year:
            _fail(
                "pilot_source_invalid",
                "The source identifier year must match exam_year.",
                "source.source_id",
            )
        _text(source.get("exam_label"), "source.exam_label", max_length=40)
        if source.get("paper") != "Paper I":
            _fail(
                "pilot_source_invalid",
                "The pilot accepts Paper I only.",
                "source.paper",
            )
        _int(source.get("question_number"), "source.question_number", minimum=1, maximum=50)
        _int(source.get("pdf_page"), "source.pdf_page", minimum=1)
        if source.get("official_key_status") not in {
            "not_found",
            "not_published",
            "marking_scheme_not_mcq_key",
            "unknown",
        }:
            _fail(
                "pilot_source_invalid",
                "A past paper needs an official-key status.",
                "source.official_key_status",
            )
        reproduction = source.get("reproduction_status")
        if reproduction not in {"unapproved", "approved"}:
            _fail(
                "pilot_source_invalid",
                "A past paper needs a reproduction status.",
                "source.reproduction_status",
            )
        if reproduction == "approved":
            _text(
                source.get("reproduction_approval_ref"),
                "source.reproduction_approval_ref",
                max_length=300,
            )
        elif approved:
            _fail(
                "pilot_reproduction_not_approved",
                "An approved past-paper item needs reproduction approval.",
                "source.reproduction_status",
            )
        _bool(source.get("transcription_verified"), "source.transcription_verified")
        if approved and source.get("transcription_verified") is not True:
            _fail(
                "pilot_transcription_not_verified",
                "An approved past-paper item needs a verified transcription.",
                "source.transcription_verified",
            )
        return

    # Synthetic content has no document and no reproduction question.
    for field in (
        "document_filename",
        "document_sha256",
        "exam_year",
        "paper",
        "question_number",
        "pdf_page",
    ):
        if source.get(field) is not None:
            _fail(
                "pilot_source_invalid",
                "A synthetic item must not claim a source document field.",
                f"source.{field}",
            )
    if source.get("exam_label") != "synthetic":
        _fail(
            "pilot_source_invalid",
            "A synthetic item needs exam_label='synthetic'.",
            "source.exam_label",
        )
    if source.get("official_key_status") != "not_applicable":
        _fail(
            "pilot_source_invalid",
            "A synthetic item has no official key.",
            "source.official_key_status",
        )
    if source.get("reproduction_status") != "not_applicable":
        _fail(
            "pilot_source_invalid",
            "A synthetic item has no reproduction status.",
            "source.reproduction_status",
        )
    if source.get("reproduction_approval_ref") is not None:
        _fail(
            "pilot_source_invalid",
            "A synthetic item cannot claim reproduction approval.",
            "source.reproduction_approval_ref",
        )
    if source.get("transcription_verified") is not False:
        _fail(
            "pilot_source_invalid",
            "A synthetic item has no source transcription to verify.",
            "source.transcription_verified",
        )


def _validate_options(options: list[Any]) -> list[Mapping[str, Any]]:
    if not 2 <= len(options) <= 10:
        _fail("pilot_question_invalid", "A pilot MCQ needs 2-10 options.", "question.options")
    keys: list[str] = []
    orders: list[int] = []
    correct: list[str] = []
    for index, raw in enumerate(options):
        field = f"question.options[{index}]"
        option = _mapping(raw, field)
        key = _text(option.get("option_key"), f"{field}.option_key", pattern=_OPTION_KEY_PATTERN)
        _text(option.get("display_text"), f"{field}.display_text", max_length=1000)
        _bool(option.get("is_correct"), f"{field}.is_correct")
        order = _int(option.get("display_order"), f"{field}.display_order", minimum=0)
        keys.append(key)
        orders.append(order)
        if option.get("is_correct"):
            correct.append(key)
    if len(set(keys)) != len(keys):
        _fail("pilot_question_invalid", "Option keys must be unique.", "question.options")
    if sorted(orders) != list(range(len(options))):
        _fail(
            "pilot_question_invalid", "Option display order must be contiguous.", "question.options"
        )
    if len(correct) != 1:
        _fail(
            "pilot_question_invalid",
            "A single-choice pilot MCQ must have exactly one correct option.",
            "question.options",
        )
    return [item for item in options if isinstance(item, Mapping)]


def _validate_question(
    question: Mapping[str, Any],
    *,
    approved: bool,
) -> None:
    question_code = _text(
        question.get("question_code"),
        "question.question_code",
        pattern=_QUESTION_CODE_PATTERN,
        max_length=100,
    )
    del question_code
    _uuid_text(question.get("subject_id"), "question.subject_id")
    _uuid_text(question.get("curriculum_version_id"), "question.curriculum_version_id")
    if question.get("question_type") != "mcq":
        _fail("pilot_question_invalid", "The pilot supports MCQ only.", "question.question_type")
    _text(question.get("prompt"), "question.prompt", max_length=5000)
    _text(question.get("explanation"), "question.explanation", max_length=5000)

    status = question.get("validation_status")
    if status not in {"draft", "approved"}:
        _fail("pilot_question_invalid", "Invalid validation status.", "question.validation_status")
    if status != ("approved" if approved else "draft"):
        _fail(
            "pilot_question_invalid",
            "Question status is inconsistent.",
            "question.validation_status",
        )

    source_class = question.get("source_class")
    target = question.get("target_source_class")
    if target != PILOT_TARGET_SOURCE_CLASS:
        _fail(
            "pilot_source_class_invalid",
            "The pilot target source class must be expert_verified.",
            "question.target_source_class",
        )
    if status == "draft":
        if source_class is not None:
            _fail(
                "pilot_draft_source_class",
                "A draft must not carry a source class; use target_source_class instead.",
                "question.source_class",
            )
        if question.get("reviewer_principal") is not None:
            _fail(
                "pilot_draft_reviewer",
                "A draft must not carry a reviewer principal before review.",
                "question.reviewer_principal",
            )
    else:
        if source_class != PILOT_TARGET_SOURCE_CLASS:
            _fail(
                "pilot_source_class_invalid",
                "An approved pilot item must be expert_verified.",
                "question.source_class",
            )

    author = _uuid_text(
        question.get("author_principal"), "question.author_principal", allow_none=True
    )
    author_qualification = _text(
        question.get("author_qualification_ref"),
        "question.author_qualification_ref",
        allow_none=True,
        max_length=300,
    )
    reviewer = _uuid_text(
        question.get("reviewer_principal"), "question.reviewer_principal", allow_none=True
    )
    if approved and (author is None or reviewer is None):
        _fail(
            "pilot_principals_required",
            "An approved item needs author and reviewer principals.",
            "question.author_principal",
        )
    if approved and author_qualification is None:
        _fail(
            "pilot_author_qualification_required",
            "An approved item needs author qualification evidence.",
            "question.author_qualification_ref",
        )
    if not approved and author_qualification is not None:
        _fail(
            "pilot_draft_author_qualification",
            "A draft must not carry author qualification evidence before approval.",
            "question.author_qualification_ref",
        )
    if author is not None and reviewer is not None and author == reviewer:
        _fail(
            "pilot_reviewer_independence",
            "The reviewer must be independent of the author.",
            "question.reviewer_principal",
        )

    content = _mapping(question.get("content"), "question.content")
    if set(content) != {"kind", "schema_version", "selection_mode"}:
        _fail(
            "pilot_content_invalid",
            "The pilot content payload must contain only kind, schema_version and selection_mode.",
            "question.content",
        )
    if content.get("kind") != "choice" or content.get("schema_version") != "1":
        _fail("pilot_content_invalid", "The pilot content payload is invalid.", "question.content")
    if content.get("selection_mode") != "single":
        _fail(
            "pilot_content_invalid",
            "The pilot supports single choice only.",
            "question.content.selection_mode",
        )

    options = _list(question.get("options"), "question.options", minimum=2, maximum=10)
    _validate_options(options)

    rubric = _mapping(question.get("rubric"), "question.rubric")
    if rubric.get("rubric_type") != "exact":
        _fail(
            "pilot_rubric_invalid",
            "The pilot supports exact rubrics only.",
            "question.rubric.rubric_type",
        )
    if rubric.get("status") not in {"draft", "approved"}:
        _fail("pilot_rubric_invalid", "Invalid rubric status.", "question.rubric.status")
    if approved and rubric.get("status") != "approved":
        _fail(
            "pilot_rubric_not_approved",
            "An approved item needs an approved rubric.",
            "question.rubric.status",
        )
    if not approved and rubric.get("status") != "draft":
        _fail(
            "pilot_rubric_invalid",
            "A draft rubric must remain in draft status.",
            "question.rubric.status",
        )
    if _number(rubric.get("max_score"), "question.rubric.max_score") != 1.0:
        _fail("pilot_rubric_invalid", "The pilot uses max_score = 1.", "question.rubric.max_score")
    ceiling = _number(rubric.get("evidence_ceiling"), "question.rubric.evidence_ceiling")
    if not 0 < ceiling <= 1:
        _fail(
            "pilot_rubric_invalid",
            "The evidence ceiling must be in (0, 1].",
            "question.rubric.evidence_ceiling",
        )
    payload = _mapping(rubric.get("payload"), "question.rubric.payload")
    if payload.get("kind") != "exact" or payload.get("schema_version") != "1":
        _fail(
            "pilot_rubric_invalid",
            "The exact rubric payload is invalid.",
            "question.rubric.payload",
        )

    mappings = _list(
        question.get("concept_mappings"), "question.concept_mappings", minimum=1, maximum=12
    )
    primary_count = 0
    seen_pairs: set[tuple[str, str]] = set()
    for index, raw in enumerate(mappings):
        field = f"question.concept_mappings[{index}]"
        mapping = _mapping(raw, field)
        concept_version_id = _uuid_text(
            mapping.get("concept_version_id"), f"{field}.concept_version_id"
        )
        known_objective = _CONCEPT_OBJECTIVE_IDS.get(UUID(concept_version_id))
        if known_objective is None:
            _fail(
                "pilot_mapping_unknown_concept",
                "Concept version is not part of the reviewed T08 seed.",
                f"{field}.concept_version_id",
            )
        learning_objective_id = _uuid_text(
            mapping.get("learning_objective_id"),
            f"{field}.learning_objective_id",
            allow_none=True,
        )
        if learning_objective_id is not None and UUID(learning_objective_id) != known_objective:
            _fail(
                "pilot_mapping_objective_mismatch",
                "Learning objective does not match the T08 concept's objective.",
                f"{field}.learning_objective_id",
            )
        role = mapping.get("mapping_role")
        if role not in {"primary", "supporting", "prerequisite", "misconception"}:
            _fail("pilot_mapping_invalid", "Invalid mapping role.", f"{field}.mapping_role")
        pair = (concept_version_id, str(role))
        if pair in seen_pairs:
            _fail(
                "pilot_mapping_invalid",
                "Concept mappings must be unique per concept and role.",
                "question.concept_mappings",
            )
        seen_pairs.add(pair)
        weight = _number(mapping.get("weight"), f"{field}.weight")
        if not 0 <= weight <= 1:
            _fail("pilot_mapping_invalid", "Mapping weight is out of bounds.", f"{field}.weight")
        if role == "primary":
            if weight <= 0:
                _fail(
                    "pilot_mapping_invalid",
                    "A primary mapping needs a positive weight.",
                    f"{field}.weight",
                )
            primary_count += 1
        provenance_type = mapping.get("provenance_type")
        if provenance_type not in PILOT_PROVENANCE_TYPES:
            _fail(
                "pilot_mapping_invalid",
                "Unsupported mapping provenance type.",
                f"{field}.provenance_type",
            )
        if status != "approved" and provenance_type not in PILOT_DRAFT_PROVENANCE_TYPES:
            _fail(
                "pilot_provenance_unreviewed",
                "Draft mappings may use only analyst_mapping or source_analysis provenance.",
                f"{field}.provenance_type",
            )
        if status == "approved" and provenance_type != "pilot_review":
            _fail(
                "pilot_provenance_not_reviewed",
                "Approved mappings must use pilot_review provenance.",
                f"{field}.provenance_type",
            )
        _text(mapping.get("provenance_ref"), f"{field}.provenance_ref", max_length=200)
    if approved and primary_count < 1:
        _fail(
            "pilot_mapping_invalid",
            "An approved pilot item requires at least one primary concept mapping.",
            "question.concept_mappings",
        )


def _validate_answer(
    answer: Mapping[str, Any],
    question: Mapping[str, Any],
    *,
    approved: bool,
) -> None:
    keys = _list(
        answer.get("derived_option_keys"), "answer_verification.derived_option_keys", minimum=1
    )
    derived = [_text(key, "answer_verification.derived_option_keys", max_length=16) for key in keys]
    if len(set(derived)) != len(derived):
        _fail(
            "pilot_answer_invalid",
            "Derived option keys must be unique.",
            "answer_verification.derived_option_keys",
        )
    options = question["options"]
    correct = sorted(
        str(option["option_key"])
        for option in options
        if isinstance(option, Mapping) and option.get("is_correct")
    )
    if sorted(derived) != correct:
        _fail(
            "pilot_answer_mismatch",
            "The derived answer must match the option marked correct.",
            "answer_verification.derived_option_keys",
        )
    _text(answer.get("derivation"), "answer_verification.derivation", max_length=5000)
    status = answer.get("independent_review_status")
    if status not in {"pending", "verified", "rejected"}:
        _fail(
            "pilot_answer_invalid",
            "Invalid independent review status.",
            "answer_verification.independent_review_status",
        )
    if approved and status != "verified":
        _fail(
            "pilot_answer_not_verified",
            "An approved item needs a verified derived answer.",
            "answer_verification.independent_review_status",
        )
    reviewer_ref = _text(
        answer.get("reviewer_ref"),
        "answer_verification.reviewer_ref",
        allow_none=True,
        max_length=300,
    )
    if status == "verified" and reviewer_ref is None:
        _fail(
            "pilot_answer_invalid",
            "A verified answer needs a reviewer reference.",
            "answer_verification.reviewer_ref",
        )
    if not approved and reviewer_ref is not None:
        _fail(
            "pilot_answer_invalid",
            "A draft answer must not carry a reviewer reference.",
            "answer_verification.reviewer_ref",
        )
    if (
        _bool(answer.get("official_key_claimed"), "answer_verification.official_key_claimed")
        is not False
    ):
        _fail(
            "pilot_official_key_unsupported",
            "The pilot does not support an official-key claim.",
            "answer_verification.official_key_claimed",
        )
    notes = answer.get("notes")
    if notes is not None and not isinstance(notes, str):
        _fail("pilot_answer_invalid", "Notes must be a string.", "answer_verification.notes")


def _validate_review(
    review: Mapping[str, Any],
    question: Mapping[str, Any],
    source: Mapping[str, Any],
    *,
    approved: bool,
    check_content_hash: bool,
    computed_hash: str,
) -> datetime | None:
    status = review.get("academic_review_status")
    if status not in {"pending", "approved", "rejected"}:
        _fail(
            "pilot_review_invalid",
            "Invalid academic review status.",
            "review.academic_review_status",
        )
    if approved and status != "approved":
        _fail(
            "pilot_review_not_approved",
            "An approved item needs an approved academic review.",
            "review.academic_review_status",
        )
    if not approved and status == "approved":
        _fail(
            "pilot_review_state_mismatch",
            "A draft cannot carry an approved review.",
            "review.academic_review_status",
        )
    if not approved and (
        review.get("reviewer_principal") is not None
        or review.get("reviewer_qualification_ref") is not None
        or review.get("reviewed_at") is not None
        or review.get("independence_declaration_ref") is not None
    ):
        _fail(
            "pilot_review_state_mismatch",
            "A draft must not carry review identity, qualification or a review date.",
            "review",
        )

    reviewer = _uuid_text(
        review.get("reviewer_principal"), "review.reviewer_principal", allow_none=True
    )
    question_reviewer = _uuid_text(
        question.get("reviewer_principal"), "question.reviewer_principal", allow_none=True
    )
    if reviewer is not None and question_reviewer is not None and reviewer != question_reviewer:
        _fail(
            "pilot_reviewer_mismatch",
            "The review reviewer must match the question reviewer.",
            "review.reviewer_principal",
        )
    if approved and reviewer is None:
        _fail(
            "pilot_reviewer_required",
            "An approved item needs a reviewer principal.",
            "review.reviewer_principal",
        )

    qualification = _text(
        review.get("reviewer_qualification_ref"),
        "review.reviewer_qualification_ref",
        allow_none=True,
        max_length=300,
    )
    if approved and qualification is None:
        _fail(
            "pilot_qualification_required",
            "An approved item needs reviewer qualification evidence.",
            "review.reviewer_qualification_ref",
        )

    scope = _list(review.get("review_scope"), "review.review_scope", minimum=0)
    scope_values = {_text(item, "review.review_scope", max_length=100) for item in scope}
    required_scope = (
        PILOT_PAST_PAPER_REVIEW_SCOPES
        if source["source_type"] == "past_paper"
        else PILOT_REVIEW_SCOPES
    )
    if approved and not required_scope.issubset(scope_values):
        missing = ", ".join(sorted(required_scope - scope_values))
        _fail(
            "pilot_review_scope_incomplete",
            f"Review scope is missing: {missing}.",
            "review.review_scope",
        )

    reviewed_at = review.get("reviewed_at")
    if approved and reviewed_at is None:
        _fail(
            "pilot_review_date_required",
            "An approved item needs a review date.",
            "review.reviewed_at",
        )
    reviewed_at_value = (
        _datetime_value(reviewed_at, "review.reviewed_at") if reviewed_at is not None else None
    )

    if review.get("ambiguity_status") not in {"pending", "cleared", "flagged"}:
        _fail("pilot_review_invalid", "Invalid ambiguity status.", "review.ambiguity_status")
    if approved and review.get("ambiguity_status") != "cleared":
        _fail(
            "pilot_ambiguity_not_cleared",
            "An approved item needs cleared ambiguity.",
            "review.ambiguity_status",
        )
    if review.get("duplicate_status") not in {"pending", "cleared", "duplicate"}:
        _fail("pilot_review_invalid", "Invalid duplicate status.", "review.duplicate_status")
    if approved and review.get("duplicate_status") != "cleared":
        _fail(
            "pilot_duplicate_not_cleared",
            "An approved item needs a cleared duplicate check.",
            "review.duplicate_status",
        )
    _text(review.get("coverage_note"), "review.coverage_note", max_length=1000)

    independence = _text(
        review.get("independence_declaration_ref"),
        "review.independence_declaration_ref",
        allow_none=True,
        max_length=300,
    )
    if approved and independence is None:
        _fail(
            "pilot_independence_required",
            "An approved item needs an independence declaration.",
            "review.independence_declaration_ref",
        )

    content_hash = _text(
        review.get("content_hash"), "review.content_hash", allow_none=True, pattern=_SHA256_PATTERN
    )
    if approved and check_content_hash and content_hash is None:
        _fail(
            "pilot_content_hash_required",
            "An approved item needs the reviewed content hash.",
            "review.content_hash",
        )
    if content_hash is not None and content_hash != computed_hash:
        _fail(
            "pilot_content_hash_mismatch",
            "The reviewed content hash does not match the current content.",
            "review.content_hash",
        )

    source_ref = _text(
        review.get("source_ref"), "review.source_ref", allow_none=True, max_length=500
    )
    expected_source_ref = source_reference(source)
    if approved and source_ref is None:
        _fail(
            "pilot_source_ref_required",
            "An approved item needs the reviewed source reference.",
            "review.source_ref",
        )
    if source_ref is not None and source_ref != expected_source_ref:
        _fail(
            "pilot_source_ref_mismatch",
            "The reviewed source reference does not match the source block.",
            "review.source_ref",
        )
    return reviewed_at_value


def _validate_publication(
    publication: Mapping[str, Any],
    *,
    approved: bool,
) -> datetime | None:
    approved_for_import = _bool(
        publication.get("approved_for_import"), "publication.approved_for_import"
    )
    if approved_for_import != approved:
        _fail(
            "pilot_publication_mismatch",
            "publication.approved_for_import must equal the question validation status.",
            "publication.approved_for_import",
        )
    approved_by = _text(
        publication.get("approved_by"), "publication.approved_by", allow_none=True, max_length=300
    )
    approved_at = publication.get("approved_at")
    import_batch = _text(
        publication.get("import_batch_id"),
        "publication.import_batch_id",
        allow_none=True,
        max_length=200,
    )
    if not approved_for_import:
        if approved_by is not None or approved_at is not None:
            _fail(
                "pilot_publication_mismatch",
                "A draft must not carry approval metadata.",
                "publication.approved_by",
            )
        if import_batch is not None:
            _fail(
                "pilot_publication_mismatch",
                "A draft must not carry an import batch.",
                "publication.import_batch_id",
            )
        return None
    if approved_by is None:
        _fail(
            "pilot_approval_required",
            "An approved item needs an approval record reference.",
            "publication.approved_by",
        )
    if approved_at is None:
        _fail(
            "pilot_approval_date_required",
            "An approved item needs an approval date.",
            "publication.approved_at",
        )
    return _datetime_value(approved_at, "publication.approved_at")


def _build_bundle(envelope: Mapping[str, Any], *, for_hash: bool) -> QuestionImportBundle:
    question = dict(_mapping(envelope.get("question"), "question"))
    question.pop("target_source_class", None)
    question.pop("author_qualification_ref", None)
    if question.get("source_class") is None:
        question["source_class"] = PILOT_TARGET_SOURCE_CLASS
    if for_hash:
        question["validation_status"] = "draft"
    return QuestionImportBundle.model_validate(question)


def compute_pilot_content_hash(envelope: Mapping[str, Any]) -> str:
    """Compute the T12 canonical hash for the current envelope content.

    Call this only after the prompt, options, explanation, rubric status and
    mappings are final. The hash is computed with the target source class so it
    matches the eventual T12 import.
    """

    validate_pilot_envelope(envelope, check_content_hash=False)
    validated = validate_question_import(_build_bundle(envelope, for_hash=True))
    return validated.content_hash


def validate_pilot_envelope(
    envelope: Mapping[str, Any],
    *,
    require_approved: bool = False,
    check_content_hash: bool = True,
) -> dict[str, Any]:
    """Validate a pilot envelope and return a shallow copy.

    Drafts are valid only when ``source_class`` is null, the review and answer
    are pending, and ``publication.approved_for_import`` is false. Approved
    envelopes must satisfy every gate. The function does not contact a database
    and does not prove that an author identity, a reviewer identity or either
    qualification record exists.
    """

    envelope = _mapping(envelope, "envelope")
    if envelope.get("schema_version") != PILOT_SCHEMA_VERSION:
        _fail("pilot_schema_version", "Unsupported pilot schema version.", "schema_version")
    _text(envelope.get("pilot_id"), "pilot_id", pattern=_PILOT_ID_PATTERN, max_length=40)

    source = _mapping(envelope.get("source"), "source")
    question = _mapping(envelope.get("question"), "question")
    answer = _mapping(envelope.get("answer_verification"), "answer_verification")
    review = _mapping(envelope.get("review"), "review")
    publication = _mapping(envelope.get("publication"), "publication")

    status = question.get("validation_status")
    approved = status == "approved"
    if require_approved and not approved:
        _fail(
            "pilot_approval_required",
            "This operation requires an approved envelope.",
            "question.validation_status",
        )

    _validate_source(source, approved=approved)
    _validate_question(question, approved=approved)
    _validate_answer(answer, question, approved=approved)
    validated = validate_question_import(_build_bundle(envelope, for_hash=True))
    reviewed_at = _validate_review(
        review,
        question,
        source,
        approved=approved,
        check_content_hash=check_content_hash,
        computed_hash=validated.content_hash,
    )
    approved_at = _validate_publication(publication, approved=approved)
    if (
        approved
        and reviewed_at is not None
        and approved_at is not None
        and approved_at < reviewed_at
    ):
        _fail(
            "pilot_approval_before_review",
            "The approval date cannot precede the review date.",
            "publication.approved_at",
        )
    return dict(envelope)


def to_validated_import(envelope: Mapping[str, Any]) -> ValidatedQuestionImport:
    """Convert an approved envelope to a validated T12 import.

    This is the only supported bridge to T12. It refuses drafts and refuses an
    approved envelope whose content hash or source reference is missing or
    stale. It does not write to a database; callers remain responsible for the
    privileged import and its PostgreSQL tests.
    """

    validate_pilot_envelope(envelope, require_approved=True)
    bundle = _build_bundle(envelope, for_hash=False)
    validated = validate_question_import(bundle)
    review = _mapping(envelope.get("review"), "review")
    if review.get("content_hash") != validated.content_hash:
        _fail(
            "pilot_content_hash_mismatch",
            "The reviewed content hash does not match the validated import.",
            "review.content_hash",
        )
    return validated
