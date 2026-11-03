import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../auth/data/secure_auth_storage.dart';
import '../../common/ids.dart';
import '../domain/ingestion_models.dart';

/// Protected, account-scoped storage for manual-text drafts and durable
/// operation keys (D4/D8).
///
/// The backing [SecureKeyStore] encrypts values at rest. Every storage key is
/// namespaced by the authenticated account id, so one account can never read
/// another account's draft or idempotency keys. Corrupt or incompatible
/// records are deleted and treated as absent instead of being surfaced.
///
/// Only the subject id, manual text and learning time are stored. File bytes
/// and picked-file paths are never persisted (D5/D8/D15).
class IngestionDraftStore {
  IngestionDraftStore({required this._keyStore});

  final SecureKeyStore _keyStore;

  static const int schemaVersion = 1;

  static const String _draftPrefix = 'memora_ingestion_draft';
  static const String _operationsPrefix = 'memora_ingestion_operations';
  static const String _decisionsPrefix = 'memora_ingestion_decisions';

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Storage key for [accountId]'s draft. Exposed for isolation tests.
  @visibleForTesting
  static String draftStorageKey(String accountId) => '$_draftPrefix:$accountId';

  /// Storage key for [accountId]'s operation-key map. Exposed for tests.
  @visibleForTesting
  static String operationsStorageKey(String accountId) =>
      '$_operationsPrefix:$accountId';

  /// Storage key for [accountId]'s unsent verification decisions. Exposed for
  /// tests.
  @visibleForTesting
  static String decisionsStorageKey(String accountId) =>
      '$_decisionsPrefix:$accountId';

  /// Reads the protected draft for [accountId], or null when none is stored.
  ///
  /// A malformed, wrong-version or incomplete record is deleted and reported
  /// as absent so the student starts from a clean editor.
  Future<IngestionDraft?> readDraft(String accountId) async {
    _requireAccount(accountId);
    final storageKey = draftStorageKey(accountId);
    final record = await _readRecord(storageKey);
    if (record == null) return null;

    if (record['schema_version'] != schemaVersion) {
      await _discard(storageKey);
      return null;
    }

    final subjectId = record['subject_id'];
    final manualText = record['manual_text'];
    final learnedAtRaw = record['learned_at'];
    if (subjectId is! String ||
        subjectId.trim().isEmpty ||
        manualText is! String ||
        learnedAtRaw is! String) {
      await _discard(storageKey);
      return null;
    }

    final learnedAt = DateTime.tryParse(learnedAtRaw);
    if (learnedAt == null) {
      await _discard(storageKey);
      return null;
    }

    return IngestionDraft(
      subjectId: subjectId,
      manualText: manualText,
      learnedAt: learnedAt.toUtc(),
    );
  }

  /// Persists [draft] for [accountId], replacing any previous draft.
  Future<void> saveDraft(String accountId, IngestionDraft draft) async {
    _requireAccount(accountId);
    if (draft.subjectId.trim().isEmpty) {
      throw ArgumentError.value(
        draft.subjectId,
        'draft.subjectId',
        'A draft must belong to a subject.',
      );
    }

    final encoded = jsonEncode(<String, dynamic>{
      'schema_version': schemaVersion,
      'subject_id': draft.subjectId,
      'manual_text': draft.manualText,
      'learned_at': draft.learnedAt.toUtc().toIso8601String(),
    });
    await _keyStore.write(draftStorageKey(accountId), encoded);
  }

  /// Removes only the protected draft, leaving operation keys untouched.
  Future<void> clearDraft(String accountId) async {
    _requireAccount(accountId);
    await _keyStore.delete(draftStorageKey(accountId));
  }

  /// Returns the durable idempotency key for [operation] under [accountId].
  ///
  /// The first call generates and persists a canonical UUID. Every later call
  /// for the same account and operation returns the same value, including after
  /// a process restart, until the operation is explicitly cleared (D4).
  Future<String> operationKey({
    required String accountId,
    required String operation,
  }) async {
    _requireAccount(accountId);
    _requireOperation(operation);

    final storageKey = operationsStorageKey(accountId);
    final keys = await _readOperations(storageKey);
    final existing = keys[operation];
    if (existing != null) return existing;

    final generated = generateUuid();
    keys[operation] = generated;
    await _writeOperations(storageKey, keys);
    return generated;
  }

