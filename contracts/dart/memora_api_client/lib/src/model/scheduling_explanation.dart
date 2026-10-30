//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'scheduling_explanation.g.dart';

/// One stored scheduling decision and its allowlisted explanation.
///
/// Properties:
/// * [decidedAt]
/// * [decisionId]
/// * [engineVersion]
/// * [message]
/// * [nextReviewAt]
/// * [policyVersion]
/// * [reasonCodes]
/// * [templateKey]
/// * [triggerEventType]
@BuiltValue()
abstract class SchedulingExplanation
    implements Built<SchedulingExplanation, SchedulingExplanationBuilder> {
  @BuiltValueField(wireName: r'decided_at')
  String get decidedAt;

  @BuiltValueField(wireName: r'decision_id')
  String get decisionId;

  @BuiltValueField(wireName: r'engine_version')
  String get engineVersion;

  @BuiltValueField(wireName: r'message')
  String get message;

  @BuiltValueField(wireName: r'next_review_at')
  String get nextReviewAt;

  @BuiltValueField(wireName: r'policy_version')
  String get policyVersion;

  @BuiltValueField(wireName: r'reason_codes')
  BuiltList<SchedulingExplanationReasonCodesEnum> get reasonCodes;
  // enum reasonCodesEnum {  state_initialized,  exposure_recorded,  recall_success,  recall_lapse,  review_scheduled,  out_of_order_evidence,  first_review_bounded,  evidence_justified_schedule,  comeback_elapsed,  low_confidence_damped,  weak_prerequisite_recover,  interval_bounded,  };

  @BuiltValueField(wireName: r'template_key')
  SchedulingExplanationTemplateKeyEnum get templateKey;
  // enum templateKeyEnum {  memory.explanation.state_initialized,  memory.explanation.exposure_recorded,  memory.explanation.recall_success,  memory.explanation.recall_lapse,  memory.explanation.first_review_scheduled,  memory.explanation.comeback,  memory.explanation.low_confidence,  memory.explanation.weak_prerequisite,  memory.explanation.evidence_recorded,  };

  @BuiltValueField(wireName: r'trigger_event_type')
  SchedulingExplanationTriggerEventTypeEnum get triggerEventType;
  // enum triggerEventTypeEnum {  exposure,  attempt,  repair,  regrade,  invalidation,  manual_review,  };

  SchedulingExplanation._();

  factory SchedulingExplanation(
      [void updates(SchedulingExplanationBuilder b)]) = _$SchedulingExplanation;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SchedulingExplanationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SchedulingExplanation> get serializer =>
      _$SchedulingExplanationSerializer();
}

