import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/domain/route_access.dart';

void main() {
  group('SafeReturnLocation Validation and Parsing', () {
    test('Allows safe internal product destinations', () {
      expect(SafeReturnLocation.parse('/home')?.path, equals('/home'));
      expect(SafeReturnLocation.parse('/learning')?.path, equals('/learning'));
      expect(
        SafeReturnLocation.parse('/learning/sbj_physics')?.path,
        equals('/learning/sbj_physics'),
      );
      expect(SafeReturnLocation.parse('/progress')?.path, equals('/progress'));
      expect(SafeReturnLocation.parse('/profile')?.path, equals('/profile'));
      expect(SafeReturnLocation.parse('/catalog')?.path, equals('/catalog'));
      expect(
        SafeReturnLocation.parse('/missions/mis_1/preview')?.path,
        equals('/missions/mis_1/preview'),
      );
    });

    test(
      'Rejects external URLs and scheme-relative targets (anti-open redirect)',
      () {
        expect(SafeReturnLocation.parse('https://evil.example.com'), isNull);
        expect(SafeReturnLocation.parse('http://phishing.site/home'), isNull);
        expect(SafeReturnLocation.parse('//malicious.site/login'), isNull);
        expect(SafeReturnLocation.parse('javascript:alert(1)'), isNull);
        expect(SafeReturnLocation.parse('data:text/html;base64,...'), isNull);
      },
    );

    test('Rejects routes containing tokens, credentials, or user identifiers in parameters', () {
      expect(
        SafeReturnLocation.parse('/home?token=super_secret_token'),
        isNull,
      );
      expect(SafeReturnLocation.parse('/home?TOKEN=123'), isNull);
      expect(SafeReturnLocation.parse('/learning?password=123'), isNull);
      expect(SafeReturnLocation.parse('/profile?secret=my_secret'), isNull);
      expect(SafeReturnLocation.parse('/profile?bearer=jwt_token'), isNull);
      expect(
        SafeReturnLocation.parse('/home?user_id=usr_other_account'),
        isNull,
      );
    });

    test('Rejects auth and splash routes to prevent redirect loops', () {
      expect(SafeReturnLocation.parse('/'), isNull);
      expect(SafeReturnLocation.parse('/auth/sign-in'), isNull);
      expect(SafeReturnLocation.parse('/auth/create-account'), isNull);
      expect(SafeReturnLocation.parse('/auth/recover'), isNull);
      expect(SafeReturnLocation.parse('/onboarding/1'), isNull);
      expect(SafeReturnLocation.parse('/onboarding/2'), isNull);
      expect(SafeReturnLocation.parse('/recovery'), isNull);
    });

    test('Rejects null, empty, or unallowlisted roots', () {
      expect(SafeReturnLocation.parse(null), isNull);
      expect(SafeReturnLocation.parse(''), isNull);
      expect(SafeReturnLocation.parse('   '), isNull);
      expect(SafeReturnLocation.parse('/admin/secrets'), isNull);
      expect(SafeReturnLocation.parse('/debug/backdoor'), isNull);
    });
  });
}
