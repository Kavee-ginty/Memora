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
