import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/components/button.dart';
import 'package:memora_mobile/src/design_system/components/text_field.dart';
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
import 'package:memora_mobile/src/features/privacy/presentation/privacy_page.dart';
import 'package:memora_mobile/src/features/privacy/presentation/privacy_reauth_screen.dart';

class _MutableReachability implements PrivacyReachability {
  _MutableReachability(this.value);

  bool value;
  int calls = 0;

  @override
  Future<bool> check() async {
    calls++;
    return value;
  }
}

class _FakeLauncher implements PrivacyDownloadLauncher {
  Uri? opened;
  int calls = 0;

  @override
  Future<void> openExternal(Uri uri) async {
    calls++;
    opened = uri;
  }
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
          accessToken: 'token_abc',
          refreshToken: 'refresh_abc',
          userId: 'usr_1',
          email: 'student@memora.internal',
        ),
        bootstrapData: BootstrapData(
          accountStatus: AccountStatusDomain.active,
          profileSummary: const ProfileSummaryDomain(
            userId: 'usr_1',
            displayName: 'Student',
            email: 'student@memora.internal',
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
    launcher = _FakeLauncher();
    controller = PrivacyController(
      repository: repository,
      reachability: reachability,
      sessionController: session,
      downloadLauncher: launcher,
      pollInterval: const Duration(seconds: 5),
      clock: () => DateTime.utc(2026, 11, 1, 12),
    );
  }

  late final MockAuthRepository auth;
  late final MockSessionRepository sessionRepository;
  late final SessionController session;
  late final MockPrivacyRepository repository;
  late final _MutableReachability reachability;
  late final _FakeLauncher launcher;
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

Widget _buildApp({
  required _Harness harness,
  required Widget child,
  double textScale = 2.0,
  bool disableAnimations = true,
}) {
  return ProviderScope(
    overrides: <Override>[
      sessionControllerProvider.overrideWith((ref) => harness.session),
      privacyControllerProvider.overrideWith((ref) => harness.controller),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: widget!,
      ),
      home: child,
    ),
  );
}

Future<void> _pumpAsync(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _Harness harness,
  Widget child, {
  double textScale = 2.0,
}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    _buildApp(harness: harness, child: child, textScale: textScale),
  );
  await _pumpAsync(tester);
}

PrivacyExport _export({
  String id = 'exp_1',
  PrivacyRequestStatus status = PrivacyRequestStatus.requested,
  Uri? downloadUri,
  DateTime? downloadExpiresAt,
}) {
  return PrivacyExport(
    id: id,
    status: status,
    requestedAt: DateTime.utc(2026, 11, 1, 10),
    completedAt: status == PrivacyRequestStatus.completed
        ? DateTime.utc(2026, 11, 1, 10, 5)
        : null,
    downloadUri: downloadUri,
    downloadExpiresAt: downloadExpiresAt,
  );
}

PrivacyDeletion _deletion({
  String id = 'del_1',
  PrivacyRequestStatus status = PrivacyRequestStatus.requested,
  List<DeletionProof> proofs = const <DeletionProof>[],
  List<String> retentionExceptions = const <String>[],
}) {
  return PrivacyDeletion(
    id: id,
    status: status,
    requestedAt: DateTime.utc(2026, 11, 1, 10),
    completedAt: status == PrivacyRequestStatus.completed
        ? DateTime.utc(2026, 11, 1, 10, 5)
        : null,
    proofs: proofs,
    retentionExceptions: retentionExceptions,
  );
}

DeletionProof _proof() {
  return DeletionProof(
    id: 'prf_1',
    scope: 'profile',
    provider: 'postgres',
    result: 'deleted',
    verifiedAt: DateTime.utc(2026, 11, 1, 10, 4),
  );
}

const AuthFailure _recentAuth = AuthFailure(
  code: 'recent_authentication_required',
  message: 'Please confirm your credentials to continue.',
);

Future<void> _triggerPendingExport(_Harness harness) async {
  harness.repository.failure = _recentAuth;
  await harness.controller.checkReachability();
  await harness.controller.requestExport();
  harness.repository.failure = null;
}

