# T24 Evidence Required from the Human Team

**Status:** Blocking. No item in this pilot has the evidence below. Do not fill this file with placeholders, synthetic principals or invented credentials.

This checklist is the human counterpart to `evidence_status.json`. The machine-readable report records what the repository actually contains; this file records what a real author, reviewer, curriculum lead, T12 owner and project/legal owner must supply before any pilot item can move from draft to approved.

## 1. Current per-candidate evidence

`source_file_identity = verified` means the tracked filename and SHA-256 match `source_manifest.json`. It does **not** mean the PDF is authenticated, that an official key exists or that reproduction is permitted.

| Candidate | Source file identity | Official answer key | Marking scheme / rubric | Reproduction rights | Attribution / provenance | Independent answer review | Author / reviewer identity and qualification | Independence declaration | Approval record | Overall |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `PILOT-PHYS-2025-P1-Q01` | verified | missing | pending human review | blocked | pending human review | missing | missing | missing | missing | blocked |
| `PILOT-PHYS-2025-P1-Q02` | verified | missing | pending human review | blocked | pending human review | missing | missing | missing | missing | blocked |
| `PILOT-PHYS-2025-P1-Q05` | verified | missing | pending human review | blocked | pending human review | missing | missing | missing | missing | blocked |
| `PILOT-PHYS-2025-P1-Q12` | verified | missing | pending human review | blocked | pending human review | missing | missing | missing | missing | blocked |
| `PILOT-PHYS-2025-P1-Q14` | verified | missing | pending human review | blocked | pending human review | missing | missing | missing | missing | blocked |
| `PILOT-PHYS-2025-P1-Q45` | verified | missing | pending human review | blocked | pending human review | missing | missing | missing | missing | blocked |
| `PILOT-PHYS-2022-P1-Q01` | verified | missing | pending human review | blocked | pending human review | missing | missing | missing | missing | blocked |
| `PILOT-PHYS-2022-P1-Q17` | verified | missing | pending human review | blocked | pending human review | missing | missing | missing | missing | blocked |

No official MCQ answer grid was found in either marking-scheme PDF. Page 2 of each is a question-to-marks allocation table. The 2022 file also contains handwritten annotations, which are not an official key. Every answer in `PILOT_QUESTIONS.md` is an analyst derivation. In `evidence_status.json`, author identity, author qualification, and reviewer identity/qualification are recorded separately; all three are `missing` for every candidate.

## 2. Evidence checklist

### A. Author and reviewer identity

- [ ] A real author principal UUID for every non-AI item, recorded in `question.author_principal`.
- [ ] A real reviewer principal UUID for every item, recorded in both `question.reviewer_principal` and `review.reviewer_principal`.
- [ ] The author and reviewer are different people; the principal UUIDs differ.
- [ ] A real author qualification record referenced by `question.author_qualification_ref`. The reference must resolve to a real, auditable record for the person named by `question.author_principal`, not a self-asserted string.
- [ ] A real reviewer qualification record referenced by `review.reviewer_qualification_ref`. The reference must resolve to a real, auditable record for the person named by `review.reviewer_principal`, not a self-asserted string.

### B. Independence and review decision

- [ ] A signed or otherwise auditable independence / conflict-of-interest declaration referenced by `review.independence_declaration_ref`.
- [ ] `review.academic_review_status = "approved"` only after the review is complete.
- [ ] A timezone-aware `review.reviewed_at` timestamp.
- [ ] The reviewed content hash in `review.content_hash`, matching the current envelope.
- [ ] The exact reviewed source reference in `review.source_ref`, matching the source block.
- [ ] `review.ambiguity_status = "cleared"` and `review.duplicate_status = "cleared"`.
- [ ] A documented near-duplicate / semantic duplicate check, not only the exact-text check.

### C. Answers and marking scheme

