import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memora_mobile/src/app.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/consent/application/consent_controller.dart';
import 'package:memora_mobile/src/features/consent/data/consent_repository.dart';
import 'package:memora_mobile/src/features/consent/domain/consent_policy.dart';
import 'package:memora_mobile/src/routing/app_router.dart';
import 'package:memora_mobile/src/routing/app_routes.dart';

const String subjectId = '11111111-1111-4111-8111-111111111111';
const String otherSubjectId = '22222222-2222-4222-8222-222222222222';
const String missionId = '33333333-3333-4333-8333-333333333333';
const String otherMissionId = '44444444-4444-4444-8444-444444444444';

BootstrapData activeBootstrap({
  bool consentRequiresReview = false,
  String missionStatus = 'planned',
}) {
  return BootstrapData(
    accountStatus: AccountStatusDomain.active,
    profileSummary: const ProfileSummaryDomain(
      userId: 'usr_1',
      displayName: 'Amani Perera',
      streakDays: 5,
    ),
    consentStatus: ConsentStatusDomain(requiresReview: consentRequiresReview),
    subjects: const <SubjectSummaryDomain>[
      SubjectSummaryDomain(
        id: subjectId,
        code: 'AL-PHYS',
        name: 'A/L Physics',
        curriculumEditionCode: '2026',
        curriculumVersionId: 'cur_1',
      ),
    ],
    activeMission: ActiveMissionSummaryDomain(
      id: missionId,
      subjectId: subjectId,
      missionDate: '2026-10-28',
      status: missionStatus,
    ),
    capabilities: const CapabilityFlagsDomain(),
    serverTime: DateTime.utc(2026, 10, 28),
  );
}

