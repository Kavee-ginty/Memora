import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_session_state.dart';
import '../../auth/domain/bootstrap_state.dart';
import '../../common/ids.dart';
import '../data/ingestion_draft_store.dart';
import '../data/ingestion_repository.dart';
import '../data/source_picker.dart';
import '../data/upload_client.dart';
import '../domain/ingestion_failure.dart';
import '../domain/ingestion_models.dart';

/// Longest manual text the server accepts (API §11.1).
const int maxManualTextChars = 20000;

/// Repository used by the local baseline and tests. The running application
/// overrides it with the generated-client implementation in `main.dart`.
final ingestionRepositoryProvider = Provider<IngestionRepository>((ref) {
  return MockIngestionRepository();
});

/// Presigned object-storage transport with no API credentials.
final uploadClientProvider = Provider<UploadClient>((ref) {
  return PresignedUploadClient();
});

/// Platform file/camera/gallery boundary.
final sourcePickerProvider = Provider<SourcePicker>((ref) {
  return PlatformSourcePicker();
});

/// Protected, account-scoped draft and operation-key storage.
final ingestionDraftStoreProvider = Provider<IngestionDraftStore>((ref) {
  return IngestionDraftStore(keyStore: ref.watch(secureKeyStoreProvider));
});

/// Add-material controller keyed by the route's subject id.
final ingestionFlowControllerProvider = StateNotifierProvider.autoDispose
    .family<IngestionFlowController, IngestionFlowState, String>((
      ref,
      subjectId,
    ) {
      final controller = IngestionFlowController(
        repository: ref.watch(ingestionRepositoryProvider),
        uploadClient: ref.watch(uploadClientProvider),
        sourcePicker: ref.watch(sourcePickerProvider),
        draftStore: ref.watch(ingestionDraftStoreProvider),
        sessionController: ref.watch(sessionControllerProvider.notifier),
        subjectId: subjectId,
      );
      unawaited(controller.initialize());
      return controller;
    });

/// Coarse screen stage. Durable update states live in [IngestionFlowState].
enum IngestionFlowStage { loading, editing, submitting, submitted }

/// Per-file state rendered by the source list (UI/UX §9.9).
enum LocalSourceState {
  queued,
  uploading,
  processing,
  ready,
  unsupported,
  failed,
}

/// One file selected on this device.
///
/// [bytes] is released as soon as the server confirms the upload, so the
/// submitted state never keeps file content in memory longer than needed.
@immutable
class LocalSource {
  final String id;
  final String name;
  final String mediaType;
  final int byteSize;
  final Uint8List? bytes;
  final LocalSourceState status;
  final double progress;
  final IngestionFailure? failure;
  final String? uploadId;
  final String? contentSha256;

  const LocalSource({
    required this.id,
    required this.name,
    required this.mediaType,
    required this.byteSize,
    required this.status,
    this.bytes,
    this.progress = 0,
    this.failure,
    this.uploadId,
    this.contentSha256,
  });

  LocalSource copy({
    LocalSourceState? status,
    double? progress,
    IngestionFailure? failure,
    bool clearFailure = false,
    String? uploadId,
    String? contentSha256,
    bool releaseBytes = false,
  }) {
    return LocalSource(
      id: id,
      name: name,
      mediaType: mediaType,
      byteSize: byteSize,
      bytes: releaseBytes ? null : bytes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      failure: clearFailure ? null : (failure ?? this.failure),
      uploadId: uploadId ?? this.uploadId,
      contentSha256: contentSha256 ?? this.contentSha256,
    );
  }
}

/// Immutable add-material state.
@immutable
class IngestionFlowState {
  final IngestionFlowStage stage;
  final String subjectId;
  final List<SubjectSummaryDomain> subjects;
  final String manualText;
  final DateTime learnedAt;
  final List<LocalSource> sources;
  final IngestionFailure? failure;
  final bool isOffline;
  final bool isSaving;
  final bool savedLocally;

