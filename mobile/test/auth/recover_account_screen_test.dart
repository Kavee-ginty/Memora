import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/presentation/recover_account_screen.dart';

void main() {
  group('RecoverAccountScreen Privacy and Confirmation Tests', () {
    late MockAuthRepository mockAuth;
    late MockSessionRepository mockSession;
    late InMemorySecureKeyStore keyStore;
    late AppLocalStorage localStorage;

    setUp(() {
      keyStore = InMemorySecureKeyStore();
      localStorage = AppLocalStorage(keyStore);
      mockAuth = MockAuthRepository();
      mockSession = MockSessionRepository();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(
            (ref) => SessionController(
              authRepository: mockAuth,
              sessionRepository: mockSession,
              localStorage: localStorage,
            ),
          ),
        ],
        child: const MaterialApp(home: RecoverAccountScreen()),
      );
    }

    testWidgets('Renders recovery email form and instructions', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Recover your account'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Send Recovery Link'), findsOneWidget);
    });

    testWidgets(
      'Submitting valid email displays safe message without leaking user existence',
      (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.enterText(
          find.widgetWithText(TextField, 'Enter your email'),
          'student@test.lk',
        );
        await tester.pump();

        await tester.tap(find.text('Send Recovery Link'));
        await tester.pumpAndSettle();

        expect(find.text('Recovery link sent'), findsOneWidget);
        expect(
          find.text(
            'If an account with that email address exists, we have sent instructions to reset your password.',
          ),
          findsOneWidget,
        );
        expect(find.text('Return to Sign In'), findsOneWidget);
      },
    );
  });
}
