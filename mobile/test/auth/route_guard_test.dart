import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/auth/domain/route_access.dart';
import 'package:memora_mobile/src/routing/app_routes.dart';
import 'package:memora_mobile/src/routing/route_guard.dart';

void main() {
  group('Route Guard Pure Resolver Matrix Tests', () {
    test('Unknown or bootstrapping phase holds on splash without loop', () {
      // On splash: allowed
      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.unknown,
          currentLocation: AppRoutes.splash,
          onboardingCompleted: false,
        ),
        isNull,
      );

      // On protected route during bootstrapping: held on splash
      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.bootstrapping,
          currentLocation: AppRoutes.home,
          onboardingCompleted: true,
        ),
        equals(AppRoutes.splash),
      );
    });

    test('Signed out student on splash routes to onboarding if incomplete', () {
      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.signedOut,
          currentLocation: AppRoutes.splash,
          onboardingCompleted: false,
        ),
        equals(AppRoutes.onboardingStep(1)),
      );
    });

    test(
      'Signed out student on splash routes to sign-in if onboarding complete',
      () {
        expect(
          resolveRouteRedirect(
            sessionPhase: AppSessionPhase.signedOut,
            currentLocation: AppRoutes.splash,
            onboardingCompleted: true,
          ),
          equals(AppRoutes.signIn),
        );
      },
    );

    test('Signed out student accessing public onboarding or auth routes is allowed', () {
      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.signedOut,
          currentLocation: AppRoutes.onboardingStep(1),
          onboardingCompleted: false,
        ),
        isNull,
      );

      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.signedOut,
          currentLocation: AppRoutes.signIn,
          onboardingCompleted: true,
        ),
        isNull,
      );

      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.signedOut,
          currentLocation: AppRoutes.createAccount,
          onboardingCompleted: false,
        ),
        isNull,
      );
    });

    test(
      'Signed out student accessing protected routes is redirected to sign-in',
      () {
        expect(
          resolveRouteRedirect(
            sessionPhase: AppSessionPhase.signedOut,
            currentLocation: AppRoutes.home,
            onboardingCompleted: true,
          ),
          equals(AppRoutes.signIn),
        );

        expect(
          resolveRouteRedirect(
            sessionPhase: AppSessionPhase.signedOut,
            currentLocation: AppRoutes.learning,
            onboardingCompleted: true,
          ),
          equals(AppRoutes.signIn),
        );

        expect(
          resolveRouteRedirect(
            sessionPhase: AppSessionPhase.signedOut,
            currentLocation: AppRoutes.profile,
            onboardingCompleted: true,
          ),
          equals(AppRoutes.signIn),
        );
      },
    );

    test('Active authenticated student is allowed on protected routes', () {
      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.active,
          currentLocation: AppRoutes.home,
          onboardingCompleted: true,
        ),
        isNull,
      );

      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.active,
          currentLocation: AppRoutes.learning,
          onboardingCompleted: true,
        ),
        isNull,
      );
    });

    test('Active student attempting to visit auth/splash routes is redirected Home', () {
      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.active,
          currentLocation: AppRoutes.splash,
          onboardingCompleted: true,
        ),
        equals(AppRoutes.home),
      );

      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.active,
          currentLocation: AppRoutes.signIn,
          onboardingCompleted: true,
        ),
        equals(AppRoutes.home),
      );

      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.active,
          currentLocation: AppRoutes.onboardingStep(2),
          onboardingCompleted: true,
        ),
        equals(AppRoutes.home),
      );
    });

    test('Active student redirects to validated safe return location instead of Home', () {
      final safeLocation = SafeReturnLocation.parse('/learning');
      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.active,
          currentLocation: AppRoutes.signIn,
          onboardingCompleted: true,
          pendingReturnLocation: safeLocation,
        ),
        equals('/learning'),
      );
    });

    test('Blocked account status routes to recovery screen', () {
      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.blocked,
          currentLocation: AppRoutes.home,
          onboardingCompleted: true,
          accountStatus: AccountStatusDomain.suspended,
        ),
        equals(AppRoutes.accountRecovery),
      );

      // On recovery screen: allowed
      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.blocked,
          currentLocation: AppRoutes.accountRecovery,
          onboardingCompleted: true,
          accountStatus: AccountStatusDomain.suspended,
        ),
        isNull,
      );
    });

    test('Required consent renewal redirects to consent screen', () {
      expect(
        resolveRouteRedirect(
          sessionPhase: AppSessionPhase.active,
          currentLocation: AppRoutes.home,
          onboardingCompleted: true,
          consentRequiresReview: true,
        ),
        equals(AppRoutes.consent),
      );
    });
  });
}
