// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ConsentResponse extends ConsentResponse {
  @override
  final BuiltList<ConsentStatus> policies;

  factory _$ConsentResponse([void Function(ConsentResponseBuilder)? updates]) =>
      (ConsentResponseBuilder()..update(updates))._build();

  _$ConsentResponse._({required this.policies}) : super._();
  @override
  ConsentResponse rebuild(void Function(ConsentResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConsentResponseBuilder toBuilder() => ConsentResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ConsentResponse && policies == other.policies;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, policies.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ConsentResponse')
          ..add('policies', policies))
        .toString();
  }
}

class ConsentResponseBuilder
    implements Builder<ConsentResponse, ConsentResponseBuilder> {
  _$ConsentResponse? _$v;

  ListBuilder<ConsentStatus>? _policies;
  ListBuilder<ConsentStatus> get policies =>
      _$this._policies ??= ListBuilder<ConsentStatus>();
  set policies(ListBuilder<ConsentStatus>? policies) =>
      _$this._policies = policies;

  ConsentResponseBuilder() {
    ConsentResponse._defaults(this);
  }

  ConsentResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _policies = $v.policies.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ConsentResponse other) {
    _$v = other as _$ConsentResponse;
  }

  @override
  void update(void Function(ConsentResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ConsentResponse build() => _build();

  _$ConsentResponse _build() {
    _$ConsentResponse _$result;
    try {
      _$result = _$v ??
          _$ConsentResponse._(
            policies: policies.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'policies';
        policies.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ConsentResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
