import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/presentation/create_account_screen.dart';

void main() {
  group('CreateAccountScreen Form Validation Tests', () {
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
        child: const MaterialApp(home: CreateAccountScreen()),
      );
    }

    testWidgets(
      'Renders all registration fields and visible password policy before submit',
      (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Welcome to Memora'), findsOneWidget);
        expect(find.text('Full Name'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Re-enter Password'), findsOneWidget);
        expect(find.text('Must be at least 8 characters long'), findsOneWidget);
        expect(find.text('Create Account'), findsOneWidget);
      },
    );

    testWidgets(
      'Mismatched passwords trigger validation error without submitting',
      (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.enterText(
          find.widgetWithText(TextField, 'Enter your full name'),
          'Nuwan Silva',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter your email'),
          'nuwan@test.lk',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter your password'),
          'Password123',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Re-enter your password'),
          'DifferentPassword123',
        );
        await tester.pump();

        await tester.ensureVisible(find.text('Create Account'));
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle();

        expect(find.text('Passwords do not match.'), findsOneWidget);
      },
    );

    testWidgets(
      'Email already in use displays safe non-technical error banner',
      (tester) async {
        mockAuth.shouldFailSignIn = true;
        mockAuth.configuredFailure = AuthFailure.emailAlreadyInUse();

        await tester.pumpWidget(createTestWidget());

        await tester.enterText(
          find.widgetWithText(TextField, 'Enter your full name'),
          'Nuwan Silva',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter your email'),
          'nuwan@test.lk',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter your password'),
          'Password123',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Re-enter your password'),
          'Password123',
        );
        await tester.pump();

        await tester.ensureVisible(find.text('Create Account'));
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle();

        expect(
          find.text('An account with this email already exists.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Unconfirmed email response displays clear check-email verification screen',
      (tester) async {
        mockAuth.shouldFailSignIn = true;
        mockAuth.configuredFailure = AuthFailure.unconfirmedEmail();

        await tester.pumpWidget(createTestWidget());

        await tester.enterText(
          find.widgetWithText(TextField, 'Enter your full name'),
          'Nuwan Silva',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter your email'),
          'nuwan@test.lk',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter your password'),
          'Password123',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Re-enter your password'),
          'Password123',
        );
        await tester.pump();

        await tester.ensureVisible(find.text('Create Account'));
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle();

        expect(find.text('Check your email'), findsOneWidget);
        expect(find.text('Proceed to Sign In'), findsOneWidget);
        expect(
          mockAuth.lastCreateAccountRedirectUri,
          'com.kaveeginty.memora://login-callback',
        );
      },
    );
  });
}
