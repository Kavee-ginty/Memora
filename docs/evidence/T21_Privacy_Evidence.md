# T21 Privacy Mobile Evidence

## Scope

This record covers the T21 student-facing privacy experience built on the T20
privacy API:

- Retained-data overview reached from Profile, naming retained categories and
  separating temporary uploads from verified learning knowledge.
- Export request, authoritative status, polling, non-null server expiry and
  external download.
- Deletion explanation, explicit confirmation, status and permitted
  cancellation.
- Recent-authentication recovery for export and deletion creation.
- Truthful pending, failed, cancelled, completed, proof-missing and
  outcome-unconfirmed states.
- Offline navigation and mutation disabling with a visible reason.
- Local account and session clearing only after a server-confirmed deletion with
  proof state.

T18 profile preferences, T19 push/deep-link consumption, T22 durable offline
reconciliation, T15 progress projections and all backend, OpenAPI, migration and
generated-client changes remain outside this task.

## Visual comparison

No privacy-specific source PNG exists. The approved composition is spec-derived
from `Profile.png`, UI/UX 9.20 and Flow 12/14. Captures use a 402 × 1001 canvas
matching the retained PNG canvas and contain synthetic data only.

| State | Retained source | Reproducible implementation capture | Intentional specification-driven difference |
| --- | --- | --- | --- |
| Privacy hub | [Profile.png](../screens/Profile.png) | [privacy_overview.png](../../mobile/test/privacy/goldens/t21/privacy_overview.png) | Hub is a dedicated privacy destination, not a Profile section; it states the recent sign-in requirement before either workflow starts and names retained categories in a `What Memora keeps` card. |
| Privacy hub offline | [Profile.png](../screens/Profile.png) | [privacy_overview_offline.png](../../mobile/test/privacy/goldens/t21/privacy_overview_offline.png) | Offline banner disables workflow navigation and mutations with a stated reason and a labelled retry action; last-known status is not fabricated. |
| Export introduction | [Profile.png](../screens/Profile.png) | [privacy_export_intro.png](../../mobile/test/privacy/goldens/t21/privacy_export_intro.png) | Explains what the export contains and the recent sign-in requirement before the destructive-adjacent action. |
| Completed export | [Profile.png](../screens/Profile.png) | [privacy_export_completed.png](../../mobile/test/privacy/goldens/t21/privacy_export_completed.png) | Download appears only when the status is completed, a signed URL is present, and the server-supplied expiry is non-null and in the future; the URL is never rendered as text or persisted. |
| Deletion explanation | [Profile.png](../screens/Profile.png) | [privacy_delete_intro.png](../../mobile/test/privacy/goldens/t21/privacy_delete_intro.png) | Separates temporary uploaded files from verified retained knowledge, requires an explicit confirmation checkbox and a second destructive dialog, and claims no completion before server proof. |
| Verified deletion | [Profile.png](../screens/Profile.png) | [privacy_deletion_completed.png](../../mobile/test/privacy/goldens/t21/privacy_deletion_completed.png) | Completion is shown only with `completed` plus non-empty verification proofs; retention exceptions are listed separately. |
| Reauthentication recovery | [Profile.png](../screens/Profile.png) | [privacy_reauth.png](../../mobile/test/privacy/goldens/t21/privacy_reauth.png) | Email/password and “Continue with Google” confirm the pending action without re-bootstrapping the session. |

Regenerate and compare the captures on Windows because Flutter text
rasterization is platform-specific:

```powershell
cd mobile
flutter test --update-goldens test/privacy/t21_visual_evidence_test.dart
flutter test test/privacy/t21_visual_evidence_test.dart
```

## Automated accessibility and responsive evidence

| Requirement | Evidence |
| --- | --- |
| 320 px width and 200% text | `privacy_accessibility_test.dart` covers the hub with its retained-data card, offline hub with disabled workflow actions, export introduction, pending/completed/failed export, export without a server expiry, deletion explanation, pending/processing/completed/proof-missing deletion, unconfirmed outcome and reauthentication form at 320 × 640 with `TextScaler.linear(2.0)`. |
| Semantics | Tests assert the back-action label, status-chip label, pending progress label, validation live-region text, labelled offline retry action and disabled workflow actions while offline. |
| Focus order | Reauthentication declares `NumericFocusOrder` 1–4 and the email → password traversal is exercised with the keyboard. |
| Reduced motion | Privacy screens add no custom motion; the accessibility harness runs with `disableAnimations: true`, and every state remains usable without animation. |
| Overflow | The shared status-card header uses `Wrap`, and the privacy scaffold top-aligns short content after the 200% text matrix exposed and fixed a real overflow and centering defect. |

## Widget and controller coverage

- `privacy_repository_test.dart` covers DTO mapping, authorization and
  idempotency headers, safe errors, URL rules, missing-expiry mapping and
  deletion proofs.
