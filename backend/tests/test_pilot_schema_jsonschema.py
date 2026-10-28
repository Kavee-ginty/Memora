from __future__ import annotations

import copy
import json
from pathlib import Path

from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parents[2]
EXAMPLE = ROOT / "content/physics/pilot/examples/synthetic_draft.json"
SCHEMA = ROOT / "content/physics/pilot/pilot_question.schema.json"
AUTHOR_ID = "40000000-0000-0000-0000-000000000001"
REVIEWER_ID = "40000000-0000-0000-0000-000000000002"
CONTENT_HASH = "a" * 64


def load(path: Path) -> dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def validator() -> Draft202012Validator:
    schema = load(SCHEMA)
    Draft202012Validator.check_schema(schema)
    return Draft202012Validator(schema)


def errors(payload: dict[str, object]) -> list[object]:
    return sorted(validator().iter_errors(payload), key=lambda error: list(error.path))


def assert_valid(payload: dict[str, object]) -> None:
    found = errors(payload)
    assert not found, [f"{list(error.path)}: {error.message}" for error in found]


def assert_invalid(payload: dict[str, object]) -> None:
    assert errors(payload), "Expected the payload to fail the JSON Schema."


def approved_payload() -> dict[str, object]:
    payload = copy.deepcopy(load(EXAMPLE))
    question = payload["question"]
    answer = payload["answer_verification"]
    review = payload["review"]
    publication = payload["publication"]

    question["validation_status"] = "approved"
    question["source_class"] = "expert_verified"
    question["author_principal"] = AUTHOR_ID
    question["author_qualification_ref"] = "author-qualification-record-synthetic-001"
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
    review["content_hash"] = CONTENT_HASH
    review["source_ref"] = "SYNTHETIC-T24-KINEMATICS-001"

    publication["approved_for_import"] = True
    publication["approved_by"] = "approval-record-synthetic-001"
    publication["approved_at"] = "2026-10-28T12:05:00+00:00"
    return payload


def test_schema_is_valid_against_the_draft_2020_12_metaschema() -> None:
    Draft202012Validator.check_schema(load(SCHEMA))


def test_synthetic_draft_validates() -> None:
    assert_valid(load(EXAMPLE))


def test_draft_contradictions_are_rejected() -> None:
    verified = load(EXAMPLE)
    verified["question"]["source_class"] = "expert_verified"

    reviewed = load(EXAMPLE)
    reviewed["question"]["reviewer_principal"] = REVIEWER_ID

    approved_rubric = load(EXAMPLE)
    approved_rubric["question"]["rubric"]["status"] = "approved"

    published = load(EXAMPLE)
    published["publication"]["approved_for_import"] = True

    asserted_transcription = load(EXAMPLE)
    asserted_transcription["source"]["transcription_verified"] = True

    claimed_document = load(EXAMPLE)
    claimed_document["source"]["document_filename"] = "not-synthetic.pdf"

    paper_two = load(EXAMPLE)
    paper_two["pilot_id"] = "PILOT-PHYS-2025-P2-Q01"

    for payload in (
        verified,
        reviewed,
        approved_rubric,
        published,
        asserted_transcription,
        claimed_document,
        paper_two,
    ):
        assert_invalid(payload)


def test_approved_payload_validates() -> None:
    assert_valid(approved_payload())


def test_approved_payload_rejects_missing_evidence() -> None:
    no_author = approved_payload()
    no_author["question"]["author_principal"] = None

    no_author_qualification = approved_payload()
    no_author_qualification["question"]["author_qualification_ref"] = None

    no_reviewer = approved_payload()
    no_reviewer["question"]["reviewer_principal"] = None

    no_qualification = approved_payload()
    no_qualification["review"]["reviewer_qualification_ref"] = None

    no_independence = approved_payload()
    no_independence["review"]["independence_declaration_ref"] = None

    no_hash = approved_payload()
    no_hash["review"]["content_hash"] = None

    no_source_ref = approved_payload()
    no_source_ref["review"]["source_ref"] = None

    no_approver = approved_payload()
    no_approver["publication"]["approved_by"] = None

    no_approval_date = approved_payload()
    no_approval_date["publication"]["approved_at"] = None

    for payload in (
        no_author,
        no_author_qualification,
        no_reviewer,
        no_qualification,
        no_independence,
        no_hash,
        no_source_ref,
        no_approver,
        no_approval_date,
    ):
        assert_invalid(payload)


def test_author_qualification_is_approval_only() -> None:
    draft_with_qualification = load(EXAMPLE)
    draft_with_qualification["question"]["author_qualification_ref"] = (
        "author-qualification-record-synthetic-001"
    )

    assert_invalid(draft_with_qualification)
    assert_valid(approved_payload())


def test_approved_payload_rejects_unapproved_or_contradictory_states() -> None:
    pending_review = approved_payload()
    pending_review["review"]["academic_review_status"] = "pending"

    pending_answer = approved_payload()
    pending_answer["answer_verification"]["independent_review_status"] = "pending"

    official_key = approved_payload()
    official_key["answer_verification"]["official_key_claimed"] = True

    not_published = approved_payload()
    not_published["publication"]["approved_for_import"] = False

    draft_rubric = approved_payload()
    draft_rubric["question"]["rubric"]["status"] = "draft"

    for payload in (
        pending_review,
        pending_answer,
        official_key,
        not_published,
        draft_rubric,
    ):
        assert_invalid(payload)


def test_approved_payload_requires_a_primary_reviewed_mapping() -> None:
    supporting_only = approved_payload()
    supporting_only["question"]["concept_mappings"][0]["mapping_role"] = "supporting"

    analyst_provenance = approved_payload()
    analyst_provenance["question"]["concept_mappings"][0]["provenance_type"] = "analyst_mapping"

    assert_invalid(supporting_only)
    assert_invalid(analyst_provenance)


def test_approved_past_paper_requires_reproduction_and_transcription_evidence() -> None:
    payload = approved_payload()
    payload["source"].update(
        {
            "source_id": "SL-DOE-AL-PHYS-2025-P1",
            "source_type": "past_paper",
            "document_filename": "AL_Physics_2025_Combined_Paper_English.pdf",
            "document_sha256": CONTENT_HASH,
            "exam_year": 2025,
            "exam_label": "2025",
            "paper": "Paper I",
            "question_number": 1,
            "pdf_page": 1,
            "official_key_status": "not_found",
            "reproduction_status": "unapproved",
            "reproduction_approval_ref": None,
            "transcription_verified": False,
        }
    )
    payload["review"]["source_ref"] = f"SL-DOE-AL-PHYS-2025-P1|{CONTENT_HASH}|1|1"

    assert_invalid(payload)

    payload["source"]["reproduction_status"] = "approved"
    payload["source"]["reproduction_approval_ref"] = "reproduction-approval-synthetic-001"
    assert_invalid(payload)

    payload["source"]["transcription_verified"] = True
    assert_valid(payload)


def test_source_metadata_cannot_be_smuggled_into_content() -> None:
    payload = approved_payload()
    payload["question"]["content"]["source_ref"] = "SL-DOE-AL-PHYS-2025-P1"

    assert_invalid(payload)


def test_unknown_top_level_properties_are_rejected() -> None:
    payload = approved_payload()
    payload["source_licence"] = "claimed-in-the-wrong-place"

    assert_invalid(payload)


def test_non_english_medium_is_rejected() -> None:
    payload = approved_payload()
    payload["source"]["medium"] = "Sinhala"

    assert_invalid(payload)
