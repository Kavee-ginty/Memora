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

  /// Privacy hub reached from Profile.
  static const String privacy = '/profile/privacy';

  /// Recent-authentication recovery for a pending privacy mutation.
  static const String privacyReauth = '/profile/privacy/reauth';

  /// Export entry and authoritative status destinations.
  static const String privacyExport = '/profile/privacy/export';
  static const String privacyExportStatus =
      '/profile/privacy/export/:requestId';

  /// Deletion confirmation and authoritative status destinations.
  static const String privacyDelete = '/profile/privacy/delete';
  static const String privacyDeletionStatus =
      '/profile/privacy/delete/:requestId';

  /// Builds an encoded export status location for a validated request ID.
  static String privacyExportStatusPath(String requestId) =>
      '/profile/privacy/export/${Uri.encodeComponent(requestId)}';

  /// Builds an encoded deletion status location for a validated request ID.
  static String privacyDeletionStatusPath(String requestId) =>
      '/profile/privacy/delete/${Uri.encodeComponent(requestId)}';

  static const String learningDetail = '/learning/:subjectId';
  static const String addMaterial = '/learning/:subjectId/material/new';
  static const String materialStatus = '/learning/updates/:updateId';
  static const String verifyConcepts = '/learning/updates/:updateId/verify';
  static const String pathPreview = '/learning/updates/:updateId/preview';
  static const String missionPreview = '/missions/:missionId/preview';

  static const String featureUnavailable = '/unavailable';
  static const String catalog = '/catalog';
  static const String quiz = '/quiz';

  /// Builds an encoded learning detail location for a validated identifier.
  static String learningDetailPath(String subjectId) =>
      '/learning/${Uri.encodeComponent(subjectId)}';

  /// Builds an encoded add-material location for a validated subject id.
  static String addMaterialPath(String subjectId) =>
      '/learning/${Uri.encodeComponent(subjectId)}/material/new';

  /// Builds an encoded material-status location for a validated update id.
  static String materialStatusPath(String updateId) =>
      '/learning/updates/${Uri.encodeComponent(updateId)}';

  /// Builds an encoded concept-verification location.
  static String verifyConceptsPath(String updateId) =>
      '${materialStatusPath(updateId)}/verify';

  /// Builds an encoded learning-path preview location.
  static String pathPreviewPath(String updateId) =>
      '${materialStatusPath(updateId)}/preview';

  /// Builds an encoded mission preview location for a validated identifier.
  static String missionPreviewPath(String missionId) =>
      '/missions/${Uri.encodeComponent(missionId)}/preview';
}
