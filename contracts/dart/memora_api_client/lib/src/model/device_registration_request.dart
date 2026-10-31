//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'device_registration_request.g.dart';

/// DeviceRegistrationRequest
///
/// Properties:
/// * [appVersion] 
/// * [installationId] 
/// * [locale] 
/// * [platform] 
/// * [pushToken] 
/// * [timezone] 
@BuiltValue()
abstract class DeviceRegistrationRequest implements Built<DeviceRegistrationRequest, DeviceRegistrationRequestBuilder> {
  @BuiltValueField(wireName: r'app_version')
  String get appVersion;

  @BuiltValueField(wireName: r'installation_id')
  String get installationId;

  @BuiltValueField(wireName: r'locale')
  String get locale;

  @BuiltValueField(wireName: r'platform')
  DeviceRegistrationRequestPlatformEnum get platform;
  // enum platformEnum {  android,  ios,  };

  @BuiltValueField(wireName: r'push_token')
  String get pushToken;

  @BuiltValueField(wireName: r'timezone')
  String get timezone;

  DeviceRegistrationRequest._();

  factory DeviceRegistrationRequest([void updates(DeviceRegistrationRequestBuilder b)]) = _$DeviceRegistrationRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeviceRegistrationRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeviceRegistrationRequest> get serializer => _$DeviceRegistrationRequestSerializer();
}

class _$DeviceRegistrationRequestSerializer implements PrimitiveSerializer<DeviceRegistrationRequest> {
  @override
  final Iterable<Type> types = const [DeviceRegistrationRequest, _$DeviceRegistrationRequest];

  @override
  final String wireName = r'DeviceRegistrationRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeviceRegistrationRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'app_version';
    yield serializers.serialize(
      object.appVersion,
      specifiedType: const FullType(String),
    );
    yield r'installation_id';
    yield serializers.serialize(
      object.installationId,
      specifiedType: const FullType(String),
    );
    yield r'locale';
    yield serializers.serialize(
      object.locale,
      specifiedType: const FullType(String),
    );
    yield r'platform';
    yield serializers.serialize(
      object.platform,
      specifiedType: const FullType(DeviceRegistrationRequestPlatformEnum),
    );
    yield r'push_token';
    yield serializers.serialize(
      object.pushToken,
      specifiedType: const FullType(String),
    );
    yield r'timezone';
    yield serializers.serialize(
      object.timezone,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DeviceRegistrationRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DeviceRegistrationRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'app_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.appVersion = valueDes;
          break;
        case r'installation_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.installationId = valueDes;
          break;
        case r'locale':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.locale = valueDes;
          break;
        case r'platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DeviceRegistrationRequestPlatformEnum),
          ) as DeviceRegistrationRequestPlatformEnum;
          result.platform = valueDes;
          break;
        case r'push_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.pushToken = valueDes;
          break;
        case r'timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.timezone = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DeviceRegistrationRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeviceRegistrationRequestBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}


class DeviceRegistrationRequestPlatformEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'android')
  static const DeviceRegistrationRequestPlatformEnum android = _$deviceRegistrationRequestPlatformEnum_android;
  @BuiltValueEnumConst(wireName: r'ios')
  static const DeviceRegistrationRequestPlatformEnum ios = _$deviceRegistrationRequestPlatformEnum_ios;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const DeviceRegistrationRequestPlatformEnum unknownDefaultOpenApi = _$deviceRegistrationRequestPlatformEnum_unknownDefaultOpenApi;

  static Serializer<DeviceRegistrationRequestPlatformEnum> get serializer => _$deviceRegistrationRequestPlatformEnumSerializer;

  const DeviceRegistrationRequestPlatformEnum._(String name): super(name);

  static BuiltSet<DeviceRegistrationRequestPlatformEnum> get values => _$deviceRegistrationRequestPlatformEnumValues;
  static DeviceRegistrationRequestPlatformEnum valueOf(String name) => _$deviceRegistrationRequestPlatformEnumValueOf(name);
}

