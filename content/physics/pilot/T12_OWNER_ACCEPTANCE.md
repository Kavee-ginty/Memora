# T12 Owner Acceptance Request — T24 Pilot

**Status:** Prepared locally. No T12 owner response exists. This is not a confirmation, approval or release decision.

## 1. What T24 asks T12 to accept

T24 keeps the pilot content in a review envelope until a real academic review and approval exist. Only an approved envelope may be converted by `backend/src/memora/modules/questions/pilot_validation.py` into a `ValidatedQuestionImport`. Draft envelopes cannot be converted, imported or published.

T12 does not need a new route for the pilot. T24 needs one owner decision on source provenance and confirmation that the local contract behaviour matches T12's intended boundary.

## 2. Verified locally

| Check | Evidence |
| --- | --- |
| Draft envelope cannot convert to an import bundle | `test_to_validated_import_refuses_drafts` in `backend/tests/test_pilot_content_validation.py` |
| Approved envelope requires real review/approval fields | `test_approved_envelope_requires_author_and_reviewer_principals`, `test_approved_item_requires_publication_approval_and_source_ref`, `test_approved_item_requires_review_and_approval_dates`, `test_approval_cannot_precede_review` in the same file |
| Reviewer and author must differ | `test_approved_envelope_requires_reviewer_independence` |
| Author and reviewer qualification and review scope are required | `test_approved_envelope_requires_qualification_and_scope`, `test_author_qualification_matches_approval_state` |
| Past-paper approval requires reproduction approval and verified transcription | `test_approved_past_paper_requires_reproduction_and_transcription_gates` |
| Unknown T08 concept UUIDs, objective mismatches and duplicate mappings are rejected | `test_mapping_concept_must_exist_in_the_t08_seed`, `test_mapping_objective_must_match_the_t08_concept_objective`, `test_mapping_pairs_must_be_unique_per_concept_and_role` |
| Source metadata cannot be placed in question `content` | `test_source_metadata_cannot_be_smuggled_into_question_content` in `backend/tests/test_questions_models.py`; `test_source_metadata_cannot_be_smuggled_into_content` in `backend/tests/test_pilot_schema_jsonschema.py` |
| Approved questions need reviewer, author, explanation, approved rubric, positive evidence ceiling and a primary mapping | `test_import_rejects_approved_question_without_required_principals`, `test_import_rejects_approved_question_without_explanation`, `test_import_rejects_approved_question_with_draft_rubric`, `test_import_rejects_approved_question_with_zero_evidence_ceiling`, `test_import_rejects_supporting_only_mapping_for_publication` in `backend/tests/test_questions_models.py` |
| Pilot-only fields are removed before T12 validation | `test_pilot_only_author_qualification_is_not_sent_to_t12` |
| Local disposable PostgreSQL migration, import, immutability, publication-guard and RLS suites | 27 passed, 0 failed on `memora_t24_test`; see section 5 |

## 3. What remains unverified

- No T12 owner has confirmed that the repo-side envelope is an acceptable provenance record for the pilot.
- No CI or staging run has accepted the PostgreSQL/RLS suites; the local run is not release evidence.
- T12 has no question-level field for source paper, year, question number, page, licence, author qualification, reviewer qualification or approval timestamp. T24 records both qualification references in its envelope only.
- T12 does not enforce reviewer/author independence. Only the T24 envelope does.
- No real author or reviewer, author or reviewer qualification record, approval record or reproduction permission exists.

## 4. Decisions needed from the T12 owner

1. **Provenance:** Is the approved T24 envelope plus the existing `question_concept_maps.provenance_type/provenance_ref` sufficient for pilot traceability, or must T12 gain a durable question-provenance table/column before import?
2. **Independence:** Does T12 accept that reviewer/author independence is enforced by the T24 envelope and is not a database constraint?
3. **Draft boundary:** Confirm that T12 accepts draft rows for authoring but that T24 drafts must not be converted or imported. If T12 intends to reject all pilot drafts at the repository boundary, identify the required check.
4. **Environment:** Which disposable PostgreSQL/pgvector environment will run the migration, import, immutability and RLS suites for acceptance, and who records the result?
5. **Source metadata:** If a durable provenance field is required, confirm the owning task, migration, API contract and backward-compatibility expectations. T24 will not add it unilaterally.

## 5. Local verification commands and results

Focused non-database suite:

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

Result: **138 passed, 0 failed**.

Disposable PostgreSQL/pgvector suite, using a database whose name ends in `_test`:

```powershell
$dbPassword = docker compose --env-file .env -f infra/compose.yaml exec -T postgres printenv POSTGRES_PASSWORD
$encoded = [uri]::EscapeDataString($dbPassword.Trim())
$env:MEMORA_TEST_DATABASE_URL = "postgresql+psycopg://memora:$encoded@127.0.0.1:5432/memora_t24_test"
$env:PYTHONPATH="$PWD\backend\src"
.\.venv\Scripts\python.exe -m pytest backend/tests/test_migrations.py backend/tests/test_question_db_contracts.py -q
```

Result: **27 passed, 0 failed, 0 skipped** (9 migration tests, 18 question-database contract tests). The database was created solely for this check. The migration tests downgrade to base and are not safe against a shared database.

Note: the migration test uses fixed OIDC subjects. Re-running it against the same non-reset disposable database can resolve a pre-existing user row and fail the RLS assertion. Recreate the `_test` database before a repeat run. This is a test-harness idempotence limitation, not an RLS policy failure.

## 6. Acceptance checklist for the T12 owner

- [ ] Decision recorded for question-level source provenance (D1).
- [ ] Independence enforcement boundary accepted (D2).
- [ ] Draft/import boundary confirmed (D3).
- [ ] Disposable acceptance environment named (D4).
- [ ] Durable provenance decision recorded, if required (D5).
- [ ] No T24 item marked approved or imported before the human evidence in `EVIDENCE_REQUIRED.md` exists.
