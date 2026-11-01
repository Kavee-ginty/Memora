import '../features/auth/domain/app_session_state.dart';
import '../features/auth/domain/bootstrap_state.dart';
import '../features/auth/domain/route_access.dart';
import 'app_routes.dart';

/// Mission states that the approved contract allows the preview route to open.
const Set<String> _previewableMissionStatuses = <String>{
  'planned',
  'started',
  'paused',
};

final RegExp _canonicalUuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// True when [value] is canonical 8-4-4-4-12 UUID text.
bool isCanonicalUuid(String value) => _canonicalUuid.hasMatch(value);

/// Evaluates the approved guard order and returns a typed access result.
///
/// Order: session, account status, recent authentication, consent, resource
/// ownership, workflow state and active-mission constraints. The evaluation is
/// pure so the same inputs always resolve to the same destination and redirect
/// targets are stable.
RouteAccessResult evaluateRouteAccess({
  required AppSessionPhase sessionPhase,
  required String currentLocation,
  required bool onboardingCompleted,
  AccountStatusDomain? accountStatus,
  bool consentRequiresReview = false,
  SafeReturnLocation? pendingReturnLocation,
  BootstrapData? bootstrapData,
  AuthFailure? failure,
  bool requiresRecentAuthentication = false,
  bool recentAuthenticationSatisfied = true,
}) {
  final path = _pathOf(currentLocation);
  final isSplash = path == AppRoutes.splash;
  final isOnboarding = path == '/onboarding' || path.startsWith('/onboarding/');
  final isAuthRoute = path == '/auth' || path.startsWith('/auth/');
  final isRecovery = path == AppRoutes.accountRecovery;
  final isConsent = path == AppRoutes.consent;

  // 1. Session lifecycle.
  switch (sessionPhase) {
    case AppSessionPhase.unknown:
    case AppSessionPhase.bootstrapping:
      return isSplash
          ? const RouteAccessResult.allowed()
          : const RouteAccessResult.redirect(AppRoutes.splash);
    case AppSessionPhase.failure:
      return isSplash
          ? const RouteAccessResult.allowed()
          : const RouteAccessResult.redirect(AppRoutes.splash);
    case AppSessionPhase.blocked:
      return isRecovery
          ? const RouteAccessResult.allowed()
          : const RouteAccessResult.accountRecoveryRequired();
    case AppSessionPhase.signedOut:
    case AppSessionPhase.refreshRequired:
      if (isSplash) {
        return RouteAccessResult.redirect(
          onboardingCompleted ? AppRoutes.signIn : AppRoutes.onboardingStep(1),
        );
      }
      if (isOnboarding || isAuthRoute) {
        return const RouteAccessResult.allowed();
      }
      if (failure?.code == 'expired_session') {
        return const RouteAccessResult.sessionExpired();
      }
      return RouteAccessResult.signInRequired(SafeReturnLocation.parse(path));
    case AppSessionPhase.active:
      break;
  }

  // 2. Account status remains authoritative even if the phase lags.
  if (accountStatus?.isBlocked ?? false) {
    return isRecovery
        ? const RouteAccessResult.allowed()
        : const RouteAccessResult.accountRecoveryRequired();
  }

  // 3. Recent authentication when the destination requires it.
  if (requiresRecentAuthentication && !recentAuthenticationSatisfied) {
    return const RouteAccessResult.recentAuthRequired();
  }

  // 4. Consent before any authenticated destination.
  if (consentRequiresReview) {
    return isConsent
        ? const RouteAccessResult.allowed()
        : const RouteAccessResult.consentReviewRequired();
  }

  // 5-7. Ownership, workflow and active-mission constraints for detail routes.
  final detailResult = _evaluateDetailRoute(path, bootstrapData);
  if (detailResult != null) {
    return detailResult;
  }

  // Authenticated students must not revisit splash, onboarding, auth or the
  // blocking recovery screen.
  if (isSplash || isOnboarding || isAuthRoute || isRecovery) {
    return RouteAccessResult.redirect(
      pendingReturnLocation?.path ?? AppRoutes.home,
    );
  }

  return const RouteAccessResult.allowed();
}

