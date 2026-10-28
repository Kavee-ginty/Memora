from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path

import pytest

from memora.modules.curriculum.seed_data import CONCEPTS_DATA, LEARNING_OBJECTIVES

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "content/physics/pilot/candidate_mappings.json"
QUESTIONS = ROOT / "content/physics/pilot/PILOT_QUESTIONS.md"
SUMMARY_ROW = re.compile(r"^\| `(PILOT-PHYS-[0-9]{4}-P1-Q[0-9]{1,2})` \|", re.MULTILINE)


def load_report() -> dict[str, object]:
    return json.loads(REPORT.read_text(encoding="utf-8"))


def summary_rows() -> dict[str, tuple[str, str, str]]:
    rows: dict[str, tuple[str, str, str]] = {}
    for line in QUESTIONS.read_text(encoding="utf-8").splitlines():
        match = SUMMARY_ROW.match(line)
        if match is None:
            continue
        columns = [column.strip() for column in line.strip().strip("|").split("|")]
        rows[match.group(1)] = (columns[3], columns[5], columns[6])
    return rows


def expected_status(label: str) -> str:
    if label.startswith("complete:"):
        return "complete"
    if label.startswith("blocked:"):
        return "missing"
    if label.startswith("weak:"):
        return "partial"
    pytest.fail(f"Unknown mapping status label: {label!r}")


def seed_index() -> dict[str, dict[str, object]]:
    return {str(concept["stable_code"]): concept for concept in CONCEPTS_DATA}


def objective_ids() -> dict[str, str]:
    return {
        str(objective["objective_code"]): str(objective["id"]) for objective in LEARNING_OBJECTIVES
    }


def candidates(report: dict[str, object]) -> list[dict[str, object]]:
    value = report["candidates"]
    assert isinstance(value, list)
    return value


def test_report_covers_every_candidate_and_matches_summary() -> None:
    report = load_report()
    rows = summary_rows()
    entries = candidates(report)

    assert report["candidate_count"] == 8
    assert len(entries) == 8
    assert len({entry["pilot_id"] for entry in entries}) == 8
    assert {entry["pilot_id"] for entry in entries} == set(rows)

    statuses = Counter(str(entry["mapping_status"]) for entry in entries)
    assert dict(statuses) == report["status_counts"]
    assert sum(statuses.values()) == report["candidate_count"]

    for entry in entries:
        topic, label, _review = rows[entry["pilot_id"]]
        assert entry["source_topic"] == topic
        assert entry["mapping_status"] == expected_status(label)


def test_existing_mappings_resolve_to_t08_concepts_objectives_and_claims() -> None:
    seed = seed_index()
    objectives = objective_ids()

    for entry in candidates(load_report()):
        mappings = entry["existing_concept_mappings"]
        assert isinstance(mappings, list)
        codes = [mapping["stable_code"] for mapping in mappings]
        assert len(codes) == len(set(codes)), entry["pilot_id"]

        for mapping in mappings:
            code = mapping["stable_code"]
            assert code in seed, f"{entry['pilot_id']} references unknown T08 code {code}"
            concept = seed[code]

            assert mapping["concept_version_id"] == concept["version_id"]
            assert mapping["objective_code"] == concept["objective_code"]
            assert mapping["learning_objective_id"] == objectives[concept["objective_code"]]
            assert mapping["mapping_role"] in {
                "primary",
                "supporting",
                "prerequisite",
                "misconception",
            }
            assert 0 <= mapping["proposed_weight"] <= 1
            assert mapping["mapping_basis"].strip()

            claim_ids = {claim["claim_id"] for claim in concept["claims"]}
            assert mapping["claim_ids"]
            assert set(mapping["claim_ids"]) <= claim_ids


def test_mapping_status_matches_primary_evidence_and_missing_topics() -> None:
    for entry in candidates(load_report()):
        mappings = entry["existing_concept_mappings"]
        has_primary = any(mapping["mapping_role"] == "primary" for mapping in mappings)
        missing = entry["missing_topics"]
        required = entry["required_evidence"]
        status = entry["mapping_status"]

        assert entry["has_primary_existing_concept"] is has_primary
        assert isinstance(missing, list)
        assert isinstance(required, list)
        assert entry["status_reason"].strip()

        if status == "complete":
            assert has_primary
            assert missing == []
            assert required == []
        elif status == "missing":
            assert not has_primary
            assert missing
            assert required
        else:
            assert status == "partial"
            assert missing
            assert required

        assert all(topic.strip() for topic in missing)
        assert all(item.strip() for item in required)


def test_projectile_gap_descriptions_match_the_candidate_topics() -> None:
    entries = {entry["pilot_id"]: entry for entry in candidates(load_report())}

    q05_topics = " ".join(entries["PILOT-PHYS-2025-P1-Q05"]["missing_topics"]).lower()
    q14_topics = " ".join(entries["PILOT-PHYS-2025-P1-Q14"]["missing_topics"]).lower()

    assert "projectile motion" in q05_topics
    assert "projectile motion" in q14_topics
    assert "independence of horizontal and vertical" in q14_topics
    assert "independence of horizontal and vertical" not in q05_topics


def test_q02_does_not_claim_dimensional_analysis_as_an_error_mapping() -> None:
    entries = {entry["pilot_id"]: entry for entry in candidates(load_report())}
    q02 = entries["PILOT-PHYS-2025-P1-Q02"]

    assert q02["existing_concept_mappings"] == []
    assert q02["has_primary_existing_concept"] is False
    assert q02["missing_topics"] == ["measurement uncertainty and percentage error"]
