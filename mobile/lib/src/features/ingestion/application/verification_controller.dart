import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/session_controller.dart';
import '../data/ingestion_draft_store.dart';
import '../data/ingestion_repository.dart';
import '../domain/ingestion_failure.dart';
import '../domain/ingestion_models.dart';
import 'ingestion_flow_controller.dart';

/// Which layer of the verify-concepts screen owns the current presentation.
enum VerificationStage {
  /// The authoritative update and first candidate page are loading.
  loading,

  /// Candidates are available for review.
  ready,

  /// The first read failed before any candidate could be shown.
  failed,

  /// The update does not exist for this account (indistinguishable 404).
  notFound,

  /// The update is no longer in `verification_required` (D13). The screen
  /// redirects to material status and explains the safe outcome.
  invalidState,
}

/// Immutable state of the concept-verification step (UI/UX §9.10, D10).
@immutable
class VerificationState {
  final VerificationStage stage;
  final UpdateSnapshot? update;
  final List<CandidateItem> candidates;

  /// Local, not-yet-submitted decisions keyed by candidate id.
  final Map<String, DecisionDraft> drafts;
  final IngestionFailure? failure;
  final bool isOffline;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final String? nextCursor;
  final bool isSubmitting;

  /// Only controls affected by the in-flight batch lock (D10).
  final Set<String> lockedCandidateIds;

  /// Explains a refresh after a stale candidate or an already-advanced update.
  final String? conflictNotice;

  const VerificationState({
    this.stage = VerificationStage.loading,
    this.update,
    this.candidates = const <CandidateItem>[],
    this.drafts = const <String, DecisionDraft>{},
    this.failure,
    this.isOffline = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.nextCursor,
    this.isSubmitting = false,
    this.lockedCandidateIds = const <String>{},
    this.conflictNotice,
  });

  bool get isLoading => stage == VerificationStage.loading;

  bool get isNotFound => stage == VerificationStage.notFound;

  bool get isInvalidState => stage == VerificationStage.invalidState;

  /// High-confidence candidates are accepted by the server and included by
  /// default; rejected or expired candidates never count as valid concepts.
  List<CandidateItem> get readyCandidates => candidates
      .where(
        (candidate) =>
            !candidate.needsReview &&
            candidate.status != CandidateState.rejected &&
            candidate.status != CandidateState.expired,
      )
      .toList(growable: false);

  /// Uncertain candidates marked **Check this** that still need a decision.
  List<CandidateItem> get reviewCandidates => candidates
      .where(
        (candidate) =>
            candidate.needsReview &&
            candidate.status != CandidateState.rejected &&
            candidate.status != CandidateState.expired,
      )
      .toList(growable: false);

  DecisionDraft? draftFor(String candidateId) => drafts[candidateId];

  /// Whether one candidate contributes a concept to the learning path.
  bool isIncluded(CandidateItem candidate) {
    if (candidate.status == CandidateState.rejected ||
        candidate.status == CandidateState.expired) {
      return false;
    }
    if (!candidate.needsReview) return true;

    final draft = drafts[candidate.id];
    if (draft == null) return false;
    return draft.kind != VerificationDecisionKind.reject;
  }

  int get includedCount => candidates.where(isIncluded).length;

  int get unresolvedCount => reviewCandidates
      .where((candidate) => !drafts.containsKey(candidate.id))
      .length;

  bool get canPreview =>
      stage == VerificationStage.ready && !isSubmitting && includedCount > 0;

  /// The only reason the primary action is disabled (UI/UX §9.10).
  String? get previewDisabledReason {
    if (stage != VerificationStage.ready) return null;
    if (candidates.isEmpty) {
      return 'No concepts were found in this material.';
    }
    if (includedCount == 0) {
      return 'Keep at least one concept to preview your learning path.';
    }
    return null;
  }

