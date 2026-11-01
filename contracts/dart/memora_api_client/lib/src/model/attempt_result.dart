//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'attempt_result.g.dart';

/// AttemptResult
///
/// Properties:
/// * [attemptId]
/// * [canComplete]
/// * [explanation]
/// * [explanationAvailable]
/// * [feedback]
/// * [gradingStatus]
/// * [influenceLimited]
/// * [nextItemId]
/// * [outcome]
/// * [repairAction]
@BuiltValue()
abstract class AttemptResult
    implements Built<AttemptResult, AttemptResultBuilder> {
  @BuiltValueField(wireName: r'attempt_id')
  String? get attemptId;

  @BuiltValueField(wireName: r'can_complete')
  bool get canComplete;

  @BuiltValueField(wireName: r'explanation')
  String? get explanation;

  @BuiltValueField(wireName: r'explanation_available')
  bool get explanationAvailable;

  @BuiltValueField(wireName: r'feedback')
  String get feedback;

  @BuiltValueField(wireName: r'grading_status')
  AttemptResultGradingStatusEnum get gradingStatus;
  // enum gradingStatusEnum {  graded,  skipped,  };

  @BuiltValueField(wireName: r'influence_limited')
  bool get influenceLimited;

  @BuiltValueField(wireName: r'next_item_id')
  String? get nextItemId;

  @BuiltValueField(wireName: r'outcome')
  AttemptResultOutcomeEnum get outcome;
  // enum outcomeEnum {  recalled,  partial,  uncertain,  weak,  skipped,  };

  @BuiltValueField(wireName: r'repair_action')
  AttemptResultRepairActionEnum get repairAction;
  // enum repairActionEnum {  none,  repair_inserted,  review_concept,  confirm_or_appeal,  };

  AttemptResult._();

  factory AttemptResult([void updates(AttemptResultBuilder b)]) =
      _$AttemptResult;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AttemptResultBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AttemptResult> get serializer =>
      _$AttemptResultSerializer();
}

class _$AttemptResultSerializer implements PrimitiveSerializer<AttemptResult> {
  @override
  final Iterable<Type> types = const [AttemptResult, _$AttemptResult];

  @override
  final String wireName = r'AttemptResult';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AttemptResult object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'attempt_id';
    yield object.attemptId == null
        ? null
        : serializers.serialize(
            object.attemptId,
            specifiedType: const FullType.nullable(String),
          );
    yield r'can_complete';
    yield serializers.serialize(
      object.canComplete,
      specifiedType: const FullType(bool),
    );
    yield r'explanation';
    yield object.explanation == null
        ? null
        : serializers.serialize(
            object.explanation,
            specifiedType: const FullType.nullable(String),
          );
    yield r'explanation_available';
    yield serializers.serialize(
      object.explanationAvailable,
      specifiedType: const FullType(bool),
    );
    yield r'feedback';
    yield serializers.serialize(
      object.feedback,
      specifiedType: const FullType(String),
    );
    yield r'grading_status';
    yield serializers.serialize(
      object.gradingStatus,
      specifiedType: const FullType(AttemptResultGradingStatusEnum),
    );
    yield r'influence_limited';
    yield serializers.serialize(
      object.influenceLimited,
      specifiedType: const FullType(bool),
    );
    yield r'next_item_id';
    yield object.nextItemId == null
        ? null
        : serializers.serialize(
            object.nextItemId,
            specifiedType: const FullType.nullable(String),
          );
    yield r'outcome';
    yield serializers.serialize(
      object.outcome,
      specifiedType: const FullType(AttemptResultOutcomeEnum),
    );
    yield r'repair_action';
    yield serializers.serialize(
      object.repairAction,
      specifiedType: const FullType(AttemptResultRepairActionEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AttemptResult object, {
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
    required AttemptResultBuilder result,
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
        case r'can_complete':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.canComplete = valueDes;
          break;
        case r'explanation':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.explanation = valueDes;
          break;
        case r'explanation_available':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.explanationAvailable = valueDes;
          break;
        case r'feedback':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.feedback = valueDes;
          break;
        case r'grading_status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AttemptResultGradingStatusEnum),
          ) as AttemptResultGradingStatusEnum;
          result.gradingStatus = valueDes;
          break;
        case r'influence_limited':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.influenceLimited = valueDes;
          break;
        case r'next_item_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.nextItemId = valueDes;
          break;
        case r'outcome':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AttemptResultOutcomeEnum),
          ) as AttemptResultOutcomeEnum;
          result.outcome = valueDes;
          break;
        case r'repair_action':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AttemptResultRepairActionEnum),
          ) as AttemptResultRepairActionEnum;
          result.repairAction = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AttemptResult deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AttemptResultBuilder();
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

class AttemptResultGradingStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'graded')
  static const AttemptResultGradingStatusEnum graded =
      _$attemptResultGradingStatusEnum_graded;
  @BuiltValueEnumConst(wireName: r'skipped')
  static const AttemptResultGradingStatusEnum skipped =
      _$attemptResultGradingStatusEnum_skipped;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const AttemptResultGradingStatusEnum unknownDefaultOpenApi =
      _$attemptResultGradingStatusEnum_unknownDefaultOpenApi;

  static Serializer<AttemptResultGradingStatusEnum> get serializer =>
      _$attemptResultGradingStatusEnumSerializer;

  const AttemptResultGradingStatusEnum._(String name) : super(name);

  static BuiltSet<AttemptResultGradingStatusEnum> get values =>
      _$attemptResultGradingStatusEnumValues;
  static AttemptResultGradingStatusEnum valueOf(String name) =>
      _$attemptResultGradingStatusEnumValueOf(name);
}

class AttemptResultOutcomeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'recalled')
  static const AttemptResultOutcomeEnum recalled =
      _$attemptResultOutcomeEnum_recalled;
  @BuiltValueEnumConst(wireName: r'partial')
  static const AttemptResultOutcomeEnum partial =
      _$attemptResultOutcomeEnum_partial;
  @BuiltValueEnumConst(wireName: r'uncertain')
  static const AttemptResultOutcomeEnum uncertain =
      _$attemptResultOutcomeEnum_uncertain;
  @BuiltValueEnumConst(wireName: r'weak')
  static const AttemptResultOutcomeEnum weak = _$attemptResultOutcomeEnum_weak;
  @BuiltValueEnumConst(wireName: r'skipped')
  static const AttemptResultOutcomeEnum skipped =
      _$attemptResultOutcomeEnum_skipped;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const AttemptResultOutcomeEnum unknownDefaultOpenApi =
      _$attemptResultOutcomeEnum_unknownDefaultOpenApi;

  static Serializer<AttemptResultOutcomeEnum> get serializer =>
      _$attemptResultOutcomeEnumSerializer;

  const AttemptResultOutcomeEnum._(String name) : super(name);

  static BuiltSet<AttemptResultOutcomeEnum> get values =>
      _$attemptResultOutcomeEnumValues;
  static AttemptResultOutcomeEnum valueOf(String name) =>
      _$attemptResultOutcomeEnumValueOf(name);
}

class AttemptResultRepairActionEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'none')
  static const AttemptResultRepairActionEnum none =
      _$attemptResultRepairActionEnum_none;
  @BuiltValueEnumConst(wireName: r'repair_inserted')
  static const AttemptResultRepairActionEnum repairInserted =
      _$attemptResultRepairActionEnum_repairInserted;
  @BuiltValueEnumConst(wireName: r'review_concept')
  static const AttemptResultRepairActionEnum reviewConcept =
      _$attemptResultRepairActionEnum_reviewConcept;
  @BuiltValueEnumConst(wireName: r'confirm_or_appeal')
  static const AttemptResultRepairActionEnum confirmOrAppeal =
      _$attemptResultRepairActionEnum_confirmOrAppeal;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const AttemptResultRepairActionEnum unknownDefaultOpenApi =
      _$attemptResultRepairActionEnum_unknownDefaultOpenApi;

  static Serializer<AttemptResultRepairActionEnum> get serializer =>
      _$attemptResultRepairActionEnumSerializer;

  const AttemptResultRepairActionEnum._(String name) : super(name);

  static BuiltSet<AttemptResultRepairActionEnum> get values =>
      _$attemptResultRepairActionEnumValues;
  static AttemptResultRepairActionEnum valueOf(String name) =>
      _$attemptResultRepairActionEnumValueOf(name);
}
