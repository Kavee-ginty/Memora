import 'package:flutter/foundation.dart';
import 'package:memora_mobile/src/routing/app_routes.dart';

import 'notification_intent.dart';

/// Destination and stable-parent fallback per supported intent, mirroring
/// Flow §13.1. Deep links never open a timed or submitted question surface:
/// the registry structurally cannot produce those routes (D8).
@immutable
class DeepLinkTarget {
  final String destinationPath;
  final String fallbackPath;

  const DeepLinkTarget({
    required this.destinationPath,
    required this.fallbackPath,
  });
}

DeepLinkTarget resolveDeepLinkTarget(
  NotificationIntent intent, {

  /// Mission id confirmed by the server for mission intents; when absent the
  /// destination falls back to the stable parent.
  String? validatedMissionId,
}) {
  switch (intent.category) {
    case NotificationCategory.missionReady:
    case NotificationCategory.dueMemories:
      final missionId = validatedMissionId ?? intent.resourceId;
      if (missionId.isEmpty) {
        return const DeepLinkTarget(
          destinationPath: AppRoutes.home,
          fallbackPath: AppRoutes.home,
        );
      }
      return DeepLinkTarget(
        destinationPath: AppRoutes.missionPreviewPath(missionId),
        fallbackPath: AppRoutes.home,
      );
    case NotificationCategory.verificationRequired:
      return DeepLinkTarget(
        destinationPath: AppRoutes.verifyConceptsPath(intent.resourceId),
        fallbackPath: AppRoutes.materialStatusPath(intent.resourceId),
      );
    case NotificationCategory.learningPathReady:
      return DeepLinkTarget(
        destinationPath: AppRoutes.pathPreviewPath(intent.resourceId),
        fallbackPath: AppRoutes.learning,
      );
    case NotificationCategory.rewardReady:
      // Reef detail and inventory arrive with T15; progress is the stable
      // parent for both destination and fallback (Flow §13.1).
      return const DeepLinkTarget(
        destinationPath: AppRoutes.progress,
        fallbackPath: AppRoutes.progress,
      );
    case NotificationCategory.privacyExportReady:
      return DeepLinkTarget(
        destinationPath: AppRoutes.privacyExportStatusPath(intent.resourceId),
        fallbackPath: AppRoutes.privacy,
      );
  }
}
