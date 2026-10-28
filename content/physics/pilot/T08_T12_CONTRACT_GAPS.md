# T08 / T12 Contract Gaps for T24

**Status:** Stage 1 analysis plus T24-only draft validation and a local disposable PostgreSQL check. No T08 or T12 production code, migration, API, table or seed data was changed. The new `pilot_validation.py` and its tests are T24-only and are not wired into T12.

## 1. Purpose and method

This report checks whether the completed T08 curriculum seed and T12 question bank can carry the T24 pilot content without silently weakening a contract. It uses:

- the actual T08 seed data and seed writer;
- the actual T12 models, validation, repository and tests;
- the schema, PRD and task-table authorities;
- a read-only T12 import probe that used no database and no real principals.

The probe result is evidence about contract shape only. It is not an approval of any question.

## 2. T08 baseline

### 2.1 What exists

`backend/src/memora/modules/curriculum/seed_data.py` currently contains:

| Item | Count | Detail |
| --- | ---: | --- |
| Learning objectives | 9 | Units 1-3 plus parent objectives. |
| Concepts | 14 | 6 `concept`, 4 `variable`, 3 `law`, 1 `principle`. |
| Claims | 15 | Includes `definition`, `condition`, `formula` and `misconception` claim types. |
| Concept edges | 16 | 15 `prerequisite_of`, 1 `related_to`. |
| Objectives actually used by concepts | 6 of 9 | `LO-PHYS-01-01-UNITS`, `LO-PHYS-01-02-DIMS`, `LO-PHYS-02-01-KINEMATICS`, `LO-PHYS-02-02-NEWTON-LAWS`, `LO-PHYS-02-03-WORK-ENERGY`, `LO-PHYS-03-01-SHM`. |

The 14 stable concept codes are:

`PHYS-MEA-SI-UNITS`, `PHYS-MEA-DIMENSIONS`, `PHYS-MEC-DISPLACEMENT`, `PHYS-MEC-VELOCITY`, `PHYS-MEC-ACCELERATION`, `PHYS-MEC-MOMENTUM`, `PHYS-MEC-NEWTON1`, `PHYS-MEC-NEWTON2`, `PHYS-MEC-NEWTON3`, `PHYS-MEC-WORK`, `PHYS-MEC-KINETIC-ENERGY`, `PHYS-MEC-GRAV-POT-ENERGY`, `PHYS-MEC-CONSERV-ENERGY`, `PHYS-WAV-SHM`.

### 2.2 What T08 does well

- The ontology, objective parentage and prerequisite graph are validated. See `backend/tests/test_curriculum_seed.py`:
  - `test_ontology_allowlists_conform_to_spec`
  - `test_learning_objectives_have_no_cycles`
  - `test_concept_edges_have_no_prerequisite_cycles`
  - `test_concept_edge_types_and_confidence`
  - `test_all_concepts_map_to_valid_learning_objectives`
  - `test_seed_data_provenance_is_populated`
- The seed is idempotent and has natural-key convergence tests.
- Concept-objective mappings carry provenance. `seed.py:155-160` writes `provenance_type` and `provenance_ref`.
- Claims and edges carry provenance. `seed.py:116-123` and `seed.py:127-138`.

### 2.3 What T08 does not contain

1. **No `formula`, `unit`, `method`, `diagram_skill` or `misconception` concept nodes.** The database allows all nine kinds (`Schema 7.3`; migration `20261023_0001_mvp_schema.up.sql:63`), but the seed uses only four. T24 explicitly requires formulas and units, not merely formula-shaped claims.
2. **No measurement-uncertainty concept.** `PHYS-MEA-DIMENSIONS` is dimensions and dimensional analysis, not error propagation.
3. **No projectile or two-dimensional kinematics concept.** The kinematics concepts are displacement, velocity and acceleration, and the objective is explicitly one-dimensional.
4. **No friction or static-friction concept.**
5. **No conservation-of-momentum principle and no elastic/inelastic collision concept.** `PHYS-MEC-MOMENTUM` is a `variable`, not a conservation law.
6. **No scalar/vector classification concept.**
7. **No simple-pendulum or effective-gravity concept.** `PHYS-WAV-SHM` is general SHM.
8. **No qualified-review identity in the seed writer.** `seed.py:85-91` writes `reviewed_at = now()` but not `reviewed_by`; `seed.py:116-123` does the same for claims. The columns exist (`Schema 7.3`, `7.5`) but are nullable and left null.

