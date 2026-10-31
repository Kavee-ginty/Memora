//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'request_headers.g.dart';

/// RequestHeaders
///
/// Properties:
/// * [acceptLanguage] 
/// * [xClientVersion] 
/// * [xCorrelationID] 
/// * [xPlatform] 
@BuiltValue()
abstract class RequestHeaders implements Built<RequestHeaders, RequestHeadersBuilder> {
  @BuiltValueField(wireName: r'Accept-Language')
  Optional<String?> get acceptLanguage;

  @BuiltValueField(wireName: r'X-Client-Version')
  String get xClientVersion;

  @BuiltValueField(wireName: r'X-Correlation-ID')
  String get xCorrelationID;

  @BuiltValueField(wireName: r'X-Platform')
  RequestHeadersXPlatformEnum get xPlatform;
  // enum xPlatformEnum {  android,  ios,  };

  RequestHeaders._();

  factory RequestHeaders([void updates(RequestHeadersBuilder b)]) = _$RequestHeaders;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RequestHeadersBuilder b) => b
      ..acceptLanguage = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<RequestHeaders> get serializer => _$RequestHeadersSerializer();
}

class _$RequestHeadersSerializer implements PrimitiveSerializer<RequestHeaders> {
  @override
  final Iterable<Type> types = const [RequestHeaders, _$RequestHeaders];

  @override
  final String wireName = r'RequestHeaders';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RequestHeaders object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.acceptLanguage.isPresent) {
      yield r'Accept-Language';
      final optionalValue = object.acceptLanguage.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    yield r'X-Client-Version';
    yield serializers.serialize(
      object.xClientVersion,
      specifiedType: const FullType(String),
    );
    yield r'X-Correlation-ID';
    yield serializers.serialize(
      object.xCorrelationID,
      specifiedType: const FullType(String),
    );
    yield r'X-Platform';
    yield serializers.serialize(
      object.xPlatform,
      specifiedType: const FullType(RequestHeadersXPlatformEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RequestHeaders object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RequestHeadersBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'Accept-Language':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.acceptLanguage = Optional.present(valueDes);
          break;
        case r'X-Client-Version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.xClientVersion = valueDes;
          break;
        case r'X-Correlation-ID':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.xCorrelationID = valueDes;
          break;
        case r'X-Platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RequestHeadersXPlatformEnum),
          ) as RequestHeadersXPlatformEnum;
          result.xPlatform = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RequestHeaders deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RequestHeadersBuilder();
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


class RequestHeadersXPlatformEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'android')
  static const RequestHeadersXPlatformEnum android = _$requestHeadersXPlatformEnum_android;
  @BuiltValueEnumConst(wireName: r'ios')
  static const RequestHeadersXPlatformEnum ios = _$requestHeadersXPlatformEnum_ios;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const RequestHeadersXPlatformEnum unknownDefaultOpenApi = _$requestHeadersXPlatformEnum_unknownDefaultOpenApi;

  static Serializer<RequestHeadersXPlatformEnum> get serializer => _$requestHeadersXPlatformEnumSerializer;

  const RequestHeadersXPlatformEnum._(String name): super(name);

  static BuiltSet<RequestHeadersXPlatformEnum> get values => _$requestHeadersXPlatformEnumValues;
  static RequestHeadersXPlatformEnum valueOf(String name) => _$requestHeadersXPlatformEnumValueOf(name);
}

