import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/ingestion/data/ingestion_draft_store.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_models.dart';

const String _accountA = 'account-a';
const String _accountB = 'account-b';
const String _subjectId = '22222222-2222-4222-8222-222222222222';

final RegExp _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

IngestionDraft _draft({
  String subjectId = _subjectId,
  String manualText = 'Newton first law',
  DateTime? learnedAt,
}) {
  return IngestionDraft(
    subjectId: subjectId,
    manualText: manualText,
    learnedAt: learnedAt ?? DateTime.utc(2026, 11, 1, 10),
  );
}

DecisionDraft _decision(String candidateId) {
  return DecisionDraft(
    candidateId: candidateId,
    candidateVersion: 1,
    kind: VerificationDecisionKind.accept,
  );
}

Future<Map<String, String>> _operationKeys(
  InMemorySecureKeyStore keyStore,
) async {
  final raw = await keyStore.read(
    IngestionDraftStore.operationsStorageKey(_accountA),
  );
  if (raw == null) return <String, String>{};
  final record = jsonDecode(raw) as Map<String, dynamic>;
  final keys = record['keys'] as Map<String, dynamic>;
  return <String, String>{
    for (final entry in keys.entries) entry.key: entry.value as String,
  };
}

void main() {
  late InMemorySecureKeyStore keyStore;
  late IngestionDraftStore store;

  setUp(() {
    keyStore = InMemorySecureKeyStore();
    store = IngestionDraftStore(keyStore: keyStore);
  });

  group('IngestionDraftStore drafts', () {
    test('persists and restores the protected draft', () async {
      await store.saveDraft(_accountA, _draft());

      final restored = await IngestionDraftStore(keyStore: keyStore)
          .readDraft(_accountA);

      expect(restored, isNotNull);
      expect(restored!.subjectId, _subjectId);
      expect(restored.manualText, 'Newton first law');
      expect(restored.learnedAt, DateTime.utc(2026, 11, 1, 10));
      expect(restored.isEmpty, isFalse);
    });

    test('overwrites the previous draft for the same account', () async {
      await store.saveDraft(_accountA, _draft(manualText: 'First'));
      await store.saveDraft(_accountA, _draft(manualText: 'Second'));

      final restored = await store.readDraft(_accountA);
      expect(restored!.manualText, 'Second');
    });

    test('round-trips an empty manual text draft', () async {
      await store.saveDraft(_accountA, _draft(manualText: ''));

      final restored = await store.readDraft(_accountA);
      expect(restored!.manualText, isEmpty);
      expect(restored.isEmpty, isTrue);
    });

    test('keeps drafts isolated between accounts', () async {
      await store.saveDraft(_accountA, _draft(manualText: 'Account A notes'));

      expect(await store.readDraft(_accountB), isNull);

      await store.saveDraft(_accountB, _draft(manualText: 'Account B notes'));
      expect((await store.readDraft(_accountA))!.manualText, 'Account A notes');
      expect((await store.readDraft(_accountB))!.manualText, 'Account B notes');

      await store.clearDraft(_accountA);
      expect(await store.readDraft(_accountA), isNull);
      expect((await store.readDraft(_accountB))!.manualText, 'Account B notes');
    });

    test('stores only the approved draft fields', () async {
      await store.saveDraft(_accountA, _draft());

      final raw = await keyStore.read(
        IngestionDraftStore.draftStorageKey(_accountA),
      );
      final record = jsonDecode(raw!) as Map<String, dynamic>;

      expect(record.keys.toSet(), <String>{
        'schema_version',
        'subject_id',
        'manual_text',
        'learned_at',
      });
      expect(raw, isNot(contains('path')));
      expect(raw, isNot(contains('bytes')));
      expect(raw, isNot(contains('fileName')));
    });

    test('rejects a draft without a subject', () async {
      await expectLater(
        store.saveDraft(_accountA, _draft(subjectId: '  ')),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('IngestionDraftStore corruption handling', () {
    test('discards malformed JSON', () async {
      final key = IngestionDraftStore.draftStorageKey(_accountA);
      await keyStore.write(key, '{not-json');

      expect(await store.readDraft(_accountA), isNull);
      expect(await keyStore.containsKey(key), isFalse);
    });

    test('discards an incompatible schema version', () async {
      final key = IngestionDraftStore.draftStorageKey(_accountA);
      await keyStore.write(
        key,
        jsonEncode(<String, dynamic>{
          'schema_version': 99,
          'subject_id': _subjectId,
          'manual_text': 'text',
          'learned_at': '2026-11-01T10:00:00Z',
        }),
      );

      expect(await store.readDraft(_accountA), isNull);
      expect(await keyStore.containsKey(key), isFalse);
    });

    test('discards missing or invalid fields', () async {
      final key = IngestionDraftStore.draftStorageKey(_accountA);
      final invalidRecords = <Map<String, dynamic>>[
        <String, dynamic>{'schema_version': 1, 'manual_text': 'text'},
        <String, dynamic>{
          'schema_version': 1,
          'subject_id': '',
          'manual_text': 'text',
          'learned_at': '2026-11-01T10:00:00Z',
        },
        <String, dynamic>{
          'schema_version': 1,
          'subject_id': _subjectId,
          'manual_text': 'text',
          'learned_at': 'not-a-date',
        },
        <String, dynamic>{
          'schema_version': 1,
          'subject_id': _subjectId,
          'manual_text': 42,
          'learned_at': '2026-11-01T10:00:00Z',
        },
      ];

      for (final record in invalidRecords) {
        await keyStore.write(key, jsonEncode(record));
        expect(await store.readDraft(_accountA), isNull);
        expect(await keyStore.containsKey(key), isFalse);
      }
    });

    test('discards a non-map payload', () async {
      final key = IngestionDraftStore.draftStorageKey(_accountA);
      await keyStore.write(key, jsonEncode(<String>['not', 'a', 'record']));

      expect(await store.readDraft(_accountA), isNull);
      expect(await keyStore.containsKey(key), isFalse);
    });
  });

  group('IngestionDraftStore operation keys', () {
    test(
      'returns one stable canonical key per account and operation',
      () async {
        final first = await store.operationKey(
          accountId: _accountA,
          operation: 'create',
        );
        final second = await store.operationKey(
          accountId: _accountA,
          operation: 'create',
        );

        expect(first, second);
        expect(_uuid.hasMatch(first), isTrue);

        final otherOperation = await store.operationKey(
          accountId: _accountA,
          operation: 'commit',
        );
        final otherAccount = await store.operationKey(
          accountId: _accountB,
          operation: 'create',
        );

        expect(otherOperation, isNot(first));
        expect(otherAccount, isNot(first));
      },
    );

    test('persists keys across store instances', () async {
      final first = await store.operationKey(
        accountId: _accountA,
        operation: 'grant:upload-1',
      );

      final second = await IngestionDraftStore(keyStore: keyStore)
          .operationKey(accountId: _accountA, operation: 'grant:upload-1');

      expect(second, first);
    });

    test('clears one completed key without touching the others', () async {
      final create = await store.operationKey(
        accountId: _accountA,
        operation: 'create',
      );
      final commit = await store.operationKey(
        accountId: _accountA,
        operation: 'commit',
      );

      await store.clearOperationKey(accountId: _accountA, operation: 'create');

      final newCreate = await store.operationKey(
        accountId: _accountA,
        operation: 'create',
      );
      final sameCommit = await store.operationKey(
        accountId: _accountA,
        operation: 'commit',
      );

      expect(newCreate, isNot(create));
      expect(sameCommit, commit);
    });

    test('clearOperations resets every key', () async {
      final create = await store.operationKey(
        accountId: _accountA,
        operation: 'create',
      );
      final commit = await store.operationKey(
        accountId: _accountA,
        operation: 'commit',
      );

      await store.clearOperations(_accountA);

      expect(
        await store.operationKey(accountId: _accountA, operation: 'create'),
        isNot(create),
      );
      expect(
        await store.operationKey(accountId: _accountA, operation: 'commit'),
        isNot(commit),
      );
    });

    test('discards a corrupt operation map and regenerates safely', () async {
      final storageKey = IngestionDraftStore.operationsStorageKey(_accountA);
      await keyStore.write(storageKey, '{broken');

      final generated = await store.operationKey(
        accountId: _accountA,
        operation: 'create',
      );

      expect(_uuid.hasMatch(generated), isTrue);
      expect(await keyStore.containsKey(storageKey), isTrue);
    });

    test('keeps valid keys while dropping corrupt entries', () async {
      final storageKey = IngestionDraftStore.operationsStorageKey(_accountA);
      const validKey = '11111111-1111-4111-8111-111111111111';
      await keyStore.write(
        storageKey,
        jsonEncode(<String, dynamic>{
          'schema_version': 1,
          'keys': <String, dynamic>{'create': validKey, 'commit': 'not-a-uuid'},
        }),
      );

      final preserved = await store.operationKey(
        accountId: _accountA,
        operation: 'create',
      );
      final regenerated = await store.operationKey(
        accountId: _accountA,
        operation: 'commit',
      );

      expect(preserved, validKey);
      expect(regenerated, isNot('not-a-uuid'));
      expect(_uuid.hasMatch(regenerated), isTrue);
    });

    test('rejects empty account or operation identifiers', () async {
      await expectLater(
        store.operationKey(accountId: '', operation: 'create'),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        store.operationKey(accountId: _accountA, operation: ' '),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('IngestionDraftStore account clearing', () {
    test('clearAccount removes the draft and every operation key', () async {
      await store.saveDraft(_accountA, _draft());
      await store.operationKey(accountId: _accountA, operation: 'create');
      await store.operationKey(accountId: _accountA, operation: 'commit');

      await store.clearAccount(_accountA);

      expect(await store.readDraft(_accountA), isNull);
      expect(
        await keyStore.containsKey(
          IngestionDraftStore.operationsStorageKey(_accountA),
        ),
        isFalse,
      );
      expect(
        await keyStore.containsKey(
          IngestionDraftStore.draftStorageKey(_accountA),
        ),
        isFalse,
      );
    });

    test('clearAccount never touches another account', () async {
      await store.saveDraft(_accountA, _draft(manualText: 'A'));
      await store.saveDraft(_accountB, _draft(manualText: 'B'));
      final keyB = await store.operationKey(
        accountId: _accountB,
        operation: 'create',
      );

      await store.clearAccount(_accountA);

      expect((await store.readDraft(_accountB))!.manualText, 'B');
      expect(
        await store.operationKey(accountId: _accountB, operation: 'create'),
        keyB,
      );
    });
  });

  group('IngestionDraftStore submission clearing', () {
    const String updateA = '11111111-1111-4111-8111-111111111111';
    const String updateB = '22222222-2222-4222-8222-222222222222';

    test('clears only the selected submission', () async {
      await store.saveDraft(_accountA, _draft());
      await store.operationKey(accountId: _accountA, operation: 'create');
      await store.operationKey(
        accountId: _accountA,
        operation: 'create_operation',
      );
      await store.operationKey(
        accountId: _accountA,
        operation: 'grant:$updateA:sha-a',
      );
      final otherKey = await store.operationKey(
        accountId: _accountA,
        operation: 'commit:$updateB',
      );
      await store.saveDecisionDrafts(
        accountId: _accountA,
        updateId: updateA,
        drafts: <String, DecisionDraft>{'c1': _decision('c1')},
      );
      await store.saveDecisionDrafts(
        accountId: _accountA,
        updateId: updateB,
        drafts: <String, DecisionDraft>{'c2': _decision('c2')},
      );

      await store.clearSubmission(accountId: _accountA, updateId: updateA);

      expect(await store.readDraft(_accountA), isNull);
      final keys = await _operationKeys(keyStore);
      expect(keys.containsKey('create'), isFalse);
      expect(keys.containsKey('create_operation'), isFalse);
      expect(keys.containsKey('grant:$updateA:sha-a'), isFalse);
      expect(keys['commit:$updateB'], otherKey);
      final decisions = await store.readDecisionDrafts(_accountA);
      expect(decisions.containsKey(updateA), isFalse);
      expect(decisions.containsKey(updateB), isTrue);
    });

    test(
      'without an update id clears the draft and create identities',
      () async {
        await store.saveDraft(_accountA, _draft());
        await store.operationKey(accountId: _accountA, operation: 'create');
        final otherKey = await store.operationKey(
          accountId: _accountA,
          operation: 'commit:$updateB',
        );

        await store.clearSubmission(accountId: _accountA);

        expect(await store.readDraft(_accountA), isNull);
        final keys = await _operationKeys(keyStore);
        expect(keys.containsKey('create'), isFalse);
        expect(keys['commit:$updateB'], otherKey);
      },
    );
  });
}
