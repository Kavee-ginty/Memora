import 'package:flutter/foundation.dart';

/// Known consent policies and their approved human-readable labels.
///
/// The wire identifiers mirror the generated contract and are never derived
/// from a Dart enum `.name`.
enum ConsentPolicyKind {
  terms('terms', 'Terms of Use'),
  privacy('privacy', 'Privacy Notice'),
  materialProcessing('material_processing', 'Learning Material Processing'),
  modelProcessing('model_processing', 'AI Model Processing'),
  notifications('notifications', 'Notifications'),
  unknown('', '');

  const ConsentPolicyKind(this.wireId, this.label);

  final String wireId;
  final String label;

  bool get isKnown => this != ConsentPolicyKind.unknown;

  /// Resolves a server-returned policy wire identifier.
  static ConsentPolicyKind fromWireId(String wireId) {
    for (final kind in ConsentPolicyKind.values) {
      if (kind != ConsentPolicyKind.unknown && kind.wireId == wireId) {
        return kind;
      }
    }
    return ConsentPolicyKind.unknown;
  }
}

/// A server-returned consent policy and the current user's latest decision.
@immutable
class ConsentPolicy {
  const ConsentPolicy({
    required this.kind,
    required this.wireId,
    required this.version,
    required this.isRequired,
    required this.isCurrent,
    this.decision,
    this.decidedAt,
  });

  final ConsentPolicyKind kind;
  final String wireId;
  final String version;
  final bool isRequired;
  final bool isCurrent;
  final String? decision;
  final DateTime? decidedAt;

  bool get isKnown => kind.isKnown;

  /// True only when this policy currently blocks app use.
  bool get requiresAction =>
      isRequired && (!isCurrent || decision != 'granted');

  String get label => kind.label;

  /// The exact checkbox copy approved for this policy and version.
  String get checkboxLabel => 'I accept $label version $version.';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsentPolicy &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          wireId == other.wireId &&
          version == other.version &&
          isRequired == other.isRequired &&
          isCurrent == other.isCurrent &&
          decision == other.decision &&
          decidedAt == other.decidedAt;

  @override
  int get hashCode => Object.hash(
    kind,
    wireId,
    version,
    isRequired,
    isCurrent,
    decision,
    decidedAt,
  );
}
