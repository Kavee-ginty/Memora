// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_decision.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$VerificationDecision extends VerificationDecision {
  @override
  final String candidateId;
  @override
  final int candidateVersion;
  @override
  final BuiltMap<String, JsonObject?> correctedPayload;
  @override
  final VerificationDecisionValue decision;

  factory _$VerificationDecision(
          [void Function(VerificationDecisionBuilder)? updates]) =>
      (VerificationDecisionBuilder()..update(updates))._build();

  _$VerificationDecision._(
      {required this.candidateId,
      required this.candidateVersion,
      required this.correctedPayload,
      required this.decision})
      : super._();
  @override
  VerificationDecision rebuild(
          void Function(VerificationDecisionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VerificationDecisionBuilder toBuilder() =>
      VerificationDecisionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VerificationDecision &&
        candidateId == other.candidateId &&
        candidateVersion == other.candidateVersion &&
        correctedPayload == other.correctedPayload &&
        decision == other.decision;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, candidateId.hashCode);
    _$hash = $jc(_$hash, candidateVersion.hashCode);
    _$hash = $jc(_$hash, correctedPayload.hashCode);
    _$hash = $jc(_$hash, decision.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'VerificationDecision')
          ..add('candidateId', candidateId)
          ..add('candidateVersion', candidateVersion)
          ..add('correctedPayload', correctedPayload)
          ..add('decision', decision))
        .toString();
  }
}

class VerificationDecisionBuilder
    implements Builder<VerificationDecision, VerificationDecisionBuilder> {
  _$VerificationDecision? _$v;

  String? _candidateId;
  String? get candidateId => _$this._candidateId;
  set candidateId(String? candidateId) => _$this._candidateId = candidateId;

  int? _candidateVersion;
  int? get candidateVersion => _$this._candidateVersion;
  set candidateVersion(int? candidateVersion) =>
      _$this._candidateVersion = candidateVersion;

  MapBuilder<String, JsonObject?>? _correctedPayload;
  MapBuilder<String, JsonObject?> get correctedPayload =>
      _$this._correctedPayload ??= MapBuilder<String, JsonObject?>();
  set correctedPayload(MapBuilder<String, JsonObject?>? correctedPayload) =>
      _$this._correctedPayload = correctedPayload;

  VerificationDecisionValue? _decision;
  VerificationDecisionValue? get decision => _$this._decision;
  set decision(VerificationDecisionValue? decision) =>
      _$this._decision = decision;

  VerificationDecisionBuilder() {
    VerificationDecision._defaults(this);
  }

  VerificationDecisionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _candidateId = $v.candidateId;
      _candidateVersion = $v.candidateVersion;
      _correctedPayload = $v.correctedPayload.toBuilder();
      _decision = $v.decision;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VerificationDecision other) {
    _$v = other as _$VerificationDecision;
  }

  @override
  void update(void Function(VerificationDecisionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  VerificationDecision build() => _build();

  _$VerificationDecision _build() {
    _$VerificationDecision _$result;
    try {
      _$result = _$v ??
          _$VerificationDecision._(
            candidateId: BuiltValueNullFieldError.checkNotNull(
                candidateId, r'VerificationDecision', 'candidateId'),
            candidateVersion: BuiltValueNullFieldError.checkNotNull(
                candidateVersion, r'VerificationDecision', 'candidateVersion'),
            correctedPayload: correctedPayload.build(),
            decision: BuiltValueNullFieldError.checkNotNull(
                decision, r'VerificationDecision', 'decision'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'correctedPayload';
        correctedPayload.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'VerificationDecision', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
