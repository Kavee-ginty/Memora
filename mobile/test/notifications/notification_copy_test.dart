import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/notifications/domain/notification_intent.dart';
import 'package:memora_mobile/src/features/notifications/presentation/notification_copy.dart';

NotificationIntent _intent({
  String locKey = 'notification.mission_ready',
  String? subjectName,
  int? count,
}) {
  final data = <String, String>{
    'schema_version': '1',
    'notification_id': 'a1b2c3d4e5f60718293a4b5c6d7e8f90',
    'category': 'mission_ready',
    'route_intent': 'open_mission_preview',
    'resource_type': 'mission',
    'resource_id': '018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80',
    'expires_at': DateTime.utc(2099, 1, 1).toIso8601String(),
    'loc_key': locKey,
  };
  if (subjectName != null) {
    data['param.subject_name'] = subjectName;
  }
  if (count != null) {
    data['param.count'] = '$count';
  }
  return NotificationIntent.parse(data)!;
}

void main() {
  group('NotificationCopy.forIntent', () {
    test('minimal band stays grammatical without any parameters', () {
      final intent = _intent();
      expect(
        NotificationCopy.forIntent(intent),
        'Your Physics daily mission is ready.',
      );
    });

    test('subject band names the curriculum subject (PRD 031)', () {
      final intent = _intent(subjectName: 'Physics');
      expect(
        NotificationCopy.forIntent(intent),
        'Your Physics daily mission is ready.',
      );
    });

    test('detailed band adds the duration clause', () {
      final intent = _intent(subjectName: 'Physics', count: 5);
      expect(
        NotificationCopy.forIntent(intent),
        'Your Physics daily mission is ready. About 5 minutes.',
      );
    });

    test('a count without a subject never leaves a dangling fragment', () {
      final intent = _intent(count: 5);
      expect(
        NotificationCopy.forIntent(intent),
        'Your Physics daily mission is ready. About 5 minutes.',
      );
    });

    test('non-mission categories render their fixed copy', () {
      final due = NotificationIntent.parse(<String, String>{
        'schema_version': '1',
        'notification_id': 'a1b2c3d4e5f60718293a4b5c6d7e8f90',
        'category': 'due_memories',
        'route_intent': 'open_mission_preview',
        'resource_type': 'mission',
        'resource_id': '018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80',
        'expires_at': DateTime.utc(2099, 1, 1).toIso8601String(),
        'loc_key': 'notification.due_memories',
      })!;
      expect(
        NotificationCopy.forIntent(due),
        'A few Physics memories are ready for care. Review when it suits you.',
      );
    });

    test('fallback explanations render calm copy', () {
      expect(
        NotificationCopy.forLocKey('notification.fallback.expired'),
        'That notification has expired.',
      );
      expect(
        NotificationCopy.forLocKey('notification.fallback.not_confirmed'),
        'That notification could not be opened. Please try again.',
      );
    });
  });
}