  VerificationState copyWith({
    VerificationStage? stage,
    UpdateSnapshot? update,
    List<CandidateItem>? candidates,
    Map<String, DecisionDraft>? drafts,
    IngestionFailure? failure,
    bool clearFailure = false,
    bool? isOffline,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isSubmitting,
    Set<String>? lockedCandidateIds,
    String? conflictNotice,
    bool clearConflictNotice = false,
  }) {
    return VerificationState(
      stage: stage ?? this.stage,
      update: update ?? this.update,
      candidates: candidates ?? this.candidates,
      drafts: drafts ?? this.drafts,
      failure: clearFailure ? null : (failure ?? this.failure),
      isOffline: isOffline ?? this.isOffline,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lockedCandidateIds: lockedCandidateIds ?? this.lockedCandidateIds,
      conflictNotice: clearConflictNotice
          ? null
          : (conflictNotice ?? this.conflictNotice),
    );
  }
}

/// Loads extraction candidates, keeps edits local and submits one idempotent
/// decision batch (UI/UX §9.10, Flow §9.4, D10).
class VerificationController extends StateNotifier<VerificationState> {
  VerificationController({
    required this.repository,
    required this.draftStore,
    required this.sessionController,
    required this.updateId,
    this.pageSize = 20,
  }) : super(const VerificationState());

  final IngestionRepository repository;
  final IngestionDraftStore draftStore;
  final SessionController sessionController;
  final String updateId;
  final int pageSize;

  bool _initialized = false;
  int _requestId = 0;

  /// Public read-only view for presentation code and widget tests.
  VerificationState get currentState => state;

  String? get _accountId => sessionController.state.session?.userId;
  String? get _accessToken => sessionController.state.session?.accessToken;