  /// True once the server owns the declared composition. Editing is locked so
  /// the client never shows text that differs from what was submitted.
  final bool isLocked;
  final String? updateId;
  final int? rowVersion;
  final LearningUpdateState? updateState;

  /// Incremented when a protected draft is restored so the text field can adopt
  /// the restored value without fighting ordinary typing.
  final int restoredRevision;

  const IngestionFlowState({
    required this.stage,
    required this.subjectId,
    required this.subjects,
    required this.manualText,
    required this.learnedAt,
    this.sources = const <LocalSource>[],
    this.failure,
    this.isOffline = false,
    this.isSaving = false,
    this.savedLocally = false,
    this.isLocked = false,
    this.updateId,
    this.rowVersion,
    this.updateState,
    this.restoredRevision = 0,
  });

  bool get isServerDraft => updateState == LearningUpdateState.draft;

  bool get hasContent =>
      manualText.trim().isNotEmpty ||
      sources.any(
        (source) =>
            source.bytes != null || source.status == LocalSourceState.ready,
      );

  bool get hasBlockingSource => sources.any(
    (source) =>
        source.status == LocalSourceState.unsupported ||
        source.status == LocalSourceState.failed,
  );

  bool get hasFailedSource =>
      sources.any((source) => source.status == LocalSourceState.failed);

  bool get isOverTextLimit => manualText.length > maxManualTextChars;

  bool get canEditText => !isLocked && stage != IngestionFlowStage.submitting;

  bool get canSelectSubject =>
      !isLocked && !isServerDraft && stage != IngestionFlowStage.submitting;

  bool get canAddSource =>
      !isLocked &&
      !isServerDraft &&
      stage == IngestionFlowStage.editing &&
      sources.length < maxSourceCount;

  bool get canRemoveSource =>
      !isLocked && !isServerDraft && stage == IngestionFlowStage.editing;

  bool get canSaveDraft => stage != IngestionFlowStage.submitting && !isSaving;

  bool get canExtract {
    if (stage != IngestionFlowStage.editing || isSaving) return false;
    if (isOffline || isServerDraft) return false;
    if (isLocked) return true;
    if (isOverTextLimit || hasBlockingSource) return false;
    return hasContent;
  }

  /// Label for the single primary action. The normal flow uses the approved
  /// **Extract concepts** copy; a retry keeps the existing update identity.
  String get primaryActionLabel {
    if (!isLocked) return 'Extract concepts';
    return hasFailedSource ? 'Retry upload' : 'Continue';
  }

  IngestionFlowState copyWith({
    IngestionFlowStage? stage,
    String? subjectId,
    List<SubjectSummaryDomain>? subjects,
    String? manualText,
    DateTime? learnedAt,
    List<LocalSource>? sources,
    IngestionFailure? failure,
    bool clearFailure = false,
    bool? isOffline,
    bool? isSaving,
    bool? savedLocally,
    bool? isLocked,
    String? updateId,
    int? rowVersion,
    LearningUpdateState? updateState,
    int? restoredRevision,
  }) {
    return IngestionFlowState(
      stage: stage ?? this.stage,
      subjectId: subjectId ?? this.subjectId,
      subjects: subjects ?? this.subjects,
      manualText: manualText ?? this.manualText,
      learnedAt: learnedAt ?? this.learnedAt,
      sources: sources ?? this.sources,
      failure: clearFailure ? null : (failure ?? this.failure),
      isOffline: isOffline ?? this.isOffline,
      isSaving: isSaving ?? this.isSaving,
      savedLocally: savedLocally ?? this.savedLocally,
      isLocked: isLocked ?? this.isLocked,
      updateId: updateId ?? this.updateId,
      rowVersion: rowVersion ?? this.rowVersion,
      updateState: updateState ?? this.updateState,
      restoredRevision: restoredRevision ?? this.restoredRevision,
    );
  }
}

