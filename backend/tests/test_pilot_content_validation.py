from __future__ import annotations

import copy
import json
from pathlib import Path

import pytest

from memora.modules.questions.pilot_validation import (
    PilotEnvelopeError,
    compute_pilot_content_hash,
    to_validated_import,
    validate_pilot_envelope,
)

ROOT = Path(__file__).resolve().parents[2]
EXAMPLE = ROOT / "content/physics/pilot/examples/synthetic_draft.json"
SCHEMA = ROOT / "content/physics/pilot/pilot_question.schema.json"
AUTHOR_ID = "40000000-0000-0000-0000-000000000001"
REVIEWER_ID = "40000000-0000-0000-0000-000000000002"


def draft() -> dict[str, object]:
    return json.loads(EXAMPLE.read_text(encoding="utf-8"))


def approved() -> dict[str, object]:
    envelope = copy.deepcopy(draft())
    question = envelope["question"]
    review = envelope["review"]
    answer = envelope["answer_verification"]
    publication = envelope["publication"]

    question["validation_status"] = "approved"
    question["source_class"] = "expert_verified"
    question["author_principal"] = AUTHOR_ID
    question["reviewer_principal"] = REVIEWER_ID
    question["rubric"]["status"] = "approved"
    for mapping in question["concept_mappings"]:
        mapping["provenance_type"] = "pilot_review"
        mapping["provenance_ref"] = "review-record-synthetic-001:mapping"

    answer["independent_review_status"] = "verified"
    answer["reviewer_ref"] = "review-record-synthetic-001"

    review["academic_review_status"] = "approved"
    review["reviewer_principal"] = REVIEWER_ID
    review["reviewer_qualification_ref"] = "qualification-record-synthetic-001"
    review["reviewed_at"] = "2026-10-28T12:00:00+00:00"
    review["ambiguity_status"] = "cleared"
    review["duplicate_status"] = "cleared"
    review["independence_declaration_ref"] = "independence-record-synthetic-001"
    review["content_hash"] = None

    publication["approved_for_import"] = True
    publication["approved_by"] = "approval-record-synthetic-001"
    publication["approved_at"] = "2026-10-28T12:05:00+00:00"
    return envelope


def failure_code(envelope: dict[str, object]) -> str:
    with pytest.raises(PilotEnvelopeError) as exc_info:
        validate_pilot_envelope(envelope)
    return exc_info.value.code


def test_synthetic_draft_is_valid_and_not_approved() -> None:
    envelope = draft()

    validated = validate_pilot_envelope(envelope)

    assert validated["question"]["validation_status"] == "draft"
    assert validated["question"]["source_class"] is None
    assert validated["question"]["target_source_class"] == "expert_verified"
    assert validated["publication"]["approved_for_import"] is False
    assert validated["review"]["academic_review_status"] == "pending"


def test_draft_cannot_claim_expert_verified() -> None:
    envelope = draft()
    envelope["question"]["source_class"] = "expert_verified"

    assert failure_code(envelope) == "pilot_draft_source_class"


def test_draft_cannot_use_pilot_review_provenance() -> None:
    envelope = draft()
    envelope["question"]["concept_mappings"][0]["provenance_type"] = "pilot_review"

    assert failure_code(envelope) == "pilot_provenance_unreviewed"


def test_draft_may_record_a_partial_mapping_without_primary() -> None:
    envelope = draft()
    envelope["question"]["concept_mappings"][0]["mapping_role"] = "supporting"

    validated = validate_pilot_envelope(envelope)

    assert validated["question"]["validation_status"] == "draft"


def test_approved_envelope_requires_reviewed_mapping_provenance() -> None:
    envelope = approved()
    envelope["question"]["concept_mappings"][0]["provenance_type"] = "analyst_mapping"

    assert failure_code(envelope) == "pilot_provenance_not_reviewed"


def test_synthetic_item_cannot_claim_transcription() -> None:
    envelope = draft()
    envelope["source"]["transcription_verified"] = True

    assert failure_code(envelope) == "pilot_source_invalid"


def test_draft_cannot_carry_reviewer_or_approved_rubric() -> None:
    reviewer = draft()
    reviewer["question"]["reviewer_principal"] = REVIEWER_ID

    rubric = draft()
    rubric["question"]["rubric"]["status"] = "approved"

    assert failure_code(reviewer) == "pilot_draft_reviewer"
    assert failure_code(rubric) == "pilot_rubric_invalid"


def test_answer_reviewer_reference_matches_review_state() -> None:
    draft_with_reviewer = draft()
    draft_with_reviewer["answer_verification"]["reviewer_ref"] = "review-record-synthetic-001"

    approved_without_reviewer = approved()
    approved_without_reviewer["answer_verification"]["reviewer_ref"] = None

    assert failure_code(draft_with_reviewer) == "pilot_answer_invalid"
    assert failure_code(approved_without_reviewer) == "pilot_answer_invalid"


