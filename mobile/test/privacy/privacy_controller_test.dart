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

class _FakeDownloadLauncher implements PrivacyDownloadLauncher {
  Uri? opened;
  Object? error;
  int calls = 0;

  @override
  Future<void> openExternal(Uri uri) async {
    calls++;
    final configured = error;
    if (configured != null) throw configured;
    opened = uri;
  }
}

const AuthFailure _recentAuth = AuthFailure(
  code: 'recent_authentication_required',
  message: 'Please confirm your credentials to continue.',
);

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
  late MockAuthRepository mockAuth;
  late MockSessionRepository mockSession;
  late SessionController sessionController;
  late MockPrivacyRepository repository;
  late _MutableReachability reachability;
  late _FakeDownloadLauncher launcher;
  late PrivacyController controller;

  const session = AuthSession(
    accessToken: 'token_abc',
    refreshToken: 'refresh_abc',
    userId: 'usr_1',
    email: 'student@memora.internal',
  );

  setUp(() async {
    mockAuth = MockAuthRepository(initialSession: session);
    mockSession = MockSessionRepository();
    sessionController = SessionController(
      authRepository: mockAuth,
      sessionRepository: mockSession,
      localStorage: AppLocalStorage(InMemorySecureKeyStore()),
    );
    await sessionController.initialize();

    repository = MockPrivacyRepository();
    reachability = _MutableReachability(true);
    launcher = _FakeDownloadLauncher();
    controller = PrivacyController(
      repository: repository,
      reachability: reachability,
      sessionController: sessionController,
      downloadLauncher: launcher,
      pollInterval: const Duration(milliseconds: 20),
      clock: () => DateTime.utc(2026, 11, 1, 12),
    );
  });

  tearDown(() {
    controller.dispose();
    sessionController.dispose();
    mockAuth.dispose();
  });

  group('reachability and offline gating', () {
    test('unknown reachability disables mutations until checked', () async {
      expect(controller.state.reachabilityKnown, isFalse);
      expect(controller.state.canMutate, isFalse);

      final reachable = await controller.checkReachability();

      expect(reachable, isTrue);
      expect(controller.state.reachabilityKnown, isTrue);
      expect(controller.state.canMutate, isTrue);
      expect(controller.state.lastCheckedAt, isNotNull);
    });

    test('offline state disables mutations with a visible reason', () async {
      reachability.value = false;

      await controller.checkReachability();
      final export = await controller.requestExport();

      expect(export, isNull);
      expect(controller.state.isOffline, isTrue);
      expect(controller.state.canMutate, isFalse);
      expect(controller.state.failure?.code, 'network_error');
      expect(repository.createExportCallCount, 0);
    });

    test('offline check stops an active poll', () async {
      repository.configuredExport = _export();
      await controller.loadExport('exp_1');
      expect(controller.state.isPolling, isTrue);

      reachability.value = false;
      await controller.checkReachability();

      expect(controller.state.isPolling, isFalse);
    });
  });

  group('export creation and idempotency', () {
    test(
      'creates one export and does not duplicate a pending request',
      () async {
        await controller.checkReachability();

        final export = await controller.requestExport();
        expect(export, isNotNull);
        expect(repository.createExportCallCount, 1);
        expect(repository.lastCreateExportKey, isNotEmpty);
        expect(controller.state.export?.status, PrivacyRequestStatus.requested);
        expect(controller.state.isPolling, isTrue);

        final duplicate = await controller.requestExport();
        expect(duplicate, same(export));
        expect(repository.createExportCallCount, 1);
        expect(controller.state.notice, contains('already in progress'));
      },
    );

    test('network failure keeps the same key for a retry', () async {
      await controller.checkReachability();
      repository.failure = AuthFailure.networkError();

      await controller.requestExport();
      final firstKey = repository.lastCreateExportKey;
      expect(firstKey, isNotNull);
      expect(controller.state.isOffline, isTrue);

      reachability.value = true;
      await controller.checkReachability();
      repository.failure = null;

      await controller.requestExport();

      expect(repository.createExportCallCount, 2);
      expect(repository.lastCreateExportKey, firstKey);
    });

    test(
      'recent authentication opens recovery and retries with the same key',
      () async {
        await controller.checkReachability();
        repository.failure = _recentAuth;

        await controller.requestExport();

        expect(controller.state.awaitingReauthentication, isTrue);
        expect(controller.state.pendingAction, PrivacyPendingAction.export);
        final firstKey = repository.lastCreateExportKey;

        repository.failure = null;
        await controller.retryPendingAction();

        expect(repository.createExportCallCount, 2);
        expect(repository.lastCreateExportKey, firstKey);
        expect(controller.state.awaitingReauthentication, isFalse);
        expect(controller.state.export, isNotNull);
      },
    );

    test('a second recent-auth rejection stops the workflow', () async {
      await controller.checkReachability();
      repository.failure = _recentAuth;
      await controller.requestExport();

      await controller.retryPendingAction();

      expect(controller.state.awaitingReauthentication, isFalse);
      expect(controller.state.pendingAction, isNull);
      expect(controller.state.failure?.code, 'reauthentication_failed');
      expect(repository.createExportCallCount, 2);
    });

    test('export 401 uses normal session-expiry handling', () async {
      await controller.checkReachability();
      repository.failure = AuthFailure.expiredSession();

      await controller.requestExport();

      expect(controller.state.failure?.code, 'expired_session');
      expect(sessionController.state.phase, AppSessionPhase.signedOut);
    });

    test('a pending bootstrap summary blocks a new export', () async {
      mockSession.configuredBootstrap = BootstrapData(
        accountStatus: AccountStatusDomain.active,
        profileSummary: const ProfileSummaryDomain(
          userId: 'usr_1',
          displayName: 'Student',
        ),
        consentStatus: const ConsentStatusDomain(requiresReview: false),
        subjects: const <SubjectSummaryDomain>[],
        pendingPrivacyRequests: <PendingResourceSummaryDomain>[
          PendingResourceSummaryDomain(
            id: 'pending_1',
            status: 'requested',
            updatedAt: DateTime.utc(2026, 11, 1, 9),
          ),
        ],
        capabilities: const CapabilityFlagsDomain(),
        serverTime: DateTime.utc(2026, 11, 1, 10),
      );
      await sessionController.bootstrapWithSession(session);
      await controller.checkReachability();

      final export = await controller.requestExport();

      expect(export, isNull);
      expect(repository.createExportCallCount, 0);
      expect(controller.state.notice, contains('already in progress'));
    });
  });

  group('export status and download', () {
    test(
      'completed export resolves a usable download and opens externally',
      () async {
        final uri = Uri.parse('https://cdn.memora.example/export?token=signed');
        repository.configuredExport = _export(
          status: PrivacyRequestStatus.completed,
          downloadUri: uri,
          downloadExpiresAt: DateTime.utc(2026, 11, 2),
        );

        await controller.loadExport('exp_1');

        expect(controller.state.export?.status, PrivacyRequestStatus.completed);
        expect(controller.state.isPolling, isFalse);
        expect(controller.canDownloadExport, isTrue);

        await controller.downloadExport();

        expect(launcher.opened, uri);
        expect(controller.state.notice, contains('Download opened'));
        expect(controller.state.downloadInProgress, isFalse);
      },
    );

    test('expired download is not offered or opened', () async {
      repository.configuredExport = _export(
        status: PrivacyRequestStatus.completed,
        downloadUri: Uri.parse('https://cdn.memora.example/export'),
        downloadExpiresAt: DateTime.utc(2026, 11, 1, 11),
      );

      await controller.loadExport('exp_1');

      expect(controller.canDownloadExport, isFalse);

      await controller.downloadExport();

      expect(launcher.calls, 0);
      expect(controller.state.failure?.code, 'download_expired');
    });

    test(
      'download launch failure is recoverable and does not log the URL',
      () async {
        repository.configuredExport = _export(
          status: PrivacyRequestStatus.completed,
          downloadUri: Uri.parse(
            'https://cdn.memora.example/export?token=signed',
          ),
          downloadExpiresAt: DateTime.utc(2026, 11, 2),
        );
        await controller.loadExport('exp_1');
        launcher.error = const PrivacyDownloadUnavailable();

        await controller.downloadExport();

        expect(controller.state.downloadInProgress, isFalse);
        expect(controller.state.failure?.code, 'download_unavailable');
        expect(controller.state.failure?.retryable, isTrue);
      },
    );

    test(
      'unknown export status is never treated as pending or terminal',
      () async {
        repository.configuredExport = _export(
          status: PrivacyRequestStatus.unknown,
        );

        await controller.loadExport('exp_1');

        expect(controller.state.export?.status, PrivacyRequestStatus.unknown);
        expect(controller.state.isPolling, isFalse);
      },
    );

    test('polling refreshes pending status and stops on completion', () async {
      repository.configuredExport = _export();
      await controller.loadExport('exp_1');
      expect(controller.state.isPolling, isTrue);

      repository.configuredExport = _export(
        status: PrivacyRequestStatus.completed,
        downloadUri: Uri.parse('https://cdn.memora.example/export'),
        downloadExpiresAt: DateTime.utc(2026, 11, 2),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(controller.state.export?.status, PrivacyRequestStatus.completed);
      expect(controller.state.isPolling, isFalse);
      expect(repository.getExportCallCount, greaterThanOrEqualTo(2));
    });
  });

  group('deletion creation and status', () {
    test('requires explicit confirmation before creating a request', () async {
      await controller.checkReachability();

      final deletion = await controller.requestDeletion(confirmed: false);

      expect(deletion, isNull);
      expect(repository.createDeletionCallCount, 0);
      expect(controller.state.failure?.code, 'confirmation_required');
    });

    test('creates one pending deletion and blocks a duplicate', () async {
      repository.configuredDeletion = _deletion();
      await controller.checkReachability();

      final deletion = await controller.requestDeletion(confirmed: true);

      expect(deletion, isNotNull);
      expect(repository.createDeletionCallCount, 1);
      expect(repository.lastCreateDeletionConfirmed, isTrue);
      expect(controller.state.deletion?.status, PrivacyRequestStatus.requested);
      expect(controller.state.isPolling, isTrue);

      await controller.requestDeletion(confirmed: true);
      expect(repository.createDeletionCallCount, 1);
      expect(controller.state.notice, contains('already in progress'));
    });

    test('deletion create 401 uses normal session-expiry handling', () async {
      await controller.checkReachability();
      repository.failure = AuthFailure.expiredSession();

      await controller.requestDeletion(confirmed: true);

      expect(controller.state.failure?.code, 'expired_session');
      expect(sessionController.state.phase, AppSessionPhase.signedOut);
    });

    test(
      'deletion status 401 reports an unconfirmed outcome without clearing',
      () async {
        await controller.checkReachability();
        repository.failure = AuthFailure.expiredSession();

        await controller.loadDeletion('del_1');

        expect(controller.state.outcomeUnconfirmed, isTrue);
        expect(controller.state.outcomeUnconfirmedRequestId, 'del_1');
        expect(controller.state.failure?.code, 'expired_session');
        expect(sessionController.state.phase, AppSessionPhase.active);
        expect(mockAuth.signOutCallCount, 0);
      },
    );

    test(
      'completed deletion without proofs is proof-missing, not confirmed',
      () async {
        repository.configuredDeletion = _deletion(
          status: PrivacyRequestStatus.completed,
        );

        await controller.loadDeletion('del_1');

        expect(controller.state.proofMissing, isTrue);
        expect(controller.state.isDeletionConfirmed, isFalse);
        expect(controller.state.outcomeUnconfirmed, isFalse);
      },
    );

    test('completed deletion with proofs is confirmed completion', () async {
      repository.configuredDeletion = _deletion(
        status: PrivacyRequestStatus.completed,
        proofs: <DeletionProof>[_proof()],
        retentionExceptions: <String>[
          'Billing records are retained for seven years.',
        ],
      );

      await controller.loadDeletion('del_1');

      expect(controller.state.proofMissing, isFalse);
      expect(controller.state.isDeletionConfirmed, isTrue);
      expect(controller.state.deletion?.retentionExceptions, hasLength(1));
    });
  });

  group('deletion cancellation', () {
    test('cancels only a requested deletion and resets the key', () async {
      repository.configuredDeletion = _deletion();
      await controller.loadDeletion('del_1');

      repository.configuredDeletion = _deletion(
        status: PrivacyRequestStatus.cancelled,
      );
      final cancelled = await controller.cancelDeletion();

      expect(cancelled?.status, PrivacyRequestStatus.cancelled);
      expect(controller.state.deletion?.status, PrivacyRequestStatus.cancelled);
      expect(repository.lastCancelDeletionKey, isNotEmpty);
      expect(repository.lastCancelReason, 'user_requested');
      expect(controller.state.isPolling, isFalse);
    });

    test('does not call the server once processing has begun', () async {
      repository.configuredDeletion = _deletion(
        status: PrivacyRequestStatus.processing,
      );
      await controller.loadDeletion('del_1');

      final cancelled = await controller.cancelDeletion();

      expect(cancelled, isNull);
      expect(repository.cancelDeletionCallCount, 0);
      expect(
        controller.state.failure?.code,
        'deletion_cancellation_disallowed',
      );
    });

    test(
      'disallowed cancellation refreshes the latest server status',
      () async {
        repository.configuredDeletion = _deletion();
        await controller.loadDeletion('del_1');

        repository.nextFailure = const AuthFailure(
          code: 'deletion_cancellation_disallowed',
          message: 'This deletion can no longer be cancelled.',
        );
        repository.configuredDeletion = _deletion(
          status: PrivacyRequestStatus.processing,
        );

        await controller.cancelDeletion();

        expect(repository.cancelDeletionCallCount, 1);
        expect(
          controller.state.deletion?.status,
          PrivacyRequestStatus.processing,
        );
        expect(
          controller.state.failure?.code,
          'deletion_cancellation_disallowed',
        );
      },
    );
  });

  group('bootstrap recovery', () {
    test('resolves an export pending summary', () async {
      repository.configuredExport = _export();

      final workflow = await controller.recoverPendingRequest('exp_1');

      expect(workflow, PrivacyWorkflow.export);
      expect(controller.state.export?.id, 'exp_1');
    });

    test('falls back to deletion when export is not found', () async {
      repository.nextFailure = const AuthFailure(
        code: 'not_found',
        message: 'That privacy request was not found.',
      );
      repository.configuredDeletion = _deletion();

      final workflow = await controller.recoverPendingRequest('del_1');

      expect(workflow, PrivacyWorkflow.deletion);
      expect(controller.state.deletion?.id, 'del_1');
    });

    test(
      'deletion 401 during recovery reports an unconfirmed outcome',
      () async {
        repository.nextFailure = const AuthFailure(
          code: 'not_found',
          message: 'That privacy request was not found.',
        );
        repository.failure = AuthFailure.expiredSession();

        final workflow = await controller.recoverPendingRequest('del_1');

        expect(workflow, isNull);
        expect(controller.state.outcomeUnconfirmed, isTrue);
        expect(controller.state.outcomeUnconfirmedRequestId, 'del_1');
        expect(sessionController.state.phase, AppSessionPhase.active);
      },
    );
  });
}