/// Orchestrates the add-material flow: protected draft, subject selection,
/// source picking, checksum, create, grant, upload progress, finalize and
/// discard.
///
/// Durable operation keys come from [IngestionDraftStore], so a retry after a
/// process restart converges on the same server update and upload (D4).
class IngestionFlowController extends StateNotifier<IngestionFlowState> {
  IngestionFlowController({
    required this.repository,
    required this.uploadClient,
    required this.sourcePicker,
    required this.draftStore,
    required this.sessionController,
    required String subjectId,
    this.resumedDraft,
    DateTime Function()? clock,
    this.draftDebounce = const Duration(milliseconds: 500),
  }) : _textKnown = resumedDraft == null,
       super(
         IngestionFlowState(
           stage: IngestionFlowStage.loading,
           subjectId: subjectId,
           subjects: _subjectsOf(sessionController.state),
           manualText: '',
           learnedAt: (clock ?? DateTime.now)().toUtc(),
           isLocked:
               resumedDraft != null &&
               resumedDraft.state != LearningUpdateState.draft,
           updateId: resumedDraft?.id,
           rowVersion: resumedDraft?.rowVersion,
           updateState: resumedDraft?.state,
         ),
       );

  final IngestionRepository repository;
  final UploadClient uploadClient;
  final SourcePicker sourcePicker;
  final IngestionDraftStore draftStore;
  final SessionController sessionController;
  final UpdateSnapshot? resumedDraft;
  final Duration draftDebounce;

  Timer? _draftTimer;

  /// Public read-only view for presentation code and widget tests.
  IngestionFlowState get currentState => state;

  /// False only for a resumed server draft whose local text is unavailable.
  /// In that case a PATCH omits `manual_text` instead of clearing it.
  bool _textKnown;

  String? get _accountId => sessionController.state.session?.userId;
  String? get _accessToken => sessionController.state.session?.accessToken;

  /// Restores the account-scoped draft, when it belongs to this subject.
  Future<void> initialize() async {
    final accountId = _accountId;
    if (accountId == null) {
      if (!mounted) return;
      state = state.copyWith(
        stage: IngestionFlowStage.editing,
        failure: IngestionFailure.expiredSession(),
      );
      return;
    }

    final draft = await draftStore.readDraft(accountId);
    if (!mounted) return;

    if (draft != null && draft.subjectId == state.subjectId) {
      _textKnown = true;
      state = state.copyWith(
        stage: IngestionFlowStage.editing,
        manualText: draft.manualText,
        learnedAt: draft.learnedAt,
        restoredRevision: state.restoredRevision + 1,
        savedLocally: true,
      );
      return;
    }

    state = state.copyWith(stage: IngestionFlowStage.editing);
  }

  void selectSubject(String subjectId) {
    if (!state.canSelectSubject || subjectId == state.subjectId) return;
    if (!state.subjects.any((subject) => subject.id == subjectId)) return;

    state = state.copyWith(subjectId: subjectId, savedLocally: false);
    _scheduleDraftSave();
  }

  void onManualTextChanged(String value) {
    if (!state.canEditText) return;
    _textKnown = true;
    state = state.copyWith(
      manualText: value,
      savedLocally: false,
      clearFailure: true,
    );
    _scheduleDraftSave();
  }

  Future<void> addDocument() => _pick(sourcePicker.pickDocument);

  Future<void> addCamera() => _pick(sourcePicker.pickCamera);

  Future<void> addGallery() => _pick(sourcePicker.pickGallery);

