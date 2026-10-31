//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/concept_progress_item.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'page_concept_progress_item.g.dart';

/// PageConceptProgressItem
///
/// Properties:
/// * [hasMore]
/// * [items]
/// * [nextCursor]
@BuiltValue()
abstract class PageConceptProgressItem
    implements Built<PageConceptProgressItem, PageConceptProgressItemBuilder> {
  @BuiltValueField(wireName: r'has_more')
  bool get hasMore;

  @BuiltValueField(wireName: r'items')
  BuiltList<ConceptProgressItem> get items;

  @BuiltValueField(wireName: r'next_cursor')
  String? get nextCursor;

  PageConceptProgressItem._();

  factory PageConceptProgressItem(
          [void updates(PageConceptProgressItemBuilder b)]) =
      _$PageConceptProgressItem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PageConceptProgressItemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PageConceptProgressItem> get serializer =>
      _$PageConceptProgressItemSerializer();
}

class _$PageConceptProgressItemSerializer
    implements PrimitiveSerializer<PageConceptProgressItem> {
  @override
  final Iterable<Type> types = const [
    PageConceptProgressItem,
    _$PageConceptProgressItem
  ];

  @override
  final String wireName = r'PageConceptProgressItem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PageConceptProgressItem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'has_more';
    yield serializers.serialize(
      object.hasMore,
      specifiedType: const FullType(bool),
    );
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(ConceptProgressItem)]),
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
    PageConceptProgressItem object, {
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
    required PageConceptProgressItemBuilder result,
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
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(BuiltList, [FullType(ConceptProgressItem)]),
          ) as BuiltList<ConceptProgressItem>;
          result.items.replace(valueDes);
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
  PageConceptProgressItem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PageConceptProgressItemBuilder();
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