  /// Reads the authoritative update and the first candidate page on entry.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _load(initial: true);
  }

  /// Re-reads the update and candidates, keeping safe local edits (UIX-033).
  Future<void> refresh() async {
    if (state.isRefreshing || state.isSubmitting) return;
    await _load(preserveDrafts: true);
  }

  /// Loads the next candidate page without discarding local decisions.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isSubmitting) return;

    final token = _accessToken;
    if (token == null) {
      await _expireSession();
      return;
    }

    final requestId = ++_requestId;
    state = state.copyWith(isLoadingMore: true, clearFailure: true);
    try {
      final page = await repository.listCandidates(
        accessToken: token,
        updateId: updateId,
        cursor: state.nextCursor,
        limit: pageSize,
      );
      if (!mounted || requestId != _requestId) return;

      final byId = <String, CandidateItem>{
        for (final candidate in state.candidates) candidate.id: candidate,
      };
      final merged = List<CandidateItem>.of(state.candidates);
      for (final candidate in page.items) {
        if (byId.containsKey(candidate.id)) continue;
        byId[candidate.id] = candidate;
        merged.add(candidate);
      }

      state = state.copyWith(
        candidates: List<CandidateItem>.unmodifiable(merged),
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
        clearNextCursor: page.nextCursor == null,
        isLoadingMore: false,
      );
    } on IngestionFailure catch (failure) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(
        isLoadingMore: false,
        failure: failure,
        isOffline: failure.code == 'network_error',
      );
      if (failure.code == 'expired_session') await _expireSession();
    }
  }

  /// Marks one uncertain candidate as accepted (no corrected payload).
  void accept(String candidateId) {
    final candidate = _reviewCandidate(candidateId);
    if (candidate == null) return;
    _setDraft(
      DecisionDraft(
        candidateId: candidate.id,
        candidateVersion: candidate.candidateVersion,
        kind: VerificationDecisionKind.accept,
      ),
    );
  }

  /// Removes one uncertain candidate from the learning path.
  void reject(String candidateId) {
    final candidate = _reviewCandidate(candidateId);
    if (candidate == null) return;
    _setDraft(
      DecisionDraft(
        candidateId: candidate.id,
        candidateVersion: candidate.candidateVersion,
        kind: VerificationDecisionKind.reject,
      ),
    );
  }

  /// Renames one uncertain candidate. The edit stays local until submission.
  void editTitle(String candidateId, String title) {
    final candidate = _reviewCandidate(candidateId);
    if (candidate == null) return;
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > 240) return;
    _setDraft(
      DecisionDraft(
        candidateId: candidate.id,
        candidateVersion: candidate.candidateVersion,
        kind: VerificationDecisionKind.edit,
        editedTitle: trimmed,
      ),
    );
  }

  /// Merges one uncertain duplicate into another retained concept.
  void mergeInto(String candidateId, String targetCandidateId) {
    final candidate = _reviewCandidate(candidateId);
    if (candidate == null || candidateId == targetCandidateId) return;

    final target = _candidateById(targetCandidateId);
    if (target == null || !state.isIncluded(target)) return;

    _setDraft(
      DecisionDraft(
        candidateId: candidate.id,
        candidateVersion: candidate.candidateVersion,
        kind: VerificationDecisionKind.merge,
        mergeIntoCandidateId: targetCandidateId,
      ),
    );
  }

  /// Discards the local decision for one candidate.
  void clearDecision(String candidateId) {
    if (!state.drafts.containsKey(candidateId)) return;
    final next = Map<String, DecisionDraft>.of(state.drafts)
      ..remove(candidateId);
    state = state.copyWith(
      drafts: Map<String, DecisionDraft>.unmodifiable(next),
    );
  }

  /// Submits every local decision in one idempotent batch, then reports whether
  /// the screen may open the learning-path preview.
  ///
  /// A double tap is absorbed by [VerificationState.isSubmitting]. The durable
  /// key is reused after a transient failure and cleared after success.
  Future<bool> submitAndContinue() async {
    if (!state.canPreview || state.isSubmitting) return false;

    final decisions = _decisions();
    if (decisions.isEmpty) return true;

    final accountId = _accountId;
    final token = _accessToken;
    if (accountId == null || token == null) {
      await _expireSession();
      return false;
    }

    final affected = decisions.map((decision) => decision.candidateId).toSet();
    state = state.copyWith(
      isSubmitting: true,
      lockedCandidateIds: Set<String>.unmodifiable(affected),
      clearFailure: true,
      clearConflictNotice: true,
      isOffline: false,
    );

    final operation = _operationFor(decisions);
    try {
      final key = await draftStore.operationKey(
        accountId: accountId,
        operation: operation,
      );
      final outcome = await repository.submitDecisions(
        accessToken: token,
        updateId: updateId,
        decisions: decisions,
        idempotencyKey: key,
      );
      await draftStore.clearOperationKey(
        accountId: accountId,
        operation: operation,
      );
      if (!mounted) return false;

      final nextDrafts = Map<String, DecisionDraft>.of(state.drafts);
      for (final decision in decisions) {
        nextDrafts.remove(decision.candidateId);
      }
      state = state.copyWith(
        update: outcome.update,
        candidates: List<CandidateItem>.unmodifiable(
          _applyOutcomes(state.candidates, outcome.outcomes, decisions),
        ),
        drafts: Map<String, DecisionDraft>.unmodifiable(nextDrafts),
        isSubmitting: false,
        lockedCandidateIds: const <String>{},
        clearFailure: true,
      );
      return true;
    } on IngestionFailure catch (failure) {
      if (!mounted) return false;

      if (failure.code == 'version_conflict' ||
          failure.code == 'invalid_state') {
        await draftStore.clearOperationKey(
          accountId: accountId,
          operation: operation,
        );
        await _load(preserveDrafts: true);
        if (!mounted) return false;
        if (state.isInvalidState) return false;
        state = state.copyWith(
          isSubmitting: false,
          lockedCandidateIds: const <String>{},
          conflictNotice:
              'These concepts changed while you were reviewing them. The '
              'latest version is shown, and your decisions were kept where '
              'they still apply.',
        );
        return false;
      }

      state = state.copyWith(
        isSubmitting: false,
        lockedCandidateIds: const <String>{},
        failure: failure,
        isOffline: failure.code == 'network_error',
      );
      if (failure.code == 'expired_session') await _expireSession();
      return false;
    }
  }

  Future<void> _load({
    bool initial = false,
    bool preserveDrafts = false,
  }) async {
    final token = _accessToken;
    if (token == null) {
      await _expireSession();
      return;
    }

    final requestId = ++_requestId;
    if (!initial) {
      state = state.copyWith(
        isRefreshing: true,
        clearFailure: true,
        clearConflictNotice: true,
      );
    }

    try {
      final update = await repository.getUpdate(
        accessToken: token,
        updateId: updateId,
      );
      if (!mounted || requestId != _requestId) return;

      if (update.state != LearningUpdateState.verificationRequired) {
        state = state.copyWith(
          stage: VerificationStage.invalidState,
          update: update,
          isRefreshing: false,
          isSubmitting: false,
          lockedCandidateIds: const <String>{},
          clearFailure: true,
        );
        return;
      }

      final page = await repository.listCandidates(
        accessToken: token,
        updateId: updateId,
        limit: pageSize,
      );
      if (!mounted || requestId != _requestId) return;

      final drafts = preserveDrafts
          ? _reconcileDrafts(state.candidates, page.items, state.drafts)
          : const <String, DecisionDraft>{};
      state = VerificationState(
        stage: VerificationStage.ready,
        update: update,
        candidates: List<CandidateItem>.unmodifiable(page.items),
        drafts: Map<String, DecisionDraft>.unmodifiable(drafts),
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      );
    } on IngestionFailure catch (failure) {
      if (!mounted || requestId != _requestId) return;
      await _handleLoadFailure(failure);
    }
  }

  Future<void> _handleLoadFailure(IngestionFailure failure) async {
    if (failure.code == 'resource_not_found') {
      state = state.copyWith(
        stage: VerificationStage.notFound,
        isRefreshing: false,
        isSubmitting: false,
        lockedCandidateIds: const <String>{},
      );
      return;
    }

    final hasData = state.update != null || state.candidates.isNotEmpty;
    state = state.copyWith(
      stage: hasData ? VerificationStage.ready : VerificationStage.failed,
      failure: failure,
      isOffline: failure.code == 'network_error',
      isRefreshing: false,
      isSubmitting: false,
      lockedCandidateIds: const <String>{},
    );

    if (failure.code == 'expired_session') await _expireSession();
  }

  CandidateItem? _reviewCandidate(String candidateId) {
    if (state.isSubmitting || state.stage != VerificationStage.ready) {
      return null;
    }
    final candidate = _candidateById(candidateId);
    if (candidate == null || !candidate.needsReview) return null;
    return candidate;
  }

  CandidateItem? _candidateById(String candidateId) {
    for (final candidate in state.candidates) {
      if (candidate.id == candidateId) return candidate;
    }
    return null;
  }

  void _setDraft(DecisionDraft draft) {
    final next = Map<String, DecisionDraft>.of(state.drafts)
      ..[draft.candidateId] = draft;
    state = state.copyWith(
      drafts: Map<String, DecisionDraft>.unmodifiable(next),
      clearConflictNotice: true,
    );
  }

  List<DecisionDraft> _decisions() {
    final decisions = <DecisionDraft>[];
    for (final candidate in state.reviewCandidates) {
      final draft = state.drafts[candidate.id];
      if (draft == null || !draft.isValid) continue;
      decisions.add(draft);
    }
    return List<DecisionDraft>.unmodifiable(decisions);
  }

  /// One durable key per logical batch. A changed batch gets a new identity,
  /// while retrying the same batch reuses the stored key (D4).
  String _operationFor(List<DecisionDraft> decisions) {
    final parts =
        decisions
            .map(
              (decision) => <String>[
                decision.candidateId,
                '${decision.candidateVersion}',
                decision.kind.name,
                decision.editedTitle ?? '',
                decision.mergeIntoCandidateId ?? '',
              ].join('|'),
            )
            .toList(growable: false)
          ..sort();
    final digest = sha256.convert(utf8.encode(parts.join('\n')));
    return 'verification_decisions:$updateId:$digest';
  }

  List<CandidateItem> _applyOutcomes(
    List<CandidateItem> current,
    List<DecisionOutcome> outcomes,
    List<DecisionDraft> decisions,
  ) {
    final outcomeById = <String, DecisionOutcome>{
      for (final outcome in outcomes) outcome.candidateId: outcome,
    };
    final decisionById = <String, DecisionDraft>{
      for (final decision in decisions) decision.candidateId: decision,
    };
    return current
        .map((candidate) {
          final outcome = outcomeById[candidate.id];
          if (outcome == null) return candidate;
          final decision = decisionById[candidate.id];
          return CandidateItem(
            id: candidate.id,
            candidateType: candidate.candidateType,
            displayTitle:
                decision?.editedTitle?.trim() ?? candidate.displayTitle,
            displaySummary: candidate.displaySummary,
            sourceContext: candidate.sourceContext,
            confidence: candidate.confidence,
            band: candidate.band,
            requiresVerification: outcome.requiresVerification,
            status: outcome.state,
            candidateVersion: candidate.candidateVersion,
          );
        })
        .toList(growable: false);
  }

  /// Keeps a local decision only when the refreshed candidate is still open and
  /// its content did not change underneath the editor (UIX-033).
  Map<String, DecisionDraft> _reconcileDrafts(
    List<CandidateItem> oldCandidates,
    List<CandidateItem> newCandidates,
    Map<String, DecisionDraft> drafts,
  ) {
    if (drafts.isEmpty) return <String, DecisionDraft>{};

    final oldById = <String, CandidateItem>{
      for (final candidate in oldCandidates) candidate.id: candidate,
    };
    final newById = <String, CandidateItem>{
      for (final candidate in newCandidates) candidate.id: candidate,
    };

    final kept = <String, DecisionDraft>{};
    for (final entry in drafts.entries) {
      final oldCandidate = oldById[entry.key];
      final newCandidate = newById[entry.key];
      final draft = entry.value;
      if (oldCandidate == null ||
          newCandidate == null ||
          !newCandidate.needsReview) {
        continue;
      }

      if (draft.kind == VerificationDecisionKind.edit &&
          oldCandidate.displayTitle != newCandidate.displayTitle) {
        continue;
      }

      if (draft.kind == VerificationDecisionKind.merge) {
        final target = newById[draft.mergeIntoCandidateId];
        if (target == null ||
            target.status == CandidateState.rejected ||
            target.status == CandidateState.expired) {
          continue;
        }
      }

      kept[entry.key] = DecisionDraft(
        candidateId: entry.key,
        candidateVersion: newCandidate.candidateVersion,
        kind: draft.kind,
        editedTitle: draft.editedTitle,
        mergeIntoCandidateId: draft.mergeIntoCandidateId,
      );
    }
    return kept;
  }

  Future<void> _expireSession() async {
    await sessionController.handleExpiredSession();
  }
}

