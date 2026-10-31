// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_decision_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$VerificationDecisionResult extends VerificationDecisionResult {
  @override
  final String candidateId;
  @override
  final CandidateStatus candidateStatus;
  @override
  final bool requiresVerification;

  factory _$VerificationDecisionResult(
          [void Function(VerificationDecisionResultBuilder)? updates]) =>
      (VerificationDecisionResultBuilder()..update(updates))._build();

  _$VerificationDecisionResult._(
      {required this.candidateId,
      required this.candidateStatus,
      required this.requiresVerification})
      : super._();
  @override
  VerificationDecisionResult rebuild(
          void Function(VerificationDecisionResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VerificationDecisionResultBuilder toBuilder() =>
      VerificationDecisionResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VerificationDecisionResult &&
        candidateId == other.candidateId &&
        candidateStatus == other.candidateStatus &&
        requiresVerification == other.requiresVerification;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, candidateId.hashCode);
    _$hash = $jc(_$hash, candidateStatus.hashCode);
    _$hash = $jc(_$hash, requiresVerification.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'VerificationDecisionResult')
          ..add('candidateId', candidateId)
          ..add('candidateStatus', candidateStatus)
          ..add('requiresVerification', requiresVerification))
        .toString();
  }
}

class VerificationDecisionResultBuilder
    implements
        Builder<VerificationDecisionResult, VerificationDecisionResultBuilder> {
  _$VerificationDecisionResult? _$v;

  String? _candidateId;
  String? get candidateId => _$this._candidateId;
  set candidateId(String? candidateId) => _$this._candidateId = candidateId;

  CandidateStatus? _candidateStatus;
  CandidateStatus? get candidateStatus => _$this._candidateStatus;
  set candidateStatus(CandidateStatus? candidateStatus) =>
      _$this._candidateStatus = candidateStatus;

  bool? _requiresVerification;
  bool? get requiresVerification => _$this._requiresVerification;
  set requiresVerification(bool? requiresVerification) =>
      _$this._requiresVerification = requiresVerification;

  VerificationDecisionResultBuilder() {
    VerificationDecisionResult._defaults(this);
  }

  VerificationDecisionResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _candidateId = $v.candidateId;
      _candidateStatus = $v.candidateStatus;
      _requiresVerification = $v.requiresVerification;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VerificationDecisionResult other) {
    _$v = other as _$VerificationDecisionResult;
  }

  @override
  void update(void Function(VerificationDecisionResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  VerificationDecisionResult build() => _build();

  _$VerificationDecisionResult _build() {
    final _$result = _$v ??
        _$VerificationDecisionResult._(
          candidateId: BuiltValueNullFieldError.checkNotNull(
              candidateId, r'VerificationDecisionResult', 'candidateId'),
          candidateStatus: BuiltValueNullFieldError.checkNotNull(
              candidateStatus,
              r'VerificationDecisionResult',
              'candidateStatus'),
          requiresVerification: BuiltValueNullFieldError.checkNotNull(
              requiresVerification,
              r'VerificationDecisionResult',
              'requiresVerification'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
