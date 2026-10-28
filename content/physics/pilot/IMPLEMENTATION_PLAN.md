# T24 Physics Pilot Implementation Plan

**Task:** T24 — Verified Physics pilot content

**Branch:** `task/T24-physics-content`

**Status:** Stage 1 planning and draft-only groundwork complete. Awaiting approval to start Stage 2.

**Date:** 2026-10-28

**Dependencies:** T08 (curriculum and knowledge graph seed) and T12 (question bank and grading backend) are marked **Done**.

## 1. Purpose and authority

T24 must produce the minimum reviewed Physics concept/question set for the pilot, including objectives, claims, formulas, units, prerequisites, rubrics, explanations, provenance and coverage reporting. The acceptance gate is:

- qualified review is recorded;
- every item maps to curriculum and concepts;
- ambiguity and duplicate checks pass;
- gaps are explicit;
- no private student content enters shared seeds.

Authorities used, in order:

1. `docs/specifications/Memora_PRD.md` §9.1-9.3.
2. `docs/specifications/Memora_TRD.md` §8.2.
3. `docs/specifications/Memora_Backend_Schema_and_Data_Model.md` §7.3, §7.5, §9.1, §9.3, §9.4 and §18.2.
4. `docs/project-management/Memora_Development_Task_Table.md` T24 row and §5.1 T24 done criteria.
5. Existing T08 and T12 code and tests.

This plan does not override any of those authorities. Where this plan proposes a new field or a new concept, it is explicitly marked as proposed, not approved.

## 2. Stage 1 scope

Stage 1 is limited to:

- source inventory and hashing;
- policy and repository-handling checks;
- T08/T12 contract validation;
- candidate question transcription and answer derivation;
- planning artifacts for Stage 2.

Stage 1 does **not**:

- change T08 seed data or seed logic;
- change T12 code, imports, migrations, APIs, tables or question data;
- import or publish a question;
- create a reviewer, author, principal or approval record;
- claim an official MCQ answer key;
- copy papers or resource books into tracked content;
- commit or otherwise stage a `.gitignore` change (the working tree already contains the T24 rules);
- run a Git command, start a database service or change environment configuration.

## 3. Stage 1 findings

### 3.1 Source corpus

- 25 PDFs, 349,201,060 bytes (333.02 MiB).
- 8 past papers, 8 marking schemes, 1 syllabus, 1 practical handbook and 7 NIE resource books.
- Exam years present: 2017-2022, 2024 and 2025. No 2023 paper.
- All documents are English-medium except the 2021 paper, which is Tamil despite its `_English` filename.
- The 2022 paper is an annotated CamScanner scan. The 2025 paper is an image scan and its rendered page 2 carries a `Past Papers Wiki` watermark. Neither has a usable text layer.
- The 2022 and 2025 marking-scheme page 2 is a question-to-marks allocation table, not an MCQ answer grid. No official MCQ key was found.
- All seven resource books show NIE copyright 2020. The syllabus is implemented from 2017. The practical handbook is effective from 2017.
- Full inventory: `SOURCE_INVENTORY.md` and `source_manifest.json`.

### 3.2 Repository handling

The PDFs are not tracked. The working-tree `.gitignore` now contains `/content/physics/source_documents/` and `/content/physics/pilot/local_review/`, so a broad `git add` does not stage the PDFs or the local verbatim review pack. These rules are not committed. The source-document rule is described in `SOURCE_INVENTORY.md` section 7.

### 3.3 T08 graph

T08 has:

- 9 objectives, 14 concepts, 15 claims and 16 edges;
- 6 `concept`, 4 `variable`, 3 `law` and 1 `principle` concept nodes;
- no `formula`, `unit`, `method`, `diagram_skill` or `misconception` concept nodes;
- no measurement-uncertainty, projectile, friction, collision/conservation-of-momentum, scalar/vector or simple-pendulum concept;
- `reviewed_at` written by the seed writer but `reviewed_by` left null.

T08 covers Units 1-3 only, and Unit 2 only partially. That is valid for its accepted scope, but it is not enough for the candidate set.

### 3.4 T12 contract

T12 supports an offline path:

```text
QuestionImportBundle -> validate_question_import() -> QuestionImportRepository.import_question()
```

