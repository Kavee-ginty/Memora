# T19 study note — push notifications and validated deep links

Companion to `docs/learning/T19_Implementation_Guide.md` (git-ignored). This
note is the committed record of what T19 built, why each locked decision was
made, and the exact verification evidence. Status at writing: implementation
complete through the foreground-notice commit; device integration evidence is
recorded separately in `docs/evidence/T19_Push_Evidence.md` once the
designated non-production Firebase project is attached.

## 1. What was built

**Backend** (`modules/notifications/`, `worker/notifications.py`, migration
`20261111_0015`):

1. **Closed payload contract** — six notification categories, each mapped to
   a route intent, a valid destination and a stable fallback parent exactly
   per Flow §13.1. The payload builder is the only place payloads are
   assembled; it rejects parameters outside the safe allowlist
   (`subject_name`, `count`), applies the recipient's `lock_screen_detail`
   band (minimal strips everything, subject keeps the subject name, detailed
   keeps both), and stamps every payload with a per-send opaque notification
   id. Note text, answers, misconception details and tokens are
   structurally inexpressible.
2. **Provider adapters** — one protocol, two implementations selected by
   `MEMORA_NOTIFICATION_PROVIDER`: `logging` (default; records dispatches
   with no external calls) and `fcm` (HTTP v1 with a PyJWT-signed
   service-account assertion and a stdlib transport). Provider responses
   reduce to bounded reason codes; credentials arrive via environment only.
   Zero new backend runtime dependencies (D2).
