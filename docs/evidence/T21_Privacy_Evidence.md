# T21 Privacy Mobile Evidence

## Scope

This record covers the T21 student-facing privacy experience built on the T20
privacy API:

- Retained-data overview reached from Profile.
- Export request, authoritative status, polling, expiry and external download.
- Deletion explanation, explicit confirmation, status and permitted
  cancellation.
- Recent-authentication recovery for export and deletion creation.
- Truthful pending, failed, cancelled, completed, proof-missing and
  outcome-unconfirmed states.
- Offline mutation disabling with a visible reason.
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
| Privacy hub | [Profile.png](../screens/Profile.png) | [privacy_overview.png](../../mobile/test/privacy/goldens/t21/privacy_overview.png) | Hub is a dedicated privacy destination, not a Profile section; it states the recent sign-in requirement before either workflow starts. |
| Privacy hub offline | [Profile.png](../screens/Profile.png) | [privacy_overview_offline.png](../../mobile/test/privacy/goldens/t21/privacy_overview_offline.png) | Offline banner disables mutations with a stated reason and a labelled retry action; last-known status is not fabricated. |
| Export introduction | [Profile.png](../screens/Profile.png) | [privacy_export_intro.png](../../mobile/test/privacy/goldens/t21/privacy_export_intro.png) | Explains what the export contains and the recent sign-in requirement before the destructive-adjacent action. |
| Completed export | [Profile.png](../screens/Profile.png) | [privacy_export_completed.png](../../mobile/test/privacy/goldens/t21/privacy_export_completed.png) | Download appears only while the server-supplied signed URL is present and unexpired; the URL is never rendered as text or persisted. |
| Deletion explanation | [Profile.png](../screens/Profile.png) | [privacy_delete_intro.png](../../mobile/test/privacy/goldens/t21/privacy_delete_intro.png) | Requires an explicit confirmation checkbox and a second destructive dialog; no completion is claimed before server proof. |
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
| 320 px width and 200% text | `privacy_accessibility_test.dart` covers hub, offline hub, export introduction, pending/completed/failed export, deletion explanation, pending/processing/completed/proof-missing deletion, unconfirmed outcome and reauthentication form at 320 × 640 with `TextScaler.linear(2.0)`. |
| Semantics | Tests assert the back-action label, status-chip label, pending progress label, validation live-region text and labelled offline retry action. |
| Focus order | Reauthentication declares `NumericFocusOrder` 1–4 and the email → password traversal is exercised with the keyboard. |
| Reduced motion | Privacy screens add no custom motion; the accessibility harness runs with `disableAnimations: true`, and every state remains usable without animation. |
| Overflow | The shared status-card header uses `Wrap`, and the privacy scaffold top-aligns short content after the 200% text matrix exposed and fixed a real overflow and centering defect. |

## Widget and controller coverage

- `privacy_repository_test.dart` covers DTO mapping, authorization and
  idempotency headers, safe errors, URL rules and deletion proofs.
- `privacy_controller_test.dart` covers create, status, polling, cancellation,
  recent authentication, session expiry, offline handling, idempotency-key
  reuse, bootstrap pending resolution and confirmed clearing.
- `privacy_screens_test.dart` covers the hub, export request/poll/download
  expiry, deletion confirmation and cancellation, proof-missing completion,
  confirmed clearing, unconfirmed expiry, reauthentication email/Google/cancel,
  a second recent-auth rejection and the Profile entry.
- `route_guard_test.dart` and `router_guards_matrix_test.dart` cover the
  deletion-pending status exception and the account-recovery action.
- `privacy_download_launcher_test.dart` and `privacy_reachability_test.dart`
  cover external URL rules and the health-based reachability probe.

## Security and privacy notes

- Download URLs are opened externally with `url_launcher`; they are never
  logged, rendered or persisted. Only `https` is accepted, with loopback `http`
  permitted in the local environment.
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

## Local verification record

| Command | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test` | Pass; 114 files, 0 changed |
| `flutter analyze` | Pass; no issues found |
| `flutter test test/auth test/privacy` | Pass; 248 tests |
| `flutter test` | Pass; 333 tests |
| `flutter test test/privacy/t21_visual_evidence_test.dart` | Pass; seven golden comparisons |
| `flutter build apk --debug` | Pass; built `build/app/outputs/flutter-apk/app-debug.apk` |
| `.venv/Scripts/python.exe tools/contracts/generate_contracts.py --check` | Pass; OpenAPI and generated Dart client are drift-clean |

## Outstanding verification

T21 remains in **Review**. The following acceptance evidence is not yet
recorded and must be completed before the task can be marked Done:

- Exercise the flows against the real T20 backend and durable deletion worker,
  including recent-auth rejection, export completion with a live signed URL,
  deletion completion with proofs, cancellation and proof-missing behavior.
- Record Android device or emulator TalkBack, keyboard/switch, reduced-motion
  and 320 px / 200% text manual results for the privacy routes.
- Capture the successful required CI run on the pull request after the branch is
  pushed.

The checked-in golden captures are Windows evidence and do not replace the
Android manual record. No push, merge, tag, deployment or Done status is claimed
by this record.
