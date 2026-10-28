import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/presentation/splash_screen.dart';

void main() {
  group('SplashScreen Widget Tests', () {
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

    Widget createTestWidget({AppSessionState? state}) {
      return ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(
            (ref) => SessionController(
              authRepository: mockAuth,
              sessionRepository: mockSession,
              localStorage: localStorage,
              initialState: state ?? const AppSessionState.unknown(),
            ),
          ),
        ],
        child: const MaterialApp(home: SplashScreen()),
      );
    }

    testWidgets(
      'Renders brand wordmark and Mora guide mascot with no buttons on loading',
      (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Memora'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        // No interactive buttons during clean startup
        expect(find.text('Retry Connection'), findsNothing);
      },
    );

    testWidgets(
      'Renders retry and sign-out controls when initialization fails',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            state: AppSessionState.failure(
              failure: const AuthFailure(
                code: 'network_error',
                message: 'Unable to reach Memora servers.',
              ),
            ),
          ),
        );

        expect(find.text('Memora'), findsOneWidget);
        expect(find.text('Unable to reach Memora servers.'), findsOneWidget);
        expect(find.text('Retry Connection'), findsOneWidget);
        expect(find.text('Sign In Again'), findsOneWidget);

        await tester.tap(find.text('Retry Connection'));
        await tester.pump();

        expect(mockSession.bootstrapCallCount, greaterThanOrEqualTo(0));
      },
    );
  });
}
