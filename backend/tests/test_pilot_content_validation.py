from __future__ import annotations

import copy
import json

import pytest

from memora.modules.questions.pilot_validation import (
    PilotEnvelopeError,
    compute_pilot_content_hash,
    load_pilot_envelopes,
    seal_directory,
    to_validated_import,
    validate_pilot_envelope,
)
from pilot_fixtures import (
    AUTHOR_ID,
    REVIEWER_ID,
    mutate,
    sealed_expert_envelope,
    sealed_official_envelope,
    sealed_self_review_envelope,
)


def failure_code(envelope: dict[str, object]) -> str:
    with pytest.raises(PilotEnvelopeError) as exc_info:
        validate_pilot_envelope(envelope)
    return exc_info.value.code


def test_official_marking_scheme_envelope_is_valid_and_blocked() -> None:
    envelope = sealed_official_envelope()

    validated = validate_pilot_envelope(envelope)

    assert validated["verification_mode"] == "official_marking_scheme"
    assert validated["question"]["validation_status"] == "approved"
    assert validated["question"]["author_principal"] is None
    assert validated["question"]["reviewer_principal"] is None
    assert validated["answer_verification"]["independent_review_status"] == "not_required"
    assert validated["review"]["academic_review_status"] == "not_required"
    assert validated["publication"]["approved_for_import"] is False
    assert validated["publication"]["import_status"] == "blocked_pending_t12_verification_mode"
    assert len(validated["review"]["content_hash"]) == 64


def test_official_mode_rejects_every_human_review_identity() -> None:
    author = mutate(sealed_official_envelope(), ("question", "author_principal"), AUTHOR_ID)
    author_qualification = mutate(
        sealed_official_envelope(),
        ("question", "author_qualification_ref"),
        "synthetic-author-qualification",
    )
    reviewer = mutate(sealed_official_envelope(), ("question", "reviewer_principal"), REVIEWER_ID)
    answer_review = mutate(
        sealed_official_envelope(),
        ("answer_verification", "independent_review_status"),
        "verified",
    )
    answer_reviewer = mutate(
        sealed_official_envelope(),
        ("answer_verification", "reviewer_ref"),
        "synthetic-answer-review",
    )
    academic_review = mutate(
        sealed_official_envelope(),
        ("review", "academic_review_status"),
        "approved",
    )
    review_reviewer = mutate(
        sealed_official_envelope(),
        ("review", "reviewer_principal"),
        REVIEWER_ID,
    )
    independence = mutate(
        sealed_official_envelope(),
        ("review", "independence_declaration_ref"),
        "synthetic-independence",
    )

    for envelope in (
        author,
        author_qualification,
        reviewer,
        answer_review,
        answer_reviewer,
        academic_review,
        review_reviewer,
        independence,
    ):
        assert failure_code(envelope) == "pilot_reviewer_not_allowed"


def test_official_mode_requires_the_recorded_deviation() -> None:
    envelope = mutate(sealed_official_envelope(), ("review", "deviation_ref"), None)

    assert failure_code(envelope) == "pilot_deviation_required"


def test_official_mode_cannot_claim_import_approval() -> None:
    approved = mutate(
        sealed_official_envelope(),
        ("publication", "approved_for_import"),
        True,
    )
    approver = mutate(
        sealed_official_envelope(),
        ("publication", "approved_by"),
        "synthetic-approver",
    )
    ready = mutate(
        sealed_official_envelope(),
        ("publication", "import_status"),
        "ready_for_import",
    )

    for envelope in (approved, approver, ready):
        assert failure_code(envelope) == "pilot_import_blocked"


