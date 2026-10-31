// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_proof_summary.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeletionProofSummary extends DeletionProofSummary {
  @override
  final String id;
  @override
  final String provider;
  @override
  final String result;
  @override
  final String scope;
  @override
  final String targetFingerprint;
  @override
  final String verifiedAt;

  factory _$DeletionProofSummary(
          [void Function(DeletionProofSummaryBuilder)? updates]) =>
      (DeletionProofSummaryBuilder()..update(updates))._build();

  _$DeletionProofSummary._(
      {required this.id,
      required this.provider,
      required this.result,
      required this.scope,
      required this.targetFingerprint,
      required this.verifiedAt})
      : super._();
  @override
  DeletionProofSummary rebuild(
          void Function(DeletionProofSummaryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeletionProofSummaryBuilder toBuilder() =>
      DeletionProofSummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeletionProofSummary &&
        id == other.id &&
        provider == other.provider &&
        result == other.result &&
        scope == other.scope &&
        targetFingerprint == other.targetFingerprint &&
        verifiedAt == other.verifiedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, provider.hashCode);
    _$hash = $jc(_$hash, result.hashCode);
    _$hash = $jc(_$hash, scope.hashCode);
    _$hash = $jc(_$hash, targetFingerprint.hashCode);
    _$hash = $jc(_$hash, verifiedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DeletionProofSummary')
          ..add('id', id)
          ..add('provider', provider)
          ..add('result', result)
          ..add('scope', scope)
          ..add('targetFingerprint', targetFingerprint)
          ..add('verifiedAt', verifiedAt))
        .toString();
  }
}

class DeletionProofSummaryBuilder
    implements Builder<DeletionProofSummary, DeletionProofSummaryBuilder> {
  _$DeletionProofSummary? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _provider;
  String? get provider => _$this._provider;
  set provider(String? provider) => _$this._provider = provider;

  String? _result;
  String? get result => _$this._result;
  set result(String? result) => _$this._result = result;

  String? _scope;
  String? get scope => _$this._scope;
  set scope(String? scope) => _$this._scope = scope;

  String? _targetFingerprint;
  String? get targetFingerprint => _$this._targetFingerprint;
  set targetFingerprint(String? targetFingerprint) =>
      _$this._targetFingerprint = targetFingerprint;

  String? _verifiedAt;
  String? get verifiedAt => _$this._verifiedAt;
  set verifiedAt(String? verifiedAt) => _$this._verifiedAt = verifiedAt;

  DeletionProofSummaryBuilder() {
    DeletionProofSummary._defaults(this);
  }

  DeletionProofSummaryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _provider = $v.provider;
      _result = $v.result;
      _scope = $v.scope;
      _targetFingerprint = $v.targetFingerprint;
      _verifiedAt = $v.verifiedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeletionProofSummary other) {
    _$v = other as _$DeletionProofSummary;
  }

  @override
  void update(void Function(DeletionProofSummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeletionProofSummary build() => _build();

  _$DeletionProofSummary _build() {
    final _$result = _$v ??
        _$DeletionProofSummary._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'DeletionProofSummary', 'id'),
          provider: BuiltValueNullFieldError.checkNotNull(
              provider, r'DeletionProofSummary', 'provider'),
          result: BuiltValueNullFieldError.checkNotNull(
              result, r'DeletionProofSummary', 'result'),
          scope: BuiltValueNullFieldError.checkNotNull(
              scope, r'DeletionProofSummary', 'scope'),
          targetFingerprint: BuiltValueNullFieldError.checkNotNull(
              targetFingerprint, r'DeletionProofSummary', 'targetFingerprint'),
          verifiedAt: BuiltValueNullFieldError.checkNotNull(
              verifiedAt, r'DeletionProofSummary', 'verifiedAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
