# T24 Pilot Review Checklist

**Status:** Stage 1 draft. No item on this checklist is approved.

Use this checklist for each of the eight candidate questions and for any concept, claim or rubric added in Stage 2. A checked box means evidence exists; it does not mean the reviewer is qualified or the content is approved. The sign-off table must contain a real reviewer reference before any item is imported as `approved`.

## 1. Roles and independence

| Role | Responsibility | Stage 1 state |
| --- | --- | --- |
| Author | Writes the question, explanation, options and rubric. | Unassigned. |
| Independent academic reviewer | Checks physics, transcription, ambiguity and curriculum fit. Must not be the author. | Unassigned. |
| Curriculum reviewer | Confirms objective/concept mapping and syllabus boundary. | Unassigned. |
| Content engineer | Runs schema, duplicate, coverage and import checks. | Unassigned. |
| Approval owner | Records the final approval and reproduction decision. | Unassigned. |

Do not write a name, principal UUID, qualification or date into a record until the person and the evidence exist.

## 2. Per-item gates

### A. Source and reproduction

- [ ] Source filename matches `source_manifest.json`.
- [ ] SHA-256 matches `source_manifest.json`.
- [ ] Year label is correct, including the `2022(2023)` form.
- [ ] Paper and question number are correct.
- [ ] PDF page reference is correct.
- [ ] Medium is English. The 2021 paper is excluded from English-medium use because it is Tamil.
- [ ] The prompt and every option have been compared with the page image, not only with OCR text.
- [ ] Handwritten annotations, ticks or marks were not treated as an answer key.
- [ ] The marking-scheme page-2 limitation is recorded: none of the inspected page-2 layouts is an MCQ key (2022/2025 are question-to-marks tables).
- [ ] Reproduction status is recorded. If it is `unapproved`, the item cannot be published or redistributed.
- [ ] Verbatim prompts and options remain in the ignored local review pack, not in tracked artifacts, until a real reproduction approval exists.
- [ ] A real reproduction approval reference exists before any copy of the question is committed to tracked content.
- [ ] No source PDF is staged in Git.

### B. Academic correctness

- [ ] The prompt is unambiguous under the stated assumptions.
- [ ] Every option is grammatically and physically plausible.
- [ ] For single-choice MCQ, exactly one option is correct.
- [ ] The derived answer is independently reproduced.
- [ ] The derivation uses the syllabus conventions and the paper's stated value of `g`.
- [ ] Units, prefixes, signs and significant figures are correct.
- [ ] No official key is claimed unless an actual official key was inspected and referenced.
- [ ] The explanation teaches the reasoning without leaking an unverified answer as fact.
- [ ] Any edge case is either excluded by the wording or recorded as an ambiguity flag.

### C. Curriculum and concept mapping

- [ ] At least one `primary` mapping exists.
- [ ] Every mapping uses an existing `concept_version_id` and, where applicable, an existing `learning_objective_id`.
- [ ] No invented concept code, objective code or UUID is used.
- [ ] The mapping role is correct: `primary`, `supporting`, `prerequisite` or `misconception`.
- [ ] The weight is between 0 and 1 and is academically justified.
- [ ] `provenance_type` and `provenance_ref` identify a real review or source.
- [ ] The item is inside the NIE 2017 English-medium syllabus boundary.
- [ ] Coverage is recorded honestly; a missing concept is a gap, not a reason to force a mapping.
- [ ] Prerequisites are explicit where the item depends on earlier knowledge.

### D. T12 contract

- [ ] `QuestionImportBundle.model_validate()` accepts the `question` object.
- [ ] `validate_question_import()` accepts the draft.
- [ ] The content hash is stable across repeated validation.
- [ ] Option keys are unique and match the pattern.
- [ ] `display_order` is contiguous from zero.
- [ ] The rubric type matches the question type.
- [ ] The rubric payload is valid for the declared type.
- [ ] `max_score` is positive and within T12 bounds.
- [ ] `evidence_ceiling` is positive and within T12 bounds.
- [ ] The explanation is non-empty for an approved item.
- [ ] A real `author_principal` exists for non-AI content.
- [ ] A real `reviewer_principal` exists.
- [ ] The reviewer principal is not the author principal. This is enforced by `pilot_validation.py`, not by T12 or the database trigger.
- [ ] `target_source_class` is `expert_verified` and draft `source_class` is null.
- [ ] The import is idempotent: re-running the same bundle returns the same version rather than creating a duplicate.

### E. Ambiguity, duplicate and coverage checks

