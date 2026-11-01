import 'dart:async';
import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memora_mobile/src/design_system/components/button.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/consent/application/consent_controller.dart';
import 'package:memora_mobile/src/features/consent/data/consent_repository.dart';
import 'package:memora_mobile/src/features/consent/domain/consent_policy.dart';
import 'package:memora_mobile/src/features/consent/presentation/consent_review_screen.dart';

const String _termsCopy = 'I accept Terms of Use version 2026-10-01.';
const String _privacyCopy = 'I accept Privacy Notice version 2026-09-15.';

ConsentPolicy _terms() => const ConsentPolicy(
  kind: ConsentPolicyKind.terms,
  wireId: 'terms',
  version: '2026-10-01',
  isRequired: true,
  isCurrent: false,
);

ConsentPolicy _privacy({bool isRequired = true}) => ConsentPolicy(
  kind: ConsentPolicyKind.privacy,
  wireId: 'privacy',
  version: '2026-09-15',
  isRequired: isRequired,
  isCurrent: false,
);

ConsentPolicy _unknownRequired() => const ConsentPolicy(
  kind: ConsentPolicyKind.unknown,
  wireId: 'future_policy',
  version: '2027-01-01',
  isRequired: true,
  isCurrent: false,
);

BootstrapData _bootstrap({bool requiresReview = false}) {
  return BootstrapData(
    accountStatus: AccountStatusDomain.active,
    profileSummary: const ProfileSummaryDomain(
      userId: 'usr_1',
      displayName: 'Amani Perera',
    ),
    consentStatus: ConsentStatusDomain(requiresReview: requiresReview),
    subjects: const <SubjectSummaryDomain>[],
    capabilities: const CapabilityFlagsDomain(),
    serverTime: DateTime.utc(2026, 10, 28),
  );
}

/// Repository whose fetch can be held open to assert the loading state.
class ControlledConsentRepository implements ConsentRepository {
  final Completer<List<ConsentPolicy>> fetchCompleter =
      Completer<List<ConsentPolicy>>();
  int fetchCallCount = 0;

  @override
  Future<List<ConsentPolicy>> fetchConsent({required String accessToken}) {
    fetchCallCount++;
    return fetchCompleter.future;
  }

  @override
  Future<void> acceptConsent({
    required String accessToken,
    required ConsentPolicyKind kind,
    required String wireId,
    required String policyVersion,
    required String idempotencyKey,
  }) async {}
}

