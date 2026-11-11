# T18 Profile and settings evidence

The mobile feature covers Profile, Edit Profile, Notifications, and Accessibility and mission settings. Profile uses the signed-in identity and the authorized A/L Physics learning path. The existing Privacy entry and sign-out warning are still available.

## Visual evidence

The Profile and Notification references informed the soft blue surfaces, identity card, Edit Profile action, and four root destinations. The captures use synthetic account data and the current Flutter theme.

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
| Rendered states through the authenticated router and design system | `mobile/test/profile/t18_visual_evidence_test.dart` |

## Verification results

Windows verification used Flutter 3.47.5 and Dart 3.13.4.

| Command | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed .` | Passed |
| `flutter analyze --no-pub` | Passed |
| `flutter test --no-pub --coverage --reporter expanded` | 635 passed |
| `flutter build apk --debug --no-pub` | Failed during Gradle configuration. The required NDK `28.2.13676358` was missing, the SDK manager could not connect to its repository, and retrying the official archive download timed out. |
| `flutter devices` | Windows and Edge detected |

## Device verification

Use a synthetic account on Android to verify TalkBack and Switch Access, keyboard traversal, system font/display scaling, reduced motion, process restart, offline load/save, and rollback after a simulated save failure. Record the device, build, and outcomes alongside the widget results. Confirmed reduced motion and high contrast are applied in the app. Sound, haptics, and timer visibility persist for mission screens that consume those settings.
