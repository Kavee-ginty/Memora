# T24 content evidence

**Task:** T24, Verified Physics pilot content

**Branch:** `task/T24-physics-content`

**Status:** Review. Route A content, review and import verification are complete
on the branch. The work is not merged and T24 is not Done. The review is an
explicit self-review, not an independent second-person check.

## Scope completed

- Eight text-only G.C.E. (A/L) Physics Paper I MCQs from 2022, 2024 and 2025.
- Answer verification against the printed Department of Examinations marking
  scheme grids, with a recorded derivation for every item.
- A named Physics teacher review record covering all eight items, with the
  self-review limitation declared.
- T08 concept and objective mappings for every item.
- Fourteen-concept brief with formulas, units, dimensions, prerequisites,
  claims, aliases and coverage status.
- Concept/objective coverage report with three explicit gaps.
- Deterministic duplicate screening.
- Review, official-key, content-hash and import-status verification report.
- Schema v2, a semantic validator, negative tests and a recorded review mode.
- All eight envelopes converted to the T12-compatible `expert_review` mode and
  approved for import batch `T24-PHYS-PILOT-2026-11`.
- A database-backed import test using the real envelopes.
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

## Review evidence

| Field | Value |
| --- | --- |
| Author and reviewer | Malshani Perera |
| Role | Physics Teacher |
| Qualification reference | `PostGraduate` (self-declared) |
| Relationship | Self-review: author and reviewer are the same person |
| Review date | 2026-11-02T19:00:00+05:30 (`2026-11-02T13:30:00+00:00`) |
| Pilot principal UUID | `a2400000-0000-4000-8000-000000000001` |
| Decision | All eight items approved; no corrections requested |
| Review record | `content/physics/pilot/REVIEW_RECORD.md` |

Every envelope records:

```text
verification_mode = "expert_review"
answer_verification.independent_review_status = "self_review"
review.academic_review_status = "approved"
question.author_principal == question.reviewer_principal
```

`REVIEW_RECORD.md` records the declaration, review scope, per-item decisions,
the reviewed and sealed hashes, and the import approval. The declaration states
that independence is not claimed.

The qualification reference `PostGraduate` is self-declared. It does not name a
degree, awarding institution, year or subject specialisation, and this branch
does not independently verify the reviewer's identity or certificates. The
name, role and qualification reference were supplied for this task. A later
reviewer should treat the qualification claim as unverified until supporting
evidence is produced.

## Verification evidence

- Every envelope has a matching `source.official_key`,
  `answer_verification.official_key` and `derived_option_key`.
- Every sealed content hash recomputes successfully.
- Every item is mapped to a real T08 concept and its owning objective, with one
  primary mapping.
- `verification_report.json` records eight `verified` items,
  `human_review_claimed: true`, `independent_review_claimed: false`,
  `self_review_count: 8` and `all_import_ready: true`.
- `duplicate_report.json` compares all 28 prompt pairs. The highest similarity is
  0.469136, below the 0.9 screening threshold.
- `coverage_report.json` records 11 of 14 concepts covered and six of six leaf
  objectives covered.
- The three explicit gaps are `PHYS-MEC-DISPLACEMENT`, `PHYS-MEC-VELOCITY` and
  `PHYS-MEC-NEWTON1`.
- The metadata-only conversion did not change the prompt, options, explanation,
  derivation, source references, concept/objective IDs, mapping roles or
  weights. `REVIEW_RECORD.md` records the reviewed and sealed hash for every
  item.

### Database import verification

`backend/tests/test_question_db_contracts.py::test_t24_physics_pilot_envelopes_import_as_expert_self_review`
loads the eight real envelopes, converts them through `to_validated_import()`,
and imports each through `QuestionImportRepository` into a disposable
PostgreSQL database. It verifies that:

- all eight question codes receive distinct question rows;
- `questions.author_principal` and `questions.reviewer_principal` are non-null
  and equal to the recorded pilot principal;
- the parent question and the imported version are `approved`;
- the stored prompt matches the reviewed envelope;
- the version carries the `Expert verified` trust label.

