# T24 Physics pilot content

This directory contains the T24 pilot bundle: eight text-only G.C.E. (A/L)
Physics Paper I multiple-choice questions, corrected against the printed
Department of Examinations marking-scheme answer grids.

The pilot validates content structure, official-key correction, curriculum
mapping, formulas, units, prerequisites, ambiguity, duplicate screening and
coverage reporting. It does not approve the items for the T12 question bank.

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
| `PILOT_QUESTIONS.md` | Generated question, answer and mapping evidence |
| `coverage_report.json` | Concept and objective coverage report |
| `duplicate_report.json` | Deterministic prompt/source/code duplicate screen |
| `verification_report.json` | Official-key, hash and import-gate status |
| `DEVIATION_REVIEW_MODE.md` | Recorded pilot deviation from PRD 9.3 qualified review |

## Verification mode

Every checked-in envelope uses `verification_mode = "official_marking_scheme"`.
The printed official grid is the answer authority. The envelope's answer is
derived first and then matched to the grid; a mismatch is a build failure.

No teacher, reviewer or verifier identity is claimed. This is a recorded pilot
deviation from PRD 9.3, not an academic approval. See
`DEVIATION_REVIEW_MODE.md`.

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

Every envelope has `approved_for_import = false` and
`import_status = "blocked_pending_t12_verification_mode"`. T12 still requires
non-null author and reviewer principals, and its database trigger enforces the
same rule. T24 does not bypass that gate.

## Source handling

The source PDFs live under `content/physics/source_documents/`, which is
gitignored. Only the selected short question excerpts needed for the pilot are
checked in. Reproduction permission is not recorded, so every envelope uses
`reproduction_status = "unapproved"` and remains internal-only.

The PDF hashes in `source_manifest.json` identify the local copies used for
transcription. Tests verify the hashes when the PDFs are present and skip that
check when they are absent.