The first seven are content gaps, not defects in T08's accepted scope. They matter because the T24 candidate set was selected independently of the current graph.

## 3. T12 baseline

### 3.1 Supported import path

T12 deliberately has no HTTP import route. The documented boundary is:

```text
QuestionImportBundle
  -> validate_question_import()
  -> QuestionImportRepository.import_question()
```

Evidence:

- `docs/learning/T12_Study_Note.md:21-23`: import is a privileged offline path; wiring it into a student request would bypass review.
- `backend/src/memora/modules/questions/models.py:297`: `QuestionImportBundle`.
- `backend/src/memora/modules/questions/validation.py:242`: `validate_question_import`.
- `backend/src/memora/modules/questions/repository.py:518`: `QuestionImportRepository`.
- `backend/src/memora/modules/questions/repository.py:524`: `import_question`.
- `backend/src/memora/modules/questions/repository.py:793`: reference validation.

No CLI is required to import. A CLI would be an operator convenience, not a contract requirement.

### 3.2 Publication gate

For `validation_status = "approved"`, `validate_question_import()` requires (`validation.py:419-476`):

1. non-empty `explanation`;
2. non-null `reviewer_principal`;
3. non-null `author_principal` for non-AI content;
4. `rubric.status = "approved"`;
5. positive `evidence_ceiling`;
6. at least one `primary` concept mapping;
7. for numeric content with `unit_rule = "required"`, a unit affordance.

`teacher_authored` content is hard-disabled (`constants.py:21`, `TEACHER_CONTENT_ENABLED = False`). T12 also rejects AI content without complete generation metadata (`validation.py:479-489`).

T12 validation and the database publication trigger check that the reviewer and author principals are non-null; they do **not** compare the two values. Reviewer/author independence is enforced only by `pilot_validation.py`. Do not claim database enforcement of independence.

The publication branches above now have direct T12 regression tests in `backend/tests/test_questions_models.py`: missing reviewer, missing author, blank explanation, draft rubric, zero evidence ceiling, supporting-only mapping and source metadata inside `content`. The pilot envelope separately enforces reviewer qualification, independence, answer review, review/approval dates and content-hash/source binding.

### 3.3 Provenance surface

T12 has exactly one provenance surface on a question: `ConceptMappingImport.provenance_type` and `provenance_ref` (`models.py:286-294`). The repository copies those fields into `question_concept_maps` (`repository.py:743-748`). The canonical content hash covers them; `backend/tests/test_questions_models.py:183` is `test_hash_covers_mapping_provenance`.

T12 has **no** question-level field for:

- source paper or resource book;
- exam year;
- question number;
- PDF page;
- licence or reproduction approval;
- reviewer qualification;
- review decision or approval timestamp beyond the principal UUID.

`questions` stores `source_class`, `author_principal` and `reviewer_principal` (`Schema 9.1`). `question_versions` stores prompt, explanation, content, trust label, curriculum, validation status and generation metadata. Neither is a source-provenance record.

The `ChoiceContent` model is strict (`extra="forbid"`; `models.py:69-80`). Source metadata cannot be added to `content` without changing the shared T12 contract. T12 tests now assert `content_invalid` when `source_ref` or `licence` is placed inside `content`, and the pilot JSON Schema rejects the same payload.

For the pilot, source provenance lives only in the T24 envelope (`source`, `answer_verification`, `review`, `publication`). That envelope is validated offline and is not persisted by T12. The T12 owner must decide whether this is acceptable or whether a durable question-provenance field is required; see `T12_OWNER_ACCEPTANCE.md`.

### 3.4 Storage and immutability

- Published versions are immutable (`Schema 9.1`; migration `20261023_0005_question_bank_integrity.up.sql`).
- `QuestionImportRepository.import_question()` is idempotent by canonical content hash; it returns `created: false` for an existing identical version (`repository.py:577-598`).
- Existing identical content with a different validation status raises `duplicate_question_version`.
- A question code cannot change source class (`repository.py:549-554`).
- Import is transactional per question; options, rubric and mappings are written in one transaction.
- PostgreSQL tests cover idempotency, immutability, publication guard, pinned history and reference validation (`backend/tests/test_question_db_contracts.py`).

