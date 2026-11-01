//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/media_reference.dart';
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/public_question_option.dart';
import 'package:memora_api_client/src/model/public_response_config.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'public_question.g.dart';

/// Pre-submission payload with no correctness or rubric data.
///
/// Properties:
/// * [media]
/// * [options]
/// * [prompt]
/// * [questionType]
/// * [questionVersionId]
/// * [responseConfig]
/// * [trustLabel]
@BuiltValue()
abstract class PublicQuestion
    implements Built<PublicQuestion, PublicQuestionBuilder> {
  @BuiltValueField(wireName: r'media')
  BuiltList<MediaReference> get media;

  @BuiltValueField(wireName: r'options')
  BuiltList<PublicQuestionOption> get options;

  @BuiltValueField(wireName: r'prompt')
  String get prompt;

  @BuiltValueField(wireName: r'question_type')
  PublicQuestionQuestionTypeEnum get questionType;
  // enum questionTypeEnum {  single_choice,  multiple_choice,  numeric,  short_answer,  };

  @BuiltValueField(wireName: r'question_version_id')
  String get questionVersionId;

  @BuiltValueField(wireName: r'response_config')
  PublicResponseConfig get responseConfig;

  @BuiltValueField(wireName: r'trust_label')
  String get trustLabel;

  PublicQuestion._();

  factory PublicQuestion([void updates(PublicQuestionBuilder b)]) =
      _$PublicQuestion;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PublicQuestionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PublicQuestion> get serializer =>
      _$PublicQuestionSerializer();
}

class _$PublicQuestionSerializer
    implements PrimitiveSerializer<PublicQuestion> {
  @override
  final Iterable<Type> types = const [PublicQuestion, _$PublicQuestion];

  @override
  final String wireName = r'PublicQuestion';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PublicQuestion object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'media';
    yield serializers.serialize(
      object.media,
      specifiedType: const FullType(BuiltList, [FullType(MediaReference)]),
    );
    yield r'options';
    yield serializers.serialize(
      object.options,
      specifiedType:
          const FullType(BuiltList, [FullType(PublicQuestionOption)]),
    );
    yield r'prompt';
    yield serializers.serialize(
      object.prompt,
      specifiedType: const FullType(String),
    );
    yield r'question_type';
    yield serializers.serialize(
      object.questionType,
      specifiedType: const FullType(PublicQuestionQuestionTypeEnum),
    );
    yield r'question_version_id';
    yield serializers.serialize(
      object.questionVersionId,
      specifiedType: const FullType(String),
    );
    yield r'response_config';
    yield serializers.serialize(
      object.responseConfig,
      specifiedType: const FullType(PublicResponseConfig),
    );
    yield r'trust_label';
    yield serializers.serialize(
      object.trustLabel,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PublicQuestion object, {
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
    required PublicQuestionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'media':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(BuiltList, [FullType(MediaReference)]),
          ) as BuiltList<MediaReference>;
          result.media.replace(valueDes);
          break;
        case r'options':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(BuiltList, [FullType(PublicQuestionOption)]),
          ) as BuiltList<PublicQuestionOption>;
          result.options.replace(valueDes);
          break;
        case r'prompt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.prompt = valueDes;
          break;
        case r'question_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PublicQuestionQuestionTypeEnum),
          ) as PublicQuestionQuestionTypeEnum;
          result.questionType = valueDes;
          break;
        case r'question_version_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.questionVersionId = valueDes;
          break;
        case r'response_config':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PublicResponseConfig),
          ) as PublicResponseConfig;
          result.responseConfig.replace(valueDes);
          break;
        case r'trust_label':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.trustLabel = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PublicQuestion deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PublicQuestionBuilder();
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

class PublicQuestionQuestionTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'single_choice')
  static const PublicQuestionQuestionTypeEnum singleChoice =
      _$publicQuestionQuestionTypeEnum_singleChoice;
  @BuiltValueEnumConst(wireName: r'multiple_choice')
  static const PublicQuestionQuestionTypeEnum multipleChoice =
      _$publicQuestionQuestionTypeEnum_multipleChoice;
  @BuiltValueEnumConst(wireName: r'numeric')
  static const PublicQuestionQuestionTypeEnum numeric =
      _$publicQuestionQuestionTypeEnum_numeric;
  @BuiltValueEnumConst(wireName: r'short_answer')
  static const PublicQuestionQuestionTypeEnum shortAnswer =
      _$publicQuestionQuestionTypeEnum_shortAnswer;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const PublicQuestionQuestionTypeEnum unknownDefaultOpenApi =
      _$publicQuestionQuestionTypeEnum_unknownDefaultOpenApi;

  static Serializer<PublicQuestionQuestionTypeEnum> get serializer =>
      _$publicQuestionQuestionTypeEnumSerializer;

  const PublicQuestionQuestionTypeEnum._(String name) : super(name);

  static BuiltSet<PublicQuestionQuestionTypeEnum> get values =>
      _$publicQuestionQuestionTypeEnumValues;
  static PublicQuestionQuestionTypeEnum valueOf(String name) =>
      _$publicQuestionQuestionTypeEnumValueOf(name);
}
