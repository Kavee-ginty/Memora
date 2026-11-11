import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract key-value store for secure encrypted storage.
abstract class SecureKeyStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<bool> containsKey(String key);
  Future<void> deleteAll();
}

/// Production implementation using [FlutterSecureStorage].
class FlutterSecureKeyStore implements SecureKeyStore {
  final FlutterSecureStorage _storage;

  const FlutterSecureKeyStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

/// Test and transient in-memory implementation of [SecureKeyStore].
class InMemorySecureKeyStore implements SecureKeyStore {
  final Map<String, String> _data = <String, String>{};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);

  @override
  Future<void> deleteAll() async {
    _data.clear();
  }
}

/// Custom secure storage adapter for Supabase Flutter.
///
/// Implements both [LocalStorage] and [GotrueAsyncStorage] to persist session
/// credentials and PKCE code verifiers securely without shared preferences.
class SecureSupabaseLocalStorage extends LocalStorage
    implements GotrueAsyncStorage {
  final SecureKeyStore keyStore;
  final String persistSessionKey;

  const SecureSupabaseLocalStorage({
    required this.keyStore,
    this.persistSessionKey = 'memora_supabase_session',
  });

  @override
  Future<void> initialize() async {
    // No-op for secure key store
  }

  @override
  Future<bool> hasAccessToken() async {
    return await accessToken() != null;
  }

  @override
  Future<String?> accessToken() async {
    try {
      final raw = await keyStore.read(persistSessionKey);
      if (raw == null) {
        return null;
      }
      if (!_isCompatibleSession(raw)) {
        // Corrupt or incompatible provider content is discarded and treated as
        // signed out. It is never exposed or re-read.
        await removePersistedSession();
        return null;
      }
      return raw;
    } catch (_) {
      // Safe fallback: corrupted storage is cleared.
      await removePersistedSession();
      return null;
    }
  }

  /// Validates the minimal Supabase session envelope before handing it back to
  /// the provider. Unknown additive fields are allowed.
  bool _isCompatibleSession(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return false;
      }
      final accessToken = decoded['access_token'];
      final refreshToken = decoded['refresh_token'];
      final user = decoded['user'];
      return accessToken is String &&
          accessToken.isNotEmpty &&
          refreshToken is String &&
          refreshToken.isNotEmpty &&
          user is Map;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await keyStore.write(persistSessionKey, persistSessionString);
    } catch (_) {
      // Intentionally safe
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await keyStore.delete(persistSessionKey);
    } catch (_) {
      // Intentionally safe
    }
  }

  // GotrueAsyncStorage implementation for PKCE
  @override
  Future<String?> getItem({required String key}) async {
    try {
      return await keyStore.read(key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    try {
      await keyStore.write(key, value);
    } catch (_) {
      // Intentionally safe
    }
  }

  @override
  Future<void> removeItem({required String key}) async {
    try {
      await keyStore.delete(key);
    } catch (_) {
      // Intentionally safe
    }
  }
}

/// App preferences and account-scoped storage manager.
class AppLocalStorage {
  static const String _onboardingKey = 'memora_onboarding_completed';
  static const String _accountScopePrefix = 'memora_user_data_';

  final SecureKeyStore _keyStore;

  AppLocalStorage(this._keyStore);

  Future<void> _profileWrites = Future<void>.value();

  String _profileKey(String userId) =>
      'memora_profile_${Uri.encodeComponent(userId)}';

  Future<String?> readProfileCache(String userId) async {
    await _profileWrites;
    return _keyStore.read(_profileKey(userId));
  }

  Future<void> writeProfileCache(String userId, String value) =>
      _queueProfileWrite(() => _keyStore.write(_profileKey(userId), value));

  Future<void> clearProfileCache(String userId) =>
      _queueProfileWrite(() => _keyStore.delete(_profileKey(userId)));

  Future<void> _queueProfileWrite(Future<void> Function() write) {
    final pending = _profileWrites.then((_) => write());
    _profileWrites = pending.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return pending;
  }

  Future<bool> isOnboardingCompleted() async {
    try {
      final value = await _keyStore.read(_onboardingKey);
      if (value == null) {
        return false;
      }
      if (value != 'true' && value != 'false') {
        // Remove an invalid schema value instead of repeatedly ignoring it.
        await _keyStore.delete(_onboardingKey);
        return false;
      }
      return value == 'true';
    } catch (_) {
      try {
        await _keyStore.delete(_onboardingKey);
      } catch (_) {
        // Intentionally safe.
      }
      return false;
    }
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    try {
      await _keyStore.write(_onboardingKey, completed ? 'true' : 'false');
    } catch (_) {
      // Intentionally safe
    }
  }

  /// Clears account-scoped cache and tokens while preserving non-sensitive
  /// onboarding completion state.
  Future<void> clearAccountScopedData({String? userId}) async {
    if (userId == null) return;
    try {
      await clearProfileCache(userId);
    } catch (_) {
      // Proceed with the remaining account cleanup.
    }
    try {
      await _keyStore.delete('$_accountScopePrefix$userId');
    } catch (_) {
      // Intentionally safe
    }
  }

  /// Completely clears all stored credentials and preferences.
  Future<void> clearAll() async {
    try {
      await _queueProfileWrite(_keyStore.deleteAll);
    } catch (_) {
      // Intentionally safe
    }
  }
}