## 4. Import smoke-test results

This is an **import smoke test only**, not the T24 envelope test. A temporary Python probe built the synthetic draft from `examples/synthetic_draft.json`, converted its `question` member with the target source class, and called T12 `validate_question_import()` with no database.

```text
synthetic_draft_with_mapping: ACCEPTED status=draft type=mcq mappings=1 hash=ea7f85853b4280ba8bb4865bfe665c1da28233958308f884492919a9820c73e1
approved_without_principals: REJECTED code=reviewer_required field=reviewer_principal
content_with_source_metadata: REJECTED code=content_invalid field=content
```

Interpretation:

- T12 accepts a draft MCQ with a real T08 concept/objective ID.
- T12 rejects approval when the reviewer principal is absent, even if the author is also absent. The first failure reported is `reviewer_required`.
- T12 rejects an extra `source_ref` field inside `content`; the strict content model cannot carry source metadata.
- The hash is a probe value for the synthetic draft, not an approved content hash.
- The smoke test does not test `validate_pilot_envelope()`, reviewer independence, the draft `source_class = null` rule, content-hash binding or source-reference binding. Those are covered by `backend/tests/test_pilot_content_validation.py`.

This confirms that the blockers are provenance, review identity and content coverage, not MCQ schema compatibility.

### 4.1 Schema, validator and publication-branch checks run locally

| Check | Result |
| --- | --- |
| `pilot_question.schema.json` against the Draft 2020-12 metaschema with `jsonschema 4.26.0` | valid |
| Synthetic draft payload against the schema | 0 errors |
| Approved synthetic payload against the schema | valid |
| Draft contradictions, missing approval evidence and source metadata in `content` | rejected |
| Pilot envelope validator tests | 32 passed |
| Candidate mapping report tests | 5 passed |
| Evidence-status report tests | 4 passed |
| JSON Schema payload/metaschema tests | 10 passed |
| T12 model, publication-branch and content-smuggling tests | 32 passed |

The schema is a structural contract only. `pilot_validation.py` and T12 `validate_question_import()` remain the semantic authorities. The schema and validator are kept consistent for the fields exercised by the tests.

## 5. Gap matrix

Severity is about the T24 acceptance gate, not about T12 runtime safety.

