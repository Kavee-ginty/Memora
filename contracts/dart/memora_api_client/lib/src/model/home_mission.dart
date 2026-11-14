//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/date.dart';
import 'package:memora_api_client/src/model/mission_completion_result.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'home_mission.g.dart';

/// HomeMission
///
/// Properties:
/// * [completionSummary]
/// * [estimatedMinutes]
/// * [id]
/// * [missionDate]
/// * [plannedItemCount]
/// * [status]
/// * [subjectId]
@BuiltValue()
abstract class HomeMission implements Built<HomeMission, HomeMissionBuilder> {
  @BuiltValueField(wireName: r'completion_summary')
  Optional<MissionCompletionResult?> get completionSummary;

  @BuiltValueField(wireName: r'estimated_minutes')
  int get estimatedMinutes;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'mission_date')
  Date get missionDate;

  @BuiltValueField(wireName: r'planned_item_count')
  int get plannedItemCount;

  @BuiltValueField(wireName: r'status')
  HomeMissionStatusEnum get status;
  // enum statusEnum {  planned,  started,  paused,  completed,  expired,  abandoned,  };

  @BuiltValueField(wireName: r'subject_id')
  String get subjectId;

  HomeMission._();

  factory HomeMission([void updates(HomeMissionBuilder b)]) = _$HomeMission;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(HomeMissionBuilder b) =>
      b..completionSummary = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<HomeMission> get serializer => _$HomeMissionSerializer();
}

class _$HomeMissionSerializer implements PrimitiveSerializer<HomeMission> {
  @override
  final Iterable<Type> types = const [HomeMission, _$HomeMission];

  @override
  final String wireName = r'HomeMission';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    HomeMission object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.completionSummary.isPresent) {
      yield r'completion_summary';
      final optionalValue = object.completionSummary.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(MissionCompletionResult),
        );
      }
    }
    yield r'estimated_minutes';
    yield serializers.serialize(
      object.estimatedMinutes,
      specifiedType: const FullType(int),
    );
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
    yield r'planned_item_count';
    yield serializers.serialize(
      object.plannedItemCount,
      specifiedType: const FullType(int),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(HomeMissionStatusEnum),
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
    HomeMission object, {
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
    required HomeMissionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'completion_summary':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(MissionCompletionResult),
          ) as MissionCompletionResult?;
          result.completionSummary = Optional.present(valueDes);
          break;
        case r'estimated_minutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.estimatedMinutes = valueDes;
          break;
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
        case r'planned_item_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.plannedItemCount = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(HomeMissionStatusEnum),
          ) as HomeMissionStatusEnum;
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
  HomeMission deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = HomeMissionBuilder();
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

class HomeMissionStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'planned')
  static const HomeMissionStatusEnum planned = _$homeMissionStatusEnum_planned;
  @BuiltValueEnumConst(wireName: r'started')
  static const HomeMissionStatusEnum started = _$homeMissionStatusEnum_started;
  @BuiltValueEnumConst(wireName: r'paused')
  static const HomeMissionStatusEnum paused = _$homeMissionStatusEnum_paused;
  @BuiltValueEnumConst(wireName: r'completed')
  static const HomeMissionStatusEnum completed =
      _$homeMissionStatusEnum_completed;
  @BuiltValueEnumConst(wireName: r'expired')
  static const HomeMissionStatusEnum expired = _$homeMissionStatusEnum_expired;
  @BuiltValueEnumConst(wireName: r'abandoned')
  static const HomeMissionStatusEnum abandoned =
      _$homeMissionStatusEnum_abandoned;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const HomeMissionStatusEnum unknownDefaultOpenApi =
      _$homeMissionStatusEnum_unknownDefaultOpenApi;

  static Serializer<HomeMissionStatusEnum> get serializer =>
      _$homeMissionStatusEnumSerializer;

  const HomeMissionStatusEnum._(String name) : super(name);

  static BuiltSet<HomeMissionStatusEnum> get values =>
      _$homeMissionStatusEnumValues;
  static HomeMissionStatusEnum valueOf(String name) =>
      _$homeMissionStatusEnumValueOf(name);
}
