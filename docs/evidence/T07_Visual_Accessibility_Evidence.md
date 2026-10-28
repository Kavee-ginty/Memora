# T07 Visual and Accessibility Evidence

## Scope

This record covers T07 splash/onboarding/authentication, bootstrap-backed Home,
responsive behavior, reduced motion, focus, and semantics. The implementation
captures use the same 402 × 1001 canvas as the approved source PNGs and contain
only synthetic test data.

## Visual comparison

| State | Approved source | Reproducible implementation capture | Intentional specification-driven difference |
| --- | --- | --- | --- |
| Onboarding step 1 | [Onboarding.png](../screens/Onboarding.png) | [onboarding_step_1.png](../../mobile/test/auth/goldens/t07/onboarding_step_1.png) | Exact UI/UX 9.2 copy replaces source wording; curve is explicitly illustrative. |
| Onboarding step 2 | [Onboarding-1.png](../screens/Onboarding-1.png) | [onboarding_step_2.png](../../mobile/test/auth/goldens/t07/onboarding_step_2.png) | The universal 24-hour promise is removed; timing is described as adaptive. |
| Onboarding step 3 | [Onboarding-3.png](../screens/Onboarding-3.png) | [onboarding_step_3.png](../../mobile/test/auth/goldens/t07/onboarding_step_3.png) | Exact UI/UX 9.4 reef/reward copy and final-step actions are authoritative. |
| Sign in | [Memora login.png](<../screens/Memora login.png>) | [sign_in.png](../../mobile/test/auth/goldens/t07/sign_in.png) | Persistent labels, password state semantics, recovery, validation summary, and Google authentication follow the Markdown specification. |
| Create account | [Memora login-1.png](<../screens/Memora login-1.png>) | [create_account.png](../../mobile/test/auth/goldens/t07/create_account.png) | No age field is shown until product/legal policy is approved; password requirements are visible before submission. |
| Home setup state | [Home.png](../screens/Home.png) | [home_setup.png](../../mobile/test/auth/goldens/t07/home_setup.png) | T07 renders bootstrap-authoritative setup data only. Mission totals, XP, streak, due dates, and reef health are deferred to T15. |

Regenerate and compare the implementation captures from `mobile/`:

These checked-in evidence captures are compared on Windows because Flutter
text rasterization is platform-specific; behavior and accessibility tests
remain platform-independent and run in CI.

```powershell
flutter test --update-goldens test/auth/t07_visual_evidence_test.dart
flutter test test/auth/t07_visual_evidence_test.dart
```

## Automated accessibility and responsive evidence

| Requirement | Evidence |
| --- | --- |
| 320 px width and 200% text | `accessibility_auth_test.dart`, `accessibility_states_test.dart`, and `consent_review_test.dart` cover onboarding, sign-in, create-account, Home, consent, bootstrap failure, blocked account, expiry, validation, offline/error, and retry states. |
| Primary headings and semantics | Widget semantics assertions cover authentication headings, consent controls, password state, root tabs, errors, Retry, and Sign out. |
| Focus order and validation recovery | Traversal tests cover Sign In and Create Account. A failed multi-field submission moves focus to one focusable live-region summary. |
| Touch targets | Authentication button tests require at least 48 logical pixels. |
| Reduced motion | Route transitions become immediate and onboarding indicator animation duration becomes zero when `disableAnimations` is true. |
| Persistence and isolation | Storage/restoration tests cover corrupt records, incompatible values, return-location consumption, provider-session deletion, and cross-account isolation. |

## Manual evidence coverage

The configured Android device record below covers Google OAuth and callback,
successful bootstrap, active/signed-out/expired/revoked cold starts, core
TalkBack reading and focus order, validation-summary focus, and OS reduced
motion. No credentials, tokens, user data, or provider payloads were recorded.

The tester ended additional manual TalkBack walkthroughs after the core root
and authentication paths passed. Consent, blocked, retry, error, keyboard-focus,
and focus-restoration states remain covered by the automated semantics,
responsive, and traversal tests listed above.

## Device evidence recorded

