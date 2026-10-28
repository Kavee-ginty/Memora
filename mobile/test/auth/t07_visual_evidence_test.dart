import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/auth/presentation/create_account_screen.dart';
import 'package:memora_mobile/src/features/auth/presentation/onboarding_screen.dart';
import 'package:memora_mobile/src/features/auth/presentation/sign_in_screen.dart';
import 'package:memora_mobile/src/features/home/presentation/home_screen.dart';
import 'package:memora_mobile/src/theme/memora_theme.dart';

const _captureKey = Key('t07_visual_evidence');
const _session = AuthSession(accessToken: 'synthetic-token', userId: 'usr_1');

Future<void> _loadEvidenceFonts() async {
  await (FontLoader(
    'Exo',
  )..addFont(rootBundle.load('assets/fonts/Exo-400.ttf'))).load();
  await (FontLoader(
    'Inter',
  )..addFont(rootBundle.load('assets/fonts/Inter-400.ttf'))).load();

  var flutterCache = File(Platform.resolvedExecutable).parent;
  while (flutterCache.path.split(Platform.pathSeparator).last.toLowerCase() !=
      'cache') {
    final parent = flutterCache.parent;
    if (parent.path == flutterCache.path) {
      throw StateError('Flutter cache not found from Dart executable.');
    }
    flutterCache = parent;
  }
  final materialIcons = <File>[
    File(
      '${flutterCache.path}/artifacts/material_fonts/materialicons-regular.otf',
    ),
    File(
      '${flutterCache.path}/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ),
  ].firstWhere(
    (file) => file.existsSync(),
    orElse: () => throw StateError('Material Icons font not found.'),
  );
  final iconBytes = await materialIcons.readAsBytes();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future<ByteData>.value(ByteData.sublistView(iconBytes)))).load();
}

BootstrapData _bootstrap() => BootstrapData(
  accountStatus: AccountStatusDomain.active,
  profileSummary: const ProfileSummaryDomain(
    userId: 'usr_1',
    displayName: 'Amani Perera',
    streakDays: 0,
  ),
  consentStatus: const ConsentStatusDomain(requiresReview: false),
  subjects: const <SubjectSummaryDomain>[],
  capabilities: const CapabilityFlagsDomain(canAddLearningMaterial: true),
  serverTime: DateTime.utc(2026, 10, 28),
);

Widget _testApp(Widget child, {bool authenticated = false}) {
  final keyStore = InMemorySecureKeyStore();
  final localStorage = AppLocalStorage(keyStore);

  return ProviderScope(
    overrides: <Override>[
      secureKeyStoreProvider.overrideWithValue(keyStore),
      appLocalStorageProvider.overrideWithValue(localStorage),
      sessionControllerProvider.overrideWith(
        (ref) => SessionController(
          authRepository: MockAuthRepository(
            initialSession: authenticated ? _session : null,
          ),
          sessionRepository: MockSessionRepository(
            configuredBootstrap: _bootstrap(),
          ),
          localStorage: localStorage,
          initialState: authenticated
              ? AppSessionState.active(
                  session: _session,
                  bootstrapData: _bootstrap(),
                )
              : AppSessionState.signedOut(),
        ),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MemoraTheme.light(),
      home: RepaintBoundary(key: _captureKey, child: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadEvidenceFonts();
  });

  Future<void> capture(
    WidgetTester tester,
    Widget screen,
    String fileName, {
    bool authenticated = false,
  }) async {
    tester.view.physicalSize = const Size(402, 1001);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp(screen, authenticated: authenticated));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(_captureKey),
      matchesGoldenFile('goldens/t07/$fileName.png'),
    );
  }

  testWidgets('captures onboarding step 1', (tester) async {
    await capture(tester, const OnboardingScreen(step: 1), 'onboarding_step_1');
  });

  testWidgets('captures onboarding step 2', (tester) async {
    await capture(tester, const OnboardingScreen(step: 2), 'onboarding_step_2');
  });

  testWidgets('captures onboarding step 3', (tester) async {
    await capture(tester, const OnboardingScreen(step: 3), 'onboarding_step_3');
  });

  testWidgets('captures sign in', (tester) async {
    await capture(tester, const SignInScreen(), 'sign_in');
  });

  testWidgets('captures create account', (tester) async {
    await capture(tester, const CreateAccountScreen(), 'create_account');
  });

  testWidgets('captures bootstrap-backed Home', (tester) async {
    await capture(
      tester,
      const HomeScreen(),
      'home_setup',
      authenticated: true,
    );
  });
}
