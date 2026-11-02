from __future__ import annotations

import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator

from memora.modules.curriculum.seed_data import CONCEPTS_DATA, LEARNING_OBJECTIVES
from memora.modules.questions.pilot_validation import (
    compute_pilot_content_hash,
    load_pilot_envelopes,
)

ROOT = Path(__file__).resolve().parents[2]
PILOT = ROOT / "content/physics/pilot"
QUESTIONS = PILOT / "questions"
CONCEPTS = PILOT / "concepts.json"
SCHEMA = PILOT / "pilot_question.schema.json"
EXPECTED_GAPS = {"PHYS-MEC-DISPLACEMENT", "PHYS-MEC-VELOCITY", "PHYS-MEC-NEWTON1"}


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def envelopes() -> list[dict[str, Any]]:
    return load_pilot_envelopes(QUESTIONS)


def concept_brief() -> dict[str, Any]:
    return load(CONCEPTS)


def seed_by_code() -> dict[str, dict[str, Any]]:
    return {str(concept["stable_code"]): concept for concept in CONCEPTS_DATA}


def objectives_by_code() -> dict[str, dict[str, Any]]:
    return {str(objective["objective_code"]): objective for objective in LEARNING_OBJECTIVES}


def test_the_pilot_contains_the_eight_selected_envelopes() -> None:
    loaded = envelopes()

    assert len(loaded) == 8
    assert [envelope["pilot_id"] for envelope in loaded] == [
        "PILOT-PHYS-2022-P1-Q01",
        "PILOT-PHYS-2022-P1-Q17",
        "PILOT-PHYS-2024-P1-Q01",
        "PILOT-PHYS-2024-P1-Q04",
        "PILOT-PHYS-2024-P1-Q05",
        "PILOT-PHYS-2025-P1-Q01",
        "PILOT-PHYS-2025-P1-Q03",
        "PILOT-PHYS-2025-P1-Q45",
    ]


def test_every_checked_in_envelope_matches_the_schema() -> None:
    schema = load(SCHEMA)
    Draft202012Validator.check_schema(schema)
    validator = Draft202012Validator(schema)

    for envelope in envelopes():
        found = sorted(validator.iter_errors(envelope), key=lambda error: list(error.path))
        assert not found, [
            f"{envelope['pilot_id']} {list(error.path)}: {error.message}" for error in found
        ]


def test_every_envelope_is_sealed_with_its_content_hash() -> None:
    for envelope in envelopes():
        assert envelope["review"]["content_hash"] == compute_pilot_content_hash(envelope)
        assert len(envelope["review"]["content_hash"]) == 64


def test_every_mapping_resolves_to_a_t08_concept_and_objective() -> None:
    concepts = {str(concept["version_id"]): concept for concept in CONCEPTS_DATA}
    objectives = {str(objective["id"]): objective for objective in LEARNING_OBJECTIVES}

    for envelope in envelopes():
        mappings = envelope["question"]["concept_mappings"]
        assert len({mapping["concept_version_id"] for mapping in mappings}) == len(mappings)
        assert sum(1 for mapping in mappings if mapping["mapping_role"] == "primary") == 1

        for mapping in mappings:
            concept = concepts[str(mapping["concept_version_id"])]
            objective = objectives[str(mapping["learning_objective_id"])]
            assert objective["objective_code"] == concept["objective_code"]
            assert mapping["provenance_type"] in {"analyst_mapping", "source_analysis"}
            assert mapping["provenance_ref"].startswith(
                f"SL-DOE-AL-PHYS-{envelope['source']['exam_year']}-P1"
            )
            assert 0 <= mapping["weight"] <= 1


def test_official_mode_envelopes_do_not_claim_human_review() -> None:
    for envelope in envelopes():
        assert envelope["verification_mode"] == "official_marking_scheme"
        assert envelope["question"]["author_principal"] is None
        assert envelope["question"]["reviewer_principal"] is None
        assert envelope["answer_verification"]["independent_review_status"] == "not_required"
        assert envelope["review"]["academic_review_status"] == "not_required"
        assert envelope["review"]["reviewer_principal"] is None
        assert (
            envelope["review"]["deviation_ref"] == "content/physics/pilot/DEVIATION_REVIEW_MODE.md"
        )
        assert envelope["publication"]["approved_for_import"] is False


