import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/notifications/domain/consumed_intent_ledger.dart';

import 'device_token_registrar_test.dart' show InMemoryKeyStore;

void main() {
  group('ConsumedIntentLedger', () {
    test('records and reports consumed intents across instances', () async {
      final keyStore = InMemoryKeyStore();
      final ledger = ConsumedIntentLedger(keyStore: keyStore);

      expect(await ledger.alreadyConsumed('intent-1'), isFalse);
      await ledger.markConsumed('intent-1');

      // A fresh instance over the same store (process recreation) still
      // reports the intent consumed.
      final reopened = ConsumedIntentLedger(keyStore: keyStore);
      expect(await reopened.alreadyConsumed('intent-1'), isTrue);
      expect(await reopened.alreadyConsumed('intent-2'), isFalse);
    });

    test('trims oldest entries at the bounded size', () async {
      final keyStore = InMemoryKeyStore();
      final ledger = ConsumedIntentLedger(keyStore: keyStore);

      for (var i = 0; i < 210; i++) {
        await ledger.markConsumed('intent-$i');
      }

      final reopened = ConsumedIntentLedger(keyStore: keyStore);
      expect(await reopened.alreadyConsumed('intent-0'), isFalse);
      expect(await reopened.alreadyConsumed('intent-5'), isFalse);
      expect(await reopened.alreadyConsumed('intent-9'), isFalse);
      expect(await reopened.alreadyConsumed('intent-10'), isTrue);
      expect(await reopened.alreadyConsumed('intent-209'), isTrue);

      final stored = jsonDecode(
        keyStore.values['memora_consumed_intents']!,
      ) as List<dynamic>;
      expect(stored.length, 200);
    });

    test('corrupt store content degrades to an empty ledger', () async {
      final keyStore = InMemoryKeyStore()
        ..values['memora_consumed_intents'] = '{not json';
      final ledger = ConsumedIntentLedger(keyStore: keyStore);

      expect(await ledger.alreadyConsumed('intent-1'), isFalse);

      await ledger.markConsumed('intent-1');
      expect(await ledger.alreadyConsumed('intent-1'), isTrue);
    });

    test('ignores empty notification ids', () async {
      final keyStore = InMemoryKeyStore();
      final ledger = ConsumedIntentLedger(keyStore: keyStore);

      await ledger.markConsumed('');
      expect(keyStore.values.containsKey('memora_consumed_intents'), isFalse);
    });

    test('concurrent taps claim the same intent only once', () async {
      final ledger = ConsumedIntentLedger(keyStore: InMemoryKeyStore());

      final results = await Future.wait(<Future<bool>>[
        ledger.markConsumed('intent-1'),
        ledger.markConsumed('intent-1'),
      ]);

      expect(results, <bool>[true, false]);
    });

    test('concurrent writes preserve distinct intents', () async {
      final ledger = ConsumedIntentLedger(keyStore: InMemoryKeyStore());

      final results = await Future.wait(<Future<bool>>[
        ledger.markConsumed('intent-1'),
        ledger.markConsumed('intent-2'),
      ]);

      expect(results, <bool>[true, true]);
      expect(await ledger.alreadyConsumed('intent-1'), isTrue);
      expect(await ledger.alreadyConsumed('intent-2'), isTrue);
    });
  });
}
