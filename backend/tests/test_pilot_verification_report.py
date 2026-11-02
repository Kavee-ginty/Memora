from __future__ import annotations

import copy
import json
from pathlib import Path
from typing import Any

from memora.modules.questions.pilot_reports import (
    build_verification_report,
    render_question_document,
)
from memora.modules.questions.pilot_validation import (
    compute_pilot_content_hash,
    load_pilot_envelopes,
)

ROOT = Path(__file__).resolve().parents[2]
PILOT = ROOT / "content/physics/pilot"
REPORT = PILOT / "verification_report.json"
QUESTIONS = PILOT / "questions"
DOCUMENT = PILOT / "PILOT_QUESTIONS.md"


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def report() -> dict[str, Any]:
    return load(REPORT)


def test_report_is_current_and_deterministic() -> None:
    assert report() == build_verification_report(load_pilot_envelopes(QUESTIONS))


def test_report_claims_official_verification_without_a_human_review() -> None:
    checked = report()

    assert checked["schema_version"] == "2.0"
    assert checked["verification_authority"].startswith("official Department of Examinations")
    assert checked["human_review_claimed"] is False
    assert checked["question_count"] == 8
    assert checked["summary"] == {
        "all_verified": True,
        "all_hashes_match": True,
        "all_import_blocked": True,
        "status_counts": {"verified": 8},
        "question_counts_by_year": {"2022": 2, "2024": 3, "2025": 3},
    }


def test_every_row_agrees_with_its_sealed_envelope() -> None:
    rows = {row["pilot_id"]: row for row in report()["questions"]}

    for envelope in load_pilot_envelopes(QUESTIONS):
        row = rows[envelope["pilot_id"]]
        source = envelope["source"]
        answer = envelope["answer_verification"]
        review = envelope["review"]
        publication = envelope["publication"]

        assert row["exam_year"] == source["exam_year"]
        assert row["question_number"] == source["question_number"]
        assert row["official_key"] == source["official_key"] == answer["official_key"]
        assert row["derived_option_key"] == answer["derived_option_key"]
        assert row["matches_official_key"] is True
        assert row["content_hash"] == review["content_hash"]
        assert row["content_hash_recomputed"] == compute_pilot_content_hash(envelope)
        assert row["publication_import_status"] == publication["import_status"]
        assert row["approved_for_import"] is False
        assert row["status"] == "verified"


def test_a_changed_answer_or_content_fails_the_report_status() -> None:
    envelopes = load_pilot_envelopes(QUESTIONS)

    changed_key = copy.deepcopy(envelopes[0])
    changed_key["answer_verification"]["official_key"] = 2

    changed_option = copy.deepcopy(envelopes[0])
    changed_option["answer_verification"]["derived_option_key"] = "2"

    changed_prompt = copy.deepcopy(envelopes[0])
    changed_prompt["question"]["prompt"] += " Changed."

    assert build_verification_report([changed_key])["questions"][0]["status"] == (
        "official_key_mismatch"
    )
    assert build_verification_report([changed_option])["questions"][0]["status"] == (
        "derived_key_mismatch"
    )
    assert build_verification_report([changed_prompt])["questions"][0]["status"] == (
        "content_hash_mismatch"
    )


def test_question_document_is_generated_from_the_envelopes() -> None:
    document = DOCUMENT.read_text(encoding="utf-8")

    assert document == render_question_document(load_pilot_envelopes(QUESTIONS))


def test_question_document_records_every_answer_and_residual_risk() -> None:
    document = DOCUMENT.read_text(encoding="utf-8")

    for envelope in load_pilot_envelopes(QUESTIONS):
        assert str(envelope["pilot_id"]) in document
        assert f"**Official key:** {envelope['source']['official_key']}" in document
        assert envelope["review"]["content_hash"] in document

    assert "No teacher, reviewer or verifier identity is claimed." in document
    assert "The phrase 'length of the spring' could be read" in document
    assert "**Counts:** 8 questions; 11 of 14 T08 concepts covered; 3 explicit gaps." in document
