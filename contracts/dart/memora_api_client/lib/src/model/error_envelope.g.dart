// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_envelope.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ErrorEnvelope extends ErrorEnvelope {
  @override
  final ErrorDetail error;

  factory _$ErrorEnvelope([void Function(ErrorEnvelopeBuilder)? updates]) =>
      (ErrorEnvelopeBuilder()..update(updates))._build();

  _$ErrorEnvelope._({required this.error}) : super._();
  @override
  ErrorEnvelope rebuild(void Function(ErrorEnvelopeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ErrorEnvelopeBuilder toBuilder() => ErrorEnvelopeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ErrorEnvelope && error == other.error;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, error.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ErrorEnvelope')..add('error', error))
        .toString();
  }
}

class ErrorEnvelopeBuilder
    implements Builder<ErrorEnvelope, ErrorEnvelopeBuilder> {
  _$ErrorEnvelope? _$v;

  ErrorDetailBuilder? _error;
  ErrorDetailBuilder get error => _$this._error ??= ErrorDetailBuilder();
  set error(ErrorDetailBuilder? error) => _$this._error = error;

  ErrorEnvelopeBuilder() {
    ErrorEnvelope._defaults(this);
  }

  ErrorEnvelopeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _error = $v.error.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ErrorEnvelope other) {
    _$v = other as _$ErrorEnvelope;
  }

  @override
  void update(void Function(ErrorEnvelopeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ErrorEnvelope build() => _build();

  _$ErrorEnvelope _build() {
    _$ErrorEnvelope _$result;
    try {
      _$result = _$v ??
          _$ErrorEnvelope._(
            error: error.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'error';
        error.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ErrorEnvelope', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
