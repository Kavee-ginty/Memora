# T12 question bank and grading backend

This note explains the reviewed-content import, immutable question versions,
deterministic grading and report/dispute backend implemented for T12. It is a
guide to the code and its invariants, not a replacement for the specifications.

T12 targets the `task/T12-questions-grading` branch but is not marked Done in the
task table. Mobile screens, mission assembly and completion remain T07 and T13
work.

## 1. Contract surface

T12 owns the three report operations in the reviewed inventory:

| Operation | Method and path | Success |
| --- | --- | --- |
| `createQuestionReport` | `POST /v1/questions/{question_version_id}/reports` | `201` |
| `listQuestionReports` | `GET /v1/question-reports` | `200` |
| `getQuestionReport` | `GET /v1/question-reports/{report_id}` | `200` |

Question import is deliberately not an HTTP route. It is a privileged offline
import path used by reviewed content tooling. Wiring `QuestionImportRepository`
into a student request would bypass the offline-review boundary.

The create request accepts `report_type`, an optional bounded `description` and
the related `attempt_id` when a grading dispute is being raised. The route uses
the shared `Idempotency-Key` header from the T05 contract. The list route uses the
shared `Page[T]` cursor shape, `limit` 1–100 and an opaque cursor.

## 2. Typed content and reviewed import

`models.py` defines strict Pydantic models for content, rubrics, options,
mappings, answers and the public pre-submission payload. Unknown fields are
forbidden. The stored JSONB payloads are parsed back into the same models, so a
database row cannot silently become a different shape.

Import follows this pipeline:

```text
QuestionImportBundle
        ↓
validate_question_import()
  - parse content and rubric for the declared question type
  - validate options, claims, mappings and publication rules
  - derive the trusted label and canonical content hash
        ↓
ValidatedQuestionImport
        ↓
QuestionImportRepository.import_question()
  - advisory lock on subject + question_code
  - validate curriculum, concept, objective and AI grounding references
  - replay when the canonical hash already exists
  - otherwise append version_no = max + 1
  - insert options, rubric and concept mappings under a draft version
  - publish to approved in the same transaction when reviewed
```

The canonical SHA-256 hash covers every immutable content, grading and provenance
field of a version:

- subject and curriculum IDs, question type, source class, trusted label, prompt,
  explanation, content and options;
- rubric type, version, payload, maximum score, evidence ceiling and status;
- every concept mapping, including its role, weight and provenance;
- generated-question provenance: model key, prompt version, grounding claim IDs,
  validator version and score, and generation trace reference.

Numeric fields that live in fixed-scale PostgreSQL columns are quantized to the
column scale before hashing (`max_score` to `0.001`; ceilings, weights and
validation scores to `0.00001`). Stored content and rubric JSONB are parsed back
through the typed models before hashing, so a replay after database rounding still
matches the import rather than creating a spurious new version. A real
within-scale change still creates a new immutable version. Exact replay returns
the existing version with `created: false`. The same question code cannot change
source class, and identical content with a different validation status is rejected
instead of silently changing history.

### Reference validation

An import is rejected unless:

- the curriculum is approved and belongs to the bundle subject;
- every mapped concept and concept version is approved and belongs to the bundle
  subject;
- every supplied learning objective is approved, belongs to the bundle
  curriculum, and is mapped to the mapped concept version;
- an approved question has at least one mapping aligned to an approved objective
  in its curriculum;
- each AI grounding ID resolves to an approved knowledge claim whose approved
  concept version belongs to the same subject and maps to an approved objective
  in the question's curriculum.

These checks close the gap between a syntactically valid UUID and a real,
reviewed, in-scope source. Missing, disputed, retired, cross-subject and
cross-curriculum claims are rejected.

### Source precedence and trust

The precedence order is:

1. `expert_verified`
2. `teacher_authored`
3. `ai_generated`

Lower ranks are selected first. T12 exposes the rank through
`source_precedence_rank`; T13 consumes it when assembling missions. The MVP
hard-disables teacher-authored content until the approved workflow flag exists.
AI-generated content must carry model key, prompt version, non-empty grounding
evidence, validator version, validation score and generation trace reference, and
its evidence ceiling cannot exceed `0.9`.