- [ ] Exact prompt duplicate check passes.
- [ ] Exact option-set duplicate check passes.
- [ ] Near-duplicate check passes, including wording variants.
- [ ] Semantic duplicate check passes, or the limitation of the check is recorded.
- [ ] The item is not a trivial variant of another pilot item.
- [ ] Ambiguity status is `cleared`, not `pending` or `flagged`.
- [ ] The ambiguity note records the assumption that resolves the item.
- [ ] The coverage report names the objective and concept covered.
- [ ] The coverage report names the nearest uncovered gap.
- [ ] The pilot-level coverage statement does not claim full syllabus coverage.

### F. Accessibility and presentation

- [ ] The item is text-only and does not depend on a diagram.
- [ ] No meaning depends on colour alone.
- [ ] The prompt and options are readable at 320 px width and 200% text scale.
- [ ] Superscripts, subscripts, fractions and symbols have a text equivalent that a screen reader can read.
- [ ] The option order is stable and does not rely on visual position.
- [ ] Any media reference has non-empty alt text. The pilot candidates should have none.
- [ ] Reduced motion is irrelevant to a static text item, but any future media must respect it.

### G. Provenance and review record

- [ ] The `source` block is complete.
- [ ] `transcription_verified` is true only after a real page-image check.
- [ ] `answer_verification.independent_review_status` is `verified`.
- [ ] `official_key_claimed` is false unless a real key is referenced.
- [ ] `review.academic_review_status` is `approved`.
- [ ] `review.reviewer_principal` is a real principal.
- [ ] `question.author_qualification_ref` points to real evidence for the author.
- [ ] `review.reviewer_qualification_ref` points to real evidence.
- [ ] `review.reviewed_at` is a real timestamp.
- [ ] `review.ambiguity_status` is `cleared`.
- [ ] `review.duplicate_status` is `cleared`.
- [ ] `review.independence_declaration_ref` records that the reviewer is independent of the author.
- [ ] `review.content_hash` matches the exact current content.
- [ ] `review.source_ref` matches the source block, including SHA-256, page and question number for a past paper.
- [ ] `publication.approved_for_import` is true only after all other gates pass.
- [ ] `publication.approved_by` references a real approval record.
- [ ] The review record and the content hash are linked.

### H. Privacy and security

- [ ] No student text, answer history, source excerpt or personal data is present.
- [ ] No secret, token, signed URL or credential is present.
- [ ] No source PDF or full-page image is committed to tracked content without reproduction approval.
- [ ] Logs and CI output do not print question answers, prompts or source excerpts.
- [ ] The import path is offline and privileged; it is not exposed as an HTTP route.
- [ ] The item does not create a new authorization surface.

### I. Versioning and rollback

- [ ] The `question_code` is stable and unique.
- [ ] The item is imported as a new version, not by editing a published row.
- [ ] The content hash is recorded.
- [ ] A changed prompt, option, explanation or mapping creates a new version.
- [ ] The previous version remains readable for attempts that reference it.
- [ ] A failed import leaves no partial question, option, rubric or mapping rows.
- [ ] The import is reversible by withdrawing the new version, not by mutating history.

### J. Documentation

- [ ] The source reference is recorded in the content bundle.
- [ ] The review decision is recorded.
- [ ] The coverage gap is recorded.
- [ ] Any excluded item is recorded with a reason.
- [ ] The task table is updated only after merge, not before.
- [ ] The pull request lists the exact commands and results.
- [ ] PostgreSQL-dependent tests are reported separately from non-database tests.

## 3. Candidate status matrix

All rows are Stage 1 status. `P` means pending; `F` means flagged.

| Candidate | Source | Physics | Mapping | Ambiguity | Duplicate | Review | Reproduction |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2025 Q1 | P | P | P | P | P | P | not approved |
| 2025 Q2 | P | P | **blocked** | P | P | P | not approved |
| 2025 Q5 | P | P | **blocked** | **F** | P | P | not approved |
| 2025 Q12 | P | P | **blocked** | **F** | P | P | not approved |
| 2025 Q14 | P | P | **blocked** | P | P | P | not approved |
| 2025 Q45 | P | P | **weak** | P | P | P | not approved |
| 2022 Q1 | P | P | **blocked** | **F** | P | P | not approved |
| 2022 Q17 | P | P | **weak** | P | P | P | not approved |

`blocked` means no existing T08 concept can serve as a credible primary mapping (`mapping_status = "missing"` in `candidate_mappings.json`). `weak` means an existing concept is only a partial fit (`mapping_status = "partial"`). Neither state is approval. Only 2025 Q1 has a complete existing mapping; seven of the eight candidates do not.

The machine-readable counts are 1 complete, 2 partial and 5 missing. Every candidate is also `blocked` in `evidence_status.json` because no answer key, author or reviewer qualification, independence declaration, approval or reproduction permission exists. The human evidence checklist is `EVIDENCE_REQUIRED.md`.

