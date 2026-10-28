# T09 Learning Ingestion Backend

## Contract

T09 implements the twelve permanent ingestion operations assigned in the reviewed API inventory:

- `POST /v1/learning-updates`: create a draft learning update (`manual_text`, `pdf`, `image`, or `mixed`)
- `GET /v1/learning-updates`: list owned learning updates with cursor pagination
- `GET /v1/learning-updates/{update_id}`: get update status and source upload summaries
- `PATCH /v1/learning-updates/{update_id}`: edit draft manual text or learned-at timestamp with optimistic row-version concurrency
- `DELETE /v1/learning-updates/{update_id}`: discard an uncommitted update and enqueue source cleanup
- `POST /v1/learning-updates/{update_id}/uploads`: request a single-use presigned PUT upload grant
- `POST /v1/learning-updates/{update_id}/uploads/{upload_id}/finalize`: independently verify uploaded storage object bounds, magic bytes, and SHA-256 digest, then enqueue extraction
- `POST /v1/learning-updates/{update_id}/retry`: retry extraction or deletion on failed updates
- `GET /v1/learning-updates/{update_id}/candidates`: list extracted candidate concepts, questions, and facts
- `POST /v1/learning-updates/{update_id}/verification-decisions`: submit learner decisions (`accept`, `edit`, `reject`, `merge`)
- `GET /v1/learning-updates/{update_id}/preview`: preview learning path additions and check commit blockers
- `POST /v1/learning-updates/{update_id}/commit`: atomically commit accepted knowledge, emit an outbox event, and enqueue temporary source deletion

Downstream boundaries: Mobile ingestion screens remain T10. Mission generation remains T13 (`first_mission` returns `null`), memory scheduling T11, XP/reef T15, and privacy exports/deletions T20.

## Lifecycle and State Machine

An update transitions through: `draft` -> `uploading` -> `processing` -> `verification_required` -> `committed` -> `deleted` (or `failed` / `expired`).

- Terminal states never regress. Multiple same-day updates are fully independent; deduplication relies on `(user_id, client_operation_id)`.
- Manual text is encrypted at rest using AES-256-GCM with a dedicated ingestion key and an update-bound associated value (`MEMORA_INGESTION_ENCRYPTION_KEY`). It is decrypted only during worker extraction and is never exposed in list or read responses.
- Temporary file uploads: upload grants have a 15-minute TTL bound to exactly one update and file. Finalize performs strict verification: magic byte signatures (`%PDF-`, PNG, JPEG), declared vs. detected media type concordance, byte bounds (max 25 MiB), and SHA-256 matching before transitioning the update to `processing`.

## Extraction and Candidate Evidence

- Worker execution claims pending `extraction` jobs with `FOR UPDATE SKIP LOCKED`, sets a bounded lease, and heartbeats during execution.
- Extraction providers:
  - `DeterministicExtractionProvider`: local test and offline extraction producing deterministic concepts, questions, and facts from synthetic text and PDFs.
  - `OpenRouterExtractionProvider`: calls external LLMs with candidate schema framing, retry backoff, and robust error handling.
- AI output is treated strictly as candidate evidence. Candidates with confidence >= 0.85 are automatically `accepted`; candidates below 0.85 become `needs_verification` and spawn an active verification request.
- Models never directly alter mastery, schedules, XP, or reef condition.

## Verification, Preview, and Atomic Commit

- Learners verify candidates via `/verification-decisions`. Submitted actions (`accept`, `edit`, `reject`, `merge`) update candidate status, record decision audit entries, and preserve optimistic concurrency via `candidate_version`.
- Path preview computes actionable new concepts, estimated mission time, and validates whether unresolved verification items block commit.
- Commit is executed in a single atomic database transaction:
  - Validates that no candidates remain in `needs_verification`.
  - Maps accepted concepts into curriculum concepts or private knowledge (`concept_mappings`).
  - Writes a permanent `knowledge_commits` record with committed concept/fact counts.
  - Appends an outbox event (`learning_update.committed`) for downstream asynchronous consumers.
  - Transitions update status to `committed` and enqueues a `source_deletion` job.
  - Repeated commit calls return the stored commit idempotently without emitting duplicate outbox events.

