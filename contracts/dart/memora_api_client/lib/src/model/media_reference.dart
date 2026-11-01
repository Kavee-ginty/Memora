//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'media_reference.g.dart';

/// Authorized media reference carried by question content.
///
/// Properties:
/// * [altText]
/// * [mediaId]
/// * [mediaType]
@BuiltValue()
abstract class MediaReference
    implements Built<MediaReference, MediaReferenceBuilder> {
  @BuiltValueField(wireName: r'alt_text')
  String get altText;

  @BuiltValueField(wireName: r'media_id')
  String get mediaId;

  @BuiltValueField(wireName: r'media_type')
  MediaReferenceMediaTypeEnum get mediaType;
  // enum mediaTypeEnum {  image,  diagram,  audio,  };

  MediaReference._();

  factory MediaReference([void updates(MediaReferenceBuilder b)]) =
      _$MediaReference;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MediaReferenceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MediaReference> get serializer =>
      _$MediaReferenceSerializer();
}

class _$MediaReferenceSerializer
    implements PrimitiveSerializer<MediaReference> {
  @override
  final Iterable<Type> types = const [MediaReference, _$MediaReference];

  @override
  final String wireName = r'MediaReference';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MediaReference object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'alt_text';
    yield serializers.serialize(
      object.altText,
      specifiedType: const FullType(String),
    );
    yield r'media_id';
    yield serializers.serialize(
      object.mediaId,
      specifiedType: const FullType(String),
    );
    yield r'media_type';
    yield serializers.serialize(
      object.mediaType,
      specifiedType: const FullType(MediaReferenceMediaTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MediaReference object, {
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
    required MediaReferenceBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'alt_text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.altText = valueDes;
          break;
        case r'media_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.mediaId = valueDes;
          break;
        case r'media_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MediaReferenceMediaTypeEnum),
          ) as MediaReferenceMediaTypeEnum;
          result.mediaType = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MediaReference deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MediaReferenceBuilder();
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

class MediaReferenceMediaTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'image')
  static const MediaReferenceMediaTypeEnum image =
      _$mediaReferenceMediaTypeEnum_image;
  @BuiltValueEnumConst(wireName: r'diagram')
  static const MediaReferenceMediaTypeEnum diagram =
      _$mediaReferenceMediaTypeEnum_diagram;
  @BuiltValueEnumConst(wireName: r'audio')
  static const MediaReferenceMediaTypeEnum audio =
      _$mediaReferenceMediaTypeEnum_audio;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MediaReferenceMediaTypeEnum unknownDefaultOpenApi =
      _$mediaReferenceMediaTypeEnum_unknownDefaultOpenApi;

  static Serializer<MediaReferenceMediaTypeEnum> get serializer =>
      _$mediaReferenceMediaTypeEnumSerializer;

  const MediaReferenceMediaTypeEnum._(String name) : super(name);

  static BuiltSet<MediaReferenceMediaTypeEnum> get values =>
      _$mediaReferenceMediaTypeEnumValues;
  static MediaReferenceMediaTypeEnum valueOf(String name) =>
      _$mediaReferenceMediaTypeEnumValueOf(name);
}
