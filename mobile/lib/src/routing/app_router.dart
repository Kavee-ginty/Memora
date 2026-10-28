import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/catalog/component_catalog_screen.dart';
import '../design_system/components/app_header.dart';
import '../design_system/tokens/colors.dart';
import '../features/auth/application/session_controller.dart';
import '../features/auth/domain/app_session_state.dart';
import '../features/auth/domain/route_access.dart';
import '../features/auth/presentation/account_recovery_screen.dart';
import '../features/auth/presentation/create_account_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/recover_account_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/common/presentation/authorized_placeholder_screen.dart';
import '../features/common/presentation/feature_unavailable_screen.dart';
import '../features/consent/presentation/consent_review_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/learning/presentation/learning_path_screen.dart';
import '../features/profile/presentation/profile_entry_screen.dart';
import '../features/progress/presentation/progress_entry_screen.dart';
import '../features/quiz/presentation/quiz_screen.dart';
import 'app_routes.dart';
import 'root_shell.dart';
import 'route_guard.dart';

/// Provider for managing route listener updates based on session state changes.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _onboardingCompleted;

  RouterNotifier(this._ref, {bool initialOnboardingCompleted = false})
    : _onboardingCompleted = initialOnboardingCompleted {
    _ref.listen<AppSessionState>(
      sessionControllerProvider,
      (_, _) => notifyListeners(),
    );
    _loadOnboarding();
  }

  bool get onboardingCompleted => _onboardingCompleted;

  void setOnboardingCompleted(bool value) {
    if (_onboardingCompleted != value) {
      _onboardingCompleted = value;
      notifyListeners();
    }
  }

  Future<void> _loadOnboarding() async {
    _onboardingCompleted = await _ref
        .read(appLocalStorageProvider)
        .isOnboardingCompleted();
    notifyListeners();
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final sessionState = ref.read(sessionControllerProvider);
      final controller = ref.read(sessionControllerProvider.notifier);

      // Capture at most one allowlisted internal return location while signed
      // out. Unsafe, external and credential-bearing candidates are discarded.
      if (sessionState.phase == AppSessionPhase.signedOut) {
        final safeLocation = SafeReturnLocation.parse(state.uri.toString());
        if (safeLocation != null) {
          controller.setSafeReturnLocation(safeLocation);
        }
      }

      final pendingReturn = controller.pendingReturnLocation;
      final result = evaluateRouteAccess(
        sessionPhase: sessionState.phase,
        currentLocation: state.uri.path,
        onboardingCompleted: notifier.onboardingCompleted,
        accountStatus: sessionState.bootstrapData?.accountStatus,
        consentRequiresReview:
            sessionState.bootstrapData?.consentStatus.requiresReview ?? false,
        pendingReturnLocation: pendingReturn,
        bootstrapData: sessionState.bootstrapData,
        failure: sessionState.failure,
      );

      if (!result.requiresRedirect) {
        return null;
      }

      final target = result.recoveryPath!;
      // Consume the return location only when it is actually used, so it can
      // never be replayed after sign-out, expiry or an account change.
      if (pendingReturn != null && target == pendingReturn.path) {
        controller.consumeSafeReturnLocation();
      }
      return target;
    },
    routes: <RouteBase>[
      // Public Splash Route
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const SplashScreen()),
      ),

      // Public Onboarding Flow
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) {
          final step = int.tryParse(state.pathParameters['step'] ?? '1') ?? 1;
          return _buildPage(context, state, OnboardingScreen(step: step));
        },
      ),

      // Public Auth Routes
      GoRoute(
        path: AppRoutes.signIn,
        name: 'signIn',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const SignInScreen()),
      ),
      GoRoute(
        path: AppRoutes.createAccount,
        name: 'createAccount',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const CreateAccountScreen()),
      ),
      GoRoute(
        path: AppRoutes.recoverAccount,
        name: 'recoverAccount',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const RecoverAccountScreen()),
      ),

      // Blocking Account Recovery Route
      GoRoute(
        path: AppRoutes.accountRecovery,
        name: 'accountRecovery',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const AccountRecoveryScreen()),
      ),

      // Authenticated Consent Destination (outside the root shell)
      GoRoute(
        path: AppRoutes.consent,
        name: 'consent',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const ConsentReviewScreen()),
      ),

      // Generic not-found destination for malformed or wrong-owner resources
      GoRoute(
        path: AppRoutes.notFound,
        name: 'notFound',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const NotFoundScreen()),
      ),

      // Canonical authenticated detail routes owned by later feature tasks
      GoRoute(
        path: AppRoutes.learningDetail,
        name: 'learningDetail',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const AuthorizedPlaceholderScreen(
            title: 'Learning path',
            message:
                'This subject is authorized for your account. The full learning '
                'path is owned by a later milestone.',
            backLabel: 'Back to Learning',
            backPath: AppRoutes.learning,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.missionPreview,
        name: 'missionPreview',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const AuthorizedPlaceholderScreen(
            title: 'Mission preview',
            message:
                'This mission is authorized for your account. The full preview '
                'and start flow are owned by a later milestone.',
            backLabel: 'Back to Home',
            backPath: AppRoutes.home,
          ),
        ),
      ),

      // Future/Placeholder Features
      GoRoute(
        path: AppRoutes.featureUnavailable,
        name: 'featureUnavailable',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          FeatureUnavailableScreen(message: state.extra as String?),
        ),
      ),

      // Authenticated Four-Destination Root Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return RootShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                pageBuilder: (context, state) =>
                    _buildPage(context, state, const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.learning,
                name: 'learning',
                pageBuilder: (context, state) => _buildPage(
                  context,
                  state,
                  Scaffold(
                    backgroundColor: MemoraColors.surfaceSoft,
                    appBar: const MemoraHeader.root(title: 'Learning'),
                    body: const LearningPathScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                name: 'progress',
                pageBuilder: (context, state) =>
                    _buildPage(context, state, const ProgressEntryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                pageBuilder: (context, state) =>
                    _buildPage(context, state, const ProfileEntryScreen()),
              ),
            ],
          ),
        ],
      ),

      // Catalog & Quiz routes for testing and development
      GoRoute(
        path: AppRoutes.catalog,
        name: 'catalog',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const ComponentCatalogScreen()),
      ),
      GoRoute(
        path: AppRoutes.quiz,
        name: 'quiz',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const QuizScreen()),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});

/// Builds an immediate page when the platform requests reduced motion and a
/// standard platform transition otherwise.
///
/// Exposed for the reduced-motion acceptance test so the exact production page
/// decision is exercised rather than a duplicate helper.
@visibleForTesting
Page<void> buildRoutePage({
  required BuildContext context,
  required LocalKey key,
  required Widget child,
}) {
  final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  if (reduceMotion) {
    return NoTransitionPage<void>(key: key, child: child);
  }
  return MaterialPage<void>(key: key, child: child);
}

Page<void> _buildPage(BuildContext context, GoRouterState state, Widget child) {
  return buildRoutePage(context: context, key: state.pageKey, child: child);
}

/// Default global router reference maintained for backwards compatibility.
/// Tests or custom contexts should prefer `appRouterProvider`.
GoRouter get appRouter => GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
