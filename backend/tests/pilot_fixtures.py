"""Synthetic in-memory envelopes for the T24 validator and schema tests.

The fixtures do not describe real past-paper content. They use fake source hashes
so the structural and semantic gates can be exercised before the checked-in
pilot envelopes are loaded. The real envelopes are covered separately.
"""

from __future__ import annotations

import copy
from typing import Any

from memora.modules.questions.pilot_validation import seal_pilot_envelope

AUTHOR_ID = "40000000-0000-0000-0000-000000000001"
REVIEWER_ID = "40000000-0000-0000-0000-000000000002"
SUBJECT_ID = "10000000-0000-0000-0000-000000000001"
CURRICULUM_ID = "20000000-0000-0000-0000-000000000001"
CONCEPT_SI_UNITS = "50000000-0000-0000-0000-000000000001"
OBJECTIVE_SI_UNITS = "30000000-0000-0000-0000-000000000002"
OFFICIAL_SCOPES = [
    "official_key_match",
    "derivation",
    "transcription",
    "curriculum_mapping",
    "ambiguity",
    "duplicate",
]
EXPERT_SCOPES = [
    "derivation",
    "transcription",
    "curriculum_mapping",
    "ambiguity",
    "duplicate",
]


def _base_source() -> dict[str, Any]:
    return {
        "source_id": "SL-DOE-AL-PHYS-2025-P1",
        "source_type": "past_paper",
        "document_filename": "synthetic-paper-fixture.pdf",
        "document_sha256": "a" * 64,
        "exam_year": 2025,
        "exam_label": "2025",
        "paper": "Paper I",
        "question_number": 1,
        "pdf_page": 1,
        "medium": "English",
        "marking_scheme_document": "synthetic-marking-scheme-fixture.pdf",
        "marking_scheme_sha256": "b" * 64,
        "marking_scheme_pdf_page": 2,
        "official_key": 1,
        "official_key_status": "verified_against_marking_scheme",
        "transcription_status": "verified_visual",
        "text_only_adaptation": False,
        "transcription_note": None,
        "reproduction_status": "unapproved",
        "licence_note": "Synthetic test fixture; not a real past-paper excerpt.",
    }


def _base_question(*, suffix: str) -> dict[str, Any]:
    return {
        "question_code": f"pilot-phys-synthetic-{suffix}",
        "subject_id": SUBJECT_ID,
        "curriculum_version_id": CURRICULUM_ID,
        "source_class": "expert_verified",
        "target_source_class": "expert_verified",
        "question_type": "mcq",
        "prompt": "Synthetic validator fixture prompt.",
        "explanation": "Synthetic validator fixture explanation.",
        "validation_status": "approved",
        "author_principal": None,
        "author_qualification_ref": None,
        "reviewer_principal": None,
        "content": {
            "kind": "choice",
            "schema_version": "1",
            "selection_mode": "single",
        },
        "options": [
            {
                "option_key": "1",
                "display_text": "Synthetic correct option.",
                "is_correct": True,
                "display_order": 0,
            },
            {
                "option_key": "2",
                "display_text": "Synthetic distractor two.",
                "is_correct": False,
                "display_order": 1,
            },
            {
                "option_key": "3",
                "display_text": "Synthetic distractor three.",
                "is_correct": False,
                "display_order": 2,
            },
            {
                "option_key": "4",
                "display_text": "Synthetic distractor four.",
                "is_correct": False,
                "display_order": 3,
            },
            {
                "option_key": "5",
                "display_text": "Synthetic distractor five.",
                "is_correct": False,
                "display_order": 4,
            },
        ],
        "rubric": {
            "rubric_type": "exact",
            "max_score": 1,
            "evidence_ceiling": 0.9,
            "status": "approved",
            "payload": {"kind": "exact", "schema_version": "1"},
        },
        "concept_mappings": [
            {
                "concept_version_id": CONCEPT_SI_UNITS,
                "learning_objective_id": OBJECTIVE_SI_UNITS,
                "mapping_role": "primary",
                "weight": 1.0,
                "provenance_type": "source_analysis",
                "provenance_ref": "synthetic-fixture:mapping",
            }
        ],
    }


def _base_review(*, mode: str, scopes: list[str]) -> dict[str, Any]:
    return {
        "review_mode": mode,
        "academic_review_status": "not_required",
        "reviewer_principal": None,
        "reviewer_qualification_ref": None,
        "review_scope": list(scopes),
        "reviewed_at": "2026-11-02T00:00:00+00:00",
        "ambiguity_status": "cleared",
        "ambiguity_note": None,
        "duplicate_status": "cleared",
        "coverage_note": "Synthetic fixture coverage note.",
        "content_hash": "0" * 64,
        "source_ref": "synthetic-fixture",
        "independence_declaration_ref": None,
        "deviation_ref": "content/physics/pilot/DEVIATION_REVIEW_MODE.md",
    }


