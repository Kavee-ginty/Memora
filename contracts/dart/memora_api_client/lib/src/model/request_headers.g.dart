// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_headers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RequestHeadersXPlatformEnum _$requestHeadersXPlatformEnum_android =
    const RequestHeadersXPlatformEnum._('android');
const RequestHeadersXPlatformEnum _$requestHeadersXPlatformEnum_ios =
    const RequestHeadersXPlatformEnum._('ios');
const RequestHeadersXPlatformEnum
    _$requestHeadersXPlatformEnum_unknownDefaultOpenApi =
    const RequestHeadersXPlatformEnum._('unknownDefaultOpenApi');

RequestHeadersXPlatformEnum _$requestHeadersXPlatformEnumValueOf(String name) {
  switch (name) {
    case 'android':
      return _$requestHeadersXPlatformEnum_android;
    case 'ios':
      return _$requestHeadersXPlatformEnum_ios;
    case 'unknownDefaultOpenApi':
      return _$requestHeadersXPlatformEnum_unknownDefaultOpenApi;
    default:
      return _$requestHeadersXPlatformEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<RequestHeadersXPlatformEnum>
    _$requestHeadersXPlatformEnumValues =
    BuiltSet<RequestHeadersXPlatformEnum>(const <RequestHeadersXPlatformEnum>[
  _$requestHeadersXPlatformEnum_android,
  _$requestHeadersXPlatformEnum_ios,
  _$requestHeadersXPlatformEnum_unknownDefaultOpenApi,
]);

Serializer<RequestHeadersXPlatformEnum>
    _$requestHeadersXPlatformEnumSerializer =
    _$RequestHeadersXPlatformEnumSerializer();

class _$RequestHeadersXPlatformEnumSerializer
    implements PrimitiveSerializer<RequestHeadersXPlatformEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'android': 'android',
    'ios': 'ios',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'android': 'android',
    'ios': 'ios',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[RequestHeadersXPlatformEnum];
  @override
  final String wireName = 'RequestHeadersXPlatformEnum';

  @override
  Object serialize(Serializers serializers, RequestHeadersXPlatformEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  RequestHeadersXPlatformEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      RequestHeadersXPlatformEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$RequestHeaders extends RequestHeaders {
  @override
  final Optional<String?> acceptLanguage;
  @override
  final String xClientVersion;
  @override
  final String xCorrelationID;
  @override
  final RequestHeadersXPlatformEnum xPlatform;

  factory _$RequestHeaders([void Function(RequestHeadersBuilder)? updates]) =>
      (RequestHeadersBuilder()..update(updates))._build();

  _$RequestHeaders._(
      {required this.acceptLanguage,
      required this.xClientVersion,
      required this.xCorrelationID,
      required this.xPlatform})
      : super._();
  @override
  RequestHeaders rebuild(void Function(RequestHeadersBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RequestHeadersBuilder toBuilder() => RequestHeadersBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RequestHeaders &&
        acceptLanguage == other.acceptLanguage &&
        xClientVersion == other.xClientVersion &&
        xCorrelationID == other.xCorrelationID &&
        xPlatform == other.xPlatform;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, acceptLanguage.hashCode);
    _$hash = $jc(_$hash, xClientVersion.hashCode);
    _$hash = $jc(_$hash, xCorrelationID.hashCode);
    _$hash = $jc(_$hash, xPlatform.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RequestHeaders')
          ..add('acceptLanguage', acceptLanguage)
          ..add('xClientVersion', xClientVersion)
          ..add('xCorrelationID', xCorrelationID)
          ..add('xPlatform', xPlatform))
        .toString();
  }
}

class RequestHeadersBuilder
    implements Builder<RequestHeaders, RequestHeadersBuilder> {
  _$RequestHeaders? _$v;

  Optional<String?>? _acceptLanguage;
  Optional<String?>? get acceptLanguage => _$this._acceptLanguage;
  set acceptLanguage(Optional<String?>? acceptLanguage) =>
      _$this._acceptLanguage = acceptLanguage;

  String? _xClientVersion;
  String? get xClientVersion => _$this._xClientVersion;
  set xClientVersion(String? xClientVersion) =>
      _$this._xClientVersion = xClientVersion;

  String? _xCorrelationID;
  String? get xCorrelationID => _$this._xCorrelationID;
  set xCorrelationID(String? xCorrelationID) =>
      _$this._xCorrelationID = xCorrelationID;

  RequestHeadersXPlatformEnum? _xPlatform;
  RequestHeadersXPlatformEnum? get xPlatform => _$this._xPlatform;
  set xPlatform(RequestHeadersXPlatformEnum? xPlatform) =>
      _$this._xPlatform = xPlatform;

  RequestHeadersBuilder() {
    RequestHeaders._defaults(this);
  }

  RequestHeadersBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _acceptLanguage = $v.acceptLanguage;
      _xClientVersion = $v.xClientVersion;
      _xCorrelationID = $v.xCorrelationID;
      _xPlatform = $v.xPlatform;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RequestHeaders other) {
    _$v = other as _$RequestHeaders;
  }

  @override
  void update(void Function(RequestHeadersBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RequestHeaders build() => _build();

  _$RequestHeaders _build() {
    final _$result = _$v ??
        _$RequestHeaders._(
          acceptLanguage: BuiltValueNullFieldError.checkNotNull(
              acceptLanguage, r'RequestHeaders', 'acceptLanguage'),
          xClientVersion: BuiltValueNullFieldError.checkNotNull(
              xClientVersion, r'RequestHeaders', 'xClientVersion'),
          xCorrelationID: BuiltValueNullFieldError.checkNotNull(
              xCorrelationID, r'RequestHeaders', 'xCorrelationID'),
          xPlatform: BuiltValueNullFieldError.checkNotNull(
              xPlatform, r'RequestHeaders', 'xPlatform'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