| ID | Gap | Severity | Required for T24? | Evidence | Impact |
| --- | --- | --- | --- | --- | --- |
| G1 | No question-level source provenance in T12 | High | Yes | `models.py:297-331`; `Schema 9.1`; `Schema 9.4` | A question can be traced to a concept mapping but not to a paper/year/question number. The T24 provenance gate cannot be met by T12 alone. |
| G2 | No reviewer qualification or approval record | High | Yes | `questions.reviewer_principal` is a bare UUID (`Schema 9.1`); T08 writes `reviewed_at` without `reviewed_by` (`seed.py:85-91`, `116-123`) | "Qualified review is recorded" is not demonstrated by a principal UUID. |
| G3 | Seed uses only 4 of 9 concept kinds | High | Yes | `seed_data.py` counts: 6/4/3/1; `Schema 7.3` allows 9 kinds | T24 requires formulas and units as typed content; current nodes do not represent them as `formula` or `unit`. |
| G4 | Candidate topics absent from the graph | High | Yes | 14-concept inventory; candidate mapping table in `PILOT_QUESTIONS.md` | Seven of eight items lack a complete mapping; only 2025 Q1 has a clean existing primary/supporting mapping. |
| G5 | No duplicate, ambiguity or coverage report | High | Yes | Search found no such tooling in `backend/src/memora/modules/questions` or `curriculum`; only `coverage_weight` in a mapping | T24 explicitly requires ambiguity, duplicate and coverage evidence. |
| G6 | `reviewed_by` never written by the T08 seed | Medium-High | Yes, if T24 adds seed concepts/claims | `seed.py:85-91`, `116-123` | New seeded content would be marked reviewed without a reviewer identity. |
| G7 | No import CLI | Low | No | `T12_Study_Note.md:21-23`; `repository.py:524` | A CLI is convenient but unnecessary; the offline call path already exists. |
| G8 | `content` cannot carry source metadata | Medium | Yes, as part of G1 | `ChoiceContent` `extra="forbid"`; probe `content_invalid` | A source reference cannot be smuggled into the question payload. |
| G9 | No real author or reviewer principal | Blocker | Yes | Stage 1 has no identity record; probe `reviewer_required` | Every candidate is limited to draft. |
| G10 | Not every publication branch has an isolated unit test | Closed for T12 | Yes, for T24 evidence | `test_questions_models.py` now covers `reviewer_required`, `author_required`, blank explanation, draft rubric, zero evidence ceiling, empty and supporting-only mappings, and source metadata in `content`. The DB test remains additional coverage. | T12 publication branches have direct regression tests; the T24 envelope has separate approval-gate tests. |
| G11 | No official MCQ key | Blocker | Yes | Marking-scheme page-2 layouts are not MCQ keys; none found | Derived answers cannot be presented as official keys. Independent review is mandatory. |
| G12 | Reproduction/licence route unresolved | Blocker | Yes | No policy or approval record found in the repository | Source text cannot be committed or published without a decision. |
| G13 | Source PDFs and the local verbatim pack are untracked | Low operational | Yes, before commit | The working-tree `.gitignore` now contains `/content/physics/source_documents/` and `/content/physics/pilot/local_review/`; the local index had no `.pdf`/`source_documents` entries at inspection | A broad `git add` no longer stages the source PDFs or the local verbatim pack, but the rules must remain present and be verified before commit. |
| G14 | PostgreSQL-dependent tests need CI acceptance | Locally closed; CI open | Yes, before merge | A disposable `memora_t24_test` database ran 27 tests: 9 migration and 18 question-database contracts, 0 failed. No CI/staging acceptance exists. | Local import, RLS and immutability behaviour is verified; release acceptance still needs a CI or approved staging run. |

## 6. Required integration fixes

These are the minimum changes or decisions needed before a T24 `approved` import.

### R1. Add a question-level source provenance record

**Why:** G1, G8.

**Minimum path:** keep the versioned `source` envelope in `content/physics/pilot/` and link it to `question_code`; validate that every imported question has exactly one source record whose SHA-256 and page reference match `source_manifest.json`.

**Durable path:** add a T12 question-provenance table or a bounded JSONB column on `question_versions`, then migrate the envelope fields. This is a shared-contract change and needs its own task boundary, migration, OpenAPI impact review and backfill plan.

**Acceptance evidence:** a schema/provenance test that fails when the source record is missing, the SHA-256 is wrong, the question number is wrong or the source is not English-medium.

### R2. Add a real review and qualification record

**Why:** G2, G9.

**Minimum path:** a versioned review record with:

- reviewer reference (real principal or external reviewer ID);
- qualification evidence reference;
- independence declaration;
- review scope;
- decision and date;
- content hash reviewed;
- ambiguity and duplicate decisions.

**Durable path:** a reviewer/approval table or an auditable review artifact with a stable ID. A principal UUID alone is not enough.

**Acceptance evidence:** an approval gate that rejects `approved` content with no review record or no qualification reference.

### R3. Add the missing concepts and claims

**Why:** G3, G4.

The candidate set needs reviewed graph additions for:

- measurement uncertainty and percentage error;
- projectile motion and independence of horizontal/vertical motion;
- static friction and the friction limit;
- conservation of linear momentum and elastic/inelastic collisions;
- scalar and vector quantities;
- simple pendulum and effective gravity.

T24 also needs formula and unit nodes/claims, not only formula-shaped prose. The exact IDs, objective parentage and prerequisite edges must be designed and reviewed; none are invented in Stage 1.

**Acceptance evidence:** every candidate has at least one primary existing concept with a reviewed mapping; graph tests still pass; no cycles or invalid edges.

### R4. Add duplicate, ambiguity and coverage checks

**Why:** G5.

**Minimum path:** a deterministic content validator that checks:

- exact prompt duplicates;
- exact option-set duplicates;
- normalized near-duplicates;
- required ambiguity fields;
- coverage by objective and concept;
- explicit uncovered gaps.

Semantic duplicate detection can be added later if deterministic checks are insufficient for the pilot. Do not claim semantic coverage from an exact-match script.

**Acceptance evidence:** a report over the eight candidates and a negative test for a known duplicate.

### R5. Decide how new T24 concepts/claims record `reviewed_by`

**Why:** G6.

Options:

1. Extend the T08 seed writer to accept and write a real reviewer principal. This changes T08 code and is a shared-contract change.
2. Seed T24 content through a separate reviewed-content path that writes `reviewed_by`.
3. Keep T24 concepts/claims out of the T08 seed and import them through a reviewed artifact.

Stage 1 does not choose. The decision must be explicit before any new concept or claim is seeded.

### R6. Add negative tests for the publication branches T24 relies on

**Why:** G10.

At minimum:

- approved without reviewer -> `reviewer_required`;
- approved without author -> `author_required`;
- approved with empty explanation -> `publish_requirements_missing`;
- approved with draft rubric -> `publish_requirements_missing`;
- approved with zero evidence ceiling -> `publish_requirements_missing`;
- approved without primary mapping -> `concept_mapping_missing`.

The existing DB test covers the reviewer branch at database level, but T24 should not rely on one indirect test.

**Implemented in T24.** `backend/tests/test_questions_models.py` now covers all six branches plus supporting-only mapping and source metadata in `content`:

- `test_import_rejects_approved_question_without_required_principals` (`reviewer_required`, `author_required`);
- `test_import_rejects_approved_question_without_explanation`;
- `test_import_rejects_approved_question_with_draft_rubric`;
- `test_import_rejects_approved_question_with_zero_evidence_ceiling`;
- `test_import_rejects_publication_without_primary_mapping` and `test_import_rejects_supporting_only_mapping_for_publication`;
- `test_source_metadata_cannot_be_smuggled_into_question_content`.

These are T12 tests, not T24-envelope tests. They do not weaken or replace the PostgreSQL checks.

## 7. Optional architecture improvements

These are useful but not required to close the pilot.

### O1. Import CLI

A thin operator command that loads the JSON envelope, strips provenance, validates and calls `QuestionImportRepository.import_question()`. It must remain offline and privileged. It must not become an HTTP route.

### O2. Durable T12 question-provenance table

A normalized table with source type, authority, year, paper, question number, page, document hash, licence state and approval reference. Better than the envelope for querying and audit, but a larger shared-surface change.

### O3. Semantic duplicate detection

Embedding-based comparison of prompts and explanations. Useful as the bank grows; not necessary for eight items if deterministic checks and human review are documented.

### O4. OCR and transcription pipeline

A repeatable OCR/extraction step with page-image comparison. Helpful for scale, but OCR must never be the authority for a question or answer.

### O5. Reviewer workflow UI

A review queue, qualification registry and approval dashboard. Outside the MVP; a file-based review record is sufficient for the pilot if it is real and auditable.

## 8. Test coverage and environment

### 8.1 Non-database tests

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

Result: **123 passed, 0 failed, 0 skipped**.

Breakdown: 32 pilot-envelope tests, 5 mapping-report tests, 4 evidence-status tests, 10 JSON Schema tests, 32 T12 model/publication tests, 13 curriculum-seed tests and 27 grading tests.

### 8.2 Disposable PostgreSQL/pgvector tests

A dedicated `memora_t24_test` database was created inside the local Compose `infra-postgres-1` container. It is not the development database. The migration tests downgrade to base, so they must never run against a shared database.

```powershell
$dbPassword = docker compose --env-file .env -f infra/compose.yaml exec -T postgres printenv POSTGRES_PASSWORD
$encoded = [uri]::EscapeDataString($dbPassword.Trim())
$env:MEMORA_TEST_DATABASE_URL = "postgresql+psycopg://memora:$encoded@127.0.0.1:5432/memora_t24_test"
$env:PYTHONPATH="$PWD\backend\src"
.\.venv\Scripts\python.exe -m pytest backend/tests/test_migrations.py backend/tests/test_question_db_contracts.py -q
```