def official_envelope() -> dict[str, Any]:
    """Return an unsealed official-marking-scheme fixture."""

    return {
        "schema_version": "2.0",
        "pilot_id": "PILOT-PHYS-2025-P1-Q01",
        "verification_mode": "official_marking_scheme",
        "source": _base_source(),
        "question": _base_question(suffix="official-001"),
        "answer_verification": {
            "mode": "official_marking_scheme",
            "official_key": 1,
            "derived_option_key": "1",
            "matches_official_key": True,
            "derivation": "The fixture's derived option is 1.",
            "official_key_source_ref": "synthetic marking scheme p.2",
            "independent_review_status": "not_required",
            "reviewer_ref": None,
            "notes": None,
        },
        "review": _base_review(mode="official_marking_scheme", scopes=OFFICIAL_SCOPES),
        "publication": {
            "approved_for_import": False,
            "approved_by": None,
            "approved_at": None,
            "import_batch_id": None,
            "import_status": "blocked_pending_t12_verification_mode",
            "blocker_ref": "content/physics/pilot/DEVIATION_REVIEW_MODE.md#t12-import-gate",
        },
    }


def sealed_official_envelope() -> dict[str, Any]:
    return seal_pilot_envelope(official_envelope())


def expert_envelope() -> dict[str, Any]:
    """Return an unsealed expert-review fixture using the same fake source."""

    envelope = official_envelope()
    envelope["pilot_id"] = "PILOT-PHYS-2025-P1-Q02"
    envelope["verification_mode"] = "expert_review"
    envelope["source"]["question_number"] = 2
    question = envelope["question"]
    question["question_code"] = "pilot-phys-synthetic-expert-002"
    question["author_principal"] = AUTHOR_ID
    question["author_qualification_ref"] = "synthetic-author-qualification"
    question["reviewer_principal"] = REVIEWER_ID
    question["concept_mappings"][0]["provenance_type"] = "pilot_review"
    question["concept_mappings"][0]["provenance_ref"] = "synthetic-fixture:review"

    answer = envelope["answer_verification"]
    answer["mode"] = "expert_review"
    answer["official_key"] = 1
    answer["independent_review_status"] = "verified"
    answer["reviewer_ref"] = "synthetic-review-record"

    review = envelope["review"]
    review["review_mode"] = "expert_review"
    review["academic_review_status"] = "approved"
    review["reviewer_principal"] = REVIEWER_ID
    review["reviewer_qualification_ref"] = "synthetic-reviewer-qualification"
    review["review_scope"] = list(EXPERT_SCOPES)
    review["independence_declaration_ref"] = "synthetic-independence-declaration"
    review["deviation_ref"] = None

    publication = envelope["publication"]
    publication["approved_for_import"] = True
    publication["approved_by"] = "synthetic-approval-record"
    publication["approved_at"] = "2026-11-02T00:05:00+00:00"
    publication["import_batch_id"] = "synthetic-import-batch"
    publication["import_status"] = "ready_for_import"
    publication["blocker_ref"] = None
    return envelope


def sealed_expert_envelope() -> dict[str, Any]:
    return seal_pilot_envelope(expert_envelope())


def self_review_envelope() -> dict[str, Any]:
    """Return an unsealed expert-review fixture with one principal as author and reviewer."""

    envelope = expert_envelope()
    envelope["pilot_id"] = "PILOT-PHYS-2025-P1-Q03"
    envelope["source"]["question_number"] = 3
    question = envelope["question"]
    question["question_code"] = "pilot-phys-synthetic-self-003"
    question["reviewer_principal"] = AUTHOR_ID

    answer = envelope["answer_verification"]
    answer["independent_review_status"] = "self_review"
    answer["reviewer_ref"] = "synthetic-self-review-record"

    review = envelope["review"]
    review["reviewer_principal"] = AUTHOR_ID
    review["reviewer_qualification_ref"] = "synthetic-author-qualification"
    review["independence_declaration_ref"] = "synthetic-self-review-declaration"

    envelope["publication"]["approved_by"] = "synthetic-self-review-approval"
    return envelope


def sealed_self_review_envelope() -> dict[str, Any]:
    return seal_pilot_envelope(self_review_envelope())


def mutate(envelope: dict[str, Any], path: tuple[str | int, ...], value: Any) -> dict[str, Any]:
    """Return a deep copy with one value replaced."""

    changed = copy.deepcopy(envelope)
    target: Any = changed
    for key in path[:-1]:
        target = target[key]
    target[path[-1]] = value
    return changed
