//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'page_meta.g.dart';

/// PageMeta
///
/// Properties:
/// * [hasMore]
/// * [nextCursor]
@BuiltValue()
abstract class PageMeta implements Built<PageMeta, PageMetaBuilder> {
  @BuiltValueField(wireName: r'has_more')
  bool get hasMore;

  @BuiltValueField(wireName: r'next_cursor')
  String? get nextCursor;

  PageMeta._();

  factory PageMeta([void updates(PageMetaBuilder b)]) = _$PageMeta;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PageMetaBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PageMeta> get serializer => _$PageMetaSerializer();
}

class _$PageMetaSerializer implements PrimitiveSerializer<PageMeta> {
  @override
  final Iterable<Type> types = const [PageMeta, _$PageMeta];

  @override
  final String wireName = r'PageMeta';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PageMeta object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'has_more';
    yield serializers.serialize(
      object.hasMore,
      specifiedType: const FullType(bool),
    );
    yield r'next_cursor';
    yield object.nextCursor == null
        ? null
        : serializers.serialize(
            object.nextCursor,
            specifiedType: const FullType.nullable(String),
          );
  }

  @override
  Object serialize(
    Serializers serializers,
    PageMeta object, {
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
    required PageMetaBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'has_more':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.hasMore = valueDes;
          break;
        case r'next_cursor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.nextCursor = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PageMeta deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PageMetaBuilder();
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
