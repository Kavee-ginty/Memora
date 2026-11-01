//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/multiple_choice_answer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/value.dart';
import 'package:memora_api_client/src/model/numeric_answer.dart';
import 'package:memora_api_client/src/model/short_answer_text.dart';
import 'package:memora_api_client/src/model/single_choice_answer.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/one_of.dart';
import 'package:memora_api_client/src/optional.dart';

part 'answer_payload.g.dart';

/// AnswerPayload
///
/// Properties:
/// * [optionKeys]
/// * [type]
/// * [unit]
/// * [value]
/// * [text]
@BuiltValue()
abstract class AnswerPayload
    implements Built<AnswerPayload, AnswerPayloadBuilder> {
  /// One Of [MultipleChoiceAnswer], [NumericAnswer], [ShortAnswerText], [SingleChoiceAnswer]
  OneOf get oneOf;

  static const String discriminatorFieldName = r'type';

  static const Map<String, Type> discriminatorMapping = {
    r'multiple_choice': MultipleChoiceAnswer,
    r'numeric': NumericAnswer,
    r'short_answer': ShortAnswerText,
    r'single_choice': SingleChoiceAnswer,
  };

  AnswerPayload._();

  factory AnswerPayload([void updates(AnswerPayloadBuilder b)]) =
      _$AnswerPayload;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AnswerPayloadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AnswerPayload> get serializer =>
      _$AnswerPayloadSerializer();
}

extension AnswerPayloadDiscriminatorExt on AnswerPayload {
  String? get discriminatorValue {
    if (this is MultipleChoiceAnswer) {
      return r'multiple_choice';
    }
    if (this is NumericAnswer) {
      return r'numeric';
    }
    if (this is ShortAnswerText) {
      return r'short_answer';
    }
    if (this is SingleChoiceAnswer) {
      return r'single_choice';
    }
    return null;
  }
}

extension AnswerPayloadBuilderDiscriminatorExt on AnswerPayloadBuilder {
  String? get discriminatorValue {
    if (this is MultipleChoiceAnswerBuilder) {
      return r'multiple_choice';
    }
    if (this is NumericAnswerBuilder) {
      return r'numeric';
    }
    if (this is ShortAnswerTextBuilder) {
      return r'short_answer';
    }
    if (this is SingleChoiceAnswerBuilder) {
      return r'single_choice';
    }
    return null;
  }
}

class _$AnswerPayloadSerializer implements PrimitiveSerializer<AnswerPayload> {
  @override
  final Iterable<Type> types = const [AnswerPayload, _$AnswerPayload];

  @override
  final String wireName = r'AnswerPayload';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AnswerPayload object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {}

  @override
  Object serialize(
    Serializers serializers,
    AnswerPayload object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(oneOf.value,
        specifiedType: FullType(oneOf.valueType))!;
  }

  @override
  AnswerPayload deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AnswerPayloadBuilder();
    Object? oneOfDataSrc;
    final serializedList = (serialized as Iterable<Object?>).toList();
    final discIndex =
        serializedList.indexOf(AnswerPayload.discriminatorFieldName) + 1;
    final discValue = serializers.deserialize(serializedList[discIndex],
        specifiedType: FullType(String)) as String;
    oneOfDataSrc = serialized;
    final oneOfTypes = [
      MultipleChoiceAnswer,
      NumericAnswer,
      ShortAnswerText,
      SingleChoiceAnswer,
    ];
    Object oneOfResult;
    Type oneOfType;
    switch (discValue) {
      case r'multiple_choice':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(MultipleChoiceAnswer),
        ) as MultipleChoiceAnswer;
        oneOfType = MultipleChoiceAnswer;
        break;
      case r'numeric':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(NumericAnswer),
        ) as NumericAnswer;
        oneOfType = NumericAnswer;
        break;
      case r'short_answer':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(ShortAnswerText),
        ) as ShortAnswerText;
        oneOfType = ShortAnswerText;
        break;
      case r'single_choice':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(SingleChoiceAnswer),
        ) as SingleChoiceAnswer;
        oneOfType = SingleChoiceAnswer;
        break;
      default:
        throw UnsupportedError(
            "Couldn't deserialize oneOf for the discriminator value: ${discValue}");
    }
    result.oneOf = OneOfDynamic(
        typeIndex: oneOfTypes.indexOf(oneOfType),
        types: oneOfTypes,
        value: oneOfResult);
    return result.build();
  }
}

class AnswerPayloadTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'single_choice')
  static const AnswerPayloadTypeEnum singleChoice =
      _$answerPayloadTypeEnum_singleChoice;
  @BuiltValueEnumConst(wireName: r'multiple_choice')
  static const AnswerPayloadTypeEnum multipleChoice =
      _$answerPayloadTypeEnum_multipleChoice;
  @BuiltValueEnumConst(wireName: r'numeric')
  static const AnswerPayloadTypeEnum numeric = _$answerPayloadTypeEnum_numeric;
  @BuiltValueEnumConst(wireName: r'short_answer')
  static const AnswerPayloadTypeEnum shortAnswer =
      _$answerPayloadTypeEnum_shortAnswer;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const AnswerPayloadTypeEnum unknownDefaultOpenApi =
      _$answerPayloadTypeEnum_unknownDefaultOpenApi;

  static Serializer<AnswerPayloadTypeEnum> get serializer =>
      _$answerPayloadTypeEnumSerializer;

  const AnswerPayloadTypeEnum._(String name) : super(name);

  static BuiltSet<AnswerPayloadTypeEnum> get values =>
      _$answerPayloadTypeEnumValues;
  static AnswerPayloadTypeEnum valueOf(String name) =>
      _$answerPayloadTypeEnumValueOf(name);
}