3. **Delivery ledger and enforcement** — migration `20261111_0015` adds the
   append-only, RLS-guarded `notification_deliveries` table with SECURITY
   DEFINER worker functions (identical pattern to the T09/T11 migrations).
   Dispatch enforces, in order: expiry → preferences enabled → category
   choice → reminder cap per user-local day → quiet hours in the recipient's
   IANA timezone (preferred window is the user's exception) → consume-once
   per trigger dedupe key. Every blocked dispatch records one skipped row
   with a closed reason code; denial never blocks any user flow.
4. **Worker integration** — `notification.send` job type plus one job per
   unseen trigger outbox event (reconcile never resurrects dead-lettered
   jobs). Handlers are envelope-tolerant: unknown event types skip,
   malformed known envelopes dead-letter with safe codes.
5. **Producer emissions** — additive same-transaction outbox writes in the
   merged modules: `mission.ready` (T13 today-mission creation),
   `ingestion.verification_required` (T09 extraction finish with pending
   requests), `ingestion.learning_path_committed` (T09 commit),
   `privacy.export_ready` (T20 export completion). Deletion completions are
   intentionally never notified. `reward.granted` is reserved for T15 and
   exercised with synthetic fixtures only.

**Mobile** (`lib/src/features/notifications/`):

6. **One notification gateway** (TRD §5.1) — `NotificationGateway`
   interface with `FirebaseNotificationGateway` (lazy, fail-safe init that
   degrades to `unavailable` without platform configuration) and a
   programmable fake for tests. CI builds and tests need no Firebase
   configuration.
7. **Token registration** — permission requested once per installation,
   token registered through the existing idempotent `registerDevice`
   operation with a stable installation id and a stable idempotency key per
   installation+token; token rotation re-registers. A failed registration
   exposes a non-blocking Retry action. Ordinary sign-out revokes the device
   before the session and invalidates the local FCM token if the server is
   unavailable. Logs contain a safe failure class only; denial never blocks use.
8. **Deep-link validation and consume-once** — payloads parse into typed
   intents (registry-mismatched route intents or localization keys are
   rejected), consumed IDs are checked before expiry, and each intent is
   recorded in a durable bounded ledger (survives process recreation,
   trimmed at 200 entries), and every mission/verification/learning-path/
   privacy target is validated through its existing GET endpoint before
   navigation (API §16.3). Wrong-owner (404), invalid workflow state and
   network-unavailable results resolve to the Flow §13.1 stable parent with
   a brief explanation. Signed-out taps hand the destination to the router's
   guard chain, which captures an allowlisted one-time return location
   (T07 pattern); the intent is consumed only after post-auth validation.
9. **Foreground notices** — a non-blocking banner above the navigator with
   contextual copy rendered from localization keys (UI/UX §9.21), polite
   live-region announcement, 6-second readable duration, tap = consume +
   navigate, dismiss = state unchanged. Notices arriving while a mission
   item, feedback, explanation or quiz route is active queue and surface
   only after the route leaves the answer surface (D11).
   The MVP's fixed Physics subject appears in learning notification copy even
   in the parameter-free minimal band; privacy export copy remains account-wide.

## 2. Decisions and why

| # | Decision | Why |
| --- | --- | --- |
| D1 | Notification module owns jobs + delivery results; preferences stay in identity, read via a narrow owner-scoped SELECT | TRD §3.2 module ownership; avoids a shared-contract change to T17 code |
| D2 | Zero new backend runtime deps; FCM via PyJWT[crypto] + stdlib transport behind a config allowlist | AGENTS §5 dependency rule; T11 precedent; adapter contract tests keep unbounded provider behaviour out |
| D3 | Closed payload allowlist with detail bands; builder rejects unknown keys | API §16.2; PRD 031; the acceptance gate demands "no sensitive detail" — the builder makes leaks unrepresentable |
| D4 | Append-only `notification_deliveries` + SECURITY DEFINER worker functions | Schema §13.3, §16.2; migration 0004 removed direct worker DML; T09/T11 pattern keeps the boundary identical |
| D5 | Enforcement order expiry → enabled → category → cap → quiet → consume-once | PRD 032; cheapest checks first; the preferred window is the PRD's "user-configured exception" |
| D6 | Six trigger event types; four emitted by merged modules this task, one reserved for T15 | Flow §13.1 coverage; same-transaction outbox discipline (Schema §13.2); T11 D9 precedent for producer envelopes — reviewer acknowledgement requested |
| D7 | Push never authoritative; client validates merged resources via existing GETs | API §16.3; reward-grant validation awaits T15 |
| D8 | Question surfaces unreachable from deep links | Flow §13.1; UI/UX §9.21 "tapping a mission notification deep-links to its preview, not directly into a timed question" |
| D9 | Durable bounded consume-once ledger keyed by payload notification id | Flow §20.3 "consumed deep link is not replayed"; survives process recreation; server-side dedupe is the authoritative counterpart |
| D10 | Fallbacks follow Flow §13.1 exactly; signed-out taps use the T07 safe-return hand-off | Reuse of the existing guard chain; no parallel auth logic |
| D11 | Foreground notices suppressed/queued on active-answer routes | Task gate "active answers are not interrupted" |
| D12 | Firebase platform config comes from the designated non-production test project; gateway degrades to `unavailable` without it | TRD §5.1 one adapter; AGENTS §6-7; keeps CI green before the human attaches the project |
| D13 | No learning text, answers, tokens, push tokens or auth headers in logs; captured-handler and redaction tests prove it | API §19; AGENTS §7 |
| D14 | Zero public API surface change; OpenAPI check stays green | Devices/preferences endpoints already exist; deep-link validation reuses read operations |

## 3. Specification map

| Requirement | Where implemented |
| --- | --- |
| PRD 031 lock-screen detail + user control | `payload.py` bands; preferences honored in `service.py`; category flags in `notification_preferences` |
| PRD 032 quiet hours/caps | `service.py` enforcement order; `notification_deliveries` counting |
| Flow §13.1 intent→destination→fallback | `notifications/constants.py` (backend), `deep_link_registry.dart` (mobile) |
| Flow §13.2 foreground non-interruption | `foreground_notice.dart` suppression + queueing |
| Flow §20.3 consumed-link replay refusal | `consumed_intent_ledger.dart` + coordinator tests |
| API §16.1 registration/prefs | existing `/v1/devices` + preferences consumed; no new routes |
| API §16.2 closed payload | `payload.py` + `notification_intent.dart` (mobile-side mirror) |
| API §16.3 client validation before navigation | `deep_link_coordinator.dart` + `deep_link_validation_api.dart` |
| Schema §13.2-13.3, §14.2 | trigger emissions in-transaction; job payloads IDs-only |
| TRD §3.2-3.3, §5.1, §16 | module boundary, narrow adapters, queue patterns |
| UI/UX §6.6, §9.21 | notice banner semantics; contextual copy templates |

## 4. Verification evidence (exact commands and results)

Backend (disposable `memora_test` database):

```text
ruff format backend / ruff check backend           -> clean
pytest backend/tests (no DB)                       -> 537 passed (pre-DB phase)
pytest backend/tests (MEMORA_TEST_DATABASE_URL)    -> 738 passed, 7 skipped (Commits 1-5 phase)
pytest backend/tests (final)                       -> 738 passed, 7 skipped
generate_contracts.py --check                      -> exit 0 (no OpenAPI drift)
```

Mobile:

```text
flutter pub get                                    -> resolved (firebase_core 5.1.x, firebase_messaging 17.x)
flutter analyze                                    -> 0 errors
flutter test                                       -> 650 passed (pre-notice phase), 650 passed (final)
```

The 7 backend skips are unrelated DB-gated suites requiring additional
disposable resources (pilot content fixtures). New T19 suites run fully:
`test_notification_payload` (18), `test_notification_providers` (12),
`test_notification_service` (24), `test_notification_worker` (11),
`test_notification_triggers` (4), and 42 mobile notification tests.

## 5. Gotchas learned (for future tasks)

- SQLAlchemy `text()` breaks on `:param::type` casts — use
  `CAST(:param AS type)` (T11 lesson, re-learned the hard way).
- `pg_advisory_xact_lock` has `bigint` single-arg and `int,int` two-arg
  forms only — hash to one bigint (`hashtextextended`).
- `INSERT ... ON CONFLICT (domain_event_key)` requires SELECT on the
  conflict-target column; the API role is intentionally INSERT-only on
  `outbox_events`, so producers use plain inserts with naturally-unique
  domain keys (attempt-scoped for re-runnable producers).
- `ALTER DEFAULT PRIVILEGES` in migration 0001 does not cover tables created
  by later migrations in fresh disposable databases — new tables must grant
  roles explicitly.
- Alembic's `fileConfig` in the test fixture disables pre-existing loggers
  (`disable_existing_loggers=True`) — re-enable the logger under test (see
  `test_memory_worker.py` and `test_notification_providers.py`).
- Riverpod disposes StateNotifierProviders itself; an extra
  `ref.onDispose(controller.dispose)` double-disposes and throws
  "use after dispose".
- Shared disposable test databases persist rows between runs — scope
  assertions (counts by user/type), never assert absolute totals, and clean
  up this task's own jobs (`background_jobs`) after each test;
  `outbox_events` is append-only and cannot be cleaned.

## 6. Open questions for reviewers

1. **Shared-surface acknowledgement** (D4/D6): new outbox event types
   `mission.ready`, `ingestion.verification_required`,
   `ingestion.learning_path_committed`, `privacy.export_ready` and the
   `notification_deliveries` table + SECURITY DEFINER grants in migration
   `20261111_0015`.
2. **Cross-module reads** (D1): the notifications module reads
   `notification_preferences` and `device_registrations` through its own
   owner-scoped SELECTs (as `memora_api` with `memora.user_id` set) instead
   of importing identity persistence code.
3. **Verification event re-emission**: re-extraction of a previously
   verified update emits a fresh `ingestion.verification_required` event
   (attempt-scoped domain key). Dispatch dedupe keeps pushes consume-once
   per update — confirm this is the desired product behaviour versus
   suppressing repeat verification pushes entirely.
4. **Reminder cap scope**: `max_daily_reminders` counts `mission_ready` +
   `due_memories` deliveries per user-local day; workflow signals are not
   capped. Confirm the PRD 032 reading.
5. **T15 follow-up**: `reward.granted` producer and the reef-detail
   destination and ownership/state validation. The owner chose to wait for
   T15 on 14 November 2026, so T19 remains in Review without an exception.

## 7. Follow-ups

- `docs/evidence/T19_Push_Evidence.md` — Android/iOS device integration
  evidence and safe-fallback screenshots after the test Firebase project is
  attached (human-run, checklist in the evidence document).
- T15 owns the reward producer; T26 owns cross-feature deep-link E2E; T23
  adds circuit breakers and alerting for notification routes.
