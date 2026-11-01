import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/presentation/onboarding_screen.dart';

void main() {
  group('OnboardingScreen Multi-Step Widget Tests', () {
    late InMemorySecureKeyStore keyStore;
    late AppLocalStorage localStorage;

    setUp(() {
      keyStore = InMemorySecureKeyStore();
      localStorage = AppLocalStorage(keyStore);
    });

    Widget createTestWidget({int step = 1}) {
      final router = GoRouter(
        initialLocation: '/onboarding/$step',
        routes: [
          GoRoute(
            path: '/onboarding/:step',
            builder: (context, state) {
              final s = int.tryParse(state.pathParameters['step'] ?? '1') ?? 1;
              return OnboardingScreen(step: s);
            },
          ),
          GoRoute(
            path: '/auth/sign-in',
            builder: (context, state) =>
                const Scaffold(body: Text('Sign In Screen')),
          ),
          GoRoute(
            path: '/auth/create-account',
            builder: (context, state) =>
                const Scaffold(body: Text('Create Account Screen')),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          secureKeyStoreProvider.overrideWithValue(keyStore),
          appLocalStorageProvider.overrideWithValue(localStorage),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('Renders Step 1 with exact specification copy', (tester) async {
      await tester.pumpWidget(createTestWidget(step: 1));
      await tester.pumpAndSettle();

      expect(find.text('1 of 3'), findsOneWidget);
      expect(find.text('New memories can fade.'), findsOneWidget);
      expect(
        find.text(
          'That is normal. A quick review at the right time helps bring them back.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Illustrative curve · not measured data'),
        findsOneWidget,
      );
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip onboarding'), findsOneWidget);
    });

    testWidgets('Renders Step 2 with exact specification copy', (tester) async {
      await tester.pumpWidget(createTestWidget(step: 2));
      await tester.pumpAndSettle();

      expect(find.text('2 of 3'), findsOneWidget);
      expect(find.text('Come back before it fades.'), findsOneWidget);
      expect(
        find.text(
          'Memora schedules short reviews when they can help most. Timing adapts as you learn.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'A starting point, not a deadline. Timing varies by learner and material.',
        ),
        findsOneWidget,
      );
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Renders Step 3 with exact specification copy', (tester) async {
      await tester.pumpWidget(createTestWidget(step: 3));
      await tester.pumpAndSettle();

      expect(find.text('3 of 3'), findsOneWidget);
      expect(
        find.text('Small reviews grow something lasting.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Protect memories to help each subject reef recover and thrive. What you earn stays yours.',
        ),
        findsOneWidget,
      );
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('I already have an account'), findsOneWidget);
    });

    testWidgets('Removes every universal 24-hour timing promise', (
      tester,
    ) async {
      final forbidden = <String>[
        '~24 hours',
        'within about 24 hours',
        'Come back within a day',
        'within a day',
      ];

      for (int step = 1; step <= 3; step++) {
        await tester.pumpWidget(createTestWidget(step: step));
        await tester.pumpAndSettle();

        for (final phrase in forbidden) {
          expect(
            find.textContaining(phrase, findRichText: true),
            findsNothing,
            reason: 'Step $step must not promise universal timing: $phrase',
          );
        }
        expect(find.textContaining('24 hours'), findsNothing);
      }
    });

    testWidgets(
      'Tapping Skip onboarding saves completion flag and routes to sign-in',
      (tester) async {
        await tester.pumpWidget(createTestWidget(step: 1));
        await tester.pumpAndSettle();

        expect(await localStorage.isOnboardingCompleted(), isFalse);

        await tester.ensureVisible(find.text('Skip onboarding'));
        await tester.tap(find.text('Skip onboarding'));
        await tester.pumpAndSettle();

        expect(await localStorage.isOnboardingCompleted(), isTrue);
        expect(find.text('Sign In Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Create account on Step 3 saves completion flag and routes',
      (tester) async {
        await tester.pumpWidget(createTestWidget(step: 3));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Create account'));
        await tester.tap(find.text('Create account'));
        await tester.pumpAndSettle();

        expect(await localStorage.isOnboardingCompleted(), isTrue);
        expect(find.text('Create Account Screen'), findsOneWidget);
      },
    );
  });
}
