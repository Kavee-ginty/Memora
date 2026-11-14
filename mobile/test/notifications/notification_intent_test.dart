import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/notifications/domain/notification_intent.dart';

NotificationCategory? _category(String? wire) =>
    NotificationCategory.fromWire(wire);

Map<String, String> _validPayload({
  String category = 'mission_ready',
  String? notificationId = 'a1b2c3d4e5f60718293a4b5c6d7e8f90',
  String resourceId = '018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80',
  String? expiresAt,
}) {
  return {
    'schema_version': '1',
    'notification_id': notificationId!,
    'category': category,
    'route_intent': 'open_mission_preview',
    'resource_type': 'mission',
    'resource_id': resourceId,
    'expires_at': expiresAt ?? DateTime.utc(2099, 1, 1).toIso8601String(),
    'loc_key': 'notification.mission_ready',
    'param.subject_name': 'Physics',
    'param.count': '5',
  };
}

void main() {
  group('NotificationCategory.fromWire', () {
    test('resolves all six categories and rejects unknown values', () {
      expect(_category('mission_ready'), NotificationCategory.missionReady);
      expect(_category('due_memories'), NotificationCategory.dueMemories);
      expect(
        _category('verification_required'),
        NotificationCategory.verificationRequired,
      );
      expect(
        _category('learning_path_ready'),
        NotificationCategory.learningPathReady,
      );
      expect(_category('reward_ready'), NotificationCategory.rewardReady);
      expect(
        _category('privacy_export_ready'),
        NotificationCategory.privacyExportReady,
      );
      expect(_category('streak_nag'), isNull);
      expect(_category(null), isNull);
    });
  });

  group('NotificationIntent.parse', () {
    test('parses a valid payload with safe parameters', () {
      final intent = NotificationIntent.parse(_validPayload());

      expect(intent, isNotNull);
      expect(intent!.category, NotificationCategory.missionReady);
      expect(intent.routeIntent, 'open_mission_preview');
      expect(intent.resourceId, '018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80');
      expect(intent.subjectName, 'Physics');
      expect(intent.count, 5);
      expect(intent.locKey, 'notification.mission_ready');
      expect(intent.isExpired(DateTime.utc(2026, 1, 1)), isFalse);
    });

    test('rejects unknown schema versions', () {
      final payload = _validPayload()..['schema_version'] = '999';
      expect(NotificationIntent.parse(payload), isNull);
    });

    test('rejects unknown categories', () {
      final payload = _validPayload()..['category'] = 'streak_nag';
      expect(NotificationIntent.parse(payload), isNull);
    });

    test('rejects empty identifiers', () {
      expect(
        NotificationIntent.parse(_validPayload()..['notification_id'] = ''),
        isNull,
      );
      expect(NotificationIntent.parse(_validPayload(resourceId: '')), isNull);
    });

    test('rejects route-intent and loc-key registry mismatches', () {
      final payload = _validPayload()..['route_intent'] = 'open_reward_center';
      expect(NotificationIntent.parse(payload), isNull);

      final mismatchedKey = _validPayload()
        ..['loc_key'] = 'notification.reward_ready';
      expect(NotificationIntent.parse(mismatchedKey), isNull);
    });

    test('rejects unparseable and non-UTC expiries', () {
      expect(
        NotificationIntent.parse(_validPayload(expiresAt: 'not-a-date')),
        isNull,
      );
      expect(
        NotificationIntent.parse(
          _validPayload(expiresAt: '2026-05-01T10:00:00+05:30'),
        ),
        isNull,
      );
    });

    test('rejects non-integer counts', () {
      final payload = _validPayload()..['param.count'] = 'soon';
      expect(NotificationIntent.parse(payload), isNull);
    });

    test('rejects a missing or mismatched resource type', () {
      expect(
        NotificationIntent.parse(_validPayload()..remove('resource_type')),
        isNull,
      );
      expect(
        NotificationIntent.parse(
          _validPayload()..['resource_type'] = 'learning_update',
        ),
        isNull,
      );
    });

    test('rejects malformed resource identifiers', () {
      expect(
        NotificationIntent.parse(_validPayload()..['resource_id'] = 'short'),
        isNull,
      );
      expect(
        NotificationIntent.parse(
          _validPayload()..['resource_id'] = 'has spaces inside',
        ),
        isNull,
      );
      expect(
        NotificationIntent.parse(_validPayload()..['resource_id'] = 'a' * 65),
        isNull,
      );
      expect(
        NotificationIntent.parse(_validPayload()..['notification_id'] = 'tiny'),
        isNull,
      );
    });

    test('expired detection respects the boundary instant', () {
      final intent = NotificationIntent.parse(
        _validPayload(
          expiresAt: DateTime.utc(2026, 5, 1, 10).toIso8601String(),
        ),
      )!;

      expect(intent.isExpired(DateTime.utc(2026, 5, 1, 9, 59)), isFalse);
      expect(intent.isExpired(DateTime.utc(2026, 5, 1, 10)), isTrue);
    });
  });
}
