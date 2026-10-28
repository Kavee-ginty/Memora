# Draft T12-Compatible Content and Provenance Schema

**Status:** Stage 1 draft. Not approved, not migrated, not wired into a T12 HTTP route.

**Files:**

- `pilot_question.schema.json` - structural JSON Schema (Draft 2020-12).
- `examples/synthetic_draft.json` - clearly synthetic draft example.
- `backend/src/memora/modules/questions/pilot_validation.py` - semantic draft/approval gates.
- This document - field meanings, T12 mapping and the synthetic worked example.

## 1. Why an envelope is needed

T12's `QuestionImportBundle` is the import contract. It carries:

- the question code, subject, curriculum, source class, type, prompt and explanation;
- MCQ options and an exact rubric;
- author and reviewer principals;
- concept mappings with `provenance_type` and `provenance_ref`.

It does **not** carry a question-level source paper, year, question number, PDF page, licence state, reproduction approval, reviewer qualification or reviewed content hash. The `ChoiceContent` payload is strict (`extra="forbid"`), so source metadata cannot be hidden inside `content`. A read-only probe confirmed that adding a source field there is rejected as `content_invalid`.

The envelope separates two concerns:

1. **T12 import object** - the `question` member, which is converted to `QuestionImportBundle` only after every pilot gate passes.
2. **T24 provenance and review record** - the `source`, `answer_verification`, `review` and `publication` members, which stay in the versioned content bundle and are not passed to T12 today.

This is a draft workaround, not a claim that repo-side provenance is a permanent substitute for a queryable database record. The durable options are in `T08_T12_CONTRACT_GAPS.md`.

## 2. Draft-only rule

A draft has:

```text
question.validation_status = "draft"
question.source_class       = null
question.target_source_class = "expert_verified"
review.academic_review_status = "pending"
answer_verification.independent_review_status = "pending"
publication.approved_for_import = false
```

`source_class` is intentionally null until review is complete. A draft is never passed to `QuestionImportRepository.import_question()` and is never persisted with an `expert_verified` trust label. The only supported bridge to T12 is `pilot_validation.to_validated_import()`, which refuses drafts and refuses an approved envelope whose review hash or source reference is stale.

`target_source_class` records the proposed destination class without claiming it. `teacher_authored` is not available because T12 hard-disables it; `ai_generated` is outside this pilot.

## 3. Envelope shape

```text
{
  schema_version: "1.0",
  pilot_id: "PILOT-PHYS-2099-P1-Q01",
  source: { ... },
  question: { ...T12-compatible question... },
  answer_verification: { ... },
  review: { ... },
  publication: { ... }
}
```

### 3.1 `source`

| Field | Type | Rule |
| --- | --- | --- |
| `source_id` | string | `SL-DOE-AL-PHYS-YYYY-P1` for a past paper; `SYNTHETIC-...` for synthetic content. |
| `source_type` | enum | `past_paper` or `synthetic`. |
| `document_filename` | string or null | Exact filename in `source_documents/`; null for synthetic content. |
| `document_sha256` | string or null | 64 lowercase hex characters matching `source_manifest.json`; null for synthetic content. |
| `exam_year` | integer or null | First year of the printed label; null for synthetic content. |
| `exam_label` | string | Printed label, e.g. `2022(2023)`, or `synthetic`. |
| `paper` | string or null | `Paper I` for this pilot; null for synthetic content. |
| `question_number` | integer or null | Printed question number, 1-50; null for synthetic content. |
| `pdf_page` | integer or null | PDF page containing the question; null for synthetic content. |
| `medium` | string | `English` for every pilot envelope. |
| `official_key_status` | enum | `not_found`, `not_published`, `marking_scheme_not_mcq_key`, `unknown`, or `not_applicable` for synthetic content. |
| `reproduction_status` | enum | `unapproved`, `approved`, or `not_applicable` for synthetic content. |
| `reproduction_approval_ref` | string or null | Reference to a real approval record; null when none exists. |
| `licence_note` | string | Short factual note. Do not assert a licence that has not been verified. |
| `transcription_verified` | boolean | True only after an independent reviewer has compared the text with the page image. Synthetic content remains false. |

A past-paper envelope cannot claim approval while reproduction is `unapproved` or transcription is false. A synthetic envelope must use `not_applicable` for official key and reproduction and must not claim a source document.

`official_key_status` must not be set to a value that implies an official key exists unless a real key has been inspected and referenced.

### 3.2 `question`

