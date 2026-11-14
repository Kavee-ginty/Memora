import 'package:flutter/foundation.dart';

/// A push message delivered through the notification gateway.
///
/// Only the flattened provider data payload is surfaced. The deep-link layer
/// (T19) validates every referenced resource through the API before
/// navigating, so this model intentionally carries no routing semantics.
@immutable
class NotificationMessage {
  final Map<String, String> data;

  const NotificationMessage({required this.data});

  factory NotificationMessage.fromRaw(Map<Object?, Object?>? raw) {
    final data = <String, String>{};
    raw?.forEach((key, value) {
      if (key is String && value is String) {
        data[key] = value;
      }
    });
    return NotificationMessage(data: data);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationMessage &&
          const MapEquality().equals(data, other.data);

  @override
  int get hashCode => const MapEquality().hash(data);
}

class MapEquality {
  const MapEquality();

  bool equals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final key in a.keys) {
      if (a[key] != b[key]) {
        return false;
      }
    }
    return true;
  }

  int hash(Map<String, String> map) => Object.hashAllUnordered(map.entries);
}
