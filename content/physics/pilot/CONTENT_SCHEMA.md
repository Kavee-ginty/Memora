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
| `official_marking_scheme` | Printed Department of Examinations Paper I answer grid | None | Blocked pending T12 support |
| `expert_review` | Independent named reviewer plus the official key | Author, reviewer, qualification and independence references | Eligible for the existing T12 path |

The T24 content uses `official_marking_scheme`. The `expert_review` branch is
retained for a future task that supplies real reviewer evidence.

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
review, a verified answer review, an independence declaration and, when
`publication.approved_for_import` is true, approval and batch evidence. The
reviewer in `review` must match the reviewer in `question`.

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

Opening the gate requires one of:

1. a T12 verification-mode extension that accepts official marking-scheme
   evidence and records the deviation at import time; or
2. real named author and reviewer evidence added to every envelope.

Neither change belongs to T24.