/// Which layer of the learning-path preview screen owns the presentation.
enum PathPreviewStage {
  /// The authoritative update and preview are loading.
  loading,

  /// The path can be reviewed, and commit may or may not be allowed.
  ready,

  /// The material is already part of the learning path.
  committed,

  /// The first read failed before a preview could be shown.
  failed,

  /// The update does not exist for this account (indistinguishable 404).
  notFound,

  /// The update is not previewable (D13). The screen returns to status.
  invalidState,
}

/// Immutable state of the learning-path preview step (UI/UX §9.11, D11).
@immutable
class PathPreviewState {
  final PathPreviewStage stage;
  final UpdateSnapshot? update;
  final PathPreview? preview;

  /// Present after this screen performed the commit, or after a replay.
  final CommitOutcome? outcome;

  /// Resolved from the session bootstrap for the preview summary.
  final String? subjectName;
  final IngestionFailure? failure;
  final bool isOffline;
  final bool isRefreshing;
  final bool isCommitting;

  /// Explains a refresh after the material changed or was already committed.
  final String? notice;

  const PathPreviewState({
    this.stage = PathPreviewStage.loading,
    this.update,
    this.preview,
    this.outcome,
    this.subjectName,
    this.failure,
    this.isOffline = false,
    this.isRefreshing = false,
    this.isCommitting = false,
    this.notice,
  });