void main() {
  group('Privacy 320 px and 200 percent text state matrix', () {
    testWidgets('overview fits and keeps both workflows readable', (
      tester,
    ) async {
      final harness = _createHarness();
      await _pumpScreen(tester, harness, const PrivacyOverviewScreen());

      expect(tester.takeException(), isNull);
      expect(find.text('Your data, your choice'), findsOneWidget);
      expect(find.byKey(const Key('privacy_overview_export')), findsOneWidget);
      expect(find.byKey(const Key('privacy_overview_delete')), findsOneWidget);
      expect(find.text('What Memora keeps'), findsOneWidget);
      expect(find.text('Verified learning knowledge'), findsOneWidget);
      expect(
        find.textContaining('Original files you upload are temporary'),
        findsOneWidget,
      );
    });

    testWidgets('offline overview disables actions with a stated reason', (
      tester,
    ) async {
      final harness = _createHarness();
      harness.reachability.value = false;
      await _pumpScreen(tester, harness, const PrivacyOverviewScreen());

      expect(tester.takeException(), isNull);
      expect(find.text('You are offline'), findsOneWidget);
      expect(
        find.textContaining('Privacy actions are unavailable'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<MemoraButton>(
              find.byKey(const Key('privacy_overview_export')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<MemoraButton>(
              find.byKey(const Key('privacy_overview_delete')),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('export introduction fits at 200 percent text', (tester) async {
      final harness = _createHarness();
      await _pumpScreen(tester, harness, const PrivacyExportScreen());

      expect(tester.takeException(), isNull);
      expect(find.text('A copy of your Memora data'), findsOneWidget);
      expect(find.byKey(const Key('privacy_export_request')), findsOneWidget);
    });

    testWidgets('pending export status fits at 200 percent text', (
      tester,
    ) async {
      final harness = _createHarness();
      harness.repository.configuredExport = _export();
      await _pumpScreen(
        tester,
        harness,
        const PrivacyExportScreen(requestId: 'exp_1'),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Export request'), findsOneWidget);
      expect(find.text('Requested'), findsOneWidget);
      expect(find.byKey(const Key('privacy_export_refresh')), findsOneWidget);
    });

    testWidgets('completed export offers the download at 200 percent text', (
      tester,
    ) async {
      final harness = _createHarness();
      harness.repository.configuredExport = _export(
        status: PrivacyRequestStatus.completed,
        downloadUri: Uri.parse(
          'https://api.memora.test/v1/privacy/exports/exp_1/download'
          '?token=synthetic',
        ),
        downloadExpiresAt: DateTime.utc(2026, 11, 2),
      );
      await _pumpScreen(
        tester,
        harness,
        const PrivacyExportScreen(requestId: 'exp_1'),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.byKey(const Key('privacy_export_download')), findsOneWidget);
    });

    testWidgets('export without an expiry never offers a download', (
      tester,
    ) async {
      final harness = _createHarness();
      harness.repository.configuredExport = _export(
        status: PrivacyRequestStatus.completed,
        downloadUri: Uri.parse('https://api.memora.test/export'),
      );
      await _pumpScreen(
        tester,
        harness,
        const PrivacyExportScreen(requestId: 'exp_1'),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.byKey(const Key('privacy_export_download')), findsNothing);
      expect(
        find.textContaining('did not return a download expiry'),
        findsOneWidget,
      );
    });

    testWidgets('failed export never offers a download', (tester) async {
      final harness = _createHarness();
      harness.repository.configuredExport = _export(
        status: PrivacyRequestStatus.failed,
      );
      await _pumpScreen(
        tester,
        harness,
        const PrivacyExportScreen(requestId: 'exp_1'),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.byKey(const Key('privacy_export_download')), findsNothing);
      expect(
        find.textContaining('The export could not be completed'),
        findsOneWidget,
      );
    });

    testWidgets(
      'deletion explanation and confirmation fit at 200 percent text',
      (tester) async {
        final harness = _createHarness();
        await _pumpScreen(tester, harness, const PrivacyDeleteScreen());

        expect(tester.takeException(), isNull);
        expect(find.text('What deletion means'), findsOneWidget);
        expect(
          find.byKey(const Key('privacy_delete_confirm_checkbox')),
          findsOneWidget,
        );
        final submit = tester.widget<MemoraButton>(
          find.byKey(const Key('privacy_delete_submit')),
        );
        expect(submit.onPressed, isNull);
      },
    );

    testWidgets('pending deletion status keeps cancellation available', (
      tester,
    ) async {
      final harness = _createHarness();
      harness.repository.configuredDeletion = _deletion();
      await _pumpScreen(
        tester,
        harness,
        const PrivacyDeletionStatusScreen(requestId: 'del_1'),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Deletion request'), findsOneWidget);
      expect(find.text('Requested'), findsOneWidget);
      expect(find.byKey(const Key('privacy_delete_cancel')), findsOneWidget);
    });

    testWidgets('processing deletion removes cancellation', (tester) async {
      final harness = _createHarness();
      harness.repository.configuredDeletion = _deletion(
        status: PrivacyRequestStatus.processing,
      );
      await _pumpScreen(
        tester,
        harness,
        const PrivacyDeletionStatusScreen(requestId: 'del_1'),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Deletion is processing'), findsOneWidget);
      expect(find.byKey(const Key('privacy_delete_cancel')), findsNothing);
    });

    testWidgets('confirmed deletion shows proof scopes at 200 percent text', (
      tester,
    ) async {
      final harness = _createHarness();
      harness.repository.configuredDeletion = _deletion(
        status: PrivacyRequestStatus.completed,
        proofs: <DeletionProof>[_proof()],
        retentionExceptions: const <String>['Billing records retained by law'],
      );
      await _pumpScreen(
        tester,
        harness,
        const PrivacyDeletionStatusScreen(requestId: 'del_1'),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Deletion verified'), findsOneWidget);
      expect(find.text('Verified scopes'), findsOneWidget);
      expect(find.text('profile'), findsOneWidget);
      expect(
        find.textContaining('Billing records retained by law'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('privacy_delete_sign_in')), findsOneWidget);
    });

    testWidgets('proof-missing completion stays explicitly unconfirmed', (
      tester,
    ) async {
      final harness = _createHarness();
      harness.repository.configuredDeletion = _deletion(
        status: PrivacyRequestStatus.completed,
      );
      await _pumpScreen(
        tester,
        harness,
        const PrivacyDeletionStatusScreen(requestId: 'del_1'),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Verification details missing'), findsOneWidget);
      expect(find.text('Deletion verified'), findsNothing);
    });

    testWidgets('unconfirmed deletion outcome fits at 200 percent text', (
      tester,
    ) async {
      final harness = _createHarness();
      harness.repository.nextFailure = AuthFailure.expiredSession();
      await _pumpScreen(
        tester,
        harness,
        const PrivacyDeletionStatusScreen(requestId: 'del_1'),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Deletion status unconfirmed'), findsAtLeastNWidgets(1));
      expect(
        find.byKey(const Key('privacy_delete_outcome_sign_out')),
        findsOneWidget,
      );
      expect(find.text('Deletion verified'), findsNothing);
    });

    testWidgets('reauthentication form fits at 200 percent text', (
      tester,
    ) async {
      final harness = _createHarness();
      await _triggerPendingExport(harness);
      await _pumpScreen(tester, harness, const PrivacyReauthScreen());

      expect(tester.takeException(), isNull);
      expect(find.text("Confirm it's you"), findsOneWidget);
      expect(find.byKey(const Key('privacy_reauth_email')), findsOneWidget);
      expect(find.byKey(const Key('privacy_reauth_password')), findsOneWidget);
      expect(find.byKey(const Key('privacy_reauth_submit')), findsOneWidget);
      expect(find.byKey(const Key('privacy_reauth_google')), findsOneWidget);
      expect(find.byKey(const Key('privacy_reauth_cancel')), findsOneWidget);
    });
  });

  group('Privacy semantics and focus evidence', () {
    testWidgets('header and status chip expose screen-reader names', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      final harness = _createHarness();
      harness.repository.configuredDeletion = _deletion();
      await _pumpScreen(
        tester,
        harness,
        const PrivacyDeletionStatusScreen(requestId: 'del_1'),
      );

      expect(find.bySemanticsLabel('Go back'), findsAtLeastNWidgets(1));
      final chip = tester.getSemantics(find.byType(PrivacyStatusChip));
      expect(chip.label, contains('Status: Requested'));
      semantics.dispose();
    });

    testWidgets('pending progress exposes an accessible state label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      final harness = _createHarness();
      harness.repository.configuredDeletion = _deletion();
      await _pumpScreen(
        tester,
        harness,
        const PrivacyDeletionStatusScreen(requestId: 'del_1'),
      );

      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator).first,
      );
      expect(progress.semanticsLabel, 'Deletion request pending');
      semantics.dispose();
    });

    testWidgets('reauth declares the approved traversal order', (tester) async {
      final harness = _createHarness();
      await _triggerPendingExport(harness);
      await _pumpScreen(tester, harness, const PrivacyReauthScreen());

      final orders = tester
          .widgetList<FocusTraversalOrder>(find.byType(FocusTraversalOrder))
          .map((widget) => (widget.order as NumericFocusOrder).order)
          .toList();
      expect(orders, <double>[1, 2, 3, 4]);
    });

    testWidgets('reauth traversal moves email -> password -> submit', (
      tester,
    ) async {
      final harness = _createHarness();
      await _triggerPendingExport(harness);
      await _pumpScreen(tester, harness, const PrivacyReauthScreen());

      final fields = tester
          .widgetList<MemoraTextField>(find.byType(MemoraTextField))
          .toList();
      expect(fields, hasLength(2));
      final emailFocus = fields[0].focusNode!;
      final passwordFocus = fields[1].focusNode!;

      await tester.ensureVisible(find.byType(MemoraTextField).at(0));
      await tester.tap(find.byType(MemoraTextField).at(0));
      await tester.pump();
      expect(emailFocus.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(passwordFocus.hasFocus, isTrue);
    });

    testWidgets('reauth validation error is announced as a live region', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      final harness = _createHarness();
      await _triggerPendingExport(harness);
      await _pumpScreen(tester, harness, const PrivacyReauthScreen());

      await tester.ensureVisible(
        find.byKey(const Key('privacy_reauth_submit')),
      );
      await tester.tap(find.byKey(const Key('privacy_reauth_submit')));
      await _pumpAsync(tester);

      expect(
        find.bySemanticsLabel('Please check the highlighted fields below.'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('offline banner keeps a labelled retry action', (tester) async {
      final semantics = tester.ensureSemantics();

      final harness = _createHarness();
      harness.reachability.value = false;
      await _pumpScreen(tester, harness, const PrivacyOverviewScreen());

      expect(find.bySemanticsLabel('Retry'), findsAtLeastNWidgets(1));
      semantics.dispose();
    });
  });
}
