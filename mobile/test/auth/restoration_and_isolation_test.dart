import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/route_access.dart';

void main() {
  group('State Restoration and Account Isolation Tests', () {
    late InMemorySecureKeyStore persistentStore;

    setUp(() {
      persistentStore = InMemorySecureKeyStore();
    });

    test(
      'Onboarding completion flag survives restart across controller instances',
      () async {
        // First process session
        final storage1 = AppLocalStorage(persistentStore);
        expect(await storage1.isOnboardingCompleted(), isFalse);
        await storage1.setOnboardingCompleted(true);
        expect(await storage1.isOnboardingCompleted(), isTrue);

        // Process recreation: new storage with the same underlying secure store
        final storage2 = AppLocalStorage(persistentStore);
        expect(await storage2.isOnboardingCompleted(), isTrue);
      },
    );

    test(
      'A consumed return location is never replayed after initial consumption',
      () {
        final mockAuth = MockAuthRepository();
        final mockSession = MockSessionRepository();
        final storage = AppLocalStorage(persistentStore);

        final controller = SessionController(
          authRepository: mockAuth,
          sessionRepository: mockSession,
          localStorage: storage,
        );

        final location = SafeReturnLocation.parse('/learning');
        controller.setSafeReturnLocation(location);

        expect(controller.pendingReturnLocation, equals(location));

        final consumed1 = controller.consumeSafeReturnLocation();
        expect(consumed1, equals(location));

        // Second consumption must be null
        final consumed2 = controller.consumeSafeReturnLocation();
        expect(consumed2, isNull);

        controller.dispose();
        mockAuth.dispose();
      },
    );

    test('Cross-account isolation: Account A signing out wipes A data without restoring to B', () async {
      final mockAuth = MockAuthRepository();
      final mockSession = MockSessionRepository();
      final storage = AppLocalStorage(persistentStore);

      final controller = SessionController(
        authRepository: mockAuth,
        sessionRepository: mockSession,
        localStorage: storage,
      );

      // Account A signs in
      await controller.signInWithEmailPassword(
        email: 'userA@memora.lk',
        password: 'PasswordA123',
      );
      final userAId = controller.state.session?.userId;
      expect(userAId, isNotNull);

      // Store private account-scoped data for Account A
      await persistentStore.write(
        'memora_user_data_$userAId',
        'secret_draft_A',
      );
      expect(
        await persistentStore.read('memora_user_data_$userAId'),
        equals('secret_draft_A'),
      );

      // Account A signs out
      await controller.signOut();
      expect(await persistentStore.read('memora_user_data_$userAId'), isNull);

      // Account B signs in
      await controller.signInWithEmailPassword(
        email: 'userB@memora.lk',
        password: 'PasswordB123',
      );
      final userBId = controller.state.session?.userId;
      expect(userBId, isNotNull);
      expect(userBId, isNot(equals(userAId)));

      // Account B has no access to Account A data
      expect(await persistentStore.read('memora_user_data_$userBId'), isNull);

      controller.dispose();
      mockAuth.dispose();
    });

    test('Session restoration always calls fresh bootstrap rather than restoring stale state', () async {
      final mockAuth = MockAuthRepository();
      final mockSession = MockSessionRepository();
      final storage = AppLocalStorage(persistentStore);

      mockAuth.emitSession(
        const AuthSession(accessToken: 'durable_token', userId: 'usr_restore'),
      );

      final controller = SessionController(
        authRepository: mockAuth,
        sessionRepository: mockSession,
        localStorage: storage,
      );

      expect(mockSession.bootstrapCallCount, equals(0));

      await controller.initialize();

      expect(mockSession.bootstrapCallCount, equals(1));
      expect(controller.state.phase, equals(AppSessionPhase.active));

      controller.dispose();
      mockAuth.dispose();
    });
  });
}
