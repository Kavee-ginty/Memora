import 'package:flutter/foundation.dart';

import '../domain/deep_link_coordinator.dart';
import '../domain/notification_intent.dart';

/// Contextual notification copy rendered on-device from wire localization
/// keys (UI/UX §9.21: replace generic push text with useful, calm copy).
/// Parameters interpolate only the safe band values the payload carries.
@immutable
class NotificationCopy {
  final String locKey;
  final String text;

  const NotificationCopy({required this.locKey, required this.text});

  static const Map<String, String> _templates = {
    'notification.mission_ready':
        'Your daily mission is ready. About {count} minutes.',
    'notification.due_memories':
        'A few memories are ready for care. Review when it suits you.',
    'notification.verification_required':
        'Your material needs a quick check before it joins your learning path.',
    'notification.learning_path_ready':
        'Your learning path is ready to preview.',
    'notification.reward_ready': 'Your reef decoration is ready to place.',
    'notification.privacy_export_ready':
        'Your data export is ready to download.',
    DeepLinkExplanations.linkExpired: 'That notification has expired.',
    DeepLinkExplanations.linkUnavailable:
        'That update is not available right now.',
    DeepLinkExplanations.workflowMovedOn: 'That workflow already moved on.',
    DeepLinkExplanations.malformedLink: 'That notification could not be read.',
  };

  /// Renders copy for a localization key; unknown keys degrade to neutral
  /// copy instead of surfacing raw wire values.
  static String forLocKey(String locKey) {
    return _templates[locKey] ?? 'You have a new update in Memora.';
  }

  /// Renders notification body copy for an intent, interpolating only the
  /// safe detail-band parameters ({subject_name}, {count}).
  static String forIntent(NotificationIntent intent) {
    var template = forLocKey(intent.locKey);
    if (intent.subjectName != null && template.contains('{subject_name}')) {
      template = template.replaceFirst('{subject_name}', intent.subjectName!);
    }
    if (intent.count != null && template.contains('{count}')) {
      template = template.replaceFirst('{count}', '${intent.count}');
    }
    return template
        .replaceAll('{subject_name}', '')
        .replaceAll('{count}', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
