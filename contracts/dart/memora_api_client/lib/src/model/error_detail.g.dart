// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_detail.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ErrorDetail extends ErrorDetail {
  @override
  final String? action;
  @override
  final String code;
  @override
  final BuiltList<FieldError> fieldErrors;
  @override
  final String message;
  @override
  final String requestId;
  @override
  final int? retryAfterSeconds;
  @override
  final bool retryable;

  factory _$ErrorDetail([void Function(ErrorDetailBuilder)? updates]) =>
      (ErrorDetailBuilder()..update(updates))._build();

  _$ErrorDetail._(
      {this.action,
      required this.code,
      required this.fieldErrors,
      required this.message,
      required this.requestId,
      this.retryAfterSeconds,
      required this.retryable})
      : super._();
  @override
  ErrorDetail rebuild(void Function(ErrorDetailBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ErrorDetailBuilder toBuilder() => ErrorDetailBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ErrorDetail &&
        action == other.action &&
        code == other.code &&
        fieldErrors == other.fieldErrors &&
        message == other.message &&
        requestId == other.requestId &&
        retryAfterSeconds == other.retryAfterSeconds &&
        retryable == other.retryable;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, action.hashCode);
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, fieldErrors.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, retryAfterSeconds.hashCode);
    _$hash = $jc(_$hash, retryable.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ErrorDetail')
          ..add('action', action)
          ..add('code', code)
          ..add('fieldErrors', fieldErrors)
          ..add('message', message)
          ..add('requestId', requestId)
          ..add('retryAfterSeconds', retryAfterSeconds)
          ..add('retryable', retryable))
        .toString();
  }
}

class ErrorDetailBuilder implements Builder<ErrorDetail, ErrorDetailBuilder> {
  _$ErrorDetail? _$v;

  String? _action;
  String? get action => _$this._action;
  set action(String? action) => _$this._action = action;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  ListBuilder<FieldError>? _fieldErrors;
  ListBuilder<FieldError> get fieldErrors =>
      _$this._fieldErrors ??= ListBuilder<FieldError>();
  set fieldErrors(ListBuilder<FieldError>? fieldErrors) =>
      _$this._fieldErrors = fieldErrors;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  int? _retryAfterSeconds;
  int? get retryAfterSeconds => _$this._retryAfterSeconds;
  set retryAfterSeconds(int? retryAfterSeconds) =>
      _$this._retryAfterSeconds = retryAfterSeconds;

  bool? _retryable;
  bool? get retryable => _$this._retryable;
  set retryable(bool? retryable) => _$this._retryable = retryable;

  ErrorDetailBuilder() {
    ErrorDetail._defaults(this);
  }

  ErrorDetailBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _action = $v.action;
      _code = $v.code;
      _fieldErrors = $v.fieldErrors.toBuilder();
      _message = $v.message;
      _requestId = $v.requestId;
      _retryAfterSeconds = $v.retryAfterSeconds;
      _retryable = $v.retryable;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ErrorDetail other) {
    _$v = other as _$ErrorDetail;
  }

  @override
  void update(void Function(ErrorDetailBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ErrorDetail build() => _build();

  _$ErrorDetail _build() {
    _$ErrorDetail _$result;
    try {
      _$result = _$v ??
          _$ErrorDetail._(
            action: action,
            code: BuiltValueNullFieldError.checkNotNull(
                code, r'ErrorDetail', 'code'),
            fieldErrors: fieldErrors.build(),
            message: BuiltValueNullFieldError.checkNotNull(
                message, r'ErrorDetail', 'message'),
            requestId: BuiltValueNullFieldError.checkNotNull(
                requestId, r'ErrorDetail', 'requestId'),
            retryAfterSeconds: retryAfterSeconds,
            retryable: BuiltValueNullFieldError.checkNotNull(
                retryable, r'ErrorDetail', 'retryable'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'fieldErrors';
        fieldErrors.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ErrorDetail', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