void main() {
  group('GoRouter and Guard Integration Matrix Tests', () {
    late MockAuthRepository mockAuth;
    late MockSessionRepository mockSession;
    late MockConsentRepository mockConsent;
    late InMemorySecureKeyStore keyStore;
    late AppLocalStorage localStorage;

    setUp(() {
      keyStore = InMemorySecureKeyStore();
      localStorage = AppLocalStorage(keyStore);
      mockAuth = MockAuthRepository();
      mockSession = MockSessionRepository();
      mockConsent = MockConsentRepository();
    });

    Widget createTestApp({
      AppSessionState initialState = const AppSessionState.unknown(),
      bool onboardingCompleted = true,
      String? initialLocation,
    }) {
      if (onboardingCompleted) {
        keyStore.write('memora_onboarding_completed', 'true');
      }

      return ProviderScope(
        overrides: [
          secureKeyStoreProvider.overrideWithValue(keyStore),
          appLocalStorageProvider.overrideWithValue(localStorage),
          authRepositoryProvider.overrideWithValue(mockAuth),
          sessionRepositoryProvider.overrideWithValue(mockSession),
          consentRepositoryProvider.overrideWithValue(mockConsent),
          routerNotifierProvider.overrideWith(
            (ref) => RouterNotifier(
              ref,
              initialOnboardingCompleted: onboardingCompleted,
            ),
          ),
          sessionControllerProvider.overrideWith(
            (ref) => SessionController(
              authRepository: mockAuth,
              sessionRepository: mockSession,
              localStorage: localStorage,
              initialState: initialState,
            ),
          ),
        ],
        child: const MemoraApp(),
      );
    }

    GoRouter routerOf(WidgetTester tester) {
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MemoraApp)),
      );
      return container.read(appRouterProvider);
    }

    Future<void> goTo(WidgetTester tester, String location) async {
      routerOf(tester).go(location);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Signed out student accessing /home is redirected to /auth/sign-in',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            initialState: const AppSessionState.signedOut(),
            onboardingCompleted: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Welcome back'), findsOneWidget);
        expect(find.text('Log in'), findsOneWidget);
      },
    );

    testWidgets(
      'Signed out student on first launch is routed to onboarding step 1',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            initialState: const AppSessionState.signedOut(),
            onboardingCompleted: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('1 of 3'), findsOneWidget);
        expect(find.text('New memories can fade.'), findsOneWidget);
      },
    );

    testWidgets('Authenticated student accessing root lands on Home shell', (
      tester,
    ) async {
      final activeSession = const AuthSession(
        accessToken: 'active_token',
        userId: 'usr_1',
        email: 'student@memora.internal',
      );
      final bootstrap = BootstrapData(
        accountStatus: AccountStatusDomain.active,
        profileSummary: const ProfileSummaryDomain(
          userId: 'usr_1',
          displayName: 'Amani Perera',
          streakDays: 5,
        ),
        consentStatus: const ConsentStatusDomain(requiresReview: false),
        subjects: const [],
        capabilities: const CapabilityFlagsDomain(),
        serverTime: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestApp(
          initialState: AppSessionState.active(
            session: activeSession,
            bootstrapData: bootstrap,
          ),
          onboardingCompleted: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ready to start learning'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Root shell bottom navigation switches tabs correctly', (
      tester,
    ) async {
      final activeSession = const AuthSession(
        accessToken: 'active_token',
        userId: 'usr_1',
        email: 'student@memora.internal',
      );
      final bootstrap = BootstrapData(
        accountStatus: AccountStatusDomain.active,
        profileSummary: const ProfileSummaryDomain(
          userId: 'usr_1',
          displayName: 'Amani Perera',
          streakDays: 5,
        ),
        consentStatus: const ConsentStatusDomain(requiresReview: false),
        subjects: const [],
        capabilities: const CapabilityFlagsDomain(),
        serverTime: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestApp(
          initialState: AppSessionState.active(
            session: activeSession,
            bootstrapData: bootstrap,
          ),
          onboardingCompleted: true,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Amani Perera'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      // Tap Progress tab
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.text('Seabed and Reef Progress'), findsOneWidget);

      // Tap Home tab
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.text('Ready to start learning'), findsOneWidget);
    });

    testWidgets('Blocked account status displays blocking recovery screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          initialState: AppSessionState.blocked(
            session: const AuthSession(accessToken: 'token', userId: 'usr_b'),
            failure: const AuthFailure(
              code: 'account_blocked',
              message: 'Your account is suspended.',
            ),
            bootstrapData: BootstrapData(
              accountStatus: AccountStatusDomain.suspended,
              profileSummary: const ProfileSummaryDomain(
                userId: 'usr_b',
                displayName: 'Blocked User',
              ),
              consentStatus: const ConsentStatusDomain(requiresReview: false),
              subjects: const [],
              capabilities: const CapabilityFlagsDomain(),
              serverTime: DateTime.now(),
            ),
          ),
          onboardingCompleted: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account Suspended'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('Required consent redirects to the registered /consent route', (
      tester,
    ) async {
      mockConsent = MockConsentRepository(
        policies: const <ConsentPolicy>[
          ConsentPolicy(
            kind: ConsentPolicyKind.terms,
            wireId: 'terms',
            version: '2026-10-01',
            isRequired: true,
            isCurrent: false,
          ),
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          initialState: AppSessionState.active(
            session: const AuthSession(accessToken: 'token', userId: 'usr_1'),
            bootstrapData: activeBootstrap(consentRequiresReview: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review and accept'), findsOneWidget);
      expect(
        find.text('I accept Terms of Use version 2026-10-01.'),
        findsOneWidget,
      );
      expect(find.text('We could not find that page'), findsNothing);
    });

    testWidgets(
      'Signed-out /consent stores a safe return location and shows sign-in',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(initialState: const AppSessionState.signedOut()),
        );
        await tester.pumpAndSettle();

        await goTo(tester, AppRoutes.consent);

        expect(find.text('Welcome back'), findsOneWidget);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MemoraApp)),
        );
        expect(
          container
              .read(sessionControllerProvider.notifier)
              .pendingReturnLocation
              ?.path,
          AppRoutes.consent,
        );
      },
    );

    testWidgets('Signed-out /progress routes through the auth matrix', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(initialState: const AppSessionState.signedOut()),
      );
      await tester.pumpAndSettle();

      await goTo(tester, AppRoutes.progress);

      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('Active /progress renders the progress destination', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          initialState: AppSessionState.active(
            session: const AuthSession(accessToken: 'token', userId: 'usr_1'),
            bootstrapData: activeBootstrap(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await goTo(tester, AppRoutes.progress);

      expect(find.text('Seabed and Reef Progress'), findsOneWidget);
    });

    testWidgets('Valid subject ownership reaches the safe placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          initialState: AppSessionState.active(
            session: const AuthSession(accessToken: 'token', userId: 'usr_1'),
            bootstrapData: activeBootstrap(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await goTo(tester, AppRoutes.learningDetailPath(subjectId));

      expect(find.text('Learning path'), findsWidgets);
      expect(find.text('Back to Learning'), findsOneWidget);
    });

    testWidgets('Wrong-owner and malformed subjects share generic not-found', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          initialState: AppSessionState.active(
            session: const AuthSession(accessToken: 'token', userId: 'usr_1'),
            bootstrapData: activeBootstrap(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await goTo(tester, AppRoutes.learningDetailPath(otherSubjectId));
      expect(find.text('We could not find that page'), findsOneWidget);

      await goTo(tester, '/learning/not-a-uuid');
      expect(find.text('We could not find that page'), findsOneWidget);
    });

    testWidgets('Valid mission preview reaches the safe placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          initialState: AppSessionState.active(
            session: const AuthSession(accessToken: 'token', userId: 'usr_1'),
            bootstrapData: activeBootstrap(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await goTo(tester, AppRoutes.missionPreviewPath(missionId));

      expect(find.text('Mission preview'), findsWidgets);
      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('Wrong-owner mission resolves to generic not-found', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          initialState: AppSessionState.active(
            session: const AuthSession(accessToken: 'token', userId: 'usr_1'),
            bootstrapData: activeBootstrap(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await goTo(tester, AppRoutes.missionPreviewPath(otherMissionId));

      expect(find.text('We could not find that page'), findsOneWidget);
    });

    testWidgets('Invalid mission state returns to the stable Home parent', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          initialState: AppSessionState.active(
            session: const AuthSession(accessToken: 'token', userId: 'usr_1'),
            bootstrapData: activeBootstrap(missionStatus: 'completed'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await goTo(tester, AppRoutes.missionPreviewPath(missionId));

      // The stable parent is Home, which renders the active mission hero.
      expect(find.text('Mission for 2026-10-28'), findsOneWidget);
    });

    testWidgets('Detail placeholder Back returns to the stable root', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          initialState: AppSessionState.active(
            session: const AuthSession(accessToken: 'token', userId: 'usr_1'),
            bootstrapData: activeBootstrap(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await goTo(tester, AppRoutes.learningDetailPath(subjectId));
      await tester.tap(find.text('Back to Learning'));
      await tester.pumpAndSettle();

      expect(find.text('Everyday English'), findsOneWidget);
    });
  });
}
