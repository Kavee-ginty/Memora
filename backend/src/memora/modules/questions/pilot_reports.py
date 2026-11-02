"""Deterministic T24 pilot coverage, duplicate and verification reports.

The reports are read-only evidence. They do not approve content, create a human
reviewer, or open the T12 import gate. They make the official-key verification,
concept coverage and duplicate checks reproducible from the sealed envelopes.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from collections.abc import Mapping, Sequence
from difflib import SequenceMatcher
from pathlib import Path
from typing import Any

from memora.modules.curriculum.seed_data import CONCEPTS_DATA, LEARNING_OBJECTIVES
from memora.modules.questions.pilot_validation import (
    compute_pilot_content_hash,
    load_pilot_envelopes,
)

REPORT_SCHEMA_VERSION = "2.0"
REPORT_DATE = "2026-11-02"
DUPLICATE_THRESHOLD = 0.9
DEFAULT_PILOT_ROOT = Path("content/physics/pilot")
DEFAULT_COVERAGE_PATH = DEFAULT_PILOT_ROOT / "coverage_report.json"
DEFAULT_DUPLICATE_PATH = DEFAULT_PILOT_ROOT / "duplicate_report.json"
DEFAULT_VERIFICATION_PATH = DEFAULT_PILOT_ROOT / "verification_report.json"
DEFAULT_QUESTIONS_DOC_PATH = DEFAULT_PILOT_ROOT / "PILOT_QUESTIONS.md"

_OBJECTIVE_BY_CODE = {
    str(objective["objective_code"]): objective for objective in LEARNING_OBJECTIVES
}
_CONCEPT_BY_VERSION = {str(concept["version_id"]): concept for concept in CONCEPTS_DATA}


def _concept_version_id(concept: Mapping[str, Any]) -> str:
    return str(concept["version_id"])


def _question_rows(envelopes: Sequence[Mapping[str, Any]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for envelope in envelopes:
        rows.append(
            {
                "pilot_id": str(envelope["pilot_id"]),
                "exam_year": int(envelope["source"]["exam_year"]),
                "question_number": int(envelope["source"]["question_number"]),
                "official_key": int(envelope["source"]["official_key"]),
                "derived_option_key": str(envelope["answer_verification"]["derived_option_key"]),
                "concept_version_ids": [
                    str(mapping["concept_version_id"])
                    for mapping in envelope["question"]["concept_mappings"]
                ],
            }
        )
    return rows


def build_coverage_report(envelopes: Sequence[Mapping[str, Any]]) -> dict[str, Any]:
    """Build a deterministic T08 concept and objective coverage report."""

    rows = _question_rows(envelopes)
    question_by_concept: dict[str, list[str]] = defaultdict(list)
    role_by_concept: dict[str, set[str]] = defaultdict(set)
    for envelope, row in zip(envelopes, rows, strict=True):
        for mapping in envelope["question"]["concept_mappings"]:
            concept_id = str(mapping["concept_version_id"])
            question_by_concept[concept_id].append(row["pilot_id"])
            role_by_concept[concept_id].add(str(mapping["mapping_role"]))

    concepts: list[dict[str, Any]] = []
    for concept in CONCEPTS_DATA:
        concept_id = _concept_version_id(concept)
        question_ids = sorted(set(question_by_concept.get(concept_id, [])))
        concepts.append(
            {
                "stable_code": str(concept["stable_code"]),
                "concept_version_id": concept_id,
                "title": str(concept["title"]),
                "objective_code": str(concept["objective_code"]),
                "question_count": len(question_ids),
                "question_ids": question_ids,
                "mapping_roles": sorted(role_by_concept.get(concept_id, set())),
                "coverage_status": "covered" if question_ids else "gap",
            }
        )

    concept_by_objective: dict[str, list[str]] = defaultdict(list)
    for concept in CONCEPTS_DATA:
        concept_by_objective[str(concept["objective_code"])].append(_concept_version_id(concept))
    covered_concept_ids = {
        concept_id for concept_id, question_ids in question_by_concept.items() if question_ids
    }
    objectives: list[dict[str, Any]] = []
    for objective in LEARNING_OBJECTIVES:
        objective_code = str(objective["objective_code"])
        child_concepts = concept_by_objective.get(objective_code, [])
        covered_children = [
            concept_id for concept_id in child_concepts if concept_id in covered_concept_ids
        ]
        direct_questions = sorted(
            {
                question_id
                for concept_id in covered_children
                for question_id in question_by_concept.get(concept_id, [])
            }
        )
        child_objectives = [
            str(child["objective_code"])
            for child in LEARNING_OBJECTIVES
            if child.get("parent_objective_code") == objective_code
        ]
        child_covered = any(
            any(
                concept_id in covered_concept_ids
                for concept_id in concept_by_objective.get(child_code, [])
            )
            for child_code in child_objectives
        )
        if direct_questions:
            coverage_status = "covered_direct"
        elif child_covered:
            coverage_status = "covered_by_descendant"
        else:
            coverage_status = "not_covered"
        objectives.append(
            {
                "objective_code": objective_code,
                "objective_id": str(objective["id"]),
                "title": str(objective["title"]),
                "parent_objective_code": objective.get("parent_objective_code"),
                "is_leaf": objective.get("parent_objective_code") is not None,
                "question_count": len(direct_questions),
                "question_ids": direct_questions,
                "coverage_status": coverage_status,
            }
        )

    gaps = [
        {
            "stable_code": concept["stable_code"],
            "title": concept["title"],
            "objective_code": concept["objective_code"],
            "reason": "No selected past-paper MCQ maps to this T08 concept.",
        }
        for concept in concepts
        if concept["coverage_status"] == "gap"
    ]
    covered_count = sum(1 for concept in concepts if concept["coverage_status"] == "covered")
    leaf_objectives = [objective for objective in objectives if objective["is_leaf"]]
    covered_leaf_objectives = [
        objective
        for objective in leaf_objectives
        if objective["coverage_status"] == "covered_direct"
    ]
    source_years = sorted({row["exam_year"] for row in rows})
    return {
        "schema_version": REPORT_SCHEMA_VERSION,
        "generated_at": REPORT_DATE,
        "source": "sealed envelopes under content/physics/pilot/questions/",
        "question_count": len(envelopes),
        "source_years": source_years,
        "summary": {
            "concepts_total": len(concepts),
            "concepts_covered": covered_count,
            "concepts_gap": len(gaps),
            "leaf_objectives_total": len(leaf_objectives),
            "leaf_objectives_covered": len(covered_leaf_objectives),
        },
        "concepts": concepts,
        "objectives": objectives,
        "gaps": gaps,
        "notes": [
            "Coverage means at least one sealed pilot question maps to the T08 concept; "
            "it is not a claim of full syllabus coverage.",
            "The three gaps are deliberate: the selected Paper I MCQs do not address "
            "displacement, velocity or Newton's first law directly.",
            "No private student content is present.",
        ],
    }


def _normalise_prompt(text: str) -> str:
    text = text.casefold()
    text = re.sub(r"[^a-z0-9\s]", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def build_duplicate_report(envelopes: Sequence[Mapping[str, Any]]) -> dict[str, Any]:
    """Compare every pair of prompts and check source/question identity."""

    normalised = {
        str(envelope["pilot_id"]): _normalise_prompt(str(envelope["question"]["prompt"]))
        for envelope in envelopes
    }
    pairs: list[dict[str, Any]] = []
    exact_groups: dict[str, list[str]] = defaultdict(list)
    for pilot_id, text in normalised.items():
        exact_groups[text].append(pilot_id)
    exact_duplicates = [
        {"normalised_prompt": text, "pilot_ids": sorted(ids)}
        for text, ids in exact_groups.items()
        if len(ids) > 1
    ]

    ids = sorted(normalised)
    for index, left in enumerate(ids):
        for right in ids[index + 1 :]:
            ratio = SequenceMatcher(None, normalised[left], normalised[right]).ratio()
            pairs.append(
                {
                    "left": left,
                    "right": right,
                    "prompt_similarity": round(ratio, 6),
                }
            )
    pairs.sort(key=lambda pair: (-pair["prompt_similarity"], pair["left"], pair["right"]))
    near_duplicates = [pair for pair in pairs if pair["prompt_similarity"] >= DUPLICATE_THRESHOLD]

    source_keys = Counter(
        (
            str(envelope["source"]["source_id"]),
            int(envelope["source"]["question_number"]),
        )
        for envelope in envelopes
    )
    source_duplicates = [
        {"source_id": source_id, "question_number": number, "count": count}
        for (source_id, number), count in sorted(source_keys.items())
        if count > 1
    ]
    question_codes = Counter(str(envelope["question"]["question_code"]) for envelope in envelopes)
    code_duplicates = [
        {"question_code": code, "count": count}
        for code, count in sorted(question_codes.items())
        if count > 1
    ]
    status = (
        "clear"
        if not exact_duplicates
        and not near_duplicates
        and not source_duplicates
        and not code_duplicates
        else "review_required"
    )
    highest = pairs[0] if pairs else None
    return {
        "schema_version": REPORT_SCHEMA_VERSION,
        "generated_at": REPORT_DATE,
        "source": "sealed envelopes under content/physics/pilot/questions/",
        "question_count": len(envelopes),
        "threshold": DUPLICATE_THRESHOLD,
        "status": status,
        "summary": {
            "pairs_compared": len(pairs),
            "exact_duplicate_groups": len(exact_duplicates),
            "near_duplicate_pairs": len(near_duplicates),
            "duplicate_source_questions": len(source_duplicates),
            "duplicate_question_codes": len(code_duplicates),
            "highest_similarity": highest["prompt_similarity"] if highest else None,
            "highest_similarity_pair": [highest["left"], highest["right"]] if highest else None,
        },
        "exact_duplicate_groups": exact_duplicates,
        "near_duplicate_pairs": near_duplicates,
        "duplicate_source_questions": source_duplicates,
        "duplicate_question_codes": code_duplicates,
        "pairs": pairs,
        "note": "Prompt similarity is a screening signal only; "
        "it is not a semantic duplicate decision.",
    }


def build_verification_report(envelopes: Sequence[Mapping[str, Any]]) -> dict[str, Any]:
    """Record official-key, hash and import-gate status for every envelope."""

    rows: list[dict[str, Any]] = []
    for envelope in envelopes:
        source = envelope["source"]
        answer = envelope["answer_verification"]
        review = envelope["review"]
        publication = envelope["publication"]
        recomputed_hash = compute_pilot_content_hash(envelope)
        if answer["official_key"] != source["official_key"]:
            status = "official_key_mismatch"
        elif answer["derived_option_key"] != str(answer["official_key"]):
            status = "derived_key_mismatch"
        elif recomputed_hash != review["content_hash"]:
            status = "content_hash_mismatch"
        else:
            status = "verified"
        rows.append(
            {
                "pilot_id": str(envelope["pilot_id"]),
                "verification_mode": str(envelope["verification_mode"]),
                "exam_year": int(source["exam_year"]),
                "question_number": int(source["question_number"]),
                "official_key": int(source["official_key"]),
                "derived_option_key": str(answer["derived_option_key"]),
                "matches_official_key": bool(answer["matches_official_key"]),
                "official_key_source_ref": str(answer["official_key_source_ref"]),
                "source_document_sha256": str(source["document_sha256"]),
                "marking_scheme_sha256": str(source["marking_scheme_sha256"]),
                "transcription_status": str(source["transcription_status"]),
                "text_only_adaptation": bool(source["text_only_adaptation"]),
                "ambiguity_status": str(review["ambiguity_status"]),
                "duplicate_status": str(review["duplicate_status"]),
                "content_hash": str(review["content_hash"]),
                "content_hash_recomputed": recomputed_hash,
                "content_hash_match": recomputed_hash == review["content_hash"],
                "publication_import_status": str(publication["import_status"]),
                "approved_for_import": bool(publication["approved_for_import"]),
                "status": status,
            }
        )
    status_counts = Counter(row["status"] for row in rows)
    year_counts = Counter(str(row["exam_year"]) for row in rows)
    return {
        "schema_version": REPORT_SCHEMA_VERSION,
        "generated_at": REPORT_DATE,
        "source": "sealed envelopes under content/physics/pilot/questions/",
        "verification_authority": "official Department of Examinations marking-scheme MCQ grid",
        "human_review_claimed": False,
        "question_count": len(envelopes),
        "summary": {
            "all_verified": all(row["status"] == "verified" for row in rows),
            "all_hashes_match": all(row["content_hash_match"] for row in rows),
            "all_import_blocked": all(
                row["publication_import_status"] == "blocked_pending_t12_verification_mode"
                and not row["approved_for_import"]
                for row in rows
            ),
            "status_counts": dict(sorted(status_counts.items())),
            "question_counts_by_year": dict(sorted(year_counts.items())),
        },
        "questions": rows,
        "notes": [
            "The official marking-scheme grid is the verification authority; "
            "no teacher, reviewer or verifier identity is claimed.",
            "Content hashes bind the source claim, question and answer verification. "
            "A mismatch is a build failure.",
            "All items remain blocked from T12 import until T12 supports official "
            "marking-scheme verification or a human review is added.",
        ],
    }


def render_question_document(envelopes: Sequence[Mapping[str, Any]]) -> str:
    """Render the human-readable question and answer evidence document."""

    coverage = build_coverage_report(envelopes)
    lines = [
        "# T24 Physics pilot questions",
        "",
        "This file is generated from the sealed envelopes under `questions/`. "
        "Do not edit it by hand; regenerate it with "
        "`python -m memora.modules.questions.pilot_reports --root content/physics/pilot --write`.",
        "",
        "The pilot uses **official marking-scheme verification**. Each answer was derived "
        "independently and then matched to the printed Department of Examinations Paper I "
        "answer grid. No teacher, reviewer or verifier identity is claimed. See "
        "`DEVIATION_REVIEW_MODE.md`.",
        "",
        "## Summary",
        "",
        "| Pilot ID | Year / question | Official key | Primary concept | Verification |",
        "| --- | --- | ---: | --- | --- |",
    ]
    for envelope in envelopes:
        source = envelope["source"]
        primary = next(
            mapping
            for mapping in envelope["question"]["concept_mappings"]
            if mapping["mapping_role"] == "primary"
        )
        concept = _CONCEPT_BY_VERSION.get(str(primary["concept_version_id"]))
        concept_code = (
            str(concept["stable_code"]) if concept else str(primary["concept_version_id"])
        )
        lines.append(
            "| "
            f"`{envelope['pilot_id']}` | {source['exam_year']} Q{source['question_number']} "
            f"| {source['official_key']} | `{concept_code}` | official key matched |"
        )
    summary = coverage["summary"]
    lines.extend(
        [
            "",
            f"**Counts:** {coverage['question_count']} questions; "
            f"{summary['concepts_covered']} of {summary['concepts_total']} T08 concepts covered; "
            f"{summary['concepts_gap']} explicit gaps.",
            "",
            "## Coverage gaps",
            "",
        ]
    )
    for gap in coverage["gaps"]:
        lines.append(
            f"- `{gap['stable_code']}` - {gap['title']}: no selected pilot question maps "
            "to this T08 concept."
        )
    lines.extend(["", "## Questions", ""])
    for envelope in envelopes:
        source = envelope["source"]
        question = envelope["question"]
        answer = envelope["answer_verification"]
        review = envelope["review"]
        publication = envelope["publication"]
        lines.extend(
            [
                f"### {envelope['pilot_id']}",
                "",
                f"**Source:** `{source['document_filename']}` p.{source['pdf_page']}, "
                f"Q{source['question_number']} ({source['exam_label']}). Marking scheme: "
                f"`{source['marking_scheme_document']}` p.{source['marking_scheme_pdf_page']}.",
                "",
                f"**Official key:** {answer['official_key']}  ",
                f"**Derived key:** {answer['derived_option_key']}  ",
                f"**Sealed content hash:** `{review['content_hash']}`",
                "",
                "**Prompt:**",
                "",
            ]
        )
        lines.extend(f"> {line}" if line else ">" for line in str(question["prompt"]).splitlines())
        lines.extend(["", "**Options:**", ""])
        ordered = sorted(question["options"], key=lambda option: int(option["display_order"]))
        for index, option in enumerate(ordered, start=1):
            marker = " **(correct)**" if option["is_correct"] else ""
            lines.append(f"{index}. {option['display_text']}{marker}")
        lines.extend(
            [
                "",
                f"**Explanation:** {question['explanation']}",
                "",
                f"**Derivation:** {answer['derivation']}",
                "",
                "**Concept mapping:**",
                "",
            ]
        )
        for mapping in question["concept_mappings"]:
            concept = _CONCEPT_BY_VERSION.get(str(mapping["concept_version_id"]))
            title = str(concept["title"]) if concept else str(mapping["concept_version_id"])
            code = str(concept["stable_code"]) if concept else "UNKNOWN"
            lines.append(
                f"- {title} (`{code}`, {mapping['mapping_role']}, "
                f"weight {float(mapping['weight']):g})"
            )
        lines.extend(
            [
                "",
                f"**Provenance:** `{answer['official_key_source_ref']}`. "
                f"Reproduction status: `{source['reproduction_status']}`. "
                f"Import status: `{publication['import_status']}`.",
                "",
                f"**Coverage note:** {review['coverage_note']}",
            ]
        )
        if review["ambiguity_note"]:
            lines.extend(["", f"**Ambiguity note:** {review['ambiguity_note']}"])
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def write_question_document(
    root: str | Path = DEFAULT_PILOT_ROOT,
    *,
    path: str | Path | None = None,
) -> Path:
    """Write the checked-in question document from the current envelopes."""

    root_path = Path(root)
    output = Path(path) if path else root_path / "PILOT_QUESTIONS.md"
    envelopes = load_pilot_envelopes(root_path / "questions")
    output.write_text(render_question_document(envelopes), encoding="utf-8", newline="\n")
    return output


def write_reports(
    root: str | Path = DEFAULT_PILOT_ROOT,
    *,
    coverage_path: str | Path | None = None,
    duplicate_path: str | Path | None = None,
    verification_path: str | Path | None = None,
) -> dict[str, Path]:
    """Generate the three checked-in reports from the current envelopes."""

    root_path = Path(root)
    envelopes = load_pilot_envelopes(root_path / "questions")
    outputs = {
        "coverage": Path(coverage_path) if coverage_path else root_path / "coverage_report.json",
        "duplicate": Path(duplicate_path)
        if duplicate_path
        else root_path / "duplicate_report.json",
        "verification": Path(verification_path)
        if verification_path
        else root_path / "verification_report.json",
    }
    payloads = {
        "coverage": build_coverage_report(envelopes),
        "duplicate": build_duplicate_report(envelopes),
        "verification": build_verification_report(envelopes),
    }
    for key, path in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps(payloads[key], ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
            newline="\n",
        )
    return outputs


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Generate the deterministic T24 pilot reports.")
    parser.add_argument("--root", default=str(DEFAULT_PILOT_ROOT))
    parser.add_argument("--write", action="store_true", help="Write the report files.")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    root = Path(args.root)
    if args.write:
        outputs = write_reports(root)
        document = write_question_document(root)
        payload = {name: str(path) for name, path in outputs.items()}
        payload["questions_document"] = str(document)
        print(json.dumps(payload, indent=2))
        return 0
    envelopes = load_pilot_envelopes(root / "questions")
    print(json.dumps(build_verification_report(envelopes), indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
