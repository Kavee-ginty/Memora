import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';

void main() {
  group('SessionController Lifecycle and State Machine Tests', () {
    late MockAuthRepository mockAuth;
    late MockSessionRepository mockSession;
    late InMemorySecureKeyStore keyStore;
    late AppLocalStorage localStorage;
    late SessionController controller;

    setUp(() {
      keyStore = InMemorySecureKeyStore();
      localStorage = AppLocalStorage(keyStore);
      mockAuth = MockAuthRepository();
      mockSession = MockSessionRepository();
      controller = SessionController(
        authRepository: mockAuth,
        sessionRepository: mockSession,
        localStorage: localStorage,
      );
    });

    tearDown(() {
      controller.dispose();
      mockAuth.dispose();
    });

    test('Initializes to signedOut when no provider session exists', () async {
      expect(controller.state.phase, equals(AppSessionPhase.unknown));

      await controller.initialize();

      expect(controller.state.phase, equals(AppSessionPhase.signedOut));
      expect(controller.state.session, isNull);
    });

    test(
      'Initializes to active when valid provider session and bootstrap succeed',
      () async {
        mockAuth.emitSession(
          const AuthSession(
            accessToken: 'valid_token',
            refreshToken: 'valid_refresh',
            userId: 'usr_active_1',
            email: 'student@memora.internal',
          ),
        );

        await controller.initialize();

        expect(controller.state.phase, equals(AppSessionPhase.active));
        expect(controller.state.session?.userId, equals('usr_active_1'));
        expect(
          controller.state.bootstrapData?.accountStatus,
          equals(AccountStatusDomain.active),
        );
      },
    );

    test('Transitions to blocked when account status is suspended', () async {
      mockSession.configuredBootstrap = BootstrapData(
        accountStatus: AccountStatusDomain.suspended,
        profileSummary: const ProfileSummaryDomain(
          userId: 'usr_suspended',
          displayName: 'Suspended User',
        ),
        consentStatus: const ConsentStatusDomain(requiresReview: false),
        subjects: const [],
        capabilities: const CapabilityFlagsDomain(),
        serverTime: DateTime.now(),
      );

      mockAuth.emitSession(
        const AuthSession(
          accessToken: 'suspended_token',
          userId: 'usr_suspended',
        ),
      );

      await controller.initialize();

      expect(controller.state.phase, equals(AppSessionPhase.blocked));
      expect(controller.state.isBlocked, isTrue);
    });

    test(
      'Sign in with valid credentials transitions to bootstrapping then active',
      () async {
        final future = controller.signInWithEmailPassword(
          email: 'student@memora.internal',
          password: 'Password123!',
        );

        await future;

        expect(controller.state.phase, equals(AppSessionPhase.active));
        expect(
          controller.state.session?.email,
          equals('student@memora.internal'),
        );
      },
    );

    test(
      'Sign out clears local credentials and transitions to signedOut',
      () async {
        await controller.signInWithEmailPassword(
          email: 'student@memora.internal',
          password: 'Password123!',
        );
        expect(controller.state.phase, equals(AppSessionPhase.active));

        final success = await controller.signOut();

        expect(success, isTrue);
        expect(controller.state.phase, equals(AppSessionPhase.signedOut));
        expect(controller.state.session, isNull);
        expect(mockSession.revokeCallCount, equals(1));
        expect(mockSession.lastRevokeIdempotencyKey, isNotNull);
      },
    );

    test(
      'Sign out completes locally even when remote revocation fails',
      () async {
        await controller.signInWithEmailPassword(
          email: 'student@memora.internal',
          password: 'Password123!',
        );

        // Force session revoke to throw network error
        mockSession.shouldFailBootstrap = true;
        mockSession.configuredFailure = AuthFailure.networkError();

        final success = await controller.signOut();

        expect(success, isFalse);
        expect(controller.state.phase, equals(AppSessionPhase.signedOut));
        expect(
          controller.state.failure?.code,
          equals('remote_revocation_unconfirmed'),
        );
        expect(controller.state.session, isNull);
      },
    );

    test(
      'Reauthentication refreshes the token without bootstrapping or clearing',
      () async {
        mockAuth.emailSignInUserId = 'usr_1';
        mockAuth.emailSignInEmail = 'student@memora.internal';
        await controller.signInWithEmailPassword(
          email: 'student@memora.internal',
          password: 'Password123!',
        );
        final bootstrapCalls = mockSession.bootstrapCallCount;
        final previousToken = controller.state.session!.accessToken;

        await controller.reauthenticateWithEmailPassword(
          email: 'student@memora.internal',
          password: 'Password123!',
        );

        expect(controller.state.phase, AppSessionPhase.active);
        expect(controller.state.session?.userId, 'usr_1');
        expect(controller.state.session?.accessToken, isNot(previousToken));
        expect(controller.state.bootstrapData, isNotNull);
        expect(mockSession.bootstrapCallCount, bootstrapCalls);
        expect(mockAuth.signOutCallCount, 0);
      },
    );

    test('Reauthentication with another account clears the session', () async {
      await controller.signInWithEmailPassword(
        email: 'student@memora.internal',
        password: 'Password123!',
      );
      mockAuth.emailSignInUserId = 'usr_other';

      await expectLater(
        controller.reauthenticateWithEmailPassword(
          email: 'other@memora.internal',
          password: 'Password123!',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.code,
            'code',
            'reauth_account_mismatch',
          ),
        ),
      );

      expect(controller.state.phase, AppSessionPhase.signedOut);
      expect(controller.state.failure?.code, 'reauth_account_mismatch');
      expect(mockAuth.signOutCallCount, 1);
    });

    test(
      'Google reauthentication applies a same-account provider session',
      () async {
        mockAuth.emitSession(
          const AuthSession(
            accessToken: 'initial_token',
            userId: 'usr_1',
            email: 'student@memora.internal',
          ),
        );
        await controller.initialize();
        final bootstrapCalls = mockSession.bootstrapCallCount;
        mockAuth.googleUserId = 'usr_1';

        await controller.reauthenticateWithGoogle(redirectUri: 'memora://auth');
        await Future<void>.delayed(Duration.zero);

        expect(controller.state.phase, AppSessionPhase.active);
        expect(controller.state.session?.accessToken, 'mock_google_token');
        expect(mockSession.bootstrapCallCount, bootstrapCalls);
      },
    );

    test(
      'Deletion pending projection can be applied and cleared locally',
      () async {
        mockAuth.emitSession(
          const AuthSession(accessToken: 'token_1', userId: 'usr_1'),
        );
        await controller.initialize();

        controller.markDeletionPending('del_1');
        expect(
          controller.state.bootstrapData?.accountStatus,
          AccountStatusDomain.deletionPending,
        );
        expect(
          controller.state.bootstrapData?.pendingPrivacyRequests.single.id,
          'del_1',
        );

        controller.clearDeletionPending(requestId: 'del_1');
        expect(
          controller.state.bootstrapData?.accountStatus,
          AccountStatusDomain.active,
        );
        expect(controller.state.bootstrapData?.pendingPrivacyRequests, isEmpty);
      },
    );

    test(
      'Privacy summaries can be refreshed and cleared without account changes',
      () async {
        mockAuth.emitSession(
          const AuthSession(accessToken: 'token_1', userId: 'usr_1'),
        );
        await controller.initialize();

        controller.upsertPrivacyRequestSummary(
          requestId: 'exp_1',
          status: 'requested',
        );
        expect(
          controller.state.bootstrapData?.pendingPrivacyRequests.single.status,
          'requested',
        );

        controller.upsertPrivacyRequestSummary(
          requestId: 'exp_1',
          status: 'processing',
        );
        expect(
          controller.state.bootstrapData?.pendingPrivacyRequests.single.status,
          'processing',
        );
        expect(
          controller.state.bootstrapData?.accountStatus,
          AccountStatusDomain.active,
        );

        controller.clearPrivacyRequest(requestId: 'exp_1');
        expect(controller.state.bootstrapData?.pendingPrivacyRequests, isEmpty);
        expect(
          controller.state.bootstrapData?.accountStatus,
          AccountStatusDomain.active,
        );
      },
    );

    test(
      'Confirmed deletion clears local credentials without remote revoke',
      () async {
        mockAuth.emitSession(
          const AuthSession(accessToken: 'token_1', userId: 'usr_1'),
        );
        await controller.initialize();
        mockSession.revokeCallCount = 0;

        await controller.clearAfterConfirmedDeletion();

        expect(controller.state.phase, AppSessionPhase.signedOut);
        expect(controller.state.session, isNull);
        expect(mockAuth.signOutCallCount, 1);
        expect(mockSession.revokeCallCount, 0);
      },
    );

    test(
      'Detects when sign-out confirmation is required due to pending work',
      () async {
        expect(controller.requiresSignOutConfirmation, isFalse);

        mockAuth.emitSession(
          const AuthSession(accessToken: 'token_123', userId: 'usr_1'),
        );

        mockSession.configuredBootstrap = BootstrapData(
          accountStatus: AccountStatusDomain.active,
          profileSummary: const ProfileSummaryDomain(
            userId: 'usr_1',
            displayName: 'Student',
          ),
          consentStatus: const ConsentStatusDomain(requiresReview: false),
          subjects: const [],
          pendingUpdates: [
            PendingResourceSummaryDomain(
              id: 'upd_1',
              status: 'uploading',
              updatedAt: DateTime.now(),
            ),
          ],
          capabilities: const CapabilityFlagsDomain(),
          serverTime: DateTime.now(),
        );

        await controller.initialize();
        expect(controller.requiresSignOutConfirmation, isTrue);
      },
    );
  });
}
