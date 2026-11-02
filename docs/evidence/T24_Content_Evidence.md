# T24 content evidence

**Task:** T24, Verified Physics pilot content

**Branch:** `task/T24-physics-content`

**Status:** Review. The content bundle, validation, reports and tests are
present. The task is not merged and not Done. The PRD 9.3 qualified-review
requirement is replaced only by the recorded pilot deviation in
`content/physics/pilot/DEVIATION_REVIEW_MODE.md`.

## Scope completed

- Eight text-only G.C.E. (A/L) Physics Paper I MCQs from 2022, 2024 and 2025.
- Answer verification against the printed Department of Examinations marking
  scheme grids, with a recorded derivation for every item.
- T08 concept and objective mappings for every item.
- Fourteen-concept brief with formulas, units, dimensions, prerequisites,
  claims, aliases and coverage status.
- Concept/objective coverage report with three explicit gaps.
- Deterministic duplicate screening.
- Official-key, content-hash and import-gate verification report.
- Schema v2, a semantic validator, negative tests and a recorded deviation.
- No private student content.

## Source evidence

The source PDFs are gitignored under `content/physics/source_documents/`. The
hashes identify the local copies used for this pilot.

| File | Type | Year | Pages | SHA-256 |
| --- | --- | --- | ---: | --- |
| `AL_Physics_Syllabus_2017.pdf` | Syllabus | 2017 | 72 | `a9e1db067f9998a182d9a915434a0b9c557f9413c7c1ecc5fc980710cf19fdb9` |
| `AL_Physics_2022_Combined_Paper_English.pdf` | Paper | 2022(2023) | 19 | `931347c30d9c96068ae3df9e6d0db62f05c903f1a2abdb268a9a0e6bdb9956dc` |
| `AL_Physics_2022_Combined_Marking_Scheme_English.pdf` | Marking scheme | 2022(2023) | 39 | `52b42bcdf22ce9f6cc8c071d0cd6ba3c6f9082183d455d4fe43ef29143ee2ca7` |
| `AL_Physics_2024_Combined_Paper_English.pdf` | Paper | 2024 | 27 | `1d628ae65f32d97ce495a244176a7aa2db31e2b1a57f698a6fe3b028772c18c2` |
| `AL_Physics_2024_Combined_Marking_Scheme_English.pdf` | Marking scheme | 2024 | 48 | `2e77a2fd58a9213ea0cf025a11a72babedef363b66126c9d7830c8dcec9394b2` |
| `AL_Physics_2025_Combined_Paper_English.pdf` | Paper | 2025 | 17 | `6572aead08a0cc5fd9feed0db0a3e56fc2c125fca8fccb7e178a2c59729bae49` |
| `AL_Physics_2025_Combined_Marking_Scheme_English.pdf` | Marking scheme | 2025 | 40 | `39d58f8f5a272614b984f78156663e0fe1bb9afc0461013989e7e50df18fceb3` |

### Official answer grids

| Year | Marking-scheme PDF page | Grid | Selected keys |
| --- | ---: | --- | --- |
| 2022(2023) | 2 | 50 entries, five question/answer column pairs | Q1 = 4, Q17 = 4 |
| 2024 | 5 | 50 entries, five question/answer column pairs | Q1 = 5, Q4 = 1, Q5 = 5 |
| 2025 | 2 | 50 entries, five question/answer column pairs | Q1 = 5, Q3 = 1, Q45 = 5 |

The 2025 Q15 cell is printed as `02/04`. It is preserved literally in
`official_answer_keys.json` and excluded from the pilot. No handwritten tick on
a question paper was used as an answer key.

## Selected items

| Pilot ID | Topic | Official key | Primary T08 concept |
| --- | --- | ---: | --- |
| `PILOT-PHYS-2022-P1-Q01` | Vector/scalar pair | 4 | `PHYS-MEC-MOMENTUM` |
| `PILOT-PHYS-2022-P1-Q17` | Pendulum in an accelerating elevator | 4 | `PHYS-WAV-SHM` |
| `PILOT-PHYS-2024-P1-Q01` | Unit without dimensions | 5 | `PHYS-MEA-DIMENSIONS` |
| `PILOT-PHYS-2024-P1-Q04` | Newton's third law | 1 | `PHYS-MEC-NEWTON3` |
| `PILOT-PHYS-2024-P1-Q05` | Momentum and energy in an inelastic collision | 5 | `PHYS-MEC-MOMENTUM` |
| `PILOT-PHYS-2025-P1-Q01` | Energy units | 5 | `PHYS-MEC-WORK` |
| `PILOT-PHYS-2025-P1-Q03` | Spring-mass period | 1 | `PHYS-WAV-SHM` |
| `PILOT-PHYS-2025-P1-Q45` | Elastic/inelastic collision ratio | 5 | `PHYS-MEC-MOMENTUM` |

