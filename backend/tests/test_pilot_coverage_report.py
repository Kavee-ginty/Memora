from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from memora.modules.curriculum.seed_data import CONCEPTS_DATA, LEARNING_OBJECTIVES
from memora.modules.questions.pilot_reports import build_coverage_report
from memora.modules.questions.pilot_validation import load_pilot_envelopes

ROOT = Path(__file__).resolve().parents[2]
PILOT = ROOT / "content/physics/pilot"
REPORT = PILOT / "coverage_report.json"
QUESTIONS = PILOT / "questions"
EXPECTED_GAPS = {"PHYS-MEC-DISPLACEMENT", "PHYS-MEC-VELOCITY", "PHYS-MEC-NEWTON1"}


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def report() -> dict[str, Any]:
    return load(REPORT)


def test_report_is_current_and_deterministic() -> None:
    assert report() == build_coverage_report(load_pilot_envelopes(QUESTIONS))


def test_summary_counts_are_the_pilot_contract() -> None:
    summary = report()["summary"]

    assert report()["schema_version"] == "2.0"
    assert report()["question_count"] == 8
    assert report()["source_years"] == [2022, 2024, 2025]
    assert summary == {
        "concepts_total": 14,
        "concepts_covered": 11,
        "concepts_gap": 3,
        "leaf_objectives_total": 6,
        "leaf_objectives_covered": 6,
    }


def test_every_t08_concept_appears_once_with_truthful_coverage() -> None:
    coverage = report()["concepts"]
    seed_codes = {str(concept["stable_code"]) for concept in CONCEPTS_DATA}

    assert len(coverage) == 14
    assert {entry["stable_code"] for entry in coverage} == seed_codes
    assert len({entry["concept_version_id"] for entry in coverage}) == 14

    for entry in coverage:
        assert entry["question_count"] == len(entry["question_ids"])
        assert entry["coverage_status"] == ("covered" if entry["question_ids"] else "gap")
        assert entry["mapping_roles"] == sorted(set(entry["mapping_roles"]))


def test_gaps_are_explicit_and_have_no_hidden_questions() -> None:
    gaps = report()["gaps"]

    assert {gap["stable_code"] for gap in gaps} == EXPECTED_GAPS
    assert all(gap["reason"].strip() for gap in gaps)
    for entry in report()["concepts"]:
        if entry["stable_code"] in EXPECTED_GAPS:
            assert entry["coverage_status"] == "gap"
            assert entry["question_ids"] == []


def test_covered_concepts_reference_real_questions() -> None:
    question_ids = {str(envelope["pilot_id"]) for envelope in load_pilot_envelopes(QUESTIONS)}

    for entry in report()["concepts"]:
        assert set(entry["question_ids"]) <= question_ids
        if entry["question_ids"]:
            assert entry["coverage_status"] == "covered"


def test_every_objective_is_classified_without_claiming_direct_coverage() -> None:
    objectives = report()["objectives"]
    seed_codes = {str(objective["objective_code"]) for objective in LEARNING_OBJECTIVES}

    assert len(objectives) == len(LEARNING_OBJECTIVES)
    assert {entry["objective_code"] for entry in objectives} == seed_codes

    for entry in objectives:
        if entry["question_ids"]:
            assert entry["coverage_status"] == "covered_direct"
        elif entry["is_leaf"]:
            assert entry["coverage_status"] == "covered_by_descendant"
        else:
            assert entry["coverage_status"] == "covered_by_descendant"
        assert entry["question_count"] == len(entry["question_ids"])


def test_report_does_not_repeat_question_text_or_answers() -> None:
    serialized = json.dumps(report()).lower()

    assert '"prompt"' not in serialized
    assert '"options"' not in serialized
    assert '"official_key"' not in serialized
    assert '"derivation"' not in serialized
