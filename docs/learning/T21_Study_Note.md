# T21 Privacy Mobile Experience Study Note

## Scope

T21 builds the student-facing privacy workflow on top of the T20 privacy API:

- Retained-data overview at `/profile/privacy`, including named retained
  categories and the distinction between temporary uploads and verified
  knowledge.
- Export request, status, polling, non-null server expiry and download.
- Deletion explanation, explicit confirmation, status and permitted cancellation.
- Recent-authentication recovery for privacy mutations.
- Truthful pending, failed, cancelled, completed and unknown states.
- Offline navigation and mutation disabling with a visible reason.
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

## Download readiness

An export is downloadable only when all of these are true:

- the status is `completed`;
- the server returned a signed download URL; and
- the server returned a non-null expiry that is still in the future.

A completed export without an expiry is shown as completed but not
downloadable, with an explanation. The client never treats a missing expiry as
"no expiry" and never opens a launcher for it. The signed URL is never logged,
rendered or persisted.

## Idempotency and pending summaries

- One stable idempotency key is reused while the same create or cancel intent is
  unresolved.
- A key is replaced only after a terminal response or after the user starts a new
  request.
- Reauthentication retries the pending action once with the same key.
- A second recent-auth rejection stops and asks the student to sign in again.
- Across process restart, the bootstrap `pending_privacy_requests` summary is the
  recovery source. A new request is not created while a matching pending request
  exists.
- A created export is upserted into the local pending summary so the hub can
  discover it. A terminal export is removed from that summary. Both are local
  projections; they never infer completion or failure from the local status.
- A retry that fails for a reason other than recent authentication resets the
  recent-auth retry guard. A later `403 recent_authentication_required` can
  therefore open recovery again instead of being treated as the second
  rejection.

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

- Hub workflow navigation, export request/refresh/download and retry, deletion
  confirmation/refresh/cancel/retry, and reauthentication submission are
  disabled.
- A visible offline banner states the reason and keeps a labelled retry action.
- Last-known status remains readable with a last-checked label. A pending
  bootstrap summary is described as last reported, not live.
- Polling stops; a resume or manual action rechecks reachability.
- The offline Retry action rechecks reachability. Once reachable, contextual
  retry on the export and deletion screens resumes the failed creation with the
  same idempotency key rather than only rechecking the health endpoint. The
  deletion-status Retry also probes reachability before loading status.

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

## Implementation outcome

The task is implemented on `task/T21-privacy-mobile` in seven commits:

1. `docs(T21): claim privacy mobile task and record plan`
2. `feat(T21): add privacy domain models and repository`
3. `feat(T21): add privacy request state controller`
4. `feat(T21): add retained-data and export/deletion screens`
5. `feat(T21): add privacy routes and reauthentication recovery`
6. `test(T21): cover privacy states accessibility and visual evidence`
7. `docs(T21): record privacy evidence and handoff`

Final local checks after the review corrections and golden regeneration:
formatting is clean, `flutter analyze` reports no issues, the full Flutter suite
passes with 345 tests (260 auth/privacy), the seven T21 golden comparisons pass,
the Android debug APK builds, and the OpenAPI/generated client drift check
passes.

The 200% text matrix found two real presentation defects, both fixed inside the
owning implementation: the status-card header now wraps instead of overflowing,
and short privacy pages are top-aligned instead of vertically centered.

The final audit also tightened download readiness to require a non-null future
server expiry, surfaced created exports through the local pending summary, reset
the recent-auth retry guard after unrelated failures, named retained-data
categories on the hub, and disabled every privacy mutation and navigation while
offline with a visible reason. These corrections are included in the final T21
review changes on the task branch.

T21 is **Done**. Pull request #49 merged into `develop` at `d387506`, all required
CI checks passed, and the post-merge privacy run passed 112 Flutter privacy
tests, 16 backend API/workflow tests and 8 real PostgreSQL/durable-worker
contracts. The repository owner accepted the missing Android
TalkBack/keyboard-switch/manual-device record as an approved deviation on 11
November 2026; T27 retains that full device accessibility sweep. Full command
results, captures and the deviation are recorded in
`docs/evidence/T21_Privacy_Evidence.md`.

## Decisions recorded

- Branch: `task/T21-privacy-mobile`.
- Owner: Neleesha Peiris.
- Visual composition: approved spec-derived from `Profile.png` and UI/UX 9.20 /
  Flow 12/14.
- Download: `url_launcher` opens the signed URL in the external browser, and
  only with a non-null future server expiry.
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
