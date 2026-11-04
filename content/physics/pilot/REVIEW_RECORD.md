# T24 Physics pilot review record

**Task:** T24, Verified Physics pilot content

**Branch:** `task/T24-physics-content`

**Review date:** 2026-11-02T19:00:00+05:30 (2026-11-02T13:30:00+00:00)

**Review type:** Self-review. The author and reviewer are the same person. No
independence is claimed.

## Identity

| Field | Author | Reviewer |
| --- | --- | --- |
| Full name | Malshani Perera | Malshani Perera |
| Role | Physics Teacher | Physics Teacher |
| Qualification reference | `PostGraduate` | `PostGraduate` |
| Pilot principal UUID | `a2400000-0000-4000-8000-000000000001` | `a2400000-0000-4000-8000-000000000001` |
| Relationship | Same person | Same person |

The single pilot principal is used for both `question.author_principal` and
`question.reviewer_principal` because this is a self-review. The UUID is a
content identity for this pilot, not an authentication credential.
`questions.author_principal` and `questions.reviewer_principal` have no foreign
key to `users`.

### Qualification basis and limits

The reviewer represents that she is a Physics Teacher with a postgraduate
qualification. The qualification reference supplied for this record is
`PostGraduate`.

This record does not contain a degree title, awarding institution, year or
subject specialisation, and it does not independently verify the reviewer's
identity or certificates. The name, role and qualification reference were
supplied for this task. No supporting documents were supplied with this task;
if any exist, they were not reviewed here. A later reviewer should treat the
qualification claim as self-declared until that evidence is produced.

## Independence declaration

<a id="independence-declaration"></a>

The reviewer declared that she is also the author of these eight items. This is
a **self-review**. She did not claim independence, and this record must not be
read as an independent second-person check.

PRD 9.3 requires questions to be "written or reviewed by qualified A/L Physics
teachers or subject experts". The named teacher performed the review. The pilot
records the self-review honestly rather than claiming a separate reviewer.

## Review scope and method

The approved review scope covers, for every item:

- the prompt and all five options against the paper page;
- the printed official key against the marking-scheme answer grid;
- the recorded derivation and explanation;
- the T08 concept and objective mapping;
- ambiguity and duplicate status;
- the text-only adaptation for `PILOT-PHYS-2024-P1-Q05`;
- reproduction status and the internal-only limitation.

The official marking-scheme grid remains the answer-key authority. The review
adds the named teacher's check of transcription, derivation, explanation,
mapping, ambiguity and adaptation. It does not replace the grid.

## Per-item decisions

The `reviewed hash` is the sealed official-mode envelope that was reviewed. The
`sealed hash` is the committed expert-review envelope after the metadata-only
conversion described below.

