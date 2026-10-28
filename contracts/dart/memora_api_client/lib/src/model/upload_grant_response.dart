//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'upload_grant_response.g.dart';

/// UploadGrantResponse
///
/// Properties:
/// * [checksumRule]
/// * [expiresAt]
/// * [maxBytes]
/// * [method]
/// * [requiredHeaders]
/// * [uploadId]
/// * [url]
@BuiltValue()
abstract class UploadGrantResponse
    implements Built<UploadGrantResponse, UploadGrantResponseBuilder> {
  @BuiltValueField(wireName: r'checksum_rule')
  String get checksumRule;

  @BuiltValueField(wireName: r'expires_at')
  String get expiresAt;

  @BuiltValueField(wireName: r'max_bytes')
  int get maxBytes;

  @BuiltValueField(wireName: r'method')
  Optional<UploadGrantResponseMethodEnum?> get method;
  // enum methodEnum {  PUT,  };

  @BuiltValueField(wireName: r'required_headers')
  BuiltMap<String, String> get requiredHeaders;

  @BuiltValueField(wireName: r'upload_id')
  String get uploadId;

  @BuiltValueField(wireName: r'url')
  String get url;

  UploadGrantResponse._();

  factory UploadGrantResponse([void updates(UploadGrantResponseBuilder b)]) =
      _$UploadGrantResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UploadGrantResponseBuilder b) => b
    ..method = Optional.absent()
    ..requiredHeaders = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<UploadGrantResponse> get serializer =>
      _$UploadGrantResponseSerializer();
}

class _$UploadGrantResponseSerializer
    implements PrimitiveSerializer<UploadGrantResponse> {
  @override
  final Iterable<Type> types = const [
    UploadGrantResponse,
    _$UploadGrantResponse
  ];

  @override
  final String wireName = r'UploadGrantResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UploadGrantResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'checksum_rule';
    yield serializers.serialize(
      object.checksumRule,
      specifiedType: const FullType(String),
    );
    yield r'expires_at';
    yield serializers.serialize(
      object.expiresAt,
      specifiedType: const FullType(String),
    );
    yield r'max_bytes';
    yield serializers.serialize(
      object.maxBytes,
      specifiedType: const FullType(int),
    );
    if (object.method.isPresent) {
      yield r'method';
      final optionalValue = object.method.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    if (object.requiredHeaders.isPresent) {
      yield r'required_headers';
      final optionalValue = object.requiredHeaders.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType:
              const FullType(BuiltMap, [FullType(String), FullType(String)]),
        );
      }
    }
    yield r'upload_id';
    yield serializers.serialize(
      object.uploadId,
      specifiedType: const FullType(String),
    );
    yield r'url';
    yield serializers.serialize(
      object.url,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UploadGrantResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UploadGrantResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'checksum_rule':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.checksumRule = valueDes;
          break;
        case r'expires_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.expiresAt = valueDes;
          break;
        case r'max_bytes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.maxBytes = valueDes;
          break;
        case r'method':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.method = Optional.present(valueDes);
          break;
        case r'required_headers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(BuiltMap, [FullType(String), FullType(String)]),
          ) as BuiltMap<String, String>?;
          result.requiredHeaders = Optional.present(valueDes);
          break;
        case r'upload_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.uploadId = valueDes;
          break;
        case r'url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.url = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UploadGrantResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UploadGrantResponseBuilder();
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

class UploadGrantResponseMethodEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'PUT')
  static const UploadGrantResponseMethodEnum PUT =
      _$uploadGrantResponseMethodEnum_PUT;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UploadGrantResponseMethodEnum unknownDefaultOpenApi =
      _$uploadGrantResponseMethodEnum_unknownDefaultOpenApi;

  static Serializer<UploadGrantResponseMethodEnum> get serializer =>
      _$uploadGrantResponseMethodEnumSerializer;

  const UploadGrantResponseMethodEnum._(String name) : super(name);

  static BuiltSet<UploadGrantResponseMethodEnum> get values =>
      _$uploadGrantResponseMethodEnumValues;
  static UploadGrantResponseMethodEnum valueOf(String name) =>
      _$uploadGrantResponseMethodEnumValueOf(name);
}