void main() {
  const session = AuthSession(accessToken: 'token', userId: 'usr_1');

  Widget buildApp({
    required ConsentRepository repository,
    AppSessionState? initialState,
    bool requiresReview = false,
    bool disableAnimations = false,
    double textScale = 1.0,
    GoRouter? router,
  }) {
    final sessionRepository = MockSessionRepository(
      configuredBootstrap: _bootstrap(requiresReview: requiresReview),
    );
    final authRepository = MockAuthRepository(initialSession: session);

    Widget content;
    if (router != null) {
      content = MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
      );
    } else {
      content = MaterialApp(
        home: const ConsentReviewScreen(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
      );
    }

    return ProviderScope(
      overrides: <Override>[
        consentRepositoryProvider.overrideWithValue(repository),
        sessionControllerProvider.overrideWith(
          (ref) => SessionController(
            authRepository: authRepository,
            sessionRepository: sessionRepository,
            localStorage: AppLocalStorage(InMemorySecureKeyStore()),
            initialState:
                initialState ??
                AppSessionState.active(
                  session: session,
                  bootstrapData: _bootstrap(requiresReview: true),
                ),
          ),
        ),
      ],
      child: content,
    );
  }

  group('ConsentReviewScreen', () {
    testWidgets('shows only server-required policies with exact copy', (
      tester,
    ) async {
      final repository = MockConsentRepository(
        policies: <ConsentPolicy>[_terms(), _privacy(isRequired: false)],
      );

      await tester.pumpWidget(buildApp(repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('Review and accept'), findsOneWidget);
      expect(find.text(_termsCopy), findsOneWidget);
      expect(find.text(_privacyCopy), findsNothing);
      expect(find.textContaining('http'), findsNothing);
      expect(find.textContaining('Terms of Use'), findsOneWidget);
    });

    testWidgets('Continue stays disabled until every policy is accepted', (
      tester,
    ) async {
      final repository = MockConsentRepository(
        policies: <ConsentPolicy>[_terms(), _privacy()],
      );

      await tester.pumpWidget(buildApp(repository: repository));
      await tester.pumpAndSettle();

      MemoraButton continueButton() => tester.widget<MemoraButton>(
        find.widgetWithText(MemoraButton, 'Continue'),
      );

      expect(continueButton().onPressed, isNull);

      await tester.tap(find.byKey(const Key('consent_checkbox_terms')));
      await tester.pump();
      expect(continueButton().onPressed, isNull);

      await tester.tap(find.byKey(const Key('consent_checkbox_privacy')));
      await tester.pump();
      expect(continueButton().onPressed, isNotNull);
    });

    testWidgets('accepting continues to Home with the server policy version', (
      tester,
    ) async {
      final repository = MockConsentRepository(
        policies: <ConsentPolicy>[_terms()],
      );
      final router = GoRouter(
        initialLocation: '/consent',
        routes: <RouteBase>[
          GoRoute(
            path: '/consent',
            builder: (context, state) => const ConsentReviewScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const Scaffold(body: Text('Home destination')),
          ),
        ],
      );

      await tester.pumpWidget(buildApp(repository: repository, router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('consent_checkbox_terms')));
      await tester.pump();
      await tester.tap(find.widgetWithText(MemoraButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Home destination'), findsOneWidget);
      expect(repository.acceptCalls, hasLength(1));
      expect(repository.acceptCalls.single.wireId, 'terms');
      expect(repository.acceptCalls.single.policyVersion, '2026-10-01');
    });

    testWidgets('load failure offers Retry and recovers', (tester) async {
      final repository = MockConsentRepository(
        policies: <ConsentPolicy>[_terms()],
      )..fetchFailure = AuthFailure.networkError();

      await tester.pumpWidget(buildApp(repository: repository));
      await tester.pumpAndSettle();

      expect(
        find.text('We could not load your consent choices'),
        findsOneWidget,
      );
      expect(find.widgetWithText(MemoraButton, 'Retry'), findsOneWidget);
      expect(find.widgetWithText(MemoraButton, 'Sign out'), findsOneWidget);

      repository.fetchFailure = null;
      await tester.tap(find.widgetWithText(MemoraButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Review and accept'), findsOneWidget);
      expect(repository.fetchCallCount, 2);
    });

    testWidgets('unknown required policy fails closed', (tester) async {
      final repository = MockConsentRepository(
        policies: <ConsentPolicy>[_unknownRequired()],
      );

      await tester.pumpWidget(buildApp(repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('Consent needs attention'), findsOneWidget);
      expect(
        find.byKey(const Key('consent_checkbox_future_policy')),
        findsNothing,
      );
      expect(find.widgetWithText(MemoraButton, 'Retry'), findsOneWidget);
      expect(find.widgetWithText(MemoraButton, 'Sign out'), findsOneWidget);
    });

    testWidgets('sign out from the app bar ends the session', (tester) async {
      final repository = MockConsentRepository(
        policies: <ConsentPolicy>[_terms()],
      );

      await tester.pumpWidget(buildApp(repository: repository));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ConsentReviewScreen)),
      );
      await tester.tap(find.text('Sign out').first);
      await tester.pumpAndSettle();

      expect(
        container.read(sessionControllerProvider).phase,
        AppSessionPhase.signedOut,
      );
    });

    testWidgets('loading state respects reduced motion', (tester) async {
      final repository = ControlledConsentRepository();

      await tester.pumpWidget(
        buildApp(repository: repository, disableAnimations: true),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Loading your consent choices…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      repository.fetchCompleter.complete(const <ConsentPolicy>[]);
      await tester.pumpAndSettle();
    });

    testWidgets('320 px width and 200 percent text scale does not overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = MockConsentRepository(
        policies: <ConsentPolicy>[_terms(), _privacy()],
      );

      await tester.pumpWidget(buildApp(repository: repository, textScale: 2.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Review and accept'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('consent_checkbox_privacy')),
        120,
      );
      expect(find.text(_privacyCopy), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('checkbox exposes checked state and policy name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final repository = MockConsentRepository(
        policies: <ConsentPolicy>[_terms()],
      );

      await tester.pumpWidget(buildApp(repository: repository));
      await tester.pumpAndSettle();

      final tile = find.byKey(const Key('consent_checkbox_terms'));
      var semantics = tester.getSemantics(tile).getSemanticsData();
      expect(semantics.label, contains(_termsCopy));
      expect(semantics.flagsCollection.isChecked, CheckedState.isFalse);

      await tester.tap(tile);
      await tester.pump();

      semantics = tester.getSemantics(tile).getSemanticsData();
      expect(semantics.flagsCollection.isChecked, CheckedState.isTrue);

      handle.dispose();
    });
  });
}