## Temporary Source Deletion and Cryptographic Proof

- Raw uploaded source files are temporary. Once committed (or expired/discarded), the worker deletes the file from object storage (S3 or memory adapter).
- The worker verifies absence using a HEAD request and writes a verifiable record to `deletion_proofs` with a SHA-256 hashed target fingerprint and server timestamp.
- Background reconciler (`memora.worker.reconciler`) sweeps unfinalized uploads past their grant TTL and expired draft updates.

## Least Privilege and Worker Security Posture

The ingestion worker operates under restricted privileges:
- The worker never has direct `UPDATE` privileges on `learning_updates`.
- Two audited `SECURITY DEFINER` functions guard status transitions:
  - `memora_ingestion_context(p_update_id, p_user_id)`: securely fetches update context and decrypts text only within the authorized job boundary.
  - `memora_ingestion_mark_update(p_update_id, p_user_id, p_status, p_failure_code)`: enforces state machine transitions.
  - `memora_reconcile_expired_ingestion(p_cutoff)`: reconciles expired uploads and drafts without giving the reconciler broad write access across users.
- Redaction guarantee: worker logs never contain note text, signed URLs, authorization tokens, full object storage keys, or raw provider payloads.

## Idempotency and Concurrency

- Retriable endpoints accept `Idempotency-Key` headers. Request bodies are normalized and SHA-256 hashed; repeated requests with identical payloads return cached responses, while key reuse with mismatched payloads yields `idempotency_key_reused`.
- Concurrent finalizations and duplicate commits converge safely under partial unique constraints and atomic state updates.
- Optimistic locking via `row_version` and `candidate_version` prevents lost updates during concurrent edits or verification submissions.

## Contracts and Client Generation

- OpenAPI 3.1 specification exported to `contracts/openapi/memora-v1.json`.
- Generated Dart client (`contracts/dart/memora_api_client`) with `dart-dio` and `built_value`.
- Enforced container guarantees via Pydantic `json_schema_extra` on `CreateLearningUpdateRequest`, `UploadGrantResponse`, and `VerificationDecision` to prevent optional collection generation bugs in `dart-dio`.
- Renamed response property `learning_update` on `SubmitVerificationDecisionsResponse` to avoid collision with `built_value` `Builder.update` method.
- 16 Dart contract tests pass in `contracts/dart/memora_api_client_contract_tests`, including full round-trip serialization tests for all ingestion models.

## Verification Evidence

- Formatting and linting: `ruff check backend`, `ruff format --check backend` passed with 0 errors.
- Unit and integration tests: 256 tests passed in `backend/tests`, covering upload validation, presigned grants, S3 SigV4 presigning, AES-256-GCM encryption, worker lease handling, extraction deduplication, verification decisions, path preview, atomic commit, outbox emission, deletion proofs, owner isolation, and the 8 dedicated bug-hunt regression tests in `test_ingestion_bug_hunt.py`.
- Contract drift check: `generate_contracts.py --check` passed cleanly with 0 drift.
- Dart client test suite: `dart test` passed all 16 contract tests.

## References

- `docs/learning/T01_T04_Study_Note.md` — database migrations, RLS and seed foundations.
- `docs/learning/T02_Study_Note.md` — CI, Compose, and environment boundaries.
- `docs/learning/T05_Study_Note.md` — OpenAPI contract generation and Dart client tooling.
- `docs/learning/T06_Study_Note.md` — Supabase authentication, RLS session context, and error envelopes.
- `docs/learning/T09_Implementation_Guide.md` — detailed T09 implementation guide and commit sequence.
- `docs/specifications/Memora_PRD.md` §5-10.
- `docs/specifications/Memora_TRD.md` §10-11.
- `docs/specifications/Memora_Backend_Schema_and_Data_Model.md` §8, §13.
- `docs/specifications/Memora_API_and_Integration_Contract.md` §11-12, §20-22.
