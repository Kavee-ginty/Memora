//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mission_reef_result.g.dart';

/// MissionReefResult
///
/// Properties:
/// * [condition]
/// * [dueMemoryCount]
/// * [healthScore]
/// * [projectedAt]
/// * [projectionVersion]
/// * [sourceWatermark]
/// * [subjectId]
@BuiltValue()
abstract class MissionReefResult
    implements Built<MissionReefResult, MissionReefResultBuilder> {
  @BuiltValueField(wireName: r'condition')
  MissionReefResultConditionEnum get condition;
  // enum conditionEnum {  new,  thriving,  healthy,  needs_care,  dormant,  };

  @BuiltValueField(wireName: r'due_memory_count')
  int get dueMemoryCount;

  @BuiltValueField(wireName: r'health_score')
  num get healthScore;

  @BuiltValueField(wireName: r'projected_at')
  String get projectedAt;

  @BuiltValueField(wireName: r'projection_version')
  String get projectionVersion;

  @BuiltValueField(wireName: r'source_watermark')
  String get sourceWatermark;

  @BuiltValueField(wireName: r'subject_id')
  String get subjectId;

  MissionReefResult._();

  factory MissionReefResult([void updates(MissionReefResultBuilder b)]) =
      _$MissionReefResult;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MissionReefResultBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MissionReefResult> get serializer =>
      _$MissionReefResultSerializer();
}

class _$MissionReefResultSerializer
    implements PrimitiveSerializer<MissionReefResult> {
  @override
  final Iterable<Type> types = const [MissionReefResult, _$MissionReefResult];

  @override
  final String wireName = r'MissionReefResult';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MissionReefResult object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'condition';
    yield serializers.serialize(
      object.condition,
      specifiedType: const FullType(MissionReefResultConditionEnum),
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
  }

  @override
  Object serialize(
    Serializers serializers,
    MissionReefResult object, {
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
    required MissionReefResultBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'condition':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MissionReefResultConditionEnum),
          ) as MissionReefResultConditionEnum;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MissionReefResult deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MissionReefResultBuilder();
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

class MissionReefResultConditionEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'new')
  static const MissionReefResultConditionEnum new_ =
      _$missionReefResultConditionEnum_new_;
  @BuiltValueEnumConst(wireName: r'thriving')
  static const MissionReefResultConditionEnum thriving =
      _$missionReefResultConditionEnum_thriving;
  @BuiltValueEnumConst(wireName: r'healthy')
  static const MissionReefResultConditionEnum healthy =
      _$missionReefResultConditionEnum_healthy;
  @BuiltValueEnumConst(wireName: r'needs_care')
  static const MissionReefResultConditionEnum needsCare =
      _$missionReefResultConditionEnum_needsCare;
  @BuiltValueEnumConst(wireName: r'dormant')
  static const MissionReefResultConditionEnum dormant =
      _$missionReefResultConditionEnum_dormant;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MissionReefResultConditionEnum unknownDefaultOpenApi =
      _$missionReefResultConditionEnum_unknownDefaultOpenApi;

  static Serializer<MissionReefResultConditionEnum> get serializer =>
      _$missionReefResultConditionEnumSerializer;

  const MissionReefResultConditionEnum._(String name) : super(name);

  static BuiltSet<MissionReefResultConditionEnum> get values =>
      _$missionReefResultConditionEnumValues;
  static MissionReefResultConditionEnum valueOf(String name) =>
      _$missionReefResultConditionEnumValueOf(name);
}
