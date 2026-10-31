//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'question_report_create_request.g.dart';

/// QuestionReportCreateRequest
///
/// Properties:
/// * [attemptId] 
/// * [description] 
/// * [reportType] 
@BuiltValue()
abstract class QuestionReportCreateRequest implements Built<QuestionReportCreateRequest, QuestionReportCreateRequestBuilder> {
  @BuiltValueField(wireName: r'attempt_id')
  Optional<String?> get attemptId;

  @BuiltValueField(wireName: r'description')
  Optional<String?> get description;

  @BuiltValueField(wireName: r'report_type')
  QuestionReportCreateRequestReportTypeEnum get reportType;
  // enum reportTypeEnum {  question_error,  answer_error,  explanation_error,  grading_dispute,  accessibility,  };

  QuestionReportCreateRequest._();

  factory QuestionReportCreateRequest([void updates(QuestionReportCreateRequestBuilder b)]) = _$QuestionReportCreateRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(QuestionReportCreateRequestBuilder b) => b
      ..attemptId = Optional.absent()
      ..description = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<QuestionReportCreateRequest> get serializer => _$QuestionReportCreateRequestSerializer();
}

class _$QuestionReportCreateRequestSerializer implements PrimitiveSerializer<QuestionReportCreateRequest> {
  @override
  final Iterable<Type> types = const [QuestionReportCreateRequest, _$QuestionReportCreateRequest];

  @override
  final String wireName = r'QuestionReportCreateRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    QuestionReportCreateRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.attemptId.isPresent) {
      yield r'attempt_id';
      final optionalValue = object.attemptId.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    if (object.description.isPresent) {
      yield r'description';
      final optionalValue = object.description.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    yield r'report_type';
    yield serializers.serialize(
      object.reportType,
      specifiedType: const FullType(QuestionReportCreateRequestReportTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    QuestionReportCreateRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required QuestionReportCreateRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'attempt_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.attemptId = Optional.present(valueDes);
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.description = Optional.present(valueDes);
          break;
        case r'report_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(QuestionReportCreateRequestReportTypeEnum),
          ) as QuestionReportCreateRequestReportTypeEnum;
          result.reportType = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  QuestionReportCreateRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = QuestionReportCreateRequestBuilder();
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


class QuestionReportCreateRequestReportTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'question_error')
  static const QuestionReportCreateRequestReportTypeEnum questionError = _$questionReportCreateRequestReportTypeEnum_questionError;
  @BuiltValueEnumConst(wireName: r'answer_error')
  static const QuestionReportCreateRequestReportTypeEnum answerError = _$questionReportCreateRequestReportTypeEnum_answerError;
  @BuiltValueEnumConst(wireName: r'explanation_error')
  static const QuestionReportCreateRequestReportTypeEnum explanationError = _$questionReportCreateRequestReportTypeEnum_explanationError;
  @BuiltValueEnumConst(wireName: r'grading_dispute')
  static const QuestionReportCreateRequestReportTypeEnum gradingDispute = _$questionReportCreateRequestReportTypeEnum_gradingDispute;
  @BuiltValueEnumConst(wireName: r'accessibility')
  static const QuestionReportCreateRequestReportTypeEnum accessibility = _$questionReportCreateRequestReportTypeEnum_accessibility;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const QuestionReportCreateRequestReportTypeEnum unknownDefaultOpenApi = _$questionReportCreateRequestReportTypeEnum_unknownDefaultOpenApi;

  static Serializer<QuestionReportCreateRequestReportTypeEnum> get serializer => _$questionReportCreateRequestReportTypeEnumSerializer;

  const QuestionReportCreateRequestReportTypeEnum._(String name): super(name);

  static BuiltSet<QuestionReportCreateRequestReportTypeEnum> get values => _$questionReportCreateRequestReportTypeEnumValues;
  static QuestionReportCreateRequestReportTypeEnum valueOf(String name) => _$questionReportCreateRequestReportTypeEnumValueOf(name);
}

