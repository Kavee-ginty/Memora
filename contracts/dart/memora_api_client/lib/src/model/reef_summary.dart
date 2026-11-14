//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'reef_summary.g.dart';

/// ReefSummary
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
abstract class ReefSummary implements Built<ReefSummary, ReefSummaryBuilder> {
  @BuiltValueField(wireName: r'condition')
  ReefSummaryConditionEnum get condition;
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

  ReefSummary._();

  factory ReefSummary([void updates(ReefSummaryBuilder b)]) = _$ReefSummary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReefSummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReefSummary> get serializer => _$ReefSummarySerializer();
}

class _$ReefSummarySerializer implements PrimitiveSerializer<ReefSummary> {
  @override
  final Iterable<Type> types = const [ReefSummary, _$ReefSummary];

  @override
  final String wireName = r'ReefSummary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReefSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'condition';
    yield serializers.serialize(
      object.condition,
      specifiedType: const FullType(ReefSummaryConditionEnum),
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
    ReefSummary object, {
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
    required ReefSummaryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'condition':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ReefSummaryConditionEnum),
          ) as ReefSummaryConditionEnum;
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
  ReefSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReefSummaryBuilder();
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

class ReefSummaryConditionEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'new')
  static const ReefSummaryConditionEnum new_ = _$reefSummaryConditionEnum_new_;
  @BuiltValueEnumConst(wireName: r'thriving')
  static const ReefSummaryConditionEnum thriving =
      _$reefSummaryConditionEnum_thriving;
  @BuiltValueEnumConst(wireName: r'healthy')
  static const ReefSummaryConditionEnum healthy =
      _$reefSummaryConditionEnum_healthy;
  @BuiltValueEnumConst(wireName: r'needs_care')
  static const ReefSummaryConditionEnum needsCare =
      _$reefSummaryConditionEnum_needsCare;
  @BuiltValueEnumConst(wireName: r'dormant')
  static const ReefSummaryConditionEnum dormant =
      _$reefSummaryConditionEnum_dormant;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ReefSummaryConditionEnum unknownDefaultOpenApi =
      _$reefSummaryConditionEnum_unknownDefaultOpenApi;

  static Serializer<ReefSummaryConditionEnum> get serializer =>
      _$reefSummaryConditionEnumSerializer;

  const ReefSummaryConditionEnum._(String name) : super(name);

  static BuiltSet<ReefSummaryConditionEnum> get values =>
      _$reefSummaryConditionEnumValues;
  static ReefSummaryConditionEnum valueOf(String name) =>
      _$reefSummaryConditionEnumValueOf(name);
}
