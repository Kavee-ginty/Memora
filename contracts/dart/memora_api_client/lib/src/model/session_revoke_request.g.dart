// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_revoke_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SessionRevokeRequest extends SessionRevokeRequest {
  @override
  final Optional<SessionRevocationScope?> scope;

  factory _$SessionRevokeRequest(
          [void Function(SessionRevokeRequestBuilder)? updates]) =>
      (SessionRevokeRequestBuilder()..update(updates))._build();

  _$SessionRevokeRequest._({required this.scope}) : super._();
  @override
  SessionRevokeRequest rebuild(
          void Function(SessionRevokeRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SessionRevokeRequestBuilder toBuilder() =>
      SessionRevokeRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SessionRevokeRequest && scope == other.scope;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, scope.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SessionRevokeRequest')
          ..add('scope', scope))
        .toString();
  }
}

class SessionRevokeRequestBuilder
    implements Builder<SessionRevokeRequest, SessionRevokeRequestBuilder> {
  _$SessionRevokeRequest? _$v;

  Optional<SessionRevocationScope?>? _scope;
  Optional<SessionRevocationScope?>? get scope => _$this._scope;
  set scope(Optional<SessionRevocationScope?>? scope) => _$this._scope = scope;

  SessionRevokeRequestBuilder() {
    SessionRevokeRequest._defaults(this);
  }

  SessionRevokeRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _scope = $v.scope;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SessionRevokeRequest other) {
    _$v = other as _$SessionRevokeRequest;
  }

  @override
  void update(void Function(SessionRevokeRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SessionRevokeRequest build() => _build();

  _$SessionRevokeRequest _build() {
    final _$result = _$v ??
        _$SessionRevokeRequest._(
          scope: BuiltValueNullFieldError.checkNotNull(
              scope, r'SessionRevokeRequest', 'scope'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
