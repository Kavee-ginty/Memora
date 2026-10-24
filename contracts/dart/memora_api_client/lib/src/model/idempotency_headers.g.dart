// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'idempotency_headers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$IdempotencyHeaders extends IdempotencyHeaders {
  @override
  final String idempotencyKey;

  factory _$IdempotencyHeaders(
          [void Function(IdempotencyHeadersBuilder)? updates]) =>
      (IdempotencyHeadersBuilder()..update(updates))._build();

  _$IdempotencyHeaders._({required this.idempotencyKey}) : super._();
  @override
  IdempotencyHeaders rebuild(
          void Function(IdempotencyHeadersBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  IdempotencyHeadersBuilder toBuilder() =>
      IdempotencyHeadersBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is IdempotencyHeaders &&
        idempotencyKey == other.idempotencyKey;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, idempotencyKey.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'IdempotencyHeaders')
          ..add('idempotencyKey', idempotencyKey))
        .toString();
  }
}

class IdempotencyHeadersBuilder
    implements Builder<IdempotencyHeaders, IdempotencyHeadersBuilder> {
  _$IdempotencyHeaders? _$v;

  String? _idempotencyKey;
  String? get idempotencyKey => _$this._idempotencyKey;
  set idempotencyKey(String? idempotencyKey) =>
      _$this._idempotencyKey = idempotencyKey;

  IdempotencyHeadersBuilder() {
    IdempotencyHeaders._defaults(this);
  }

  IdempotencyHeadersBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _idempotencyKey = $v.idempotencyKey;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(IdempotencyHeaders other) {
    _$v = other as _$IdempotencyHeaders;
  }

  @override
  void update(void Function(IdempotencyHeadersBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  IdempotencyHeaders build() => _build();

  _$IdempotencyHeaders _build() {
    final _$result = _$v ??
        _$IdempotencyHeaders._(
          idempotencyKey: BuiltValueNullFieldError.checkNotNull(
              idempotencyKey, r'IdempotencyHeaders', 'idempotencyKey'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
