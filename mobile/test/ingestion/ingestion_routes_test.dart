import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memora_mobile/src/app.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/auth/domain/route_access.dart';
import 'package:memora_mobile/src/features/consent/application/consent_controller.dart';
import 'package:memora_mobile/src/features/consent/data/consent_repository.dart';
import 'package:memora_mobile/src/features/ingestion/application/ingestion_flow_controller.dart';
import 'package:memora_mobile/src/features/ingestion/data/ingestion_repository.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_models.dart';
import 'package:memora_mobile/src/routing/app_router.dart';
import 'package:memora_mobile/src/routing/app_routes.dart';
import 'package:memora_mobile/src/routing/route_guard.dart';

const String _subjectId = '11111111-1111-4111-8111-111111111111';
const String _otherSubjectId = '22222222-2222-4222-8222-222222222222';
const String _updateId = '33333333-3333-4333-8333-333333333333';
const String _otherUpdateId = '44444444-4444-4444-8444-444444444444';

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

UpdateSnapshot _updateSnapshot({
  String id = _updateId,
  LearningUpdateState state = LearningUpdateState.committed,
}) {
  return UpdateSnapshot(
    id: id,
    subjectId: _subjectId,
    inputType: IngestionInputType.manualText,
    state: state,
    hasManualText: true,
    learnedAt: DateTime.utc(2026, 11, 1),
    createdAt: DateTime.utc(2026, 11, 1),
    updatedAt: DateTime.utc(2026, 11, 1),
    rowVersion: 1,
    sourceDeletionStatus: SourceDeletionStatus.notRequired,
  );
}

List<CandidateItem> _candidates() {
  return const <CandidateItem>[
    CandidateItem(
      id: 'candidate-high',
      candidateType: 'concept',
      displayTitle: 'Newton first law',
      confidence: 0.94,
      band: ConfidenceBand.high,
      requiresVerification: false,
      status: CandidateState.accepted,
      candidateVersion: 1,
    ),
    CandidateItem(
      id: 'candidate-review',
      candidateType: 'concept',
      displayTitle: 'Ohm law',
      confidence: 0.62,
      band: ConfidenceBand.medium,
      requiresVerification: true,
      status: CandidateState.needsVerification,
      candidateVersion: 1,
    ),
  ];
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

  group('Material status route guard', () {
    test('a canonical update id may open the status destination', () {
      final result = _evaluate(
        location: AppRoutes.materialStatusPath(_updateId),
        bootstrap: _bootstrap(),
      );

      expect(result.isAllowed, isTrue);
    });

    test('a malformed update id is rejected before any request', () {
      final result = _evaluate(
        location: '/learning/updates/not-a-uuid',
        bootstrap: _bootstrap(),
      );

      expect(result.type, RouteAccessType.malformedRoute);
      expect(result.recoveryPath, AppRoutes.notFound);
    });

    test('an unknown update step is malformed', () {
      final result = _evaluate(
        location: '/learning/updates/$_updateId/unknown',
        bootstrap: _bootstrap(),
      );

      expect(result.type, RouteAccessType.malformedRoute);
    });

    test('signed-out status access requires sign-in with a safe return', () {
      final result = _evaluate(
        location: AppRoutes.materialStatusPath(_updateId),
        phase: AppSessionPhase.signedOut,
        bootstrap: _bootstrap(),
      );

      expect(result.type, RouteAccessType.signInRequired);
      expect(
        result.returnLocation?.path,
        AppRoutes.materialStatusPath(_updateId),
      );
    });
  });

  group('Add-material router integration', () {
    late MockAuthRepository mockAuth;
    late MockSessionRepository mockSession;
    late MockConsentRepository mockConsent;
    late MockIngestionRepository mockIngestion;
    late InMemorySecureKeyStore keyStore;
    late AppLocalStorage localStorage;

    setUp(() {
      keyStore = InMemorySecureKeyStore();
      localStorage = AppLocalStorage(keyStore);
      mockAuth = MockAuthRepository();
      mockSession = MockSessionRepository();
      mockConsent = MockConsentRepository();
      mockIngestion = MockIngestionRepository(autoAdvanceProcessing: false);
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
          ingestionRepositoryProvider.overrideWithValue(mockIngestion),
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

    testWidgets('the add-material receipt opens the status route', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await goTo(tester, AppRoutes.addMaterialPath(_subjectId));
      await tester.enterText(find.byType(TextField), 'Newton first law');
      await tester.pump();
      await tester.tap(find.widgetWithText(MemoraButton, 'Extract concepts'));
      await tester.pumpAndSettle();

      expect(find.text('Material received'), findsOneWidget);

      await tester.tap(find.text('View status'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('Material status'), findsOneWidget);
      expect(find.text('Extracting concepts'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('the owned status route renders the snapshot and bottom nav', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      mockIngestion.seedUpdate(_updateSnapshot());
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await goTo(tester, AppRoutes.materialStatusPath(_updateId));

      expect(find.text('Material status'), findsOneWidget);
      expect(find.text('Learning path ready'), findsOneWidget);
      expect(find.text('Preview learning path'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('a malformed update id never reaches the repository', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await goTo(tester, '/learning/updates/not-a-uuid');

      expect(find.text('We could not find that page'), findsOneWidget);
      expect(mockIngestion.operations, isEmpty);
    });

    testWidgets(
      'a wrong-owner update is indistinguishable from a missing one',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await goTo(tester, AppRoutes.materialStatusPath(_otherUpdateId));

        expect(find.text('We could not find that page'), findsOneWidget);
        expect(find.text('Material status'), findsNothing);
        expect(mockIngestion.operations, <IngestionOperation>[
          IngestionOperation.get,
        ]);
      },
    );

    testWidgets(
      'the verify route renders the screen and hides the bottom nav',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        mockIngestion.seedUpdate(
          _updateSnapshot(state: LearningUpdateState.verificationRequired),
          candidates: _candidates(),
        );
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await goTo(tester, AppRoutes.verifyConceptsPath(_updateId));

        expect(find.text('Verify concepts'), findsOneWidget);
        expect(find.text('Review the concepts Memora found'), findsOneWidget);
        expect(find.text('Newton first law'), findsOneWidget);
        expect(find.text('Ohm law'), findsOneWidget);
        expect(find.text('Preview learning path'), findsOneWidget);
        expect(find.text('Back to status'), findsNothing);
        expect(find.text('Home'), findsNothing);

        await goTo(tester, AppRoutes.pathPreviewPath(_updateId));

        expect(find.text('Learning path preview'), findsOneWidget);
        expect(find.text('Back to status'), findsOneWidget);
        expect(find.text('Home'), findsNothing);
      },
    );

    testWidgets('a verify route in the wrong state redirects to status', (
      tester,
    ) async {
      mockIngestion.seedUpdate(
        _updateSnapshot(state: LearningUpdateState.committed),
        candidates: _candidates(),
      );
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await goTo(tester, AppRoutes.verifyConceptsPath(_updateId));

      expect(find.text('Material status'), findsOneWidget);
      expect(find.text('Learning path ready'), findsOneWidget);
      expect(find.text('Verify concepts'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('a malformed verify id never reaches the repository', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await goTo(tester, '/learning/updates/not-a-uuid/verify');

      expect(find.text('We could not find that page'), findsOneWidget);
      expect(find.text('Verify concepts'), findsNothing);
      expect(mockIngestion.operations, isEmpty);
    });
  });
}