## 4. Sign-off record

This table is intentionally blank. Do not fill it with placeholders.

| Candidate | Reviewer role | Real reviewer reference | Decision | Date | Content hash | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| 2025 Q1 |  |  |  |  |  |  |
| 2025 Q2 |  |  |  |  |  |  |
| 2025 Q5 |  |  |  |  |  |  |
| 2025 Q12 |  |  |  |  |  |  |
| 2025 Q14 |  |  |  |  |  |  |
| 2025 Q45 |  |  |  |  |  |  |
| 2022 Q1 |  |  |  |  |  |  |
| 2022 Q17 |  |  |  |  |  |  |

## 5. Blocking rules

An item may not be imported as `approved` if any of the following is true:

1. No real reviewer principal.
2. No author qualification evidence for that author.
3. No qualification evidence for that reviewer.
4. Reviewer and author are the same person.
5. No primary concept mapping.
6. Ambiguity status is `pending` or `flagged`.
7. Duplicate status is `pending` or `duplicate`.
8. Explanation is empty.
9. Rubric is not approved.
10. Evidence ceiling is zero or missing.
11. Reproduction status is `unapproved`.
12. Transcription has not been checked against the page image.
13. The item depends on a diagram that has not passed accessibility review.
14. The review content hash is missing or does not match the current content.
15. The review source reference is missing or does not match the source block.
16. The reviewer/author independence declaration is missing.
17. The item is a draft carrying a non-null `source_class`, `author_qualification_ref` or `pilot_review` provenance.
18. An approved item has a mapping whose provenance is not `pilot_review`.
19. The review date or approval date is missing, or the approval date precedes the review date.
20. The author or reviewer qualification reference is missing or does not resolve to a real record.
21. An official answer key is claimed without an official key.
22. A past-paper transcription has not been checked against the page image.
23. T08 concept version UUIDs, objective IDs or claim IDs do not resolve in the reviewed seed.

## 6. Commands for Stage 2

Non-database checks:

```powershell
$env:PYTHONPATH="$PWD\backend\src"
.\.venv\Scripts\python.exe -m pytest `
  backend/tests/test_pilot_content_validation.py `
  backend/tests/test_pilot_mapping_report.py `
  backend/tests/test_pilot_evidence_status.py `
  backend/tests/test_pilot_schema_jsonschema.py `
  backend/tests/test_questions_models.py `
  backend/tests/test_curriculum_seed.py `
  backend/tests/test_questions_grading.py -q
```

Result: **128 passed, 0 failed**. The T24 tests validate the synthetic draft, reject misleading draft trust classes, enforce author and reviewer identity/qualification/independence, review and approval dates, content-hash/source binding and T08 concept/objective resolution. The mapping and evidence reports check the eight candidate IDs against `PILOT_QUESTIONS.md` and the source manifest, and cross-check their schema versions and the B4 concept-gap blocker. The JSON Schema tests use `jsonschema` against Draft 2020-12.

PostgreSQL-dependent checks, only with a disposable database and `MEMORA_TEST_DATABASE_URL` set:

```powershell
$dbPassword = docker compose --env-file .env -f infra/compose.yaml exec -T postgres printenv POSTGRES_PASSWORD
$encoded = [uri]::EscapeDataString($dbPassword.Trim())
$env:MEMORA_TEST_DATABASE_URL = "postgresql+psycopg://memora:$encoded@127.0.0.1:5432/memora_t24_test"
.\.venv\Scripts\python.exe -m pytest backend\tests\test_migrations.py backend\tests\test_question_db_contracts.py -q
```

Result on the fresh local `memora_t24_test` database: **27 passed, 0 failed, 0 skipped**. These are local results, not CI or staging acceptance. The migration tests downgrade to base and must never be pointed at a shared or production database. Recreate the `_test` database before a repeat run because the RLS test uses fixed OIDC subjects.

## 7. Exit criteria for the review

The review is complete only when:

- every candidate has a real source, physics, mapping and ambiguity decision;
- every `flagged` item is either fixed or excluded;
- every `blocked` mapping has a reviewed concept or the item is excluded;
- every item has a real author and reviewer principal, a real author qualification reference, a real reviewer qualification reference and a date;
- reproduction status is resolved for every item that will be tracked or published;
- the duplicate and coverage reports are attached;
- the approved-envelope conversion and the PostgreSQL import test pass in the approved environment (drafts are not imported);
- a CI or approved staging run of the PostgreSQL migration, import, immutability and RLS suites is recorded; a local disposable run is not release acceptance;
- the T12 owner has answered the provenance and independence-boundary questions in `T12_OWNER_ACCEPTANCE.md`;
- the pull request records the exact commands and results.

Until then, the correct state is **draft**, not **approved**.
