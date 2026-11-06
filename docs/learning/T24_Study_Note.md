# T24 Verified Physics Pilot Content - Study Note

## 1. The Core Analogy: A Reference Standard and a Signed Review

An official past-paper marking scheme is a **reference standard**. It tells us
which option the examination board marked correct. It does not, by itself,
certify the explanation, the curriculum mapping, the accessibility of the
wording or the absence of ambiguity.

T24 therefore uses two separate ideas:

- the **official grid** verifies the answer key;
- a **named teacher review** verifies the surrounding content, and records
  exactly who reviewed it and under what qualification claim.

For this pilot the reviewer is also the author. That is a **self-review**. The
record says so instead of pretending a second person checked the work. The
envelope uses `independent_review_status = "self_review"`, not `"verified"`.

## 2. Two Verification Modes

### A. `official_marking_scheme` (historical pilot mode)

This was the original T24 route and is retained for official-key-only content.

- Source type must be a past paper.
- The official key must be present in the printed marking-scheme grid.
- The transcription must be checked visually against the page image.
- The author, reviewer and qualification fields are null.
- `independent_review_status` and `academic_review_status` are `not_required`.
- The envelope must reference `DEVIATION_REVIEW_MODE.md`.
- Import is blocked because T12 needs named author and reviewer principals.

`DEVIATION_REVIEW_MODE.md` is now a superseded record. The active eight-item
bundle no longer uses this mode.

### B. `expert_review` (active mode)

This is the T12-style path.

- Non-null author and reviewer UUIDs.
- Author and reviewer qualification references.
- An approved academic review and an independence declaration.
- A separate `review` reviewer identity that matches the question reviewer.
- Import approval only with approval and batch evidence.

The answer review has two honest variants:

| Status | Principal rule | Meaning |
| --- | --- | --- |
| `verified` | Author and reviewer must be different | An independent review is claimed |
| `self_review` | Author and reviewer must be the same | The reviewer is the author; no independence is claimed |

The validator rejects `verified` when the principals are equal and rejects
`self_review` when they differ. This is a small rule with a large purpose: the
envelope cannot accidentally claim an independence that did not happen.

The active bundle uses `self_review`.

## 3. What the Envelope Binds

Each envelope stores:

- the source paper filename, SHA-256, PDF page and question number;
- the marking-scheme filename, SHA-256 and answer-grid page;
- the official key and the derived option;
- the prompt, five options, explanation and exact rubric;
- the T08 concept and objective mappings;
- the ambiguity, duplicate and coverage notes;
- the reviewer identity, qualification reference and review date;
- the import batch and approval fields.

The content hash covers the source claim, question and answer verification. It
does **not** cover `review.content_hash` or `publication`, so an import-state
change does not invalidate the academic content. The reviewed and sealed hashes
for each item are recorded in `REVIEW_RECORD.md`.

The T12 import path computes a different hash over the persisted bundle. The two
hashes have different jobs and must not be compared as if they were the same.

## 4. Curriculum Mapping Without Invented Knowledge

Every item must point at a real T08 concept version and the objective that owns
it. The pilot does not invent a concept to make a question fit.

The eight questions cover 11 of 14 concepts. Three gaps remain explicit:

- displacement;
- velocity;
- Newton's first law.

Those gaps are useful evidence. They say the selected Paper I items do not
exercise those concepts directly, so a later content task must add coverage
rather than relabeling an existing question.

## 5. Duplicate and Ambiguity Checks

Duplicate screening normalises case, punctuation and whitespace, then compares
all prompt pairs. The highest similarity in this bundle is 0.469136, well below
the 0.9 review threshold. Source identity and question code are checked
separately.

Ambiguity is a human-language problem, not a hash problem. Two items carry notes:

- 2024 Q5 distinguishes total energy conservation from mechanical-energy
  conservation.
- 2025 Q3 records that "length of the spring" could mean extension rather than
  natural length. The official key selects the natural-length interpretation.

A note is not a rewrite. The paper wording stays verbatim and the residual risk
is visible to the reviewer.

## 6. Self-Review and Import

T12 requires an approved question to have a non-null author and reviewer. The
database trigger enforces the same rule. It does **not** require the two
principals to be different.

That distinction matters:

- the trigger is an **identity-presence gate**;
- the pilot validator's `self_review` rule is an **honesty gate** about whether
  independence is claimed.

The active envelopes therefore carry the same pilot principal in both fields and
set:

```text
approved_for_import = true
import_status = "ready_for_import"
import_batch_id = "T24-PHYS-PILOT-2026-11"
```

The database import test loads the real envelopes, converts them through
`to_validated_import()` and imports them through `QuestionImportRepository`. It
then checks that all eight versions are approved and that the stored author and
reviewer are non-null and equal.

This is not a workaround. A fake second reviewer would be worse than an honest
self-review. The limitation is recorded in `REVIEW_RECORD.md` and repeated in the
evidence document.

## 7. The Qualification Limitation

The review record names Malshani Perera as a Physics Teacher with the
qualification reference `PostGraduate`.

That reference is self-declared. It does not contain a degree title, awarding
institution, year or subject specialisation, and this branch does not verify the
reviewer's identity or certificates. The record keeps the limitation visible
instead of turning a short label into a stronger claim than the evidence
supports.

## 8. Technologies and Methods

| Tool or method | Role in T24 |
| --- | --- |
| JSON Schema Draft 2020-12 | Structural contract, strict extra-field rejection and mode-specific required fields |
| Python validator | Semantic checks against the T08 seed, official key, hash, review status and import state |
| SHA-256 content hash | Binds source, question and answer evidence; detects silent edits |
| Pytest | Negative tests for identities, keys, mappings, hashes, duplicates and reports |
| PostgreSQL integration test | Proves the real envelopes import through T12 with the recorded principals |
| Deterministic reports | Coverage, duplicate and verification evidence generated from the envelopes |
| Review record | Makes the reviewer, qualification claim, self-review limitation and per-item decisions explicit |

## 9. Commands

From the repository root:

```powershell
$env:PYTHONPATH = "backend/src"
.\.venv\Scripts\python.exe -m memora.modules.questions.pilot_validation validate content/physics/pilot/questions
.\.venv\Scripts\python.exe -m memora.modules.questions.pilot_reports --root content/physics/pilot --write
.\.venv\Scripts\python.exe -m pytest backend/tests -k pilot
```

The database import test runs when `MEMORA_TEST_DATABASE_URL` points at a
disposable database whose name ends in `_test` or `_ci`. Otherwise it skips.

## 10. Summary Takeaway

> **An official key can verify an answer. A named review can verify the
> surrounding content. Neither claim should be stretched into a claim that was
> never made.**

The pilot gets a reliable answer check from the marking scheme, records a named
teacher's self-review of the transcription, derivation, explanation, mapping,
ambiguity and adaptation, and imports the result through the existing T12 path
with the same principal in both identity fields. The record states plainly that
this is not an independent review and that the qualification reference is
self-declared. That is safer than turning a missing second reviewer into a silent
approval.
