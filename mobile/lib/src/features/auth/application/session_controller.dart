import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../configuration/app_configuration.dart';
import '../data/auth_repository.dart';
import '../data/secure_auth_storage.dart';
import '../data/session_repository.dart';
import '../domain/app_session_state.dart';
import '../domain/route_access.dart';

// --- Riverpod Dependency Providers ---

final appConfigurationProvider = Provider<AppConfiguration>((ref) {
  return AppConfiguration.fromEnvironment();
});

final secureKeyStoreProvider = Provider<SecureKeyStore>((ref) {
  return const FlutterSecureKeyStore();
});

final appLocalStorageProvider = Provider<AppLocalStorage>((ref) {
  final keyStore = ref.watch(secureKeyStoreProvider);
  return AppLocalStorage(keyStore);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return MockSessionRepository();
});

final sessionControllerProvider =
    StateNotifierProvider<SessionController, AppSessionState>((ref) {
      final authRepo = ref.watch(authRepositoryProvider);
      final sessionRepo = ref.watch(sessionRepositoryProvider);
      final localStorage = ref.watch(appLocalStorageProvider);

      final controller = SessionController(
        authRepository: authRepo,
        sessionRepository: sessionRepo,
        localStorage: localStorage,
      );
      controller.initialize();
      return controller;
    });

/// Riverpod StateNotifier controlling the application authentication and session lifecycle.
class SessionController extends StateNotifier<AppSessionState> {
  final AuthRepository authRepository;
  final SessionRepository sessionRepository;
  final AppLocalStorage localStorage;

  StreamSubscription<AuthSession?>? _authSubscription;
  SafeReturnLocation? _pendingReturnLocation;

  SessionController({
    required this.authRepository,
    required this.sessionRepository,
    required this.localStorage,
    AppSessionState initialState = const AppSessionState.unknown(),
  }) : super(initialState) {
    _listenToAuthChanges();
  }

  SafeReturnLocation? get pendingReturnLocation => _pendingReturnLocation;

  void setSafeReturnLocation(SafeReturnLocation? location) {
    _pendingReturnLocation = location;
  }

  SafeReturnLocation? consumeSafeReturnLocation() {
    final location = _pendingReturnLocation;
    _pendingReturnLocation = null;
    return location;
  }

  void _listenToAuthChanges() {
    _authSubscription = authRepository.authStateChanges.listen((session) {
      if (session == null) {
        if (state.phase != AppSessionPhase.signedOut &&
            state.phase != AppSessionPhase.unknown) {
          state = const AppSessionState.signedOut();
        }
      } else if (state.session?.accessToken != session.accessToken) {
        // Session refreshed or changed externally
        bootstrapWithSession(session);
      }
    });
  }

  /// Cold-start initialization resolving persisted session and bootstrap.
  Future<void> initialize() async {
    try {
      final session = await authRepository.getCurrentSession();
      if (session == null) {
        state = const AppSessionState.signedOut();
        return;
      }
      await bootstrapWithSession(session);
    } catch (_) {
      state = AppSessionState.signedOut(failure: AuthFailure.networkError());
    }
  }

  /// Executes Memora bootstrap for an authenticated session.
  Future<void> bootstrapWithSession(AuthSession session) async {
    state = AppSessionState.bootstrapping(session: session);

    try {
      final bootstrapData = await sessionRepository.bootstrapSession(
        accessToken: session.accessToken,
      );

      // Check account status
      if (bootstrapData.accountStatus.isBlocked) {
        state = AppSessionState.blocked(
          session: session,
          failure: AuthFailure(
            code: 'account_blocked',
            message:
                'Your account is currently suspended or deletion requested.',
          ),
          bootstrapData: bootstrapData,
        );
        return;
      }

      state = AppSessionState.active(
        session: session,
        bootstrapData: bootstrapData,
      );
    } on AuthFailure catch (e) {
      if (e.code == 'expired_session') {
        await _clearExpiredSession(session, e);
      } else {
        state = AppSessionState.failure(failure: e, session: session);
      }
    } catch (_) {
      state = AppSessionState.failure(
        failure: AuthFailure.networkError(),
        session: session,
      );
    }
  }

  /// Clears every credential and private local record after a failed refresh.
  ///
  /// The signed-out state is published first so the provider auth-state listener
  /// cannot downgrade the expiry reason, then credentials are removed through the
  /// provider-local sign-out boundary.
  Future<void> handleExpiredSession([AuthFailure? failure]) async {
    final session = state.session;
    final reason = failure ?? AuthFailure.expiredSession();
    if (session == null) {
      state = AppSessionState.signedOut(failure: reason);
      _pendingReturnLocation = null;
      return;
    }
    await _clearExpiredSession(session, reason);
  }

  Future<void> _clearExpiredSession(
    AuthSession session,
    AuthFailure failure,
  ) async {
    state = AppSessionState.signedOut(failure: failure);
    _pendingReturnLocation = null;

    try {
      await authRepository.signOut();
    } catch (_) {
      // Local clearing below still proceeds.
    }

    try {
      await localStorage.clearAccountScopedData(userId: session.userId);
    } catch (_) {
      // Intentionally safe.
    }
  }

  /// Retries bootstrap resolution from a failure state.
  Future<void> retryBootstrap() async {
    final session = state.session ?? await authRepository.getCurrentSession();
    if (session != null) {
      await bootstrapWithSession(session);
    } else {
      state = const AppSessionState.signedOut();
    }
  }

  /// Signs in with email and password and loads bootstrap.
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final session = await authRepository.signInWithEmailPassword(
      email: email,
      password: password,
    );
    await bootstrapWithSession(session);
  }

  /// Creates a new student account and loads bootstrap.
  Future<void> createAccount({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final session = await authRepository.createAccount(
      email: email,
      password: password,
      fullName: fullName,
    );
    await bootstrapWithSession(session);
  }

  /// Initiates OAuth Google sign in.
  Future<void> signInWithGoogle({required String redirectUri}) async {
    await authRepository.signInWithGoogle(redirectUri: redirectUri);
  }

  /// Sends password recovery email.
  Future<void> sendPasswordRecoveryEmail(String email) async {
    await authRepository.sendPasswordRecoveryEmail(email);
  }

  /// Checks if sign-out requires confirmation due to unsynced work.
  bool get requiresSignOutConfirmation =>
      state.hasUnsyncedWork || (state.bootstrapData?.hasPendingWork ?? false);

  /// Safely revokes and clears local credentials.
  ///
  /// Returns `true` if remote revocation succeeded or was not needed,
  /// and `false` if remote revocation failed but local clearing completed.
  Future<bool> signOut({bool force = false}) async {
    final currentSession = state.session;
    bool remoteRevocationSuccess = true;

    if (currentSession != null) {
      try {
        final idempotencyKey = generateUuid();
        await sessionRepository.revokeSession(
          accessToken: currentSession.accessToken,
          idempotencyKey: idempotencyKey,
        );
      } catch (_) {
        remoteRevocationSuccess = false;
      }
    }

    // Always complete local sign-out regardless of server reachability
    await authRepository.signOut();
    if (currentSession != null) {
      await localStorage.clearAccountScopedData(userId: currentSession.userId);
    }
    _pendingReturnLocation = null;

    state = AppSessionState.signedOut(
      failure: remoteRevocationSuccess
          ? null
          : const AuthFailure(
              code: 'remote_revocation_unconfirmed',
              message: 'Signed out locally. Remote revocation could not be confirmed.',
            ),
    );

    return remoteRevocationSuccess;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