Every version stores a server-derived trust label. A caller cannot supply a
different label.

### Publication prerequisites

An approved version requires:

- an approved parent question;
- a non-empty explanation;
- a reviewer principal;
- an author principal unless the content is AI-generated;
- an approved rubric with a positive evidence ceiling;
- at least one primary concept mapping with positive weight;
- for option questions, 2–10 options, at least one correct option and exactly one
  correct option for single-choice;
- for a numeric question with a required unit, a unit affordance;
- complete AI grounding metadata when applicable.

The pure validator fails before rows are written. The database publication guard
repeats the structural checks as a deferred constraint trigger, so a direct SQL
publication cannot bypass them. AI metadata truthiness and the `0.9` evidence
ceiling remain enforced by the Python import validator rather than the trigger.

### Why approved imports are staged as draft

The database treats published question content as immutable. Inserting child
options, rubrics or mappings directly under a parent version that is already
`approved` would look like an edit of live content and would be rejected.

`QuestionImportRepository` therefore inserts the new version as `draft`, writes
all children, and then updates the version to `approved` inside the same
transaction. The publication guard is deferred and runs on the completed set. The
transaction either publishes a complete question version or rolls back.

## 3. Answer keys never leak before submission

`QuestionSnapshot.public_question()` builds the student payload. It includes only:

- question version ID, type, prompt and media;
- option key, display text, accessible image reference and order;
- response configuration such as selection mode, unit affordance or character
  limit;
- trust label.

It excludes `is_correct`, option explanations, expected numeric values,
tolerances, rubric claims, contradictions and the question explanation. The
`PublicQuestion` models have no fields capable of carrying those values.

The snapshot loader is owner-scoped through `memora_api` and the transaction-local
user context. A pinned version stays readable to the mission owner after the
parent question is retired, but not to another user.

## 4. Deterministic grading

`grade_answer(snapshot, answer)` returns a `GradeOutcome` containing normalized
score, classification, confidence, grader type/version, public outcome, feedback
code and evidence. It never returns rubric internals, expected values, hidden
reasoning or the raw student answer.

### MCQ and option-based questions

Grading compares the selected option-key set with the stored correct set.

- Exact set match: score `1`, classification `correct`, public outcome `recalled`.
- Any mismatch: score `0`, classification `incorrect`, public outcome `weak`.
- Unknown option keys or a wrong answer shape: `ungradable`, confidence `0`,
  influence limited, repair action `confirm_or_appeal`.

Single-choice answers must contain exactly one key; multiple-choice answers can
contain several unique keys. Confidence is capped by the rubric evidence ceiling.

### Numeric questions

Numeric rules are per question version; there is no universal tolerance.

- `unit_rule` is `required`, `optional` or `ignored`.
- Units are compared after normalization (Unicode NFKC, case folding, whitespace
  removal, middle-dot normalization). There is no unit conversion in the MVP.
- `required` with no unit, or a wrong unit, is incorrect and explains the unit
  problem.
- `optional` accepts an absent or blank unit, but a present unit must match.
- `ignored` does not inspect the unit.
- `allow_negative` defaults to true; when false, a negative answer is incorrect
  with reason code `negative_not_allowed` before tolerance is applied.
- Significant-figure rounding is applied to both the answer and expected value
  before tolerance.
- `tolerance` defines full credit. An optional wider `partial_tolerance` yields
  score `0.5`, classification `partial` and public outcome `partial`.
- Outside both bands: score `0`, classification `incorrect`, public outcome
  `weak`.

Relative tolerance is measured against the expected magnitude and cannot be used
with a zero expected value.

### Bounded short answer

The MVP uses `DeterministicClaimEvaluator`, an exact normalized phrase matcher.
`ClaimEvaluator` is a protocol so a validated evaluator can be added later without
changing grading or persistence. An evaluator receives one stored rubric claim and
the normalized response and may return only `ClaimEvidence`:

- `matched_variant`: a phrase the evaluator claims is present;
- `contradiction_phrase`: a contradiction phrase it claims is present.