class _$SchedulingExplanationSerializer
    implements PrimitiveSerializer<SchedulingExplanation> {
  @override
  final Iterable<Type> types = const [
    SchedulingExplanation,
    _$SchedulingExplanation
  ];

  @override
  final String wireName = r'SchedulingExplanation';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SchedulingExplanation object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'decided_at';
    yield serializers.serialize(
      object.decidedAt,
      specifiedType: const FullType(String),
    );
    yield r'decision_id';
    yield serializers.serialize(
      object.decisionId,
      specifiedType: const FullType(String),
    );
    yield r'engine_version';
    yield serializers.serialize(
      object.engineVersion,
      specifiedType: const FullType(String),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
    yield r'next_review_at';
    yield serializers.serialize(
      object.nextReviewAt,
      specifiedType: const FullType(String),
    );
    yield r'policy_version';
    yield serializers.serialize(
      object.policyVersion,
      specifiedType: const FullType(String),
    );
    yield r'reason_codes';
    yield serializers.serialize(
      object.reasonCodes,
      specifiedType: const FullType(
          BuiltList, [FullType(SchedulingExplanationReasonCodesEnum)]),
    );
    yield r'template_key';
    yield serializers.serialize(
      object.templateKey,
      specifiedType: const FullType(SchedulingExplanationTemplateKeyEnum),
    );
    yield r'trigger_event_type';
    yield serializers.serialize(
      object.triggerEventType,
      specifiedType: const FullType(SchedulingExplanationTriggerEventTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SchedulingExplanation object, {
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
    required SchedulingExplanationBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'decided_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.decidedAt = valueDes;
          break;
        case r'decision_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.decisionId = valueDes;
          break;
        case r'engine_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.engineVersion = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        case r'next_review_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nextReviewAt = valueDes;
          break;
        case r'policy_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.policyVersion = valueDes;
          break;
        case r'reason_codes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(
                BuiltList, [FullType(SchedulingExplanationReasonCodesEnum)]),
          ) as BuiltList<SchedulingExplanationReasonCodesEnum>;
          result.reasonCodes.replace(valueDes);
          break;
        case r'template_key':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(SchedulingExplanationTemplateKeyEnum),
          ) as SchedulingExplanationTemplateKeyEnum;
          result.templateKey = valueDes;
          break;
        case r'trigger_event_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(SchedulingExplanationTriggerEventTypeEnum),
          ) as SchedulingExplanationTriggerEventTypeEnum;
          result.triggerEventType = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SchedulingExplanation deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SchedulingExplanationBuilder();
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

class SchedulingExplanationReasonCodesEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'state_initialized')
  static const SchedulingExplanationReasonCodesEnum stateInitialized =
      _$schedulingExplanationReasonCodesEnum_stateInitialized;
  @BuiltValueEnumConst(wireName: r'exposure_recorded')
  static const SchedulingExplanationReasonCodesEnum exposureRecorded =
      _$schedulingExplanationReasonCodesEnum_exposureRecorded;
  @BuiltValueEnumConst(wireName: r'recall_success')
  static const SchedulingExplanationReasonCodesEnum recallSuccess =
      _$schedulingExplanationReasonCodesEnum_recallSuccess;
  @BuiltValueEnumConst(wireName: r'recall_lapse')
  static const SchedulingExplanationReasonCodesEnum recallLapse =
      _$schedulingExplanationReasonCodesEnum_recallLapse;
  @BuiltValueEnumConst(wireName: r'review_scheduled')
  static const SchedulingExplanationReasonCodesEnum reviewScheduled =
      _$schedulingExplanationReasonCodesEnum_reviewScheduled;
  @BuiltValueEnumConst(wireName: r'out_of_order_evidence')
  static const SchedulingExplanationReasonCodesEnum outOfOrderEvidence =
      _$schedulingExplanationReasonCodesEnum_outOfOrderEvidence;
  @BuiltValueEnumConst(wireName: r'first_review_bounded')
  static const SchedulingExplanationReasonCodesEnum firstReviewBounded =
      _$schedulingExplanationReasonCodesEnum_firstReviewBounded;
  @BuiltValueEnumConst(wireName: r'evidence_justified_schedule')
  static const SchedulingExplanationReasonCodesEnum evidenceJustifiedSchedule =
      _$schedulingExplanationReasonCodesEnum_evidenceJustifiedSchedule;
  @BuiltValueEnumConst(wireName: r'comeback_elapsed')
  static const SchedulingExplanationReasonCodesEnum comebackElapsed =
      _$schedulingExplanationReasonCodesEnum_comebackElapsed;
  @BuiltValueEnumConst(wireName: r'low_confidence_damped')
  static const SchedulingExplanationReasonCodesEnum lowConfidenceDamped =
      _$schedulingExplanationReasonCodesEnum_lowConfidenceDamped;
  @BuiltValueEnumConst(wireName: r'weak_prerequisite_recover')
  static const SchedulingExplanationReasonCodesEnum weakPrerequisiteRecover =
      _$schedulingExplanationReasonCodesEnum_weakPrerequisiteRecover;
  @BuiltValueEnumConst(wireName: r'interval_bounded')
  static const SchedulingExplanationReasonCodesEnum intervalBounded =
      _$schedulingExplanationReasonCodesEnum_intervalBounded;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const SchedulingExplanationReasonCodesEnum unknownDefaultOpenApi =
      _$schedulingExplanationReasonCodesEnum_unknownDefaultOpenApi;

  static Serializer<SchedulingExplanationReasonCodesEnum> get serializer =>
      _$schedulingExplanationReasonCodesEnumSerializer;

  const SchedulingExplanationReasonCodesEnum._(String name) : super(name);

  static BuiltSet<SchedulingExplanationReasonCodesEnum> get values =>
      _$schedulingExplanationReasonCodesEnumValues;
  static SchedulingExplanationReasonCodesEnum valueOf(String name) =>
      _$schedulingExplanationReasonCodesEnumValueOf(name);
}

class SchedulingExplanationTemplateKeyEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'memory.explanation.state_initialized')
  static const SchedulingExplanationTemplateKeyEnum
      memoryPeriodExplanationPeriodStateInitialized =
      _$schedulingExplanationTemplateKeyEnum_memoryPeriodExplanationPeriodStateInitialized;
  @BuiltValueEnumConst(wireName: r'memory.explanation.exposure_recorded')
  static const SchedulingExplanationTemplateKeyEnum
      memoryPeriodExplanationPeriodExposureRecorded =
      _$schedulingExplanationTemplateKeyEnum_memoryPeriodExplanationPeriodExposureRecorded;
  @BuiltValueEnumConst(wireName: r'memory.explanation.recall_success')
  static const SchedulingExplanationTemplateKeyEnum
      memoryPeriodExplanationPeriodRecallSuccess =
      _$schedulingExplanationTemplateKeyEnum_memoryPeriodExplanationPeriodRecallSuccess;
  @BuiltValueEnumConst(wireName: r'memory.explanation.recall_lapse')
  static const SchedulingExplanationTemplateKeyEnum
      memoryPeriodExplanationPeriodRecallLapse =
      _$schedulingExplanationTemplateKeyEnum_memoryPeriodExplanationPeriodRecallLapse;
  @BuiltValueEnumConst(wireName: r'memory.explanation.first_review_scheduled')
  static const SchedulingExplanationTemplateKeyEnum
      memoryPeriodExplanationPeriodFirstReviewScheduled =
      _$schedulingExplanationTemplateKeyEnum_memoryPeriodExplanationPeriodFirstReviewScheduled;
  @BuiltValueEnumConst(wireName: r'memory.explanation.comeback')
  static const SchedulingExplanationTemplateKeyEnum
      memoryPeriodExplanationPeriodComeback =
      _$schedulingExplanationTemplateKeyEnum_memoryPeriodExplanationPeriodComeback;
  @BuiltValueEnumConst(wireName: r'memory.explanation.low_confidence')
  static const SchedulingExplanationTemplateKeyEnum
      memoryPeriodExplanationPeriodLowConfidence =
      _$schedulingExplanationTemplateKeyEnum_memoryPeriodExplanationPeriodLowConfidence;
  @BuiltValueEnumConst(wireName: r'memory.explanation.weak_prerequisite')
  static const SchedulingExplanationTemplateKeyEnum
      memoryPeriodExplanationPeriodWeakPrerequisite =
      _$schedulingExplanationTemplateKeyEnum_memoryPeriodExplanationPeriodWeakPrerequisite;
  @BuiltValueEnumConst(wireName: r'memory.explanation.evidence_recorded')
  static const SchedulingExplanationTemplateKeyEnum
      memoryPeriodExplanationPeriodEvidenceRecorded =
      _$schedulingExplanationTemplateKeyEnum_memoryPeriodExplanationPeriodEvidenceRecorded;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const SchedulingExplanationTemplateKeyEnum unknownDefaultOpenApi =
      _$schedulingExplanationTemplateKeyEnum_unknownDefaultOpenApi;

  static Serializer<SchedulingExplanationTemplateKeyEnum> get serializer =>
      _$schedulingExplanationTemplateKeyEnumSerializer;

  const SchedulingExplanationTemplateKeyEnum._(String name) : super(name);

  static BuiltSet<SchedulingExplanationTemplateKeyEnum> get values =>
      _$schedulingExplanationTemplateKeyEnumValues;
  static SchedulingExplanationTemplateKeyEnum valueOf(String name) =>
      _$schedulingExplanationTemplateKeyEnumValueOf(name);
}

class SchedulingExplanationTriggerEventTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'exposure')
  static const SchedulingExplanationTriggerEventTypeEnum exposure =
      _$schedulingExplanationTriggerEventTypeEnum_exposure;
  @BuiltValueEnumConst(wireName: r'attempt')
  static const SchedulingExplanationTriggerEventTypeEnum attempt =
      _$schedulingExplanationTriggerEventTypeEnum_attempt;
  @BuiltValueEnumConst(wireName: r'repair')
  static const SchedulingExplanationTriggerEventTypeEnum repair =
      _$schedulingExplanationTriggerEventTypeEnum_repair;
  @BuiltValueEnumConst(wireName: r'regrade')
  static const SchedulingExplanationTriggerEventTypeEnum regrade =
      _$schedulingExplanationTriggerEventTypeEnum_regrade;
  @BuiltValueEnumConst(wireName: r'invalidation')
  static const SchedulingExplanationTriggerEventTypeEnum invalidation =
      _$schedulingExplanationTriggerEventTypeEnum_invalidation;
  @BuiltValueEnumConst(wireName: r'manual_review')
  static const SchedulingExplanationTriggerEventTypeEnum manualReview =
      _$schedulingExplanationTriggerEventTypeEnum_manualReview;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const SchedulingExplanationTriggerEventTypeEnum unknownDefaultOpenApi =
      _$schedulingExplanationTriggerEventTypeEnum_unknownDefaultOpenApi;

  static Serializer<SchedulingExplanationTriggerEventTypeEnum> get serializer =>
      _$schedulingExplanationTriggerEventTypeEnumSerializer;

  const SchedulingExplanationTriggerEventTypeEnum._(String name) : super(name);

  static BuiltSet<SchedulingExplanationTriggerEventTypeEnum> get values =>
      _$schedulingExplanationTriggerEventTypeEnumValues;
  static SchedulingExplanationTriggerEventTypeEnum valueOf(String name) =>
      _$schedulingExplanationTriggerEventTypeEnumValueOf(name);
}
