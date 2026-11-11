import 'package:flutter/foundation.dart';

import '../../../routing/app_routes.dart';
import '../infrastructure/deep_link_validation_api.dart';
import 'consumed_intent_ledger.dart';
import 'deep_link_registry.dart';
import 'notification_intent.dart';

/// How a tap was resolved (Flow §13.1-13.2, D9-D10).
enum DeepLinkResolution {
  /// Navigate to the validated destination; the intent is consumed.
  navigate,

  /// Resolve to the stable parent with a brief explanation; consumed.
  fallback,

  /// The intent was already consumed; do nothing at all.
  alreadyConsumed,

  /// Signed out: hand the destination to the router so the sign-in flow
  /// captures it as a one-time return location (T07). The intent is NOT
  /// consumed — post-auth replay goes through validation again.
  handedToSignIn,

  /// Malformed payload: discard silently (nothing to consume or navigate).
  discarded,
}

/// The outcome of one deep-link tap, consumed by the notice host (Commit 8)
/// for the brief fallback explanation.
@immutable
class DeepLinkDecision {
  final DeepLinkResolution resolution;
  final String? navigationPath;

  /// Localization key describing why a fallback happened, when applicable.
  final String? explanationLocKey;

  const DeepLinkDecision({
    required this.resolution,
    this.navigationPath,
    this.explanationLocKey,
  });
}

/// Fallback explanation keys (UI/UX §9.21 contextual copy family).
class DeepLinkExplanations {
  static const String linkExpired = 'notification.fallback.expired';
  static const String linkUnavailable = 'notification.fallback.unavailable';
  static const String workflowMovedOn = 'notification.fallback.workflow';
  static const String malformedLink = 'notification.fallback.malformed';

  const DeepLinkExplanations._();
}

/// Validates and consumes push intents before any navigation (D7, D9-D10).
///
/// Pipeline per tap: parse → session hand-off → expiry → consume-once →
/// API resource validation → navigate destination or resolve to the stable
/// parent. Question surfaces (mission item, feedback, explanation) are
/// structurally unreachable: the registry cannot produce those routes.
class DeepLinkCoordinator {
  final DeepLinkValidationApi validationApi;
  final ConsumedIntentLedger ledger;
  final void Function(String path) navigate;
  final DateTime Function() clock;
  final bool Function() isAuthenticated;

  const DeepLinkCoordinator({
    required this.validationApi,
    required this.ledger,
    required this.navigate,
    required this.clock,
    required this.isAuthenticated,
  });

  Future<DeepLinkDecision> handleTap(Map<String, String> data) async {
    // 1. Parse: malformed payloads discard silently.
    final intent = NotificationIntent.parse(data);
    if (intent == null) {
      return const DeepLinkDecision(
        resolution: DeepLinkResolution.discarded,
        explanationLocKey: DeepLinkExplanations.malformedLink,
      );
    }

    // 2. Signed out: hand the destination to the router guard chain, which
    // captures an allowlisted one-time return location for sign-in (D10).
    // The intent stays unconsumed so post-auth replay revalidates.
    if (!isAuthenticated()) {
      final decision = _handOffToSignIn(intent);
      if (decision != null) {
        navigate(decision.navigationPath!);
        return decision;
      }
      final fallback = resolveDeepLinkTarget(intent).fallbackPath;
      navigate(fallback);
      return DeepLinkDecision(
        resolution: DeepLinkResolution.handedToSignIn,
        navigationPath: fallback,
      );
    }

    // 3. Expiry: an expired intent never navigates; it is consumed so it
    // cannot replay later either.
    if (intent.isExpired(clock())) {
      await ledger.markConsumed(intent.notificationId);
      final fallback = resolveDeepLinkTarget(intent).fallbackPath;
      navigate(fallback);
      return DeepLinkDecision(
        resolution: DeepLinkResolution.fallback,
        navigationPath: fallback,
        explanationLocKey: DeepLinkExplanations.linkExpired,
      );
    }

    // 4. Consume-once: a replayed intent does nothing at all (Flow §20.3).
    if (await ledger.alreadyConsumed(intent.notificationId)) {
      return const DeepLinkDecision(
        resolution: DeepLinkResolution.alreadyConsumed,
      );
    }

    // 5. Validate the referenced resource through the API (D7).
    final target = await _validatedTarget(intent);

    // 6. Consume once, then navigate or fall back.
    await ledger.markConsumed(intent.notificationId);
    final navigated = target.resolution == DeepLinkResolution.navigate;
    navigate(target.navigationPath!);
    return target;
  }