The server ignores any claim identity, required flag, weight, score or confidence
from the evaluator. It takes the claim ID, required status and weight from the
stored rubric, canonicalizes the cited phrase against that claim's declared
variants or contradictions, and requires the cited phrase to occur in the
learner's normalized response. Anything undeclared or absent from the response is
discarded and reported through `evidence.evaluator_evidence_rejected: true`; it
cannot add coverage or turn an answer into a misconception. If an evaluator cites
a match and a contradiction for the same claim, the contradiction wins and no
credit is awarded. Optional claim weight never increases coverage because the
score is derived only from required claims.

Rubric claims have required/optional status, weight, bounded variants and
contradiction phrases. Phrases must be unique after normalization across the whole
rubric. Matching is on alphanumeric token boundaries.

Extreme numeric answers cannot crash significant-figure rounding; invalid or
overflowing exponents fail closed to the unrounded value and are handled by the
existing tolerance logic.

Outcomes are deliberately capped:

| Situation | Score | Classification | Confidence cap | Typical influence |
| --- | ---: | --- | ---: | --- |
| All required claims matched | `1` | `correct` | `0.85` | normal* |
| Coverage at or above the rubric minimum, but missing a required claim | coverage | `partial` | `0.65` | limited |
| Any contradiction phrase matched | `0` | `misconception` | `0.80` | normal* |
| No supported coverage | `0` | `ungradable` | `0.40` | limited |

Effective confidence is the lower of the rubric evidence ceiling and the cap.
`influence_limited` is true when that value is below `0.7` (*) or the classification
is `ungradable`/`invalidated`. Uncertain answers offer `confirm_or_appeal`; they
are never converted into confident recall evidence.

## 5. Reports, disputes and provenance

Reports are owner-scoped records. The repository resolves the local user from the
validated issuer and subject, selects the restricted `memora_api` role and sets the
transaction-local user context before any query. Cross-user reads and attempts
return `404 resource_not_found`, not a distinguishable authorization error.

A report target is valid when:

- `attempt_id` is supplied and belongs to the caller, and its mission item pins
  the same question version; or
- no attempt is supplied and the question version is approved.

A grading dispute must include the related attempt. Report creation never updates
the historical question, rubric, grading result or attempt. An open
`grading_dispute` or `answer_error` is reported as
`evidence_state: limited_pending_review` only when it is linked to an attempt;
a report without an attempt remains `recorded`. `review_required` is true for any
open report because every report still needs review.

`QuestionReportRepository.attempt_evidence_eligibility()` is the T13-facing hook.
For the owner's attempt it returns `eligible` or `limited_pending_review` by
checking for an open `grading_dispute` or `answer_error` linked to that attempt.
T13 must not consume attempt evidence for memory, XP, streak, reef or other
high-impact updates while the result is limited. A missing or foreign attempt
returns the same `404 resource_not_found` shape as other owner-scoped reads.

### Idempotency

`createQuestionReport` uses the shared idempotency record keyed by user scope,
operation and `Idempotency-Key`. A replay with the same request hash returns the
existing report; the route still returns `201`. Reusing the key with a changed body
returns `409 idempotency_key_reused`. An in-flight record returns a retryable
`409 operation_in_progress`.

### Description encryption

Optional free text is encrypted with AES-256-GCM before storage. A fresh 12-byte
nonce is generated per report, and the associated data binds the ciphertext to the
report encryption context, issuer, subject, question version and report ID. The
key is derived with HKDF-SHA-256 from the existing
`MEMORA_DEVICE_ENCRYPTION_KEY`; no new secret is introduced.

The plaintext description is never logged or returned. Responses expose only
`description_present`. A report without a description does not need the encryption
key; a report with one fails safely with `503 temporarily_unavailable` when the key
is missing or invalid.

### Pagination

The list query orders by `(submitted_at DESC, id DESC)` and uses a keyset cursor
over the same tuple. The cursor is base64url JSON with a version marker, UTC
timestamp and report ID. Invalid or stale-version cursors return `400
invalid_cursor`. `has_more` is derived by fetching `limit + 1` rows.

## 6. Database integrity

Migration `20261023_0005_question_bank_integrity` adds the enforcement that cannot
be expressed by application code alone:

- question identity columns are immutable and a question with versions cannot be
  deleted;
- a question version is immutable after use (pinned by a mission item);
- options, rubrics and concept mappings are immutable once the version is
  published or used;
