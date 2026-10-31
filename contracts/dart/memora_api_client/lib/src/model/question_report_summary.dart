//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'question_report_summary.g.dart';

/// QuestionReportSummary
///
/// Properties:
/// * [attemptId] 
/// * [descriptionPresent] 
/// * [evidenceState] 
/// * [id] 
/// * [questionVersionId] 
/// * [reportType] 
/// * [resolvedAt] 
/// * [status] 
/// * [submittedAt] 
@BuiltValue()
abstract class QuestionReportSummary implements Built<QuestionReportSummary, QuestionReportSummaryBuilder> {
  @BuiltValueField(wireName: r'attempt_id')
  String? get attemptId;

  @BuiltValueField(wireName: r'description_present')
  bool get descriptionPresent;

  @BuiltValueField(wireName: r'evidence_state')
  QuestionReportSummaryEvidenceStateEnum get evidenceState;
  // enum evidenceStateEnum {  recorded,  limited_pending_review,  };

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'question_version_id')
  String get questionVersionId;

  @BuiltValueField(wireName: r'report_type')
  QuestionReportSummaryReportTypeEnum get reportType;
  // enum reportTypeEnum {  question_error,  answer_error,  explanation_error,  grading_dispute,  accessibility,  };

  @BuiltValueField(wireName: r'resolved_at')
  String? get resolvedAt;

  @BuiltValueField(wireName: r'status')
  QuestionReportSummaryStatusEnum get status;
  // enum statusEnum {  submitted,  triaged,  under_review,  resolved,  dismissed,  };

  @BuiltValueField(wireName: r'submitted_at')
  String get submittedAt;

  QuestionReportSummary._();

  factory QuestionReportSummary([void updates(QuestionReportSummaryBuilder b)]) = _$QuestionReportSummary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(QuestionReportSummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<QuestionReportSummary> get serializer => _$QuestionReportSummarySerializer();
}

class _$QuestionReportSummarySerializer implements PrimitiveSerializer<QuestionReportSummary> {
  @override
  final Iterable<Type> types = const [QuestionReportSummary, _$QuestionReportSummary];

  @override
  final String wireName = r'QuestionReportSummary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    QuestionReportSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'attempt_id';
    yield object.attemptId == null ? null : serializers.serialize(
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
      specifiedType: const FullType(QuestionReportSummaryEvidenceStateEnum),
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
      specifiedType: const FullType(QuestionReportSummaryReportTypeEnum),
    );
    yield r'resolved_at';
    yield object.resolvedAt == null ? null : serializers.serialize(
      object.resolvedAt,
      specifiedType: const FullType.nullable(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(QuestionReportSummaryStatusEnum),
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
    QuestionReportSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required QuestionReportSummaryBuilder result,
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
            specifiedType: const FullType(QuestionReportSummaryEvidenceStateEnum),
          ) as QuestionReportSummaryEvidenceStateEnum;
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
            specifiedType: const FullType(QuestionReportSummaryReportTypeEnum),
          ) as QuestionReportSummaryReportTypeEnum;
          result.reportType = valueDes;
          break;
        case r'resolved_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.resolvedAt = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(QuestionReportSummaryStatusEnum),
          ) as QuestionReportSummaryStatusEnum;
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
  QuestionReportSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = QuestionReportSummaryBuilder();
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


class QuestionReportSummaryEvidenceStateEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'recorded')
  static const QuestionReportSummaryEvidenceStateEnum recorded = _$questionReportSummaryEvidenceStateEnum_recorded;
  @BuiltValueEnumConst(wireName: r'limited_pending_review')
  static const QuestionReportSummaryEvidenceStateEnum limitedPendingReview = _$questionReportSummaryEvidenceStateEnum_limitedPendingReview;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const QuestionReportSummaryEvidenceStateEnum unknownDefaultOpenApi = _$questionReportSummaryEvidenceStateEnum_unknownDefaultOpenApi;

  static Serializer<QuestionReportSummaryEvidenceStateEnum> get serializer => _$questionReportSummaryEvidenceStateEnumSerializer;

  const QuestionReportSummaryEvidenceStateEnum._(String name): super(name);

  static BuiltSet<QuestionReportSummaryEvidenceStateEnum> get values => _$questionReportSummaryEvidenceStateEnumValues;
  static QuestionReportSummaryEvidenceStateEnum valueOf(String name) => _$questionReportSummaryEvidenceStateEnumValueOf(name);
}

class QuestionReportSummaryReportTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'question_error')
  static const QuestionReportSummaryReportTypeEnum questionError = _$questionReportSummaryReportTypeEnum_questionError;
  @BuiltValueEnumConst(wireName: r'answer_error')
  static const QuestionReportSummaryReportTypeEnum answerError = _$questionReportSummaryReportTypeEnum_answerError;
  @BuiltValueEnumConst(wireName: r'explanation_error')
  static const QuestionReportSummaryReportTypeEnum explanationError = _$questionReportSummaryReportTypeEnum_explanationError;
  @BuiltValueEnumConst(wireName: r'grading_dispute')
  static const QuestionReportSummaryReportTypeEnum gradingDispute = _$questionReportSummaryReportTypeEnum_gradingDispute;
  @BuiltValueEnumConst(wireName: r'accessibility')
  static const QuestionReportSummaryReportTypeEnum accessibility = _$questionReportSummaryReportTypeEnum_accessibility;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const QuestionReportSummaryReportTypeEnum unknownDefaultOpenApi = _$questionReportSummaryReportTypeEnum_unknownDefaultOpenApi;

  static Serializer<QuestionReportSummaryReportTypeEnum> get serializer => _$questionReportSummaryReportTypeEnumSerializer;

  const QuestionReportSummaryReportTypeEnum._(String name): super(name);

  static BuiltSet<QuestionReportSummaryReportTypeEnum> get values => _$questionReportSummaryReportTypeEnumValues;
  static QuestionReportSummaryReportTypeEnum valueOf(String name) => _$questionReportSummaryReportTypeEnumValueOf(name);
}

class QuestionReportSummaryStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'submitted')
  static const QuestionReportSummaryStatusEnum submitted = _$questionReportSummaryStatusEnum_submitted;
  @BuiltValueEnumConst(wireName: r'triaged')
  static const QuestionReportSummaryStatusEnum triaged = _$questionReportSummaryStatusEnum_triaged;
  @BuiltValueEnumConst(wireName: r'under_review')
  static const QuestionReportSummaryStatusEnum underReview = _$questionReportSummaryStatusEnum_underReview;
  @BuiltValueEnumConst(wireName: r'resolved')
  static const QuestionReportSummaryStatusEnum resolved = _$questionReportSummaryStatusEnum_resolved;
  @BuiltValueEnumConst(wireName: r'dismissed')
  static const QuestionReportSummaryStatusEnum dismissed = _$questionReportSummaryStatusEnum_dismissed;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const QuestionReportSummaryStatusEnum unknownDefaultOpenApi = _$questionReportSummaryStatusEnum_unknownDefaultOpenApi;

  static Serializer<QuestionReportSummaryStatusEnum> get serializer => _$questionReportSummaryStatusEnumSerializer;

  const QuestionReportSummaryStatusEnum._(String name): super(name);

  static BuiltSet<QuestionReportSummaryStatusEnum> get values => _$questionReportSummaryStatusEnumValues;
  static QuestionReportSummaryStatusEnum valueOf(String name) => _$questionReportSummaryStatusEnumValueOf(name);
}

