//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'upload_grant_request.g.dart';

/// UploadGrantRequest
///
/// Properties:
/// * [byteSize] 
/// * [contentSha256] 
/// * [declaredMediaType] 
/// * [declaredName] 
@BuiltValue()
abstract class UploadGrantRequest implements Built<UploadGrantRequest, UploadGrantRequestBuilder> {
  @BuiltValueField(wireName: r'byte_size')
  int get byteSize;

  @BuiltValueField(wireName: r'content_sha256')
  String get contentSha256;

  @BuiltValueField(wireName: r'declared_media_type')
  String get declaredMediaType;

  @BuiltValueField(wireName: r'declared_name')
  String get declaredName;

  UploadGrantRequest._();

  factory UploadGrantRequest([void updates(UploadGrantRequestBuilder b)]) = _$UploadGrantRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UploadGrantRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UploadGrantRequest> get serializer => _$UploadGrantRequestSerializer();
}

class _$UploadGrantRequestSerializer implements PrimitiveSerializer<UploadGrantRequest> {
  @override
  final Iterable<Type> types = const [UploadGrantRequest, _$UploadGrantRequest];

  @override
  final String wireName = r'UploadGrantRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UploadGrantRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'byte_size';
    yield serializers.serialize(
      object.byteSize,
      specifiedType: const FullType(int),
    );
    yield r'content_sha256';
    yield serializers.serialize(
      object.contentSha256,
      specifiedType: const FullType(String),
    );
    yield r'declared_media_type';
    yield serializers.serialize(
      object.declaredMediaType,
      specifiedType: const FullType(String),
    );
    yield r'declared_name';
    yield serializers.serialize(
      object.declaredName,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UploadGrantRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UploadGrantRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'byte_size':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.byteSize = valueDes;
          break;
        case r'content_sha256':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.contentSha256 = valueDes;
          break;
        case r'declared_media_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.declaredMediaType = valueDes;
          break;
        case r'declared_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.declaredName = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UploadGrantRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UploadGrantRequestBuilder();
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