| Date | Device | Check | Result |
| --- | --- | --- | --- |
| 2026-10-28 | Android 17 / API 37 emulator | Google OAuth and app callback | Pass; provider authentication returned through `com.kaveeginty.memora://login-callback` without exposing credentials or tokens. |
| 2026-10-28 | Android 17 / API 37 emulator | Authenticated session bootstrap | Pass; the generated bootstrap request returned 200 and routed to the required consent destination. |
| 2026-10-28 | Android 17 / API 37 emulator | Consent retrieval | Pass; the generated consent read returned 200 and rendered the device Consent screen. |
| 2026-10-28 | Samsung Galaxy S24 Ultra / Android 16 (API 36) | Google OAuth, app callback, and authenticated bootstrap | Pass; sign-in returned to the app, the backend accepted the provider token with bounded clock-skew handling, and the app loaded successfully. No credentials, tokens, or provider payloads were recorded. |
| 2026-10-28 | Samsung Galaxy S24 Ultra / Android 16 (API 36) | Active-session cold start | Pass; after an OS force stop, Memora restored the provider session, completed a fresh bootstrap, and reached Home without showing Google login, crashing, or flashing private content before authorization completed. |
| 2026-10-28 | Samsung Galaxy S24 Ultra / Android 16 (API 36) with TalkBack | Home and root-navigation reading/focus order | Pass; Home content and all four root tabs were announced in logical order, selected states were exposed, and focus had no duplicate, missing, confusing, out-of-order, or trapped stops. |
| 2026-10-28 | Samsung Galaxy S24 Ultra / Android 16 (API 36) with TalkBack | Sign-out dialog and sign-in validation | Pass; dialog focus remained contained, sign-in controls were announced in logical order, empty submission moved focus to the announced validation summary, and no missing, duplicate, or confusing stops were observed. |
| 2026-10-28 | Samsung Galaxy S24 Ultra / Android 16 (API 36) | Signed-out cold start | Pass; after an OS force stop, Memora remained signed out and opened the onboarding flow without launching Google login, restoring validation errors, or flashing Home/private content. The tester then navigated to Welcome back. |
| 2026-10-28 | Samsung Galaxy S24 Ultra / Android 16 (API 36) with TalkBack | Create-account reading order and validation | Pass; labels, password visibility states, action order, validation-summary focus, individual errors, and return-to-sign-in navigation were announced and reachable without trapped or confusing focus. |
| 2026-10-28 | Samsung Galaxy S24 Ultra / Android 16 (API 36), OS reduced motion enabled | Splash/onboarding/authentication transitions | Pass; route changes and onboarding indicators respected the OS motion preference while content, controls, back navigation, and loading states remained usable without flashing or interaction traps. |
| 2026-10-28 | Samsung Galaxy S24 Ultra / Android 16 (API 36) | Expired-session cold start | Pass; a local standard `token_expired` bootstrap response caused one refresh/replay boundary, cleared the provider session, withheld Home/private content, and displayed “Your session expired. Sign in again to continue.” The simulator was then removed and normal API routing restored. |
| 2026-10-28 | Samsung Galaxy S24 Ultra / Android 16 (API 36) | Revoked-session cold start | Pass; the current Supabase test session was revoked, the protected bootstrap was rejected, and Memora displayed the session-expired recovery state without crashing or exposing Home/private content. Normal API routing was restored immediately afterward. |

## Local verification record

| Command | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test` | Pass; 95 files, 0 changed |
| `flutter analyze` | Pass; no issues found |
| `flutter test` | Pass; 221 tests |
| `flutter test test/auth/t07_visual_evidence_test.dart` | Pass; six golden comparisons |
| `backend/.venv/Scripts/python.exe tools/contracts/generate_contracts.py --check` | Pass; OpenAPI and generated Dart client are drift-clean |
| `backend/.venv/Scripts/python.exe -m pytest backend/tests/test_identity.py -q` | Pass; 13 identity tests, including bounded issuer clock skew and strict expiry coverage |
| `backend/.venv/Scripts/python.exe -m ruff check backend/src/memora/api/security.py backend/tests/test_identity.py` | Pass; no issues found |
| `backend/.venv/Scripts/python.exe -m ruff format --check backend/src/memora/api/security.py backend/tests/test_identity.py` | Pass; both files already formatted |
| `flutter build apk --debug` | Pass; built `build/app/outputs/flutter-apk/app-debug.apk` |

The successful build was rerun from a normal PowerShell session after Codex's
host process encountered a local Gradle loopback-connection failure.