The database trigger in `20261023_0005_question_bank_integrity.up.sql` accepts
the same principal in both fields because it is an identity-presence gate, not
an independence gate. No migration or T12 contract change was made.

## Commands run

| Command | Result |
| --- | --- |
| `python -m memora.modules.questions.pilot_validation validate content/physics/pilot/questions` | `status: valid`, 8 envelopes |
| `python -m memora.modules.questions.pilot_reports --root content/physics/pilot --write` | Wrote three reports and `PILOT_QUESTIONS.md`; a second run was byte-identical |
| `pytest backend/tests -k pilot` with `MEMORA_TEST_DATABASE_URL` | 78 passed |
| `pytest backend/tests` with `MEMORA_TEST_DATABASE_URL` | 676 passed |
| `pytest backend/tests` without `MEMORA_TEST_DATABASE_URL` | 517 passed, 159 skipped |
| `pytest backend/tests/test_question_db_contracts.py::test_t24_physics_pilot_envelopes_import_as_expert_self_review` with `MEMORA_TEST_DATABASE_URL` | 1 passed |
| `ruff format --check` on the affected T24 Python files | 9 files already formatted |
| `ruff check` on the affected T24 Python files | All checks passed |

The commands use the repository `.venv` and `PYTHONPATH=backend/src`. The
disposable database name ends in `_test`, as required by the test fixture.

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
| Qualified review is recorded | Named Physics teacher self-review in `REVIEW_RECORD.md`; qualification reference is self-declared and underspecified | Recorded, with an open evidence limitation |
| T12 import | Real envelopes imported through `QuestionImportRepository` into a disposable database | Verified |

The PRD 9.3 clause is "written or reviewed by qualified A/L Physics teachers or
subject experts". A named Physics teacher performed the review. The record does
not claim that the review was independent, and it does not present the
self-declared qualification reference as independently verified evidence.

T24 remains in **Review** until the branch is merged and the import evidence is
part of the merged task. The branch content is ready for that review.

## Import gate

All eight envelopes record:

```text
approved_for_import = true
import_status = "ready_for_import"
import_batch_id = "T24-PHYS-PILOT-2026-11"
approved_by = "Malshani Perera"
approved_at = "2026-11-02T13:30:00+00:00"
```

The same non-null pilot principal is used as author and reviewer because the
review is a self-review. The database import test proves that T12 and its
trigger accept this honest representation. No fake distinct reviewer, disabled
trigger, draft-import workaround or schema-mode bypass was used.

`DEVIATION_REVIEW_MODE.md` is retained as the superseded record of the earlier
official-marking-scheme-only pilot. The active envelopes no longer reference it.

## Known limitations

- The review is a self-review, not an independent check.
- The qualification reference is self-declared and lacks a degree title,
  institution, year and subject specialisation.
- Reproduction permission is not recorded. The excerpts are internal pilot
  evidence, not cleared for redistribution.
- The 2022 paper is an annotated scan. Handwriting was ignored.
- The 2025 Q03 wording is ambiguous if "length of the spring" means extension.
  The official key selects the natural-length interpretation and the note
  records the risk.
- The source PDFs are not committed, so hash checks skip when the local files
  are absent.
- The official grid verifies the answer option. The named reviewer approved the
  explanation and mapping, but there is no second-person academic review of
  those judgements.

## Review evidence files

- `content/physics/pilot/REVIEW_RECORD.md`: reviewer identity, self-review
  declaration, per-item decisions, reviewed/sealed hashes and approval.
- `content/physics/pilot/PILOT_QUESTIONS.md`: question, answer, derivation,
  review and mapping evidence.
- `content/physics/pilot/coverage_report.json`: concept and objective coverage.
- `content/physics/pilot/duplicate_report.json`: deterministic duplicate screen.
- `content/physics/pilot/verification_report.json`: review, key, hash and import
  status.
- `content/physics/pilot/DEVIATION_REVIEW_MODE.md`: superseded historical
  official-mode record.
- `docs/learning/T24_Study_Note.md`: learning-oriented explanation.