  Future<void> _pick(Future<PickedSource?> Function() pick) async {
    if (!state.canAddSource) return;

    try {
      final picked = await pick();
      if (!mounted || picked == null) return;

      if (state.sources.length >= maxSourceCount) {
        state = state.copyWith(failure: _tooManySources);
        return;
      }

      final source = LocalSource(
        id: generateUuid(),
        name: picked.name,
        mediaType: picked.mediaType,
        byteSize: picked.byteSize,
        bytes: picked.bytes,
        status: picked.isUsable
            ? LocalSourceState.queued
            : LocalSourceState.unsupported,
        failure: picked.failure,
      );
      state = state.copyWith(
        sources: <LocalSource>[...state.sources, source],
        clearFailure: true,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(failure: IngestionFailure.unknown());
    }
  }

  void removeSource(String id) {
    if (!state.canRemoveSource) return;
    state = state.copyWith(
      sources: state.sources
          .where((source) => source.id != id)
          .toList(growable: false),
    );
  }

  /// Persists the draft immediately and, for a server draft, PATCHes it with
  /// the fetched `row_version` (D4).
  Future<void> saveDraft() async {
    if (state.isSaving || state.stage == IngestionFlowStage.submitting) return;

    final accountId = _accountId;
    if (accountId == null) {
      await _expireSession();
      return;
    }

    state = state.copyWith(isSaving: true, clearFailure: true);
    await _persistDraft(accountId);
    if (!mounted) return;

    if (state.updateState != LearningUpdateState.draft) {
      state = state.copyWith(isSaving: false, savedLocally: true);
      return;
    }
    if (state.isOffline) {
      state = state.copyWith(isSaving: false, savedLocally: true);
      return;
    }

    final token = _accessToken;
    final updateId = state.updateId;
    final version = state.rowVersion;
    if (token == null || updateId == null || version == null) {
      state = state.copyWith(isSaving: false, savedLocally: true);
      return;
    }

    final operation = 'draft:$updateId:$version';
    try {
      final key = await _operationKey(accountId, operation);
      final updated = await repository.updateDraft(
        accessToken: token,
        updateId: updateId,
        version: version,
        idempotencyKey: key,
        learnedAt: state.learnedAt,
        manualText: _textKnown ? state.manualText : null,
      );
      if (!mounted) return;
      state = state.copyWith(
        rowVersion: updated.rowVersion,
        updateState: updated.state,
        isSaving: false,
        savedLocally: true,
        clearFailure: true,
      );
      await draftStore.clearOperationKey(
        accountId: accountId,
        operation: operation,
      );
    } on IngestionFailure catch (failure) {
      if (!mounted) return;
      if (failure.code == 'version_conflict') {
        await _refreshDraftVersion(
          accountId: accountId,
          token: token,
          updateId: updateId,
          failure: failure,
        );
        return;
      }
      state = state.copyWith(
        isSaving: false,
        savedLocally: true,
        failure: failure,
        isOffline: failure.code == 'network_error',
      );
      if (failure.code == 'expired_session') await _expireSession();
    }
  }

  Future<void> _refreshDraftVersion({
    required String accountId,
    required String token,
    required String updateId,
    required IngestionFailure failure,
  }) async {
    try {
      final latest = await repository.getUpdate(
        accessToken: token,
        updateId: updateId,
      );
      if (!mounted) return;
      state = state.copyWith(
        rowVersion: latest.rowVersion,
        updateState: latest.state,
        isSaving: false,
        savedLocally: true,
        failure: failure,
      );
    } on IngestionFailure catch (refreshFailure) {
      if (!mounted) return;
      state = state.copyWith(
        isSaving: false,
        savedLocally: true,
        failure: refreshFailure,
        isOffline: refreshFailure.code == 'network_error',
      );
    }
  }

  /// Creates the update (once per durable operation key) and uploads every
  /// selected file in order, reporting byte progress per file.
  Future<void> extractConcepts() async {
    if (!state.canExtract || state.isLocked) return;

    final accountId = _accountId;
    final token = _accessToken;
    if (accountId == null || token == null) {
      await _expireSession();
      return;
    }

    // Persist the latest text before the server owns the composition.
    await _persistDraft(accountId);
    if (!mounted) return;
    _draftTimer?.cancel();

    state = state.copyWith(
      stage: IngestionFlowStage.submitting,
      clearFailure: true,
      isOffline: false,
    );

    try {
      final prepared = await _prepareSources();
      if (!mounted) return;

      if (state.updateId == null) {
        try {
          final snapshot = await repository.createUpdate(
            accessToken: token,
            subjectId: state.subjectId,
            inputType: _inputType,
            learnedAt: state.learnedAt,
            clientOperationId: await _operationKey(
              accountId,
              'create_operation',
            ),
            idempotencyKey: await _operationKey(accountId, 'create'),
            manualText: state.manualText.trim().isEmpty
                ? null
                : state.manualText,
            files: prepared.values
                .map((upload) => upload.declaration)
                .toList(growable: false),
          );
          if (!mounted) return;
          state = state.copyWith(
            updateId: snapshot.id,
            rowVersion: snapshot.rowVersion,
            updateState: snapshot.state,
            isLocked: snapshot.state != LearningUpdateState.draft,
          );
        } on IngestionFailure catch (failure) {
          if (failure.code != 'idempotency_key_reused') rethrow;
          // The durable create identity collided with a changed body —
          // possible when a process died between the server processing the
          // create and this client restoring its state. Drop the stale
          // identity so the next attempt starts a fresh update; the abandoned
          // row expires server-side. The local draft is preserved (UIX-033).
          await draftStore.clearOperationKey(
            accountId: accountId,
            operation: 'create',
          );
          await draftStore.clearOperationKey(
            accountId: accountId,
            operation: 'create_operation',
          );
          if (!mounted) return;
          state = state.copyWith(
            stage: IngestionFlowStage.editing,
            failure: failure,
            isOffline: false,
          );
          return;
        }
      }

      final updateId = state.updateId;
      if (updateId == null) {
        state = state.copyWith(
          stage: IngestionFlowStage.editing,
          failure: IngestionFailure.unknown(),
        );
        return;
      }

      for (final source in List<LocalSource>.of(state.sources)) {
        if (source.status == LocalSourceState.ready) continue;
        final upload = prepared[source.id];
        if (upload == null) continue;
        await _uploadSource(
          source: source,
          upload: upload,
          updateId: updateId,
          token: token,
          accountId: accountId,
        );
        if (!mounted || state.failure != null) return;
      }

      await _completeSubmission(accountId: accountId);
    } on IngestionFailure catch (failure) {
      if (!mounted) return;
      state = state.copyWith(
        stage: IngestionFlowStage.editing,
        failure: failure,
        isOffline: failure.code == 'network_error',
      );
      if (failure.code == 'expired_session') await _expireSession();
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        stage: IngestionFlowStage.editing,
        failure: IngestionFailure.unknown(),
      );
    }
  }