  /// Clears one completed operation key.
  Future<void> clearOperationKey({
    required String accountId,
    required String operation,
  }) async {
    _requireAccount(accountId);
    _requireOperation(operation);

    final storageKey = operationsStorageKey(accountId);
    final keys = await _readOperations(storageKey);
    if (keys.remove(operation) == null) return;
    await _writeOperations(storageKey, keys);
  }

  /// Clears every operation key for [accountId].
  Future<void> clearOperations(String accountId) async {
    _requireAccount(accountId);
    await _keyStore.delete(operationsStorageKey(accountId));
  }

  /// Reads the persisted, unsent verification decisions for [accountId],
  /// keyed by update id.
  ///
  /// Decisions survive navigation and process death so concept edits persist
  /// through ordinary interruptions (UIX-033). Invalid entries are dropped;
  /// a malformed record is deleted and treated as absent.
  Future<Map<String, Map<String, DecisionDraft>>> readDecisionDrafts(
    String accountId,
  ) async {
    _requireAccount(accountId);
    final storageKey = decisionsStorageKey(accountId);
    final record = await _readRecord(storageKey);
    if (record == null) return <String, Map<String, DecisionDraft>>{};

    if (record['schema_version'] != schemaVersion) {
      await _discard(storageKey);
      return <String, Map<String, DecisionDraft>>{};
    }

    final raw = record['updates'];
    if (raw is! Map) {
      await _discard(storageKey);
      return <String, Map<String, DecisionDraft>>{};
    }

    final updates = <String, Map<String, DecisionDraft>>{};
    var changed = false;
    for (final entry in raw.entries) {
      final updateId = entry.key;
      if (updateId is! String || !_uuidPattern.hasMatch(updateId)) {
        changed = true;
        continue;
      }
      final drafts = <String, DecisionDraft>{};
      final items = entry.value is Map ? (entry.value as Map)['drafts'] : null;
      if (items is List) {
        for (final item in items) {
          final draft = _decodeDecisionDraft(item);
          if (draft == null) {
            changed = true;
            continue;
          }
          drafts[draft.candidateId] = draft;
        }
      } else {
        changed = true;
      }
      if (drafts.isNotEmpty) updates[updateId] = drafts;
    }

    if (changed) {
      await _writeDecisionDrafts(storageKey, updates);
    }
    return updates;
  }

  /// Persists the unsent decisions of one update for [accountId], replacing
  /// that update's entry. An empty [drafts] map removes the entry.
  Future<void> saveDecisionDrafts({
    required String accountId,
    required String updateId,
    required Map<String, DecisionDraft> drafts,
  }) async {
    _requireAccount(accountId);
    _requireUpdateId(updateId);

    final storageKey = decisionsStorageKey(accountId);
    final updates = await readDecisionDrafts(accountId);
    if (drafts.isEmpty) {
      if (!updates.containsKey(updateId)) return;
      updates.remove(updateId);
    } else {
      updates[updateId] = Map<String, DecisionDraft>.of(drafts);
    }
    await _writeDecisionDrafts(storageKey, updates);
  }

  /// Removes the persisted decisions of one update for [accountId].
  Future<void> clearDecisionDrafts({
    required String accountId,
    required String updateId,
  }) async {
    await saveDecisionDrafts(
      accountId: accountId,
      updateId: updateId,
      drafts: const <String, DecisionDraft>{},
    );
  }

  Map<String, dynamic>? _encodeDecisionDraft(DecisionDraft draft) {
    if (!draft.isValid) return null;
    return <String, dynamic>{
      'candidate_id': draft.candidateId,
      'candidate_version': draft.candidateVersion,
      'kind': draft.kind.name,
      if (draft.editedTitle != null) 'edited_title': draft.editedTitle,
      if (draft.mergeIntoCandidateId != null)
        'merge_into_candidate_id': draft.mergeIntoCandidateId,
    };
  }

