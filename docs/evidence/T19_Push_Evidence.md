# T19 Push and Deep-Link Evidence

## Scope

This record covers the T19 push-notification integration and validated
deep-link experience:

- Closed push payload contract with safe lock-screen detail bands (API §16.2,
  PRD 031).
- Provider adapters behind one protocol, selected by configuration allowlist,
  with credential-absent degraded operation (TRD §3.3, §16.2).
- Send-time enforcement: expiry, preferences, category choice, reminder caps
  per user-local day, quiet hours in the recipient's timezone with the
  preferred-window exception (PRD 032).
- Consume-once at the source (outbox + delivery ledger) and on the client
  (durable bounded intent ledger).
- Validated deep links: session, expiry, ownership and workflow state are
  checked through existing read operations before navigation; expired,
  wrong-owner, invalid-state and malformed intents resolve to the Flow §13.1
  stable parent with a brief explanation.
- Non-blocking foreground notices that never interrupt an active answer and
  queue until the answer surface closes (Flow §13.2).
- Trigger events emitted in the same transaction as the authoritative change
  by the merged T09/T11/T13/T20 producers; `reward.granted` reserved for T15.

T17/T18 notification-settings screens, T15 reward producers, T22 offline
reconciliation and all real-device push delivery remain outside the automated
evidence below; the device record is the explicit human checklist in the last
section and is completed on the designated non-production Firebase project
before the task leaves Review.

## Automated backend evidence

Environment: Windows, Python 3.12 venv, disposable `memora_test` PostgreSQL
database from the Compose stack (synthetic fixtures only).

| Requirement | Evidence |
| --- | --- |
| Payload contract (redaction, bands, expiry, opaque ids) | `backend/tests/test_notification_payload.py` — 18 tests: allowlist rejection, detail bands, non-UTC expiry rejection, wire-form round trip, registry-mismatch rejection |
| Provider adapters (contract, failure classes, token cache, redaction) | `backend/tests/test_notification_providers.py` — 12 tests: success/retryable/permanent classification, 401 refresh-and-retry, unregistered-token permanence, transport timeout, credential-absent degradation, no parameter or token in logs |
| Enforcement (quiet hours incl. DST, caps, category, consume-once, RLS, append-only) | `backend/tests/test_notification_service.py` — 27 tests, DB-gated: quiet hours in the recipient timezone with preferred-window exception and spring-forward boundary, cap at exactly the boundary, zero-cap, category disabled, duplicate trigger convergence under a real advisory-lock race, revoked-device skip, corrupt-token failure, worker role boundary, cross-owner RLS denial, ledger append-only trigger |
| Worker (one send per unseen trigger, envelope tolerance, resource resolution) | `backend/tests/test_notification_worker.py` — 11 tests, DB-gated: backlog idempotence, all six trigger types, due-memories mission resolution and `resource_unavailable` consumption, duplicate-resource convergence, job replay refusal, unknown-type/malformed/missing-event dead-letters |
| Producer emissions (same-transaction, safe payloads) | `backend/tests/test_notification_triggers.py` — 4 tests, DB-gated: `mission.ready` at today-mission materialization (replay emits nothing new), `ingestion.learning_path_committed` at commit (alongside the untouched T09 event), `ingestion.verification_required` at extraction finish with pending requests, `privacy.export_ready` at export completion |
| Migration | `backend/tests/test_migrations.py` full round trip incl. `20261111_0015` up/down |
| Contracts | `tools/contracts/generate_contracts.py --check` — exit 0, zero OpenAPI/client diff (T19 adds no public operation) |

Full-suite results at implementation close: **741 passed, 7 skipped**
(backend, with `MEMORA_TEST_DATABASE_URL`; skips are unrelated suites needing
additional disposable resources) with `ruff format` and `ruff check` clean.

## Automated mobile evidence

Environment: Windows, Flutter 3.47.x / Dart 3.13.x, no Firebase configuration
required (the gateway degrades to `unavailable` under test).