/// Backwards-compatible string resolver used by existing call sites.
///
/// Returns `null` when the location is allowed, otherwise the stable redirect
/// target produced by [evaluateRouteAccess].
String? resolveRouteRedirect({
  required AppSessionPhase sessionPhase,
  required String currentLocation,
  required bool onboardingCompleted,
  AccountStatusDomain? accountStatus,
  bool consentRequiresReview = false,
  SafeReturnLocation? pendingReturnLocation,
  BootstrapData? bootstrapData,
  AuthFailure? failure,
  bool requiresRecentAuthentication = false,
  bool recentAuthenticationSatisfied = true,
}) {
  final result = evaluateRouteAccess(
    sessionPhase: sessionPhase,
    currentLocation: currentLocation,
    onboardingCompleted: onboardingCompleted,
    accountStatus: accountStatus,
    consentRequiresReview: consentRequiresReview,
    pendingReturnLocation: pendingReturnLocation,
    bootstrapData: bootstrapData,
    failure: failure,
    requiresRecentAuthentication: requiresRecentAuthentication,
    recentAuthenticationSatisfied: recentAuthenticationSatisfied,
  );

  return result.requiresRedirect ? result.recoveryPath : null;
}

/// Resolves ownership and workflow rules for canonical detail routes.
///
/// Returns `null` when [path] is not a canonical detail route.
RouteAccessResult? _evaluateDetailRoute(
  String path,
  BootstrapData? bootstrapData,
) {
  if (path == AppRoutes.learning) {
    return null;
  }

  if (path.startsWith('/learning/')) {
    final subjectId = path.substring('/learning/'.length);
    if (subjectId.isEmpty ||
        subjectId.contains('/') ||
        !isCanonicalUuid(subjectId)) {
      // Malformed identifiers resolve to generic not-found without lookup.
      return const RouteAccessResult.malformedRoute();
    }
    if (bootstrapData == null) {
      return const RouteAccessResult.notFound();
    }
    final ownsSubject = bootstrapData.subjects.any(
      (subject) => subject.id == subjectId,
    );
    // Missing and wrong-owner are intentionally indistinguishable.
    return ownsSubject
        ? const RouteAccessResult.allowed()
        : const RouteAccessResult.notFound();
  }

  if (path == '/missions' || path.startsWith('/missions/')) {
    final segments = path.split('/');
    if (segments.length != 4 || segments[3] != 'preview') {
      return const RouteAccessResult.malformedRoute();
    }

    final missionId = segments[2];
    if (!isCanonicalUuid(missionId)) {
      return const RouteAccessResult.malformedRoute();
    }
    if (bootstrapData == null) {
      return const RouteAccessResult.notFound();
    }

    final mission = bootstrapData.activeMission;
    // Missing and wrong-owner missions share the same generic result.
    if (mission == null || mission.id != missionId) {
      return const RouteAccessResult.notFound();
    }

    final ownsSubject = bootstrapData.subjects.any(
      (subject) => subject.id == mission.subjectId,
    );
    if (!ownsSubject) {
      return const RouteAccessResult.notFound();
    }

    // 7. Active-mission constraints: only approved previewable states open.
    if (!_previewableMissionStatuses.contains(mission.status)) {
      return const RouteAccessResult.invalidWorkflowState();
    }

    return const RouteAccessResult.allowed();
  }

  return null;
}

/// Returns the path portion of a location, without query or fragment, and
/// without a trailing slash (except the root path).
String _pathOf(String location) {
  var path = location;
  final queryIndex = path.indexOf('?');
  if (queryIndex >= 0) {
    path = path.substring(0, queryIndex);
  }
  final fragmentIndex = path.indexOf('#');
  if (fragmentIndex >= 0) {
    path = path.substring(0, fragmentIndex);
  }
  if (path.isEmpty) {
    return '/';
  }
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return path;
}
