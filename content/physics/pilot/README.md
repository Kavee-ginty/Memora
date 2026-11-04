# T24 Physics pilot content

This directory contains the T24 pilot bundle: eight text-only G.C.E. (A/L)
Physics Paper I multiple-choice questions, checked against the printed
Department of Examinations marking-scheme answer grids and reviewed by a named
Physics teacher.

The pilot validates content structure, review evidence, official-key
correction, curriculum mapping, formulas, units, prerequisites, ambiguity,
duplicate screening and coverage reporting. The active batch is approved for the
T12 offline/admin import path.

## Contents

| Path | Purpose |
| --- | --- |
| `source_manifest.json` | Selected source files, hashes, pages and selected-question index |
| `official_answer_keys.json` | Complete 2022, 2024 and 2025 Paper I answer grids |
| `SOURCE_INVENTORY.md` | Human-readable source and grid evidence |
| `pilot_question.schema.json` | Structural contract for sealed envelopes |
| `CONTENT_SCHEMA.md` | Schema, validation and import-gate explanation |
| `questions/` | Eight sealed question envelopes |
| `concepts.json` | Fourteen T08 concepts with formulas, units, prerequisites, claims and coverage |
| `REVIEW_RECORD.md` | Reviewer/author identity, self-review declaration, per-item decisions and hashes |
| `PILOT_QUESTIONS.md` | Generated question, answer, review and mapping evidence |
| `coverage_report.json` | Concept and objective coverage report |
| `duplicate_report.json` | Deterministic prompt/source/code duplicate screen |
| `verification_report.json` | Review, official-key, hash and import status |
| `DEVIATION_REVIEW_MODE.md` | Superseded historical record of the official-mode deviation |

## Verification mode

Every checked-in envelope uses `verification_mode = "expert_review"`. The printed
official grid remains the answer-key authority: each answer was derived and then
matched to the grid, and a mismatch is a build failure.

The named reviewer, Malshani Perera, approved all eight items on 2026-11-02. The
review is a **self-review**: the author and reviewer are the same person, and no
independence is claimed. The envelope records
`answer_verification.independent_review_status = "self_review"`. See
`REVIEW_RECORD.md` for the identity, qualification, declaration, per-item
decisions and reviewed/sealed hashes.

The `official_marking_scheme` mode remains supported for historical or other
official-key-only content. It is not the active mode. See `CONTENT_SCHEMA.md`
and the superseded `DEVIATION_REVIEW_MODE.md`.

## Coverage

The eight items cover 11 of the 14 T08 concepts. The three explicit gaps are:

- `PHYS-MEC-DISPLACEMENT`
- `PHYS-MEC-VELOCITY`
- `PHYS-MEC-NEWTON1`

The gaps are reported rather than filled with invented mappings.

## Validate and regenerate

From the repository root:

```powershell
$env:PYTHONPATH = "backend/src"
.\.venv\Scripts\python.exe -m memora.modules.questions.pilot_validation validate content/physics/pilot/questions
.\.venv\Scripts\python.exe -m memora.modules.questions.pilot_reports --root content/physics/pilot --write
```

The report generator rewrites `PILOT_QUESTIONS.md`, the three JSON reports and
must leave the checked-in files unchanged when the envelopes are unchanged.

## Import status

Every envelope has:

```text
approved_for_import = true
import_status = "ready_for_import"
import_batch_id = "T24-PHYS-PILOT-2026-11"
```

T12 requires non-null author and reviewer principals, and its database trigger
enforces the same rule. Both fields carry the same self-review principal. The
trigger is an identity-presence gate, not an independence test; the self-review
limitation is recorded in `REVIEW_RECORD.md`, not hidden in the database fields.

## Source handling

The source PDFs live under `content/physics/source_documents/`, which is
gitignored. Only the selected short question excerpts needed for the pilot are
checked in. Reproduction permission is not recorded, so every envelope uses
`reproduction_status = "unapproved"` and remains internal-only.

The PDF hashes in `source_manifest.json` identify the local copies used for
transcription. Tests verify the hashes when the PDFs are present and skip that
check when they are absent.