Result: **27 passed, 0 failed, 0 skipped** (9 migration tests, 18 question-database contract tests). This includes:

- upgrade to head, downgrade to base and upgrade again;
- RLS owner isolation and append-only guards;
- API-role grants and protected-table coverage;
- import idempotency, version immutability and publication guards;
- owner-scoped pinned question history;
- foreign/draft curriculum, concept and objective rejection;
- generated-content grounding checks.

The run proves local behaviour only. It is not CI or staging acceptance.

**Repeat-run caveat:** the RLS migration test uses fixed OIDC subjects (`test` / `one` and `test` / `two`) and inserts users with `ON CONFLICT DO NOTHING`. Re-running it against the same non-reset database can resolve a pre-existing user row and fail the user-ID assertion. Recreate the `_test` database before a repeat run. This is a test-harness idempotence limitation, not an RLS policy failure; the fresh-database run and the targeted rerun both passed.

### 8.3 Existing coverage that matters

| Area | Existing evidence |
| --- | --- |
| T08 ontology and cycles | `backend/tests/test_curriculum_seed.py` |
| T08 provenance | `test_seed_data_provenance_is_populated`, `test_curriculum_mapping_provenance_in_seed` |
| T12 content hash | `backend/tests/test_questions_models.py` |
| T12 publication branches | reviewer, author, explanation, rubric, evidence-ceiling and mapping tests in `test_questions_models.py` |
| T12 source-metadata rejection | `test_source_metadata_cannot_be_smuggled_into_question_content` |
| T12 idempotency and immutability | `test_import_is_idempotent_and_versions_are_immutable` |
| T12 DB publication guard | `test_publication_guard_validates_the_complete_content_set` |
| T12 RLS and pinned history | `test_pinned_question_history_stays_readable_only_to_its_owner`; migration RLS tests |
| T12 reference validation | `test_import_rejects_foreign_or_unapproved_concept_mapping` and related tests |
| Pilot T08 concept/objective resolution | `test_mapping_concept_must_exist_in_the_t08_seed`, `test_mapping_objective_must_match_the_t08_concept_objective`; mapping-report tests |
| Pilot schema | `backend/tests/test_pilot_schema_jsonschema.py` |

The T24 pilot validator is covered by 32 tests. The mapping report is covered by 5 tests, the evidence report by 4, and real JSON Schema validation by 10. These do not replace the PostgreSQL import, RLS and immutability tests.

## 9. Decisions needed before Stage 2

1. Is the repo-side provenance envelope acceptable for the pilot, or must T12 gain a durable question-provenance field before import? **Open; T12 owner decision.**
2. Who is qualified to review A/L Physics content, and what qualification evidence will be recorded? **Open; academic content lead.**
3. Will T24 add concepts/claims through the T08 seed writer, or through a separate reviewed-content path? **Open; curriculum lead.**
4. What is the reproduction/licence route for past-paper text? **Open; project/legal owner.**
5. Are the six missing topic areas in scope for T24, or should the candidate set be reduced to items already covered by T08? **Open; curriculum lead.**
6. Is deterministic duplicate/ambiguity checking sufficient for eight items, or is semantic checking required before approval? **Open; independent reviewer.**
7. Which environment will run the PostgreSQL import, RLS and migration tests for acceptance? **Locally answered with `memora_t24_test`; CI/staging acceptance still open.**

The working tree now contains a draft-only validator, synthetic example, real JSON Schema validation, structured mapping/evidence reports and focused T12 regression tests. It does not contain an approved question, a real reviewer, a reproduction decision or an imported pilot question. Approval remains blocked until these decisions are answered.

## 10. What this checkpoint did not change

- No T08 seed data or seed logic.
- No T12 production model, validation, repository, route or migration. The new `pilot_validation.py` and its tests are T24-only and are not wired into T12.
- No migration.
- No table or column.
- No API contract or generated client.
- No past-paper question data or import; one synthetic draft example was added.
- The source-PDF and local-review-pack ignore rules are present in the working tree; no Git command was run.
- No commit, branch, push or merge.
- No production or shared database was touched. The local Compose PostgreSQL container was used only through the disposable `memora_t24_test` database.
