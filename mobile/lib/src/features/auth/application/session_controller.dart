import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../configuration/app_configuration.dart';
import '../data/auth_repository.dart';
import '../data/secure_auth_storage.dart';
import '../data/session_repository.dart';
import '../domain/app_session_state.dart';
import '../domain/bootstrap_state.dart';
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

  /// Registered by the T19 push controller while it is alive. Runs before
  /// session revocation so device deletion can use the valid bearer token.
  Future<bool> Function(String accessToken)? revokePushBeforeSignOut;

  StreamSubscription<AuthSession?>? _authSubscription;
  SafeReturnLocation? _pendingReturnLocation;

  /// User whose credentials are being confirmed for a sensitive action.
  ///
  /// While set, a matching provider session replaces only the access token and
  /// never re-runs bootstrap. That keeps a deletion-pending or privacy status
  /// route stable instead of sending the student back through splash.
  String? _reauthExpectedUserId;

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
        _reauthExpectedUserId = null;
        if (state.phase != AppSessionPhase.signedOut &&
            state.phase != AppSessionPhase.unknown) {
          state = const AppSessionState.signedOut();
        }
        return;
      }

      final expectedUserId = _reauthExpectedUserId;
      if (expectedUserId != null) {
        _reauthExpectedUserId = null;
        if (session.userId == expectedUserId) {
          _applyReauthenticatedSession(session);
        } else {
          unawaited(_rejectReauthentication());
        }
        return;
      }

      if (state.session?.accessToken != session.accessToken) {
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
    _reauthExpectedUserId = null;

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
    required String redirectUri,
  }) async {
    final session = await authRepository.createAccount(
      email: email,
      password: password,
      fullName: fullName,
      redirectUri: redirectUri,
    );
    await bootstrapWithSession(session);
  }

  /// Initiates OAuth Google sign in.
  Future<void> signInWithGoogle({required String redirectUri}) async {
    await authRepository.signInWithGoogle(redirectUri: redirectUri);
  }

  /// Sends password recovery email.
  Future<void> sendPasswordRecoveryEmail(
    String email, {
    required String redirectUri,
  }) async {
    await authRepository.sendPasswordRecoveryEmail(
      email,
      redirectUri: redirectUri,
    );
  }

  /// Confirms credentials for a pending sensitive action without bootstrapping.
  ///
  /// The returned provider session must belong to the account already signed in
  /// on this device. A different account is treated as a failed confirmation,
  /// every local credential is cleared and the caller receives a safe failure.
  Future<AuthSession> reauthenticateWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final currentSession = state.session;
    if (currentSession == null) {
      throw AuthFailure.expiredSession();
    }

    _beginReauthentication(currentSession.userId);
    try {
      final session = await authRepository.signInWithEmailPassword(
        email: email.trim(),
        password: password,
      );

      if (session.userId != currentSession.userId) {
        await _rejectReauthentication();
        throw const AuthFailure(
          code: 'reauth_account_mismatch',
          message:
              'That account does not match the account signed in on this '
              'device. Sign in with the original account.',
        );
      }

      _applyReauthenticatedSession(session);
      return session;
    } finally {
      _finishReauthentication(currentSession.userId);
    }
  }

  /// Starts Google confirmation for a pending sensitive action.
  ///
  /// The provider delivers the confirmed session through [authStateChanges].
  /// Until it arrives the pending privacy action remains untouched.
  Future<void> reauthenticateWithGoogle({required String redirectUri}) async {
    final currentSession = state.session;
    if (currentSession == null) {
      throw AuthFailure.expiredSession();
    }

    _beginReauthentication(currentSession.userId);
    try {
      await authRepository.signInWithGoogle(redirectUri: redirectUri);
    } catch (_) {
      _finishReauthentication(currentSession.userId);
      rethrow;
    }
  }

  void _beginReauthentication(String userId) {
    if (_reauthExpectedUserId != null) {
      throw const AuthFailure(
        code: 'reauthentication_in_progress',
        message: 'A confirmation is already in progress. Please wait.',
        retryable: true,
      );
    }
    _reauthExpectedUserId = userId;
  }

  void _finishReauthentication(String userId) {
    if (_reauthExpectedUserId == userId) {
      _reauthExpectedUserId = null;
    }
  }

  void _applyReauthenticatedSession(AuthSession session) {
    if (!mounted) return;
    state = AppSessionState(
      phase: state.phase,
      session: session,
      bootstrapData: state.bootstrapData,
      failure: state.failure,
      hasUnsyncedWork: state.hasUnsyncedWork,
    );
  }

  Future<void> _rejectReauthentication() async {
    if (state.phase == AppSessionPhase.signedOut &&
        state.failure?.code == 'reauth_account_mismatch') {
      return;
    }

    final currentSession = state.session;
    _reauthExpectedUserId = null;
    state = const AppSessionState.signedOut(
      failure: AuthFailure(
        code: 'reauth_account_mismatch',
        message:
            'That account does not match the account signed in on this '
            'device. Sign in with the original account.',
      ),
    );
    _pendingReturnLocation = null;

    try {
      await authRepository.signOut();
    } catch (_) {
      // Local clearing below still proceeds.
    }

    if (currentSession != null) {
      try {
        await localStorage.clearAccountScopedData(
          userId: currentSession.userId,
        );
      } catch (_) {
        // Intentionally safe.
      }
    }
  }

  /// Adds or refreshes a pending privacy summary without changing account
  /// status.
  ///
  /// Bootstrap only returns pending summaries, so this keeps the local overview
  /// truthful after a request is created or its server status changes without
  /// running bootstrap and losing the current route.
  void upsertPrivacyRequestSummary({
    required String requestId,
    required String status,
  }) {
    final data = state.bootstrapData;
    if (data == null) return;

    final pending = data.pendingPrivacyRequests;
    final index = pending.indexWhere((item) => item.id == requestId);
    final summary = PendingResourceSummaryDomain(
      id: requestId,
      status: status,
      updatedAt: DateTime.now().toUtc(),
    );
    final updated = List<PendingResourceSummaryDomain>.of(pending);
    if (index >= 0) {
      updated[index] = summary;
    } else {
      updated.add(summary);
    }

    state = state.copyWith(
      bootstrapData: data.copyWith(pendingPrivacyRequests: updated),
    );
  }

  /// Removes a resolved privacy summary without changing account status.
  void clearPrivacyRequest({required String requestId}) {
    final data = state.bootstrapData;
    if (data == null) return;

    final updated = data.pendingPrivacyRequests
        .where((item) => item.id != requestId)
        .toList(growable: false);
    if (updated.length == data.pendingPrivacyRequests.length) return;

    state = state.copyWith(
      bootstrapData: data.copyWith(pendingPrivacyRequests: updated),
    );
  }

  /// Projects a server-confirmed deletion request into local account state.
  ///
  /// This deliberately avoids bootstrap, which would replace the current route
  /// with splash. The deletion status route remains reachable under the guard's
  /// deletion-pending exception.
  void markDeletionPending(String requestId, {String status = 'requested'}) {
    final data = state.bootstrapData;
    if (data == null) return;

    final pending = data.pendingPrivacyRequests;
    final index = pending.indexWhere((item) => item.id == requestId);
    if (data.accountStatus == AccountStatusDomain.deletionPending &&
        index >= 0 &&
        pending[index].status == status) {
      return;
    }

    final updated = List<PendingResourceSummaryDomain>.of(pending);
    final summary = PendingResourceSummaryDomain(
      id: requestId,
      status: status,
      updatedAt: DateTime.now().toUtc(),
    );
    if (index >= 0) {
      updated[index] = summary;
    } else {
      updated.add(summary);
    }

    state = state.copyWith(
      bootstrapData: data.copyWith(
        accountStatus: AccountStatusDomain.deletionPending,
        pendingPrivacyRequests: updated,
      ),
    );
  }

  /// Reactivates the local account projection after a confirmed cancellation or
  /// terminal failure. The server remains authoritative; this only removes the
  /// blocking status so the student can continue safely.
  void clearDeletionPending({String? requestId}) {
    final data = state.bootstrapData;
    if (data == null) return;

    final updated = requestId == null
        ? data.pendingPrivacyRequests
        : data.pendingPrivacyRequests
              .where((item) => item.id != requestId)
              .toList(growable: false);
    final nextStatus = data.accountStatus == AccountStatusDomain.deletionPending
        ? AccountStatusDomain.active
        : data.accountStatus;

    if (nextStatus == data.accountStatus &&
        updated.length == data.pendingPrivacyRequests.length) {
      return;
    }

    state = state.copyWith(
      bootstrapData: data.copyWith(
        accountStatus: nextStatus,
        pendingPrivacyRequests: updated,
      ),
    );
  }

  /// Clears credentials only after the server confirms deletion with proofs.
  Future<void> clearAfterConfirmedDeletion() async {
    final currentSession = state.session;
    _reauthExpectedUserId = null;
    _pendingReturnLocation = null;
    state = const AppSessionState.signedOut();

    try {
      await authRepository.signOut();
    } catch (_) {
      // Local clearing below still proceeds.
    }

    if (currentSession != null) {
      try {
        await localStorage.clearAccountScopedData(
          userId: currentSession.userId,
        );
      } catch (_) {
        // Intentionally safe.
      }
    }
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
        final revoke = revokePushBeforeSignOut;
        if (revoke != null && !await revoke(currentSession.accessToken)) {
          remoteRevocationSuccess = false;
        }
      } catch (_) {
        remoteRevocationSuccess = false;
      }
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
    _reauthExpectedUserId = null;

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