- `privacy_controller_test.dart` covers create, status, polling, cancellation,
  recent authentication, session expiry, offline handling, idempotency-key
  reuse, bootstrap pending resolution, pending-summary upsert/clear, retry-guard
  reset, expiry gating and confirmed clearing.
- `privacy_screens_test.dart` covers the retained-data hub, offline-disabled
  navigation and mutations, reconnection retry for export and deletion creation,
  deletion-status offline retry, export request/poll/download expiry, a
  completed export without an expiry, deletion confirmation and cancellation,
  proof-missing completion, confirmed clearing, unconfirmed expiry,
  reauthentication email/Google/offline/cancel, a second recent-auth rejection
  and the Profile entry.
- `session_controller_test.dart` covers local privacy-summary refresh and clear
  without changing account status.
- `route_guard_test.dart` and `router_guards_matrix_test.dart` cover the
  deletion-pending status exception and the account-recovery action.
- `privacy_download_launcher_test.dart` and `privacy_reachability_test.dart`
  cover external URL rules and the health-based reachability probe.

## Security and privacy notes

- Download URLs are opened externally with `url_launcher`; they are never
  logged, rendered or persisted. Only `https` is accepted, with loopback `http`
  permitted in the local environment. A completed export without a non-null
  future server expiry is explained and never offered or opened.
- Ownership comes from the validated session; the client never sends a
  `user_id`.
- No credential, token, signed URL or production data appears in code, tests,
  captures or this record.
- Deletion completion clears local credentials only for `completed` with
  non-empty proofs. A proof-missing or 401 outcome never claims completion and
  never clears credentials.
- Export session expiry uses the normal session-expiry path; deletion session
  expiry shows an outcome-unconfirmed state with the request ID and a manual
  sign-out.

## Review corrections

The final local audit added these corrections inside the T21 boundary:

- A completed export is downloadable only with a signed URL and a non-null
  server expiry in the future. A missing expiry is distinguished from an
  expired URL, is explained to the student, and never opens a launcher.
- Created exports are upserted into the local pending summary so the hub can
  discover them, and terminal exports are removed from that summary. This is a
  local projection only; completion still comes from the server.
- A retry that fails for a reason other than recent authentication resets the
  recent-auth retry guard, so a later legitimate recent-auth rejection can still
  open recovery.
- The hub names retained-data categories and separates temporary uploads from
  verified learning knowledge. Pending bootstrap summaries are described as
  last reported rather than live.
- Offline mode disables hub workflow navigation, export request/refresh/download
  and retry, deletion confirmation/refresh/cancel/retry, and reauthentication
  submission, while retaining the visible reason and labelled retry.
- Contextual retry on the export and deletion screens retries the failed
  creation instead of only rechecking reachability, including after a network
  failure once the liveness probe recovers. The deletion-status offline retry
  now rechecks reachability instead of calling a load that short-circuits
  offline.

## Local verification record

Final local checks after the review corrections and golden regeneration:

| Command | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test` | Pass; 114 files, 0 changed |
| `flutter analyze` | Pass; no issues found |
| `flutter test test/auth test/privacy` | Pass; 260 tests |
| `flutter test` | Pass; 345 tests |
| `flutter test test/privacy/t21_visual_evidence_test.dart` | Pass; seven golden comparisons |
| `flutter build apk --debug` | Pass; built `build/app/outputs/flutter-apk/app-debug.apk` |
| `.venv/Scripts/python.exe tools/contracts/generate_contracts.py --check` | Pass; OpenAPI and generated Dart client are drift-clean |

### Revalidation after merging current `develop`

| Command | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test` | Pass; 148 files, 0 changed |
| `flutter analyze` | Pass; no issues found |
| `flutter test` | Pass; all 602 mobile tests, including T21 privacy and merged T10 ingestion coverage |
| `flutter build apk --debug` | Not completed locally; Gradle failed before compilation with `Unable to establish loopback connection` on this Windows host |

The required GitHub run for the pre-merge PR commit passed format/analyze/tests,
contract drift, migrations, compose validation and secret/dependency scans. The
backend container and Flutter APK jobs built their outputs but failed while
uploading them because the repository's GitHub Actions artifact storage quota
was exhausted. A fresh required run is still needed for the merged branch.

## Outstanding verification

T21 remains in **Review**. The following acceptance evidence is not yet
recorded and must be completed before the task can be marked Done:

- Exercise the flows against the real T20 backend and durable deletion worker,
  including recent-auth rejection, export completion with a live signed URL,
  deletion completion with proofs, cancellation and proof-missing behavior.
- Record Android device or emulator TalkBack, keyboard/switch, reduced-motion
  and 320 px / 200% text manual results for the privacy routes.
- Capture a successful required CI run on the updated pull request.

The local Docker engine is unavailable and there is no local `.env`, so the real
T20 API/worker exercise could not run here. Flutter lists an Android emulator
image but no connected Android device; the local APK build is also blocked by
Gradle's loopback error. The checked-in Windows golden captures do not replace
the Android manual record. T21 remains in **Review** until those items pass.