This object mirrors `backend/src/memora/modules/questions/models.py::QuestionImportBundle`. The schema restricts the pilot to `question_type = mcq`, `content.kind = choice`, `selection_mode = single` and `rubric_type = exact`.

The following T12 fields are represented:

`question_code`, `subject_id`, `curriculum_version_id`, `source_class`, `target_source_class`, `question_type`, `prompt`, `explanation`, `validation_status`, `author_principal`, `reviewer_principal`, `content`, `options`, `rubric`, `concept_mappings`.

T12's own bounds still apply. Examples: 2-10 options, contiguous `display_order`, one correct option for single choice, unique option keys, at least one primary mapping for publication, and an approved rubric with a positive evidence ceiling.

For a draft, `source_class` must be null and `reviewer_principal` must be null. The author may be null. For approval, T12's publication gates apply and the pilot validator additionally requires reviewer independence.

### 3.3 `answer_verification`

| Field | Type | Rule |
| --- | --- | --- |
| `derived_option_keys` | array of one string | Option key derived by the analyst. |
| `derivation` | string | Reproducible working. |
| `independent_review_status` | enum | `pending`, `verified` or `rejected`. |
| `reviewer_ref` | string or null | Reference to a real review record, not an invented name. |
| `official_key_claimed` | boolean | Must be `false` unless an actual official key was inspected. |
| `notes` | string or null | Assumptions and ambiguity notes. |

The pilot validator requires the derived key to match the option marked `is_correct`, and requires `verified` plus a reviewer reference before approval.

### 3.4 `review`

| Field | Type | Rule |
| --- | --- | --- |
| `academic_review_status` | enum | `pending`, `approved` or `rejected`. |
| `reviewer_principal` | UUID or null | Real T12 reviewer principal. Null in Stage 1. |
| `reviewer_qualification_ref` | string or null | Reference to qualification evidence. Null in Stage 1. |
| `review_scope` | array of strings | `transcription`, `derivation`, `ambiguity`, `curriculum_mapping` as applicable. |
| `reviewed_at` | date-time or null | Null until a real review occurs. |
| `ambiguity_status` | enum | `pending`, `cleared` or `flagged`. |
| `duplicate_status` | enum | `pending`, `cleared` or `duplicate`. |
| `coverage_note` | string | Explicit gap statement. |
| `content_hash` | string or null | SHA-256 of the exact reviewed content; required for approval. |
| `source_ref` | string or null | Canonical source reference; required for approval. |
| `independence_declaration_ref` | string or null | Evidence that reviewer and author are independent. |

A bare UUID is not qualification evidence. The review record must be backed by a separate qualification/approval reference. The pilot validator enforces reviewer principal != author principal; it does not claim that T12 or the database enforces this.

For a past-paper approval, `review_scope` must include `transcription`, `derivation`, `ambiguity` and `curriculum_mapping`. Synthetic content does not need a transcription scope.

### 3.5 `publication`

| Field | Type | Rule |
| --- | --- | --- |
| `approved_for_import` | boolean | True only after all gates pass. |
| `approved_by` | string or null | Real approval record reference. |
| `approved_at` | date-time or null | Real timestamp. |
| `import_batch_id` | string or null | Set after a real import run. |

In Stage 1 every value is `false` or null. The schema does not grant approval and the presence of a valid envelope is not an approval.

## 4. Mapping to the T12 call path

The only supported conversion is:

```text
pilot JSON
  -> pilot_validation.validate_pilot_envelope()
  -> pilot_validation.to_validated_import()      # approved envelopes only
  -> validate_question_import()                 # T12 semantic checks
  -> QuestionImportRepository.import_question() # privileged offline path
```

`validate_question_import()` is at `backend/src/memora/modules/questions/validation.py`. The privileged import is at `backend/src/memora/modules/questions/repository.py`. No HTTP route and no CLI are required.

A draft is validated offline and stopped before import. It must not be converted by stripping the envelope and calling T12, because that would persist `source_class = expert_verified` without the review evidence.

### 4.1 Mapping-level provenance

T12 requires `provenance_type` and `provenance_ref` on every `ConceptMappingImport`. The pilot convention is:

| State | Allowed `provenance_type` | Example |
| --- | --- | --- |
| Draft, no review | `analyst_mapping` or `source_analysis` | `analyst_mapping` |
| Approved after review | `pilot_review` | `pilot_review` |

The validator enforces both directions: a draft may use only `analyst_mapping` or `source_analysis`, and an approved item must use `pilot_review`. The provenance reference identifies the source analysis or the review record; it is not a substitute for the question-level `source` block.

## 5. Worked example: synthetic draft

