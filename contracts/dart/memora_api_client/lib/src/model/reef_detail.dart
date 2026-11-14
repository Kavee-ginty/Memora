//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/reward_grant.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'reef_detail.g.dart';

/// ReefDetail
///
/// Properties:
/// * [condition]
/// * [dueMemoryCount]
/// * [healthScore]
/// * [prerequisiteRisk]
/// * [projectedAt]
/// * [projectionVersion]
/// * [recentEvidenceScore]
/// * [rewards]
/// * [sourceWatermark]
/// * [subjectId]
/// * [subjectName]
@BuiltValue()
abstract class ReefDetail implements Built<ReefDetail, ReefDetailBuilder> {
  @BuiltValueField(wireName: r'condition')
  ReefDetailConditionEnum get condition;
  // enum conditionEnum {  new,  thriving,  healthy,  needs_care,  dormant,  };

  @BuiltValueField(wireName: r'due_memory_count')
  int get dueMemoryCount;

  @BuiltValueField(wireName: r'health_score')
  num get healthScore;

  @BuiltValueField(wireName: r'prerequisite_risk')
  num get prerequisiteRisk;

  @BuiltValueField(wireName: r'projected_at')
  String get projectedAt;

  @BuiltValueField(wireName: r'projection_version')
  String get projectionVersion;

  @BuiltValueField(wireName: r'recent_evidence_score')
  num get recentEvidenceScore;

  @BuiltValueField(wireName: r'rewards')
  BuiltList<RewardGrant> get rewards;

  @BuiltValueField(wireName: r'source_watermark')
  String get sourceWatermark;

  @BuiltValueField(wireName: r'subject_id')
  String get subjectId;

  @BuiltValueField(wireName: r'subject_name')
  String get subjectName;

  ReefDetail._();

  factory ReefDetail([void updates(ReefDetailBuilder b)]) = _$ReefDetail;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReefDetailBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReefDetail> get serializer => _$ReefDetailSerializer();
}

class _$ReefDetailSerializer implements PrimitiveSerializer<ReefDetail> {
  @override
  final Iterable<Type> types = const [ReefDetail, _$ReefDetail];

  @override
  final String wireName = r'ReefDetail';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReefDetail object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'condition';
    yield serializers.serialize(
      object.condition,
      specifiedType: const FullType(ReefDetailConditionEnum),
    );
    yield r'due_memory_count';
    yield serializers.serialize(
      object.dueMemoryCount,
      specifiedType: const FullType(int),
    );
    yield r'health_score';
    yield serializers.serialize(
      object.healthScore,
      specifiedType: const FullType(num),
    );
    yield r'prerequisite_risk';
    yield serializers.serialize(
      object.prerequisiteRisk,
      specifiedType: const FullType(num),
    );
    yield r'projected_at';
    yield serializers.serialize(
      object.projectedAt,
      specifiedType: const FullType(String),
    );
    yield r'projection_version';
    yield serializers.serialize(
      object.projectionVersion,
      specifiedType: const FullType(String),
    );
    yield r'recent_evidence_score';
    yield serializers.serialize(
      object.recentEvidenceScore,
      specifiedType: const FullType(num),
    );
    yield r'rewards';
    yield serializers.serialize(
      object.rewards,
      specifiedType: const FullType(BuiltList, [FullType(RewardGrant)]),
    );
    yield r'source_watermark';
    yield serializers.serialize(
      object.sourceWatermark,
      specifiedType: const FullType(String),
    );
    yield r'subject_id';
    yield serializers.serialize(
      object.subjectId,
      specifiedType: const FullType(String),
    );
    yield r'subject_name';
    yield serializers.serialize(
      object.subjectName,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ReefDetail object, {
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
    required ReefDetailBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'condition':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ReefDetailConditionEnum),
          ) as ReefDetailConditionEnum;
          result.condition = valueDes;
          break;
        case r'due_memory_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.dueMemoryCount = valueDes;
          break;
        case r'health_score':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.healthScore = valueDes;
          break;
        case r'prerequisite_risk':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.prerequisiteRisk = valueDes;
          break;
        case r'projected_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.projectedAt = valueDes;
          break;
        case r'projection_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.projectionVersion = valueDes;
          break;
        case r'recent_evidence_score':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.recentEvidenceScore = valueDes;
          break;
        case r'rewards':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(RewardGrant)]),
          ) as BuiltList<RewardGrant>;
          result.rewards.replace(valueDes);
          break;
        case r'source_watermark':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.sourceWatermark = valueDes;
          break;
        case r'subject_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.subjectId = valueDes;
          break;
        case r'subject_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.subjectName = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReefDetail deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReefDetailBuilder();
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

class ReefDetailConditionEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'new')
  static const ReefDetailConditionEnum new_ = _$reefDetailConditionEnum_new_;
  @BuiltValueEnumConst(wireName: r'thriving')
  static const ReefDetailConditionEnum thriving =
      _$reefDetailConditionEnum_thriving;
  @BuiltValueEnumConst(wireName: r'healthy')
  static const ReefDetailConditionEnum healthy =
      _$reefDetailConditionEnum_healthy;
  @BuiltValueEnumConst(wireName: r'needs_care')
  static const ReefDetailConditionEnum needsCare =
      _$reefDetailConditionEnum_needsCare;
  @BuiltValueEnumConst(wireName: r'dormant')
  static const ReefDetailConditionEnum dormant =
      _$reefDetailConditionEnum_dormant;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ReefDetailConditionEnum unknownDefaultOpenApi =
      _$reefDetailConditionEnum_unknownDefaultOpenApi;

  static Serializer<ReefDetailConditionEnum> get serializer =>
      _$reefDetailConditionEnumSerializer;

  const ReefDetailConditionEnum._(String name) : super(name);

  static BuiltSet<ReefDetailConditionEnum> get values =>
      _$reefDetailConditionEnumValues;
  static ReefDetailConditionEnum valueOf(String name) =>
      _$reefDetailConditionEnumValueOf(name);
}