  bool get isLoading => stage == PathPreviewStage.loading;

  bool get isNotFound => stage == PathPreviewStage.notFound;

  bool get isInvalidState => stage == PathPreviewStage.invalidState;

  bool get isCommitted => stage == PathPreviewStage.committed;

  /// The number of concepts that are part of, or will join, the path.
  int get conceptCount =>
      outcome?.conceptMappings.length ?? preview?.conceptCount ?? 0;

  /// Bounded list shown on the preview and ready states.
  List<PreviewConcept> get firstConcepts {
    final concepts =
        outcome?.conceptMappings ?? preview?.firstConcepts ?? const [];
    return concepts.take(5).toList(growable: false);
  }

  int? get estimatedFirstMissionMinutes =>
      preview?.estimatedFirstMissionMinutes;

  FirstMissionInfo? get firstMission => outcome?.firstMission;

  /// Source deletion is deliberately separate from retained knowledge (D9).
  SourceDeletionStatus get deletionStatus {
    final committed = outcome;
    if (committed != null) return committed.sourceDeletionStatus;

    final snapshot = update;
    if (snapshot == null) return SourceDeletionStatus.notRequired;
    if (snapshot.sourceDeletionStatus != SourceDeletionStatus.notRequired) {
      return snapshot.sourceDeletionStatus;
    }
    for (final upload in snapshot.uploads) {
      if (upload.deletionStatus != SourceDeletionStatus.notRequired) {
        return upload.deletionStatus;
      }
    }
    return SourceDeletionStatus.notRequired;
  }

