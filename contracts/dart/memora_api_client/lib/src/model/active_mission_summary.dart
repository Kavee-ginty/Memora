//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'active_mission_summary.g.dart';

/// ActiveMissionSummary
///
/// Properties:
/// * [id]
/// * [missionDate]
/// * [status]
/// * [subjectId]
@BuiltValue()
abstract class ActiveMissionSummary
    implements Built<ActiveMissionSummary, ActiveMissionSummaryBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'mission_date')
  Date get missionDate;

  @BuiltValueField(wireName: r'status')
  ActiveMissionSummaryStatusEnum get status;
  // enum statusEnum {  planned,  started,  paused,  };

  @BuiltValueField(wireName: r'subject_id')
  String get subjectId;

  ActiveMissionSummary._();

  factory ActiveMissionSummary([void updates(ActiveMissionSummaryBuilder b)]) =
      _$ActiveMissionSummary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ActiveMissionSummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ActiveMissionSummary> get serializer =>
      _$ActiveMissionSummarySerializer();
}

class _$ActiveMissionSummarySerializer
    implements PrimitiveSerializer<ActiveMissionSummary> {
  @override
  final Iterable<Type> types = const [
    ActiveMissionSummary,
    _$ActiveMissionSummary
  ];

  @override
  final String wireName = r'ActiveMissionSummary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ActiveMissionSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'mission_date';
    yield serializers.serialize(
      object.missionDate,
      specifiedType: const FullType(Date),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(ActiveMissionSummaryStatusEnum),
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
    ActiveMissionSummary object, {
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
    required ActiveMissionSummaryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'mission_date':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.missionDate = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ActiveMissionSummaryStatusEnum),
          ) as ActiveMissionSummaryStatusEnum;
          result.status = valueDes;
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
  ActiveMissionSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ActiveMissionSummaryBuilder();
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

class ActiveMissionSummaryStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'planned')
  static const ActiveMissionSummaryStatusEnum planned =
      _$activeMissionSummaryStatusEnum_planned;
  @BuiltValueEnumConst(wireName: r'started')
  static const ActiveMissionSummaryStatusEnum started =
      _$activeMissionSummaryStatusEnum_started;
  @BuiltValueEnumConst(wireName: r'paused')
  static const ActiveMissionSummaryStatusEnum paused =
      _$activeMissionSummaryStatusEnum_paused;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ActiveMissionSummaryStatusEnum unknownDefaultOpenApi =
      _$activeMissionSummaryStatusEnum_unknownDefaultOpenApi;

  static Serializer<ActiveMissionSummaryStatusEnum> get serializer =>
      _$activeMissionSummaryStatusEnumSerializer;

  const ActiveMissionSummaryStatusEnum._(String name) : super(name);

  static BuiltSet<ActiveMissionSummaryStatusEnum> get values =>
      _$activeMissionSummaryStatusEnumValues;
  static ActiveMissionSummaryStatusEnum valueOf(String name) =>
      _$activeMissionSummaryStatusEnumValueOf(name);
}