  /// Retries the failed or queued files of an update that already exists.
  Future<void> retrySubmission() async {
    if (state.isOffline || state.stage == IngestionFlowStage.submitting) return;
    if (!state.isLocked) {
      await extractConcepts();
      return;
    }

    final accountId = _accountId;
    final token = _accessToken;
    final updateId = state.updateId;
    if (accountId == null || token == null || updateId == null) {
      await _expireSession();
      return;
    }

    final pending = state.sources
        .where(
          (source) =>
              source.status != LocalSourceState.ready && source.bytes != null,
        )
        .toList(growable: false);
    if (pending.isEmpty) {
      await _completeSubmission(accountId: accountId);
      return;
    }

    state = state.copyWith(
      stage: IngestionFlowStage.submitting,
      clearFailure: true,
      isOffline: false,
    );

    for (final source in pending) {
      final bytes = source.bytes;
      if (bytes == null) continue;
      try {
        final upload = await uploadClient.prepare(
          UploadSource(
            declaredName: source.name,
            declaredMediaType: source.mediaType,
            bytes: bytes,
          ),
        );
        await _uploadSource(
          source: source,
          upload: upload,
          updateId: updateId,
          token: token,
          accountId: accountId,
        );
        if (!mounted || state.failure != null) return;
      } on IngestionFailure catch (failure) {
        if (!mounted) return;
        _updateSource(
          source.id,
          (current) =>
              current.copy(status: LocalSourceState.failed, failure: failure),
        );
        state = state.copyWith(
          stage: IngestionFlowStage.editing,
          failure: failure,
          isOffline: failure.code == 'network_error',
        );
        return;
      }
    }

    if (!mounted) return;
    if (!state.sources.every(
      (source) => source.status == LocalSourceState.ready,
    )) {
      state = state.copyWith(stage: IngestionFlowStage.editing);
      return;
    }
    await _completeSubmission(accountId: accountId);
  }