  /// A short, human-readable source name for the summary.
  String? get sourceName {
    final snapshot = update;
    if (snapshot == null) return null;
    final uploads = snapshot.uploads;
    if (uploads.isEmpty) {
      return snapshot.hasManualText ? 'Typed notes' : null;
    }
    final first = uploads.first.declaredName;
    return uploads.length == 1 ? first : '$first + ${uploads.length - 1} more';
  }

  /// Why commit is unavailable, in approved student-facing copy.
  String? get blockedReasonCopy {
    final value = preview;
    if (value == null || value.canCommit) return null;
    // A committed path is already added; no blocked explanation applies.
    if (stage == PathPreviewStage.committed) return null;
    return switch (value.blockedReason) {
      PreviewBlockReason.verificationPending =>
        'Some concepts still need a check. Go back to verify them before '
            'adding this path.',
      PreviewBlockReason.noValidConcept =>
        'No concepts are ready to add. Edit the concepts to keep at least one.',
      PreviewBlockReason.invalidState =>
        'This material is not ready to add right now.',
      PreviewBlockReason.unknown =>
        'This learning path cannot be added right now. Refresh to check again.',
      null => 'Refresh to check whether this learning path can be added.',
    };
  }

  bool get canCommit =>
      stage == PathPreviewStage.ready &&
      !isCommitting &&
      !isOffline &&
      (preview?.canCommit ?? false);

  String? get commitDisabledReason {
    if (stage != PathPreviewStage.ready) return null;
    if (isOffline) return 'Reconnect to add this learning path.';
    final value = preview;
    if (value == null) return null;
    if (!value.canCommit) return blockedReasonCopy;
    return null;
  }

