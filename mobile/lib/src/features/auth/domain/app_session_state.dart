import 'package:flutter/foundation.dart';

import 'bootstrap_state.dart';

/// Provider-issued authenticated session details.
@immutable
class AuthSession {
  final String accessToken;
  final String? refreshToken;
  final String userId;
  final String? email;

  const AuthSession({
    required this.accessToken,
    this.refreshToken,
    required this.userId,
    this.email,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSession &&
          runtimeType == other.runtimeType &&
          accessToken == other.accessToken &&
          refreshToken == other.refreshToken &&
          userId == other.userId &&
          email == other.email;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, userId, email);
}

/// Safe domain failure representations for authentication and session operations.
@immutable
class AuthFailure {
  final String code;
  final String message;
  final bool retryable;

  const AuthFailure({
    required this.code,
    required this.message,
    this.retryable = false,
  });

  factory AuthFailure.invalidCredentials([String? message]) => AuthFailure(
    code: 'invalid_credentials',
    message:
        message ??
        'Invalid email or password. Please check your input and try again.',
    retryable: false,
  );

  factory AuthFailure.userNotFound([String? message]) => AuthFailure(
    code: 'user_not_found',
    message: message ?? 'No account was found matching those details.',
    retryable: false,
  );

  factory AuthFailure.emailAlreadyInUse([String? message]) => AuthFailure(
    code: 'email_already_in_use',
    message: message ?? 'An account with this email already exists.',
    retryable: false,
  );

  factory AuthFailure.weakPassword([String? message]) => AuthFailure(
    code: 'weak_password',
    message: message ?? 'Password must be at least 8 characters long.',
    retryable: false,
  );

  factory AuthFailure.unconfirmedEmail([String? message]) => AuthFailure(
    code: 'unconfirmed_email',
    message: message ?? 'Please verify your email before signing in.',
    retryable: false,
  );

  factory AuthFailure.expiredSession([String? message]) => AuthFailure(
    code: 'expired_session',
    message: message ?? 'Your session has expired. Please sign in again.',
    retryable: false,
  );

  factory AuthFailure.networkError([String? message]) => AuthFailure(
    code: 'network_error',
    message: message ?? 'Unable to connect to Memora. Please check your connection and try again.',
    retryable: true,
  );

  factory AuthFailure.unknown([String? message]) => AuthFailure(
    code: 'unknown',
    message: message ?? 'An unexpected error occurred. Please try again.',
    retryable: true,
  );

  @override
  String toString() => 'AuthFailure(code: $code, message: $message)';
}

/// High-level lifecycle phase of the student session.
enum AppSessionPhase {
  unknown,
  signedOut,
  bootstrapping,
  active,
  refreshRequired,
  blocked,
  failure,
}

/// Immutable state containing the current session phase, data, and failures.
@immutable
class AppSessionState {
  final AppSessionPhase phase;
  final AuthSession? session;
  final BootstrapData? bootstrapData;
  final AuthFailure? failure;
  final bool hasUnsyncedWork;

  const AppSessionState({
    this.phase = AppSessionPhase.unknown,
    this.session,
    this.bootstrapData,
    this.failure,
    this.hasUnsyncedWork = false,
  });

  const AppSessionState.unknown() : this(phase: AppSessionPhase.unknown);

  const AppSessionState.signedOut({AuthFailure? failure})
    : this(phase: AppSessionPhase.signedOut, failure: failure);

  const AppSessionState.bootstrapping({AuthSession? session})
    : this(phase: AppSessionPhase.bootstrapping, session: session);

  const AppSessionState.active({
    required AuthSession session,
    required BootstrapData bootstrapData,
    bool hasUnsyncedWork = false,
  }) : this(
         phase: AppSessionPhase.active,
         session: session,
         bootstrapData: bootstrapData,
         hasUnsyncedWork: hasUnsyncedWork,
       );

  const AppSessionState.refreshRequired({AuthSession? session})
    : this(phase: AppSessionPhase.refreshRequired, session: session);

  const AppSessionState.blocked({
    required AuthSession session,
    required AuthFailure failure,
    BootstrapData? bootstrapData,
  }) : this(
         phase: AppSessionPhase.blocked,
         session: session,
         failure: failure,
         bootstrapData: bootstrapData,
       );

  const AppSessionState.failure({
    required AuthFailure failure,
    AuthSession? session,
  }) : this(phase: AppSessionPhase.failure, session: session, failure: failure);

  bool get isAuthenticated =>
      phase == AppSessionPhase.active && session != null;
  bool get isBootstrapping => phase == AppSessionPhase.bootstrapping;
  bool get isSignedOut => phase == AppSessionPhase.signedOut;
  bool get isBlocked => phase == AppSessionPhase.blocked;

  AppSessionState copyWith({
    AppSessionPhase? phase,
    AuthSession? session,
    BootstrapData? bootstrapData,
    AuthFailure? failure,
    bool? hasUnsyncedWork,
  }) {
    return AppSessionState(
      phase: phase ?? this.phase,
      session: session ?? this.session,
      bootstrapData: bootstrapData ?? this.bootstrapData,
      failure: failure ?? this.failure,
      hasUnsyncedWork: hasUnsyncedWork ?? this.hasUnsyncedWork,
    );
  }
}
