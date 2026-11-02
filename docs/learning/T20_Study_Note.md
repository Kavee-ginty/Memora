# T20 Privacy Export and Deletion Backend

## Contract

T20 implements the five operations assigned in the reviewed API inventory:

- `POST /v1/privacy/exports` (`createPrivacyExport`)
- `GET /v1/privacy/exports/{request_id}` (`getPrivacyExport`)
- `POST /v1/privacy/deletions` (`createPrivacyDeletion`)
- `GET /v1/privacy/deletions/{request_id}` (`getPrivacyDeletion`)
- `POST /v1/privacy/deletions/{request_id}/cancel` (`cancelPrivacyDeletion`)

Mobile user experience and settings screens remain `T21` work.

## Recent Authentication and Idempotency

Both export and deletion requests require recent interactive authentication using the OIDC/Supabase `amr` claim window (`require_recent_authentication`). If the authenticated session timestamp is missing or older than the configured `recent_auth_window_seconds` (10 minutes), the request is rejected with `403 recent_authentication_required`.

Mutations require an `Idempotency-Key` header:
- Repeated requests with the identical key return the existing operation without launching duplicate processing.
- A reused idempotency key with a changed body is rejected with `409 idempotency_key_reused`.
- Active requests in progress converge cleanly so users cannot spin up parallel conflicting deletions or exports.

## Cancellation Invariants

Deletion requests can be cancelled only while in `requested` or `verifying` status. Once processing commences, cancellation is disallowed (`409 deletion_cancellation_disallowed`) to guarantee data integrity across scopes. Cancelling an already-cancelled request returns the existing cancelled state idempotently.

## Multi-Scope Deletion and Append-Only Proofs

Account deletion runs as a durable multi-stage background job via `memora.worker`:
1. **Database Learner State:** Anonymizes user profile, removes push device registrations, and cleans private learning states while preserving database constraints.
2. **Temporary Uploads:** Reconciles and proves absence of temporary raw files and derivatives.
3. **Auth Provider Scope:** Marks the identity link as deleted and anonymizes the OIDC subject mapping.

Each scope records an immutable entry in `deletion_proofs`. PostgreSQL triggers prevent update or deletion of recorded proofs (`deletion_proofs_append_only`). Terminal deletion status is reached only after all required scopes have recorded proofs or documented legal/security retention exceptions.

## Security, Auditing and Data Isolation

- All queries enforce server-derived ownership resolved from the verified session subject via `memora_resolve_user_id`. PostgreSQL Row-Level Security (`memora_api` role) provides defense-in-depth isolation. Cross-user access is impossible and rejected with `404 not_found`.
- Lifecycle actions are audited in `audit_events` with strict redaction: no PII, passwords, student notes, or tokens are ever stored or logged.
- Completed deletion responses never echo deleted learner data.
- Export archives are not streamed directly through JSON; instead, an ephemeral signed download URL with a 24-hour TTL is issued upon completion.

## Verification

- Automated tests cover:
  - Route authentication and idempotency validation (`test_privacy_api.py`).
  - Recent authentication gating (recent vs stale vs non-interactive tokens).
  - Deletion lifecycle, confirmation validation, and safe cancellation rules.
  - End-to-end export and deletion job execution via worker (`test_privacy_db_contracts.py`).
  - Immutability of deletion proofs.
  - Cross-user isolation and authorization rejection.
  - OpenAPI schema canonical validation and artifact consistency (`test_openapi_artifact.py`, `test_openapi_contract.py`).
