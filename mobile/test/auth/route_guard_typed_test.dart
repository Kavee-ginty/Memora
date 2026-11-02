import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/auth/domain/route_access.dart';
import 'package:memora_mobile/src/routing/app_routes.dart';
import 'package:memora_mobile/src/routing/route_guard.dart';

const String subjectOwned = '11111111-1111-4111-8111-111111111111';
const String subjectOtherOwner = '22222222-2222-4222-8222-222222222222';
const String missionOwned = '33333333-3333-4333-8333-333333333333';
const String missionOtherOwner = '44444444-4444-4444-8444-444444444444';

BootstrapData bootstrapWith({
  String missionStatus = 'planned',
  String? activeMissionId = missionOwned,
}) {
  return BootstrapData(
    accountStatus: AccountStatusDomain.active,
    profileSummary: const ProfileSummaryDomain(
      userId: 'usr_1',
      displayName: 'Amani Perera',
    ),
    consentStatus: const ConsentStatusDomain(requiresReview: false),
    subjects: const <SubjectSummaryDomain>[
      SubjectSummaryDomain(
        id: subjectOwned,
        code: 'AL-PHYS',
        name: 'A/L Physics',
        curriculumEditionCode: '2026',
        curriculumVersionId: 'cur_1',
      ),
    ],
    activeMission: activeMissionId == null
        ? null
        : ActiveMissionSummaryDomain(
            id: activeMissionId,
            subjectId: subjectOwned,
            missionDate: '2026-10-28',
            status: missionStatus,
          ),
    capabilities: const CapabilityFlagsDomain(),
    serverTime: DateTime.utc(2026, 10, 28),
  );
}

RouteAccessResult evaluate({
  AppSessionPhase phase = AppSessionPhase.active,
  required String location,
  BootstrapData? bootstrap,
  bool consentRequiresReview = false,
  AccountStatusDomain? accountStatus,
  AuthFailure? failure,
  SafeReturnLocation? pending,
}) {
  return evaluateRouteAccess(
    sessionPhase: phase,
    currentLocation: location,
    onboardingCompleted: true,
    accountStatus: accountStatus,
    consentRequiresReview: consentRequiresReview,
    pendingReturnLocation: pending,
    bootstrapData: bootstrap,
    failure: failure,
  );
}