  /// Retries one failed file while keeping the update identity.
  Future<void> retrySource(String id) async {
    LocalSource? source;
    for (final item in state.sources) {
      if (item.id == id) {
        source = item;
        break;
      }
    }
    if (source == null || source.bytes == null) return;
    if (state.stage == IngestionFlowStage.submitting) return;

    final accountId = _accountId;
    final token = _accessToken;
    if (accountId == null || token == null) {
      await _expireSession();
      return;
    }

    final updateId = state.updateId;
    if (updateId == null) {
      await extractConcepts();
      return;
    }

    state = state.copyWith(
      stage: IngestionFlowStage.submitting,
      clearFailure: true,
      isOffline: false,
    );

    try {
      final upload = await uploadClient.prepare(
        UploadSource(
          declaredName: source.name,
          declaredMediaType: source.mediaType,
          bytes: source.bytes!,
        ),
      );
      await _uploadSource(
        source: source,
        upload: upload,
        updateId: updateId,
        token: token,
        accountId: accountId,
      );
      if (!mounted || state.failure != null) return;

      if (state.sources.every(
        (item) => item.status == LocalSourceState.ready,
      )) {
        await _completeSubmission(accountId: accountId);
      } else {
        state = state.copyWith(stage: IngestionFlowStage.editing);
      }
    } on IngestionFailure catch (failure) {
      if (!mounted) return;
      _updateSource(
        id,
        (current) =>
            current.copy(status: LocalSourceState.failed, failure: failure),
      );
      state = state.copyWith(
        stage: IngestionFlowStage.editing,
        failure: failure,
        isOffline: failure.code == 'network_error',
      );
    }
  }

  /// Retries the last failed operation after the student taps the offline or
  /// failure banner action. Input is never discarded.
  Future<void> retryAfterFailure() async {
    if (state.stage == IngestionFlowStage.submitting) return;
    state = state.copyWith(isOffline: false, clearFailure: true);
    if (!state.canExtract) return;

    if (state.isLocked) {
      await retrySubmission();
    } else {
      await extractConcepts();
    }
  }

  /// Discards the server update (when one exists) and clears this submission's
  /// protected draft and operation keys. Returns false when cleanup could not
  /// complete.
  Future<bool> discard() async {
    _draftTimer?.cancel();
    final accountId = _accountId;
    if (accountId == null) {
      await _expireSession();
      return false;
    }

    final updateId = state.updateId;
    state = state.copyWith(isSaving: true, clearFailure: true);

    if (updateId != null) {
      final token = _accessToken;
      if (token == null) {
        await _expireSession();
        return false;
      }
      try {
        final operation = 'delete:$updateId';
        final key = await _operationKey(accountId, operation);
        await repository.deleteUpdate(
          accessToken: token,
          updateId: updateId,
          idempotencyKey: key,
        );
        await draftStore.clearOperationKey(
          accountId: accountId,
          operation: operation,
        );
      } on IngestionFailure catch (failure) {
        if (!mounted) return false;
        state = state.copyWith(
          isSaving: false,
          failure: failure,
          isOffline: failure.code == 'network_error',
        );
        if (failure.code == 'expired_session') await _expireSession();
        return false;
      }
    }

    await draftStore.clearSubmission(accountId: accountId, updateId: updateId);
    if (mounted) {
      state = state.copyWith(
        isSaving: false,
        savedLocally: true,
        clearFailure: true,
        isOffline: false,
      );
    }
    return true;
  }

  /// Saves the local draft immediately, cancelling a pending debounce.
  Future<void> flushDraft() async {
    _draftTimer?.cancel();
    final accountId = _accountId;
    if (accountId == null || state.isLocked) return;
    await _persistDraft(accountId);
  }

