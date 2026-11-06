# T24-DEV-001: official marking-scheme verification mode

**Status:** **Superseded on 2026-11-02.** The active eight-item bundle now uses
`expert_review` with the recorded self-review in `REVIEW_RECORD.md`. This file is
retained as the historical record of the official-mode decision. The statements
below describe the superseded state, not the current envelopes.

**Original status:** Recorded pilot deviation. Not a qualified academic review,
not a T12 import approval and not a claim that T24 is Done.

**Date recorded:** 2026-11-02

## Supersession

Route A was completed on 2026-11-02:

- all eight envelopes changed from `official_marking_scheme` to `expert_review`;
- the named pilot reviewer approved all eight items in `REVIEW_RECORD.md`;
- the review is an explicit self-review and does not claim independence;
- `publication.approved_for_import` is `true` with batch
  `T24-PHYS-PILOT-2026-11`;
- the active envelopes no longer reference this file in `review.deviation_ref`.

The official marking-scheme grid remains the answer-key authority. The controls
described below still apply if an official-mode envelope is ever reintroduced.

**Authority:** The T24 task instruction directed that this pilot use the
official past-paper marking schemes and that no teacher, reviewer or verifier
be required. This file records that product decision and its limits.

## PRD rule being deviated from

PRD 9.3, "Verified question bank", requires:

| PRD 9.3 rule | T24 pilot treatment |
| --- | --- |
| Authorship: questions are written or reviewed by qualified A/L Physics teachers or subject experts | Waived for this pilot. Envelopes carry null author and reviewer principals and claim no qualification. |
| Mapping: every question maps to curriculum objectives and one or more knowledge-graph concepts | Retained. Every item maps to a T08 concept and its owning objective. |
| Answer support: each item has an official key or rubric, reasoning and required constants or diagram | Retained with the official marking-scheme grid as the answer authority. |
| Versioning: academic edits create a new version | Retained by content hashes and a new envelope version when content changes. |
| Coverage: reporting distinguishes verified coverage gaps from generated fallback coverage | Retained in `coverage_report.json`, with three explicit gaps. |
| Disputes: ambiguous questions can be removed from high-impact updates | Retained through the ambiguity note and `ambiguity_status`; every checked-in item is cleared against the official key. |

## Scope

This deviation applies only to envelopes with all of the following:

- `verification_mode = "official_marking_scheme"`;
- `source.source_type = "past_paper"`;
- `source.official_key_status = "verified_against_marking_scheme"`;
- `source.transcription_status = "verified_visual"`;
- a source document and marking-scheme SHA-256 recorded in `source_manifest.json`;
- `review.deviation_ref = "content/physics/pilot/DEVIATION_REVIEW_MODE.md"`.

It does not apply to the `expert_review` path, to any future generated content,
or to any question without a printed official MCQ key.

## What is waived

Only the human academic-review evidence is waived:

- named author identity and author qualification;
- named independent reviewer identity and reviewer qualification;
- an academic review approval signature;
- an independent human answer-review record.

## What is not waived

- The official key must be present and must match the derived answer.
- The question and all five options must be transcribed from the rendered
  paper page and checked visually.
- The derivation must be recorded and must reach the official option.
- The item must map to a real T08 concept and its owning objective.
- Ambiguity, duplicate and coverage checks must pass.
- Reproduction rights must be recorded truthfully; the current status is
  `unapproved`.
- No private student content may enter the bundle.
- The T12 import gate remains closed.

## Why the waiver is bounded

An official marking-scheme grid is stronger than an unverified generated answer
for the narrow question "which option did the examination board mark correct?".
It is weaker than a qualified review for explanation quality, syllabus fit,
diagram interpretation, accessibility and future dispute handling. The pilot
therefore treats the grid as answer-verification evidence only. It does not
claim that the wording, explanation or curriculum mapping received independent
academic approval.

The 2025 Q3 wording is the clearest residual risk: "length of the spring" can be
read as extension rather than natural length. The official key selects the
natural-length interpretation, and the envelope records the wording risk rather
than silently rewriting the paper.

## Controls in this bundle

- `pilot_validation.py` rejects human identities in official mode.
- The validator rejects any derived answer that differs from the official key.
- The validator requires the `deviation_ref` and blocks import approval.
- `verification_report.json` records `human_review_claimed: false`.
- `SOURCE_INVENTORY.md` records the page-level grid evidence and excludes the
  ambiguous 2025 Q15 cell.
- `coverage_report.json` reports the three concept gaps instead of inventing
  mappings.
- Tests reject official-mode import conversion and require a matching content
  hash.

## T12 import gate

The official-mode envelopes are structurally valid but not importable. T12's
`validate_question_import()` requires a non-null reviewer and, for a
non-AI-generated source, a non-null author. The database trigger in
`backend/migrations/versions/20261023_0005_question_bank_integrity.up.sql`
enforces the same rule.

The bundle therefore uses:

```text
approved_for_import = false
import_status = "blocked_pending_t12_verification_mode"
```

The existing `source_class = "expert_verified"` value is retained only because
no new database source class is approved. It must not be read as a claim that a
named expert reviewed the item; import is blocked precisely because that claim
cannot be made.

## Residual risks

| Risk | Treatment |
| --- | --- |
| No named academic owner for explanations or disputes | T24 remains in Review; a qualified reviewer is still required before any import or public use. |
| Official grid errors or transcription error | Page-level visual check, full 50-entry grids, content hashes and a second report pass. |
| Ambiguous question wording | Recorded ambiguity notes; 2025 Q15 excluded; 2025 Q3 flagged in the note while the official key resolves the intended option. |
| Copyright and reproduction | Source PDFs are local-only; excerpts are short; reproduction status is `unapproved`; import is blocked. |
| T12 source-class semantics | Import remains blocked until T12 supports an official-verification mode or human review is added. |

## Exit and review triggers

This deviation must be revisited before any of the following:

- T24 is marked Done;
- any official-mode envelope is imported into T12;
- the content is used in a student-facing mission;
- the bundle is deployed to staging or production;
- the source reproduction status changes.

At that point the project must either add real qualified review or approve and
implement a T12 verification mode that records this deviation at import time.

## Approval record

No named academic approver is claimed. The only recorded authority is the T24
task instruction that selected official marking-scheme verification and waived
teacher, reviewer and verifier involvement for this pilot. This file is a
transparency record, not a substitute for the PRD 9.3 sign-off.
