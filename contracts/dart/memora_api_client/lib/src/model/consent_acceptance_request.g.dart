// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_acceptance_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ConsentAcceptanceRequest extends ConsentAcceptanceRequest {
  @override
  final BuiltList<String> acceptedScopes;
  @override
  final ConsentType policyId;
  @override
  final String policyVersion;

  factory _$ConsentAcceptanceRequest(
          [void Function(ConsentAcceptanceRequestBuilder)? updates]) =>
      (ConsentAcceptanceRequestBuilder()..update(updates))._build();

  _$ConsentAcceptanceRequest._(
      {required this.acceptedScopes,
      required this.policyId,
      required this.policyVersion})
      : super._();
  @override
  ConsentAcceptanceRequest rebuild(
          void Function(ConsentAcceptanceRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConsentAcceptanceRequestBuilder toBuilder() =>
      ConsentAcceptanceRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ConsentAcceptanceRequest &&
        acceptedScopes == other.acceptedScopes &&
        policyId == other.policyId &&
        policyVersion == other.policyVersion;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, acceptedScopes.hashCode);
    _$hash = $jc(_$hash, policyId.hashCode);
    _$hash = $jc(_$hash, policyVersion.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ConsentAcceptanceRequest')
          ..add('acceptedScopes', acceptedScopes)
          ..add('policyId', policyId)
          ..add('policyVersion', policyVersion))
        .toString();
  }
}

class ConsentAcceptanceRequestBuilder
    implements
        Builder<ConsentAcceptanceRequest, ConsentAcceptanceRequestBuilder> {
  _$ConsentAcceptanceRequest? _$v;

  ListBuilder<String>? _acceptedScopes;
  ListBuilder<String> get acceptedScopes =>
      _$this._acceptedScopes ??= ListBuilder<String>();
  set acceptedScopes(ListBuilder<String>? acceptedScopes) =>
      _$this._acceptedScopes = acceptedScopes;

  ConsentType? _policyId;
  ConsentType? get policyId => _$this._policyId;
  set policyId(ConsentType? policyId) => _$this._policyId = policyId;

  String? _policyVersion;
  String? get policyVersion => _$this._policyVersion;
  set policyVersion(String? policyVersion) =>
      _$this._policyVersion = policyVersion;

  ConsentAcceptanceRequestBuilder() {
    ConsentAcceptanceRequest._defaults(this);
  }

  ConsentAcceptanceRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _acceptedScopes = $v.acceptedScopes.toBuilder();
      _policyId = $v.policyId;
      _policyVersion = $v.policyVersion;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ConsentAcceptanceRequest other) {
    _$v = other as _$ConsentAcceptanceRequest;
  }

  @override
  void update(void Function(ConsentAcceptanceRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ConsentAcceptanceRequest build() => _build();

  _$ConsentAcceptanceRequest _build() {
    _$ConsentAcceptanceRequest _$result;
    try {
      _$result = _$v ??
          _$ConsentAcceptanceRequest._(
            acceptedScopes: acceptedScopes.build(),
            policyId: BuiltValueNullFieldError.checkNotNull(
                policyId, r'ConsentAcceptanceRequest', 'policyId'),
            policyVersion: BuiltValueNullFieldError.checkNotNull(
                policyVersion, r'ConsentAcceptanceRequest', 'policyVersion'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'acceptedScopes';
        acceptedScopes.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ConsentAcceptanceRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
