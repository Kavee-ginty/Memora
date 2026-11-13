import 'dart:convert';

import '../../auth/data/secure_auth_storage.dart';

/// Durable consume-once ledger for push intents (Flow §20.3: a consumed
/// deep link is not replayed after later navigation; the record survives
/// process recreation).
///
/// The ledger is a bounded JSON list of notification ids in the OS-protected
/// key store. Oldest entries are trimmed at [_maxEntries] so the store never
/// grows unbounded. Notification ids carry no user content, so storing them
/// adds no sensitive material.
class ConsumedIntentLedger {
  static const String _storageKey = 'memora_consumed_intents';
  static const int _maxEntries = 200;

  final SecureKeyStore keyStore;

  ConsumedIntentLedger({required this.keyStore});

  Future<bool> alreadyConsumed(String notificationId) async {
    final ids = await _load();
    return ids.contains(notificationId);
  }

  /// Records the intent; returns whether consumption is durably recorded.
  ///
  /// A failed write returns ``false`` so the caller can refuse navigation:
  /// consume-once must never be silently skipped (Flow 20.3).
  Future<bool> markConsumed(String notificationId) async {
    if (notificationId.isEmpty) {
      return false;
    }
    final ids = await _load();
    if (ids.contains(notificationId)) {
      return true;
    }
    ids.add(notificationId);
    while (ids.length > _maxEntries) {
      ids.removeAt(0);
    }
    try {
      await keyStore.write(_storageKey, jsonEncode(ids));
      return true;
    } catch (_) {
      // The server-side delivery ledger still prevents duplicate pushes,
      // but client-side navigation is refused until consumption records.
      return false;
    }
  }

  Future<List<String>> _load() async {
    try {
      final raw = await keyStore.read(_storageKey);
      if (raw == null || raw.isEmpty) {
        return <String>[];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <String>[];
      }
      return decoded.whereType<String>().toList();
    } catch (_) {
      // Corrupt entries degrade to an empty ledger; replay protection then
      // leans on the destination guards and the server ledger.
      return <String>[];
    }
  }
}
