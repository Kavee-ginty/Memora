from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from memora.modules.questions.pilot_reports import (
    DUPLICATE_THRESHOLD,
    build_duplicate_report,
)
from memora.modules.questions.pilot_validation import load_pilot_envelopes

ROOT = Path(__file__).resolve().parents[2]
PILOT = ROOT / "content/physics/pilot"
REPORT = PILOT / "duplicate_report.json"
QUESTIONS = PILOT / "questions"


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def report() -> dict[str, Any]:
    return load(REPORT)


def minimal(pilot_id: str, prompt: str, code: str = "code") -> dict[str, Any]:
    return {
        "pilot_id": pilot_id,
        "source": {"source_id": "SYNTHETIC-T24-DUPLICATE", "question_number": 1},
        "question": {
            "question_code": code,
            "prompt": prompt,
            "options": ["alpha", "beta", "gamma", "delta", "epsilon"],
        },
    }


def test_report_is_current_and_deterministic() -> None:
    assert report() == build_duplicate_report(load_pilot_envelopes(QUESTIONS))


def test_checked_in_pilot_has_no_deterministic_duplicate_signal() -> None:
    checked = report()

    assert checked["schema_version"] == "2.0"
    assert checked["question_count"] == 8
    assert checked["threshold"] == DUPLICATE_THRESHOLD
    assert checked["status"] == "clear"
    assert checked["summary"] == {
        "pairs_compared": 28,
        "exact_duplicate_groups": 0,
        "near_duplicate_pairs": 0,
        "duplicate_source_questions": 0,
        "duplicate_question_codes": 0,
        "highest_similarity": 0.469136,
        "highest_similarity_pair": [
            "PILOT-PHYS-2022-P1-Q01",
            "PILOT-PHYS-2024-P1-Q01",
        ],
    }
    assert checked["exact_duplicate_groups"] == []
    assert checked["near_duplicate_pairs"] == []
    assert checked["duplicate_source_questions"] == []
    assert checked["duplicate_question_codes"] == []


def test_report_does_not_repeat_prompts_or_options() -> None:
    serialized = json.dumps(report())
    for envelope in load_pilot_envelopes(QUESTIONS):
        candidates = [envelope["question"]["prompt"]]
        candidates.extend(option["display_text"] for option in envelope["question"]["options"])
        for text in candidates:
            if len(text) >= 8:
                assert text not in serialized


def test_exact_normalised_prompt_duplicate_is_flagged() -> None:
    first = minimal("PILOT-PHYS-2025-P1-Q01", "Which  one is correct?", "first")
    second = minimal("PILOT-PHYS-2025-P1-Q02", "which one is correct", "second")

    checked = build_duplicate_report([first, second])

    assert checked["status"] == "review_required"
    assert len(checked["exact_duplicate_groups"]) == 1
    assert checked["exact_duplicate_groups"][0]["pilot_ids"] == [
        "PILOT-PHYS-2025-P1-Q01",
        "PILOT-PHYS-2025-P1-Q02",
    ]


def test_near_duplicate_pair_is_a_screening_signal() -> None:
    first = minimal(
        "PILOT-PHYS-2025-P1-Q01",
        "A block moves on a smooth horizontal surface with constant velocity.",
        "first",
    )
    second = minimal(
        "PILOT-PHYS-2025-P1-Q02",
        "A block moves on a smooth horizontal surface with constant speed.",
        "second",
    )

    checked = build_duplicate_report([first, second])

    assert checked["status"] == "review_required"
    assert checked["near_duplicate_pairs"]
    assert checked["near_duplicate_pairs"][0]["prompt_similarity"] >= DUPLICATE_THRESHOLD


def test_duplicate_source_question_and_question_code_are_flagged() -> None:
    first = minimal("PILOT-PHYS-2025-P1-Q01", "First distinct prompt.", "same-code")
    second = minimal("PILOT-PHYS-2025-P1-Q02", "Second distinct prompt.", "same-code")

    checked = build_duplicate_report([first, second])

    assert checked["status"] == "review_required"
    assert checked["duplicate_source_questions"] == [
        {
            "source_id": "SYNTHETIC-T24-DUPLICATE",
            "question_number": 1,
            "count": 2,
        }
    ]
    assert checked["duplicate_question_codes"] == [{"question_code": "same-code", "count": 2}]


def test_similarity_pairs_are_sorted_and_keep_ids_only() -> None:
    first = minimal("PILOT-PHYS-2025-P1-Q01", "Alpha beta gamma.", "first")
    second = minimal("PILOT-PHYS-2025-P1-Q02", "Alpha beta delta.", "second")
    third = minimal("PILOT-PHYS-2025-P1-Q03", "Unrelated wording.", "third")

    checked = build_duplicate_report([first, second, third])

    assert len(checked["pairs"]) == 3
    assert checked["pairs"][0]["left"] == "PILOT-PHYS-2025-P1-Q01"
    assert checked["pairs"][0]["right"] == "PILOT-PHYS-2025-P1-Q02"
    for pair in checked["pairs"]:
        assert set(pair) == {"left", "right", "prompt_similarity"}
        assert 0 <= pair["prompt_similarity"] <= 1
