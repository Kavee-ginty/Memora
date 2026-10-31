//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'page_params.g.dart';

/// PageParams
///
/// Properties:
/// * [cursor] 
/// * [limit] 
@BuiltValue()
abstract class PageParams implements Built<PageParams, PageParamsBuilder> {
  @BuiltValueField(wireName: r'cursor')
  Optional<String?> get cursor;

  @BuiltValueField(wireName: r'limit')
  Optional<int?> get limit;

  PageParams._();

  factory PageParams([void updates(PageParamsBuilder b)]) = _$PageParams;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PageParamsBuilder b) => b
      ..cursor = Optional.absent()
      ..limit = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<PageParams> get serializer => _$PageParamsSerializer();
}

class _$PageParamsSerializer implements PrimitiveSerializer<PageParams> {
  @override
  final Iterable<Type> types = const [PageParams, _$PageParams];

  @override
  final String wireName = r'PageParams';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PageParams object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.cursor.isPresent) {
      yield r'cursor';
      final optionalValue = object.cursor.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    if (object.limit.isPresent) {
      yield r'limit';
      final optionalValue = object.limit.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(int),
        );
      }
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PageParams object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PageParamsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'cursor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.cursor = Optional.present(valueDes);
          break;
        case r'limit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          result.limit = Optional.present(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PageParams deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PageParamsBuilder();
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


