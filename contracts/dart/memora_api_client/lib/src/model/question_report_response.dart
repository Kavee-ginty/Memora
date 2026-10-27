//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'question_report_response.g.dart';

/// QuestionReportResponse
///
/// Properties:
/// * [attemptId]
/// * [descriptionPresent]
/// * [evidenceState]
/// * [id]
/// * [questionVersionId]
/// * [reportType]
/// * [resolutionCode]
/// * [resolvedAt]
/// * [reviewRequired]
/// * [status]
/// * [submittedAt]
@BuiltValue()
abstract class QuestionReportResponse
    implements Built<QuestionReportResponse, QuestionReportResponseBuilder> {
  @BuiltValueField(wireName: r'attempt_id')
  String? get attemptId;

  @BuiltValueField(wireName: r'description_present')
  bool get descriptionPresent;

  @BuiltValueField(wireName: r'evidence_state')
  QuestionReportResponseEvidenceStateEnum get evidenceState;
  // enum evidenceStateEnum {  recorded,  limited_pending_review,  };

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'question_version_id')
  String get questionVersionId;

  @BuiltValueField(wireName: r'report_type')
  QuestionReportResponseReportTypeEnum get reportType;
  // enum reportTypeEnum {  question_error,  answer_error,  explanation_error,  grading_dispute,  accessibility,  };

  @BuiltValueField(wireName: r'resolution_code')
  String? get resolutionCode;

  @BuiltValueField(wireName: r'resolved_at')
  String? get resolvedAt;

  @BuiltValueField(wireName: r'review_required')
  bool get reviewRequired;

  @BuiltValueField(wireName: r'status')
  QuestionReportResponseStatusEnum get status;
  // enum statusEnum {  submitted,  triaged,  under_review,  resolved,  dismissed,  };

  @BuiltValueField(wireName: r'submitted_at')
  String get submittedAt;

  QuestionReportResponse._();

  factory QuestionReportResponse(
          [void updates(QuestionReportResponseBuilder b)]) =
      _$QuestionReportResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(QuestionReportResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<QuestionReportResponse> get serializer =>
      _$QuestionReportResponseSerializer();
}

class _$QuestionReportResponseSerializer
    implements PrimitiveSerializer<QuestionReportResponse> {
  @override
  final Iterable<Type> types = const [
    QuestionReportResponse,
    _$QuestionReportResponse
  ];

  @override
  final String wireName = r'QuestionReportResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    QuestionReportResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'attempt_id';
    yield object.attemptId == null
        ? null
        : serializers.serialize(
            object.attemptId,
            specifiedType: const FullType.nullable(String),
          );
    yield r'description_present';
    yield serializers.serialize(
      object.descriptionPresent,
      specifiedType: const FullType(bool),
    );
    yield r'evidence_state';
    yield serializers.serialize(
      object.evidenceState,
      specifiedType: const FullType(QuestionReportResponseEvidenceStateEnum),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'question_version_id';
    yield serializers.serialize(
      object.questionVersionId,
      specifiedType: const FullType(String),
    );
    yield r'report_type';
    yield serializers.serialize(
      object.reportType,
      specifiedType: const FullType(QuestionReportResponseReportTypeEnum),
    );
    yield r'resolution_code';
    yield object.resolutionCode == null
        ? null
        : serializers.serialize(
            object.resolutionCode,
            specifiedType: const FullType.nullable(String),
          );
    yield r'resolved_at';
    yield object.resolvedAt == null
        ? null
        : serializers.serialize(
            object.resolvedAt,
            specifiedType: const FullType.nullable(String),
          );
    yield r'review_required';
    yield serializers.serialize(
      object.reviewRequired,
      specifiedType: const FullType(bool),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(QuestionReportResponseStatusEnum),
    );
    yield r'submitted_at';
    yield serializers.serialize(
      object.submittedAt,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    QuestionReportResponse object, {
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
    required QuestionReportResponseBuilder result,
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
          if (valueDes == null) continue;
          result.attemptId = valueDes;
          break;
        case r'description_present':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.descriptionPresent = valueDes;
          break;
        case r'evidence_state':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(QuestionReportResponseEvidenceStateEnum),
          ) as QuestionReportResponseEvidenceStateEnum;
          result.evidenceState = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'question_version_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.questionVersionId = valueDes;
          break;
        case r'report_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(QuestionReportResponseReportTypeEnum),
          ) as QuestionReportResponseReportTypeEnum;
          result.reportType = valueDes;
          break;
        case r'resolution_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.resolutionCode = valueDes;
          break;
        case r'resolved_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.resolvedAt = valueDes;
          break;
        case r'review_required':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.reviewRequired = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(QuestionReportResponseStatusEnum),
          ) as QuestionReportResponseStatusEnum;
          result.status = valueDes;
          break;
        case r'submitted_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.submittedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  QuestionReportResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = QuestionReportResponseBuilder();
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

class QuestionReportResponseEvidenceStateEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'recorded')
  static const QuestionReportResponseEvidenceStateEnum recorded =
      _$questionReportResponseEvidenceStateEnum_recorded;
  @BuiltValueEnumConst(wireName: r'limited_pending_review')
  static const QuestionReportResponseEvidenceStateEnum limitedPendingReview =
      _$questionReportResponseEvidenceStateEnum_limitedPendingReview;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const QuestionReportResponseEvidenceStateEnum unknownDefaultOpenApi =
      _$questionReportResponseEvidenceStateEnum_unknownDefaultOpenApi;

  static Serializer<QuestionReportResponseEvidenceStateEnum> get serializer =>
      _$questionReportResponseEvidenceStateEnumSerializer;

  const QuestionReportResponseEvidenceStateEnum._(String name) : super(name);

  static BuiltSet<QuestionReportResponseEvidenceStateEnum> get values =>
      _$questionReportResponseEvidenceStateEnumValues;
  static QuestionReportResponseEvidenceStateEnum valueOf(String name) =>
      _$questionReportResponseEvidenceStateEnumValueOf(name);
}

class QuestionReportResponseReportTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'question_error')
  static const QuestionReportResponseReportTypeEnum questionError =
      _$questionReportResponseReportTypeEnum_questionError;
  @BuiltValueEnumConst(wireName: r'answer_error')
  static const QuestionReportResponseReportTypeEnum answerError =
      _$questionReportResponseReportTypeEnum_answerError;
  @BuiltValueEnumConst(wireName: r'explanation_error')
  static const QuestionReportResponseReportTypeEnum explanationError =
      _$questionReportResponseReportTypeEnum_explanationError;
  @BuiltValueEnumConst(wireName: r'grading_dispute')
  static const QuestionReportResponseReportTypeEnum gradingDispute =
      _$questionReportResponseReportTypeEnum_gradingDispute;
  @BuiltValueEnumConst(wireName: r'accessibility')
  static const QuestionReportResponseReportTypeEnum accessibility =
      _$questionReportResponseReportTypeEnum_accessibility;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const QuestionReportResponseReportTypeEnum unknownDefaultOpenApi =
      _$questionReportResponseReportTypeEnum_unknownDefaultOpenApi;

  static Serializer<QuestionReportResponseReportTypeEnum> get serializer =>
      _$questionReportResponseReportTypeEnumSerializer;

  const QuestionReportResponseReportTypeEnum._(String name) : super(name);

  static BuiltSet<QuestionReportResponseReportTypeEnum> get values =>
      _$questionReportResponseReportTypeEnumValues;
  static QuestionReportResponseReportTypeEnum valueOf(String name) =>
      _$questionReportResponseReportTypeEnumValueOf(name);
}

class QuestionReportResponseStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'submitted')
  static const QuestionReportResponseStatusEnum submitted =
      _$questionReportResponseStatusEnum_submitted;
  @BuiltValueEnumConst(wireName: r'triaged')
  static const QuestionReportResponseStatusEnum triaged =
      _$questionReportResponseStatusEnum_triaged;
  @BuiltValueEnumConst(wireName: r'under_review')
  static const QuestionReportResponseStatusEnum underReview =
      _$questionReportResponseStatusEnum_underReview;
  @BuiltValueEnumConst(wireName: r'resolved')
  static const QuestionReportResponseStatusEnum resolved =
      _$questionReportResponseStatusEnum_resolved;
  @BuiltValueEnumConst(wireName: r'dismissed')
  static const QuestionReportResponseStatusEnum dismissed =
      _$questionReportResponseStatusEnum_dismissed;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const QuestionReportResponseStatusEnum unknownDefaultOpenApi =
      _$questionReportResponseStatusEnum_unknownDefaultOpenApi;

  static Serializer<QuestionReportResponseStatusEnum> get serializer =>
      _$questionReportResponseStatusEnumSerializer;

  const QuestionReportResponseStatusEnum._(String name) : super(name);

  static BuiltSet<QuestionReportResponseStatusEnum> get values =>
      _$questionReportResponseStatusEnumValues;
  static QuestionReportResponseStatusEnum valueOf(String name) =>
      _$questionReportResponseStatusEnumValueOf(name);
}
