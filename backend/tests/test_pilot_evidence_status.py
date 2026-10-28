from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "content/physics/pilot/evidence_status.json"
MAPPINGS = ROOT / "content/physics/pilot/candidate_mappings.json"
MANIFEST = ROOT / "content/physics/pilot/source_manifest.json"
QUESTIONS = ROOT / "content/physics/pilot/PILOT_QUESTIONS.md"
SUMMARY_ROW = re.compile(r"^\| `(PILOT-PHYS-[0-9]{4}-P1-Q[0-9]{1,2})` \|", re.MULTILINE)
ALLOWED = {"verified", "missing", "pending_human_review", "blocked"}


def load(path: Path) -> dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def candidate_ids() -> set[str]:
    return {
        match.group(1)
        for line in QUESTIONS.read_text(encoding="utf-8").splitlines()
        if (match := SUMMARY_ROW.match(line)) is not None
    }


def manifest_files() -> dict[str, dict[str, object]]:
    manifest = load(MANIFEST)
    files = manifest["files"]
    assert isinstance(files, list)
    return {str(entry["filename"]): entry for entry in files}


def candidates(report: dict[str, object]) -> list[dict[str, object]]:
    value = report["candidates"]
    assert isinstance(value, list)
    return value


def mapping_candidates() -> dict[str, dict[str, object]]:
    report = load(MAPPINGS)
    entries = candidates(report)
    return {str(entry["pilot_id"]): entry for entry in entries}


def test_report_schema_versions_are_declared() -> None:
    assert load(REPORT)["schema_version"] == "1.0"
    assert load(MAPPINGS)["schema_version"] == "1.1"


def test_reports_agree_on_candidate_ids_and_concept_gap_blocker() -> None:
    evidence = candidates(load(REPORT))
    mappings = mapping_candidates()

    assert len(evidence) == len(mappings)
    assert {str(entry["pilot_id"]) for entry in evidence} == set(mappings)
    assert set(mappings) == candidate_ids()

    for entry in evidence:
        mapping = mappings[str(entry["pilot_id"])]
        requires_concept_gap = mapping["mapping_status"] != "complete"
        assert ("B4" in entry["blocker_ids"]) is requires_concept_gap


def test_report_covers_every_candidate() -> None:
    report = load(REPORT)
    entries = candidates(report)
    ids = {str(entry["pilot_id"]) for entry in entries}

    assert len(entries) == 8
    assert len(ids) == 8
    assert ids == candidate_ids()


def test_source_and_marking_scheme_hashes_match_the_manifest() -> None:
    files = manifest_files()

    for entry in candidates(load(REPORT)):
        source = entry["source"]
        marking = entry["marking_scheme"]

        source_file = files[source["document_filename"]]
        assert source_file["document_type"] == "past_paper"
        assert source_file["language"] == "English"
        assert source_file["exam_year"] == source["exam_year"]
        assert source_file["sha256"] == source["document_sha256"]
        assert source["paper"] == "Paper I"
        assert str(source["source_id"]).endswith(f"-{source['exam_year']}-P1")

        marking_file = files[marking["document_filename"]]
        assert marking_file["document_type"] == "marking_scheme"
        assert marking_file["exam_year"] == source["exam_year"]
        assert marking_file["sha256"] == marking["document_sha256"]
        assert marking["mcq_key_present"] is False
        assert "not an mcq answer grid" in str(marking_file["notes"]).lower()


def test_evidence_statuses_are_truthful_and_every_candidate_is_blocked() -> None:
    report = load(REPORT)
    allowed = set(report["status_values"])
    blocker_ids = {blocker["id"] for blocker in report["global_blockers"]}

    assert allowed == ALLOWED

    for entry in candidates(report):
        statuses = entry["evidence_status"]
        assert entry["overall_status"] == "blocked"
        assert set(statuses.values()) <= ALLOWED
        assert statuses["source_file_identity"] == "verified"
        assert statuses["source_authenticity"] != "verified"
        assert statuses["official_answer_key"] == "missing"
        assert statuses["reproduction_rights"] == "blocked"
        assert statuses["author_identity"] == "missing"
        assert statuses["author_qualification"] == "missing"
        assert statuses["reviewer_identity_and_qualification"] == "missing"
        assert statuses["independent_answer_review"] == "missing"
        assert statuses["approval_record"] == "missing"
        assert entry["derived_option_key"]
        assert entry["blocker_ids"]
        assert set(entry["blocker_ids"]) <= blocker_ids


def test_global_blockers_have_an_owner_status_and_action() -> None:
    report = load(REPORT)
    blockers = report["global_blockers"]
    ids = [blocker["id"] for blocker in blockers]

    assert len(ids) == len(set(ids))
    assert len(ids) >= 5
    for blocker in blockers:
        assert blocker["owner"].strip()
        assert blocker["action"].strip()
        assert blocker["status"] in ALLOWED
        assert blocker["status"] in {"blocked", "pending_human_review"}

    assert {"B1", "B2", "B3", "B4", "B7"} <= set(ids)
    assert {"B5", "B6"} <= set(ids)