| Requirement | Evidence |
| --- | --- |
| Gateway contract and degradation | `mobile/test/notifications/notification_gateway_test.dart` — 5 tests: permission states, sticky denial, broadcast streams, cold-start message |
| Token registration (idempotency, rotation, denial, failure swallowing) | `mobile/test/notifications/device_token_registrar_test.dart` — 8 tests: stable installation id, token-scoped idempotency key, denied/missing-token skips, transport-failure swallowing, prompt-once flag |
| Registration orchestration | `mobile/test/notifications/push_registration_controller_test.dart` — 5 tests: register on activation, denied never registers or re-prompts, sign-out reset, unavailable terminal state, token-rotation re-registration |
| Intent parsing (wire contract mirror) | `mobile/test/notifications/notification_intent_test.dart` — 8 tests: six categories, schema/registry mismatch rejection, non-UTC expiry rejection, boundary expiry |
| Consume-once ledger (durable, bounded, corrupt-safe) | `mobile/test/notifications/consumed_intent_ledger_test.dart` — 4 tests: survives instance recreation, 200-entry trim, corrupt-store degradation |
| Deep-link validation matrix | `mobile/test/notifications/deep_link_coordinator_test.dart` — 12 tests: malformed discard, expired fallback + consume, replay refusal, signed-out hand-off without consumption, per-category validation (mission, verification, learning-path committed-state, reward, privacy), wrong-owner/invalid-state fallbacks with explanations |
| Foreground notice (non-blocking, suppression, a11y) | `mobile/test/notifications/foreground_notice_test.dart` — 7 tests: contextual copy, tap consumes + navigates, dismiss changes nothing, queue during active answer drains after route change, polite live region, 320 px + 200% text |
| Regression: fallback explanation surfaced after navigation | included in the notice suite (`notice_explanation` snackbar) |

Full-suite results at implementation close: **651 passed** with
`flutter analyze` at zero errors.

## Safe fallback screenshots (automated placeholders)

The fallback paths are covered by coordinator widget tests rather than
goldens because the fallback UX is a destination route plus an explanation
snackbar, not a distinct screen. The device record below captures the same
paths on real builds with real push payloads.

## Device integration evidence (human-run, pending)

To be executed on the designated non-production Firebase project (shared test
resource; may be reset freely) with `MEMORA_NOTIFICATION_PROVIDER=fcm` on the
backend and the project's `google-services.json` /
`GoogleService-Info.plist` installed. Every row produces a screenshot or
screen recording stored next to this file (`t19/<platform>/<scenario>.png`).

| # | Platform | Scenario | Expected | Capture |
| --- | --- | --- | --- | --- |
| 1 | Android | Permission prompt once per install; grant registers device (bootstrap → device row with encrypted token) | Registration succeeds; denial later never blocks use | screenshot of prompt; backend delivery ledger row |
| 2 | Android | Foreground notice: daily-mission push while on Home | Non-blocking banner, polite announcement, no navigation | screenshot |
| 3 | Android | Tap foreground notice (mission intent) | Consume-once, validated navigation to mission preview | screenshot |
| 4 | Android | Background tap: verification-required push | Verify-concepts route after validation | screenshot |
| 5 | Android | Cold-start tap: privacy export ready | Export-status route after validation | screenshot |
| 6 | Android | Expired intent (payload expiry in the past) | Stable parent + explanation snackbar, no destination navigation | screenshot |
| 7 | Android | Wrong-owner or deleted resource id | Stable parent + explanation, never an error surface | screenshot |
| 8 | Android | Notice during an active mission item | Suppressed; queued notice appears after leaving the item | recording |
| 9 | Android | Kill and restart after tapping a notice | Replay of the same notification does nothing (consume-once) | recording |
| 10 | Android | Quiet hours (set window around now, disable after) | No push during window; delivery ledger shows `quiet_hours` skip | ledger export |
| 11 | iOS | Permission prompt, grant, foreground notice, tap, cold-start tap | Same as Android rows 1–5 | screenshots |
| 12 | iOS | Quiet hours + reminder cap (cap = 1, two pushes) | Second reminder skipped; ledger shows `reminder_cap_reached` | ledger export |

Record results and any deviation in the table above; a task cannot leave
Review with pending rows. Device evidence may use the synthetic pilot account
only (no real student data), consistent with the shared-test-resource policy.
