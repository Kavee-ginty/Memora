//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'due_reason_explanation.g.dart';

/// Why this concept is due, in plain language (PRD 016).
///
/// Properties:
/// * [message] 
/// * [reasonCode] 
/// * [templateKey] 
@BuiltValue()
abstract class DueReasonExplanation implements Built<DueReasonExplanation, DueReasonExplanationBuilder> {
  @BuiltValueField(wireName: r'message')
  String get message;

  @BuiltValueField(wireName: r'reason_code')
  DueReasonExplanationReasonCodeEnum get reasonCode;
  // enum reasonCodeEnum {  forgetting_curve_overdue,  daily_retention_protect,  high_error_rate_repair,  weak_prerequisite_failure,  new_concept_introduction,  };

  @BuiltValueField(wireName: r'template_key')
  DueReasonExplanationTemplateKeyEnum get templateKey;
  // enum templateKeyEnum {  memory.due_reason.overdue,  memory.due_reason.retention,  memory.due_reason.error_repair,  memory.due_reason.weak_prerequisite,  memory.due_reason.new_concept,  };

  DueReasonExplanation._();

  factory DueReasonExplanation([void updates(DueReasonExplanationBuilder b)]) = _$DueReasonExplanation;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DueReasonExplanationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DueReasonExplanation> get serializer => _$DueReasonExplanationSerializer();
}

class _$DueReasonExplanationSerializer implements PrimitiveSerializer<DueReasonExplanation> {
  @override
  final Iterable<Type> types = const [DueReasonExplanation, _$DueReasonExplanation];

  @override
  final String wireName = r'DueReasonExplanation';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DueReasonExplanation object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
    yield r'reason_code';
    yield serializers.serialize(
      object.reasonCode,
      specifiedType: const FullType(DueReasonExplanationReasonCodeEnum),
    );
    yield r'template_key';
    yield serializers.serialize(
      object.templateKey,
      specifiedType: const FullType(DueReasonExplanationTemplateKeyEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DueReasonExplanation object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DueReasonExplanationBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        case r'reason_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DueReasonExplanationReasonCodeEnum),
          ) as DueReasonExplanationReasonCodeEnum;
          result.reasonCode = valueDes;
          break;
        case r'template_key':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DueReasonExplanationTemplateKeyEnum),
          ) as DueReasonExplanationTemplateKeyEnum;
          result.templateKey = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DueReasonExplanation deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DueReasonExplanationBuilder();
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


class DueReasonExplanationReasonCodeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'forgetting_curve_overdue')
  static const DueReasonExplanationReasonCodeEnum forgettingCurveOverdue = _$dueReasonExplanationReasonCodeEnum_forgettingCurveOverdue;
  @BuiltValueEnumConst(wireName: r'daily_retention_protect')
  static const DueReasonExplanationReasonCodeEnum dailyRetentionProtect = _$dueReasonExplanationReasonCodeEnum_dailyRetentionProtect;
  @BuiltValueEnumConst(wireName: r'high_error_rate_repair')
  static const DueReasonExplanationReasonCodeEnum highErrorRateRepair = _$dueReasonExplanationReasonCodeEnum_highErrorRateRepair;
  @BuiltValueEnumConst(wireName: r'weak_prerequisite_failure')
  static const DueReasonExplanationReasonCodeEnum weakPrerequisiteFailure = _$dueReasonExplanationReasonCodeEnum_weakPrerequisiteFailure;
  @BuiltValueEnumConst(wireName: r'new_concept_introduction')
  static const DueReasonExplanationReasonCodeEnum newConceptIntroduction = _$dueReasonExplanationReasonCodeEnum_newConceptIntroduction;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const DueReasonExplanationReasonCodeEnum unknownDefaultOpenApi = _$dueReasonExplanationReasonCodeEnum_unknownDefaultOpenApi;

  static Serializer<DueReasonExplanationReasonCodeEnum> get serializer => _$dueReasonExplanationReasonCodeEnumSerializer;

  const DueReasonExplanationReasonCodeEnum._(String name): super(name);

  static BuiltSet<DueReasonExplanationReasonCodeEnum> get values => _$dueReasonExplanationReasonCodeEnumValues;
  static DueReasonExplanationReasonCodeEnum valueOf(String name) => _$dueReasonExplanationReasonCodeEnumValueOf(name);
}

class DueReasonExplanationTemplateKeyEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'memory.due_reason.overdue')
  static const DueReasonExplanationTemplateKeyEnum memoryPeriodDueReasonPeriodOverdue = _$dueReasonExplanationTemplateKeyEnum_memoryPeriodDueReasonPeriodOverdue;
  @BuiltValueEnumConst(wireName: r'memory.due_reason.retention')
  static const DueReasonExplanationTemplateKeyEnum memoryPeriodDueReasonPeriodRetention = _$dueReasonExplanationTemplateKeyEnum_memoryPeriodDueReasonPeriodRetention;
  @BuiltValueEnumConst(wireName: r'memory.due_reason.error_repair')
  static const DueReasonExplanationTemplateKeyEnum memoryPeriodDueReasonPeriodErrorRepair = _$dueReasonExplanationTemplateKeyEnum_memoryPeriodDueReasonPeriodErrorRepair;
  @BuiltValueEnumConst(wireName: r'memory.due_reason.weak_prerequisite')
  static const DueReasonExplanationTemplateKeyEnum memoryPeriodDueReasonPeriodWeakPrerequisite = _$dueReasonExplanationTemplateKeyEnum_memoryPeriodDueReasonPeriodWeakPrerequisite;
  @BuiltValueEnumConst(wireName: r'memory.due_reason.new_concept')
  static const DueReasonExplanationTemplateKeyEnum memoryPeriodDueReasonPeriodNewConcept = _$dueReasonExplanationTemplateKeyEnum_memoryPeriodDueReasonPeriodNewConcept;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const DueReasonExplanationTemplateKeyEnum unknownDefaultOpenApi = _$dueReasonExplanationTemplateKeyEnum_unknownDefaultOpenApi;

  static Serializer<DueReasonExplanationTemplateKeyEnum> get serializer => _$dueReasonExplanationTemplateKeyEnumSerializer;

  const DueReasonExplanationTemplateKeyEnum._(String name): super(name);

  static BuiltSet<DueReasonExplanationTemplateKeyEnum> get values => _$dueReasonExplanationTemplateKeyEnumValues;
  static DueReasonExplanationTemplateKeyEnum valueOf(String name) => _$dueReasonExplanationTemplateKeyEnumValueOf(name);
}