  PathPreviewState copyWith({
    PathPreviewStage? stage,
    UpdateSnapshot? update,
    PathPreview? preview,
    CommitOutcome? outcome,
    String? subjectName,
    IngestionFailure? failure,
    bool clearFailure = false,
    bool? isOffline,
    bool? isRefreshing,
    bool? isCommitting,
    String? notice,
    bool clearNotice = false,
  }) {
    return PathPreviewState(
      stage: stage ?? this.stage,
      update: update ?? this.update,
      preview: preview ?? this.preview,
      outcome: outcome ?? this.outcome,
      subjectName: subjectName ?? this.subjectName,
      failure: clearFailure ? null : (failure ?? this.failure),
      isOffline: isOffline ?? this.isOffline,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isCommitting: isCommitting ?? this.isCommitting,
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }
}

/// Loads the authoritative preview and performs one replay-safe commit
/// (UI/UX §9.11, Flow §9.5, D11).
class PathPreviewController extends StateNotifier<PathPreviewState> {
  PathPreviewController({
    required this.repository,
    required this.draftStore,
    required this.sessionController,
    required this.updateId,
  }) : super(const PathPreviewState());

  final IngestionRepository repository;
  final IngestionDraftStore draftStore;
  final SessionController sessionController;
  final String updateId;

  bool _initialized = false;
  int _requestId = 0;

  /// Public read-only view for presentation code and widget tests.
  PathPreviewState get currentState => state;

  String? get _accountId => sessionController.state.session?.userId;
  String? get _accessToken => sessionController.state.session?.accessToken;

  String get _commitOperation => 'commit:$updateId';

  /// Reads the update and preview on entry.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _load(initial: true);
  }

  /// Re-reads the update and preview, keeping any completed commit outcome.
  Future<void> refresh() async {
    if (state.isRefreshing || state.isCommitting) return;
    await _load();
  }

  /// Commits the previewed path with one durable operation key.
  ///
  /// A double tap is absorbed by [PathPreviewState.isCommitting]. The key is
  /// reused after a transient failure and cleared after success or a terminal
  /// conflict, so a replay can never create a second commit.
  Future<bool> commit() async {
    if (!state.canCommit || state.isCommitting) return false;

    final accountId = _accountId;
    final token = _accessToken;
    if (accountId == null || token == null) {
      await _expireSession();
      return false;
    }

    state = state.copyWith(
      isCommitting: true,
      clearFailure: true,
      clearNotice: true,
      isOffline: false,
    );

    try {
      final key = await draftStore.operationKey(
        accountId: accountId,
        operation: _commitOperation,
      );
      final outcome = await repository.commitUpdate(
        accessToken: token,
        updateId: updateId,
        idempotencyKey: key,
      );
      await draftStore.clearOperationKey(
        accountId: accountId,
        operation: _commitOperation,
      );
      await draftStore.clearDraft(accountId);
      if (!mounted) return false;

      state = state.copyWith(
        stage: PathPreviewStage.committed,
        outcome: outcome,
        isCommitting: false,
        clearFailure: true,
        isOffline: false,
      );
      return true;
    } on IngestionFailure catch (failure) {
      if (!mounted) return false;

      if (failure.code == 'invalid_state' ||
          failure.code == 'version_conflict' ||
          failure.code == 'idempotency_key_reused') {
        await draftStore.clearOperationKey(
          accountId: accountId,
          operation: _commitOperation,
        );
        await _load();
        if (!mounted) return false;
        if (state.stage == PathPreviewStage.invalidState ||
            state.stage == PathPreviewStage.notFound ||
            state.stage == PathPreviewStage.failed) {
          return false;
        }

        state = state.copyWith(
          isCommitting: false,
          notice: state.isCommitted
              ? 'This material is already in your learning path.'
              : 'This material changed while you were previewing it. The '
                    'latest preview is shown.',
        );
        return false;
      }

      state = state.copyWith(
        isCommitting: false,
        failure: failure,
        isOffline: failure.code == 'network_error',
      );
      if (failure.code == 'expired_session') await _expireSession();
      return false;
    }
  }

