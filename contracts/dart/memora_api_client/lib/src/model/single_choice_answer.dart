//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'single_choice_answer.g.dart';

/// SingleChoiceAnswer
///
/// Properties:
/// * [optionKeys]
/// * [type]
@BuiltValue()
abstract class SingleChoiceAnswer
    implements Built<SingleChoiceAnswer, SingleChoiceAnswerBuilder> {
  @BuiltValueField(wireName: r'option_keys')
  BuiltList<String> get optionKeys;

  @BuiltValueField(wireName: r'type')
  SingleChoiceAnswerTypeEnum get type;
  // enum typeEnum {  single_choice,  };

  SingleChoiceAnswer._();

  factory SingleChoiceAnswer([void updates(SingleChoiceAnswerBuilder b)]) =
      _$SingleChoiceAnswer;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SingleChoiceAnswerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SingleChoiceAnswer> get serializer =>
      _$SingleChoiceAnswerSerializer();
}

class _$SingleChoiceAnswerSerializer
    implements PrimitiveSerializer<SingleChoiceAnswer> {
  @override
  final Iterable<Type> types = const [SingleChoiceAnswer, _$SingleChoiceAnswer];

  @override
  final String wireName = r'SingleChoiceAnswer';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SingleChoiceAnswer object, {
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
      specifiedType: const FullType(SingleChoiceAnswerTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SingleChoiceAnswer object, {
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
    required SingleChoiceAnswerBuilder result,
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
            specifiedType: const FullType(SingleChoiceAnswerTypeEnum),
          ) as SingleChoiceAnswerTypeEnum;
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
  SingleChoiceAnswer deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SingleChoiceAnswerBuilder();
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

class SingleChoiceAnswerTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'single_choice')
  static const SingleChoiceAnswerTypeEnum singleChoice =
      _$singleChoiceAnswerTypeEnum_singleChoice;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const SingleChoiceAnswerTypeEnum unknownDefaultOpenApi =
      _$singleChoiceAnswerTypeEnum_unknownDefaultOpenApi;

  static Serializer<SingleChoiceAnswerTypeEnum> get serializer =>
      _$singleChoiceAnswerTypeEnumSerializer;

  const SingleChoiceAnswerTypeEnum._(String name) : super(name);

  static BuiltSet<SingleChoiceAnswerTypeEnum> get values =>
      _$singleChoiceAnswerTypeEnumValues;
  static SingleChoiceAnswerTypeEnum valueOf(String name) =>
      _$singleChoiceAnswerTypeEnumValueOf(name);
}
