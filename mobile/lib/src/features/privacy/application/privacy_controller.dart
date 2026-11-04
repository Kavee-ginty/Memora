import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_session_state.dart';
import '../../auth/domain/bootstrap_state.dart';
import '../../common/ids.dart';
import '../data/privacy_download_launcher.dart';
import '../data/privacy_reachability.dart';
import '../data/privacy_repository.dart';
import '../domain/privacy_models.dart';

/// Which privacy workflow owns the current pending intent.
enum PrivacyWorkflow { export, deletion, cancellation }

/// Immutable state for the T21 privacy workflow.
@immutable
class PrivacyState {
  final bool isLoading;
  final bool isRefreshing;
  final bool isSubmitting;
  final bool isCheckingReachability;
  final bool isReachable;
  final bool reachabilityKnown;
  final DateTime? lastCheckedAt;

  final PrivacyExport? export;
  final PrivacyDeletion? deletion;
  final AuthFailure? failure;
  final String? notice;

  final bool isPolling;
  final bool downloadInProgress;
  final bool proofMissing;
  final bool outcomeUnconfirmed;
  final String? outcomeUnconfirmedRequestId;

  final bool awaitingReauthentication;
  final PrivacyPendingAction? pendingAction;
  final bool reauthenticationRetryUsed;

  const PrivacyState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.isSubmitting = false,
    this.isCheckingReachability = false,
    this.isReachable = false,
    this.reachabilityKnown = false,
    this.lastCheckedAt,
    this.export,
    this.deletion,
    this.failure,
    this.notice,
    this.isPolling = false,
    this.downloadInProgress = false,
    this.proofMissing = false,
    this.outcomeUnconfirmed = false,
    this.outcomeUnconfirmedRequestId,
    this.awaitingReauthentication = false,
    this.pendingAction,
    this.reauthenticationRetryUsed = false,
  });

  bool get canMutate =>
      reachabilityKnown &&
      isReachable &&
      !isSubmitting &&
      !isLoading &&
      !isRefreshing;

  bool get isOffline => reachabilityKnown && !isReachable;

  bool get hasPendingExport => export?.status.isPending ?? false;

  bool get hasPendingDeletion => deletion?.status.isPending ?? false;

  bool get isDeletionConfirmed => deletion?.isConfirmedComplete ?? false;

  static const Object _unset = Object();

  PrivacyState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? isSubmitting,
    bool? isCheckingReachability,
    bool? isReachable,
    bool? reachabilityKnown,
    Object? lastCheckedAt = _unset,
    Object? export = _unset,
    Object? deletion = _unset,
    Object? failure = _unset,
    Object? notice = _unset,
    bool? isPolling,
    bool? downloadInProgress,
    bool? proofMissing,
    bool? outcomeUnconfirmed,
    Object? outcomeUnconfirmedRequestId = _unset,
    bool? awaitingReauthentication,
    Object? pendingAction = _unset,
    bool? reauthenticationRetryUsed,
  }) {
    return PrivacyState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCheckingReachability:
          isCheckingReachability ?? this.isCheckingReachability,
      isReachable: isReachable ?? this.isReachable,
      reachabilityKnown: reachabilityKnown ?? this.reachabilityKnown,
      lastCheckedAt: identical(lastCheckedAt, _unset)
          ? this.lastCheckedAt
          : lastCheckedAt as DateTime?,
      export: identical(export, _unset)
          ? this.export
          : export as PrivacyExport?,
      deletion: identical(deletion, _unset)
          ? this.deletion
          : deletion as PrivacyDeletion?,
      failure: identical(failure, _unset)
          ? this.failure
          : failure as AuthFailure?,
      notice: identical(notice, _unset) ? this.notice : notice as String?,
      isPolling: isPolling ?? this.isPolling,
      downloadInProgress: downloadInProgress ?? this.downloadInProgress,
      proofMissing: proofMissing ?? this.proofMissing,
      outcomeUnconfirmed: outcomeUnconfirmed ?? this.outcomeUnconfirmed,
      outcomeUnconfirmedRequestId:
          identical(outcomeUnconfirmedRequestId, _unset)
          ? this.outcomeUnconfirmedRequestId
          : outcomeUnconfirmedRequestId as String?,
      awaitingReauthentication:
          awaitingReauthentication ?? this.awaitingReauthentication,
      pendingAction: identical(pendingAction, _unset)
          ? this.pendingAction
          : pendingAction as PrivacyPendingAction?,
      reauthenticationRetryUsed:
          reauthenticationRetryUsed ?? this.reauthenticationRetryUsed,
    );
  }
}