  Future<Map<String, PreparedUpload>> _prepareSources() async {
    final prepared = <String, PreparedUpload>{};
    for (final source in state.sources) {
      if (source.status == LocalSourceState.ready) continue;
      final bytes = source.bytes;
      if (bytes == null) continue;
      try {
        final upload = await uploadClient.prepare(
          UploadSource(
            declaredName: source.name,
            declaredMediaType: source.mediaType,
            bytes: bytes,
          ),
        );
        prepared[source.id] = upload;
        _updateSource(
          source.id,
          (current) => current.copy(
            contentSha256: upload.declaration.contentSha256,
            clearFailure: true,
          ),
        );
      } on IngestionFailure catch (failure) {
        _updateSource(
          source.id,
          (current) =>
              current.copy(status: LocalSourceState.failed, failure: failure),
        );
        rethrow;
      }
    }
    return prepared;
  }

  Future<void> _uploadSource({
    required LocalSource source,
    required PreparedUpload upload,
    required String updateId,
    required String token,
    required String accountId,
  }) async {
    final sha = upload.declaration.contentSha256;
    // Keys are scoped per update and file so the same file can be attached to
    // different updates without ever reusing one identity with a different
    // body (D4, FLOW-002).
    final grantOperation = 'grant:$updateId:$sha';
    final finalizeOperation = 'finalize:$updateId:$sha';
    final finalizeClientOperation = 'finalize_operation:$updateId:$sha';

    try {
      _updateSource(
        source.id,
        (current) => current.copy(
          status: LocalSourceState.uploading,
          progress: 0,
          clearFailure: true,
        ),
      );

      final grantKey = await _operationKey(accountId, grantOperation);
      final grant = await repository.createUploadGrant(
        accessToken: token,
        updateId: updateId,
        source: upload.declaration,
        idempotencyKey: grantKey,
      );
      _updateSource(
        source.id,
        (current) => current.copy(uploadId: grant.uploadId),
      );

      await uploadClient.upload(
        grant: grant,
        upload: upload,
        onProgress: (sent, total) {
          if (!mounted) return;
          final progress = total <= 0 ? 0.0 : (sent / total).clamp(0.0, 1.0);
          _updateSource(
            source.id,
            (current) => current.copy(progress: progress),
          );
        },
      );
      if (!mounted) return;

      _updateSource(
        source.id,
        (current) =>
            current.copy(status: LocalSourceState.processing, progress: 1),
      );

      final finalizeKey = await _operationKey(accountId, finalizeOperation);
      final finalizeClientId = await _operationKey(
        accountId,
        finalizeClientOperation,
      );
      final snapshot = await repository.finalizeUpload(
        accessToken: token,
        updateId: updateId,
        uploadId: grant.uploadId,
        observedSize: upload.declaration.byteSize,
        contentSha256: sha,
        clientOperationId: finalizeClientId,
        idempotencyKey: finalizeKey,
      );
      if (!mounted) return;

      _updateSource(
        source.id,
        (current) => current.copy(
          status: LocalSourceState.ready,
          progress: 1,
          releaseBytes: true,
          clearFailure: true,
        ),
      );
      state = state.copyWith(
        rowVersion: snapshot.rowVersion,
        updateState: snapshot.state,
        clearFailure: true,
      );

      await draftStore.clearOperationKey(
        accountId: accountId,
        operation: grantOperation,
      );
      await draftStore.clearOperationKey(
        accountId: accountId,
        operation: finalizeOperation,
      );
      await draftStore.clearOperationKey(
        accountId: accountId,
        operation: finalizeClientOperation,
      );
    } on IngestionFailure catch (failure) {
      if (!mounted) return;
      if (failure.code == 'idempotency_key_reused') {
        // A durable key collided with a different body. Drop the stale keys so
        // the retry issues a fresh single-purpose grant; finalize converges
        // server-side per upload (D4).
        await draftStore.clearOperationKey(
          accountId: accountId,
          operation: grantOperation,
        );
        await draftStore.clearOperationKey(
          accountId: accountId,
          operation: finalizeOperation,
        );
        await draftStore.clearOperationKey(
          accountId: accountId,
          operation: finalizeClientOperation,
        );
        if (!mounted) return;
      }
      _updateSource(
        source.id,
        (current) =>
            current.copy(status: LocalSourceState.failed, failure: failure),
      );
      state = state.copyWith(
        stage: IngestionFlowStage.editing,
        failure: failure,
        isOffline: failure.code == 'network_error',
      );
      if (failure.code == 'expired_session') await _expireSession();
    } catch (_) {
      if (!mounted) return;
      final failure = IngestionFailure.unknown();
      _updateSource(
        source.id,
        (current) =>
            current.copy(status: LocalSourceState.failed, failure: failure),
      );
      state = state.copyWith(
        stage: IngestionFlowStage.editing,
        failure: failure,
      );
    }
  }

