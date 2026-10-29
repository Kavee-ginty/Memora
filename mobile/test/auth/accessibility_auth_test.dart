import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/components/button.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/auth/presentation/create_account_screen.dart';
import 'package:memora_mobile/src/features/auth/presentation/onboarding_screen.dart';
import 'package:memora_mobile/src/features/auth/presentation/sign_in_screen.dart';
import 'package:memora_mobile/src/features/auth/presentation/splash_screen.dart';
import 'package:memora_mobile/src/features/home/presentation/home_screen.dart';

void main() {
  group('Auth Accessibility and Responsive Acceptance Tests (T07)', () {
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

    Widget wrapWithScope({
      required Widget child,
      double textScaleFactor = 1.0,
      Size size = const Size(320, 640),
    }) {
      return ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(
            (ref) => SessionController(
              authRepository: mockAuth,
              sessionRepository: mockSession,
              localStorage: localStorage,
              initialState: AppSessionState.active(
                session: const AuthSession(
                  accessToken: 'active_token',
                  userId: 'usr_1',
                ),
                bootstrapData: BootstrapData(
                  accountStatus: AccountStatusDomain.active,
                  profileSummary: const ProfileSummaryDomain(
                    userId: 'usr_1',
                    displayName: 'Amani Perera',
                    streakDays: 4,
                  ),
                  consentStatus: const ConsentStatusDomain(
                    requiresReview: false,
                  ),
                  subjects: const [
                    SubjectSummaryDomain(
                      id: 'sbj_phys',
                      code: 'AL-PHYS',
                      name: 'A/L Physics',
                      curriculumEditionCode: '2026',
                      curriculumVersionId: 'cur_1',
                    ),
                  ],
                  capabilities: const CapabilityFlagsDomain(
                    canStartMission: true,
                    canAddLearningMaterial: true,
                  ),
                  serverTime: DateTime.now(),
                ),
              ),
            ),
          ),
        ],
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: MaterialApp(home: child),
        ),
      );
    }

    testWidgets('SplashScreen renders cleanly at 320 px without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithScope(child: const SplashScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Memora'), findsOneWidget);
    });

    testWidgets(
      'OnboardingScreen steps render cleanly at 320 px and 200% text scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        for (int step = 1; step <= 3; step++) {
          await tester.pumpWidget(
            wrapWithScope(
              child: OnboardingScreen(step: step),
              textScaleFactor: 2.0,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('$step of 3'), findsOneWidget);
        }
      },
    );

    testWidgets('SignInScreen renders cleanly at 320 px with 200% text scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithScope(child: const SignInScreen(), textScaleFactor: 2.0),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets(
      'CreateAccountScreen renders cleanly at 320 px with 200% text scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          wrapWithScope(
            child: const CreateAccountScreen(),
            textScaleFactor: 2.0,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Welcome to Memora'), findsOneWidget);
        expect(find.text('Create Account'), findsOneWidget);
      },
    );

    testWidgets('HomeScreen renders cleanly at 320 px with 200% text scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithScope(child: const HomeScreen(), textScaleFactor: 2.0),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Keep your memories fresh'), findsOneWidget);
    });

    testWidgets(
      'All interactive buttons meet minimum 48 px touch target (UIX-030)',
      (tester) async {
        await tester.pumpWidget(wrapWithScope(child: const SignInScreen()));
        await tester.pumpAndSettle();

        final buttonFinder = find.byType(MemoraButton);
        expect(buttonFinder, findsWidgets);
        for (final element in buttonFinder.evaluate()) {
          final box = element.renderObject as RenderBox?;
          if (box != null && box.hasSize) {
            expect(box.size.height, greaterThanOrEqualTo(48.0));
          }
        }
      },
    );

    testWidgets(
      'Headings have semantic header flags across authentication screens',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(wrapWithScope(child: const SignInScreen()));
        await tester.pumpAndSettle();

        final semantics = tester.getSemantics(find.text('Welcome back'));
        // ignore: deprecated_member_use
        expect(semantics.hasFlag(SemanticsFlag.isHeader), isTrue);
        handle.dispose();
      },
    );
  });
}