def test_official_key_and_derived_option_must_agree() -> None:
    source_mismatch = mutate(
        sealed_official_envelope(),
        ("answer_verification", "official_key"),
        2,
    )
    derived_mismatch = mutate(
        sealed_official_envelope(),
        ("answer_verification", "derived_option_key"),
        "2",
    )
    false_match = mutate(
        sealed_official_envelope(),
        ("answer_verification", "matches_official_key"),
        False,
    )

    assert failure_code(source_mismatch) == "pilot_official_key_mismatch"
    assert failure_code(derived_mismatch) == "pilot_official_key_mismatch"
    assert failure_code(false_match) == "pilot_official_key_mismatch"


def test_the_derived_option_must_be_the_marked_correct_option() -> None:
    envelope = sealed_official_envelope()
    for option in envelope["question"]["options"]:
        option["is_correct"] = option["option_key"] == "2"

    assert failure_code(envelope) == "pilot_answer_invalid"


def test_paper_i_mcq_needs_exactly_five_unique_options() -> None:
    missing_option = sealed_official_envelope()
    missing_option["question"]["options"].pop()

    duplicate_text = sealed_official_envelope()
    duplicate_text["question"]["options"][1]["display_text"] = duplicate_text["question"][
        "options"
    ][0]["display_text"]

    duplicate_order = sealed_official_envelope()
    duplicate_order["question"]["options"][1]["display_order"] = 0

    two_correct = sealed_official_envelope()
    two_correct["question"]["options"][1]["is_correct"] = True

    assert failure_code(missing_option) == "pilot_options_invalid"
    assert failure_code(duplicate_text) == "pilot_options_invalid"
    assert failure_code(duplicate_order) == "pilot_options_invalid"
    assert failure_code(two_correct) == "pilot_answer_invalid"


def test_concept_mappings_must_resolve_to_the_t08_seed() -> None:
    unknown_concept = mutate(
        sealed_official_envelope(),
        ("question", "concept_mappings", 0, "concept_version_id"),
        "50000000-0000-0000-0000-000000009999",
    )
    wrong_objective = mutate(
        sealed_official_envelope(),
        ("question", "concept_mappings", 0, "learning_objective_id"),
        "30000000-0000-0000-0000-000000000001",
    )
    no_primary = mutate(
        sealed_official_envelope(),
        ("question", "concept_mappings", 0, "mapping_role"),
        "supporting",
    )

    assert failure_code(unknown_concept) == "pilot_mapping_unknown_concept"
    assert failure_code(wrong_objective) == "pilot_mapping_objective_mismatch"
    assert failure_code(no_primary) == "pilot_mapping_invalid"


def test_unknown_top_level_fields_are_rejected() -> None:
    envelope = sealed_official_envelope()
    envelope["reviewer_identity"] = "smuggled-outside-review"

    assert failure_code(envelope) == "pilot_envelope_invalid"


def test_content_hash_binds_question_but_not_publication_state() -> None:
    envelope = sealed_official_envelope()
    original = compute_pilot_content_hash(envelope)

    changed_prompt = mutate(
        envelope,
        ("question", "prompt"),
        "A changed synthetic validator fixture prompt.",
    )
    changed_publication = mutate(
        envelope,
        ("publication", "approved_by"),
        "synthetic-approver",
    )

    assert compute_pilot_content_hash(changed_prompt) != original
    assert compute_pilot_content_hash(changed_publication) == original
    assert envelope["review"]["content_hash"] == original


def test_content_hash_mismatch_is_a_build_failure() -> None:
    envelope = mutate(sealed_official_envelope(), ("review", "content_hash"), "f" * 64)

    assert failure_code(envelope) == "pilot_content_hash_mismatch"


def test_official_mode_cannot_be_converted_to_the_t12_import_path() -> None:
    with pytest.raises(PilotEnvelopeError) as exc_info:
        to_validated_import(sealed_official_envelope())

    assert exc_info.value.code == "pilot_import_blocked"


def test_expert_review_envelope_is_importable() -> None:
    envelope = sealed_expert_envelope()

    validated = to_validated_import(envelope)

    assert validated.bundle.validation_status == "approved"
    assert validated.bundle.source_class == "expert_verified"
    assert validated.trust_label == "Expert verified"
    assert len(validated.content_hash) == 64
    # The T12 hash covers the persisted import bundle, not the pilot envelope.
    assert validated.content_hash != envelope["review"]["content_hash"]


