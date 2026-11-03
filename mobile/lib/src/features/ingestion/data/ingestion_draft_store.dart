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

  /// Clears the draft and every operation key for [accountId].
  ///
  /// Called on discard, successful commit and sign-out (D8).
  Future<void> clearAccount(String accountId) async {
    _requireAccount(accountId);
    await _keyStore.delete(draftStorageKey(accountId));
    await _keyStore.delete(operationsStorageKey(accountId));
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
}
