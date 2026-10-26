// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_registration_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DeviceRegistrationResponsePlatformEnum
    _$deviceRegistrationResponsePlatformEnum_android =
    const DeviceRegistrationResponsePlatformEnum._('android');
const DeviceRegistrationResponsePlatformEnum
    _$deviceRegistrationResponsePlatformEnum_ios =
    const DeviceRegistrationResponsePlatformEnum._('ios');
const DeviceRegistrationResponsePlatformEnum
    _$deviceRegistrationResponsePlatformEnum_unknownDefaultOpenApi =
    const DeviceRegistrationResponsePlatformEnum._('unknownDefaultOpenApi');

DeviceRegistrationResponsePlatformEnum
    _$deviceRegistrationResponsePlatformEnumValueOf(String name) {
  switch (name) {
    case 'android':
      return _$deviceRegistrationResponsePlatformEnum_android;
    case 'ios':
      return _$deviceRegistrationResponsePlatformEnum_ios;
    case 'unknownDefaultOpenApi':
      return _$deviceRegistrationResponsePlatformEnum_unknownDefaultOpenApi;
    default:
      return _$deviceRegistrationResponsePlatformEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<DeviceRegistrationResponsePlatformEnum>
    _$deviceRegistrationResponsePlatformEnumValues = BuiltSet<
        DeviceRegistrationResponsePlatformEnum>(const <DeviceRegistrationResponsePlatformEnum>[
  _$deviceRegistrationResponsePlatformEnum_android,
  _$deviceRegistrationResponsePlatformEnum_ios,
  _$deviceRegistrationResponsePlatformEnum_unknownDefaultOpenApi,
]);

Serializer<DeviceRegistrationResponsePlatformEnum>
    _$deviceRegistrationResponsePlatformEnumSerializer =
    _$DeviceRegistrationResponsePlatformEnumSerializer();

class _$DeviceRegistrationResponsePlatformEnumSerializer
    implements PrimitiveSerializer<DeviceRegistrationResponsePlatformEnum> {
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
  final Iterable<Type> types = const <Type>[
    DeviceRegistrationResponsePlatformEnum
  ];
  @override
  final String wireName = 'DeviceRegistrationResponsePlatformEnum';

  @override
  Object serialize(Serializers serializers,
          DeviceRegistrationResponsePlatformEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  DeviceRegistrationResponsePlatformEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      DeviceRegistrationResponsePlatformEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$DeviceRegistrationResponse extends DeviceRegistrationResponse {
  @override
  final String appVersion;
  @override
  final String id;
  @override
  final String installationId;
  @override
  final DateTime lastSeenAt;
  @override
  final String locale;
  @override
  final DeviceRegistrationResponsePlatformEnum platform;
  @override
  final String timezone;

  factory _$DeviceRegistrationResponse(
          [void Function(DeviceRegistrationResponseBuilder)? updates]) =>
      (DeviceRegistrationResponseBuilder()..update(updates))._build();

  _$DeviceRegistrationResponse._(
      {required this.appVersion,
      required this.id,
      required this.installationId,
      required this.lastSeenAt,
      required this.locale,
      required this.platform,
      required this.timezone})
      : super._();
  @override
  DeviceRegistrationResponse rebuild(
          void Function(DeviceRegistrationResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeviceRegistrationResponseBuilder toBuilder() =>
      DeviceRegistrationResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeviceRegistrationResponse &&
        appVersion == other.appVersion &&
        id == other.id &&
        installationId == other.installationId &&
        lastSeenAt == other.lastSeenAt &&
        locale == other.locale &&
        platform == other.platform &&
        timezone == other.timezone;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, appVersion.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, installationId.hashCode);
    _$hash = $jc(_$hash, lastSeenAt.hashCode);
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DeviceRegistrationResponse')
          ..add('appVersion', appVersion)
          ..add('id', id)
          ..add('installationId', installationId)
          ..add('lastSeenAt', lastSeenAt)
          ..add('locale', locale)
          ..add('platform', platform)
          ..add('timezone', timezone))
        .toString();
  }
}

class DeviceRegistrationResponseBuilder
    implements
        Builder<DeviceRegistrationResponse, DeviceRegistrationResponseBuilder> {
  _$DeviceRegistrationResponse? _$v;

  String? _appVersion;
  String? get appVersion => _$this._appVersion;
  set appVersion(String? appVersion) => _$this._appVersion = appVersion;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _installationId;
  String? get installationId => _$this._installationId;
  set installationId(String? installationId) =>
      _$this._installationId = installationId;

  DateTime? _lastSeenAt;
  DateTime? get lastSeenAt => _$this._lastSeenAt;
  set lastSeenAt(DateTime? lastSeenAt) => _$this._lastSeenAt = lastSeenAt;

  String? _locale;
  String? get locale => _$this._locale;
  set locale(String? locale) => _$this._locale = locale;

  DeviceRegistrationResponsePlatformEnum? _platform;
  DeviceRegistrationResponsePlatformEnum? get platform => _$this._platform;
  set platform(DeviceRegistrationResponsePlatformEnum? platform) =>
      _$this._platform = platform;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(String? timezone) => _$this._timezone = timezone;

  DeviceRegistrationResponseBuilder() {
    DeviceRegistrationResponse._defaults(this);
  }

  DeviceRegistrationResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _appVersion = $v.appVersion;
      _id = $v.id;
      _installationId = $v.installationId;
      _lastSeenAt = $v.lastSeenAt;
      _locale = $v.locale;
      _platform = $v.platform;
      _timezone = $v.timezone;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeviceRegistrationResponse other) {
    _$v = other as _$DeviceRegistrationResponse;
  }

  @override
  void update(void Function(DeviceRegistrationResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeviceRegistrationResponse build() => _build();

  _$DeviceRegistrationResponse _build() {
    final _$result = _$v ??
        _$DeviceRegistrationResponse._(
          appVersion: BuiltValueNullFieldError.checkNotNull(
              appVersion, r'DeviceRegistrationResponse', 'appVersion'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'DeviceRegistrationResponse', 'id'),
          installationId: BuiltValueNullFieldError.checkNotNull(
              installationId, r'DeviceRegistrationResponse', 'installationId'),
          lastSeenAt: BuiltValueNullFieldError.checkNotNull(
              lastSeenAt, r'DeviceRegistrationResponse', 'lastSeenAt'),
          locale: BuiltValueNullFieldError.checkNotNull(
              locale, r'DeviceRegistrationResponse', 'locale'),
          platform: BuiltValueNullFieldError.checkNotNull(
              platform, r'DeviceRegistrationResponse', 'platform'),
          timezone: BuiltValueNullFieldError.checkNotNull(
              timezone, r'DeviceRegistrationResponse', 'timezone'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
