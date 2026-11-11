# T24 pilot content schema v2

## Purpose

`pilot_question.schema.json` is the structural contract for a sealed T24
Physics pilot envelope. The Python validator in
`backend/src/memora/modules/questions/pilot_validation.py` and the T08 seed data
in `backend/src/memora/modules/curriculum/seed_data.py` are the semantic
authorities.

The schema and validator are intentionally pilot-only. They do not change the
T12 question-bank contract, the database schema or the `expert_verified` source
class.

## Verification modes

| Mode | Authority | Human identities | Import status |
| --- | --- | --- | --- |
| `official_marking_scheme` | Printed Department of Examinations Paper I answer grid | None | Blocked pending T12 support; historical pilot mode |
| `expert_review` | Named reviewer plus the official key; independent or explicit self-review | Author, reviewer, qualification and independence references | Eligible for the existing T12 path |

The active T24 bundle uses `expert_review`. The named reviewer recorded in
`REVIEW_RECORD.md` approved all eight items as a self-review. The
`official_marking_scheme` branch remains supported for historical or other
official-key-only content.

## Envelope sections

| Section | Required content |
| --- | --- |
| `schema_version` | `"2.0"` |
| `pilot_id` | `PILOT-PHYS-<year>-P1-Q<number>` |
| `verification_mode` | `official_marking_scheme` or `expert_review` |
| `source` | Source identity, hashes, page references, official key, transcription and reproduction state |
| `question` | Prompt, explanation, five options, exact rubric and T08 concept mappings |
| `answer_verification` | Official key, derived option, derivation and reference to the marking-scheme page |
| `review` | Verification scope, ambiguity and duplicate status, coverage note and content hash |
| `publication` | Import state and any blocker |

Every object uses `additionalProperties: false`. Unknown fields are rejected so
source or review metadata cannot be smuggled into question content.

## Official marking-scheme invariants

The schema requires:

- `source.source_type = "past_paper"`;
- `source.official_key_status = "verified_against_marking_scheme"`;
- `source.transcription_status = "verified_visual"`;
- a marking-scheme filename, SHA-256 and PDF page;
- `question.author_principal`, `question.reviewer_principal`,
  `question.author_qualification_ref` and `review.reviewer_principal` are null;
- `answer_verification.independent_review_status = "not_required"`;
- `review.academic_review_status = "not_required"`;
- `review.deviation_ref` points at `DEVIATION_REVIEW_MODE.md`;
- `publication.approved_for_import = false` and
  `publication.import_status = "blocked_pending_t12_verification_mode"`.

The Python validator additionally requires five options, exactly one of them
correct; the source key, answer key and derived option to agree; the derived
option to be the single correct option; a T08 concept and its owning objective
to match; one primary mapping; cleared ambiguity and duplicate status; and a
matching content hash.

## Expert-review invariants

The `expert_review` branch keeps the original T12-style evidence: non-null
author and reviewer UUIDs, qualification references, an approved academic
review, an answer review, an independence declaration and, when
`publication.approved_for_import` is true, approval and batch evidence. The
reviewer in `review` must match the reviewer in `question`.

The answer review is one of:

- `independent_review_status = "verified"` with distinct author and reviewer
  principals; or
- `independent_review_status = "self_review"` with the same author and reviewer
  principal. The declaration must state that independence is not claimed.

The validator rejects `verified` when the principals are equal and rejects
`self_review` when they differ. This prevents the envelope from claiming an
independent review that did not happen.

## Content hash

`compute_pilot_content_hash()` hashes the canonical JSON of:

```text
schema_version, pilot_id, verification_mode, source, question, answer_verification
```

`review.content_hash` and `publication` are excluded. The hash therefore binds
the source claim, question and answer evidence without binding the import state.
Any change to a hashed field invalidates the envelope until it is resealed with:

```powershell
$env:PYTHONPATH = "backend/src"
.\.venv\Scripts\python.exe -m memora.modules.questions.pilot_validation seal content/physics/pilot/questions
```

The T12 import path computes a different hash over the persisted question
bundle. The two hashes serve different boundaries and must not be treated as
interchangeable.

## Validation commands

```powershell
$env:PYTHONPATH = "backend/src"
.\.venv\Scripts\python.exe -m memora.modules.questions.pilot_validation validate content/physics/pilot/questions
.\.venv\Scripts\python.exe -m memora.modules.questions.pilot_reports --root content/physics/pilot --write
```

The second command writes `coverage_report.json`, `duplicate_report.json`,
`verification_report.json` and `PILOT_QUESTIONS.md` deterministically.

## Structural versus semantic validation

A payload can satisfy the JSON Schema and still fail the pilot contract. For
example, the schema accepts an unknown concept UUID because it cannot read the
T08 seed; the Python validator rejects it with
`pilot_mapping_unknown_concept`. Run both checks.

## T12 import gate

Official-mode envelopes are not importable. The T12 service requires non-null
author and reviewer principals for an approved question, and the database
trigger in `20261023_0005_question_bank_integrity.up.sql` enforces the same
rule. `to_validated_import()` raises `pilot_import_blocked` for this mode.

Expert-review envelopes are importable. The active eight envelopes carry the
same non-null pilot principal as author and reviewer because the review is a
self-review, and the database trigger accepts that. The trigger is an
identity-presence gate, not an independence test. The self-review limitation is
recorded in `REVIEW_RECORD.md`; it is not hidden in the database field names.

The active publication state is:

```text
approved_for_import = true
import_status = "ready_for_import"
import_batch_id = "T24-PHYS-PILOT-2026-11"
```

Official-mode import would still require a separate T12 mode decision and does
not belong to T24.
