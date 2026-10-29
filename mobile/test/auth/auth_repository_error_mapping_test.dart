import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Supabase authentication error mapping', () {
    test('maps invalid email by stable provider code', () {
      final failure = mapSupabaseAuthException(
        const AuthException(
          'provider wording may change',
          statusCode: '400',
          code: 'email_address_invalid',
        ),
      );

      expect(failure.code, 'invalid_email');
      expect(failure.message, 'Enter a valid email address.');
      expect(failure.retryable, isFalse);
    });

    test('maps email send rate limit by stable provider code', () {
      final failure = mapSupabaseAuthException(
        const AuthException(
          'provider wording may change',
          statusCode: '429',
          code: 'over_email_send_rate_limit',
        ),
      );

      expect(failure.code, 'rate_limited');
      expect(failure.message, 'Too many attempts. Please wait and try again.');
      expect(failure.retryable, isTrue);
    });

    test('keeps HTTP 429 fallback for providers without an error code', () {
      final failure = mapSupabaseAuthException(
        const AuthException('rate limited', statusCode: '429'),
      );

      expect(failure.code, 'rate_limited');
    });
  });
}