  Future<void> _completeSubmission({required String accountId}) async {
    _draftTimer?.cancel();
    // The server owns the material now; this submission's protected draft and
    // completed keys are no longer needed (D8). Other updates keep theirs.
    await draftStore.clearSubmission(
      accountId: accountId,
      updateId: state.updateId,
    );
    if (!mounted) return;
    state = state.copyWith(
      stage: IngestionFlowStage.submitted,
      savedLocally: true,
      clearFailure: true,
      isOffline: false,
    );
  }

  Future<void> _persistDraft(String accountId) async {
    if (!_textKnown && state.manualText.isEmpty) return;
    await draftStore.saveDraft(
      accountId,
      IngestionDraft(
        subjectId: state.subjectId,
        manualText: state.manualText,
        learnedAt: state.learnedAt,
      ),
    );
    if (!mounted) return;
    state = state.copyWith(savedLocally: true);
  }

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(draftDebounce, () {
      final accountId = _accountId;
      if (accountId == null) return;
      unawaited(_persistDraft(accountId));
    });
  }

  Future<String> _operationKey(String accountId, String operation) {
    return draftStore.operationKey(accountId: accountId, operation: operation);
  }

  Future<void> _expireSession() async {
    await sessionController.handleExpiredSession();
  }

  void _updateSource(
    String id,
    LocalSource Function(LocalSource current) update,
  ) {
    final next = state.sources
        .map((source) => source.id == id ? update(source) : source)
        .toList(growable: false);
    state = state.copyWith(sources: next);
  }

  IngestionInputType get _inputType {
    final files = state.sources
        .where(
          (source) =>
              source.bytes != null &&
              source.status != LocalSourceState.unsupported,
        )
        .toList(growable: false);
    final hasText = state.manualText.trim().isNotEmpty;
    if (files.isEmpty) return IngestionInputType.manualText;

    final hasPdf = files.any((source) => source.mediaType == 'application/pdf');
    final hasImage = files.any(
      (source) => source.mediaType.startsWith('image/'),
    );
    if (hasText || (hasPdf && hasImage)) return IngestionInputType.mixed;
    return hasPdf ? IngestionInputType.pdf : IngestionInputType.image;
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    super.dispose();
  }
}

/// Clears protected ingestion drafts and operation keys when the signed-in
/// account changes or signs out (D8).
///
/// Watched once by the application shell so the cleanup is not tied to any one
/// screen's lifetime.
final ingestionSessionCleanupProvider = Provider<IngestionSessionCleanup>((
  ref,
) {
  return IngestionSessionCleanup(ref);
});

class IngestionSessionCleanup {
  IngestionSessionCleanup(this._ref) {
    _ref.listen<AppSessionState>(sessionControllerProvider, _onSessionChanged);
  }

  final Ref _ref;

  void _onSessionChanged(AppSessionState? previous, AppSessionState next) {
    final previousId = previous?.session?.userId;
    final nextId = next.session?.userId;
    if (previousId == null || previousId == nextId) return;
    unawaited(_ref.read(ingestionDraftStoreProvider).clearAccount(previousId));
  }
}

List<SubjectSummaryDomain> _subjectsOf(AppSessionState state) {
  return state.bootstrapData?.subjects ?? const <SubjectSummaryDomain>[];
}

const IngestionFailure _tooManySources = IngestionFailure(
  code: 'validation_failed',
  message: 'You can add up to 5 files to one material.',
  nextAction: 'Remove a file before adding another.',
);
