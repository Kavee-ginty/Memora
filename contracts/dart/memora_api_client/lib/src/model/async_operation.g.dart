// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'async_operation.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AsyncOperation extends AsyncOperation {
  @override
  final String resourceId;
  @override
  final int? retryAfterSeconds;
  @override
  final String status;
  @override
  final String statusUrl;
  @override
  final DateTime updatedAt;

  factory _$AsyncOperation([void Function(AsyncOperationBuilder)? updates]) =>
      (AsyncOperationBuilder()..update(updates))._build();

  _$AsyncOperation._(
      {required this.resourceId,
      this.retryAfterSeconds,
      required this.status,
      required this.statusUrl,
      required this.updatedAt})
      : super._();
  @override
  AsyncOperation rebuild(void Function(AsyncOperationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AsyncOperationBuilder toBuilder() => AsyncOperationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AsyncOperation &&
        resourceId == other.resourceId &&
        retryAfterSeconds == other.retryAfterSeconds &&
        status == other.status &&
        statusUrl == other.statusUrl &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, resourceId.hashCode);
    _$hash = $jc(_$hash, retryAfterSeconds.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, statusUrl.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AsyncOperation')
          ..add('resourceId', resourceId)
          ..add('retryAfterSeconds', retryAfterSeconds)
          ..add('status', status)
          ..add('statusUrl', statusUrl)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class AsyncOperationBuilder
    implements Builder<AsyncOperation, AsyncOperationBuilder> {
  _$AsyncOperation? _$v;

  String? _resourceId;
  String? get resourceId => _$this._resourceId;
  set resourceId(String? resourceId) => _$this._resourceId = resourceId;

  int? _retryAfterSeconds;
  int? get retryAfterSeconds => _$this._retryAfterSeconds;
  set retryAfterSeconds(int? retryAfterSeconds) =>
      _$this._retryAfterSeconds = retryAfterSeconds;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _statusUrl;
  String? get statusUrl => _$this._statusUrl;
  set statusUrl(String? statusUrl) => _$this._statusUrl = statusUrl;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  AsyncOperationBuilder() {
    AsyncOperation._defaults(this);
  }

  AsyncOperationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _resourceId = $v.resourceId;
      _retryAfterSeconds = $v.retryAfterSeconds;
      _status = $v.status;
      _statusUrl = $v.statusUrl;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AsyncOperation other) {
    _$v = other as _$AsyncOperation;
  }

  @override
  void update(void Function(AsyncOperationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AsyncOperation build() => _build();

  _$AsyncOperation _build() {
    final _$result = _$v ??
        _$AsyncOperation._(
          resourceId: BuiltValueNullFieldError.checkNotNull(
              resourceId, r'AsyncOperation', 'resourceId'),
          retryAfterSeconds: retryAfterSeconds,
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'AsyncOperation', 'status'),
          statusUrl: BuiltValueNullFieldError.checkNotNull(
              statusUrl, r'AsyncOperation', 'statusUrl'),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt, r'AsyncOperation', 'updatedAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
