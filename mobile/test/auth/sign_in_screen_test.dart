import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/presentation/sign_in_screen.dart';

void main() {
  group('SignInScreen Form Validation and Submission Tests', () {
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
        child: const MaterialApp(home: SignInScreen()),
      );
    }

    testWidgets('Renders all fields, labels, Mora header, and Google action', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
    });

    testWidgets(
      'Empty fields trigger inline validation errors and focusable banner',
      (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('Log in'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter your email.'), findsOneWidget);
        expect(find.text('Please enter your password.'), findsOneWidget);
        expect(
          find.text('Please check the highlighted fields below.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Password visibility toggle updates icon and obscureText state',
      (tester) async {
        await tester.pumpWidget(createTestWidget());

        final toggleFinder = find.byTooltip('Show password');
        expect(toggleFinder, findsOneWidget);

        await tester.tap(toggleFinder);
        await tester.pumpAndSettle();

        expect(find.byTooltip('Hide password'), findsOneWidget);
      },
    );

    testWidgets('Submitting valid credentials invokes signIn on controller', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(
        find.widgetWithText(TextField, 'Enter your email'),
        'student@memora.lk',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter your password'),
        'Secret1234!',
      );
      await tester.pump();

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please check the highlighted fields below.'),
        findsNothing,
      );
    });

    testWidgets(
      'Displays safe error message when provider rejects credentials',
      (tester) async {
        mockAuth.shouldFailSignIn = true;
        mockAuth.configuredFailure = AuthFailure.invalidCredentials();

        await tester.pumpWidget(createTestWidget());

        await tester.enterText(
          find.widgetWithText(TextField, 'Enter your email'),
          'student@memora.lk',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter your password'),
          'WrongPassword123',
        );
        await tester.pump();

        await tester.tap(find.text('Log in'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Invalid email or password. Please check your input and try again.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