  Future<void> _load({bool initial = false}) async {
    final token = _accessToken;
    if (token == null) {
      await _expireSession();
      return;
    }

    final requestId = ++_requestId;
    if (!initial) {
      state = state.copyWith(
        isRefreshing: true,
        clearFailure: true,
        clearNotice: true,
      );
    }

    try {
      final update = await repository.getUpdate(
        accessToken: token,
        updateId: updateId,
      );
      if (!mounted || requestId != _requestId) return;

      if (update.state != LearningUpdateState.verificationRequired &&
          update.state != LearningUpdateState.committed) {
        state = state.copyWith(
          stage: PathPreviewStage.invalidState,
          update: update,
          isRefreshing: false,
          isCommitting: false,
          clearFailure: true,
        );
        return;
      }

      final preview = await repository.previewPath(
        accessToken: token,
        updateId: updateId,
      );
      if (!mounted || requestId != _requestId) return;

      final subjectName = _subjectNameFor(update.subjectId);
      if (update.state == LearningUpdateState.committed ||
          preview.state == LearningUpdateState.committed) {
        state = state.copyWith(
          stage: PathPreviewStage.committed,
          update: update,
          preview: preview,
          subjectName: subjectName,
          isRefreshing: false,
          isCommitting: false,
          clearFailure: true,
          clearNotice: true,
        );
        return;
      }

      state = PathPreviewState(
        stage: PathPreviewStage.ready,
        update: update,
        preview: preview,
        subjectName: subjectName,
      );
    } on IngestionFailure catch (failure) {
      if (!mounted || requestId != _requestId) return;
      await _handleLoadFailure(failure);
    }
  }

  Future<void> _handleLoadFailure(IngestionFailure failure) async {
    if (failure.code == 'resource_not_found') {
      state = state.copyWith(
        stage: PathPreviewStage.notFound,
        isRefreshing: false,
        isCommitting: false,
      );
      return;
    }

    if (failure.code == 'invalid_state') {
      state = state.copyWith(
        stage: PathPreviewStage.invalidState,
        isRefreshing: false,
        isCommitting: false,
        clearFailure: true,
      );
      return;
    }

    final hasPreview = state.preview != null;
    state = state.copyWith(
      stage: hasPreview
          ? (state.isCommitted
                ? PathPreviewStage.committed
                : PathPreviewStage.ready)
          : PathPreviewStage.failed,
      failure: failure,
      isOffline: failure.code == 'network_error',
      isRefreshing: false,
      isCommitting: false,
    );

    if (failure.code == 'expired_session') await _expireSession();
  }

  String? _subjectNameFor(String subjectId) {
    final subjects = sessionController.state.bootstrapData?.subjects;
    if (subjects == null) return null;
    for (final subject in subjects) {
      if (subject.id == subjectId) return subject.name;
    }
    return null;
  }

  Future<void> _expireSession() async {
    await sessionController.handleExpiredSession();
  }
}

/// Verification controller keyed by the route's update id.
final verificationControllerProvider = StateNotifierProvider.autoDispose
    .family<VerificationController, VerificationState, String>((ref, updateId) {
      final controller = VerificationController(
        repository: ref.watch(ingestionRepositoryProvider),
        draftStore: ref.watch(ingestionDraftStoreProvider),
        sessionController: ref.watch(sessionControllerProvider.notifier),
        updateId: updateId,
      );
      unawaited(controller.initialize());
      return controller;
    });

/// Learning-path preview controller keyed by the route's update id.
final pathPreviewControllerProvider = StateNotifierProvider.autoDispose
    .family<PathPreviewController, PathPreviewState, String>((ref, updateId) {
      final controller = PathPreviewController(
        repository: ref.watch(ingestionRepositoryProvider),
        draftStore: ref.watch(ingestionDraftStoreProvider),
        sessionController: ref.watch(sessionControllerProvider.notifier),
        updateId: updateId,
      );
      unawaited(controller.initialize());
      return controller;
    });