No CLI is required. T12 publication requires a non-empty explanation, a real reviewer principal, a real author principal for non-AI content, an approved rubric, a positive evidence ceiling and at least one primary concept mapping.

T12 has no question-level source provenance field, no reviewer qualification record and no licence/reproduction field. Its only provenance surface is per-mapping `provenance_type` / `provenance_ref`.

A read-only probe confirmed:

- the synthetic draft with one real T08 mapping is accepted as a draft;
- an approved bundle without a reviewer is rejected with `reviewer_required`;
- a source field inside `content` is rejected with `content_invalid`.

This is an import smoke test only, not envelope approval.

Full analysis: `T08_T12_CONTRACT_GAPS.md`.

## 4. Pilot scope

### 4.1 Candidate set

Eight text-only MCQs:

| Candidate | Topic | Derived answer |
| --- | --- | --- |
| 2025 Paper I Q1 | Units of energy | (5) |
| 2025 Paper I Q2 | Percentage error of a period | (3) |
| 2025 Paper I Q5 | Projectile statements | (3) |
| 2025 Paper I Q12 | Static friction, four-wheel drive | (2) |
| 2025 Paper I Q14 | Independence of horizontal and vertical motion | (5) |
| 2025 Paper I Q45 | Collisions and momentum | (5) |
| 2022 Paper I Q1 | Vector and scalar quantities | (4) |
| 2022 Paper I Q17 | Simple pendulum in an accelerating elevator | (4) |

All eight are candidates, not approved questions. All derived answers are unverified by an independent reviewer and are not official keys.

### 4.2 Exclusions

- 2022 Paper I Q2: held back for ambiguity review.
- 2025 Paper I Q3: held back for ambiguity review of the spring-length/spring-constant wording.
- Diagram-dependent items: deferred because the pilot is text-only and diagram accessibility is not yet designed.

### 4.3 Why this set

The set is small enough to review properly and spans measurement, mechanics and SHM. It is not a representative sample of the whole syllabus. The coverage limits are recorded in `PILOT_QUESTIONS.md`.

## 5. Stage 2 work plan

Stage 2 starts only after this plan is approved. It has six workstreams.

### W1. Content graph additions

**Goal:** give every candidate a credible primary concept and add the formulas, units and prerequisites T24 requires.

Work:

1. Design the missing concepts and claims:
   - measurement uncertainty and percentage error;
   - projectile motion and independence of horizontal/vertical motion;
   - static friction and the friction limit;
   - conservation of linear momentum and elastic/inelastic collisions;
   - scalar and vector quantities;
   - simple pendulum and effective gravity.
2. Add formula and unit representation as typed concepts or claims, not only prose.
3. Add prerequisite edges and objective mappings.
4. Record provenance for every new concept, claim and edge.
5. Decide the `reviewed_by` path before seeding (R5).

**Exit criteria:**

- graph tests still pass;
- no cycles or invalid edge types;
- every candidate has a reviewed primary concept;
- every new concept/claim has provenance;
- every new concept/claim that is marked approved has a real reviewer record, or is explicitly draft.

### W2. Draft envelopes

**Goal:** create one draft-only envelope per candidate.

Work:

1. Put the verbatim prompt and options in the ignored local review pack for page-image comparison.
2. Record the source block: filename, SHA-256, year, paper, question number, PDF page, medium.
3. Record the derived answer and non-verbatim derivation in the tracked candidate record.
4. Propose the rubric: exact, one correct option, `max_score = 1`, reviewer-set evidence ceiling.
5. Propose mappings and weights.
6. Record ambiguity, duplicate and coverage notes.
7. Set `validation_status = "draft"`, `source_class = null`, `target_source_class = "expert_verified"` and leave principals null until they exist.

**Exit criteria:**

- every draft envelope validates through `validate_pilot_envelope()` and its offline T12 check;
- every source reference matches `source_manifest.json`;
- no envelope claims an official key;
- every envelope is still draft and none is imported.

### W3. Provenance and review records

**Goal:** make qualified review auditable.

Work:

1. Define the review record: reviewer reference, qualification reference, independence declaration, scope, decision, date and content hash.
2. Define the reproduction/licence record.
3. Obtain real reviewer and approval decisions. Do not invent them.
4. Link the review record to the content hash and the source record.
5. Decide whether the pilot record stays file-based or needs a T12 table/column.

**Exit criteria:**