def test_expert_review_requires_identity_qualification_and_independence() -> None:
    no_reviewer = mutate(sealed_expert_envelope(), ("review", "reviewer_principal"), None)
    no_qualification = mutate(
        sealed_expert_envelope(),
        ("review", "reviewer_qualification_ref"),
        None,
    )
    no_independence = mutate(
        sealed_expert_envelope(),
        ("review", "independence_declaration_ref"),
        None,
    )
    pending = mutate(
        sealed_expert_envelope(),
        ("review", "academic_review_status"),
        "pending",
    )

    for envelope in (no_reviewer, no_qualification, no_independence, pending):
        assert failure_code(envelope) == "pilot_review_required"


def test_expert_review_requires_a_verified_answer_review() -> None:
    envelope = mutate(
        sealed_expert_envelope(),
        ("answer_verification", "reviewer_ref"),
        None,
    )

    assert failure_code(envelope) == "pilot_answer_review_required"


def test_self_review_envelope_is_importable_without_claiming_independence() -> None:
    envelope = sealed_self_review_envelope()

    validated = to_validated_import(envelope)

    assert validated.bundle.author_principal == validated.bundle.reviewer_principal
    assert envelope["answer_verification"]["independent_review_status"] == "self_review"
    assert envelope["review"]["independence_declaration_ref"] == (
        "synthetic-self-review-declaration"
    )
    assert validated.trust_label == "Expert verified"


def test_self_review_requires_the_same_author_and_reviewer_principal() -> None:
    envelope = sealed_self_review_envelope()
    envelope["question"]["reviewer_principal"] = REVIEWER_ID
    envelope["review"]["reviewer_principal"] = REVIEWER_ID

    assert failure_code(envelope) == "pilot_self_review_mismatch"


def test_independent_review_requires_distinct_author_and_reviewer_principals() -> None:
    envelope = mutate(
        sealed_expert_envelope(),
        ("question", "author_principal"),
        REVIEWER_ID,
    )

    assert failure_code(envelope) == "pilot_independence_claim_invalid"


def test_load_pilot_envelopes_rejects_duplicate_ids_and_codes(tmp_path) -> None:
    first = sealed_official_envelope()
    second = copy.deepcopy(first)
    second["question"]["question_code"] = "pilot-phys-synthetic-second"
    second["review"]["content_hash"] = compute_pilot_content_hash(second)
    (tmp_path / "first.json").write_text(json.dumps(first), encoding="utf-8")
    (tmp_path / "second.json").write_text(json.dumps(second), encoding="utf-8")

    with pytest.raises(PilotEnvelopeError) as exc_info:
        load_pilot_envelopes(tmp_path)
    assert exc_info.value.code == "pilot_id_duplicate"

    second = copy.deepcopy(first)
    second["pilot_id"] = "PILOT-PHYS-2025-P1-Q02"
    second["source"]["question_number"] = 2
    second["review"]["content_hash"] = compute_pilot_content_hash(second)
    (tmp_path / "second.json").write_text(json.dumps(second), encoding="utf-8")

    with pytest.raises(PilotEnvelopeError) as exc_info:
        load_pilot_envelopes(tmp_path)
    assert exc_info.value.code == "pilot_question_code_duplicate"


def test_seal_directory_writes_the_computed_hash(tmp_path) -> None:
    envelope = sealed_official_envelope()
    envelope["review"]["content_hash"] = "0" * 64
    path = tmp_path / "item.json"
    path.write_text(json.dumps(envelope), encoding="utf-8")

    changed = seal_directory(tmp_path)

    assert changed == ["item.json"]
    sealed = json.loads(path.read_text(encoding="utf-8"))
    assert sealed["review"]["content_hash"] == compute_pilot_content_hash(sealed)
