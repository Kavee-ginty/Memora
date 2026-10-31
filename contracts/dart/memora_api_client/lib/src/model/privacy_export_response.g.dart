// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_export_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PrivacyExportResponseRequestTypeEnum
    _$privacyExportResponseRequestTypeEnum_export_ =
    const PrivacyExportResponseRequestTypeEnum._('export_');
const PrivacyExportResponseRequestTypeEnum
    _$privacyExportResponseRequestTypeEnum_unknownDefaultOpenApi =
    const PrivacyExportResponseRequestTypeEnum._('unknownDefaultOpenApi');

PrivacyExportResponseRequestTypeEnum
    _$privacyExportResponseRequestTypeEnumValueOf(String name) {
  switch (name) {
    case 'export_':
      return _$privacyExportResponseRequestTypeEnum_export_;
    case 'unknownDefaultOpenApi':
      return _$privacyExportResponseRequestTypeEnum_unknownDefaultOpenApi;
    default:
      return _$privacyExportResponseRequestTypeEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<PrivacyExportResponseRequestTypeEnum>
    _$privacyExportResponseRequestTypeEnumValues = BuiltSet<
        PrivacyExportResponseRequestTypeEnum>(const <PrivacyExportResponseRequestTypeEnum>[
  _$privacyExportResponseRequestTypeEnum_export_,
  _$privacyExportResponseRequestTypeEnum_unknownDefaultOpenApi,
]);

const PrivacyExportResponseStatusEnum
    _$privacyExportResponseStatusEnum_requested =
    const PrivacyExportResponseStatusEnum._('requested');
const PrivacyExportResponseStatusEnum
    _$privacyExportResponseStatusEnum_verifying =
    const PrivacyExportResponseStatusEnum._('verifying');
const PrivacyExportResponseStatusEnum
    _$privacyExportResponseStatusEnum_processing =
    const PrivacyExportResponseStatusEnum._('processing');
const PrivacyExportResponseStatusEnum
    _$privacyExportResponseStatusEnum_completed =
    const PrivacyExportResponseStatusEnum._('completed');
const PrivacyExportResponseStatusEnum _$privacyExportResponseStatusEnum_failed =
    const PrivacyExportResponseStatusEnum._('failed');
const PrivacyExportResponseStatusEnum
    _$privacyExportResponseStatusEnum_cancelled =
    const PrivacyExportResponseStatusEnum._('cancelled');
const PrivacyExportResponseStatusEnum
    _$privacyExportResponseStatusEnum_unknownDefaultOpenApi =
    const PrivacyExportResponseStatusEnum._('unknownDefaultOpenApi');

PrivacyExportResponseStatusEnum _$privacyExportResponseStatusEnumValueOf(
    String name) {
  switch (name) {
    case 'requested':
      return _$privacyExportResponseStatusEnum_requested;
    case 'verifying':
      return _$privacyExportResponseStatusEnum_verifying;
    case 'processing':
      return _$privacyExportResponseStatusEnum_processing;
    case 'completed':
      return _$privacyExportResponseStatusEnum_completed;
    case 'failed':
      return _$privacyExportResponseStatusEnum_failed;
    case 'cancelled':
      return _$privacyExportResponseStatusEnum_cancelled;
    case 'unknownDefaultOpenApi':
      return _$privacyExportResponseStatusEnum_unknownDefaultOpenApi;
    default:
      return _$privacyExportResponseStatusEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<PrivacyExportResponseStatusEnum>
    _$privacyExportResponseStatusEnumValues = BuiltSet<
        PrivacyExportResponseStatusEnum>(const <PrivacyExportResponseStatusEnum>[
  _$privacyExportResponseStatusEnum_requested,
  _$privacyExportResponseStatusEnum_verifying,
  _$privacyExportResponseStatusEnum_processing,
  _$privacyExportResponseStatusEnum_completed,
  _$privacyExportResponseStatusEnum_failed,
  _$privacyExportResponseStatusEnum_cancelled,
  _$privacyExportResponseStatusEnum_unknownDefaultOpenApi,
]);

Serializer<PrivacyExportResponseRequestTypeEnum>
    _$privacyExportResponseRequestTypeEnumSerializer =
    _$PrivacyExportResponseRequestTypeEnumSerializer();
Serializer<PrivacyExportResponseStatusEnum>
    _$privacyExportResponseStatusEnumSerializer =
    _$PrivacyExportResponseStatusEnumSerializer();

class _$PrivacyExportResponseRequestTypeEnumSerializer
    implements PrimitiveSerializer<PrivacyExportResponseRequestTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'export_': 'export',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'export': 'export_',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PrivacyExportResponseRequestTypeEnum
  ];
  @override
  final String wireName = 'PrivacyExportResponseRequestTypeEnum';

  @override
  Object serialize(
          Serializers serializers, PrivacyExportResponseRequestTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  PrivacyExportResponseRequestTypeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      PrivacyExportResponseRequestTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$PrivacyExportResponseStatusEnumSerializer
    implements PrimitiveSerializer<PrivacyExportResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'requested': 'requested',
    'verifying': 'verifying',
    'processing': 'processing',
    'completed': 'completed',
    'failed': 'failed',
    'cancelled': 'cancelled',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'requested': 'requested',
    'verifying': 'verifying',
    'processing': 'processing',
    'completed': 'completed',
    'failed': 'failed',
    'cancelled': 'cancelled',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[PrivacyExportResponseStatusEnum];
  @override
  final String wireName = 'PrivacyExportResponseStatusEnum';

  @override
  Object serialize(
          Serializers serializers, PrivacyExportResponseStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  PrivacyExportResponseStatusEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      PrivacyExportResponseStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$PrivacyExportResponse extends PrivacyExportResponse {
  @override
  final Optional<String?> completedAt;
  @override
  final Optional<String?> downloadExpiresAt;
  @override
  final Optional<String?> downloadUrl;
  @override
  final Optional<String?> failureCode;
  @override
  final String id;
  @override
  final Optional<PrivacyExportResponseRequestTypeEnum?> requestType;
  @override
  final String requestedAt;
  @override
  final PrivacyExportResponseStatusEnum status;

  factory _$PrivacyExportResponse(
          [void Function(PrivacyExportResponseBuilder)? updates]) =>
      (PrivacyExportResponseBuilder()..update(updates))._build();

  _$PrivacyExportResponse._(
      {required this.completedAt,
      required this.downloadExpiresAt,
      required this.downloadUrl,
      required this.failureCode,
      required this.id,
      required this.requestType,
      required this.requestedAt,
      required this.status})
      : super._();
  @override
  PrivacyExportResponse rebuild(
          void Function(PrivacyExportResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PrivacyExportResponseBuilder toBuilder() =>
      PrivacyExportResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PrivacyExportResponse &&
        completedAt == other.completedAt &&
        downloadExpiresAt == other.downloadExpiresAt &&
        downloadUrl == other.downloadUrl &&
        failureCode == other.failureCode &&
        id == other.id &&
        requestType == other.requestType &&
        requestedAt == other.requestedAt &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, completedAt.hashCode);
    _$hash = $jc(_$hash, downloadExpiresAt.hashCode);
    _$hash = $jc(_$hash, downloadUrl.hashCode);
    _$hash = $jc(_$hash, failureCode.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, requestType.hashCode);
    _$hash = $jc(_$hash, requestedAt.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PrivacyExportResponse')
          ..add('completedAt', completedAt)
          ..add('downloadExpiresAt', downloadExpiresAt)
          ..add('downloadUrl', downloadUrl)
          ..add('failureCode', failureCode)
          ..add('id', id)
          ..add('requestType', requestType)
          ..add('requestedAt', requestedAt)
          ..add('status', status))
        .toString();
  }
}

class PrivacyExportResponseBuilder
    implements Builder<PrivacyExportResponse, PrivacyExportResponseBuilder> {
  _$PrivacyExportResponse? _$v;

  Optional<String?>? _completedAt;
  Optional<String?>? get completedAt => _$this._completedAt;
  set completedAt(Optional<String?>? completedAt) =>
      _$this._completedAt = completedAt;

  Optional<String?>? _downloadExpiresAt;
  Optional<String?>? get downloadExpiresAt => _$this._downloadExpiresAt;
  set downloadExpiresAt(Optional<String?>? downloadExpiresAt) =>
      _$this._downloadExpiresAt = downloadExpiresAt;

  Optional<String?>? _downloadUrl;
  Optional<String?>? get downloadUrl => _$this._downloadUrl;
  set downloadUrl(Optional<String?>? downloadUrl) =>
      _$this._downloadUrl = downloadUrl;

  Optional<String?>? _failureCode;
  Optional<String?>? get failureCode => _$this._failureCode;
  set failureCode(Optional<String?>? failureCode) =>
      _$this._failureCode = failureCode;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  Optional<PrivacyExportResponseRequestTypeEnum?>? _requestType;
  Optional<PrivacyExportResponseRequestTypeEnum?>? get requestType =>
      _$this._requestType;
  set requestType(
          Optional<PrivacyExportResponseRequestTypeEnum?>? requestType) =>
      _$this._requestType = requestType;

  String? _requestedAt;
  String? get requestedAt => _$this._requestedAt;
  set requestedAt(String? requestedAt) => _$this._requestedAt = requestedAt;

  PrivacyExportResponseStatusEnum? _status;
  PrivacyExportResponseStatusEnum? get status => _$this._status;
  set status(PrivacyExportResponseStatusEnum? status) =>
      _$this._status = status;

  PrivacyExportResponseBuilder() {
    PrivacyExportResponse._defaults(this);
  }

  PrivacyExportResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _completedAt = $v.completedAt;
      _downloadExpiresAt = $v.downloadExpiresAt;
      _downloadUrl = $v.downloadUrl;
      _failureCode = $v.failureCode;
      _id = $v.id;
      _requestType = $v.requestType;
      _requestedAt = $v.requestedAt;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PrivacyExportResponse other) {
    _$v = other as _$PrivacyExportResponse;
  }

  @override
  void update(void Function(PrivacyExportResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PrivacyExportResponse build() => _build();

  _$PrivacyExportResponse _build() {
    final _$result = _$v ??
        _$PrivacyExportResponse._(
          completedAt: BuiltValueNullFieldError.checkNotNull(
              completedAt, r'PrivacyExportResponse', 'completedAt'),
          downloadExpiresAt: BuiltValueNullFieldError.checkNotNull(
              downloadExpiresAt, r'PrivacyExportResponse', 'downloadExpiresAt'),
          downloadUrl: BuiltValueNullFieldError.checkNotNull(
              downloadUrl, r'PrivacyExportResponse', 'downloadUrl'),
          failureCode: BuiltValueNullFieldError.checkNotNull(
              failureCode, r'PrivacyExportResponse', 'failureCode'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'PrivacyExportResponse', 'id'),
          requestType: BuiltValueNullFieldError.checkNotNull(
              requestType, r'PrivacyExportResponse', 'requestType'),
          requestedAt: BuiltValueNullFieldError.checkNotNull(
              requestedAt, r'PrivacyExportResponse', 'requestedAt'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'PrivacyExportResponse', 'status'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