- every approved item has a real reviewer and qualification reference;
- every approved item has a resolved reproduction status;
- the review record is linked to the exact content hash;
- no placeholder principal or approval exists.

### W4. Validation tooling

**Goal:** make the T24 checks repeatable.

Work:

1. Add a schema check for the envelope.
2. Add a T12 draft-import check that uses no database.
3. Add exact and normalized duplicate checks.
4. Add ambiguity-field checks.
5. Add a coverage report by objective and concept.
6. Add negative tests for the publication branches T24 relies on.

**Exit criteria:**

- the checks run in CI without a database;
- a known duplicate fails;
- a missing primary mapping fails;
- a missing reviewer fails;
- a missing source record fails;
- the coverage report names both covered and uncovered objectives.

### W5. Import dry run and database verification

**Goal:** prove the real path works before publishing.

Work:

1. Convert only an approved envelope with `to_validated_import()`; never import a draft.
2. Run the approved-envelope import against a disposable PostgreSQL/pgvector database if an approved fixture exists. Otherwise record the database checks as not run.
3. Verify idempotency: the same bundle returns the same version.
4. Verify immutability: a published version cannot be edited.
5. Verify reference validation: foreign, draft or unapproved concepts/objectives are rejected.
6. Verify RLS and owner-scoped reads are not weakened.
7. Verify the rubric and mapping rows are written atomically.

**Exit criteria:**

- `backend/tests/test_question_db_contracts.py` and `backend/tests/test_migrations.py` pass in the disposable environment;
- an approved-envelope import creates the expected rows and no partial rows, or the check is explicitly reported as not run;
- replay does not create a duplicate version;
- no test points at a shared or production database.

### W6. Documentation and handoff

**Goal:** make the task reviewable and reproducible.

Work:

1. Record the review decisions and coverage report.
2. Record the exact commands and results.
3. Record known limitations, including the absence of an official key and the 2021 Tamil mismatch.
4. Update the task table only after the work is merged, not before.
5. Produce the pull request with the T24 evidence.

**Exit criteria:**

- the pull request lists the task, branch, specs, tests, migrations/generated artifacts (if any), security/privacy impact and follow-ups;
- no secret, source PDF or private student content is present;
- the task status is not marked Done before merge.

## 6. Required integration fixes versus optional improvements

### 6.1 Required

| ID | Fix | Why |
| --- | --- | --- |
| R1 | Question-level source provenance record | T12 has no source field; T24 requires provenance. |
| R2 | Reviewer qualification and approval record | A principal UUID is not qualification evidence. |
| R3 | Missing concepts, claims, formulas and units | Seven of eight candidates lack a complete mapping; only 2025 Q1 has a clean existing mapping. T24 requires formulas and units. |
| R4 | Duplicate, ambiguity and coverage checks | T24 explicitly requires them. |
| R5 | `reviewed_by` decision for new T24 concepts/claims | The T08 seed writes `reviewed_at` but not `reviewed_by`. |
| R6 | Negative tests for publication branches | T24 evidence must not rely on one indirect DB test. |

### 6.2 Optional

| ID | Improvement | Why optional |
| --- | --- | --- |
| O1 | Import CLI | The offline call path already exists. |
| O2 | Durable T12 question-provenance table | Better long-term audit, but a larger shared-surface change. |
| O3 | Semantic duplicate detection | Useful at scale; deterministic checks plus review may suffice for eight items. |
| O4 | OCR/transcription pipeline | Helpful for scale; OCR is never the authority. |
| O5 | Reviewer workflow UI | Outside the MVP; a real file-based record can suffice for the pilot. |

The detailed evidence for each item is in `T08_T12_CONTRACT_GAPS.md`.

## 7. Review and approval model

### 7.1 Draft is the default

Every candidate starts as `validation_status = "draft"` with `source_class = null`, `target_source_class = "expert_verified"` and null reviewer/approval metadata. A draft is offline-only and is never imported. An approved item must pass every T12 and pilot gate.

### 7.2 Approval is a separate act

An item becomes `approved` only when:

- a real reviewer principal exists;
- the reviewer is independent of the author;
- the reviewer's qualification is recorded;
- the review decision and date are recorded;
- the content hash matches the reviewed content;
- the rubric is approved with a positive evidence ceiling;
- at least one primary mapping exists;
- ambiguity and duplicate status are cleared;
- reproduction status is resolved;
- the explanation is non-empty.

