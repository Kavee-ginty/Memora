//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'seabed_reef.g.dart';

/// SeabedReef
///
/// Properties:
/// * [condition]
/// * [dueMemoryCount]
/// * [healthScore]
/// * [prerequisiteRisk]
/// * [projectedAt]
/// * [projectionVersion]
/// * [recentEvidenceScore]
/// * [sourceWatermark]
/// * [subjectId]
/// * [subjectName]
@BuiltValue()
abstract class SeabedReef implements Built<SeabedReef, SeabedReefBuilder> {
  @BuiltValueField(wireName: r'condition')
  SeabedReefConditionEnum get condition;
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

  @BuiltValueField(wireName: r'source_watermark')
  String get sourceWatermark;

  @BuiltValueField(wireName: r'subject_id')
  String get subjectId;

  @BuiltValueField(wireName: r'subject_name')
  String get subjectName;

  SeabedReef._();

  factory SeabedReef([void updates(SeabedReefBuilder b)]) = _$SeabedReef;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SeabedReefBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SeabedReef> get serializer => _$SeabedReefSerializer();
}

class _$SeabedReefSerializer implements PrimitiveSerializer<SeabedReef> {
  @override
  final Iterable<Type> types = const [SeabedReef, _$SeabedReef];

  @override
  final String wireName = r'SeabedReef';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SeabedReef object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'condition';
    yield serializers.serialize(
      object.condition,
      specifiedType: const FullType(SeabedReefConditionEnum),
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
    SeabedReef object, {
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
    required SeabedReefBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'condition':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(SeabedReefConditionEnum),
          ) as SeabedReefConditionEnum;
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
  SeabedReef deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SeabedReefBuilder();
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

class SeabedReefConditionEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'new')
  static const SeabedReefConditionEnum new_ = _$seabedReefConditionEnum_new_;
  @BuiltValueEnumConst(wireName: r'thriving')
  static const SeabedReefConditionEnum thriving =
      _$seabedReefConditionEnum_thriving;
  @BuiltValueEnumConst(wireName: r'healthy')
  static const SeabedReefConditionEnum healthy =
      _$seabedReefConditionEnum_healthy;
  @BuiltValueEnumConst(wireName: r'needs_care')
  static const SeabedReefConditionEnum needsCare =
      _$seabedReefConditionEnum_needsCare;
  @BuiltValueEnumConst(wireName: r'dormant')
  static const SeabedReefConditionEnum dormant =
      _$seabedReefConditionEnum_dormant;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const SeabedReefConditionEnum unknownDefaultOpenApi =
      _$seabedReefConditionEnum_unknownDefaultOpenApi;

  static Serializer<SeabedReefConditionEnum> get serializer =>
      _$seabedReefConditionEnumSerializer;

  const SeabedReefConditionEnum._(String name) : super(name);

  static BuiltSet<SeabedReefConditionEnum> get values =>
      _$seabedReefConditionEnumValues;
  static SeabedReefConditionEnum valueOf(String name) =>
      _$seabedReefConditionEnumValueOf(name);
}