Seven items are verbatim text-only questions. `PILOT-PHYS-2024-P1-Q05`
originally refers to a figure; the prompt states the same setup in words and
records `text_only_adaptation = true`.

## Verification evidence

- Every envelope has a matching `source.official_key`,
  `answer_verification.official_key` and `derived_option_key`.
- Every sealed content hash recomputes successfully.
- Every item is mapped to a real T08 concept and its owning objective, with one
  primary mapping.
- `verification_report.json` records eight `verified` items,
  `human_review_claimed: false` and eight blocked imports.
- `duplicate_report.json` compares all 28 prompt pairs. The highest similarity is
  0.469136, below the 0.9 screening threshold.
- `coverage_report.json` records 11 of 14 concepts covered and six of six leaf
  objectives covered.
- The three explicit gaps are `PHYS-MEC-DISPLACEMENT`, `PHYS-MEC-VELOCITY` and
  `PHYS-MEC-NEWTON1`.

## Commands run

| Command | Result |
| --- | --- |
| `python -m memora.modules.questions.pilot_validation validate content/physics/pilot/questions` | `status: valid`, 8 envelopes |
| `python -m memora.modules.questions.pilot_reports --root content/physics/pilot --write` | Wrote three reports and `PILOT_QUESTIONS.md` with LF endings; a second run was byte-identical |
| `ruff format --check` on the T24 Python files | 10 files already formatted |
| `ruff check` on the T24 Python files | All checks passed |
| Focused `pytest` for the seven T24 test modules | 72 passed in 2.97s |
| Adjacent question-bank tests (`test_questions_grading.py`, `test_questions_models.py`, `test_question_reports.py`) | 72 passed, one existing Starlette deprecation warning |
| `jsonschema` Draft 2020-12 meta-schema check | `schema meta-valid` |

The commands use the repository `.venv` and `PYTHONPATH=backend/src`.

## Acceptance gate mapping

| T24 gate | Evidence | Status |
| --- | --- | --- |
| Minimum Physics concept/question set | 14 concepts, 8 questions, 11 concepts covered | Met in scope |
| Objectives, claims, formulas, units and prerequisites | `concepts.json` | Met |
| Rubrics and explanations | Every envelope has an exact rubric, explanation and derivation | Met |
| Provenance | Source hashes, pages and official keys in every envelope | Met |
| Every item maps to curriculum and concepts | Validator and mapping tests | Met |
| Ambiguity and duplicate checks | Clean reports plus recorded notes | Met |
| Gaps are explicit | Three named gaps | Met |
| No private student content | Bundle contains only public past-paper excerpts and derived analysis | Met |
| Qualified review is recorded | No teacher, reviewer or verifier identity; recorded deviation only | **Not met; deviation recorded** |
| T12 import | Blocked by the T12 author/reviewer gate | **Blocked** |

T24 therefore remains in **Review**. The pilot deviation does not satisfy the
qualified-review clause and does not authorize import.

## Import gate

`publication.approved_for_import = false` and
`import_status = "blocked_pending_t12_verification_mode"` on all eight
envelopes. T12 still requires non-null author and reviewer principals, and the
database trigger rejects an approved question without them. No migration or T12
contract change was made in T24.

## Known limitations

- Reproduction permission is not recorded. The excerpts are internal pilot
  evidence, not cleared for redistribution.
- The 2022 paper is an annotated scan. Handwriting was ignored.
- The 2025 Q03 wording is ambiguous if "length of the spring" means extension.
  The official key selects the natural-length interpretation and the note
  records the risk.
- The source PDFs are not committed, so hash checks skip when the local files
  are absent.
- The official grid verifies the answer option, not the explanation or
  accessibility quality. Those still need qualified review before public use.

## Review evidence

- `content/physics/pilot/PILOT_QUESTIONS.md`: question, answer, derivation and
  mapping evidence.
- `content/physics/pilot/coverage_report.json`: concept and objective coverage.
- `content/physics/pilot/duplicate_report.json`: deterministic duplicate screen.
- `content/physics/pilot/verification_report.json`: key, hash and import status.
- `content/physics/pilot/DEVIATION_REVIEW_MODE.md`: deviation scope and limits.
- `docs/learning/T24_Study_Note.md`: learning-oriented explanation.