### 7.3 No invented identities

Stage 1 has no reviewer, author or principal. Do not use a synthetic UUID in a real content record. Test fixtures may use synthetic IDs only inside tests, clearly labelled as fixtures.

## 8. Validation strategy

### 8.1 Stage 1 checks already run

```powershell
$env:PYTHONPATH="$PWD\backend\src"
.\.venv\Scripts\python.exe -m pytest backend/tests/test_pilot_content_validation.py backend/tests/test_pilot_mapping_report.py backend/tests/test_questions_models.py backend/tests/test_curriculum_seed.py backend/tests/test_questions_grading.py -q
```

Result: **93 passed**.

These are non-PostgreSQL tests. They cover T24 draft/approval gates, the read-only candidate mapping report, T12 model/hash/validation behavior and T08 seed integrity.

### 8.2 Synthetic import smoke test

A read-only smoke test called `validate_question_import()` with the synthetic draft from `examples/synthetic_draft.json` and no database. Results:

- synthetic draft with one mapping: accepted;
- approved without principals: rejected `reviewer_required`;
- source metadata in `content`: rejected `content_invalid`.

This is an import smoke test only. The T24 envelope, independence and hash/source gates are covered by `backend/tests/test_pilot_content_validation.py`. The smoke test is described in `CONTENT_SCHEMA.md` section 5.1 and `T08_T12_CONTRACT_GAPS.md` section 4.

### 8.3 Not run

```powershell
.\.venv\Scripts\python.exe -m pytest backend/tests/test_question_db_contracts.py backend/tests/test_migrations.py -q
```

Not run: no disposable PostgreSQL/pgvector environment and no `MEMORA_TEST_DATABASE_URL`. These tests are required before merge and must not use a shared or production database.

### 8.4 Stage 2 checks

- JSON Schema validation of every envelope.
- T12 draft validation of every bundle.
- Exact/normalized duplicate checks.
- Ambiguity and coverage report.
- Negative publication tests.
- PostgreSQL import, idempotency, immutability, reference and RLS tests.
- Migration check only if a migration is added.

## 9. Suggested commit boundaries

No commit has been made. If Stage 1 is approved for commit, keep the boundaries small:

| Commit | Message | Contents |
| --- | --- | --- |
| C0 | `chore(content): ignore local T24 source PDFs and review pack` | The two `.gitignore` rules already present in the working tree. |
| C1 | `docs(t24): add stage 1 source inventory and pilot plan` | `IMPLEMENTATION_PLAN.md`, `SOURCE_INVENTORY.md`, `source_manifest.json`. |
| C2 | `docs(t24): add pilot provenance schema and review checklist` | `CONTENT_SCHEMA.md`, `pilot_question.schema.json`, `REVIEW_CHECKLIST.md`, `T08_T12_CONTRACT_GAPS.md`. |
| C3 | `content(t24): add reviewed pilot graph additions` | New concepts/claims/edges/objectives, once designed and reviewed. |
| C4 | `content(t24): add draft pilot question bundles` | One draft envelope per candidate, all `validation_status = "draft"`. |
| C5 | `test(t24): add pilot duplicate ambiguity and coverage checks` | Validator and negative tests. |
| C6 | `test(t24): add pilot schema mapping and provenance tests` | Envelope/T12 contract tests. |
| C7 | `docs(t24): record review decisions and coverage report` | Real review records and coverage evidence. |
| C8 | `docs(t24): update task status after merge` | Task table update only after the merge actually occurs. |

Do not combine C3-C6 into one commit. Content additions, import bundles and validation tooling should be reviewable separately.

## 10. Risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| A derived answer is treated as an official key | Academic misinformation | Keep `official_key_claimed = false`; require independent review; record the marking-scheme limitation. |
| Source PDFs are committed | 349 MB of third-party material and licence risk | Apply the approved ignore rule; check the index; never stage source PDFs. |
| A reviewer identity is invented | False audit evidence | Leave principals null; block approval until a real record exists. |
| The pilot overclaims coverage | Misleading progress | Publish the coverage gap table; do not describe eight items as syllabus coverage. |
| Missing concepts are forced onto weak mappings | Bad memory evidence | Treat missing concepts as gaps; add reviewed concepts or exclude the item. |
| Reproduction is assumed | Legal/ethical risk | Keep reproduction status `unapproved` until a real approval exists. |
| PostgreSQL tests are skipped | Import/RLS defects reach merge | Require a disposable DB run before merge; report it separately. |
| T12 is changed without contract review | Shared-surface drift | Keep T12 changes in a separate task unless T24 approval explicitly includes them. |
| 2022 annotations contaminate transcription | Wrong prompt or answer | Compare with the page image; do not use handwritten ticks as a key. |
| 2021 Tamil paper is used as English | Curriculum/medium violation | Exclude it from English-medium content; record the filename mismatch. |

