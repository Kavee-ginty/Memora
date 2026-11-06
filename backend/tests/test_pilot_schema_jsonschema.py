from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator

from pilot_fixtures import (
    AUTHOR_ID,
    REVIEWER_ID,
    expert_envelope,
    official_envelope,
    self_review_envelope,
)

ROOT = Path(__file__).resolve().parents[2]
SCHEMA = ROOT / "content/physics/pilot/pilot_question.schema.json"


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def validator() -> Draft202012Validator:
    schema = load(SCHEMA)
    Draft202012Validator.check_schema(schema)
    return Draft202012Validator(schema)


def errors(payload: dict[str, Any]) -> list[object]:
    return sorted(validator().iter_errors(payload), key=lambda error: list(error.path))


def assert_valid(payload: dict[str, Any]) -> None:
    found = errors(payload)
    assert not found, [f"{list(error.path)}: {error.message}" for error in found]


def assert_invalid(payload: dict[str, Any]) -> None:
    assert errors(payload), "Expected the payload to fail the JSON Schema."


def test_schema_is_valid_against_the_draft_2020_12_metaschema() -> None:
    Draft202012Validator.check_schema(load(SCHEMA))


def test_official_marking_scheme_envelope_matches_the_schema() -> None:
    assert_valid(official_envelope())


def test_expert_review_envelope_matches_the_schema() -> None:
    assert_valid(expert_envelope())


def test_self_review_envelope_matches_the_schema() -> None:
    assert_valid(self_review_envelope())


def test_missing_top_level_sections_are_rejected() -> None:
    for section in (
        "schema_version",
        "pilot_id",
        "verification_mode",
        "source",
        "question",
        "answer_verification",
        "review",
        "publication",
    ):
        payload = official_envelope()
        payload.pop(section)
        assert_invalid(payload)


def test_unknown_properties_are_rejected_at_every_level() -> None:
    top_level = official_envelope()
    top_level["source_licence"] = "claimed-in-the-wrong-place"

    source = official_envelope()
    source["source"]["reproduction_approval_ref"] = "not-part-of-v2"

    question = official_envelope()
    question["question"]["content"]["source_ref"] = "smuggled-metadata"

    option = official_envelope()
    option["question"]["options"][0]["feedback"] = "not-part-of-v2"

    for payload in (top_level, source, question, option):
        assert_invalid(payload)


def test_official_mode_rejects_human_review_and_import_claims() -> None:
    author = official_envelope()
    author["question"]["author_principal"] = AUTHOR_ID

    reviewer = official_envelope()
    reviewer["question"]["reviewer_principal"] = REVIEWER_ID

    answer_review = official_envelope()
    answer_review["answer_verification"]["independent_review_status"] = "verified"

    academic_review = official_envelope()
    academic_review["review"]["academic_review_status"] = "approved"

    approved = official_envelope()
    approved["publication"]["approved_for_import"] = True

    independence = official_envelope()
    independence["review"]["independence_declaration_ref"] = "synthetic-independence"

    for payload in (author, reviewer, answer_review, academic_review, approved, independence):
        assert_invalid(payload)


def test_official_mode_requires_the_marking_scheme_evidence() -> None:
    missing_key = official_envelope()
    missing_key["source"]["official_key"] = None

    unverified_key = official_envelope()
    unverified_key["source"]["official_key_status"] = "not_found"

    unverified_transcription = official_envelope()
    unverified_transcription["source"]["transcription_status"] = "unverified"

    missing_deviation = official_envelope()
    missing_deviation["review"]["deviation_ref"] = None

    missing_a_scope = official_envelope()
    missing_a_scope["review"]["review_scope"].pop()

    for payload in (
        missing_key,
        unverified_key,
        unverified_transcription,
        missing_deviation,
        missing_a_scope,
    ):
        assert_invalid(payload)


def test_expert_mode_requires_human_review_evidence() -> None:
    no_author = expert_envelope()
    no_author["question"]["author_principal"] = None

    no_author_qualification = expert_envelope()
    no_author_qualification["question"]["author_qualification_ref"] = None

    no_reviewer = expert_envelope()
    no_reviewer["review"]["reviewer_principal"] = None

    no_qualification = expert_envelope()
    no_qualification["review"]["reviewer_qualification_ref"] = None

    no_independence = expert_envelope()
    no_independence["review"]["independence_declaration_ref"] = None

    pending_answer = expert_envelope()
    pending_answer["answer_verification"]["independent_review_status"] = "pending"

    pending_review = expert_envelope()
    pending_review["review"]["academic_review_status"] = "pending"

    for payload in (
        no_author,
        no_author_qualification,
        no_reviewer,
        no_qualification,
        no_independence,
        pending_answer,
        pending_review,
    ):
        assert_invalid(payload)


def test_source_identity_fields_are_constrained() -> None:
    bad_hash = official_envelope()
    bad_hash["source"]["document_sha256"] = "not-a-sha256"

    bad_year = official_envelope()
    bad_year["source"]["exam_year"] = 2016

    paper_two = official_envelope()
    paper_two["pilot_id"] = "PILOT-PHYS-2025-P2-Q01"

    sinhala = official_envelope()
    sinhala["source"]["medium"] = "Sinhala"

    for payload in (bad_hash, bad_year, paper_two, sinhala):
        assert_invalid(payload)


def test_publication_and_answer_values_are_constrained() -> None:
    false_match = official_envelope()
    false_match["answer_verification"]["matches_official_key"] = False

    bad_key = official_envelope()
    bad_key["answer_verification"]["official_key"] = 6

    bad_publication = official_envelope()
    bad_publication["publication"]["import_status"] = "ready_for_import"

    for payload in (false_match, bad_key, bad_publication):
        assert_invalid(payload)
