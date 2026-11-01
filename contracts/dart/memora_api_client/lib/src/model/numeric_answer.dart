//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/value.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'numeric_answer.g.dart';

/// NumericAnswer
///
/// Properties:
/// * [type]
/// * [unit]
/// * [value]
@BuiltValue()
abstract class NumericAnswer
    implements Built<NumericAnswer, NumericAnswerBuilder> {
  @BuiltValueField(wireName: r'type')
  NumericAnswerTypeEnum get type;
  // enum typeEnum {  numeric,  };

  @BuiltValueField(wireName: r'unit')
  Optional<String?> get unit;

  @BuiltValueField(wireName: r'value')
  Value get value;

  NumericAnswer._();

  factory NumericAnswer([void updates(NumericAnswerBuilder b)]) =
      _$NumericAnswer;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NumericAnswerBuilder b) => b..unit = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<NumericAnswer> get serializer =>
      _$NumericAnswerSerializer();
}

class _$NumericAnswerSerializer implements PrimitiveSerializer<NumericAnswer> {
  @override
  final Iterable<Type> types = const [NumericAnswer, _$NumericAnswer];

  @override
  final String wireName = r'NumericAnswer';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NumericAnswer object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(NumericAnswerTypeEnum),
    );
    if (object.unit.isPresent) {
      yield r'unit';
      final optionalValue = object.unit.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    yield r'value';
    yield serializers.serialize(
      object.value,
      specifiedType: const FullType(Value),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NumericAnswer object, {
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
    required NumericAnswerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(NumericAnswerTypeEnum),
          ) as NumericAnswerTypeEnum;
          result.type = valueDes;
          break;
        case r'unit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.unit = Optional.present(valueDes);
          break;
        case r'value':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Value),
          ) as Value;
          result.value.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NumericAnswer deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NumericAnswerBuilder();
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

class NumericAnswerTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'numeric')
  static const NumericAnswerTypeEnum numeric = _$numericAnswerTypeEnum_numeric;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const NumericAnswerTypeEnum unknownDefaultOpenApi =
      _$numericAnswerTypeEnum_unknownDefaultOpenApi;

  static Serializer<NumericAnswerTypeEnum> get serializer =>
      _$numericAnswerTypeEnumSerializer;

  const NumericAnswerTypeEnum._(String name) : super(name);

  static BuiltSet<NumericAnswerTypeEnum> get values =>
      _$numericAnswerTypeEnumValues;
  static NumericAnswerTypeEnum valueOf(String name) =>
      _$numericAnswerTypeEnumValueOf(name);
}
