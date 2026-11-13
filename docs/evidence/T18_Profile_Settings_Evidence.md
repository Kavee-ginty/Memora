# T18 Profile and settings evidence

The mobile feature covers Profile, Edit Profile, Notifications, and Accessibility and mission settings. Profile uses the signed-in identity and the authorized A/L Physics learning path. The existing Privacy entry and sign-out warning are still available.

## Visual evidence

The Profile and Notification references informed the soft blue surfaces, identity card, Edit Profile action, and four root destinations. The captures use synthetic account data and the current Flutter theme.

The seven captures were reviewed against the retained references. The Profile composition keeps the identity card, prominent Edit Profile action, and selected Profile tab. The learning entry uses the authorized Physics subject and leaves progress metrics in Progress under UI/UX §9.20. `Notification.png` depicts a push message. The T18 capture shows notification preferences under §9.21. At narrow widths, the root tabs reflow to preserve their labels. The Windows golden comparisons passed. Repository-owner visual approval is pending.

| State | Capture |
| --- | --- |
| Profile | [Profile](../../mobile/test/profile/goldens/t18/profile.png) |
| Edit Profile | [Edit Profile](../../mobile/test/profile/goldens/t18/edit_profile.png) |
| Notifications | [Notifications](../../mobile/test/profile/goldens/t18/notifications.png) |
| Accessibility and mission settings | [Accessibility](../../mobile/test/profile/goldens/t18/accessibility.png) |
| Failed save and rollback | [Rollback](../../mobile/test/profile/goldens/t18/rollback.png) |
| 320 logical pixels | [Narrow Profile](../../mobile/test/profile/goldens/t18/profile_320.png) |
| 320 logical pixels and 200% text | [Large-text accessibility](../../mobile/test/profile/goldens/t18/accessibility_200_percent.png) |

Regenerate the screenshots on Windows with Flutter 3.47.5.

```powershell
Set-Location mobile
flutter test --update-goldens test/profile/t18_visual_evidence_test.dart
flutter test test/profile --reporter expanded
```

## Automated evidence

| Requirement | Test |
| --- | --- |
| Authorized reads and versioned PATCH requests, explicit null for paired fields, safe error mapping, and replay after a single auth refresh | `mobile/test/profile/profile_repository_test.dart` |
| Account-scoped restore, offline use, corrupt cache cleanup, sign-out, expiry, version conflict, retry, rollback, and concurrent account checks | `mobile/test/profile/profile_controller_test.dart` |
| 320 px at 200% text, keyboard traversal, validation announcements, switch semantics, reduced motion, and visible conflict/rollback recovery | `mobile/test/profile/profile_screens_test.dart` |
| Real router, generated client, Dio serialization, simulated API, and the production settings cache through save, same-key replay after a lost response, conflict reconciliation, offline restart, and rollback | `mobile/test/profile/profile_integration_test.dart` |
| Rendered states through the authenticated router and design system | `mobile/test/profile/t18_visual_evidence_test.dart` |

Tapping the selected Profile tab preserves a dirty form. Back still prompts before discarding edits. Editing after a failed save removes Retry for the old payload. Save changes submits the edited payload with a fresh key. Reduced-motion previews keep the settings route mounted.

## Contrast measurements

The widget test reads the rendered text styles and the switch colors from the active theme. Ratios use WCAG relative luminance for the tested foreground/background pairs.

| UI pair | Standard | High contrast |
| --- | ---: | ---: |
| Profile Privacy title on the ocean card | 13.53:1 | 17.75:1 |
| Edit Profile input text on the ocean fill | 13.53:1 | 17.75:1 |
| Notifications text action on the soft surface | 6.95:1 | 19.88:1 |
| High-contrast switch thumb against its track | — | 21:1 |

## Verification results

Windows verification used Flutter 3.47.5 and Dart 3.13.4.

| Command | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed .` | Passed |
| `flutter analyze --no-pub` | Passed |
| `flutter test --no-pub --reporter expanded test/profile` | 35 passed, including seven Windows golden comparisons |
| `flutter test --no-pub --coverage --reporter expanded` | 637 passed |
| `python -m pytest backend/tests/test_api_contract_models.py backend/tests/test_openapi_contract.py backend/tests/test_openapi_artifact.py -q` | 63 passed |
| `python tools/contracts/generate_contracts.py --check` | Passed |
| `flutter devices` | Android API 37 emulator, Windows, and Edge detected |

The previous Windows APK attempt at `89b9a94` failed because NDK `28.2.13676358` was unavailable. The [debug APK job for that commit](https://github.com/Kavee-ginty/Memora/actions/runs/43067639378/job/130686743342) passed. The Windows NDK was then installed from the checksum-verified Google archive.

On the updated branch, `flutter build apk --debug --no-pub` reached `:app:mergeDebugNativeLibs` and failed when the Windows system drive ran out of space.

## Device verification

Android API 37 x86_64 test emulator `Medium_Phone_API_37.0` booted with TalkBack and Switch Access installed. Confirmed reduced motion and high contrast are applied in the app. Sound, haptics, and timer visibility persist for mission screens that consume those settings.

## Open acceptance items

- Confirm the approved Profile support destination or an explicit deviation. The repository does not supply a support address.
- When T19 supplies platform permission status, exercise device-denied notifications with the server preference enabled. T18 explains that device permission is managed in system settings.
