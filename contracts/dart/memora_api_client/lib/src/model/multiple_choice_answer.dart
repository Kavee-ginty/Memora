//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'multiple_choice_answer.g.dart';

/// MultipleChoiceAnswer
///
/// Properties:
/// * [optionKeys]
/// * [type]
@BuiltValue()
abstract class MultipleChoiceAnswer
    implements Built<MultipleChoiceAnswer, MultipleChoiceAnswerBuilder> {
  @BuiltValueField(wireName: r'option_keys')
  BuiltList<String> get optionKeys;

  @BuiltValueField(wireName: r'type')
  MultipleChoiceAnswerTypeEnum get type;
  // enum typeEnum {  multiple_choice,  };

  MultipleChoiceAnswer._();

  factory MultipleChoiceAnswer([void updates(MultipleChoiceAnswerBuilder b)]) =
      _$MultipleChoiceAnswer;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MultipleChoiceAnswerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MultipleChoiceAnswer> get serializer =>
      _$MultipleChoiceAnswerSerializer();
}

class _$MultipleChoiceAnswerSerializer
    implements PrimitiveSerializer<MultipleChoiceAnswer> {
  @override
  final Iterable<Type> types = const [
    MultipleChoiceAnswer,
    _$MultipleChoiceAnswer
  ];

  @override
  final String wireName = r'MultipleChoiceAnswer';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MultipleChoiceAnswer object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'option_keys';
    yield serializers.serialize(
      object.optionKeys,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(MultipleChoiceAnswerTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MultipleChoiceAnswer object, {
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
    required MultipleChoiceAnswerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'option_keys':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.optionKeys.replace(valueDes);
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MultipleChoiceAnswerTypeEnum),
          ) as MultipleChoiceAnswerTypeEnum;
          result.type = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MultipleChoiceAnswer deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MultipleChoiceAnswerBuilder();
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

class MultipleChoiceAnswerTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'multiple_choice')
  static const MultipleChoiceAnswerTypeEnum multipleChoice =
      _$multipleChoiceAnswerTypeEnum_multipleChoice;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MultipleChoiceAnswerTypeEnum unknownDefaultOpenApi =
      _$multipleChoiceAnswerTypeEnum_unknownDefaultOpenApi;

  static Serializer<MultipleChoiceAnswerTypeEnum> get serializer =>
      _$multipleChoiceAnswerTypeEnumSerializer;

  const MultipleChoiceAnswerTypeEnum._(String name) : super(name);

  static BuiltSet<MultipleChoiceAnswerTypeEnum> get values =>
      _$multipleChoiceAnswerTypeEnumValues;
  static MultipleChoiceAnswerTypeEnum valueOf(String name) =>
      _$multipleChoiceAnswerTypeEnumValueOf(name);
}
