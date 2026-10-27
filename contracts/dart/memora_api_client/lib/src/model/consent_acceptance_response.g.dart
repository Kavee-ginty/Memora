// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_acceptance_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ConsentAcceptanceResponse extends ConsentAcceptanceResponse {
  @override
  final BuiltList<String> acceptedScopes;
  @override
  final DateTime decidedAt;
  @override
  final ConsentDecision decision;
  @override
  final String id;
  @override
  final ConsentType policyId;
  @override
  final String policyVersion;

  factory _$ConsentAcceptanceResponse(
          [void Function(ConsentAcceptanceResponseBuilder)? updates]) =>
      (ConsentAcceptanceResponseBuilder()..update(updates))._build();

  _$ConsentAcceptanceResponse._(
      {required this.acceptedScopes,
      required this.decidedAt,
      required this.decision,
      required this.id,
      required this.policyId,
      required this.policyVersion})
      : super._();
  @override
  ConsentAcceptanceResponse rebuild(
          void Function(ConsentAcceptanceResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConsentAcceptanceResponseBuilder toBuilder() =>
      ConsentAcceptanceResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ConsentAcceptanceResponse &&
        acceptedScopes == other.acceptedScopes &&
        decidedAt == other.decidedAt &&
        decision == other.decision &&
        id == other.id &&
        policyId == other.policyId &&
        policyVersion == other.policyVersion;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, acceptedScopes.hashCode);
    _$hash = $jc(_$hash, decidedAt.hashCode);
    _$hash = $jc(_$hash, decision.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, policyId.hashCode);
    _$hash = $jc(_$hash, policyVersion.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ConsentAcceptanceResponse')
          ..add('acceptedScopes', acceptedScopes)
          ..add('decidedAt', decidedAt)
          ..add('decision', decision)
          ..add('id', id)
          ..add('policyId', policyId)
          ..add('policyVersion', policyVersion))
        .toString();
  }
}

class ConsentAcceptanceResponseBuilder
    implements
        Builder<ConsentAcceptanceResponse, ConsentAcceptanceResponseBuilder> {
  _$ConsentAcceptanceResponse? _$v;

  ListBuilder<String>? _acceptedScopes;
  ListBuilder<String> get acceptedScopes =>
      _$this._acceptedScopes ??= ListBuilder<String>();
  set acceptedScopes(ListBuilder<String>? acceptedScopes) =>
      _$this._acceptedScopes = acceptedScopes;

  DateTime? _decidedAt;
  DateTime? get decidedAt => _$this._decidedAt;
  set decidedAt(DateTime? decidedAt) => _$this._decidedAt = decidedAt;

  ConsentDecision? _decision;
  ConsentDecision? get decision => _$this._decision;
  set decision(ConsentDecision? decision) => _$this._decision = decision;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  ConsentType? _policyId;
  ConsentType? get policyId => _$this._policyId;
  set policyId(ConsentType? policyId) => _$this._policyId = policyId;

  String? _policyVersion;
  String? get policyVersion => _$this._policyVersion;
  set policyVersion(String? policyVersion) =>
      _$this._policyVersion = policyVersion;

  ConsentAcceptanceResponseBuilder() {
    ConsentAcceptanceResponse._defaults(this);
  }

  ConsentAcceptanceResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _acceptedScopes = $v.acceptedScopes.toBuilder();
      _decidedAt = $v.decidedAt;
      _decision = $v.decision;
      _id = $v.id;
      _policyId = $v.policyId;
      _policyVersion = $v.policyVersion;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ConsentAcceptanceResponse other) {
    _$v = other as _$ConsentAcceptanceResponse;
  }

  @override
  void update(void Function(ConsentAcceptanceResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ConsentAcceptanceResponse build() => _build();

  _$ConsentAcceptanceResponse _build() {
    _$ConsentAcceptanceResponse _$result;
    try {
      _$result = _$v ??
          _$ConsentAcceptanceResponse._(
            acceptedScopes: acceptedScopes.build(),
            decidedAt: BuiltValueNullFieldError.checkNotNull(
                decidedAt, r'ConsentAcceptanceResponse', 'decidedAt'),
            decision: BuiltValueNullFieldError.checkNotNull(
                decision, r'ConsentAcceptanceResponse', 'decision'),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'ConsentAcceptanceResponse', 'id'),
            policyId: BuiltValueNullFieldError.checkNotNull(
                policyId, r'ConsentAcceptanceResponse', 'policyId'),
            policyVersion: BuiltValueNullFieldError.checkNotNull(
                policyVersion, r'ConsentAcceptanceResponse', 'policyVersion'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'acceptedScopes';
        acceptedScopes.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ConsentAcceptanceResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
