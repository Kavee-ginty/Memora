//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'device_registration_response.g.dart';

/// DeviceRegistrationResponse
///
/// Properties:
/// * [appVersion] 
/// * [id] 
/// * [installationId] 
/// * [lastSeenAt] 
/// * [locale] 
/// * [platform] 
/// * [timezone] 
@BuiltValue()
abstract class DeviceRegistrationResponse implements Built<DeviceRegistrationResponse, DeviceRegistrationResponseBuilder> {
  @BuiltValueField(wireName: r'app_version')
  String get appVersion;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'installation_id')
  String get installationId;

  @BuiltValueField(wireName: r'last_seen_at')
  DateTime get lastSeenAt;

  @BuiltValueField(wireName: r'locale')
  String get locale;

  @BuiltValueField(wireName: r'platform')
  DeviceRegistrationResponsePlatformEnum get platform;
  // enum platformEnum {  android,  ios,  };

  @BuiltValueField(wireName: r'timezone')
  String get timezone;

  DeviceRegistrationResponse._();

  factory DeviceRegistrationResponse([void updates(DeviceRegistrationResponseBuilder b)]) = _$DeviceRegistrationResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeviceRegistrationResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeviceRegistrationResponse> get serializer => _$DeviceRegistrationResponseSerializer();
}

class _$DeviceRegistrationResponseSerializer implements PrimitiveSerializer<DeviceRegistrationResponse> {
  @override
  final Iterable<Type> types = const [DeviceRegistrationResponse, _$DeviceRegistrationResponse];

  @override
  final String wireName = r'DeviceRegistrationResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeviceRegistrationResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'app_version';
    yield serializers.serialize(
      object.appVersion,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'installation_id';
    yield serializers.serialize(
      object.installationId,
      specifiedType: const FullType(String),
    );
    yield r'last_seen_at';
    yield serializers.serialize(
      object.lastSeenAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'locale';
    yield serializers.serialize(
      object.locale,
      specifiedType: const FullType(String),
    );
    yield r'platform';
    yield serializers.serialize(
      object.platform,
      specifiedType: const FullType(DeviceRegistrationResponsePlatformEnum),
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
    DeviceRegistrationResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DeviceRegistrationResponseBuilder result,
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
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'installation_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.installationId = valueDes;
          break;
        case r'last_seen_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.lastSeenAt = valueDes;
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
            specifiedType: const FullType(DeviceRegistrationResponsePlatformEnum),
          ) as DeviceRegistrationResponsePlatformEnum;
          result.platform = valueDes;
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
  DeviceRegistrationResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeviceRegistrationResponseBuilder();
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


class DeviceRegistrationResponsePlatformEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'android')
  static const DeviceRegistrationResponsePlatformEnum android = _$deviceRegistrationResponsePlatformEnum_android;
  @BuiltValueEnumConst(wireName: r'ios')
  static const DeviceRegistrationResponsePlatformEnum ios = _$deviceRegistrationResponsePlatformEnum_ios;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const DeviceRegistrationResponsePlatformEnum unknownDefaultOpenApi = _$deviceRegistrationResponsePlatformEnum_unknownDefaultOpenApi;

  static Serializer<DeviceRegistrationResponsePlatformEnum> get serializer => _$deviceRegistrationResponsePlatformEnumSerializer;

  const DeviceRegistrationResponsePlatformEnum._(String name): super(name);

  static BuiltSet<DeviceRegistrationResponsePlatformEnum> get values => _$deviceRegistrationResponsePlatformEnumValues;
  static DeviceRegistrationResponsePlatformEnum valueOf(String name) => _$deviceRegistrationResponsePlatformEnumValueOf(name);
}