The canonical example is `examples/synthetic_draft.json`. It is deliberately synthetic: it has no examination year, paper, question number, page or source document. It uses the existing T08 displacement concept version `50000000-0000-0000-0000-000000000003` and objective `30000000-0000-0000-0000-000000000005`, and it is a draft.

Key fields:

```json
{
  "pilot_id": "PILOT-PHYS-2099-P1-Q01",
  "source": {
    "source_id": "SYNTHETIC-T24-KINEMATICS-001",
    "source_type": "synthetic",
    "document_filename": null,
    "document_sha256": null,
    "exam_year": null,
    "exam_label": "synthetic",
    "paper": null,
    "question_number": null,
    "pdf_page": null,
    "medium": "English",
    "official_key_status": "not_applicable",
    "reproduction_status": "not_applicable",
    "reproduction_approval_ref": null,
    "licence_note": "Synthetic example for the T24 draft workflow. No third-party source or reproduction right is claimed.",
    "transcription_verified": false
  },
  "question": {
    "question_code": "synthetic-phys-kinematics-mcq-001",
    "source_class": null,
    "target_source_class": "expert_verified",
    "question_type": "mcq",
    "validation_status": "draft",
    "author_principal": null,
    "reviewer_principal": null,
    "rubric": {
      "rubric_type": "exact",
      "max_score": 1,
      "evidence_ceiling": 0.9,
      "status": "draft",
      "payload": {
        "kind": "exact",
        "schema_version": "1"
      }
    }
  },
  "answer_verification": {
    "independent_review_status": "pending",
    "reviewer_ref": null,
    "official_key_claimed": false
  },
  "review": {
    "academic_review_status": "pending",
    "reviewer_principal": null,
    "reviewer_qualification_ref": null,
    "reviewed_at": null,
    "ambiguity_status": "pending",
    "duplicate_status": "pending",
    "content_hash": null,
    "source_ref": "SYNTHETIC-T24-KINEMATICS-001",
    "independence_declaration_ref": null
  },
  "publication": {
    "approved_for_import": false,
    "approved_by": null,
    "approved_at": null,
    "import_batch_id": null
  }
}
```

The full example adds the synthetic prompt, five options, one primary mapping and a pending derivation. The question is: a cyclist accelerating uniformly from rest; the derived displacement is 9.0 m. It is not a past-paper question and does not claim to be one.

### 5.1 Probe result

`examples/synthetic_draft.json` was passed to `validate_pilot_envelope()` without a database. It was accepted as a draft. The question member was converted with `target_source_class = expert_verified` and `validation_status = draft`, then passed to T12 `validate_question_import()`; T12 accepted it and produced a content hash. Reusing the payload with `validation_status = "approved"` and null principals was rejected with `reviewer_required`. Adding a `source_ref` field to `content` was rejected by `validate_question_import()` with `content_invalid`; the outer bundle model alone does not reject it because its `content` member is a plain mapping.

These are contract observations, not approval evidence. The synthetic example is not imported or persisted.

## 6. Validation limits

- The JSON Schema file is syntactically valid JSON and is checked for parseability, internal `$ref` resolution and `required`/`properties` consistency in tests.
- `jsonschema 4.26.0` is installed locally and declared as a constrained development dependency (`jsonschema>=4.23,<5`) in `backend/pyproject.toml`. The schema passes `Draft202012Validator.check_schema()`, and the synthetic draft and approved synthetic payload validate with zero errors. Negative tests cover missing approval evidence, contradictory draft/approved states, source metadata in `content` and Paper II IDs. This is real metaschema and payload validation, not a JSON parse check.
- The Python validator is the semantic authority for draft/approval gates. T12 validation remains authoritative for its own import contract.
- The schema does not validate academic truth, transcription accuracy, reviewer qualification, licence status or reproduction permission.
- The schema does not create a database column, migration or API field.
- The schema cannot enforce reviewer != author; the Python validator does.

## 7. Stage 2 use

1. Keep past-paper text in the ignored local review pack until reproduction is approved.
2. Add one JSON record per candidate, all `validation_status = "draft"` with `source_class = null`.
3. Run the Draft 2020-12 metaschema/payload tests and `validate_pilot_envelope()` in CI without a database.
4. Run the duplicate, ambiguity and coverage checks.
5. Record real reviewer and author principals only after those identities exist.
6. Flip to `approved` only after every gate in `REVIEW_CHECKLIST.md` passes and the content hash is recorded.
7. Import through `to_validated_import()` and `QuestionImportRepository` only after approval and reproduction clearance.
