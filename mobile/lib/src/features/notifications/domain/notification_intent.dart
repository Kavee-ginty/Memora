import 'package:flutter/foundation.dart';

/// Push notification categories, mirroring the closed backend registry
/// (Flow §13.1). Unknown wire values parse to `null` and the tap falls back
/// safely instead of crashing.
enum NotificationCategory {
  missionReady('mission_ready'),
  dueMemories('due_memories'),
  verificationRequired('verification_required'),
  learningPathReady('learning_path_ready'),
  rewardReady('reward_ready'),
  privacyExportReady('privacy_export_ready');

  final String wire;

  const NotificationCategory(this.wire);

  static NotificationCategory? fromWire(String? value) {
    for (final category in NotificationCategory.values) {
      if (category.wire == value) {
        return category;
      }
    }
    return null;
  }
}

/// A validated, typed push intent parsed from the flattened provider data
/// payload (API §16.2). Malformed payloads parse to `null`; callers fall
/// back safely (Task Table T19 acceptance gate).
@immutable
class NotificationIntent {
  static const String _schemaVersion = '1';

  final NotificationCategory category;
  final String routeIntent;
  final String resourceType;
  final String resourceId;
  final String notificationId;
  final DateTime expiresAt;
  final String locKey;
  final String? subjectName;
  final int? count;

  const NotificationIntent({
    required this.category,
    required this.routeIntent,
    required this.resourceType,
    required this.resourceId,
    required this.notificationId,
    required this.expiresAt,
    required this.locKey,
    this.subjectName,
    this.count,
  });

  /// Parses the flattened data map; `null` for anything malformed or from an
  /// unknown schema version. The route intent and localization key must match
  /// the category contract, so tampered payloads cannot redirect navigation.
  static NotificationIntent? parse(Map<String, String> data) {
    if (data['schema_version'] != _schemaVersion) {
      return null;
    }
    final category = NotificationCategory.fromWire(data['category']);
    if (category == null) {
      return null;
    }
    final notificationId = data['notification_id'] ?? '';
    final resourceId = data['resource_id'] ?? '';
    final routeIntent = data['route_intent'] ?? '';
    final locKey = data['loc_key'] ?? '';
    final resourceType = data['resource_type'] ?? '';
    final expiresRaw = data['expires_at'] ?? '';
    // Closed contract (API 16.2 mirror): identifiers are opaque and bounded,
    // and the resource type must match the category exactly as the backend
    // builder enforces. Malformed payloads never navigate.
    if (!_isOpaqueId(notificationId) || !_isOpaqueId(resourceId)) {
      return null;
    }
    if (resourceType != _expectedResourceType(category)) {
      return null;
    }
    // The wire contract emits Z-suffixed UTC only (payload_to_data);
    // anything else is malformed and must not navigate.
    final DateTime expiresAt;
    if (!expiresRaw.endsWith('Z')) {
      return null;
    }
    try {
      expiresAt = DateTime.parse(expiresRaw.replaceFirst('Z', '+00:00'));
      if (!expiresAt.isUtc) {
        return null;
      }
    } on FormatException {
      return null;
    }
    final expectedRouteIntent = _expectedRouteIntent(category);
    if (routeIntent != expectedRouteIntent ||
        locKey != _expectedLocKey(category)) {
      return null;
    }
    final subjectName = data['param.subject_name'];
    final countRaw = data['param.count'];
    int? count;
    if (countRaw != null) {
      count = int.tryParse(countRaw);
      if (count == null) {
        return null;
      }
    }
    return NotificationIntent(
      category: category,
      routeIntent: routeIntent,
      resourceType: resourceType,
      resourceId: resourceId,
      notificationId: notificationId,
      expiresAt: expiresAt.toUtc(),
      locKey: locKey,
      subjectName: subjectName,
      count: count,
    );
  }

  static String _expectedRouteIntent(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.missionReady:
      case NotificationCategory.dueMemories:
        return 'open_mission_preview';
      case NotificationCategory.verificationRequired:
        return 'open_verify_concepts';
      case NotificationCategory.learningPathReady:
        return 'open_path_preview';
      case NotificationCategory.rewardReady:
        return 'open_progress';
      case NotificationCategory.privacyExportReady:
        return 'open_export_status';
    }
  }

  static bool _isOpaqueId(String value) {
    if (value.length < 8 || value.length > 64) {
      return false;
    }
    return RegExp(r'^[0-9a-zA-Z_-]+$').hasMatch(value);
  }

  static String _expectedResourceType(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.missionReady:
      case NotificationCategory.dueMemories:
        return 'mission';
      case NotificationCategory.verificationRequired:
      case NotificationCategory.learningPathReady:
        return 'learning_update';
      case NotificationCategory.rewardReady:
        return 'reward_grant';
      case NotificationCategory.privacyExportReady:
        return 'privacy_request';
    }
  }

  static String _expectedLocKey(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.missionReady:
        return 'notification.mission_ready';
      case NotificationCategory.dueMemories:
        return 'notification.due_memories';
      case NotificationCategory.verificationRequired:
        return 'notification.verification_required';
      case NotificationCategory.learningPathReady:
        return 'notification.learning_path_ready';
      case NotificationCategory.rewardReady:
        return 'notification.reward_ready';
      case NotificationCategory.privacyExportReady:
        return 'notification.privacy_export_ready';
    }
  }

  /// Whether the intent is expired at [now] (send time and tap time).
  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationIntent &&
          other.category == category &&
          other.notificationId == notificationId &&
          other.resourceId == resourceId &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(category, notificationId, resourceId);
}
