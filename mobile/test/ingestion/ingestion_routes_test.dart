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
import 'package:memora_mobile/src/features/auth/domain/route_access.dart';
import 'package:memora_mobile/src/features/consent/application/consent_controller.dart';
import 'package:memora_mobile/src/features/consent/data/consent_repository.dart';
import 'package:memora_mobile/src/routing/app_router.dart';
import 'package:memora_mobile/src/routing/app_routes.dart';
import 'package:memora_mobile/src/routing/route_guard.dart';

const String _subjectId = '11111111-1111-4111-8111-111111111111';
const String _otherSubjectId = '22222222-2222-4222-8222-222222222222';

BootstrapData _bootstrap() {
  return BootstrapData(
    accountStatus: AccountStatusDomain.active,
    profileSummary: const ProfileSummaryDomain(
      userId: 'usr_1',
      displayName: 'Amani Perera',
      activeSubjectId: _subjectId,
    ),
    consentStatus: const ConsentStatusDomain(requiresReview: false),
    subjects: const <SubjectSummaryDomain>[
      SubjectSummaryDomain(
        id: _subjectId,
        code: 'AL-PHYS',
        name: 'A/L Physics',
        curriculumEditionCode: '2026',
        curriculumVersionId: 'cur_1',
      ),
    ],
    capabilities: const CapabilityFlagsDomain(),
    serverTime: DateTime.utc(2026, 11, 1),
  );
}

RouteAccessResult _evaluate({
  required String location,
  AppSessionPhase phase = AppSessionPhase.active,
  BootstrapData? bootstrap,
  bool consentRequiresReview = false,
}) {
  return evaluateRouteAccess(
    sessionPhase: phase,
    currentLocation: location,
    onboardingCompleted: true,
    consentRequiresReview: consentRequiresReview,
    bootstrapData: bootstrap,
  );
}

void main() {
  group('Add-material route guard', () {
    test('an owned subject may open the add-material destination', () {
      final result = _evaluate(
        location: AppRoutes.addMaterialPath(_subjectId),
        bootstrap: _bootstrap(),
      );

      expect(result.isAllowed, isTrue);
    });

    test('a wrong-owner subject is indistinguishable from a missing one', () {
      final wrongOwner = _evaluate(
        location: AppRoutes.addMaterialPath(_otherSubjectId),
        bootstrap: _bootstrap(),
      );
      final missingBootstrap = _evaluate(
        location: AppRoutes.addMaterialPath(_subjectId),
      );

      expect(wrongOwner.type, RouteAccessType.resourceNotFound);
      expect(wrongOwner.recoveryPath, AppRoutes.notFound);
      expect(missingBootstrap.type, RouteAccessType.resourceNotFound);
    });

    test('a malformed subject id is rejected before any lookup', () {
      final result = _evaluate(
        location: '/learning/not-a-uuid/material/new',
        bootstrap: _bootstrap(),
      );

      expect(result.type, RouteAccessType.malformedRoute);
      expect(result.recoveryPath, AppRoutes.notFound);
    });

    test('an unknown extra learning segment is malformed', () {
      final result = _evaluate(
        location: '/learning/$_subjectId/unknown',
        bootstrap: _bootstrap(),
      );

      expect(result.type, RouteAccessType.malformedRoute);
    });

    test('signed-out access requires sign-in with a safe return location', () {
      final result = _evaluate(
        location: AppRoutes.addMaterialPath(_subjectId),
        phase: AppSessionPhase.signedOut,
        bootstrap: _bootstrap(),
      );

      expect(result.type, RouteAccessType.signInRequired);
      expect(
        result.returnLocation?.path,
        AppRoutes.addMaterialPath(_subjectId),
      );
    });

    test('consent review blocks the destination', () {
      final result = _evaluate(
        location: AppRoutes.addMaterialPath(_subjectId),
        bootstrap: _bootstrap(),
        consentRequiresReview: true,
      );

      expect(result.type, RouteAccessType.consentReviewRequired);
      expect(result.recoveryPath, AppRoutes.consent);
    });
  });

  group('Add-material router integration', () {
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

    Widget createTestApp() {
      keyStore.write('memora_onboarding_completed', 'true');
      return ProviderScope(
        overrides: [
          secureKeyStoreProvider.overrideWithValue(keyStore),
          appLocalStorageProvider.overrideWithValue(localStorage),
          authRepositoryProvider.overrideWithValue(mockAuth),
          sessionRepositoryProvider.overrideWithValue(mockSession),
          consentRepositoryProvider.overrideWithValue(mockConsent),
          routerNotifierProvider.overrideWith(
            (ref) => RouterNotifier(ref, initialOnboardingCompleted: true),
          ),
          sessionControllerProvider.overrideWith(
            (ref) => SessionController(
              authRepository: mockAuth,
              sessionRepository: mockSession,
              localStorage: localStorage,
              initialState: AppSessionState.active(
                session: const AuthSession(
                  accessToken: 'token',
                  userId: 'usr_1',
                ),
                bootstrapData: _bootstrap(),
              ),
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
      'the owned add-material route renders the screen and bottom nav',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await goTo(tester, AppRoutes.addMaterialPath(_subjectId));

        expect(find.text('Add learning material'), findsOneWidget);
        expect(find.text('Upload material'), findsOneWidget);
        expect(find.text('Extract concepts'), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Learning'), findsWidgets);
      },
    );

    testWidgets('a wrong-owner add-material route shows generic not-found', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await goTo(tester, AppRoutes.addMaterialPath(_otherSubjectId));

      expect(find.text('We could not find that page'), findsOneWidget);
      expect(find.text('Add learning material'), findsNothing);
    });

    testWidgets('the Learning tab exposes Add material and opens the route', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await goTo(tester, AppRoutes.learning);

      expect(find.text('Add material'), findsOneWidget);
      await tester.tap(find.text('Add material'));
      await tester.pumpAndSettle();

      expect(find.text('Add learning material'), findsOneWidget);
      expect(find.text('Upload material'), findsOneWidget);
    });
  });
}
