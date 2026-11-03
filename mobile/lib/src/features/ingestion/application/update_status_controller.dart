import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/session_controller.dart';
import '../data/ingestion_draft_store.dart';
import '../data/ingestion_repository.dart';
import '../domain/ingestion_failure.dart';
import '../domain/ingestion_models.dart';
import 'ingestion_flow_controller.dart';

/// Which layer of the material-status screen owns the current presentation.
enum UpdateStatusStage {
  /// The first authoritative read is still running.
  loading,

  /// A snapshot (or a safe failure state) is available.
  ready,

  /// The first read failed before any snapshot could be shown.
  failed,

  /// The update does not exist for this account (indistinguishable 404).
  notFound,
}

/// Immutable state of one learning update's status screen.
@immutable
class UpdateStatusState {
  final UpdateStatusStage stage;
  final UpdateSnapshot? snapshot;

  /// Transport or refresh failure. A durable update failure lives on
  /// [UpdateSnapshot.failure] and is never merged into this field.
  final IngestionFailure? failure;
  final bool isOffline;
  final bool isRefreshing;
  final bool isRetrying;

  /// True after the UIX-019 threshold without a terminal result.
  final bool isSlow;

  /// True after the longer threshold; the student is advised to leave and
  /// return because processing continues server-side (D7).
  final bool shouldLeaveAndReturn;

  const UpdateStatusState({
    this.stage = UpdateStatusStage.loading,
    this.snapshot,
    this.failure,
    this.isOffline = false,
    this.isRefreshing = false,
    this.isRetrying = false,
    this.isSlow = false,
    this.shouldLeaveAndReturn = false,
  });

  LearningUpdateState? get updateState => snapshot?.state;

  bool get isLoading => stage == UpdateStatusStage.loading;

  bool get isNotFound => stage == UpdateStatusStage.notFound;

  bool get isInFlight => snapshot?.state.isInFlight ?? false;

  /// A failed extraction can be retried only when the contract marks the safe
  /// failure code retryable. Terminal and source-specific failures cannot.
  bool get canRetryExtraction =>
      snapshot?.state == LearningUpdateState.failed &&
      (snapshot?.failure?.retryable ?? false);

  /// Deletion cleanup is independent of the update's knowledge state.
  bool get canRetryDeletion => snapshot?.deletionRetryAvailable ?? false;

  UpdateStatusState copyWith({
    UpdateStatusStage? stage,
    UpdateSnapshot? snapshot,
    IngestionFailure? failure,
    bool clearFailure = false,
    bool? isOffline,
    bool? isRefreshing,
    bool? isRetrying,
    bool? isSlow,
    bool? shouldLeaveAndReturn,
  }) {
    return UpdateStatusState(
      stage: stage ?? this.stage,
      snapshot: snapshot ?? this.snapshot,
      failure: clearFailure ? null : (failure ?? this.failure),
      isOffline: isOffline ?? this.isOffline,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isRetrying: isRetrying ?? this.isRetrying,
      isSlow: isSlow ?? this.isSlow,
      shouldLeaveAndReturn: shouldLeaveAndReturn ?? this.shouldLeaveAndReturn,
    );
  }
}

/// Polls one learning update, retries eligible stages and keeps deletion status
/// separate from retained knowledge (Flow §9.2, D7/D9).
class UpdateStatusController extends StateNotifier<UpdateStatusState> {
  UpdateStatusController({
    required this.repository,
    required this.draftStore,
    required this.sessionController,
    required this.updateId,
    this.pollInterval = const Duration(seconds: 2),
    this.maxPollInterval = const Duration(seconds: 10),
    this.slowAfter = const Duration(seconds: 10),
    this.leaveAfter = const Duration(minutes: 10),
  }) : _pollDelay = pollInterval,
       super(const UpdateStatusState());

  final IngestionRepository repository;
  final IngestionDraftStore draftStore;
  final SessionController sessionController;
  final String updateId;