def test_source_excerpts_are_short_enough_to_be_questions_not_papers() -> None:
    for envelope in envelopes():
        assert len(envelope["question"]["prompt"]) < 1500
        assert len(envelope["question"]["explanation"]) < 1500
        assert len(envelope["answer_verification"]["derivation"]) < 1500


def test_concept_brief_covers_every_t08_concept() -> None:
    brief = concept_brief()
    entries = brief["concepts"]
    seed = seed_by_code()

    assert brief["schema_version"] == "2.0"
    assert brief["concept_count"] == len(CONCEPTS_DATA) == 14
    assert {entry["stable_code"] for entry in entries} == set(seed)

    for entry in entries:
        concept = seed[entry["stable_code"]]
        assert entry["concept_id"] == str(concept["concept_id"])
        assert entry["concept_version_id"] == str(concept["version_id"])
        assert entry["title"] == concept["title"]
        assert entry["objective_code"] == concept["objective_code"]
        assert entry["definition"].strip()
        assert entry["formula"] or entry["unit"] or entry["dimensions"]
        assert entry["claims"]

        concept_codes = set(seed)
        for prerequisite in entry["prerequisites"]:
            assert prerequisite in concept_codes, entry["stable_code"]
            assert prerequisite != entry["stable_code"]

        for claim in entry["claims"]:
            assert claim["claim_id"]
            assert claim["claim_type"]
            assert claim["statement"].strip()


def test_concept_brief_coverage_matches_the_envelopes() -> None:
    brief = concept_brief()
    loaded = envelopes()
    question_ids: dict[str, set[str]] = defaultdict(set)
    roles: dict[str, set[str]] = defaultdict(set)
    for envelope in loaded:
        for mapping in envelope["question"]["concept_mappings"]:
            question_ids[str(mapping["concept_version_id"])].add(str(envelope["pilot_id"]))
            roles[str(mapping["concept_version_id"])].add(str(mapping["mapping_role"]))

    for entry in brief["concepts"]:
        expected_questions = sorted(question_ids.get(entry["concept_version_id"], set()))
        assert entry["question_ids"] == expected_questions
        assert entry["mapping_roles"] == sorted(roles.get(entry["concept_version_id"], set()))
        expected_status = "covered" if expected_questions else "gap"
        assert entry["pilot_status"] == expected_status

    covered = sum(1 for entry in brief["concepts"] if entry["pilot_status"] == "covered")
    gaps = {entry["stable_code"] for entry in brief["concepts"] if entry["pilot_status"] == "gap"}
    assert brief["covered_count"] == covered == 11
    assert brief["gap_count"] == len(gaps) == 3
    assert gaps == EXPECTED_GAPS


def test_every_pilot_question_has_exactly_one_primary_concept() -> None:
    counts = Counter(
        str(mapping["concept_version_id"])
        for envelope in envelopes()
        for mapping in envelope["question"]["concept_mappings"]
        if mapping["mapping_role"] == "primary"
    )

    assert sum(counts.values()) == 8
    assert set(counts) == {
        "50000000-0000-0000-0000-000000000002",
        "50000000-0000-0000-0000-000000000006",
        "50000000-0000-0000-0000-000000000009",
        "50000000-0000-0000-0000-000000000010",
        "50000000-0000-0000-0000-000000000014",
    }


def test_every_question_maps_to_a_leaf_objective() -> None:
    objectives = objectives_by_code()
    for envelope in envelopes():
        for mapping in envelope["question"]["concept_mappings"]:
            concepts = {str(concept["version_id"]): concept for concept in CONCEPTS_DATA}
            concept = concepts[str(mapping["concept_version_id"])]
            objective = objectives[concept["objective_code"]]
            assert objective["parent_objective_code"] is not None
