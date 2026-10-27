# T06 Identity and Session Backend

## Contract

T06 implements the six operations assigned in the reviewed inventory:

- `GET /v1/session/bootstrap`
- `POST /v1/session/revoke`
- `POST /v1/devices`
- `DELETE /v1/devices/{device_id}`
- `GET /v1/consent`
- `POST /v1/consent/acceptances`

Profile/preferences mutation remains T17 work. Mobile authentication and guarded
navigation remain T07 work.

## Supabase Auth decision

Memora uses Supabase Auth with Google OAuth. The backend remains dependent on the
standard token contract rather than Google identity fields: asymmetric signature,
exact Supabase issuer, audience `authenticated`, expiry, issued-at, subject, role
and session identifier. Anonymous and non-authenticated tokens are rejected.

Recent authentication uses the latest interactive Supabase `amr` timestamp and a
ten-minute window. Token-refresh timestamps do not count. Missing or stale evidence
returns `recent_authentication_required`.

Supabase logout scopes map as follows:

| Memora | Supabase |
| --- | --- |
| `current` | `local` |
| `other_sessions` | `others` |
| `all` | `global` |

Supabase access JWTs can remain valid until expiry after logout. They must therefore
remain short-lived.

Session revocation keeps the same idempotency record across provider failures.
Same-body retries may safely repeat Supabase's idempotent logout call, while the
database completion transition permits only one successful audit event. A changed
body with the same key is rejected.

## Ownership and sensitive data

The API resolves the local user from validated issuer and subject. Every private
query also includes that local `user_id`; PostgreSQL RLS remains defense in depth.
Each identity transaction first selects the restricted `memora_api` role and then
sets the authenticated user context used by RLS policies.
Unknown authenticated subjects are provisioned during bootstrap with the approved
Physics subject when the seed exists.

Push tokens use AES-256-GCM with a fresh nonce and owner-bound associated data.
Deduplication uses a separate HMAC-SHA-256 fingerprint key. Neither plaintext token,
authorization header nor provider response is logged or returned.

Consent evidence is append-only. `terms` and `privacy` gate account capabilities;
`material_processing` and `model_processing` additionally gate ingestion. Policy
versions are server configuration and deployed environments reject unapproved
placeholders.

## Verification

Focused tests cover token signature/audience/expiry, recent authentication, safe
error envelopes, bootstrap shape, encryption and redaction, consent-version checks,
and device ownership isolation. OpenAPI and the Dart client are regenerated from
the typed routes; generated files are not edited manually.
