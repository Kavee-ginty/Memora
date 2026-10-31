import 'package:flutter/foundation.dart';

import 'consent_policy.dart';

/// Lifecycle of the consent review destination.
enum ConsentPhase {
  initial,
  loading,
  ready,
  submitting,
  blocked,
  error,
  completed,
}

/// Immutable consent review state.
@immutable
class ConsentState {
  const ConsentState({
    this.phase = ConsentPhase.initial,
    this.policies = const <ConsentPolicy>[],
    this.selectedWireIds = const <String>{},
    this.notice,
    this.errorMessage,
    this.retryable = false,
  });

  final ConsentPhase phase;
  final List<ConsentPolicy> policies;
  final Set<String> selectedWireIds;

  /// Safe informational message such as a policy version change.
  final String? notice;

  /// Safe failure message for the current error state.
  final String? errorMessage;
  final bool retryable;

  List<ConsentPolicy> get requiredPolicies =>
      policies.where((policy) => policy.requiresAction).toList(growable: false);

  bool get hasRequired => requiredPolicies.isNotEmpty;

  /// Unknown required policies fail closed and can never be accepted.
  bool get hasUnknownRequired =>
      requiredPolicies.any((policy) => !policy.isKnown);

  bool isSelected(String wireId) => selectedWireIds.contains(wireId);

  bool get allRequiredSelected =>
      hasRequired &&
      requiredPolicies.every(
        (policy) => selectedWireIds.contains(policy.wireId),
      );

  bool get canSubmit =>
      phase == ConsentPhase.ready && !hasUnknownRequired && allRequiredSelected;

  ConsentState copyWith({
    ConsentPhase? phase,
    List<ConsentPolicy>? policies,
    Set<String>? selectedWireIds,
    String? notice,
    bool clearNotice = false,
    String? errorMessage,
    bool clearError = false,
    bool? retryable,
  }) {
    return ConsentState(
      phase: phase ?? this.phase,
      policies: policies ?? this.policies,
      selectedWireIds: selectedWireIds ?? this.selectedWireIds,
      notice: clearNotice ? null : (notice ?? this.notice),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      retryable: retryable ?? this.retryable,
    );
  }
}
