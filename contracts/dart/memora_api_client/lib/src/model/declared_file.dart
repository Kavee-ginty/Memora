//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'declared_file.g.dart';

/// DeclaredFile
///
/// Properties:
/// * [byteSize]
/// * [contentSha256]
/// * [declaredMediaType]
/// * [declaredName]
@BuiltValue()
abstract class DeclaredFile
    implements Built<DeclaredFile, DeclaredFileBuilder> {
  @BuiltValueField(wireName: r'byte_size')
  int get byteSize;

  @BuiltValueField(wireName: r'content_sha256')
  String get contentSha256;

  @BuiltValueField(wireName: r'declared_media_type')
  String get declaredMediaType;

  @BuiltValueField(wireName: r'declared_name')
  String get declaredName;

  DeclaredFile._();

  factory DeclaredFile([void updates(DeclaredFileBuilder b)]) = _$DeclaredFile;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeclaredFileBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeclaredFile> get serializer => _$DeclaredFileSerializer();
}

class _$DeclaredFileSerializer implements PrimitiveSerializer<DeclaredFile> {
  @override
  final Iterable<Type> types = const [DeclaredFile, _$DeclaredFile];

  @override
  final String wireName = r'DeclaredFile';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeclaredFile object, {
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
    DeclaredFile object, {
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
    required DeclaredFileBuilder result,
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
  DeclaredFile deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeclaredFileBuilder();
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