  DecisionDraft? _decodeDecisionDraft(Object? item) {
    if (item is! Map) return null;
    final candidateId = item['candidate_id'];
    final candidateVersion = item['candidate_version'];
    final kindRaw = item['kind'];
    if (candidateId is! String ||
        candidateId.trim().isEmpty ||
        candidateVersion is! int ||
        kindRaw is! String) {
      return null;
    }

    final VerificationDecisionKind kind;
    try {
      kind = VerificationDecisionKind.values.byName(kindRaw);
    } catch (_) {
      return null;
    }

    final editedTitle = item['edited_title'];
    final mergeInto = item['merge_into_candidate_id'];
    final draft = DecisionDraft(
      candidateId: candidateId,
      candidateVersion: candidateVersion,
      kind: kind,
      editedTitle: editedTitle is String ? editedTitle : null,
      mergeIntoCandidateId: mergeInto is String ? mergeInto : null,
    );
    // Reject entries the API contract would reject so a persisted draft can
    // never block a submit.
    return draft.isValid ? draft : null;
  }

  Future<void> _writeDecisionDrafts(
    String storageKey,
    Map<String, Map<String, DecisionDraft>> updates,
  ) async {
    if (updates.isEmpty) {
      await _keyStore.delete(storageKey);
      return;
    }

    final encoded = <String, Map<String, dynamic>>{};
    for (final entry in updates.entries) {
      final drafts = <Map<String, dynamic>>[];
      for (final draft in entry.value.values) {
        final json = _encodeDecisionDraft(draft);
        if (json != null) drafts.add(json);
      }
      if (drafts.isNotEmpty) {
        encoded[entry.key] = <String, dynamic>{'drafts': drafts};
      }
    }

    if (encoded.isEmpty) {
      await _keyStore.delete(storageKey);
      return;
    }

    final record = jsonEncode(<String, dynamic>{
      'schema_version': schemaVersion,
      'updates': encoded,
    });
    await _keyStore.write(storageKey, record);
  }

  /// Clears the draft, every operation key and every unsent decision record
  /// for [accountId].
  ///
  /// Called on discard, successful commit and sign-out (D8).
  Future<void> clearAccount(String accountId) async {
    _requireAccount(accountId);
    await _keyStore.delete(draftStorageKey(accountId));
    await _keyStore.delete(operationsStorageKey(accountId));
    await _keyStore.delete(decisionsStorageKey(accountId));
  }

  Future<Map<String, dynamic>?> _readRecord(String storageKey) async {
    final raw = await _keyStore.read(storageKey);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await _discard(storageKey);
        return null;
      }
      return decoded.map<String, dynamic>(
        (Object? key, Object? value) =>
            MapEntry<String, dynamic>(key?.toString() ?? '', value),
      );
    } catch (_) {
      // Never surface corrupt storage content; delete it and start clean.
      await _discard(storageKey);
      return null;
    }
  }

  Future<Map<String, String>> _readOperations(String storageKey) async {
    final record = await _readRecord(storageKey);
    if (record == null) return <String, String>{};

    if (record['schema_version'] != schemaVersion) {
      await _discard(storageKey);
      return <String, String>{};
    }

    final raw = record['keys'];
    if (raw is! Map) {
      await _discard(storageKey);
      return <String, String>{};
    }

    final keys = <String, String>{};
    var discarded = false;
    for (final entry in raw.entries) {
      final operation = entry.key;
      final value = entry.value;
      if (operation is! String ||
          operation.trim().isEmpty ||
          value is! String ||
          !_uuidPattern.hasMatch(value)) {
        discarded = true;
        continue;
      }
      keys[operation] = value;
    }

    if (discarded) {
      // Keep valid identities; only the corrupt entries are dropped.
      await _writeOperations(storageKey, keys);
    }
    return keys;
  }

  Future<void> _writeOperations(
    String storageKey,
    Map<String, String> keys,
  ) async {
    if (keys.isEmpty) {
      await _keyStore.delete(storageKey);
      return;
    }

    final encoded = jsonEncode(<String, dynamic>{
      'schema_version': schemaVersion,
      'keys': keys,
    });
    await _keyStore.write(storageKey, encoded);
  }

  Future<void> _discard(String storageKey) => _keyStore.delete(storageKey);

  void _requireAccount(String accountId) {
    if (accountId.trim().isEmpty) {
      throw ArgumentError.value(
        accountId,
        'accountId',
        'An authenticated account is required.',
      );
    }
  }

  void _requireOperation(String operation) {
    if (operation.trim().isEmpty) {
      throw ArgumentError.value(
        operation,
        'operation',
        'An operation name is required.',
      );
    }
  }

  void _requireUpdateId(String updateId) {
    if (!_uuidPattern.hasMatch(updateId)) {
      throw ArgumentError.value(
        updateId,
        'updateId',
        'A canonical update id is required.',
      );
    }
  }
}
