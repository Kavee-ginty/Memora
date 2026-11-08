import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memora_mobile/src/design_system/components/button.dart';
import 'package:memora_mobile/src/design_system/components/dialog.dart';
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
import 'package:memora_mobile/src/features/profile/presentation/profile_entry_screen.dart';
import 'package:memora_mobile/src/routing/app_routes.dart';

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
  _Harness({List<PendingResourceSummaryDomain> pending = const []}) {
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
          pendingPrivacyRequests: pending,
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

_Harness _createHarness({
  List<PendingResourceSummaryDomain> pending = const [],
}) {
  final harness = _Harness(pending: pending);
  addTearDown(harness.dispose);
  return harness;
}

Widget _buildApp({
  required _Harness harness,
  required Widget child,
  String initialLocation = '/test',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(path: '/test', builder: (context, state) => child),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (context, state) => const Scaffold(body: Text('privacy-stub')),
      ),
      GoRoute(
        path: AppRoutes.privacyExport,
        builder: (context, state) =>
            const Scaffold(body: Text('export-entry-stub')),
      ),
      GoRoute(
        path: AppRoutes.privacyExportStatus,
        builder: (context, state) => Scaffold(
          body: Text('export-status-stub:${state.pathParameters['requestId']}'),
        ),
      ),
      GoRoute(
        path: AppRoutes.privacyDelete,
        builder: (context, state) =>
            const Scaffold(body: Text('delete-entry-stub')),
      ),
      GoRoute(
        path: AppRoutes.privacyDeletionStatus,
        builder: (context, state) => Scaffold(
          body: Text(
            'deletion-status-stub:${state.pathParameters['requestId']}',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.privacyReauth,
        builder: (context, state) => const PrivacyReauthScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const Scaffold(body: Text('profile-stub')),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const Scaffold(body: Text('sign-in-stub')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      sessionControllerProvider.overrideWith((ref) => harness.session),
      privacyControllerProvider.overrideWith((ref) => harness.controller),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _pumpAsync(WidgetTester tester, {int frames = 6}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
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

void main() {
  group('Privacy overview', () {
    testWidgets('presents both workflows and the recent sign-in requirement', (
      tester,
    ) async {
      final harness = _createHarness();
      await tester.pumpWidget(
        _buildApp(harness: harness, child: const PrivacyOverviewScreen()),
      );
      await _pumpAsync(tester);

      expect(find.text('Export your data'), findsOneWidget);
      expect(find.text('Delete your account'), findsOneWidget);
      expect(find.byKey(const Key('privacy_overview_export')), findsOneWidget);
      expect(find.byKey(const Key('privacy_overview_delete')), findsOneWidget);
      expect(find.text('Recent sign-in required'), findsOneWidget);
      expect(harness.reachability.calls, greaterThanOrEqualTo(1));
    });

    testWidgets('shows an offline banner and recovers after a retry', (
      tester,
    ) async {
      final harness = _createHarness();
      harness.reachability.value = false;

      await tester.pumpWidget(
        _buildApp(harness: harness, child: const PrivacyOverviewScreen()),
      );
      await _pumpAsync(tester);

      expect(find.text('You are offline'), findsOneWidget);

      harness.reachability.value = true;
      await tester.tap(find.text('Retry'));
      await _pumpAsync(tester);

      expect(find.text('You are offline'), findsNothing);
    });

    testWidgets('resolves a pending bootstrap request before navigating', (
      tester,
    ) async {
      final harness = _createHarness(
        pending: <PendingResourceSummaryDomain>[
          PendingResourceSummaryDomain(
            id: 'exp_1',
            status: 'requested',
            updatedAt: DateTime.utc(2026, 11, 1, 9),
          ),
        ],
      );
      harness.repository.configuredExport = _export(id: 'exp_1');

      await tester.pumpWidget(
        _buildApp(harness: harness, child: const PrivacyOverviewScreen()),
      );
      await _pumpAsync(tester);

      expect(find.text('Privacy request in progress'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('privacy_overview_pending_status')),
      );
      await _pumpAsync(tester, frames: 12);

      expect(harness.repository.getExportCallCount, 1);
      expect(find.text('export-status-stub:exp_1'), findsOneWidget);
    });
  });

  group('Privacy export screen', () {
    testWidgets('requests one export and routes to its status', (tester) async {
      final harness = _createHarness();

      await tester.pumpWidget(
        _buildApp(harness: harness, child: const PrivacyExportScreen()),
      );
      await _pumpAsync(tester);

      await tester.tap(find.byKey(const Key('privacy_export_request')));
      await _pumpAsync(tester, frames: 12);

      expect(harness.repository.createExportCallCount, 1);
      expect(harness.repository.lastCreateExportKey, isNotEmpty);
      expect(
        find.text('export-status-stub:${MockPrivacyRepository.mockExportId}'),
        findsOneWidget,
      );
    });

    testWidgets('polls a pending export and stops on completion', (
      tester,
    ) async {
      final harness = _createHarness();
      harness.repository.configuredExport = _export();

      await tester.pumpWidget(
        _buildApp(
          harness: harness,
          child: const PrivacyExportScreen(requestId: 'exp_1'),
        ),
      );
      await _pumpAsync(tester);

      expect(find.text('Requested'), findsOneWidget);
      final initialReads = harness.repository.getExportCallCount;

      harness.repository.configuredExport = _export(
        status: PrivacyRequestStatus.completed,
        downloadUri: Uri.parse('https://cdn.memora.example/export'),
        downloadExpiresAt: DateTime.utc(2026, 11, 2),
      );
      await tester.pump(const Duration(seconds: 5));
      await _pumpAsync(tester, frames: 12);

      expect(harness.repository.getExportCallCount, greaterThan(initialReads));
      expect(find.text('Completed'), findsOneWidget);
      expect(find.byKey(const Key('privacy_export_download')), findsOneWidget);
    });

    testWidgets('offers a download only while the signed URL is valid', (
      tester,
    ) async {
      final harness = _createHarness();
      final uri = Uri.parse(
        'https://cdn.memora.example/v1/privacy/exports/exp_1/download'
        '?token=signed-token',
      );
      harness.repository.configuredExport = _export(
        status: PrivacyRequestStatus.completed,
        downloadUri: uri,
        downloadExpiresAt: DateTime.utc(2026, 11, 2),
      );

      await tester.pumpWidget(
        _buildApp(
          harness: harness,
          child: const PrivacyExportScreen(requestId: 'exp_1'),
        ),
      );
      await _pumpAsync(tester);

      expect(find.textContaining('Your export is ready'), findsOneWidget);
      expect(find.byKey(const Key('privacy_export_download')), findsOneWidget);
      expect(find.textContaining('token=signed-token'), findsNothing);

      await tester.tap(find.byKey(const Key('privacy_export_download')));
      await _pumpAsync(tester);

      expect(harness.launcher.opened, uri);
      expect(find.text('Download opened in your browser.'), findsOneWidget);
    });

    testWidgets('does not offer an expired download', (tester) async {
      final harness = _createHarness();
      harness.repository.configuredExport = _export(
        status: PrivacyRequestStatus.completed,
        downloadUri: Uri.parse('https://cdn.memora.example/export'),
        downloadExpiresAt: DateTime.utc(2026, 11, 1, 11),
      );

      await tester.pumpWidget(
        _buildApp(
          harness: harness,
          child: const PrivacyExportScreen(requestId: 'exp_1'),
        ),
      );
      await _pumpAsync(tester);

      expect(find.textContaining('download link has expired'), findsOneWidget);
      expect(find.byKey(const Key('privacy_export_download')), findsNothing);
      expect(
        find.byKey(const Key('privacy_export_request_new')),
        findsOneWidget,
      );
    });
  });

  group('Privacy deletion screen', () {
    testWidgets('requires explicit confirmation before starting deletion', (
      tester,
    ) async {
      final harness = _createHarness();

      await tester.pumpWidget(
        _buildApp(harness: harness, child: const PrivacyDeleteScreen()),
      );
      await _pumpAsync(tester);

      final submit = find.byKey(const Key('privacy_delete_submit'));
      expect(tester.widget<MemoraButton>(submit).onPressed, isNull);

      final checkbox = find.byKey(const Key('privacy_delete_confirm_checkbox'));
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pump();
      expect(tester.widget<MemoraButton>(submit).onPressed, isNotNull);

      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await _pumpAsync(tester);
      expect(find.text('Delete your account?'), findsOneWidget);

      await tester.tap(find.text('Delete account'));
      await _pumpAsync(tester, frames: 12);

      expect(harness.repository.createDeletionCallCount, 1);
      expect(harness.repository.lastCreateDeletionConfirmed, isTrue);
      expect(
        find.text(
          'deletion-status-stub:${MockPrivacyRepository.mockDeletionId}',
        ),
        findsOneWidget,
      );
    });
  });

  group('Privacy deletion status screen', () {
    testWidgets('cancels only a pending deletion after confirmation', (
      tester,
    ) async {
      final harness = _createHarness();
      harness.repository.configuredDeletion = _deletion(
        status: PrivacyRequestStatus.requested,
      );

      await tester.pumpWidget(
        _buildApp(
          harness: harness,
          child: const PrivacyDeletionStatusScreen(requestId: 'del_1'),
        ),
      );
      await _pumpAsync(tester);

      expect(find.byKey(const Key('privacy_delete_cancel')), findsOneWidget);

      harness.repository.configuredDeletion = _deletion(
        status: PrivacyRequestStatus.cancelled,
      );
      await tester.tap(find.byKey(const Key('privacy_delete_cancel')));
      await _pumpAsync(tester);
      expect(find.byType(MemoraDialog), findsOneWidget);

      await tester.tap(find.text('Cancel deletion').last);
      await _pumpAsync(tester);

      expect(harness.repository.cancelDeletionCallCount, 1);
      expect(find.text('Deletion cancelled'), findsOneWidget);
    });

    testWidgets('claims completion only with server proof state', (
      tester,
    ) async {
      final harness = _createHarness();
      harness.repository.configuredDeletion = _deletion(
        status: PrivacyRequestStatus.completed,
        proofs: <DeletionProof>[_proof()],
        retentionExceptions: <String>[
          'Billing records are retained for seven years.',
        ],
      );

      await tester.pumpWidget(
        _buildApp(
          harness: harness,
          child: const PrivacyDeletionStatusScreen(requestId: 'del_1'),
        ),
      );
      await _pumpAsync(tester);

      expect(find.text('Deletion verified'), findsOneWidget);
      expect(find.text('profile'), findsOneWidget);
      expect(find.textContaining('Billing records'), findsOneWidget);
      expect(find.byKey(const Key('privacy_delete_sign_in')), findsOneWidget);
      expect(find.text('Verification details missing'), findsNothing);
    });

    testWidgets('completed without proofs stays unconfirmed', (tester) async {
      final harness = _createHarness();
      harness.repository.configuredDeletion = _deletion(
        status: PrivacyRequestStatus.completed,
      );

      await tester.pumpWidget(
        _buildApp(
          harness: harness,
          child: const PrivacyDeletionStatusScreen(requestId: 'del_1'),
        ),
      );
      await _pumpAsync(tester);

      expect(find.text('Verification details missing'), findsOneWidget);
      expect(find.text('Deletion verified'), findsNothing);
      expect(
        find.textContaining('did not return verification details'),
        findsAtLeastNWidgets(1),
      );
      // Proof-missing completion must never clear the local session.
      expect(harness.session.state.phase, AppSessionPhase.active);
      expect(harness.auth.signOutCallCount, 0);
    });

    testWidgets('confirmed deletion clears credentials on the return action', (
      tester,
    ) async {
      final harness = _createHarness();
      harness.repository.configuredDeletion = _deletion(
        status: PrivacyRequestStatus.completed,
        proofs: <DeletionProof>[_proof()],
      );

      await tester.pumpWidget(
        _buildApp(
          harness: harness,
          child: const PrivacyDeletionStatusScreen(requestId: 'del_1'),
        ),
      );
      await _pumpAsync(tester);

      expect(harness.session.state.phase, AppSessionPhase.active);
      expect(harness.auth.signOutCallCount, 0);

      await tester.ensureVisible(
        find.byKey(const Key('privacy_delete_sign_in')),
      );
      await tester.tap(find.byKey(const Key('privacy_delete_sign_in')));
      await _pumpAsync(tester, frames: 12);

      expect(harness.session.state.phase, AppSessionPhase.signedOut);
      expect(harness.session.state.session, isNull);
      expect(harness.auth.signOutCallCount, 1);
    });

    testWidgets('an expired session reports an unconfirmed outcome', (
      tester,
    ) async {
      final harness = _createHarness();
      harness.repository.nextFailure = AuthFailure.expiredSession();

      await tester.pumpWidget(
        _buildApp(
          harness: harness,
          child: const PrivacyDeletionStatusScreen(requestId: 'del_1'),
        ),
      );
      await _pumpAsync(tester);

      expect(find.text('Deletion status unconfirmed'), findsAtLeastNWidgets(1));
      expect(find.textContaining('del_1'), findsAtLeastNWidgets(1));
      expect(
        find.byKey(const Key('privacy_delete_outcome_sign_out')),
        findsOneWidget,
      );
      expect(harness.session.state.phase, AppSessionPhase.active);

      await tester.tap(
        find.byKey(const Key('privacy_delete_outcome_sign_out')),
      );
      await _pumpAsync(tester);

      expect(harness.session.state.phase, AppSessionPhase.signedOut);
      expect(harness.auth.signOutCallCount, 1);
    });
  });

  group('Privacy reauthentication', () {
    testWidgets(
      'email confirmation retries the pending export without bootstrap',
      (tester) async {
        final harness = _createHarness();
        await _triggerPendingExport(harness);
        harness.auth.emailSignInUserId = 'usr_1';
        harness.auth.emailSignInEmail = 'student@memora.internal';
        final bootstrapCalls = harness.sessionRepository.bootstrapCallCount;
        final previousToken = harness.session.state.session!.accessToken;

        await tester.pumpWidget(
          _buildApp(
            harness: harness,
            child: const PrivacyReauthScreen(),
            initialLocation: AppRoutes.privacyReauth,
          ),
        );
        await _pumpAsync(tester);

        expect(find.text("Confirm it's you"), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('privacy_reauth_password')),
          'Password123!',
        );
        await tester.tap(find.byKey(const Key('privacy_reauth_submit')));
        await _pumpAsync(tester, frames: 16);

        expect(harness.repository.createExportCallCount, 2);
        expect(
          harness.session.state.session?.accessToken,
          isNot(previousToken),
        );
        expect(harness.sessionRepository.bootstrapCallCount, bootstrapCalls);
        expect(harness.auth.signOutCallCount, 0);
        expect(
          find.text('export-status-stub:${MockPrivacyRepository.mockExportId}'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Google confirmation retries the pending export', (
      tester,
    ) async {
      final harness = _createHarness();
      await _triggerPendingExport(harness);
      harness.auth.googleUserId = 'usr_1';

      await tester.pumpWidget(
        _buildApp(
          harness: harness,
          child: const PrivacyReauthScreen(),
          initialLocation: AppRoutes.privacyReauth,
        ),
      );
      await _pumpAsync(tester);

      await tester.tap(find.byKey(const Key('privacy_reauth_google')));
      await _pumpAsync(tester, frames: 20);

      expect(harness.repository.createExportCallCount, 2);
      expect(harness.session.state.session?.accessToken, 'mock_google_token');
      expect(harness.auth.signOutCallCount, 0);
      expect(
        find.text('export-status-stub:${MockPrivacyRepository.mockExportId}'),
        findsOneWidget,
      );
    });

    testWidgets('invalid credentials keep the pending action recoverable', (
      tester,
    ) async {
      final harness = _createHarness();
      await _triggerPendingExport(harness);
      harness.auth.shouldFailSignIn = true;
      harness.auth.configuredFailure = AuthFailure.invalidCredentials();

      await tester.pumpWidget(
        _buildApp(
          harness: harness,
          child: const PrivacyReauthScreen(),
          initialLocation: AppRoutes.privacyReauth,
        ),
      );
      await _pumpAsync(tester);

      await tester.enterText(
        find.byKey(const Key('privacy_reauth_password')),
        'wrong-password',
      );
      await tester.tap(find.byKey(const Key('privacy_reauth_submit')));
      await _pumpAsync(tester);

      expect(find.textContaining('Invalid email or password'), findsOneWidget);
      expect(harness.controller.state.awaitingReauthentication, isTrue);
      expect(
        harness.controller.state.pendingAction,
        PrivacyPendingAction.export,
      );
      expect(harness.repository.createExportCallCount, 1);
    });

    testWidgets('cancel clears the recovery intent and returns to Privacy', (
      tester,
    ) async {
      final harness = _createHarness();
      await _triggerPendingExport(harness);

      await tester.pumpWidget(
        _buildApp(
          harness: harness,
          child: const PrivacyReauthScreen(),
          initialLocation: AppRoutes.privacyReauth,
        ),
      );
      await _pumpAsync(tester);

      await tester.ensureVisible(
        find.byKey(const Key('privacy_reauth_cancel')),
      );
      await tester.tap(find.byKey(const Key('privacy_reauth_cancel')));
      await _pumpAsync(tester);

      expect(harness.controller.state.awaitingReauthentication, isFalse);
      expect(harness.controller.state.pendingAction, isNull);
      expect(find.text('privacy-stub'), findsOneWidget);
    });

    testWidgets('a second recent-auth rejection offers sign-in recovery', (
      tester,
    ) async {
      final harness = _createHarness();
      await _triggerPendingExport(harness);
      harness.repository.failure = _recentAuth;
      harness.auth.emailSignInUserId = 'usr_1';
      harness.auth.emailSignInEmail = 'student@memora.internal';

      await tester.pumpWidget(
        _buildApp(
          harness: harness,
          child: const PrivacyReauthScreen(),
          initialLocation: AppRoutes.privacyReauth,
        ),
      );
      await _pumpAsync(tester);

      await tester.enterText(
        find.byKey(const Key('privacy_reauth_password')),
        'Password123!',
      );
      await tester.tap(find.byKey(const Key('privacy_reauth_submit')));
      await _pumpAsync(tester);

      expect(find.textContaining('Please sign in again'), findsOneWidget);
      expect(
        find.byKey(const Key('privacy_reauth_sign_in_again')),
        findsOneWidget,
      );
      expect(harness.controller.state.pendingAction, isNull);
    });
  });

  group('Profile privacy entry', () {
    testWidgets('replaces the T21 placeholder with a privacy destination', (
      tester,
    ) async {
      final harness = _createHarness();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith((ref) => harness.session),
          ],
          child: const MaterialApp(home: ProfileEntryScreen()),
        ),
      );

      expect(find.text('Privacy'), findsOneWidget);
      expect(
        find.text('Export your data or delete your account'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('profile_privacy_entry')), findsOneWidget);
    });
  });
}