| Item | Topic | Official key | Decision | Reviewed hash | Sealed hash |
| --- | --- | ---: | --- | --- | --- |
| <a id="pilot-phys-2022-p1-q01"></a>`PILOT-PHYS-2022-P1-Q01` | Vector/scalar pair | 4 | Approved | `68fcec6747d61017fdb8931167e07708cd6708bc46adea8943ad0ff135614839` | `88c6c0190e56546d8d3e5ec1dd2b4d57b7ba9c6d2a38c63720d63004c845edcd` |
| <a id="pilot-phys-2022-p1-q17"></a>`PILOT-PHYS-2022-P1-Q17` | Pendulum in an accelerating elevator | 4 | Approved | `37baa78305f9a24403ef3b37e0d203fe5a3c6d18d05bceebc6a5e9672d694f39` | `f0526870c2e27ed13aa2dc8044343d8a22033da567a533c0a76e7dae5a47a9e8` |
| <a id="pilot-phys-2024-p1-q01"></a>`PILOT-PHYS-2024-P1-Q01` | Unit without dimensions | 5 | Approved | `ce95afdaea900de52b6ec4921ef1cb6d7ef1244d744c15718a800d31f150c805` | `f4e89ffbbb74be8d8fa527823d6e87ebd998c65e75a38488d8d48ac34ef3e835` |
| <a id="pilot-phys-2024-p1-q04"></a>`PILOT-PHYS-2024-P1-Q04` | Newton's third law | 1 | Approved | `dd094c6c584f5e4013d80cd4587c864c56bdf26d62dd868218e4d4cacd4a6c1a` | `a9f113027d7e50b7d4b77d6eba2ba7821d846741a5a55436a1ac7eed014683b3` |
| <a id="pilot-phys-2024-p1-q05"></a>`PILOT-PHYS-2024-P1-Q05` | Momentum and energy in an inelastic collision; text-only adaptation | 5 | Approved | `af45f74e608cf3336eec4ee4b4df59932ed959888d100a7fb29652d249bd2e85` | `daddcd8e44eba36b773a1ec7002a7eb0e760cdca93e9088fe257398a297f880d` |
| <a id="pilot-phys-2025-p1-q01"></a>`PILOT-PHYS-2025-P1-Q01` | Energy units | 5 | Approved | `c3dd6d4b2b3a9835e8a13a22d51c25d821d8c5f2e3939c37d62196583f9f4582` | `f21d837f269c83ef067e465d6552f64479f4f12a16763184a065a6b17fb6cc90` |
| <a id="pilot-phys-2025-p1-q03"></a>`PILOT-PHYS-2025-P1-Q03` | Spring-mass period | 1 | Approved | `8df91967b94b8e572d2ba2a0a75eb2ea9fd037e5f110c060b8027f1b31a6354c` | `2c308ce5a9e6918fc8260e12350c3f2068aa9c7d32313eb791364161c8ea91c5` |
| <a id="pilot-phys-2025-p1-q45"></a>`PILOT-PHYS-2025-P1-Q45` | Elastic/inelastic collision ratio | 5 | Approved | `7cc1167628f5ecdfe2e7e2b117eb8d35e2e8ec66dab03489de39b298f08f9a70` | `6ba2ea48f2c41e3cf22fb6e46dda47aa19bd3ed2af37822d6c4ace55c49b2261` |

All eight items were approved. No corrections were requested.

## Content preservation check

The conversion from `official_marking_scheme` to `expert_review` changed only:

- `verification_mode`;
- `question.author_principal`, `question.author_qualification_ref` and
  `question.reviewer_principal`;
- `question.concept_mappings[*].provenance_type` and
  `question.concept_mappings[*].provenance_ref`;
- `answer_verification.mode`, `answer_verification.independent_review_status`,
  `answer_verification.reviewer_ref` and `answer_verification.notes`;
- `review.review_mode`, `review.academic_review_status`,
  `review.reviewer_principal`, `review.reviewer_qualification_ref`,
  `review.reviewed_at`, `review.independence_declaration_ref` and
  `review.deviation_ref`;
- `review.content_hash` and the `publication` import fields.

The source block, prompt, options, explanation, rubric, concept/objective IDs,
mapping roles and weights, derivation, official key, source references,
ambiguity note and coverage note were not changed.

## Import approval

| Field | Value |
| --- | --- |
| `publication.approved_for_import` | `true` |
| `publication.approved_by` | `Malshani Perera` |
| `publication.approved_at` | `2026-11-02T13:30:00+00:00` |
| `publication.import_batch_id` | `T24-PHYS-PILOT-2026-11` |
| `publication.import_status` | `ready_for_import` |
| `publication.blocker_ref` | `null` |

`answer_verification.independent_review_status` is `self_review`, not
`verified`. The pilot validator requires `self_review` to use the same author
and reviewer principal, and requires an independent `verified` review to use
distinct principals. This prevents the envelope from claiming independence that
did not happen.

The T12 import path accepts expert-review envelopes. `QuestionImportBundle`
requires non-null author and reviewer principals, and the database trigger
enforces the same rule. Both fields carry the same pilot principal above
because the review is a self-review; the trigger does not require distinct
principals.

## Limitations

- The review is a self-review, not an independent check.
- The qualification reference is self-declared and lacks a degree title,
  institution, year and subject specialisation.
- Reproduction permission is not recorded. The excerpts remain internal-only
  and are not cleared for redistribution.
- The official grid verifies the answer option. The named reviewer approved the
  explanation and mapping, but the pilot has no second-person academic review
  of those judgements.
- If the principal, qualification reference or item content changes, this
  record and the envelope hashes must be updated together.

## Sign-off

**Reviewer:** Malshani Perera

**Review date:** 2026-11-02T19:00:00+05:30

**Decision:** All eight items approved for the T24 pilot import batch
`T24-PHYS-PILOT-2026-11`.