- [ ] Either an official MCQ answer key or an independent reviewer's verified derivation for every item.
- [ ] `answer_verification.independent_review_status = "verified"` and a real `answer_verification.reviewer_ref` only when that review exists.
- [ ] `answer_verification.official_key_claimed` remains `false`. The pilot contract does not support an official-key claim.
- [ ] A truthful `source.official_key_status`: one of `not_found`, `not_published`, `marking_scheme_not_mcq_key` or `unknown`.
- [ ] A reviewed rubric or marking approach for each item, including the assumed uncertainty model for 2025 Q2 and the launch-angle assumption for 2025 Q5.
- [ ] Resolution of every ambiguity flag in `PILOT_QUESTIONS.md` section 4.2.

### D. Source, reproduction and transcription

- [ ] A decision on whether the pilot may reproduce past-paper text or only use a non-verbatim adaptation.
- [ ] A real reproduction approval reference in `source.reproduction_approval_ref`.
- [ ] `source.reproduction_status = "approved"` only after that approval exists.
- [ ] Independent page-image verification of the transcription: `source.transcription_verified = true`.
- [ ] Attribution and provenance sufficient for the chosen distribution route.
- [ ] No source PDF and no verbatim review pack is staged, committed or published.

### E. Curriculum and mapping

- [ ] Reviewed T08 concepts, objectives and claims for the six missing topic areas:
  - measurement uncertainty and percentage error;
  - projectile motion, including independence of horizontal and vertical components;
  - static friction and the friction limit;
  - conservation of linear momentum and elastic/inelastic collisions;
  - scalar and vector classification;
  - simple pendulum and effective gravity.
- [ ] Real concept version IDs and objective IDs from the reviewed seed, not invented UUIDs.
- [ ] A primary reviewed mapping for every item that will be imported as approved.
- [ ] Mapping provenance `pilot_review` with a real review record reference for approved items.

### F. Publication and database acceptance

- [ ] A real approval record reference in `publication.approved_by`.
- [ ] A timezone-aware `publication.approved_at` that is not earlier than the review date.
- [ ] `publication.approved_for_import = true` only after all of the above.
- [ ] A decision from the T12 owner on question-level source provenance (see `T12_OWNER_ACCEPTANCE.md`).
- [ ] A CI or approved staging run of the PostgreSQL migration, import, immutability and RLS suites against a disposable database. A local run is evidence, not release acceptance.

## 3. What the repository already verifies locally

- The T24 envelope rejects unknown T08 concept version UUIDs, objective/concept mismatches and duplicate mappings.
- An approved envelope requires an author, a reviewer, separate author and reviewer qualification references, an independence declaration, an approved review, a verified answer review, a content hash, a source reference, reproduction approval and transcription verification for past papers.
- The T24-only author qualification reference is removed before the T12 bundle is validated, so it cannot be mistaken for a T12 database field.
- Approval cannot precede review, and drafts cannot carry approval or review identity metadata.
- The JSON Schema is valid against the Draft 2020-12 metaschema and rejects missing approval evidence and source metadata smuggled into `content`.
- The T12 import path rejects source metadata in `content`, missing publication evidence and supporting-only mappings.
- The disposable PostgreSQL suites pass locally for migrations, import idempotency, immutability, publication guards, reference checks, owner-scoped history and RLS.

These checks prove the gates work. They do not supply the human evidence the gates are waiting for.

## 4. Current blockers

| ID | Blocker | Owner |
| --- | --- | --- |
| B1 | No real author, reviewer, qualification, independence or approval record | Academic content lead |
| B2 | No official MCQ key and no independent answer/rubric verification | Independent Physics reviewer |
| B3 | No reproduction or distribution permission | Project or legal owner |
| B4 | Six topic areas absent from T08 | Curriculum lead |
| B5 | T12 has no question-level source-provenance field | T12 owner |
| B6 | PostgreSQL/RLS checks not yet accepted in CI | Backend owner |
| B7 | Ambiguity and semantic duplicate clearance pending | Independent reviewer |

T24 remains **Ready, not Done** until every blocker has real evidence and the acceptance conditions in the task table are met.
