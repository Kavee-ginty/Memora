import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/privacy/data/privacy_download_launcher.dart';

void main() {
  group('UrlLauncherPrivacyDownloadLauncher', () {
    test('opens an HTTPS export URL externally', () async {
      Uri? opened;
      final launcher = UrlLauncherPrivacyDownloadLauncher(
        launch: (uri) async {
          opened = uri;
          return true;
        },
      );

      final uri = Uri.parse('https://cdn.memora.example/export?token=signed');
      await launcher.openExternal(uri);

      expect(opened, uri);
    });

    test('reports a launch refusal as unavailable', () async {
      final launcher = UrlLauncherPrivacyDownloadLauncher(
        launch: (uri) async => false,
      );

      await expectLater(
        launcher.openExternal(Uri.parse('https://cdn.memora.example/export')),
        throwsA(isA<PrivacyDownloadUnavailable>()),
      );
    });

    test('reports a platform exception as unavailable', () async {
      final launcher = UrlLauncherPrivacyDownloadLauncher(
        launch: (uri) async => throw StateError('platform failure'),
      );

      await expectLater(
        launcher.openExternal(Uri.parse('https://cdn.memora.example/export')),
        throwsA(isA<PrivacyDownloadUnavailable>()),
      );
    });

    test('rejects HTTP loopback unless local development is allowed', () async {
      var calls = 0;
      final launcher = UrlLauncherPrivacyDownloadLauncher(
        launch: (uri) async {
          calls++;
          return true;
        },
      );

      await expectLater(
        launcher.openExternal(
          Uri.parse('http://127.0.0.1:8000/v1/privacy/export'),
        ),
        throwsA(isA<PrivacyDownloadUnavailable>()),
      );
      expect(calls, 0);
    });

    test('allows loopback HTTP only when explicitly enabled', () async {
      Uri? opened;
      final launcher = UrlLauncherPrivacyDownloadLauncher(
        allowLocalHttp: true,
        launch: (uri) async {
          opened = uri;
          return true;
        },
      );

      final uri = Uri.parse('http://localhost:8000/v1/privacy/export');
      await launcher.openExternal(uri);

      expect(opened, uri);
    });

    test('never allows non-loopback HTTP even in local mode', () async {
      final launcher = UrlLauncherPrivacyDownloadLauncher(
        allowLocalHttp: true,
        launch: (uri) async => true,
      );

      await expectLater(
        launcher.openExternal(
          Uri.parse('http://192.168.1.10:8000/v1/privacy/export'),
        ),
        throwsA(isA<PrivacyDownloadUnavailable>()),
      );
    });

    test('rejects non-HTTP schemes', () async {
      final launcher = UrlLauncherPrivacyDownloadLauncher(
        allowLocalHttp: true,
        launch: (uri) async => true,
      );

      await expectLater(
        launcher.openExternal(Uri.parse('javascript:alert(1)')),
        throwsA(isA<PrivacyDownloadUnavailable>()),
      );
    });
  });
}
