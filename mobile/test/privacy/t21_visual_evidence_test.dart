@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/privacy/application/privacy_controller.dart';
import 'package:memora_mobile/src/features/privacy/data/privacy_download_launcher.dart';
import 'package:memora_mobile/src/features/privacy/data/privacy_reachability.dart';
import 'package:memora_mobile/src/features/privacy/data/privacy_repository.dart';
import 'package:memora_mobile/src/features/privacy/domain/privacy_models.dart';
import 'package:memora_mobile/src/features/privacy/presentation/privacy_delete_screen.dart';
import 'package:memora_mobile/src/features/privacy/presentation/privacy_deletion_status_screen.dart';
import 'package:memora_mobile/src/features/privacy/presentation/privacy_export_screen.dart';
import 'package:memora_mobile/src/features/privacy/presentation/privacy_overview_screen.dart';
import 'package:memora_mobile/src/features/privacy/presentation/privacy_reauth_screen.dart';
import 'package:memora_mobile/src/theme/memora_theme.dart';

const _captureKey = Key('t21_visual_evidence');

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
  final materialIcons =
      <File>[
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

class _MutableReachability implements PrivacyReachability {
  _MutableReachability(this.value);

  bool value;

  @override
  Future<bool> check() async => value;
}

class _FakeLauncher implements PrivacyDownloadLauncher {
  @override
  Future<void> openExternal(Uri uri) async {}
}

class _Harness {
  _Harness() {
    auth = MockAuthRepository();
    sessionRepository = MockSessionRepository();
    session = SessionController(
      authRepository: auth,
      sessionRepository: sessionRepository,
      localStorage: AppLocalStorage(InMemorySecureKeyStore()),
      initialState: AppSessionState.active(
        session: const AuthSession(
          accessToken: 'synthetic-token',
          userId: 'usr_1',
          email: 'student@memora.internal',
        ),
        bootstrapData: BootstrapData(
          accountStatus: AccountStatusDomain.active,
          profileSummary: const ProfileSummaryDomain(
            userId: 'usr_1',
            displayName: 'Amani Perera',
          ),
          consentStatus: const ConsentStatusDomain(requiresReview: false),
          subjects: const <SubjectSummaryDomain>[],
          capabilities: const CapabilityFlagsDomain(),
          serverTime: DateTime.utc(2026, 11, 1),
        ),
      ),
    );
    repository = MockPrivacyRepository();
    reachability = _MutableReachability(true);
    controller = PrivacyController(
      repository: repository,
      reachability: reachability,
      sessionController: session,
      downloadLauncher: _FakeLauncher(),
      clock: () => DateTime.utc(2026, 11, 1, 12),
    );
  }

  late final MockAuthRepository auth;
  late final MockSessionRepository sessionRepository;
  late final SessionController session;
  late final MockPrivacyRepository repository;
  late final _MutableReachability reachability;
  late final PrivacyController controller;

  void dispose() {
    auth.dispose();
  }
}

_Harness _createHarness() {
  final harness = _Harness();
  addTearDown(harness.dispose);
  return harness;
}

Widget _testApp(_Harness harness, Widget child) {
  return ProviderScope(
    overrides: <Override>[
      sessionControllerProvider.overrideWith((ref) => harness.session),
      privacyControllerProvider.overrideWith((ref) => harness.controller),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MemoraTheme.light(),
      home: RepaintBoundary(key: _captureKey, child: child),
    ),
  );
}

Future<void> _pumpAsync(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const AuthFailure _recentAuth = AuthFailure(
  code: 'recent_authentication_required',
  message: 'Please confirm your credentials to continue.',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadEvidenceFonts();
  });

  Future<void> capture(
    WidgetTester tester,
    _Harness harness,
    Widget screen,
    String fileName,
  ) async {
    tester.view.physicalSize = const Size(402, 1001);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp(harness, screen));
    await _pumpAsync(tester);

    await expectLater(
      find.byKey(_captureKey),
      matchesGoldenFile('goldens/t21/$fileName.png'),
    );
  }

  testWidgets('captures the privacy hub', (tester) async {
    await capture(
      tester,
      _createHarness(),
      const PrivacyOverviewScreen(),
      'privacy_overview',
    );
  });

  testWidgets('captures the privacy hub offline state', (tester) async {
    final harness = _createHarness();
    harness.reachability.value = false;
    await capture(
      tester,
      harness,
      const PrivacyOverviewScreen(),
      'privacy_overview_offline',
    );
  });

  testWidgets('captures the export introduction', (tester) async {
    await capture(
      tester,
      _createHarness(),
      const PrivacyExportScreen(),
      'privacy_export_intro',
    );
  });

  testWidgets('captures a completed export with a download', (tester) async {
    final harness = _createHarness();
    harness.repository.configuredExport = PrivacyExport(
      id: 'exp_1',
      status: PrivacyRequestStatus.completed,
      requestedAt: DateTime.utc(2026, 11, 1, 10),
      completedAt: DateTime.utc(2026, 11, 1, 10, 5),
      downloadUri: Uri.parse(
        'https://api.memora.test/v1/privacy/exports/exp_1/download'
        '?token=synthetic',
      ),
      downloadExpiresAt: DateTime.utc(2026, 11, 2),
    );
    await capture(
      tester,
      harness,
      const PrivacyExportScreen(requestId: 'exp_1'),
      'privacy_export_completed',
    );
  });

  testWidgets('captures the deletion explanation', (tester) async {
    await capture(
      tester,
      _createHarness(),
      const PrivacyDeleteScreen(),
      'privacy_delete_intro',
    );
  });

  testWidgets('captures a verified deletion outcome', (tester) async {
    final harness = _createHarness();
    harness.repository.configuredDeletion = PrivacyDeletion(
      id: 'del_1',
      status: PrivacyRequestStatus.completed,
      requestedAt: DateTime.utc(2026, 11, 1, 10),
      completedAt: DateTime.utc(2026, 11, 1, 10, 5),
      proofs: <DeletionProof>[
        DeletionProof(
          id: 'prf_1',
          scope: 'profile',
          provider: 'postgres',
          result: 'deleted',
          verifiedAt: DateTime.utc(2026, 11, 1, 10, 4),
        ),
      ],
      retentionExceptions: const <String>[
        'Billing records retained where required by law',
      ],
    );
    await capture(
      tester,
      harness,
      const PrivacyDeletionStatusScreen(requestId: 'del_1'),
      'privacy_deletion_completed',
    );
  });

  testWidgets('captures the reauthentication recovery form', (tester) async {
    final harness = _createHarness();
    harness.repository.failure = _recentAuth;
    await harness.controller.checkReachability();
    await harness.controller.requestExport();
    harness.repository.failure = null;

    await capture(
      tester,
      harness,
      const PrivacyReauthScreen(),
      'privacy_reauth',
    );
  });
}
