import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/app.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/route_access.dart';
import 'package:memora_mobile/src/routing/app_router.dart';

/// Auth repository that clears the persisted provider session like the real
/// Supabase local sign-out boundary does.
class StorageClearingAuthRepository implements AuthRepository {
  StorageClearingAuthRepository(this.storage);

  final SecureSupabaseLocalStorage storage;
  final StreamController<AuthSession?> _controller =
      StreamController<AuthSession?>.broadcast();
  AuthSession? _session;
  int signOutCallCount = 0;

  @override
  Stream<AuthSession?> get authStateChanges => _controller.stream;

  @override
  Future<AuthSession?> getCurrentSession() async => _session;

  void setSession(AuthSession? session) {
    _session = session;
  }

  @override
  Future<AuthSession> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<AuthSession> createAccount({
    required String email,
    required String password,
    required String fullName,
  }) async => throw UnimplementedError();

  @override
  Future<void> signInWithGoogle({required String redirectUri}) async {}

  @override
  Future<void> sendPasswordRecoveryEmail(String email) async {}

  @override
  Future<AuthSession?> refreshSession() async => null;

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    _session = null;
    await storage.removePersistedSession();
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('Expired session clearing and sign-in notice', () {
    late InMemorySecureKeyStore keyStore;
    late SecureSupabaseLocalStorage supabaseStorage;
    late AppLocalStorage localStorage;
    late MockSessionRepository mockSession;
    late StorageClearingAuthRepository authRepository;
    late SessionController controller;

    const session = AuthSession(
      accessToken: 'expired_access_token',
      refreshToken: 'expired_refresh_token',
      userId: 'usr_expired_1',
      email: 'student@memora.internal',
    );

    setUp(() async {
      keyStore = InMemorySecureKeyStore();
      supabaseStorage = SecureSupabaseLocalStorage(keyStore: keyStore);
      localStorage = AppLocalStorage(keyStore);
      mockSession = MockSessionRepository();
      authRepository = StorageClearingAuthRepository(supabaseStorage);
      authRepository.setSession(session);

      await supabaseStorage.persistSession(
        '{"access_token":"expired_access_token","refresh_token":"expired_refresh_token"}',
      );
      await keyStore.write('memora_user_data_usr_expired_1', 'private_draft');

      controller = SessionController(
        authRepository: authRepository,
        sessionRepository: mockSession,
        localStorage: localStorage,
      );
    });

    tearDown(() {
      controller.dispose();
      authRepository.dispose();
    });

    test(
      'Failed refresh clears credentials, private state and return location',
      () async {
        mockSession.should401 = true;
        controller.setSafeReturnLocation(SafeReturnLocation.parse('/learning'));

        await controller.bootstrapWithSession(session);
        await Future<void>.delayed(Duration.zero);

        expect(controller.state.phase, equals(AppSessionPhase.signedOut));
        expect(controller.state.failure?.code, equals('expired_session'));
        expect(controller.state.session, isNull);
        expect(controller.state.bootstrapData, isNull);
        expect(controller.pendingReturnLocation, isNull);
        expect(await supabaseStorage.hasAccessToken(), isFalse);
        expect(await keyStore.read('memora_user_data_usr_expired_1'), isNull);
      },
    );

    test(
      'Failed refresh invokes provider-local sign-out exactly once',
      () async {
        mockSession.should401 = true;

        await controller.bootstrapWithSession(session);
        await Future<void>.delayed(Duration.zero);

        expect(authRepository.signOutCallCount, equals(1));
      },
    );

    test(
      'Explicit sign-out clears provider credentials when revoke fails',
      () async {
        await controller.bootstrapWithSession(session);
        expect(controller.state.phase, equals(AppSessionPhase.active));

        mockSession.shouldFailBootstrap = true;
        mockSession.configuredFailure = AuthFailure.networkError();

        final success = await controller.signOut();

        expect(success, isFalse);
        expect(controller.state.phase, equals(AppSessionPhase.signedOut));
        expect(await supabaseStorage.hasAccessToken(), isFalse);
        expect(authRepository.signOutCallCount, equals(1));
      },
    );

    testWidgets('Sign-in shows the expiry message once and announces it once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureKeyStoreProvider.overrideWithValue(keyStore),
            appLocalStorageProvider.overrideWithValue(localStorage),
            authRepositoryProvider.overrideWithValue(authRepository),
            sessionRepositoryProvider.overrideWithValue(mockSession),
            routerNotifierProvider.overrideWith(
              (ref) => RouterNotifier(ref, initialOnboardingCompleted: true),
            ),
            sessionControllerProvider.overrideWith(
              (ref) => SessionController(
                authRepository: authRepository,
                sessionRepository: mockSession,
                localStorage: localStorage,
                initialState: const AppSessionState.signedOut(
                  failure: AuthFailure(
                    code: 'expired_session',
                    message: 'Your session expired. Sign in again to continue.',
                  ),
                ),
              ),
            ),
          ],
          child: const MemoraApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(
        find.text('Your session expired. Sign in again to continue.'),
        findsOneWidget,
      );

      // Unrelated rebuilds must not duplicate or re-insert the notice.
      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Hide password'));
      await tester.pumpAndSettle();

      expect(
        find.text('Your session expired. Sign in again to continue.'),
        findsOneWidget,
      );

      final semantics = tester.getSemantics(
        find.byKey(const Key('session_expired_notice')),
      );
      expect(semantics.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });
  });
}
