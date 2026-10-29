import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memora_mobile/src/design_system/components/text_field.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/auth/presentation/account_recovery_screen.dart';
import 'package:memora_mobile/src/features/auth/presentation/create_account_screen.dart';
import 'package:memora_mobile/src/features/auth/presentation/onboarding_screen.dart';
import 'package:memora_mobile/src/features/auth/presentation/sign_in_screen.dart';
import 'package:memora_mobile/src/features/auth/presentation/splash_screen.dart';
import 'package:memora_mobile/src/routing/app_router.dart';

BootstrapData _bootstrap({
  AccountStatusDomain accountStatus = AccountStatusDomain.active,
}) {
  return BootstrapData(
    accountStatus: accountStatus,
    profileSummary: const ProfileSummaryDomain(
      userId: 'usr_1',
      displayName: 'Amani Perera',
      streakDays: 4,
    ),
    consentStatus: const ConsentStatusDomain(requiresReview: false),
    subjects: const <SubjectSummaryDomain>[],
    capabilities: const CapabilityFlagsDomain(),
    serverTime: DateTime.utc(2026, 10, 28),
  );
}

void main() {
  const session = AuthSession(accessToken: 'token', userId: 'usr_1');

  Widget wrapWithScope({
    required Widget child,
    AppSessionState? initialState,
    bool disableAnimations = false,
    double textScale = 1.0,
    Size size = const Size(320, 640),
  }) {
    final authRepository = MockAuthRepository(initialSession: session);
    final sessionRepository = MockSessionRepository(
      configuredBootstrap: _bootstrap(),
    );

    return ProviderScope(
      overrides: <Override>[
        sessionControllerProvider.overrideWith(
          (ref) => SessionController(
            authRepository: authRepository,
            sessionRepository: sessionRepository,
            localStorage: AppLocalStorage(InMemorySecureKeyStore()),
            initialState:
                initialState ??
                AppSessionState.active(
                  session: session,
                  bootstrapData: _bootstrap(),
                ),
          ),
        ),
      ],
      child: MaterialApp(
        home: child,
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
            size: size,
          ),
          child: widget!,
        ),
      ),
    );
  }

  group('Auth focus and validation semantics', () {
    testWidgets('Sign in traversal moves email -> password in order', (
      tester,
    ) async {
      await tester.pumpWidget(wrapWithScope(child: const SignInScreen()));
      await tester.pumpAndSettle();

      final fields = tester
          .widgetList<MemoraTextField>(find.byType(MemoraTextField))
          .toList();
      expect(fields, hasLength(2));
      final emailFocus = fields[0].focusNode!;
      final passwordFocus = fields[1].focusNode!;

      await tester.tap(find.byType(MemoraTextField).at(0));
      await tester.pump();
      expect(emailFocus.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(passwordFocus.hasFocus, isTrue);
    });

    testWidgets('Sign in declares the approved traversal order', (
      tester,
    ) async {
      await tester.pumpWidget(wrapWithScope(child: const SignInScreen()));
      await tester.pumpAndSettle();

      final orders = tester
          .widgetList<FocusTraversalOrder>(find.byType(FocusTraversalOrder))
          .map((widget) => (widget.order as NumericFocusOrder).order)
          .toList();

      expect(orders, <double>[1, 2, 3, 4, 5, 6]);
    });

    testWidgets('Create account starts with name then email', (tester) async {
      await tester.pumpWidget(
        wrapWithScope(child: const CreateAccountScreen()),
      );
      await tester.pumpAndSettle();

      final fields = tester
          .widgetList<MemoraTextField>(find.byType(MemoraTextField))
          .toList();
      expect(fields, hasLength(4));
      final nameFocus = fields[0].focusNode!;
      final emailFocus = fields[1].focusNode!;

      await tester.tap(find.byType(MemoraTextField).at(0));
      await tester.pump();
      expect(nameFocus.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(emailFocus.hasFocus, isTrue);
    });

    testWidgets('Create account declares the approved traversal order', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithScope(child: const CreateAccountScreen()),
      );
      await tester.pumpAndSettle();

      final orders = tester
          .widgetList<FocusTraversalOrder>(find.byType(FocusTraversalOrder))
          .map((widget) => (widget.order as NumericFocusOrder).order)
          .toList();

      expect(orders, <double>[1, 2, 3, 4, 5, 6, 7]);
    });

    testWidgets(
      'Sign in validation summary receives focus and is a live region',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(wrapWithScope(child: const SignInScreen()));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Log in'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Log in'));
        await tester.pumpAndSettle();

        final summary = find.byKey(const Key('validation_summary'));
        expect(summary, findsOneWidget);

        final focusNode = tester.widget<Focus>(summary).focusNode!;
        expect(focusNode.hasFocus, isTrue);

        final summarySemantics = find.bySemanticsLabel(
          'Please check the highlighted fields below.',
        );
        expect(summarySemantics, findsOneWidget);
        expect(
          tester
              .getSemantics(summarySemantics)
              .getSemanticsData()
              .flagsCollection
              .isLiveRegion,
          isTrue,
        );
        handle.dispose();
      },
    );

    testWidgets(
      'Create account validation summary receives focus and is live',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          wrapWithScope(child: const CreateAccountScreen()),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Create Account'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle();

        final summary = find.byKey(const Key('validation_summary'));
        expect(summary, findsOneWidget);

        final focusNode = tester.widget<Focus>(summary).focusNode!;
        expect(focusNode.hasFocus, isTrue);

        final summarySemantics = find.bySemanticsLabel(
          'Please check the highlighted fields below.',
        );
        expect(summarySemantics, findsOneWidget);
        expect(
          tester
              .getSemantics(summarySemantics)
              .getSemanticsData()
              .flagsCollection
              .isLiveRegion,
          isTrue,
        );
        handle.dispose();
      },
    );

    testWidgets('Password visibility exposes label, state and value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrapWithScope(child: const SignInScreen()));
      await tester.pumpAndSettle();

      final toggle = find.bySemanticsLabel('Password visibility');
      expect(toggle, findsOneWidget);

      var data = tester.getSemantics(toggle).getSemanticsData();
      expect(data.label, contains('Password visibility'));
      expect(data.value, 'Hidden');
      expect(data.flagsCollection.isToggled, Tristate.isFalse);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();

      data = tester.getSemantics(toggle).getSemanticsData();
      expect(data.value, 'Visible');
      expect(data.flagsCollection.isToggled, Tristate.isTrue);
      handle.dispose();
    });
  });

  group('Reduced motion', () {
    testWidgets('Onboarding indicator animation is immediate', (tester) async {
      await tester.pumpWidget(
        wrapWithScope(
          child: const OnboardingScreen(step: 1),
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      final indicators = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      expect(indicators, isNotEmpty);
      for (final indicator in indicators) {
        expect(indicator.duration, Duration.zero);
      }
    });

    testWidgets('Onboarding indicator animates when motion is allowed', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithScope(child: const OnboardingScreen(step: 1)),
      );
      await tester.pumpAndSettle();

      final indicators = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      expect(
        indicators.any(
          (indicator) =>
              indicator.duration == const Duration(milliseconds: 200),
        ),
        isTrue,
      );
    });

    testWidgets('Route pages drop transitions when motion is reduced', (
      tester,
    ) async {
      late Page<void> page;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Builder(
            builder: (context) {
              page = buildRoutePage(
                context: context,
                key: const ValueKey<String>('route'),
                child: const SizedBox(),
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(page, isA<NoTransitionPage<void>>());
    });

    testWidgets('Route pages keep transitions when motion is allowed', (
      tester,
    ) async {
      late Page<void> page;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              page = buildRoutePage(
                context: context,
                key: const ValueKey<String>('route'),
                child: const SizedBox(),
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(page, isA<MaterialPage<void>>());
    });
  });

  group('Narrow width and large text state matrix', () {
    Future<void> pumpAtNarrowLargeText(
      WidgetTester tester,
      Widget child, {
      AppSessionState? initialState,
    }) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithScope(child: child, initialState: initialState, textScale: 2.0),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    testWidgets('Sign in expired-session notice fits', (tester) async {
      await pumpAtNarrowLargeText(
        tester,
        const SignInScreen(),
        initialState: AppSessionState.signedOut(
          failure: AuthFailure.expiredSession(),
        ),
      );

      expect(
        find.text('Your session expired. Sign in again to continue.'),
        findsOneWidget,
      );
    });

    testWidgets('Sign in validation errors fit', (tester) async {
      await pumpAtNarrowLargeText(tester, const SignInScreen());

      await tester.ensureVisible(find.text('Log in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('validation_summary')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Splash bootstrap failure fits', (tester) async {
      await pumpAtNarrowLargeText(
        tester,
        const SplashScreen(),
        initialState: AppSessionState.failure(
          failure: AuthFailure.networkError(),
        ),
      );

      expect(find.text('Retry Connection'), findsOneWidget);
      expect(find.text('Sign In Again'), findsOneWidget);
    });

    testWidgets('Blocked account recovery fits', (tester) async {
      await pumpAtNarrowLargeText(
        tester,
        const AccountRecoveryScreen(),
        initialState: AppSessionState.blocked(
          session: session,
          failure: const AuthFailure(
            code: 'account_blocked',
            message: 'Your account is currently suspended.',
          ),
          bootstrapData: _bootstrap(
            accountStatus: AccountStatusDomain.suspended,
          ),
        ),
      );

      expect(find.text('Account Suspended'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('Create account validation errors fit', (tester) async {
      await pumpAtNarrowLargeText(tester, const CreateAccountScreen());

      await tester.ensureVisible(find.text('Create Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('validation_summary')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