  /// Signed-out hand-off destinations built from payload identifiers. The
  /// mission categories need a server-confirmed mission id, so due-memories
  /// taps hand off to Home; daily-mission taps can hand off with the
  /// pushed mission id because the preview route revalidates ownership.
  DeepLinkDecision? _handOffToSignIn(NotificationIntent intent) {
    switch (intent.category) {
      case NotificationCategory.missionReady:
        return DeepLinkDecision(
          resolution: DeepLinkResolution.handedToSignIn,
          navigationPath: AppRoutes.missionPreviewPath(intent.resourceId),
        );
      case NotificationCategory.dueMemories:
      case NotificationCategory.verificationRequired:
      case NotificationCategory.learningPathReady:
      case NotificationCategory.rewardReady:
      case NotificationCategory.privacyExportReady:
        return null;
    }
  }

  Future<DeepLinkDecision> _validatedTarget(NotificationIntent intent) async {
    switch (intent.category) {
      case NotificationCategory.missionReady:
      case NotificationCategory.dueMemories:
        final mission = await validationApi.todayMission();
        final target = resolveDeepLinkTarget(
          intent,
          validatedMissionId: mission.missionId,
        );
        if (!mission.valid) {
          return DeepLinkDecision(
            resolution: DeepLinkResolution.fallback,
            navigationPath: target.fallbackPath,
            explanationLocKey: DeepLinkExplanations.workflowMovedOn,
          );
        }
        return DeepLinkDecision(
          resolution: DeepLinkResolution.navigate,
          navigationPath: target.destinationPath,
        );
      case NotificationCategory.verificationRequired:
        final state = await validationApi.learningUpdate(
          intent.resourceId,
          requireCommitted: false,
        );
        return _stateDecision(intent, state);
      case NotificationCategory.learningPathReady:
        final state = await validationApi.learningUpdate(
          intent.resourceId,
          requireCommitted: true,
        );
        return _stateDecision(
          intent,
          state,
          fallbackOverride: AppRoutes.learning,
        );
      case NotificationCategory.rewardReady:
        // No validation endpoint until T15 ships; progress is both
        // destination and stable parent (Flow §13.1).
        return const DeepLinkDecision(
          resolution: DeepLinkResolution.navigate,
          navigationPath: AppRoutes.progress,
        );
      case NotificationCategory.privacyExportReady:
        final state = await validationApi.privacyExport(intent.resourceId);
        return _stateDecision(
          intent,
          state,
          fallbackOverride: AppRoutes.privacy,
        );
    }
  }

  DeepLinkDecision _stateDecision(
    NotificationIntent intent,
    DeepLinkResourceState state, {
    String? fallbackOverride,
  }) {
    final target = resolveDeepLinkTarget(intent);
    final fallback = fallbackOverride ?? target.fallbackPath;
    switch (state) {
      case DeepLinkResourceState.valid:
        return DeepLinkDecision(
          resolution: DeepLinkResolution.navigate,
          navigationPath: target.destinationPath,
        );
      case DeepLinkResourceState.invalidState:
        return DeepLinkDecision(
          resolution: DeepLinkResolution.fallback,
          navigationPath: fallback,
          explanationLocKey: DeepLinkExplanations.workflowMovedOn,
        );
      case DeepLinkResourceState.missing:
        return DeepLinkDecision(
          resolution: DeepLinkResolution.fallback,
          navigationPath: fallback,
          explanationLocKey: DeepLinkExplanations.linkUnavailable,
        );
      case DeepLinkResourceState.unavailable:
        return DeepLinkDecision(
          resolution: DeepLinkResolution.fallback,
          navigationPath: fallback,
          explanationLocKey: DeepLinkExplanations.linkUnavailable,
        );
    }
  }
}