## 11. Open decisions

1. Is the repo-side provenance envelope sufficient for the pilot, or must T12 gain a durable provenance field before import?
2. Who is qualified to review A/L Physics content, and what qualification evidence will be recorded?
3. Will T24 add concepts/claims through the T08 seed writer or a separate reviewed-content path?
4. What is the reproduction/licence route for past-paper text?
5. Are the six missing topic areas in scope for T24, or should the candidate set be reduced?
6. Is deterministic duplicate/ambiguity checking sufficient for eight items?
7. Which disposable environment will run the PostgreSQL import, RLS and migration tests?

## 12. Stage 1 exit checklist

- [x] All 25 PDFs inventoried with size, SHA-256, page count, year, type and language.
- [x] Full hash manifest written.
- [x] 2021 Tamil mismatch recorded.
- [x] Marking-scheme page-2 limitation recorded.
- [x] 2022/2025 text-layer limitation recorded.
- [x] T08 graph counts and gaps recorded.
- [x] T12 import path and publication gates recorded.
- [x] T12 synthetic import smoke test run without a database.
- [x] Eight candidate questions summarized with derived answers; verbatim text moved to the ignored local review pack.
- [x] Candidate answers marked unverified and non-official.
- [x] Draft T12-compatible schema written.
- [x] Review checklist written.
- [x] Required versus optional integration fixes separated.
- [x] Suggested commit boundaries written.
- [x] `.gitignore` rules for source PDFs and the local review pack are present in the working tree; not committed.
- [x] No T08 seed, T12 model, migration, API or question data changed; the pilot validator and tests were added.
- [x] Safe non-PostgreSQL tests run: 93 passed.
- [ ] Reviewer, author and approval identities supplied by the project.
- [ ] Reproduction/licence route decided.
- [ ] Disposable PostgreSQL environment available for Stage 2 verification.
- [ ] Stage 1 artifacts approved for commit.

## 13. Stop point

The draft-only implementation stops here. Approval, graph expansion, real-principal assignment, import and database verification must not begin until the open decisions are answered and the review gates are real. In particular, do not:

- add the missing concepts to the seed;
- create question bundles with real principals;
- import any question;
- claim PostgreSQL/RLS verification;
- mark T24 Done.

## 14. Artifact map

| File | Purpose |
| --- | --- |
| `IMPLEMENTATION_PLAN.md` | This plan. |
| `SOURCE_INVENTORY.md` | Human-readable 25-file inventory, findings and working-tree ignore rules. |
| `source_manifest.json` | Machine-readable inventory with full hashes. |
| `PILOT_QUESTIONS.md` | Eight candidate records, non-verbatim derivations, mappings, ambiguity and coverage notes. |
| `CONTENT_SCHEMA.md` | Draft envelope, T12 mapping and synthetic worked example. |
| `pilot_question.schema.json` | Draft JSON Schema. |
| `examples/synthetic_draft.json` | Synthetic draft example used by the validator tests. |
| `backend/src/memora/modules/questions/pilot_validation.py` | Draft/approval gates and approved-envelope conversion. |
| `backend/tests/test_pilot_content_validation.py` | T24 validator and schema tests. |
| `candidate_mappings.json` | Read-only eight-candidate mapping report; not a T12 import or syllabus coverage claim. |
| `backend/tests/test_pilot_mapping_report.py` | Validates candidate IDs, summary-status consistency and referenced T08 codes. |
| `local_review/` | Ignored local verbatim review pack; never tracked or imported. |
| `REVIEW_CHECKLIST.md` | Per-item review gates, status matrix and sign-off table. |
| `T08_T12_CONTRACT_GAPS.md` | Evidence-backed gap analysis and required/optional fixes. |
