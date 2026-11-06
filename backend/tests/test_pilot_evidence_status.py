from __future__ import annotations

import hashlib
import json
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PILOT = ROOT / "content/physics/pilot"
SOURCE_DOCUMENTS = ROOT / "content/physics/source_documents"
MANIFEST = PILOT / "source_manifest.json"
ANSWER_KEYS = PILOT / "official_answer_keys.json"
INVENTORY = PILOT / "SOURCE_INVENTORY.md"


def load(path: Path) -> dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def manifest() -> dict[str, object]:
    return load(MANIFEST)


def keys() -> dict[str, object]:
    return load(ANSWER_KEYS)


def sources() -> dict[str, dict[str, object]]:
    entries = manifest()["sources"]
    assert isinstance(entries, list)
    return {str(entry["filename"]): entry for entry in entries}


def selected_questions() -> list[dict[str, object]]:
    entries = manifest()["selected_questions"]
    assert isinstance(entries, list)
    return entries


def test_manifest_and_answer_key_versions_are_declared() -> None:
    assert manifest()["schema_version"] == "2.0"
    assert keys()["schema_version"] == "2.0"


def test_selected_sources_are_complete_and_unique() -> None:
    entries = sources()

    assert len(entries) == 7
    assert len({entry["sha256"] for entry in entries.values()}) == 7

    selected = {
        filename: entry for filename, entry in entries.items() if entry["selected_for_t24"] is True
    }
    assert len(selected) == 6
    assert {int(entry["exam_year"]) for entry in selected.values()} == {2022, 2024, 2025}

    for year in (2022, 2024, 2025):
        papers = [
            entry
            for entry in selected.values()
            if int(entry["exam_year"]) == year and entry["document_type"] == "past_paper"
        ]
        schemes = [
            entry
            for entry in selected.values()
            if int(entry["exam_year"]) == year and entry["document_type"] == "marking_scheme"
        ]
        assert len(papers) == 1
        assert len(schemes) == 1
        expected_page = 5 if year == 2024 else 2
        assert schemes[0]["mcq_answer_grid"]["present"] is True
        assert schemes[0]["mcq_answer_grid"]["pdf_page"] == expected_page
        assert schemes[0]["mcq_answer_grid"]["entry_count"] == 50

    syllabus = entries["AL_Physics_Syllabus_2017.pdf"]
    assert syllabus["document_type"] == "syllabus"
    assert syllabus["selected_for_t24"] is False


def test_every_selected_question_has_a_verified_answer_key() -> None:
    grid = keys()["keys"]
    assert isinstance(grid, dict)
    assert set(grid) == {"2022", "2024", "2025"}

    questions = selected_questions()
    assert len(questions) == 8
    assert len({str(question["pilot_id"]) for question in questions}) == 8

    for question in questions:
        year = str(question["exam_year"])
        number = int(question["question_number"])
        official_key = int(question["official_key"])
        answers = grid[year]["answers"]
        assert len(answers) == 50
        assert answers[number - 1] == official_key
        assert 1 <= official_key <= 5
        assert question["marking_scheme_pdf_page"] == grid[year]["pdf_page"]

    assert [question["pilot_id"] for question in questions] == [
        "PILOT-PHYS-2022-P1-Q01",
        "PILOT-PHYS-2022-P1-Q17",
        "PILOT-PHYS-2024-P1-Q01",
        "PILOT-PHYS-2024-P1-Q04",
        "PILOT-PHYS-2024-P1-Q05",
        "PILOT-PHYS-2025-P1-Q01",
        "PILOT-PHYS-2025-P1-Q03",
        "PILOT-PHYS-2025-P1-Q45",
    ]


def test_the_ambiguous_2025_cell_is_preserved_and_excluded() -> None:
    answers = keys()["keys"]["2025"]["answers"]

    assert answers[14] == "02/04"
    assert all(
        int(question["official_key"]) in range(1, 6)
        for question in selected_questions()
        if int(question["exam_year"]) == 2025
    )
    assert "2025 question 15" in INVENTORY.read_text(encoding="utf-8")


def test_selected_question_pages_match_the_manifest_sources() -> None:
    entries = sources()
    for question in selected_questions():
        year = int(question["exam_year"])
        paper = entries[f"AL_Physics_{year}_Combined_Paper_English.pdf"]
        scheme = entries[f"AL_Physics_{year}_Combined_Marking_Scheme_English.pdf"]
        assert int(question["exam_year"]) == int(paper["exam_year"])
        assert question["question_number"] <= 50
        assert int(question["paper_pdf_page"]) <= int(paper["pages"])
        assert int(question["marking_scheme_pdf_page"]) == int(
            scheme["mcq_answer_grid"]["pdf_page"]
        )


def test_excluded_years_are_explicit() -> None:
    excluded = manifest()["excluded_years"]
    assert isinstance(excluded, list)
    assert {int(entry["exam_year"]) for entry in excluded} == {2021, 2023}
    assert all(str(entry["reason"]).strip() for entry in excluded)


def test_inventory_names_every_selected_question_and_source() -> None:
    text = INVENTORY.read_text(encoding="utf-8")
    for question in selected_questions():
        assert str(question["pilot_id"]) in text
    for filename in sources():
        assert filename in text
    assert "REVIEW_RECORD.md" in text


def test_manifest_does_not_embed_question_or_source_text() -> None:
    serialized = json.dumps(manifest()).lower()
    assert '"prompt"' not in serialized
    assert '"options"' not in serialized
    assert '"derivation"' not in serialized


@pytest.mark.parametrize("filename", sorted(sources()))
def test_local_source_hash_matches_the_manifest_when_present(filename: str) -> None:
    path = SOURCE_DOCUMENTS / filename
    if not path.is_file():
        pytest.skip(f"Local source PDF is not present: {filename}")

    entry = sources()[filename]
    digest = hashlib.sha256(path.read_bytes()).hexdigest()

    assert digest == entry["sha256"]
    assert path.stat().st_size == entry["bytes"]
