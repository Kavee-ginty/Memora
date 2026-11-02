"""Sealed-envelope validation for the T24 Physics pilot.

The pilot supports two verification modes:

* ``official_marking_scheme`` - the printed Department of Examinations answer
  grid is the verification authority. No teacher, reviewer or verifier identity
  is required. The envelope records null human principals and an explicit
  deviation reference. This mode is pilot-only and is not importable through
  the T12 path, which still requires author and reviewer principals.
* ``expert_review`` - the original T12-style path with an author and reviewer,
  qualification references and an independence declaration. The answer review is
  either an independent review (distinct principals, status ``verified``) or an
  explicit self-review (same principal, status ``self_review``). A self-review
  never claims independence.

The JSON Schema is the structural contract. This module and the T08 seed data
are the semantic authorities. The source PDFs are gitignored; hashes identify
the local copies and do not prove publication or reproduction rights.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
from collections.abc import Mapping, Sequence
from datetime import datetime
from pathlib import Path
from typing import Any
from uuid import UUID

from memora.modules.curriculum.seed_data import CONCEPTS_DATA, LEARNING_OBJECTIVES
from memora.modules.questions.models import (
    ConceptMappingImport,
    QuestionImportBundle,
    QuestionOptionImport,
    RubricImport,
    ValidatedQuestionImport,
)
from memora.modules.questions.validation import validate_question_import

PILOT_SCHEMA_VERSION = "2.0"
PILOT_VERIFICATION_MODES = frozenset({"official_marking_scheme", "expert_review"})
PILOT_SOURCE_TYPES = frozenset({"past_paper", "synthetic"})
PILOT_SOURCE_CLASS = "expert_verified"
PILOT_SUBJECT_ID = UUID("10000000-0000-0000-0000-000000000001")
PILOT_CURRICULUM_ID = UUID("20000000-0000-0000-0000-000000000001")
PILOT_REVIEW_SCOPES = frozenset(
    {
        "official_key_match",
        "derivation",
        "transcription",
        "curriculum_mapping",
        "ambiguity",
        "duplicate",
    }
)
PILOT_OFFICIAL_SCOPES = frozenset(
    {
        "official_key_match",
        "derivation",
        "transcription",
        "curriculum_mapping",
        "ambiguity",
        "duplicate",
    }
)
PILOT_EXPERT_SCOPES = frozenset(
    {"derivation", "transcription", "curriculum_mapping", "ambiguity", "duplicate"}
)
PILOT_OFFICIAL_PROVENANCE = frozenset({"analyst_mapping", "source_analysis"})
PILOT_EXPERT_PROVENANCE = frozenset({"pilot_review"})
PILOT_IMPORT_BLOCKED_STATUS = "blocked_pending_t12_verification_mode"
PILOT_DEVIATION_REF = "content/physics/pilot/DEVIATION_REVIEW_MODE.md"

_PILOT_ID_PATTERN = re.compile(r"^PILOT-PHYS-([0-9]{4})-P1-Q([0-9]{1,2})$")
_QUESTION_CODE_PATTERN = re.compile(r"^[a-z0-9][a-z0-9._-]*$")
_OPTION_KEY_PATTERN = re.compile(r"^[a-z0-9][a-z0-9_-]*$")
_SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")
_SOURCE_ID_PATTERN = re.compile(r"^SL-DOE-AL-PHYS-([0-9]{4})-P1$")
_SYNTHETIC_SOURCE_PATTERN = re.compile(r"^SYNTHETIC-[A-Z0-9-]+$")

_OBJECTIVES_BY_CODE = {
    str(objective["objective_code"]): objective for objective in LEARNING_OBJECTIVES
}
_OBJECTIVES_BY_ID = {str(objective["id"]): objective for objective in LEARNING_OBJECTIVES}
_CONCEPTS_BY_VERSION = {str(concept["version_id"]): concept for concept in CONCEPTS_DATA}
_CONCEPT_OBJECTIVE_IDS = {
    str(concept["version_id"]): str(_OBJECTIVES_BY_CODE[str(concept["objective_code"])]["id"])
    for concept in CONCEPTS_DATA
}

_TOP_LEVEL_KEYS = (
    "schema_version",
    "pilot_id",
    "verification_mode",
    "source",
    "question",
    "answer_verification",
    "review",
    "publication",
)
_HASHED_KEYS = (
    "schema_version",
    "pilot_id",
    "verification_mode",
    "source",
    "question",
    "answer_verification",
)
_SOURCE_KEYS = (
    "source_id",
    "source_type",
    "document_filename",
    "document_sha256",
    "exam_year",
    "exam_label",
    "paper",
    "question_number",
    "pdf_page",
    "medium",
    "marking_scheme_document",
    "marking_scheme_sha256",
    "marking_scheme_pdf_page",
    "official_key",
    "official_key_status",
    "transcription_status",
    "text_only_adaptation",
    "transcription_note",
    "reproduction_status",
    "licence_note",
)
_QUESTION_KEYS = (
    "question_code",
    "subject_id",
    "curriculum_version_id",
    "source_class",
    "target_source_class",
    "question_type",
    "prompt",
    "explanation",
    "validation_status",
    "author_principal",
    "author_qualification_ref",
    "reviewer_principal",
    "content",
    "options",
    "rubric",
    "concept_mappings",
)
_OPTION_KEYS = ("option_key", "display_text", "is_correct", "display_order")
_RUBRIC_KEYS = ("rubric_type", "max_score", "evidence_ceiling", "status", "payload")
_RUBRIC_PAYLOAD_KEYS = ("kind", "schema_version")
_MAPPING_KEYS = (
    "concept_version_id",
    "learning_objective_id",
    "mapping_role",
    "weight",
    "provenance_type",
    "provenance_ref",
)
_ANSWER_KEYS = (
    "mode",
    "official_key",
    "derived_option_key",
    "matches_official_key",
    "derivation",
    "official_key_source_ref",
    "independent_review_status",
    "reviewer_ref",
    "notes",
)
_REVIEW_KEYS = (
    "review_mode",
    "academic_review_status",
    "reviewer_principal",
    "reviewer_qualification_ref",
    "review_scope",
    "reviewed_at",
    "ambiguity_status",
    "ambiguity_note",
    "duplicate_status",
    "coverage_note",
    "content_hash",
    "source_ref",
    "independence_declaration_ref",
    "deviation_ref",
)
_PUBLICATION_KEYS = (
    "approved_for_import",
    "approved_by",
    "approved_at",
    "import_batch_id",
    "import_status",
    "blocker_ref",
)


class PilotEnvelopeError(ValueError):
    """A pilot envelope failed a structural or semantic gate."""

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


def _object(
    value: Any,
    field: str,
    required: Sequence[str],
) -> Mapping[str, Any]:
    data = _mapping(value, field)
    required_set = set(required)
    missing = sorted(required_set - set(data))
    extra = sorted(set(data) - required_set)
    if missing:
        _fail(
            "pilot_envelope_invalid",
            f"Missing required fields: {', '.join(missing)}.",
            field,
        )
    if extra:
        _fail(
            "pilot_envelope_invalid",
            f"Unexpected fields: {', '.join(extra)}.",
            field,
        )
    return data


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


def _optional_text(value: Any, field: str, *, max_length: int = 500) -> str | None:
    return _text(value, field, allow_none=True, max_length=max_length)


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
        _fail("pilot_envelope_invalid", "Value is below the minimum.", field)
    if maximum is not None and value > maximum:
        _fail("pilot_envelope_invalid", "Value is above the maximum.", field)
    return value


def _number(
    value: Any,
    field: str,
    *,
    minimum: float | None = None,
    maximum: float | None = None,
    exclusive_minimum: float | None = None,
) -> float:
    if not isinstance(value, (int, float)) or isinstance(value, bool):
        _fail("pilot_envelope_invalid", "Expected a number.", field)
    number = float(value)
    if minimum is not None and number < minimum:
        _fail("pilot_envelope_invalid", "Value is below the minimum.", field)
    if exclusive_minimum is not None and number <= exclusive_minimum:
        _fail("pilot_envelope_invalid", "Value must be greater than the minimum.", field)
    if maximum is not None and number > maximum:
        _fail("pilot_envelope_invalid", "Value is above the maximum.", field)
    return number


def _list(value: Any, field: str, *, minimum: int = 1, maximum: int = 50) -> list[Any]:
    if not isinstance(value, list):
        _fail("pilot_envelope_invalid", "Expected a list.", field)
    if not minimum <= len(value) <= maximum:
        _fail(
            "pilot_envelope_invalid",
            f"Expected between {minimum} and {maximum} items.",
            field,
        )
    return value


def _enum(value: Any, field: str, allowed: frozenset[str] | set[str] | tuple[str, ...]) -> str:
    if not isinstance(value, str) or value not in allowed:
        _fail("pilot_envelope_invalid", "Value is not an allowed option.", field)
    return value


def _date_time(value: Any, field: str) -> datetime:
    text = _text(value, field)
    try:
        parsed = datetime.fromisoformat(str(text).replace("Z", "+00:00"))
    except ValueError:
        _fail("pilot_envelope_invalid", "Expected an ISO-8601 date-time.", field)
    if parsed.tzinfo is None:
        _fail("pilot_envelope_invalid", "Expected a timezone-aware date-time.", field)
    return parsed


def _validate_source(
    source: Any, *, mode: str, pilot_year: int, pilot_question: int
) -> dict[str, Any]:
    data = dict(_object(source, "source", _SOURCE_KEYS))
    source_id = str(_text(data["source_id"], "source.source_id", max_length=200))
    source_type = _enum(data["source_type"], "source.source_type", PILOT_SOURCE_TYPES)

    if mode == "official_marking_scheme" and source_type != "past_paper":
        _fail(
            "pilot_source_mode_mismatch",
            "Official marking-scheme verification requires a past-paper source.",
            "source.source_type",
        )

    match = _SOURCE_ID_PATTERN.fullmatch(source_id)
    if source_type == "past_paper":
        if match is None:
            _fail(
                "pilot_source_id_invalid",
                "A past-paper source id must identify the SL-DOE Physics Paper I year.",
                "source.source_id",
            )
        source_year = int(match.group(1))
        if source_year != pilot_year:
            _fail(
                "pilot_source_year_mismatch",
                "The source id year does not match the pilot id year.",
                "source.source_id",
            )
        _text(data["document_filename"], "source.document_filename", max_length=300)
        document_hash = str(_text(data["document_sha256"], "source.document_sha256"))
        if _SHA256_PATTERN.fullmatch(document_hash) is None:
            _fail(
                "pilot_source_hash_invalid",
                "The source document hash must be a SHA-256 hex digest.",
                "source.document_sha256",
            )
        exam_year = _int(data["exam_year"], "source.exam_year", minimum=2017, maximum=2025)
        if exam_year != source_year:
            _fail(
                "pilot_source_year_mismatch",
                "The exam year does not match the source id.",
                "source.exam_year",
            )
        if data["paper"] != "Paper I":
            _fail("pilot_source_paper_invalid", "Only Paper I is in scope.", "source.paper")
        paper_question = _int(
            data["question_number"], "source.question_number", minimum=1, maximum=50
        )
        if paper_question != pilot_question:
            _fail(
                "pilot_source_question_mismatch",
                "The source question number does not match the pilot id.",
                "source.question_number",
            )
        _int(data["pdf_page"], "source.pdf_page", minimum=1)
        _text(data["marking_scheme_document"], "source.marking_scheme_document", max_length=300)
        scheme_hash = str(_text(data["marking_scheme_sha256"], "source.marking_scheme_sha256"))
        if _SHA256_PATTERN.fullmatch(scheme_hash) is None:
            _fail(
                "pilot_source_hash_invalid",
                "The marking-scheme hash must be a SHA-256 hex digest.",
                "source.marking_scheme_sha256",
            )
        _int(data["marking_scheme_pdf_page"], "source.marking_scheme_pdf_page", minimum=1)
        official_key = _int(data["official_key"], "source.official_key", minimum=1, maximum=5)
        _enum(
            data["official_key_status"],
            "source.official_key_status",
            frozenset(
                {
                    "verified_against_marking_scheme",
                    "not_found",
                    "not_published",
                    "marking_scheme_not_mcq_key",
                    "unknown",
                    "not_applicable",
                }
            ),
        )
        _enum(
            data["transcription_status"],
            "source.transcription_status",
            frozenset({"verified_visual", "unverified", "not_applicable"}),
        )
        if mode == "official_marking_scheme":
            if data["official_key_status"] != "verified_against_marking_scheme":
                _fail(
                    "pilot_official_key_not_verified",
                    "Official marking-scheme mode needs a verified answer-grid entry.",
                    "source.official_key_status",
                )
            if data["transcription_status"] != "verified_visual":
                _fail(
                    "pilot_transcription_not_verified",
                    "Official marking-scheme mode needs a visually verified transcription.",
                    "source.transcription_status",
                )
        data["_validated_official_key"] = official_key
    else:
        if match is not None or _SYNTHETIC_SOURCE_PATTERN.fullmatch(source_id) is None:
            _fail(
                "pilot_source_id_invalid",
                "A synthetic source id must use the SYNTHETIC- prefix.",
                "source.source_id",
            )
        if data["official_key"] is not None:
            _fail(
                "pilot_source_key_invalid",
                "A synthetic source must not claim an official key.",
                "source.official_key",
            )

    if data["medium"] != "English":
        _fail("pilot_medium_invalid", "The pilot is English-medium only.", "source.medium")
    _text(data["exam_label"], "source.exam_label", max_length=40)
    _bool(data["text_only_adaptation"], "source.text_only_adaptation")
    _optional_text(data["transcription_note"], "source.transcription_note", max_length=1000)
    _enum(
        data["reproduction_status"],
        "source.reproduction_status",
        frozenset({"unapproved", "approved", "not_applicable"}),
    )
    _text(data["licence_note"], "source.licence_note", max_length=1000)
    return data


def _validate_options(value: Any, *, mode: str) -> list[dict[str, Any]]:
    options = _list(value, "question.options", minimum=2, maximum=10)
    if mode == "official_marking_scheme" and len(options) != 5:
        _fail(
            "pilot_options_invalid",
            "A Paper I MCQ must have exactly five options.",
            "question.options",
        )
    keys: list[str] = []
    texts: list[str] = []
    orders: list[int] = []
    correct: list[str] = []
    checked: list[dict[str, Any]] = []
    for index, option in enumerate(options):
        field = f"question.options[{index}]"
        item = dict(_object(option, field, _OPTION_KEYS))
        key = str(_text(item["option_key"], f"{field}.option_key", pattern=_OPTION_KEY_PATTERN))
        text = str(_text(item["display_text"], f"{field}.display_text", max_length=1000))
        is_correct = _bool(item["is_correct"], f"{field}.is_correct")
        order = _int(item["display_order"], f"{field}.display_order", minimum=0, maximum=9)
        keys.append(key)
        texts.append(text)
        orders.append(order)
        if is_correct:
            correct.append(key)
        checked.append(item)
    if len(set(keys)) != len(keys):
        _fail("pilot_options_invalid", "Option keys must be unique.", "question.options")
    if len(set(texts)) != len(texts):
        _fail("pilot_options_invalid", "Option text must be unique.", "question.options")
    if sorted(orders) != list(range(len(options))):
        _fail(
            "pilot_options_invalid",
            "Display order must be a contiguous zero-based sequence.",
            "question.options",
        )
    if len(correct) != 1:
        _fail(
            "pilot_answer_invalid",
            "Exactly one option must be marked correct.",
            "question.options",
        )
    return checked


def _validate_rubric(value: Any) -> dict[str, Any]:
    data = dict(_object(value, "question.rubric", _RUBRIC_KEYS))
    if data["rubric_type"] != "exact":
        _fail("pilot_rubric_invalid", "The pilot uses exact MCQ grading.", "question.rubric")
    if data["max_score"] != 1:
        _fail("pilot_rubric_invalid", "The pilot uses max_score = 1.", "question.rubric.max_score")
    _number(
        data["evidence_ceiling"],
        "question.rubric.evidence_ceiling",
        exclusive_minimum=0,
        maximum=1,
    )
    if data["status"] != "approved":
        _fail("pilot_rubric_invalid", "The rubric must be approved.", "question.rubric.status")
    payload = _object(data["payload"], "question.rubric.payload", _RUBRIC_PAYLOAD_KEYS)
    if payload["kind"] != "exact" or payload["schema_version"] != "1":
        _fail("pilot_rubric_invalid", "The rubric payload is invalid.", "question.rubric.payload")
    return data


def _validate_mappings(value: Any, *, mode: str) -> list[dict[str, Any]]:
    mappings = _list(value, "question.concept_mappings", minimum=1, maximum=12)
    allowed_provenance = (
        PILOT_OFFICIAL_PROVENANCE if mode == "official_marking_scheme" else PILOT_EXPERT_PROVENANCE
    )
    pairs: set[tuple[str, str]] = set()
    primary = 0
    checked: list[dict[str, Any]] = []
    for index, mapping in enumerate(mappings):
        field = f"question.concept_mappings[{index}]"
        item = dict(_object(mapping, field, _MAPPING_KEYS))
        concept_version_id = str(
            _uuid_text(item["concept_version_id"], f"{field}.concept_version_id")
        )
        concept = _CONCEPTS_BY_VERSION.get(concept_version_id)
        if concept is None:
            _fail(
                "pilot_mapping_unknown_concept",
                "The mapped concept is not in the T08 seed.",
                f"{field}.concept_version_id",
            )
        objective_id = str(
            _uuid_text(item["learning_objective_id"], f"{field}.learning_objective_id")
        )
        expected_objective = _CONCEPT_OBJECTIVE_IDS[concept_version_id]
        if objective_id != expected_objective:
            _fail(
                "pilot_mapping_objective_mismatch",
                "The objective does not own the mapped T08 concept.",
                f"{field}.learning_objective_id",
            )
        role = _enum(
            item["mapping_role"],
            f"{field}.mapping_role",
            frozenset({"primary", "supporting", "prerequisite", "misconception"}),
        )
        weight = _number(item["weight"], f"{field}.weight", minimum=0, maximum=1)
        if role == "primary" and weight <= 0:
            _fail(
                "pilot_mapping_invalid",
                "A primary concept mapping needs a positive weight.",
                f"{field}.weight",
            )
        _enum(item["provenance_type"], f"{field}.provenance_type", allowed_provenance)
        _text(item["provenance_ref"], f"{field}.provenance_ref", max_length=200)
        pair = (concept_version_id, role)
        if pair in pairs:
            _fail(
                "pilot_mapping_invalid",
                "Concept mappings must be unique per concept and role.",
                "question.concept_mappings",
            )
        pairs.add(pair)
        if role == "primary":
            primary += 1
    if primary != 1:
        _fail(
            "pilot_mapping_invalid",
            "Each question needs exactly one primary concept mapping.",
            "question.concept_mappings",
        )
    return checked


def _validate_question(question: Any, *, mode: str) -> dict[str, Any]:
    data = dict(_object(question, "question", _QUESTION_KEYS))
    _text(
        data["question_code"],
        "question.question_code",
        pattern=_QUESTION_CODE_PATTERN,
        max_length=100,
    )
    subject_id = _uuid_text(data["subject_id"], "question.subject_id")
    if subject_id != str(PILOT_SUBJECT_ID):
        _fail(
            "pilot_subject_invalid",
            "The subject is not the seeded Physics subject.",
            "question.subject_id",
        )
    curriculum_id = _uuid_text(data["curriculum_version_id"], "question.curriculum_version_id")
    if curriculum_id != str(PILOT_CURRICULUM_ID):
        _fail(
            "pilot_curriculum_invalid",
            "The curriculum is not the seeded 2017 Physics curriculum.",
            "question.curriculum_version_id",
        )
    if data["source_class"] != PILOT_SOURCE_CLASS:
        _fail(
            "pilot_source_class_invalid",
            "source_class must be expert_verified.",
            "question.source_class",
        )
    if data["target_source_class"] != PILOT_SOURCE_CLASS:
        _fail(
            "pilot_source_class_invalid",
            "target_source_class must be expert_verified.",
            "question.target_source_class",
        )
    if data["question_type"] != "mcq":
        _fail(
            "pilot_question_type_invalid", "The pilot contains MCQs only.", "question.question_type"
        )
    if data["validation_status"] != "approved":
        _fail(
            "pilot_validation_status_invalid",
            "A sealed pilot envelope must be approved.",
            "question.validation_status",
        )
    _text(data["prompt"], "question.prompt", max_length=5000)
    _text(data["explanation"], "question.explanation", max_length=5000)

    content = _object(
        data["content"],
        "question.content",
        ("kind", "schema_version", "selection_mode"),
    )
    if content["kind"] != "choice" or content["schema_version"] != "1":
        _fail(
            "pilot_content_invalid", "The question content must be choice v1.", "question.content"
        )
    if content["selection_mode"] != "single":
        _fail("pilot_content_invalid", "The pilot uses single selection.", "question.content")

    _validate_options(data["options"], mode=mode)
    _validate_rubric(data["rubric"])
    _validate_mappings(data["concept_mappings"], mode=mode)

    author = _uuid_text(data["author_principal"], "question.author_principal", allow_none=True)
    reviewer = _uuid_text(
        data["reviewer_principal"], "question.reviewer_principal", allow_none=True
    )
    qualification = _optional_text(
        data["author_qualification_ref"], "question.author_qualification_ref", max_length=300
    )
    if mode == "official_marking_scheme":
        if author is not None or reviewer is not None or qualification is not None:
            _fail(
                "pilot_reviewer_not_allowed",
                "Official marking-scheme mode does not carry human author or reviewer identities.",
                "question",
            )
    else:
        if author is None or reviewer is None or qualification is None:
            _fail(
                "pilot_reviewer_required",
                "Expert-review mode needs author and reviewer principals and a "
                "qualification reference.",
                "question",
            )
    data["_validated_author"] = author
    data["_validated_reviewer"] = reviewer
    return data


def _validate_answer(
    answer: Any,
    *,
    source: Mapping[str, Any],
    question: Mapping[str, Any],
    mode: str,
) -> dict[str, Any]:
    data = dict(_object(answer, "answer_verification", _ANSWER_KEYS))
    if data["mode"] != mode:
        _fail(
            "pilot_mode_mismatch",
            "answer_verification.mode must match verification_mode.",
            "answer_verification.mode",
        )
    official_key = _int(
        data["official_key"], "answer_verification.official_key", minimum=1, maximum=5
    )
    source_key = source.get("_validated_official_key")
    if source_key is None or official_key != source_key:
        _fail(
            "pilot_official_key_mismatch",
            "The answer verification key does not match the source key.",
            "answer_verification.official_key",
        )
    derived_key = str(
        _text(
            data["derived_option_key"],
            "answer_verification.derived_option_key",
            pattern=_OPTION_KEY_PATTERN,
            max_length=16,
        )
    )
    if derived_key != str(official_key):
        _fail(
            "pilot_official_key_mismatch",
            "The derived option key must equal the official key.",
            "answer_verification.derived_option_key",
        )
    options = question["options"]
    derived_option = next(
        (option for option in options if option["option_key"] == derived_key), None
    )
    if derived_option is None or not derived_option["is_correct"]:
        _fail(
            "pilot_answer_invalid",
            "The derived option must exist and be marked correct.",
            "answer_verification.derived_option_key",
        )
    if data["matches_official_key"] is not True:
        _fail(
            "pilot_official_key_mismatch",
            "The envelope must record a match with the official key.",
            "answer_verification.matches_official_key",
        )
    _text(data["derivation"], "answer_verification.derivation", max_length=5000)
    _text(
        data["official_key_source_ref"],
        "answer_verification.official_key_source_ref",
        max_length=500,
    )
    status = _enum(
        data["independent_review_status"],
        "answer_verification.independent_review_status",
        frozenset({"not_required", "pending", "verified", "rejected", "self_review"}),
    )
    reviewer_ref = _optional_text(
        data["reviewer_ref"], "answer_verification.reviewer_ref", max_length=300
    )
    if mode == "official_marking_scheme":
        if status != "not_required" or reviewer_ref is not None:
            _fail(
                "pilot_reviewer_not_allowed",
                "Official marking-scheme mode does not require independent human review.",
                "answer_verification.independent_review_status",
            )
    else:
        if status not in {"verified", "self_review"} or reviewer_ref is None:
            _fail(
                "pilot_answer_review_required",
                "Expert-review mode needs a verified or self-review answer review.",
                "answer_verification.independent_review_status",
            )
        author = question.get("_validated_author")
        reviewer = question.get("_validated_reviewer")
        if status == "verified" and author == reviewer:
            _fail(
                "pilot_independence_claim_invalid",
                "An independent answer review needs distinct author and reviewer principals.",
                "answer_verification.independent_review_status",
            )
        if status == "self_review" and author != reviewer:
            _fail(
                "pilot_self_review_mismatch",
                "A self-review needs the same author and reviewer principal.",
                "answer_verification.independent_review_status",
            )
    _optional_text(data["notes"], "answer_verification.notes", max_length=2000)
    return data


def _validate_review(
    review: Any,
    *,
    question: Mapping[str, Any],
    mode: str,
    computed_hash: str,
    check_content_hash: bool,
) -> dict[str, Any]:
    data = dict(_object(review, "review", _REVIEW_KEYS))
    if data["review_mode"] != mode:
        _fail(
            "pilot_mode_mismatch",
            "review.review_mode must match verification_mode.",
            "review.review_mode",
        )
    academic_status = _enum(
        data["academic_review_status"],
        "review.academic_review_status",
        frozenset({"not_required", "pending", "approved", "rejected"}),
    )
    reviewer = _uuid_text(data["reviewer_principal"], "review.reviewer_principal", allow_none=True)
    qualification = _optional_text(
        data["reviewer_qualification_ref"], "review.reviewer_qualification_ref", max_length=300
    )
    scopes = _list(data["review_scope"], "review.review_scope", minimum=1, maximum=10)
    checked_scopes: list[str] = []
    for index, scope in enumerate(scopes):
        checked_scopes.append(_enum(scope, f"review.review_scope[{index}]", PILOT_REVIEW_SCOPES))
    if len(set(checked_scopes)) != len(checked_scopes):
        _fail("pilot_review_scope_invalid", "Review scopes must be unique.", "review.review_scope")
    required_scopes = (
        PILOT_OFFICIAL_SCOPES if mode == "official_marking_scheme" else PILOT_EXPERT_SCOPES
    )
    missing_scopes = sorted(required_scopes - set(checked_scopes))
    if missing_scopes:
        _fail(
            "pilot_review_scope_invalid",
            f"Missing review scopes: {', '.join(missing_scopes)}.",
            "review.review_scope",
        )
    _date_time(data["reviewed_at"], "review.reviewed_at")
    ambiguity_status = _enum(
        data["ambiguity_status"],
        "review.ambiguity_status",
        frozenset({"cleared", "flagged", "pending"}),
    )
    _optional_text(data["ambiguity_note"], "review.ambiguity_note", max_length=1000)
    duplicate_status = _enum(
        data["duplicate_status"],
        "review.duplicate_status",
        frozenset({"cleared", "duplicate", "pending"}),
    )
    coverage_note = str(_text(data["coverage_note"], "review.coverage_note", max_length=1000))
    content_hash = str(_text(data["content_hash"], "review.content_hash", pattern=_SHA256_PATTERN))
    if check_content_hash and content_hash != computed_hash:
        _fail(
            "pilot_content_hash_mismatch",
            "The sealed content hash does not match the current content.",
            "review.content_hash",
        )
    _text(data["source_ref"], "review.source_ref", max_length=500)
    independence = _optional_text(
        data["independence_declaration_ref"],
        "review.independence_declaration_ref",
        max_length=300,
    )
    deviation_ref = _optional_text(data["deviation_ref"], "review.deviation_ref", max_length=300)

    if mode == "official_marking_scheme":
        if academic_status != "not_required":
            _fail(
                "pilot_reviewer_not_allowed",
                "Official marking-scheme mode has no academic reviewer.",
                "review.academic_review_status",
            )
        if reviewer is not None or qualification is not None or independence is not None:
            _fail(
                "pilot_reviewer_not_allowed",
                "Official marking-scheme mode does not carry reviewer identity evidence.",
                "review",
            )
        if deviation_ref is None:
            _fail(
                "pilot_deviation_required",
                "Official marking-scheme mode must reference the recorded pilot deviation.",
                "review.deviation_ref",
            )
    else:
        if academic_status != "approved":
            _fail(
                "pilot_review_required",
                "Expert-review mode needs an approved academic review.",
                "review.academic_review_status",
            )
        if reviewer is None or qualification is None or independence is None:
            _fail(
                "pilot_review_required",
                "Expert-review mode needs reviewer identity, qualification and "
                "independence evidence.",
                "review",
            )
        if reviewer != question.get("_validated_reviewer"):
            _fail(
                "pilot_reviewer_mismatch",
                "The review reviewer must match the question reviewer.",
                "review.reviewer_principal",
            )
    if ambiguity_status != "cleared":
        _fail(
            "pilot_ambiguity_open",
            "A sealed pilot item needs a cleared ambiguity status.",
            "review.ambiguity_status",
        )
    if duplicate_status != "cleared":
        _fail(
            "pilot_duplicate_open",
            "A sealed pilot item needs a cleared duplicate status.",
            "review.duplicate_status",
        )
    if not coverage_note.strip():
        _fail("pilot_coverage_note_missing", "A coverage note is required.", "review.coverage_note")
    return data


def _validate_publication(publication: Any, *, mode: str) -> dict[str, Any]:
    data = dict(_object(publication, "publication", _PUBLICATION_KEYS))
    approved = _bool(data["approved_for_import"], "publication.approved_for_import")
    approved_by = _optional_text(data["approved_by"], "publication.approved_by", max_length=300)
    approved_at = data["approved_at"]
    if approved_at is not None:
        _date_time(approved_at, "publication.approved_at")
    import_batch = _optional_text(
        data["import_batch_id"], "publication.import_batch_id", max_length=200
    )
    status = _enum(
        data["import_status"],
        "publication.import_status",
        frozenset({"not_requested", "blocked_pending_t12_verification_mode", "ready_for_import"}),
    )
    blocker_ref = _optional_text(data["blocker_ref"], "publication.blocker_ref", max_length=300)

    if mode == "official_marking_scheme":
        if approved:
            _fail(
                "pilot_import_blocked",
                "Official marking-scheme content cannot be imported until T12 supports this mode.",
                "publication.approved_for_import",
            )
        if approved_by is not None or approved_at is not None or import_batch is not None:
            _fail(
                "pilot_import_blocked",
                "A blocked official marking-scheme item cannot carry import approval fields.",
                "publication",
            )
        if status != PILOT_IMPORT_BLOCKED_STATUS or blocker_ref is None:
            _fail(
                "pilot_import_blocked",
                "Official marking-scheme content must record the T12 import blocker.",
                "publication.import_status",
            )
    else:
        if approved:
            if approved_by is None or approved_at is None or import_batch is None:
                _fail(
                    "pilot_import_incomplete",
                    "An approved import needs approval and batch evidence.",
                    "publication",
                )
            if status != "ready_for_import":
                _fail(
                    "pilot_import_incomplete",
                    "An approved import needs ready_for_import status.",
                    "publication.import_status",
                )
        elif status == "ready_for_import":
            _fail(
                "pilot_import_incomplete",
                "ready_for_import requires approved_for_import.",
                "publication.import_status",
            )
    return data


def compute_pilot_content_hash(envelope: Mapping[str, Any]) -> str:
    """Return the canonical SHA-256 hash of the sealed content.

    The review hash and publication state are intentionally excluded. The hash
    binds the schema version, pilot id, verification mode, source claim,
    question payload and answer verification.
    """

    payload = {key: envelope[key] for key in _HASHED_KEYS if key in envelope}
    canonical = json.dumps(
        payload,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def validate_pilot_envelope(
    envelope: Mapping[str, Any],
    *,
    require_approved: bool = True,
    check_content_hash: bool = True,
) -> dict[str, Any]:
    """Validate one pilot envelope and return a deep copy.

    ``require_approved`` is kept for callers that validate work in progress.
    The v2 schema itself only describes sealed, approved envelopes.
    """

    data = _mapping(envelope, "envelope")
    missing = sorted(set(_TOP_LEVEL_KEYS) - set(data))
    extra = sorted(set(data) - set(_TOP_LEVEL_KEYS))
    if missing:
        _fail(
            "pilot_envelope_invalid",
            f"Missing required fields: {', '.join(missing)}.",
            "envelope",
        )
    if extra:
        _fail(
            "pilot_envelope_invalid",
            f"Unexpected fields: {', '.join(extra)}.",
            "envelope",
        )
    if data["schema_version"] != PILOT_SCHEMA_VERSION:
        _fail(
            "pilot_schema_version_unsupported",
            f"Only schema version {PILOT_SCHEMA_VERSION} is supported.",
            "schema_version",
        )
    pilot_id = str(_text(data["pilot_id"], "pilot_id", max_length=40))
    match = _PILOT_ID_PATTERN.fullmatch(pilot_id)
    if match is None:
        _fail("pilot_id_invalid", "The pilot id has an invalid format.", "pilot_id")
    pilot_year = int(match.group(1))
    pilot_question = int(match.group(2))
    mode = _enum(data["verification_mode"], "verification_mode", PILOT_VERIFICATION_MODES)

    source = _validate_source(
        data["source"], mode=mode, pilot_year=pilot_year, pilot_question=pilot_question
    )
    question = _validate_question(data["question"], mode=mode)
    _validate_answer(data["answer_verification"], source=source, question=question, mode=mode)
    if require_approved and question["validation_status"] != "approved":
        _fail(
            "pilot_validation_status_invalid",
            "The envelope is not approved.",
            "question.validation_status",
        )
    computed_hash = compute_pilot_content_hash(data)
    _validate_review(
        data["review"],
        question=question,
        mode=mode,
        computed_hash=computed_hash,
        check_content_hash=check_content_hash,
    )
    _validate_publication(data["publication"], mode=mode)
    if check_content_hash:
        sealed = str(data["review"]["content_hash"])
        if sealed != computed_hash:
            _fail(
                "pilot_content_hash_mismatch",
                "The sealed content hash does not match the current content.",
                "review.content_hash",
            )
    return copy.deepcopy(dict(data))


def load_pilot_envelopes(directory: str | Path) -> list[dict[str, Any]]:
    """Load and validate every ``*.json`` envelope in a directory."""

    path = Path(directory)
    if not path.is_dir():
        _fail("pilot_bundle_missing", "The pilot question directory does not exist.", str(path))
    envelopes: list[dict[str, Any]] = []
    pilot_ids: set[str] = set()
    question_codes: set[str] = set()
    for file_path in sorted(path.glob("*.json")):
        try:
            payload = json.loads(file_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            _fail(
                "pilot_envelope_invalid", f"Could not read {file_path.name}: {exc}", str(file_path)
            )
        envelope = validate_pilot_envelope(payload)
        pilot_id = str(envelope["pilot_id"])
        question_code = str(envelope["question"]["question_code"])
        if pilot_id in pilot_ids:
            _fail("pilot_id_duplicate", f"Duplicate pilot id: {pilot_id}", "pilot_id")
        if question_code in question_codes:
            _fail(
                "pilot_question_code_duplicate",
                f"Duplicate question code: {question_code}",
                "question.question_code",
            )
        pilot_ids.add(pilot_id)
        question_codes.add(question_code)
        envelopes.append(envelope)
    if not envelopes:
        _fail("pilot_bundle_empty", "No pilot envelopes were found.", str(path))
    envelopes.sort(key=lambda item: str(item["pilot_id"]))
    return envelopes


def seal_pilot_envelope(envelope: Mapping[str, Any]) -> dict[str, Any]:
    """Validate an envelope with a placeholder hash, then set the real hash."""

    validated = validate_pilot_envelope(envelope, check_content_hash=False)
    validated["review"]["content_hash"] = compute_pilot_content_hash(validated)
    validate_pilot_envelope(validated)
    return validated


def seal_directory(directory: str | Path) -> list[str]:
    """Seal every envelope in a directory and write changed files."""

    path = Path(directory)
    changed: list[str] = []
    for file_path in sorted(path.glob("*.json")):
        payload = json.loads(file_path.read_text(encoding="utf-8"))
        sealed = seal_pilot_envelope(payload)
        text = json.dumps(sealed, ensure_ascii=False, indent=2) + "\n"
        if text != file_path.read_text(encoding="utf-8"):
            file_path.write_text(text, encoding="utf-8", newline="\n")
            changed.append(file_path.name)
    return changed


def to_validated_import(envelope: Mapping[str, Any]) -> ValidatedQuestionImport:
    """Convert an expert-review envelope to the T12 import path.

    Both independent reviews and explicit self-reviews are eligible. Official
    marking-scheme envelopes are deliberately blocked: T12 and the database
    trigger still require non-null author and reviewer principals.
    """

    validated = validate_pilot_envelope(envelope)
    if validated["verification_mode"] != "expert_review":
        _fail(
            "pilot_import_blocked",
            "Official marking-scheme envelopes are not importable through the T12 path.",
            "publication.import_status",
        )
    question = validated["question"]
    review = validated["review"]
    if review["reviewer_principal"] != question["reviewer_principal"]:
        _fail(
            "pilot_reviewer_mismatch",
            "The review reviewer must match the question reviewer.",
            "review.reviewer_principal",
        )
    bundle = QuestionImportBundle(
        question_code=question["question_code"],
        subject_id=UUID(str(question["subject_id"])),
        curriculum_version_id=UUID(str(question["curriculum_version_id"])),
        source_class=question["source_class"],
        question_type=question["question_type"],
        prompt=question["prompt"],
        explanation=question["explanation"],
        validation_status=question["validation_status"],
        author_principal=UUID(str(question["author_principal"])),
        reviewer_principal=UUID(str(question["reviewer_principal"])),
        content=question["content"],
        options=[
            QuestionOptionImport(
                option_key=option["option_key"],
                display_text=option["display_text"],
                is_correct=option["is_correct"],
                display_order=option["display_order"],
            )
            for option in question["options"]
        ],
        rubric=RubricImport(
            rubric_type=question["rubric"]["rubric_type"],
            max_score=question["rubric"]["max_score"],
            evidence_ceiling=question["rubric"]["evidence_ceiling"],
            status=question["rubric"]["status"],
            payload=question["rubric"]["payload"],
        ),
        concept_mappings=[
            ConceptMappingImport(
                concept_version_id=UUID(str(mapping["concept_version_id"])),
                learning_objective_id=UUID(str(mapping["learning_objective_id"])),
                mapping_role=mapping["mapping_role"],
                weight=mapping["weight"],
                provenance_type=mapping["provenance_type"],
                provenance_ref=mapping["provenance_ref"],
            )
            for mapping in question["concept_mappings"]
        ],
    )
    return validate_question_import(bundle)


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Validate or seal T24 pilot envelopes.")
    subparsers = parser.add_subparsers(dest="command", required=True)
    validate_parser = subparsers.add_parser(
        "validate", help="Validate every envelope in a directory."
    )
    validate_parser.add_argument("directory")
    seal_parser = subparsers.add_parser(
        "seal", help="Recompute and write every envelope content hash."
    )
    seal_parser.add_argument("directory")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    if args.command == "validate":
        envelopes = load_pilot_envelopes(args.directory)
        print(
            json.dumps(
                {
                    "status": "valid",
                    "count": len(envelopes),
                    "pilot_ids": [envelope["pilot_id"] for envelope in envelopes],
                },
                indent=2,
            )
        )
        return 0
    changed = seal_directory(args.directory)
    print(json.dumps({"status": "sealed", "changed": changed}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