def test_draft_cannot_carry_approved_review_or_publication() -> None:
    reviewed = draft()
    reviewed["review"]["academic_review_status"] = "approved"

    published = draft()
    published["publication"]["approved_for_import"] = True
    published["publication"]["approved_by"] = "approval-record-synthetic-001"
    published["publication"]["approved_at"] = "2026-10-28T12:05:00+00:00"

    assert failure_code(reviewed) == "pilot_review_state_mismatch"
    assert failure_code(published) == "pilot_publication_mismatch"


def test_to_validated_import_refuses_drafts() -> None:
    with pytest.raises(PilotEnvelopeError) as exc_info:
        to_validated_import(draft())

    assert exc_info.value.code == "pilot_approval_required"


def test_approved_envelope_converts_with_bound_hash() -> None:
    envelope = approved()
    envelope["review"]["content_hash"] = compute_pilot_content_hash(envelope)

    validated = to_validated_import(envelope)

    assert validated.bundle.validation_status == "approved"
    assert validated.bundle.source_class == "expert_verified"
    assert validated.content_hash == envelope["review"]["content_hash"]
    assert validated.trust_label == "Expert verified"


def test_approved_envelope_requires_reviewer_independence() -> None:
    envelope = approved()
    envelope["question"]["author_principal"] = REVIEWER_ID

    assert failure_code(envelope) == "pilot_reviewer_independence"


def test_approved_envelope_requires_review_hash_and_source_ref() -> None:
    missing_hash = approved()
    assert failure_code(missing_hash) == "pilot_content_hash_required"

    wrong_hash = approved()
    wrong_hash["review"]["content_hash"] = "0" * 64
    assert failure_code(wrong_hash) == "pilot_content_hash_mismatch"

    wrong_source = approved()
    wrong_source["review"]["content_hash"] = compute_pilot_content_hash(wrong_source)
    wrong_source["review"]["source_ref"] = "SL-DOE-AL-PHYS-2025-P1|" + "0" * 64 + "|1|1"
    assert failure_code(wrong_source) == "pilot_source_ref_mismatch"


def test_approved_past_paper_requires_reproduction_and_transcription_gates() -> None:
    envelope = approved()
    source = envelope["source"]
    source.update(
        {
            "source_id": "SL-DOE-AL-PHYS-2025-P1",
            "source_type": "past_paper",
            "document_filename": "AL_Physics_2025_Combined_Paper_English.pdf",
            "document_sha256": "a" * 64,
            "exam_year": 2025,
            "exam_label": "2025",
            "paper": "Paper I",
            "question_number": 1,
            "pdf_page": 1,
            "official_key_status": "marking_scheme_not_mcq_key",
            "reproduction_status": "unapproved",
            "reproduction_approval_ref": None,
            "transcription_verified": False,
        }
    )

    assert failure_code(envelope) == "pilot_reproduction_not_approved"

    source["reproduction_status"] = "approved"
    source["reproduction_approval_ref"] = "reproduction-approval-synthetic-001"
    assert failure_code(envelope) == "pilot_transcription_not_verified"


def test_approved_envelope_requires_qualification_and_scope() -> None:
    no_qualification = approved()
    no_qualification["review"]["content_hash"] = compute_pilot_content_hash(no_qualification)
    no_qualification["review"]["reviewer_qualification_ref"] = None

    missing_scope = approved()
    missing_scope["review"]["content_hash"] = compute_pilot_content_hash(missing_scope)
    missing_scope["review"]["review_scope"] = ["derivation"]

    assert failure_code(no_qualification) == "pilot_qualification_required"
    assert failure_code(missing_scope) == "pilot_review_scope_incomplete"


def test_synthetic_schema_is_parseable_and_draft_only() -> None:
    schema = json.loads(SCHEMA.read_text(encoding="utf-8"))

    question = schema["$defs"]["question"]
    review = schema["$defs"]["review"]
    answer = schema["$defs"]["answerVerification"]
    source = schema["$defs"]["source"]

    assert "target_source_class" in question["required"]
    assert "content_hash" in review["required"]
    assert "source_ref" in review["required"]
    assert "independence_declaration_ref" in review["required"]
    assert "reviewer_ref" in answer["required"]
    assert "synthetic" in source["properties"]["source_type"]["enum"]
    assert schema["description"].startswith("A review envelope")


def _walk_schema(node: object):
    if isinstance(node, dict):
        yield node
        for value in node.values():
            yield from _walk_schema(value)
    elif isinstance(node, list):
        for item in node:
            yield from _walk_schema(item)


def test_schema_references_and_required_fields_resolve() -> None:
    schema = json.loads(SCHEMA.read_text(encoding="utf-8"))
    defs = schema["$defs"]

    for node in _walk_schema(schema):
        ref = node.get("$ref")
        if isinstance(ref, str):
            assert ref.startswith("#/$defs/")
            assert ref.removeprefix("#/$defs/") in defs

        properties = node.get("properties")
        required = node.get("required")
        if isinstance(properties, dict) and isinstance(required, list):
            assert set(required) <= set(properties)
