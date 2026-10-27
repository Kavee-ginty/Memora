// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_registration_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DeviceRegistrationRequestPlatformEnum
    _$deviceRegistrationRequestPlatformEnum_android =
    const DeviceRegistrationRequestPlatformEnum._('android');
const DeviceRegistrationRequestPlatformEnum
    _$deviceRegistrationRequestPlatformEnum_ios =
    const DeviceRegistrationRequestPlatformEnum._('ios');
const DeviceRegistrationRequestPlatformEnum
    _$deviceRegistrationRequestPlatformEnum_unknownDefaultOpenApi =
    const DeviceRegistrationRequestPlatformEnum._('unknownDefaultOpenApi');

DeviceRegistrationRequestPlatformEnum
    _$deviceRegistrationRequestPlatformEnumValueOf(String name) {
  switch (name) {
    case 'android':
      return _$deviceRegistrationRequestPlatformEnum_android;
    case 'ios':
      return _$deviceRegistrationRequestPlatformEnum_ios;
    case 'unknownDefaultOpenApi':
      return _$deviceRegistrationRequestPlatformEnum_unknownDefaultOpenApi;
    default:
      return _$deviceRegistrationRequestPlatformEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<DeviceRegistrationRequestPlatformEnum>
    _$deviceRegistrationRequestPlatformEnumValues = BuiltSet<
        DeviceRegistrationRequestPlatformEnum>(const <DeviceRegistrationRequestPlatformEnum>[
  _$deviceRegistrationRequestPlatformEnum_android,
  _$deviceRegistrationRequestPlatformEnum_ios,
  _$deviceRegistrationRequestPlatformEnum_unknownDefaultOpenApi,
]);

Serializer<DeviceRegistrationRequestPlatformEnum>
    _$deviceRegistrationRequestPlatformEnumSerializer =
    _$DeviceRegistrationRequestPlatformEnumSerializer();

class _$DeviceRegistrationRequestPlatformEnumSerializer
    implements PrimitiveSerializer<DeviceRegistrationRequestPlatformEnum> {
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
    DeviceRegistrationRequestPlatformEnum
  ];
  @override
  final String wireName = 'DeviceRegistrationRequestPlatformEnum';

  @override
  Object serialize(
          Serializers serializers, DeviceRegistrationRequestPlatformEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  DeviceRegistrationRequestPlatformEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      DeviceRegistrationRequestPlatformEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$DeviceRegistrationRequest extends DeviceRegistrationRequest {
  @override
  final String appVersion;
  @override
  final String installationId;
  @override
  final String locale;
  @override
  final DeviceRegistrationRequestPlatformEnum platform;
  @override
  final String pushToken;
  @override
  final String timezone;

  factory _$DeviceRegistrationRequest(
          [void Function(DeviceRegistrationRequestBuilder)? updates]) =>
      (DeviceRegistrationRequestBuilder()..update(updates))._build();

  _$DeviceRegistrationRequest._(
      {required this.appVersion,
      required this.installationId,
      required this.locale,
      required this.platform,
      required this.pushToken,
      required this.timezone})
      : super._();
  @override
  DeviceRegistrationRequest rebuild(
          void Function(DeviceRegistrationRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeviceRegistrationRequestBuilder toBuilder() =>
      DeviceRegistrationRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeviceRegistrationRequest &&
        appVersion == other.appVersion &&
        installationId == other.installationId &&
        locale == other.locale &&
        platform == other.platform &&
        pushToken == other.pushToken &&
        timezone == other.timezone;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, appVersion.hashCode);
    _$hash = $jc(_$hash, installationId.hashCode);
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, pushToken.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DeviceRegistrationRequest')
          ..add('appVersion', appVersion)
          ..add('installationId', installationId)
          ..add('locale', locale)
          ..add('platform', platform)
          ..add('pushToken', pushToken)
          ..add('timezone', timezone))
        .toString();
  }
}

class DeviceRegistrationRequestBuilder
    implements
        Builder<DeviceRegistrationRequest, DeviceRegistrationRequestBuilder> {
  _$DeviceRegistrationRequest? _$v;

  String? _appVersion;
  String? get appVersion => _$this._appVersion;
  set appVersion(String? appVersion) => _$this._appVersion = appVersion;

  String? _installationId;
  String? get installationId => _$this._installationId;
  set installationId(String? installationId) =>
      _$this._installationId = installationId;

  String? _locale;
  String? get locale => _$this._locale;
  set locale(String? locale) => _$this._locale = locale;

  DeviceRegistrationRequestPlatformEnum? _platform;
  DeviceRegistrationRequestPlatformEnum? get platform => _$this._platform;
  set platform(DeviceRegistrationRequestPlatformEnum? platform) =>
      _$this._platform = platform;

  String? _pushToken;
  String? get pushToken => _$this._pushToken;
  set pushToken(String? pushToken) => _$this._pushToken = pushToken;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(String? timezone) => _$this._timezone = timezone;

  DeviceRegistrationRequestBuilder() {
    DeviceRegistrationRequest._defaults(this);
  }

  DeviceRegistrationRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _appVersion = $v.appVersion;
      _installationId = $v.installationId;
      _locale = $v.locale;
      _platform = $v.platform;
      _pushToken = $v.pushToken;
      _timezone = $v.timezone;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeviceRegistrationRequest other) {
    _$v = other as _$DeviceRegistrationRequest;
  }

  @override
  void update(void Function(DeviceRegistrationRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeviceRegistrationRequest build() => _build();

  _$DeviceRegistrationRequest _build() {
    final _$result = _$v ??
        _$DeviceRegistrationRequest._(
          appVersion: BuiltValueNullFieldError.checkNotNull(
              appVersion, r'DeviceRegistrationRequest', 'appVersion'),
          installationId: BuiltValueNullFieldError.checkNotNull(
              installationId, r'DeviceRegistrationRequest', 'installationId'),
          locale: BuiltValueNullFieldError.checkNotNull(
              locale, r'DeviceRegistrationRequest', 'locale'),
          platform: BuiltValueNullFieldError.checkNotNull(
              platform, r'DeviceRegistrationRequest', 'platform'),
          pushToken: BuiltValueNullFieldError.checkNotNull(
              pushToken, r'DeviceRegistrationRequest', 'pushToken'),
          timezone: BuiltValueNullFieldError.checkNotNull(
              timezone, r'DeviceRegistrationRequest', 'timezone'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
