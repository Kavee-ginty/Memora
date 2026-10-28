import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_session_state.dart';

/// Contract for authentication operations.
abstract class AuthRepository {
  Stream<AuthSession?> get authStateChanges;
  Future<AuthSession?> getCurrentSession();
  Future<AuthSession> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<AuthSession> createAccount({
    required String email,
    required String password,
    required String fullName,
  });
  Future<void> signInWithGoogle({required String redirectUri});
  Future<void> sendPasswordRecoveryEmail(String email);
  Future<AuthSession?> refreshSession();
  Future<void> signOut();
}

/// Supabase Flutter implementation of [AuthRepository].
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Stream<AuthSession?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) {
      final session = data.session;
      if (session == null) return null;
      return _mapSession(session);
    });
  }

  @override
  Future<AuthSession?> getCurrentSession() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;
    return _mapSession(session);
  }

  @override
  Future<AuthSession> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final session = response.session;
      if (session == null) {
        throw AuthFailure.invalidCredentials();
      }
      return _mapSession(session);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure.networkError();
    }
  }

  @override
  Future<AuthSession> createAccount({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, dynamic>{'full_name': fullName.trim()},
      );
      final session = response.session;
      if (session == null) {
        // Confirmation email may be required
        if (response.user != null) {
          throw AuthFailure.unconfirmedEmail();
        }
        throw AuthFailure.invalidCredentials();
      }
      return _mapSession(session);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure.networkError();
    }
  }

  @override
  Future<void> signInWithGoogle({required String redirectUri}) async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUri,
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthFailure.networkError();
    }
  }

  @override
  Future<void> sendPasswordRecoveryEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      // In accordance with security specifications, do not expose whether
      // an account exists; allow request to complete safely unless rate limited.
      if (e.statusCode == '429') {
        throw const AuthFailure(
          code: 'rate_limited',
          message: 'Too many requests. Please wait before trying again.',
        );
      }
    } catch (_) {
      throw AuthFailure.networkError();
    }
  }

  @override
  Future<AuthSession?> refreshSession() async {
    try {
      final response = await _client.auth.refreshSession();
      final session = response.session;
      if (session == null) return null;
      return _mapSession(session);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // Intentionally safe
    }
  }

  AuthSession _mapSession(Session session) {
    return AuthSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      userId: session.user.id,
      email: session.user.email,
    );
  }

  AuthFailure _mapAuthException(AuthException exception) {
    final msg = exception.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_grant')) {
      return AuthFailure.invalidCredentials();
    }
    if (msg.contains('user not found') || msg.contains('not found')) {
      return AuthFailure.userNotFound();
    }
    if (msg.contains('already registered') ||
        msg.contains('already in use') ||
        msg.contains('user already exists')) {
      return AuthFailure.emailAlreadyInUse();
    }
    if (msg.contains('password') &&
        (msg.contains('weak') || msg.contains('least'))) {
      return AuthFailure.weakPassword();
    }
    if (msg.contains('email not confirmed') ||
        msg.contains('confirm your email')) {
      return AuthFailure.unconfirmedEmail();
    }
    if (exception.statusCode == '429') {
      return const AuthFailure(
        code: 'rate_limited',
        message: 'Too many attempts. Please try again in a few minutes.',
      );
    }
    return AuthFailure.unknown();
  }
}

/// In-memory mock [AuthRepository] for deterministic testing.
class MockAuthRepository implements AuthRepository {
  final StreamController<AuthSession?> _controller =
      StreamController<AuthSession?>.broadcast();
  AuthSession? _currentSession;
  bool shouldFailSignIn = false;
  bool shouldFailRefresh = false;
  int signOutCallCount = 0;
  AuthFailure? configuredFailure;

  MockAuthRepository({AuthSession? initialSession})
    : _currentSession = initialSession;

  void emitSession(AuthSession? session) {
    _currentSession = session;
    _controller.add(session);
  }

  @override
  Stream<AuthSession?> get authStateChanges => _controller.stream;

  @override
  Future<AuthSession?> getCurrentSession() async => _currentSession;

  @override
  Future<AuthSession> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (shouldFailSignIn) {
      throw configuredFailure ?? AuthFailure.invalidCredentials();
    }
    final session = AuthSession(
      accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock_refresh_token',
      userId: 'mock_user_${email.hashCode.abs()}',
      email: email,
    );
    emitSession(session);
    return session;
  }

  @override
  Future<AuthSession> createAccount({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (shouldFailSignIn) {
      throw configuredFailure ?? AuthFailure.emailAlreadyInUse();
    }
    final session = AuthSession(
      accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock_refresh_token',
      userId: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
    );
    emitSession(session);
    return session;
  }

  @override
  Future<void> signInWithGoogle({required String redirectUri}) async {
    if (shouldFailSignIn) {
      throw configuredFailure ?? AuthFailure.networkError();
    }
    final session = const AuthSession(
      accessToken: 'mock_google_token',
      refreshToken: 'mock_google_refresh',
      userId: 'mock_google_user',
      email: 'student@memora.internal',
    );
    emitSession(session);
  }

  @override
  Future<void> sendPasswordRecoveryEmail(String email) async {
    if (shouldFailSignIn) {
      throw configuredFailure ?? AuthFailure.networkError();
    }
  }

  @override
  Future<AuthSession?> refreshSession() async {
    if (shouldFailRefresh || _currentSession == null) {
      return null;
    }
    final refreshed = AuthSession(
      accessToken:
          'refreshed_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: _currentSession!.refreshToken,
      userId: _currentSession!.userId,
      email: _currentSession!.email,
    );
    emitSession(refreshed);
    return refreshed;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    emitSession(null);
  }

  void dispose() {
    _controller.close();
  }
}