/// Coordinates export, deletion, cancellation, download and recovery state.
class PrivacyController extends StateNotifier<PrivacyState> {
  PrivacyController({
    required this.repository,
    required this.reachability,
    required this.sessionController,
    required this.downloadLauncher,
    this.pollInterval = const Duration(seconds: 5),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const PrivacyState());

  final PrivacyRepository repository;
  final PrivacyReachability reachability;
  final SessionController sessionController;
  final PrivacyDownloadLauncher downloadLauncher;
  final Duration pollInterval;
  final DateTime Function() _clock;

  Timer? _pollTimer;
  bool _pollInFlight = false;

  String? _exportKey;
  String? _deletionKey;
  String? _cancelKey;

  String? get _accessToken => sessionController.state.session?.accessToken;

  DateTime _now() => _clock().toUtc();

  /// Whether the current export has a signed URL that has not expired.
  bool get canDownloadExport =>
      state.export?.hasActiveDownload(_now()) ?? false;

  /// Checks backend reachability before enabling privacy mutations.
  Future<bool> checkReachability() async {
    if (state.isCheckingReachability) {
      return state.isReachable;
    }

    state = state.copyWith(isCheckingReachability: true);
    bool reachable;
    try {
      reachable = await reachability.check();
    } catch (_) {
      reachable = false;
    }
    if (!mounted) return reachable;

    state = state.copyWith(
      isCheckingReachability: false,
      isReachable: reachable,
      reachabilityKnown: true,
      lastCheckedAt: _now(),
    );
    if (!reachable) {
      _stopPolling();
    }
    return reachable;
  }

  Future<bool> _ensureReachable() async {
    if (!state.reachabilityKnown) {
      return checkReachability();
    }
    return state.isReachable;
  }

  void _markReachable() {
    state = state.copyWith(
      isReachable: true,
      reachabilityKnown: true,
      lastCheckedAt: _now(),
    );
  }

  void _markOffline() {
    state = state.copyWith(
      isReachable: false,
      reachabilityKnown: true,
      lastCheckedAt: _now(),
    );
    _stopPolling();
  }

  void _setOfflineFailure() {
    state = state.copyWith(
      failure: AuthFailure.networkError(
        'Memora cannot reach the server. Reconnect and try again.',
      ),
    );
  }

  /// Loads the overview and refreshes the reachability indicator.
  Future<void> initializeOverview() async {
    await checkReachability();
  }

  /// Creates one export request, reusing the unresolved intent key.
  Future<PrivacyExport?> requestExport() async {
    if (state.export?.status.isPending == true) {
      state = state.copyWith(
        notice: 'Your export is already in progress.',
        failure: null,
      );
      return state.export;
    }

    if (_unresolvedBootstrapPending() != null) {
      state = state.copyWith(
        notice:
            'A privacy request is already in progress. Check its status before '
            'starting another.',
        failure: null,
      );
      return null;
    }

    if (!await _ensureReachable()) {
      _setOfflineFailure();
      return null;
    }

    final token = _accessToken;
    if (token == null) {
      await _expireSession(AuthFailure.expiredSession());
      return null;
    }

    _exportKey = _keyForNewExportIntent();
    state = state.copyWith(
      isSubmitting: true,
      failure: null,
      notice: null,
      proofMissing: false,
      outcomeUnconfirmed: false,
      outcomeUnconfirmedRequestId: null,
    );

    try {
      final export = await repository.createExport(
        accessToken: token,
        idempotencyKey: _exportKey!,
      );
      if (!mounted) return null;
      _markReachable();
      _applyExport(export);
      return export;
    } on AuthFailure catch (failure) {
      if (!mounted) return null;
      await _handleFailure(failure, PrivacyWorkflow.export);
      return null;
    } finally {
      if (mounted) {
        state = state.copyWith(isSubmitting: false);
      }
    }
  }

  /// Reads export status and starts polling while the request is pending.
  Future<void> loadExport(String requestId, {bool startPolling = true}) async {
    if (!await _ensureReachable()) {
      _setOfflineFailure();
      return;
    }

    final token = _accessToken;
    if (token == null) {
      await _expireSession(AuthFailure.expiredSession());
      return;
    }

    final firstLoad = state.export?.id != requestId;
    state = state.copyWith(
      isLoading: firstLoad,
      isRefreshing: !firstLoad,
      failure: null,
      notice: null,
      proofMissing: false,
      outcomeUnconfirmed: false,
      outcomeUnconfirmedRequestId: null,
    );

    try {
      final export = await repository.getExport(
        accessToken: token,
        requestId: requestId,
      );
      if (!mounted) return;
      _markReachable();
      _applyExport(export, startPolling: startPolling);
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      await _handleFailure(failure, PrivacyWorkflow.export);
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false, isRefreshing: false);
      }
    }
  }

  /// Refreshes export status without replacing the visible state with a skeleton.
  Future<void> refreshExport(String requestId) async {
    if (_pollInFlight) return;
    _pollInFlight = true;
    try {
      await loadExport(requestId);
    } finally {
      _pollInFlight = false;
    }
  }

  /// Creates one deletion request after explicit confirmation.
  Future<PrivacyDeletion?> requestDeletion({required bool confirmed}) async {
    if (!confirmed) {
      state = state.copyWith(
        failure: const AuthFailure(
          code: 'confirmation_required',
          message: 'Confirm that you understand this action.',
        ),
      );
      return null;
    }

    if (state.deletion?.status.isPending == true) {
      state = state.copyWith(
        notice: 'Your deletion request is already in progress.',
        failure: null,
      );
      return state.deletion;
    }

    if (_unresolvedBootstrapPending() != null) {
      state = state.copyWith(
        notice:
            'A privacy request is already in progress. Check its status before '
            'starting another.',
        failure: null,
      );
      return null;
    }

    if (!await _ensureReachable()) {
      _setOfflineFailure();
      return null;
    }

    final token = _accessToken;
    if (token == null) {
      await _expireSession(AuthFailure.expiredSession());
      return null;
    }

    _deletionKey = _keyForNewDeletionIntent();
    state = state.copyWith(
      isSubmitting: true,
      failure: null,
      notice: null,
      proofMissing: false,
      outcomeUnconfirmed: false,
      outcomeUnconfirmedRequestId: null,
    );

    try {
      final deletion = await repository.createDeletion(
        accessToken: token,
        idempotencyKey: _deletionKey!,
        confirmed: true,
      );
      if (!mounted) return null;
      _markReachable();
      _applyDeletion(deletion);
      return deletion;
    } on AuthFailure catch (failure) {
      if (!mounted) return null;
      await _handleFailure(failure, PrivacyWorkflow.deletion);
      return null;
    } finally {
      if (mounted) {
        state = state.copyWith(isSubmitting: false);
      }
    }
  }

  /// Reads deletion status and starts polling while the request is pending.
  Future<void> loadDeletion(
    String requestId, {
    bool startPolling = true,
  }) async {
    if (!await _ensureReachable()) {
      _setOfflineFailure();
      return;
    }

    final token = _accessToken;
    if (token == null) {
      _markDeletionOutcomeUnconfirmed(requestId);
      return;
    }

    final firstLoad = state.deletion?.id != requestId;
    state = state.copyWith(
      isLoading: firstLoad,
      isRefreshing: !firstLoad,
      failure: null,
      notice: null,
      proofMissing: false,
      outcomeUnconfirmed: false,
      outcomeUnconfirmedRequestId: null,
    );

    try {
      final deletion = await repository.getDeletion(
        accessToken: token,
        requestId: requestId,
      );
      if (!mounted) return;
      _markReachable();
      _applyDeletion(deletion, startPolling: startPolling);
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      if (failure.code == 'expired_session') {
        // The access token may expire while deletion is processing. Completion
        // can no longer be verified, so the client must not infer or claim it.
        _markDeletionOutcomeUnconfirmed(requestId);
      } else {
        await _handleFailure(failure, PrivacyWorkflow.deletion);
      }
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false, isRefreshing: false);
      }
    }
  }

  /// Refreshes deletion status without replacing the visible state.
  Future<void> refreshDeletion(String requestId) async {
    if (_pollInFlight) return;
    _pollInFlight = true;
    try {
      await loadDeletion(requestId);
    } finally {
      _pollInFlight = false;
    }
  }

  /// Cancels a deletion only when the current status still permits it.
  Future<PrivacyDeletion?> cancelDeletion() async {
    final deletion = state.deletion;
    if (deletion == null || !deletion.canCancel) {
      _stopPolling();
      state = state.copyWith(
        failure: const AuthFailure(
          code: 'deletion_cancellation_disallowed',
          message: 'This deletion can no longer be cancelled.',
        ),
      );
      return null;
    }

    if (!await _ensureReachable()) {
      _setOfflineFailure();
      return null;
    }

    final token = _accessToken;
    if (token == null) {
      _markDeletionOutcomeUnconfirmed(deletion.id);
      return null;
    }

    _cancelKey ??= generateUuid();
    state = state.copyWith(isSubmitting: true, failure: null, notice: null);

    try {
      final cancelled = await repository.cancelDeletion(
        accessToken: token,
        requestId: deletion.id,
        idempotencyKey: _cancelKey!,
        reason: 'user_requested',
      );
      if (!mounted) return null;
      _markReachable();
      _cancelKey = null;
      _applyDeletion(cancelled, startPolling: false);
      return cancelled;
    } on AuthFailure catch (failure) {
      if (!mounted) return null;
      if (failure.code == 'deletion_cancellation_disallowed') {
        _cancelKey = null;
        await loadDeletion(deletion.id);
        _stopPolling();
        if (mounted) {
          state = state.copyWith(failure: failure);
        }
      } else if (failure.code == 'expired_session') {
        _markDeletionOutcomeUnconfirmed(deletion.id);
      } else {
        await _handleFailure(failure, PrivacyWorkflow.cancellation);
      }
      return null;
    } finally {
      if (mounted) {
        state = state.copyWith(isSubmitting: false);
      }
    }
  }

  /// Opens the signed export URL externally without logging or persisting it.
  Future<void> downloadExport() async {
    final export = state.export;
    if (export == null || !export.hasActiveDownload(_now())) {
      state = state.copyWith(
        failure: const AuthFailure(
          code: 'download_expired',
          message: 'That download has expired. Request a new export.',
        ),
      );
      return;
    }

    if (!await _ensureReachable()) {
      _setOfflineFailure();
      return;
    }

    final uri = export.downloadUri!;
    state = state.copyWith(
      downloadInProgress: true,
      failure: null,
      notice: null,
    );

    try {
      await downloadLauncher.openExternal(uri);
      if (!mounted) return;
      state = state.copyWith(
        downloadInProgress: false,
        notice: 'Download opened in your browser.',
      );
    } on PrivacyDownloadUnavailable {
      if (!mounted) return;
      state = state.copyWith(
        downloadInProgress: false,
        failure: const AuthFailure(
          code: 'download_unavailable',
          message: 'Could not open the download. Please try again.',
          retryable: true,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        downloadInProgress: false,
        failure: const AuthFailure(
          code: 'download_unavailable',
          message: 'Could not open the download. Please try again.',
          retryable: true,
        ),
      );
    }
  }

  /// Retries the mutation that triggered recent-authentication recovery.
  ///
  /// The first retry keeps the original idempotency key. A second recent-auth
  /// rejection stops the workflow and asks the student to sign in again.
  Future<void> retryPendingAction() async {
    final action = state.pendingAction;
    if (action == null) return;

    state = state.copyWith(
      awaitingReauthentication: false,
      reauthenticationRetryUsed: true,
      failure: null,
    );

    switch (action) {
      case PrivacyPendingAction.export:
        await requestExport();
      case PrivacyPendingAction.deletion:
        await requestDeletion(confirmed: true);
      case PrivacyPendingAction.cancellation:
        await cancelDeletion();
    }
  }

  /// Leaves recent-authentication recovery without retrying.
  void cancelReauthentication() {
    state = state.copyWith(
      awaitingReauthentication: false,
      pendingAction: null,
      failure: null,
    );
  }

  /// Probes both request types for a bootstrap pending identifier.
  ///
  /// T20 bootstrap summaries intentionally omit the request type, so the client
  /// resolves it by reading the export first and the deletion second.
  Future<PrivacyWorkflow?> recoverPendingRequest(String requestId) async {
    if (!await _ensureReachable()) {
      _setOfflineFailure();
      return null;
    }

    final token = _accessToken;
    if (token == null) {
      await _expireSession(AuthFailure.expiredSession());
      return null;
    }

    state = state.copyWith(
      isLoading: true,
      failure: null,
      notice: null,
      outcomeUnconfirmed: false,
      outcomeUnconfirmedRequestId: null,
    );

    try {
      final export = await repository.getExport(
        accessToken: token,
        requestId: requestId,
      );
      if (!mounted) return null;
      _markReachable();
      _applyExport(export);
      return PrivacyWorkflow.export;
    } on AuthFailure catch (failure) {
      if (!mounted) return null;
      if (failure.code == 'not_found' || failure.code == 'resource_not_found') {
        return _recoverDeletionRequest(token, requestId);
      }
      await _handleFailure(failure, PrivacyWorkflow.export);
      return null;
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<PrivacyWorkflow?> _recoverDeletionRequest(
    String token,
    String requestId,
  ) async {
    try {
      final deletion = await repository.getDeletion(
        accessToken: token,
        requestId: requestId,
      );
      if (!mounted) return null;
      _markReachable();
      _applyDeletion(deletion);
      return PrivacyWorkflow.deletion;
    } on AuthFailure catch (failure) {
      if (!mounted) return null;
      if (failure.code == 'expired_session') {
        _markDeletionOutcomeUnconfirmed(requestId);
      } else {
        await _handleFailure(failure, PrivacyWorkflow.deletion);
      }
      return null;
    }
  }

  void clearFailure() {
    state = state.copyWith(failure: null);
  }

  void clearNotice() {
    state = state.copyWith(notice: null);
  }

  void _applyExport(PrivacyExport export, {bool startPolling = true}) {
    state = state.copyWith(
      export: export,
      failure: null,
      notice: null,
      proofMissing: false,
      outcomeUnconfirmed: false,
      outcomeUnconfirmedRequestId: null,
      pendingAction: null,
      awaitingReauthentication: false,
      reauthenticationRetryUsed: false,
    );

    if (export.status.isPending) {
      if (startPolling) {
        _startExportPolling(export.id);
      } else {
        _stopPolling();
      }
    } else {
      _stopPolling();
      _exportKey = null;
    }
  }

  void _applyDeletion(PrivacyDeletion deletion, {bool startPolling = true}) {
    final proofMissing =
        deletion.status == PrivacyRequestStatus.completed &&
        !deletion.isConfirmedComplete;

    state = state.copyWith(
      deletion: deletion,
      failure: null,
      notice: null,
      proofMissing: proofMissing,
      outcomeUnconfirmed: false,
      outcomeUnconfirmedRequestId: null,
      pendingAction: null,
      awaitingReauthentication: false,
      reauthenticationRetryUsed: false,
    );

    if (deletion.status.isPending) {
      if (startPolling) {
        _startDeletionPolling(deletion.id);
      } else {
        _stopPolling();
      }
    } else {
      _stopPolling();
      _deletionKey = null;
    }
  }

  void _startExportPolling(String requestId) {
    _stopPolling();
    state = state.copyWith(isPolling: true);
    _pollTimer = Timer.periodic(pollInterval, (_) {
      unawaited(refreshExport(requestId));
    });
  }

  void _startDeletionPolling(String requestId) {
    _stopPolling();
    state = state.copyWith(isPolling: true);
    _pollTimer = Timer.periodic(pollInterval, (_) {
      unawaited(refreshDeletion(requestId));
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (mounted && state.isPolling) {
      state = state.copyWith(isPolling: false);
    }
  }

  Future<void> _handleFailure(
    AuthFailure failure,
    PrivacyWorkflow workflow,
  ) async {
    if (failure.code == 'recent_authentication_required') {
      _handleRecentAuthentication(failure, workflow);
      return;
    }

    if (failure.code == 'expired_session') {
      await _expireSession(failure);
      return;
    }

    if (failure.code == 'network_error') {
      _markOffline();
    } else if (!_keepIdempotencyKey(failure)) {
      _resetKey(workflow);
    }

    state = state.copyWith(
      failure: failure,
      awaitingReauthentication: false,
      pendingAction: null,
    );
  }

  void _handleRecentAuthentication(
    AuthFailure failure,
    PrivacyWorkflow workflow,
  ) {
    if (state.reauthenticationRetryUsed) {
      state = state.copyWith(
        awaitingReauthentication: false,
        pendingAction: null,
        reauthenticationRetryUsed: false,
        failure: const AuthFailure(
          code: 'reauthentication_failed',
          message: 'Please sign in again to continue.',
        ),
      );
      return;
    }

    state = state.copyWith(
      awaitingReauthentication: true,
      pendingAction: _pendingActionFor(workflow),
      failure: failure,
    );
  }

  Future<void> _expireSession(AuthFailure failure) async {
    _stopPolling();
    state = state.copyWith(
      failure: failure,
      isLoading: false,
      isRefreshing: false,
      isSubmitting: false,
    );
    await sessionController.handleExpiredSession(failure);
  }

  void _markDeletionOutcomeUnconfirmed(String requestId) {
    _stopPolling();
    state = state.copyWith(
      outcomeUnconfirmed: true,
      outcomeUnconfirmedRequestId: requestId,
      failure: AuthFailure.expiredSession(
        'We could not confirm the deletion status. Sign in again to check it.',
      ),
      isLoading: false,
      isRefreshing: false,
      isSubmitting: false,
    );
  }

  bool _keepIdempotencyKey(AuthFailure failure) {
    return failure.code == 'network_error' ||
        failure.code == 'unknown' ||
        failure.code == 'temporarily_unavailable' ||
        failure.code == 'rate_limited' ||
        failure.code == 'operation_in_progress';
  }

  void _resetKey(PrivacyWorkflow workflow) {
    switch (workflow) {
      case PrivacyWorkflow.export:
        _exportKey = null;
      case PrivacyWorkflow.deletion:
        _deletionKey = null;
      case PrivacyWorkflow.cancellation:
        _cancelKey = null;
    }
  }

  String _keyForNewExportIntent() {
    if (state.export?.status.isTerminal ?? false) {
      _exportKey = null;
    }
    _exportKey ??= generateUuid();
    return _exportKey!;
  }

  String _keyForNewDeletionIntent() {
    if (state.deletion?.status.isTerminal ?? false) {
      _deletionKey = null;
    }
    _deletionKey ??= generateUuid();
    return _deletionKey!;
  }

  PrivacyPendingAction _pendingActionFor(PrivacyWorkflow workflow) {
    switch (workflow) {
      case PrivacyWorkflow.export:
        return PrivacyPendingAction.export;
      case PrivacyWorkflow.deletion:
        return PrivacyPendingAction.deletion;
      case PrivacyWorkflow.cancellation:
        return PrivacyPendingAction.cancellation;
    }
  }

  /// Returns a bootstrap pending summary that is not already resolved in state.
  PendingResourceSummaryDomain? _unresolvedBootstrapPending() {
    final pending =
        sessionController.state.bootstrapData?.pendingPrivacyRequests ??
        const <PendingResourceSummaryDomain>[];
    final resolvedIds = <String>{
      if (state.export?.status.isTerminal ?? false) state.export!.id,
      if (state.deletion?.status.isTerminal ?? false) state.deletion!.id,
    };

    for (final item in pending) {
      if (!resolvedIds.contains(item.id)) {
        return item;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }
}

/// Privacy repository used when the app is unconfigured. Production overrides.
final privacyRepositoryProvider = Provider<PrivacyRepository>((ref) {
  return MockPrivacyRepository();
});

/// Reachability probe. Production overrides with [ApiPrivacyReachability].
final privacyReachabilityProvider = Provider<PrivacyReachability>((ref) {
  return const StaticPrivacyReachability(true);
});

/// External download launcher. Production overrides with local HTTP rules.
final privacyDownloadLauncherProvider = Provider<PrivacyDownloadLauncher>((
  ref,
) {
  return UrlLauncherPrivacyDownloadLauncher();
});

final privacyControllerProvider =
    StateNotifierProvider<PrivacyController, PrivacyState>((ref) {
      final controller = PrivacyController(
        repository: ref.watch(privacyRepositoryProvider),
        reachability: ref.watch(privacyReachabilityProvider),
        sessionController: ref.watch(sessionControllerProvider.notifier),
        downloadLauncher: ref.watch(privacyDownloadLauncherProvider),
      );
      ref.onDispose(controller.dispose);
      return controller;
    });
