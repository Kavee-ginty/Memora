// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ConsentStatus extends ConsentStatus {
  @override
  final DateTime? decidedAt;
  @override
  final ConsentDecision? decision;
  @override
  final bool isCurrent;
  @override
  final ConsentType policyId;
  @override
  final String policyVersion;
  @override
  final bool required_;

  factory _$ConsentStatus([void Function(ConsentStatusBuilder)? updates]) =>
      (ConsentStatusBuilder()..update(updates))._build();

  _$ConsentStatus._(
      {this.decidedAt,
      this.decision,
      required this.isCurrent,
      required this.policyId,
      required this.policyVersion,
      required this.required_})
      : super._();
  @override
  ConsentStatus rebuild(void Function(ConsentStatusBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConsentStatusBuilder toBuilder() => ConsentStatusBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ConsentStatus &&
        decidedAt == other.decidedAt &&
        decision == other.decision &&
        isCurrent == other.isCurrent &&
        policyId == other.policyId &&
        policyVersion == other.policyVersion &&
        required_ == other.required_;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, decidedAt.hashCode);
    _$hash = $jc(_$hash, decision.hashCode);
    _$hash = $jc(_$hash, isCurrent.hashCode);
    _$hash = $jc(_$hash, policyId.hashCode);
    _$hash = $jc(_$hash, policyVersion.hashCode);
    _$hash = $jc(_$hash, required_.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ConsentStatus')
          ..add('decidedAt', decidedAt)
          ..add('decision', decision)
          ..add('isCurrent', isCurrent)
          ..add('policyId', policyId)
          ..add('policyVersion', policyVersion)
          ..add('required_', required_))
        .toString();
  }
}

class ConsentStatusBuilder
    implements Builder<ConsentStatus, ConsentStatusBuilder> {
  _$ConsentStatus? _$v;

  DateTime? _decidedAt;
  DateTime? get decidedAt => _$this._decidedAt;
  set decidedAt(DateTime? decidedAt) => _$this._decidedAt = decidedAt;

  ConsentDecision? _decision;
  ConsentDecision? get decision => _$this._decision;
  set decision(ConsentDecision? decision) => _$this._decision = decision;

  bool? _isCurrent;
  bool? get isCurrent => _$this._isCurrent;
  set isCurrent(bool? isCurrent) => _$this._isCurrent = isCurrent;

  ConsentType? _policyId;
  ConsentType? get policyId => _$this._policyId;
  set policyId(ConsentType? policyId) => _$this._policyId = policyId;

  String? _policyVersion;
  String? get policyVersion => _$this._policyVersion;
  set policyVersion(String? policyVersion) =>
      _$this._policyVersion = policyVersion;

  bool? _required_;
  bool? get required_ => _$this._required_;
  set required_(bool? required_) => _$this._required_ = required_;

  ConsentStatusBuilder() {
    ConsentStatus._defaults(this);
  }

  ConsentStatusBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _decidedAt = $v.decidedAt;
      _decision = $v.decision;
      _isCurrent = $v.isCurrent;
      _policyId = $v.policyId;
      _policyVersion = $v.policyVersion;
      _required_ = $v.required_;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ConsentStatus other) {
    _$v = other as _$ConsentStatus;
  }

  @override
  void update(void Function(ConsentStatusBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ConsentStatus build() => _build();

  _$ConsentStatus _build() {
    final _$result = _$v ??
        _$ConsentStatus._(
          decidedAt: decidedAt,
          decision: decision,
          isCurrent: BuiltValueNullFieldError.checkNotNull(
              isCurrent, r'ConsentStatus', 'isCurrent'),
          policyId: BuiltValueNullFieldError.checkNotNull(
              policyId, r'ConsentStatus', 'policyId'),
          policyVersion: BuiltValueNullFieldError.checkNotNull(
              policyVersion, r'ConsentStatus', 'policyVersion'),
          required_: BuiltValueNullFieldError.checkNotNull(
              required_, r'ConsentStatus', 'required_'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
