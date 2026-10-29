/// Canonical route names and path definitions for Memora.
abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding/:step';
  static String onboardingStep(int step) => '/onboarding/$step';

  static const String signIn = '/auth/sign-in';
  static const String createAccount = '/auth/create-account';
  static const String recoverAccount = '/auth/recover';

  static const String accountRecovery = '/recovery';
  static const String consent = '/consent';
  static const String notFound = '/not-found';

  static const String home = '/home';
  static const String learning = '/learning';
  static const String progress = '/progress';
  static const String profile = '/profile';

  static const String learningDetail = '/learning/:subjectId';
  static const String missionPreview = '/missions/:missionId/preview';

  static const String featureUnavailable = '/unavailable';
  static const String catalog = '/catalog';
  static const String quiz = '/quiz';

  /// Builds an encoded learning detail location for a validated identifier.
  static String learningDetailPath(String subjectId) =>
      '/learning/${Uri.encodeComponent(subjectId)}';

  /// Builds an encoded mission preview location for a validated identifier.
  static String missionPreviewPath(String missionId) =>
      '/missions/${Uri.encodeComponent(missionId)}/preview';
}