- a deferred publication guard validates the complete approved content set;
- report provenance columns are immutable while status, resolution code and
  resolution time may change during review;
- a check constraint requires `resolved_at` exactly when a report is `resolved` or
  `dismissed`;
- pinned historical read policies keep retired content visible to the mission
  owner only;
- indexes support owner report history and mission-item/version lookups.

The report trigger allows the review workflow to resolve a report without
rewriting the student's original submission. Regrading remains an append-only
operation outside T12; T12 only records the dispute and limits its influence while
review is open.

## 7. Verification

Backend tests cover model bounds and source precedence, canonical-hash coverage of
every immutable field, database-scale normalization, reference and grounding
validation, answer validation, pre-submission redaction, MCQ/numeric/short-answer
grading fixtures, evaluator-authority boundaries, report encryption, cursor
behavior, API payloads and route headers.

PostgreSQL integration tests cover import replay/versioning, replay after numeric
rounding, approved-content immutability, publication prerequisites, pinned draft
immutability, owner-only historical reads, curriculum/concept/objective alignment,
missing/disputed/cross-subject/cross-curriculum AI grounding, report
idempotency/ownership/pagination/encryption, report provenance with grading
preservation, `answer_error` recorded without an attempt, and attempt-evidence
eligibility before and after dispute resolution.

Commands run from the repository root unless noted:

```powershell
cd backend
$env:MEMORA_TEST_DATABASE_URL = 'postgresql+psycopg://memora:memora@127.0.0.1:5432/memora_test'
..\.venv\Scripts\python.exe -m ruff check .
..\.venv\Scripts\python.exe -m ruff format --check .
..\.venv\Scripts\python.exe -m pytest
..\.venv\Scripts\python.exe -m pytest tests\test_question_db_contracts.py tests\test_migrations.py -q

cd ..
.\.venv\Scripts\python.exe tools\contracts\generate_contracts.py --check

cd mobile
flutter analyze
flutter test
```

Results:

- Ruff lint and format checks pass; 66 backend files formatted.
- Full backend suite with `MEMORA_TEST_DATABASE_URL` configured: 248 passed, with
  one existing Starlette/httpx deprecation warning.
- Focused PostgreSQL question contract suite: 18 passed.
- `generate_contracts.py --check` exits `0` after export, generation, formatting
  and comparison. It reports the same five pre-existing unused-model
  recommendations.
- Flutter analyzer reports no issues; Flutter tests: 58 passed.

The generated artifact and Dart client are produced only by
`tools/contracts/generate_contracts.py`; generated files are never hand-edited.
The report routes are present in `contracts/openapi/memora-v1.json` and the Dart
client exports the corresponding `ReportsApi` and report models.

## 8. Boundaries and follow-ups

- T13 must pin the question version and persist grading results; T12 supplies the
  pure grading service and snapshot loader, not mission assembly.
- T13 must call `attempt_evidence_eligibility()` before using an attempt for
  memory, XP, streak, reef or other high-impact updates and honour
  `limited_pending_review`.
- The import repository is for offline reviewed content. No admin HTTP endpoint is
  introduced here.
- Report review/resolution is a future workflow. T12 records reports and exposes
  safe status; it does not build a reviewer console.
- Short-answer grading is intentionally deterministic in the MVP. A model-backed
  evaluator can implement `ClaimEvaluator` later, but may emit only bounded
  `ClaimEvidence`; the server continues to derive outcomes from the stored rubric.
- Report descriptions depend on `MEMORA_DEVICE_ENCRYPTION_KEY`. Environments that
  enable descriptions must provision it before deployment.
- T12 must not be marked Done until the branch is reviewed, merged and the task
  table is updated with all code, tests, migration and generated artifacts.

## Specification map

- PRD requirements 017–022 (source precedence, formats, grounding, feedback
  confidence, reporting and optional timing).
- TRD 12 (source precedence, grading methods, generated-question validation and
  disputes).
- Backend Schema 9 (questions, rubrics, concept mappings, reports) and 11.4
  (grading results).
- API and Integration Contract 13 (mission questions and grading) and 15 (reports,
  disputes and corrections).
- Task table T12 scope and acceptance gate.
