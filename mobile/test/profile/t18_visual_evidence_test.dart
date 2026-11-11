@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/app.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/profile/application/profile_controller.dart';
import 'package:memora_mobile/src/features/profile/domain/profile_settings.dart';
import 'package:memora_mobile/src/routing/app_router.dart';
import 'package:memora_mobile/src/routing/app_routes.dart';

import 'profile_fixtures.dart';

const _capture = Key('t18_capture');

Future<void> _loadFonts() async {
  for (final family in ['Exo', 'Inter']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family-400.ttf'))).load();
  }
  var directory = File(Platform.resolvedExecutable).parent;
  while (!directory.path.toLowerCase().endsWith(
    '${Platform.pathSeparator}cache',
  )) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Flutter cache not found');
    }
    directory = parent;
  }
  final icons = Directory('${directory.path}/artifacts/material_fonts')
      .listSync()
      .whereType<File>()
      .firstWhere(
        (file) => file.path.toLowerCase().endsWith('materialicons-regular.otf'),
      );
  final bytes = await icons.readAsBytes();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);

  const captures = [
    (
      name: 'profile',
      path: AppRoutes.profile,
      width: 402.0,
      scale: 1.0,
      rollback: false,
    ),
    (
      name: 'edit_profile',
      path: AppRoutes.editProfile,
      width: 402.0,
      scale: 1.0,
      rollback: false,
    ),
    (
      name: 'notifications',
      path: AppRoutes.profileNotifications,
      width: 402.0,
      scale: 1.0,
      rollback: false,
    ),
    (
      name: 'accessibility',
      path: AppRoutes.profileAccessibility,
      width: 402.0,
      scale: 1.0,
      rollback: false,
    ),
    (
      name: 'rollback',
      path: AppRoutes.profileAccessibility,
      width: 402.0,
      scale: 1.0,
      rollback: true,
    ),
    (
      name: 'profile_320',
      path: AppRoutes.profile,
      width: 320.0,
      scale: 1.0,
      rollback: false,
    ),
    (
      name: 'accessibility_200_percent',
      path: AppRoutes.profileAccessibility,
      width: 320.0,
      scale: 2.0,
      rollback: false,
    ),
  ];

  for (final capture in captures) {
    testWidgets('T18 visual evidence ${capture.name}', (tester) async {
      await tester.binding.setSurfaceSize(Size(capture.width, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = AppLocalStorage(InMemorySecureKeyStore());
      final repository = FakeProfileRepository();
      final container = ProviderContainer(
        overrides: [
          appLocalStorageProvider.overrideWithValue(store),
          profileRepositoryProvider.overrideWithValue(repository),
          sessionControllerProvider.overrideWith(
            (ref) => SessionController(
              authRepository: MockAuthRepository(),
              sessionRepository: MockSessionRepository(),
              localStorage: store,
              initialState: signedIn(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(capture.width, 950),
              textScaler: TextScaler.linear(capture.scale),
              disableAnimations: true,
            ),
            child: RepaintBoundary(
              key: _capture,
              child: MemoraApp(router: router),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      router.go(capture.path);
      await tester.pumpAndSettle();
      if (capture.rollback) {
        repository.saveFailure = const ProfileFailure(
          'network_error',
          'Offline',
          retryable: true,
        );
        await tester.tap(find.widgetWithText(SwitchListTile, 'Reduced motion'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save changes'));
        await tester.pumpAndSettle();
        expect(find.textContaining('You may be offline'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(_capture),
        matchesGoldenFile('goldens/t18/${capture.name}.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
