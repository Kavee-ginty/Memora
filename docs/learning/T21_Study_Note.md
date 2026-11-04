# T21 Privacy Mobile Experience Study Note

## Scope

T21 builds the student-facing privacy workflow on top of the T20 privacy API:

- Retained-data overview at `/profile/privacy`.
- Export request, status, polling, expiry and download.
- Deletion explanation, explicit confirmation, status and permitted cancellation.
- Recent-authentication recovery for privacy mutations.
- Truthful pending, failed, cancelled, completed and unknown states.
- Offline mutation disabling with a visible reason.
- Account and session clearing only after server-confirmed deletion with proof
  state.

Out of scope:

- T18 profile preferences, notification settings and accessibility settings.
- T19 push-provider adapters and deep-link intent consumption.
- T22 versioned offline persistence, drafts and reconciliation queues.
- T15 progress, XP, streak and reef projections.
- Backend, OpenAPI, migration or generated-client changes.

## Authoritative inputs

- PRD 033-035.
- TRD 14-16.
- UI/UX 9.20, 12-16 and the state matrix.
- Flow 3.3, 4, 5, 12.2, 13.1, 14 and 15.
- API 17-18 and 21.
- Schema 13.5 and 17.
- `docs/screens/Profile.png` for retained composition only.

No privacy-specific PNG exists. The approved composition is spec-derived from
`Profile.png`, UI/UX 9.20 and Flow 12/14. Intentional differences are recorded in
`docs/evidence/T21_Privacy_Evidence.md`.

## Routes

| Route | Purpose | Guard |
| --- | --- | --- |
| `/profile/privacy` | Retained data and request overview | Active session; deletion-pending exception |
| `/profile/privacy/exports/:requestId` | Export status and download | Active session |
| `/profile/privacy/deletions/:requestId` | Deletion status and cancellation | Active session; deletion-pending exception |
| `/profile/privacy/delete` | Explanation and explicit confirmation | Active session |
| `/profile/privacy/reauthenticate` | Recent-auth recovery | Active session |

Privacy routes live outside the four-destination root shell so the bottom
navigation is not available during a sensitive workflow.

## Domain state

`PrivacyRequestStatus` is `requested`, `verifying`, `processing`, `completed`,
`failed`, `cancelled` or `unknown`.

- Pending: `requested`, `verifying`, `processing`.
- Terminal: `completed`, `failed`, `cancelled`.
- `unknown` is never treated as pending or terminal. It is shown as
  "Status unavailable" with a manual refresh action.

Generated `unknown_default_open_api` values map to domain `unknown`; they never
map to complete or failed.

## Idempotency

- One stable idempotency key is reused while the same create or cancel intent is
  unresolved.
- A key is replaced only after a terminal response or after the user starts a new
  request.
- Reauthentication retries the pending action once with the same key.
- A second recent-auth rejection stops and asks the student to sign in again.
- Across process restart, the bootstrap `pending_privacy_requests` summary is the
  recovery source. A new request is not created while a matching pending request
  exists.

## Recent authentication

T20 requires an interactive authentication no older than ten minutes for export
and deletion creation. The client does not use a local clock to pre-block
mutations. It reacts to `403 recent_authentication_required` by opening the
reauthentication screen and retrying the pending action once.

Email/password accounts confirm with their password. Google-only accounts use
"Continue with Google" without re-bootstrapping the whole session. The
reauthentication path preserves the current phase, bootstrap data and pending
privacy state.

## Deletion lifecycle

1. The student reads the explanation and ticks the explicit confirmation.
2. A final destructive dialog is required.
3. The create response returns `requested`; the client navigates to the deletion
   status route first.
4. The session controller then applies a local `deletion_pending` projection so
   the rest of the app is blocked immediately without a bootstrapping splash.
5. The status route remains reachable through the restricted exception.
6. Cancellation is offered only for `requested` or `verifying`.
7. A successful cancellation restores the local account status to active.
8. Completion is claimed only when the server returns `completed` and proof
   state. Missing proofs show a support-safe proof-missing state.
9. `clearAfterAccountDeletion` runs only for confirmed completion. It clears
   local account-scoped data and signs out locally; it does not call remote
   session revocation.

If the access token expires while deletion is processing, the client cannot
fetch the final state. It shows an outcome-unconfirmed state with the request ID.
It does not infer completion, does not clear account data as deleted, and does
not claim success.

## Offline behavior

The client uses `GET /health/live` with a short timeout as the reachability
check. It does not add a connectivity dependency.

While unreachable:

- Export request, deletion request, cancellation and download are disabled.
- A visible offline banner states the reason.
- Last-known status remains readable with a last-checked label.
- Polling stops; a resume or manual action rechecks reachability.

## Evidence plan

- Repository tests for DTO mapping, headers, idempotency, errors and URL safety.
- Controller tests for request, polling, download, reauthentication, cancellation,
  failure, offline and confirmed clearing.
- Widget flow tests for every state and the explicit destructive confirmation.
- Guard tests for the deletion-pending exception.
- Accessibility tests at 320 px, 200% text, semantics, focus, keyboard and
  reduced motion.
- Windows golden captures for overview, export pending/ready, deletion
  confirmation/pending/complete, reauthentication and offline states.
- `docs/evidence/T21_Privacy_Evidence.md` records commands, captures and manual
  device evidence.

## Decisions recorded

- Branch: `task/T21-privacy-mobile`.
- Owner: Neleesha Peiris.
- Visual composition: approved spec-derived from `Profile.png` and UI/UX 9.20 /
  Flow 12/14.
- Download: `url_launcher` opens the signed URL in the external browser.
- Reauthentication: email/password and Google-only "Continue with Google",
  without re-bootstrapping.
- Deletion-pending access: restricted to the privacy overview and deletion
  status routes, plus a recovery-screen action.
- Unconfirmed deletion outcome: no completion claim and no deletion-based
  clearing.

## Follow-ups outside T21

- T19 owns privacy status deep-link intent consumption.
- T22 owns durable offline operation identity and reconciliation.
- T27 owns the full accessibility and visual QA sweep.
- A T20 follow-up may expose a short-lived status/proof token if product needs
  proof retrieval after the access token expires.
