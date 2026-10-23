# Memora mobile

The mobile client uses Flutter 3.47.5, Riverpod and `go_router`. This T01 baseline contains only the app shell and placeholder Home route; feature screens belong to their CPM tasks.

The Android and iOS host projects are generated and versioned with the application. Install Flutter 3.47.5. On Windows, keep the Android SDK and `PUB_CACHE` in paths without spaces; install NDK `28.2.13676358` from Android Studio's SDK Manager.

Then run:

```powershell
cd mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

If your Windows user directory contains spaces, set a persistent package cache before `flutter pub get`:

```powershell
$env:PUB_CACHE = 'D:\FlutterPubCache'
[Environment]::SetEnvironmentVariable('PUB_CACHE', 'D:\FlutterPubCache', 'User')
```