void main() {
  group('Typed route access evaluation', () {
    test('Signed-out matrix requires sign-in with a safe return location', () {
      final locations = <String>[
        AppRoutes.home,
        AppRoutes.learning,
        AppRoutes.progress,
        AppRoutes.profile,
        AppRoutes.learningDetailPath(subjectOwned),
        AppRoutes.missionPreviewPath(missionOwned),
        AppRoutes.consent,
      ];

      for (final location in locations) {
        final result = evaluate(
          phase: AppSessionPhase.signedOut,
          location: location,
        );
        expect(
          result.type,
          RouteAccessType.signInRequired,
          reason: 'Signed-out $location must require sign-in',
        );
        expect(result.recoveryPath, AppRoutes.signIn);
        expect(result.returnLocation?.path, location);
      }
    });

    test('Active matrix allows roots and canonical detail routes', () {
      final bootstrap = bootstrapWith();
      for (final location in <String>[
        AppRoutes.home,
        AppRoutes.learning,
        AppRoutes.progress,
        AppRoutes.profile,
        AppRoutes.learningDetailPath(subjectOwned),
        AppRoutes.missionPreviewPath(missionOwned),
      ]) {
        final result = evaluate(location: location, bootstrap: bootstrap);
        expect(
          result.type,
          RouteAccessType.allowed,
          reason: 'Active $location must be allowed',
        );
        expect(result.requiresRedirect, isFalse);
      }
    });

    test('Malformed identifiers resolve to not-found without a lookup', () {
      for (final location in <String>[
        '/learning/not-a-uuid',
        '/learning/$subjectOwned/extra',
        '/missions/not-a-uuid/preview',
        '/missions/$missionOwned',
      ]) {
        final result = evaluate(location: location, bootstrap: bootstrapWith());
        expect(result.type, RouteAccessType.malformedRoute);
        expect(result.recoveryPath, AppRoutes.notFound);
      }
    });

    test(
      'Wrong-owner subject and mission are indistinguishable from missing',
      () {
        final bootstrap = bootstrapWith();
        final wrongSubject = evaluate(
          location: AppRoutes.learningDetailPath(subjectOtherOwner),
          bootstrap: bootstrap,
        );
        final wrongMission = evaluate(
          location: AppRoutes.missionPreviewPath(missionOtherOwner),
          bootstrap: bootstrap,
        );

        expect(wrongSubject.type, RouteAccessType.resourceNotFound);
        expect(wrongMission.type, RouteAccessType.resourceNotFound);
        expect(wrongSubject.recoveryPath, wrongMission.recoveryPath);
        expect(wrongSubject.userMessage, wrongMission.userMessage);
      },
    );

    test(
      'Known mission in a non-previewable state returns to stable parent',
      () {
        final result = evaluate(
          location: AppRoutes.missionPreviewPath(missionOwned),
          bootstrap: bootstrapWith(missionStatus: 'completed'),
        );

        expect(result.type, RouteAccessType.invalidWorkflowState);
        expect(result.recoveryPath, AppRoutes.home);
      },
    );

    test('Consent review gates every authenticated destination', () {
      final result = evaluate(
        location: AppRoutes.home,
        bootstrap: bootstrapWith(),
        consentRequiresReview: true,
      );
      expect(result.type, RouteAccessType.consentReviewRequired);
      expect(result.recoveryPath, AppRoutes.consent);

      final onConsent = evaluate(
        location: AppRoutes.consent,
        bootstrap: bootstrapWith(),
        consentRequiresReview: true,
      );
      expect(onConsent.type, RouteAccessType.allowed);
    });

    test('Blocked accounts route to recovery and stay there', () {
      final blocked = evaluate(
        location: AppRoutes.home,
        bootstrap: bootstrapWith(),
        accountStatus: AccountStatusDomain.suspended,
      );
      expect(blocked.type, RouteAccessType.accountRecoveryRequired);
      expect(blocked.recoveryPath, AppRoutes.accountRecovery);

      final onRecovery = evaluate(
        location: AppRoutes.accountRecovery,
        bootstrap: bootstrapWith(),
        accountStatus: AccountStatusDomain.suspended,
      );
      expect(onRecovery.type, RouteAccessType.allowed);
    });

    test('Unknown and bootstrapping phases hold on splash', () {
      for (final phase in <AppSessionPhase>[
        AppSessionPhase.unknown,
        AppSessionPhase.bootstrapping,
      ]) {
        expect(
          evaluate(phase: phase, location: AppRoutes.splash).type,
          RouteAccessType.allowed,
        );
        final redirected = evaluate(phase: phase, location: AppRoutes.home);
        expect(redirected.recoveryPath, AppRoutes.splash);
      }
    });

    test('Expired session produces a typed sign-in result', () {
      final result = evaluate(
        phase: AppSessionPhase.signedOut,
        location: AppRoutes.home,
        failure: AuthFailure.expiredSession(),
      );
      expect(result.type, RouteAccessType.sessionExpired);
      expect(result.recoveryPath, AppRoutes.signIn);
    });

    test('Redirect targets are stable under the same state', () {
      final bootstrap = bootstrapWith();
      final consentRedirect = evaluate(
        location: AppRoutes.home,
        bootstrap: bootstrap,
        consentRequiresReview: true,
      );
      expect(consentRedirect.recoveryPath, AppRoutes.consent);
      final cases = <({RouteAccessResult first, RouteAccessResult second})>[
        (
          first: evaluate(
            phase: AppSessionPhase.signedOut,
            location: AppRoutes.home,
          ),
          second: evaluate(
            phase: AppSessionPhase.signedOut,
            location: AppRoutes.signIn,
            pending: SafeReturnLocation.parse(AppRoutes.home),
          ),
        ),
        (
          first: consentRedirect,
          second: evaluate(
            location: consentRedirect.recoveryPath!,
            bootstrap: bootstrap,
            consentRequiresReview: true,
          ),
        ),
        (
          first: evaluate(
            location: AppRoutes.home,
            bootstrap: bootstrap,
            accountStatus: AccountStatusDomain.deleted,
          ),
          second: evaluate(
            location: AppRoutes.accountRecovery,
            bootstrap: bootstrap,
            accountStatus: AccountStatusDomain.deleted,
          ),
        ),
        (
          first: evaluate(
            location: AppRoutes.learningDetailPath(subjectOtherOwner),
            bootstrap: bootstrap,
          ),
          second: evaluate(location: AppRoutes.notFound, bootstrap: bootstrap),
        ),
        (
          first: evaluate(
            location: AppRoutes.missionPreviewPath(missionOwned),
            bootstrap: bootstrapWith(missionStatus: 'completed'),
          ),
          second: evaluate(
            location: AppRoutes.home,
            bootstrap: bootstrapWith(missionStatus: 'completed'),
          ),
        ),
      ];

      for (final entry in cases) {
        expect(
          entry.second.type,
          RouteAccessType.allowed,
          reason: 'Redirect target must not loop back',
        );
      }
    });

    test('String resolver mirrors the typed result', () {
      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.signedOut,
          currentLocation: AppRoutes.progress,
          onboardingCompleted: true,
        ),
        AppRoutes.signIn,
      );
      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.active,
          currentLocation: AppRoutes.progress,
          onboardingCompleted: true,
          bootstrapData: bootstrapWith(),
        ),
        isNull,
      );
    });

    test('Canonical UUID helper rejects non-canonical text', () {
      expect(isCanonicalUuid(subjectOwned), isTrue);
      expect(isCanonicalUuid('not-a-uuid'), isFalse);
      expect(isCanonicalUuid('1111'), isFalse);
      expect(isCanonicalUuid(''), isFalse);
    });
  });
}
