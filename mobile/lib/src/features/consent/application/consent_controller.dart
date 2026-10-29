import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_session_state.dart';
import '../../common/ids.dart';
import '../data/consent_repository.dart';
import '../domain/consent_policy.dart';
import '../domain/consent_state.dart';

/// Repository provider overridden with the generated client implementation in
/// the running application.
final consentRepositoryProvider = Provider<ConsentRepository>((ref) {
  return MockConsentRepository();
});

final consentControllerProvider =
    StateNotifierProvider.autoDispose<ConsentController, ConsentState>((ref) {
      return ConsentController(
        repository: ref.watch(consentRepositoryProvider),
        sessionController: ref.watch(sessionControllerProvider.notifier),
      );
    });

/// Coordinates server-derived consent review and acceptance.
class ConsentController extends StateNotifier<ConsentState> {
  ConsentController({
    required this.repository,
    required this.sessionController,
    ConsentState initialState = const ConsentState(),
  }) : super(initialState);

  final ConsentRepository repository;
  final SessionController sessionController;

  /// One stable idempotency key per policy wire ID and version while that
  /// acceptance remains unresolved.
  final Map<String, String> _idempotencyKeys = <String, String>{};

  String? get _accessToken => sessionController.state.session?.accessToken;

  Future<void> load() => _reload();

  /// Toggles one currently required, known policy.
  void toggle(String wireId) {
    if (state.phase != ConsentPhase.ready) return;
    ConsentPolicy? policy;
    for (final item in state.policies) {
      if (item.wireId == wireId && item.requiresAction) {
        policy = item;
        break;
      }
    }
    if (policy == null || !policy.isKnown) return;

    final selected = Set<String>.of(state.selectedWireIds);
    if (!selected.add(wireId)) {
      selected.remove(wireId);
    }
    state = state.copyWith(selectedWireIds: selected, clearError: true);
  }

  /// Submits every currently required policy sequentially, or continues when
  /// nothing requires action.
  Future<void> submit() async {
    if (state.phase != ConsentPhase.ready) return;
    if (state.hasUnknownRequired) {
      state = state.copyWith(phase: ConsentPhase.blocked);
      return;
    }
    if (state.hasRequired && !state.allRequiredSelected) return;

    final required = state.requiredPolicies;
    state = state.copyWith(
      phase: ConsentPhase.submitting,
      clearNotice: true,
      clearError: true,
    );

    final accessToken = _accessToken;
    if (accessToken == null) {
      state = state.copyWith(
        phase: ConsentPhase.error,
        errorMessage: 'Please sign in again to continue.',
        retryable: false,
      );
      return;
    }

    for (final policy in required) {
      if (!policy.isKnown) {
        state = state.copyWith(phase: ConsentPhase.blocked);
        return;
      }

      final key = _keyFor(policy);
      final idempotencyKey = _idempotencyKeys.putIfAbsent(key, generateUuid);

      try {
        await repository.acceptConsent(
          accessToken: accessToken,
          kind: policy.kind,
          wireId: policy.wireId,
          policyVersion: policy.version,
          idempotencyKey: idempotencyKey,
        );
        _idempotencyKeys.remove(key);
      } on AuthFailure catch (failure) {
        if (!mounted) return;
        if (failure.code == 'expired_session') {
          await sessionController.handleExpiredSession(failure);
          return;
        }
        if (failure.code == 'version_conflict') {
          await _reload(
            notice: 'A consent policy has changed. Review the new version to continue.',
          );
          return;
        }
        await _reload(notice: failure.message);
        return;
      } catch (_) {
        if (!mounted) return;
        await _reload(
          notice: 'We could not save your consent. Check your connection and try again.',
        );
        return;
      }
    }

    await _finish();
  }

  Future<void> _finish() async {
    final session = sessionController.state.session;
    if (session == null) {
      if (!mounted) return;
      state = state.copyWith(
        phase: ConsentPhase.error,
        errorMessage: 'Please sign in again to continue.',
        retryable: false,
      );
      return;
    }

    // Refresh authoritative bootstrap state before navigation so the guard
    // sees the accepted policies.
    await sessionController.bootstrapWithSession(session);
    if (!mounted) return;

    final refreshed = sessionController.state;
    if (refreshed.phase != AppSessionPhase.active) {
      // The router owns the signed-out, blocked or retry destination.
      return;
    }

    if (refreshed.bootstrapData?.consentStatus.requiresReview ?? false) {
      await _reload(notice: 'Additional policies require review.');
      return;
    }

    state = state.copyWith(
      phase: ConsentPhase.completed,
      selectedWireIds: const <String>{},
      clearNotice: true,
      clearError: true,
    );
  }

  Future<void> _reload({String? notice}) async {
    if (!mounted) return;
    state = state.copyWith(
      phase: ConsentPhase.loading,
      selectedWireIds: const <String>{},
      notice: notice,
      clearError: true,
    );

    final accessToken = _accessToken;
    if (accessToken == null) {
      state = state.copyWith(
        phase: ConsentPhase.error,
        errorMessage: 'Please sign in again to continue.',
        retryable: false,
      );
      return;
    }

    try {
      final policies = await repository.fetchConsent(accessToken: accessToken);
      if (!mounted) return;
      _pruneIdempotencyKeys(policies);

      final hasUnknownRequired = policies.any(
        (policy) => policy.requiresAction && !policy.isKnown,
      );
      state = ConsentState(
        phase: hasUnknownRequired ? ConsentPhase.blocked : ConsentPhase.ready,
        policies: policies,
        notice: notice,
      );
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      if (failure.code == 'expired_session') {
        await sessionController.handleExpiredSession(failure);
        return;
      }
      state = state.copyWith(
        phase: ConsentPhase.error,
        errorMessage: failure.message,
        retryable: failure.retryable,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        phase: ConsentPhase.error,
        errorMessage:
            'We could not load your consent choices. Please try again.',
        retryable: true,
      );
    }
  }

  /// Removes retained keys for policies that no longer require the same
  /// version, including after a version conflict.
  void _pruneIdempotencyKeys(List<ConsentPolicy> policies) {
    final activeKeys = policies
        .where((policy) => policy.requiresAction && policy.isKnown)
        .map(_keyFor)
        .toSet();
    _idempotencyKeys.removeWhere((key, _) => !activeKeys.contains(key));
  }

  String _keyFor(ConsentPolicy policy) => '${policy.wireId}@${policy.version}';
}