  /// First poll delay; doubles until [maxPollInterval] (D7).
  final Duration pollInterval;
  final Duration maxPollInterval;
  final Duration slowAfter;
  final Duration leaveAfter;

  Timer? _pollTimer;
  Timer? _slowTimer;
  Timer? _leaveTimer;
  Duration _pollDelay;
  bool _initialized = false;
  int _requestId = 0;

  /// Public read-only view for presentation code and widget tests.
  UpdateStatusState get currentState => state;

  String? get _accountId => sessionController.state.session?.userId;
  String? get _accessToken => sessionController.state.session?.accessToken;

  /// Performs the authoritative read on entry. Safe to call twice; only the
  /// first call starts a request and the polling timers.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _startSlowTimers();
    await _load(initial: true);
  }

  /// Re-reads the authoritative snapshot and restarts the backoff sequence.
  Future<void> refresh() async {
    if (state.isRefreshing || state.isRetrying) return;
    _pollTimer?.cancel();
    _pollDelay = pollInterval;
    await _load();
  }

  /// Retries extraction for a failed update. The update identity is retained;
  /// no new update or upload is created (Flow §9.3).
  Future<void> retryExtraction() async {
    final snapshot = state.snapshot;
    if (snapshot == null || !state.canRetryExtraction || state.isRetrying) {
      return;
    }
    await _retryStage(
      IngestionRetryStage.extraction,
      operation: 'retry_extraction:${snapshot.id}',
      restartTimers: true,
    );
  }

  /// Retries temporary-source deletion. Retained knowledge is unaffected (D9).
  Future<void> retryDeletion() async {
    final snapshot = state.snapshot;
    if (snapshot == null || !state.canRetryDeletion || state.isRetrying) {
      return;
    }
    await _retryStage(
      IngestionRetryStage.deletion,
      operation: 'retry_deletion:${snapshot.id}',
      restartTimers: false,
    );
  }

  Future<void> _load({bool initial = false}) async {
    final token = _accessToken;
    if (token == null) {
      await _expireSession();
      return;
    }

    final requestId = ++_requestId;
    if (!initial) {
      state = state.copyWith(isRefreshing: true, clearFailure: true);
    }

    try {
      final snapshot = await repository.getUpdate(
        accessToken: token,
        updateId: updateId,
      );
      if (!mounted || requestId != _requestId) return;
      _applySnapshot(snapshot, isRefreshing: false);
    } on IngestionFailure catch (failure) {
      if (!mounted || requestId != _requestId) return;
      await _handleFailure(failure, isRefreshing: false);
    }
  }

  Future<void> _poll() async {
    if (!mounted) return;
    final snapshot = state.snapshot;
    if (snapshot == null || !snapshot.state.isInFlight) return;

    final token = _accessToken;
    if (token == null) {
      await _expireSession();
      return;
    }

    final requestId = ++_requestId;
    try {
      final next = await repository.getUpdate(
        accessToken: token,
        updateId: updateId,
      );
      if (!mounted || requestId != _requestId) return;
      _applySnapshot(next);
    } on IngestionFailure catch (failure) {
      if (!mounted || requestId != _requestId) return;
      await _handleFailure(failure);
    }
  }

  void _applySnapshot(UpdateSnapshot snapshot, {bool isRefreshing = false}) {
    _pollTimer?.cancel();
    state = state.copyWith(
      stage: UpdateStatusStage.ready,
      snapshot: snapshot,
      clearFailure: true,
      isOffline: false,
      isRefreshing: isRefreshing,
      isRetrying: false,
    );

    if (snapshot.state.isInFlight) {
      _schedulePoll();
      return;
    }

    // Terminal and review states never keep a background poll or a stale
    // "still working" message.
    _slowTimer?.cancel();
    _leaveTimer?.cancel();
    state = state.copyWith(isSlow: false, shouldLeaveAndReturn: false);
  }

  Future<void> _handleFailure(
    IngestionFailure failure, {
    bool isRefreshing = false,
  }) async {
    _pollTimer?.cancel();

    if (failure.code == 'resource_not_found') {
      _slowTimer?.cancel();
      _leaveTimer?.cancel();
      state = const UpdateStatusState(stage: UpdateStatusStage.notFound);
      return;
    }

    final hasSnapshot = state.snapshot != null;
    if (!hasSnapshot) {
      _slowTimer?.cancel();
      _leaveTimer?.cancel();
    }
    state = state.copyWith(
      stage: hasSnapshot ? UpdateStatusStage.ready : UpdateStatusStage.failed,
      failure: failure,
      isOffline: failure.code == 'network_error',
      isRefreshing: isRefreshing,
      isRetrying: false,
    );

    if (failure.code == 'expired_session') {
      await _expireSession();
    }
  }

  Future<void> _retryStage(
    IngestionRetryStage stage, {
    required String operation,
    required bool restartTimers,
  }) async {
    final accountId = _accountId;
    final token = _accessToken;
    if (accountId == null || token == null) {
      await _expireSession();
      return;
    }

    state = state.copyWith(
      isRetrying: true,
      clearFailure: true,
      isOffline: false,
    );

    try {
      final key = await draftStore.operationKey(
        accountId: accountId,
        operation: operation,
      );
      final updated = await repository.retryUpdate(
        accessToken: token,
        updateId: updateId,
        stage: stage,
        idempotencyKey: key,
      );
      await draftStore.clearOperationKey(
        accountId: accountId,
        operation: operation,
      );
      if (!mounted) return;

      _pollDelay = pollInterval;
      if (restartTimers) _restartSlowTimers();
      _applySnapshot(updated);
    } on IngestionFailure catch (failure) {
      if (!mounted) return;

      // A stale or already-advanced update is explained from fresh state
      // rather than leaving the screen on an outdated card (D9).
      if (failure.code == 'invalid_state' ||
          failure.code == 'version_conflict') {
        await _load();
        if (!mounted || state.isNotFound) return;
      }

      state = state.copyWith(
        isRetrying: false,
        failure: failure,
        isOffline: failure.code == 'network_error',
      );
      if (failure.code == 'expired_session') await _expireSession();
    }
  }

  void _schedulePoll() {
    if (!mounted) return;
    _pollTimer?.cancel();

    final delay = _pollDelay;
    final nextMilliseconds = math.min(
      delay.inMilliseconds * 2,
      maxPollInterval.inMilliseconds,
    );
    _pollDelay = Duration(milliseconds: nextMilliseconds);
    _pollTimer = Timer(delay, _poll);
  }

  void _startSlowTimers() {
    _slowTimer?.cancel();
    _leaveTimer?.cancel();
    _slowTimer = Timer(slowAfter, () {
      if (!mounted) return;
      state = state.copyWith(isSlow: true);
    });
    _leaveTimer = Timer(leaveAfter, () {
      if (!mounted) return;
      state = state.copyWith(shouldLeaveAndReturn: true);
    });
  }

  void _restartSlowTimers() {
    state = state.copyWith(isSlow: false, shouldLeaveAndReturn: false);
    _startSlowTimers();
  }

  Future<void> _expireSession() async {
    await sessionController.handleExpiredSession();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _slowTimer?.cancel();
    _leaveTimer?.cancel();
    super.dispose();
  }
}

/// Status controller keyed by the route's update id.
final updateStatusControllerProvider = StateNotifierProvider.autoDispose
    .family<UpdateStatusController, UpdateStatusState, String>((ref, updateId) {
      final controller = UpdateStatusController(
        repository: ref.watch(ingestionRepositoryProvider),
        draftStore: ref.watch(ingestionDraftStoreProvider),
        sessionController: ref.watch(sessionControllerProvider.notifier),
        updateId: updateId,
      );
      unawaited(controller.initialize());
      return controller;
    });
