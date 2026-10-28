from __future__ import annotations

import json
import re
from pathlib import Path

import pytest

from memora.modules.curriculum.seed_data import CONCEPTS_DATA

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "content/physics/pilot/candidate_mappings.json"
QUESTIONS = ROOT / "content/physics/pilot/PILOT_QUESTIONS.md"
SUMMARY_ROW = re.compile(r"^\| `(PILOT-PHYS-[0-9]{4}-P1-Q[0-9]{1,2})` \|", re.MULTILINE)


def load_report() -> dict[str, object]:
    return json.loads(REPORT.read_text(encoding="utf-8"))


def summary_rows() -> dict[str, tuple[str, str]]:
    rows: dict[str, tuple[str, str]] = {}
    for line in QUESTIONS.read_text(encoding="utf-8").splitlines():
        match = SUMMARY_ROW.match(line)
        if match is None:
            continue
        columns = [column.strip() for column in line.strip().strip("|").split("|")]
        rows[match.group(1)] = (columns[5], columns[6])
    return rows


def expected_status(label: str) -> str:
    if label.startswith("complete:"):
        return "complete"
    if label.startswith("blocked:"):
        return "missing"
    if label.startswith("weak:"):
        return "partial"
    pytest.fail(f"Unknown mapping status label: {label!r}")


def test_report_covers_every_candidate_and_matches_summary() -> None:
    report = load_report()
    candidates = report["candidates"]
    assert isinstance(candidates, list)
    assert len(candidates) == 8

    ids = [candidate["pilot_id"] for candidate in candidates]
    assert len(set(ids)) == 8
    assert set(ids) == set(summary_rows())

    for candidate in candidates:
        summary = summary_rows()[candidate["pilot_id"]]
        assert candidate["mapping_status"] == expected_status(summary[0])


def test_referenced_codes_resolve_to_existing_t08_concepts() -> None:
    known_codes = {concept["stable_code"] for concept in CONCEPTS_DATA}
    report = load_report()

    for candidate in report["candidates"]:
        codes = candidate["referenced_existing_concepts"]
        assert len(codes) == len(set(codes))
        for code in codes:
            assert code in known_codes, (
                f"{candidate['pilot_id']} references unknown T08 code {code}"
            )


def test_mapping_status_does_not_hide_missing_or_invalid_mappings() -> None:
    report = load_report()
    candidates = report["candidates"]

    for candidate in candidates:
        status = candidate["mapping_status"]
        has_primary = candidate["has_primary_existing_concept"]
        missing = candidate["missing_topics"]

        assert status in {"complete", "partial", "missing"}
        assert isinstance(has_primary, bool)
        assert isinstance(missing, list)

        if status == "complete":
            assert has_primary is True
            assert missing == []
        elif status == "missing":
            assert has_primary is False
            assert missing
        else:
            assert missing

    complete = [c for c in candidates if c["mapping_status"] == "complete"]
    assert len(complete) == 1
    assert complete[0]["pilot_id"] == "PILOT-PHYS-2025-P1-Q01"
