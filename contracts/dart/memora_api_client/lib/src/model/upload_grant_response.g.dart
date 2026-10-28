// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_grant_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UploadGrantResponseMethodEnum _$uploadGrantResponseMethodEnum_PUT =
    const UploadGrantResponseMethodEnum._('PUT');
const UploadGrantResponseMethodEnum
    _$uploadGrantResponseMethodEnum_unknownDefaultOpenApi =
    const UploadGrantResponseMethodEnum._('unknownDefaultOpenApi');

UploadGrantResponseMethodEnum _$uploadGrantResponseMethodEnumValueOf(
    String name) {
  switch (name) {
    case 'PUT':
      return _$uploadGrantResponseMethodEnum_PUT;
    case 'unknownDefaultOpenApi':
      return _$uploadGrantResponseMethodEnum_unknownDefaultOpenApi;
    default:
      return _$uploadGrantResponseMethodEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UploadGrantResponseMethodEnum>
    _$uploadGrantResponseMethodEnumValues = BuiltSet<
        UploadGrantResponseMethodEnum>(const <UploadGrantResponseMethodEnum>[
  _$uploadGrantResponseMethodEnum_PUT,
  _$uploadGrantResponseMethodEnum_unknownDefaultOpenApi,
]);

Serializer<UploadGrantResponseMethodEnum>
    _$uploadGrantResponseMethodEnumSerializer =
    _$UploadGrantResponseMethodEnumSerializer();

class _$UploadGrantResponseMethodEnumSerializer
    implements PrimitiveSerializer<UploadGrantResponseMethodEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PUT': 'PUT',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PUT': 'PUT',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[UploadGrantResponseMethodEnum];
  @override
  final String wireName = 'UploadGrantResponseMethodEnum';

  @override
  Object serialize(
          Serializers serializers, UploadGrantResponseMethodEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UploadGrantResponseMethodEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UploadGrantResponseMethodEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UploadGrantResponse extends UploadGrantResponse {
  @override
  final String checksumRule;
  @override
  final String expiresAt;
  @override
  final int maxBytes;
  @override
  final Optional<UploadGrantResponseMethodEnum?> method;
  @override
  final BuiltMap<String, String> requiredHeaders;
  @override
  final String uploadId;
  @override
  final String url;

  factory _$UploadGrantResponse(
          [void Function(UploadGrantResponseBuilder)? updates]) =>
      (UploadGrantResponseBuilder()..update(updates))._build();

  _$UploadGrantResponse._(
      {required this.checksumRule,
      required this.expiresAt,
      required this.maxBytes,
      required this.method,
      required this.requiredHeaders,
      required this.uploadId,
      required this.url})
      : super._();
  @override
  UploadGrantResponse rebuild(
          void Function(UploadGrantResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UploadGrantResponseBuilder toBuilder() =>
      UploadGrantResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UploadGrantResponse &&
        checksumRule == other.checksumRule &&
        expiresAt == other.expiresAt &&
        maxBytes == other.maxBytes &&
        method == other.method &&
        requiredHeaders == other.requiredHeaders &&
        uploadId == other.uploadId &&
        url == other.url;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, checksumRule.hashCode);
    _$hash = $jc(_$hash, expiresAt.hashCode);
    _$hash = $jc(_$hash, maxBytes.hashCode);
    _$hash = $jc(_$hash, method.hashCode);
    _$hash = $jc(_$hash, requiredHeaders.hashCode);
    _$hash = $jc(_$hash, uploadId.hashCode);
    _$hash = $jc(_$hash, url.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UploadGrantResponse')
          ..add('checksumRule', checksumRule)
          ..add('expiresAt', expiresAt)
          ..add('maxBytes', maxBytes)
          ..add('method', method)
          ..add('requiredHeaders', requiredHeaders)
          ..add('uploadId', uploadId)
          ..add('url', url))
        .toString();
  }
}

class UploadGrantResponseBuilder
    implements Builder<UploadGrantResponse, UploadGrantResponseBuilder> {
  _$UploadGrantResponse? _$v;

  String? _checksumRule;
  String? get checksumRule => _$this._checksumRule;
  set checksumRule(String? checksumRule) => _$this._checksumRule = checksumRule;

  String? _expiresAt;
  String? get expiresAt => _$this._expiresAt;
  set expiresAt(String? expiresAt) => _$this._expiresAt = expiresAt;

  int? _maxBytes;
  int? get maxBytes => _$this._maxBytes;
  set maxBytes(int? maxBytes) => _$this._maxBytes = maxBytes;

  Optional<UploadGrantResponseMethodEnum?>? _method;
  Optional<UploadGrantResponseMethodEnum?>? get method => _$this._method;
  set method(Optional<UploadGrantResponseMethodEnum?>? method) =>
      _$this._method = method;

  MapBuilder<String, String>? _requiredHeaders;
  MapBuilder<String, String> get requiredHeaders =>
      _$this._requiredHeaders ??= MapBuilder<String, String>();
  set requiredHeaders(MapBuilder<String, String>? requiredHeaders) =>
      _$this._requiredHeaders = requiredHeaders;

  String? _uploadId;
  String? get uploadId => _$this._uploadId;
  set uploadId(String? uploadId) => _$this._uploadId = uploadId;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  UploadGrantResponseBuilder() {
    UploadGrantResponse._defaults(this);
  }

  UploadGrantResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _checksumRule = $v.checksumRule;
      _expiresAt = $v.expiresAt;
      _maxBytes = $v.maxBytes;
      _method = $v.method;
      _requiredHeaders = $v.requiredHeaders.toBuilder();
      _uploadId = $v.uploadId;
      _url = $v.url;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UploadGrantResponse other) {
    _$v = other as _$UploadGrantResponse;
  }

  @override
  void update(void Function(UploadGrantResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UploadGrantResponse build() => _build();

  _$UploadGrantResponse _build() {
    _$UploadGrantResponse _$result;
    try {
      _$result = _$v ??
          _$UploadGrantResponse._(
            checksumRule: BuiltValueNullFieldError.checkNotNull(
                checksumRule, r'UploadGrantResponse', 'checksumRule'),
            expiresAt: BuiltValueNullFieldError.checkNotNull(
                expiresAt, r'UploadGrantResponse', 'expiresAt'),
            maxBytes: BuiltValueNullFieldError.checkNotNull(
                maxBytes, r'UploadGrantResponse', 'maxBytes'),
            method: BuiltValueNullFieldError.checkNotNull(
                method, r'UploadGrantResponse', 'method'),
            requiredHeaders: requiredHeaders.build(),
            uploadId: BuiltValueNullFieldError.checkNotNull(
                uploadId, r'UploadGrantResponse', 'uploadId'),
            url: BuiltValueNullFieldError.checkNotNull(
                url, r'UploadGrantResponse', 'url'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'requiredHeaders';
        requiredHeaders.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UploadGrantResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
