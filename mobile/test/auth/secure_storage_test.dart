import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';

/// Key store that can throw on reads to exercise the failure boundary.
class ThrowingSecureKeyStore implements SecureKeyStore {
  final InMemorySecureKeyStore _inner = InMemorySecureKeyStore();
  bool throwOnRead = false;

  @override
  Future<String?> read(String key) async {
    if (throwOnRead) {
      throw StateError('secure storage unavailable');
    }
    return _inner.read(key);
  }

  @override
  Future<void> write(String key, String value) => _inner.write(key, value);

  @override
  Future<void> delete(String key) => _inner.delete(key);

  @override
  Future<bool> containsKey(String key) => _inner.containsKey(key);

  @override
  Future<void> deleteAll() => _inner.deleteAll();
}

void main() {
  group('Secure Auth Storage Tests', () {
    late InMemorySecureKeyStore keyStore;
    late SecureSupabaseLocalStorage supabaseStorage;
    late AppLocalStorage appStorage;

    setUp(() {
      keyStore = InMemorySecureKeyStore();
      supabaseStorage = SecureSupabaseLocalStorage(keyStore: keyStore);
      appStorage = AppLocalStorage(keyStore);
    });

    test(
      'Persists, checks, and removes Supabase session tokens securely',
      () async {
        expect(await supabaseStorage.hasAccessToken(), isFalse);
        expect(await supabaseStorage.accessToken(), isNull);

        const sessionPayload =
            '{"access_token":"mock_jwt","refresh_token":"mock_refresh",'
            '"user":{"id":"usr_1"}}';
        await supabaseStorage.persistSession(sessionPayload);

        expect(await supabaseStorage.hasAccessToken(), isTrue);
        expect(await supabaseStorage.accessToken(), equals(sessionPayload));

        await supabaseStorage.removePersistedSession();
        expect(await supabaseStorage.hasAccessToken(), isFalse);
        expect(await supabaseStorage.accessToken(), isNull);
      },
    );

    test(
      'Corrupt provider session content is discarded as signed out',
      () async {
        await supabaseStorage.persistSession('not-json-at-all');

        expect(await supabaseStorage.accessToken(), isNull);
        expect(await supabaseStorage.hasAccessToken(), isFalse);
        expect(await keyStore.containsKey('memora_supabase_session'), isFalse);
      },
    );

    test('Incompatible provider session content is discarded', () async {
      await supabaseStorage.persistSession(
        '{"access_token":"","refresh_token":"r","user":{}}',
      );

      expect(await supabaseStorage.accessToken(), isNull);
      expect(await keyStore.containsKey('memora_supabase_session'), isFalse);
    });

    test(
      'A thrown read failure is treated as signed out without crashing',
      () async {
        final throwingStore = ThrowingSecureKeyStore();
        await throwingStore.write(
          'memora_supabase_session',
          '{"access_token":"a","refresh_token":"r","user":{}}',
        );
        throwingStore.throwOnRead = true;

        final storage = SecureSupabaseLocalStorage(keyStore: throwingStore);

        expect(await storage.accessToken(), isNull);
        expect(await storage.hasAccessToken(), isFalse);
      },
    );

    test(
      'Implements PKCE GotrueAsyncStorage get, set, and remove items',
      () async {
        const pkceKey = 'pkce_code_verifier_123';
        const verifier = 'high_entropy_random_verifier_string';

        expect(await supabaseStorage.getItem(key: pkceKey), isNull);

        await supabaseStorage.setItem(key: pkceKey, value: verifier);
        expect(await supabaseStorage.getItem(key: pkceKey), equals(verifier));

        await supabaseStorage.removeItem(key: pkceKey);
        expect(await supabaseStorage.getItem(key: pkceKey), isNull);
      },
    );

    test(
      'Onboarding completion survives session clearing but is resettable',
      () async {
        expect(await appStorage.isOnboardingCompleted(), isFalse);

        await appStorage.setOnboardingCompleted(true);
        expect(await appStorage.isOnboardingCompleted(), isTrue);

        // Clear account-scoped data
        await appStorage.clearAccountScopedData(userId: 'usr_test_1');
        expect(await appStorage.isOnboardingCompleted(), isTrue);

        // Explicit all-clear removes onboarding
        await appStorage.clearAll();
        expect(await appStorage.isOnboardingCompleted(), isFalse);
      },
    );

    test('Invalid onboarding value is deleted rather than ignored', () async {
      await keyStore.write('memora_onboarding_completed', 'yes-please');

      expect(await appStorage.isOnboardingCompleted(), isFalse);
      expect(
        await keyStore.containsKey('memora_onboarding_completed'),
        isFalse,
      );
    });

    test('Account-scoped isolation preserves Account B data when Account A is cleared', () async {
      await keyStore.write('memora_user_data_user_A', 'private_cache_A');
      await keyStore.write('memora_user_data_user_B', 'private_cache_B');

      await appStorage.clearAccountScopedData(userId: 'user_A');

      expect(await keyStore.read('memora_user_data_user_A'), isNull);
      expect(
        await keyStore.read('memora_user_data_user_B'),
        equals('private_cache_B'),
      );
    });
  });
}
