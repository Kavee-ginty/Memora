# T24 Verified Physics Pilot Content - Study Note

## 1. The Core Analogy: The Official Answer Grid as a Reference Standard

In T12, a question passed through a human review chain: an author wrote it, a
qualified reviewer checked it, and the database recorded both identities. T24
uses a different pilot route.

Think of an official past-paper marking scheme as a **reference standard in a
metrology lab**. The lab does not ask a person to "approve" the metre bar; it
compares the instrument against the standard and records the comparison. T24
does the same for eight multiple-choice answers:

- the **question** is transcribed from the rendered paper page;
- the **derivation** is worked independently;
- the **official marking-scheme grid** is the reference answer;
- the **sealed envelope** records the comparison, the source hashes and the
  content hash;
- the **T12 import gate** stays closed because the question bank still expects a
  named human reviewer.

The reference standard is authoritative only for the narrow claim "this is the
option the examination board marked correct". It does not certify the
explanation, accessibility, syllabus fit or dispute handling. That distinction
is the heart of the T24 deviation.

## 2. Two Verification Modes

### A. `official_marking_scheme`

This is the T24 mode.

- Source type must be a past paper.
- The official key must be present in the printed marking-scheme grid.
- The transcription must be checked visually against the page image.
- The author, reviewer and qualification fields are null.
- `independent_review_status` and `academic_review_status` are `not_required`.
- The envelope must reference `DEVIATION_REVIEW_MODE.md`.
- Import is blocked.

The Python validator is deliberately strict: a missing key, a mismatched derived
option, an invented concept UUID, an open ambiguity flag or a stale content hash
all stop the envelope.

### B. `expert_review`

This is the original T12-style path retained for future content.

- Non-null author and reviewer UUIDs.
- Author and reviewer qualification references.
- Independent answer review.
- Approved academic review and independence declaration.
- A separate `review` reviewer identity that matches the question reviewer.
- Import approval only with approval and batch evidence.

T24 does not use this mode. Keeping it in the schema proves the official-mode
waiver is a branch, not a silent weakening of every question.

## 3. What the Envelope Binds

Each envelope stores:

- the source paper filename, SHA-256, PDF page and question number;
- the marking-scheme filename, SHA-256 and answer-grid page;
- the official key and the derived option;
- the prompt, five options, explanation and exact rubric;
- the T08 concept and objective mappings;
- the ambiguity, duplicate and coverage notes;
- the import blocker.

The content hash covers the source claim, question and answer verification. It
does **not** cover `review.content_hash` or `publication`, so an import-state
change does not invalidate the academic content. That separation is intentional:
a blocked item can later become importable without pretending the question
changed.

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

## 6. Why Import Is Still Blocked

T12 requires an approved question to have a non-null author and reviewer. The
database trigger enforces the same rule. An official marking-scheme envelope has
neither, so it cannot pass T12's import validation.

T24 therefore sets:

```text
approved_for_import = false
import_status = "blocked_pending_t12_verification_mode"
```

This is not a bug to work around. It is the boundary between "the answer is
verified against the official grid" and "the question bank has accepted a
qualified human review". The second claim has not been made.

## 7. Technologies and Methods

| Tool or method | Role in T24 |
| --- | --- |
| JSON Schema Draft 2020-12 | Structural contract, strict extra-field rejection and mode-specific required fields |
| Python validator | Semantic checks against the T08 seed, official key, hash and import state |
| SHA-256 content hash | Binds source, question and answer evidence; detects silent edits |
| Pytest | Negative tests for identities, keys, mappings, hashes, duplicates and reports |
| Deterministic reports | Coverage, duplicate and verification evidence generated from the envelopes |
| Recorded deviation | Makes the PRD 9.3 gap explicit instead of hiding it |

## 8. Commands

From the repository root:

```powershell
$env:PYTHONPATH = "backend/src"
.\.venv\Scripts\python.exe -m memora.modules.questions.pilot_validation validate content/physics/pilot/questions
.\.venv\Scripts\python.exe -m memora.modules.questions.pilot_reports --root content/physics/pilot --write
.\.venv\Scripts\python.exe -m pytest backend/tests/test_pilot_content_validation.py backend/tests/test_pilot_schema_jsonschema.py backend/tests/test_pilot_evidence_status.py backend/tests/test_pilot_mapping_report.py backend/tests/test_pilot_coverage_report.py backend/tests/test_pilot_duplicate_report.py backend/tests/test_pilot_verification_report.py -q
```

## 9. Summary Takeaway

> **An official key can verify an answer without verifying the whole
> question.**

The pilot gets a reliable answer check from the marking scheme, records exactly
what it did not review, and refuses to import content that the question bank's
human-review contract cannot yet accept. That is safer than turning a missing
reviewer into a silent approval.
