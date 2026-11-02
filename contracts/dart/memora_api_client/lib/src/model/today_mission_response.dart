//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/mission_summary.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'today_mission_response.g.dart';

/// TodayMissionResponse
///
/// Properties:
/// * [mission]
/// * [state]
@BuiltValue()
abstract class TodayMissionResponse
    implements Built<TodayMissionResponse, TodayMissionResponseBuilder> {
  @BuiltValueField(wireName: r'mission')
  MissionSummary? get mission;

  @BuiltValueField(wireName: r'state')
  TodayMissionResponseStateEnum get state;
  // enum stateEnum {  no_due,  mission_ready,  mission_in_progress,  mission_complete,  };

  TodayMissionResponse._();

  factory TodayMissionResponse([void updates(TodayMissionResponseBuilder b)]) =
      _$TodayMissionResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TodayMissionResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TodayMissionResponse> get serializer =>
      _$TodayMissionResponseSerializer();
}

class _$TodayMissionResponseSerializer
    implements PrimitiveSerializer<TodayMissionResponse> {
  @override
  final Iterable<Type> types = const [
    TodayMissionResponse,
    _$TodayMissionResponse
  ];

  @override
  final String wireName = r'TodayMissionResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TodayMissionResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'mission';
    yield object.mission == null
        ? null
        : serializers.serialize(
            object.mission,
            specifiedType: const FullType.nullable(MissionSummary),
          );
    yield r'state';
    yield serializers.serialize(
      object.state,
      specifiedType: const FullType(TodayMissionResponseStateEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TodayMissionResponse object, {
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
    required TodayMissionResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'mission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(MissionSummary),
          ) as MissionSummary?;
          if (valueDes == null) continue;
          result.mission.replace(valueDes);
          break;
        case r'state':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TodayMissionResponseStateEnum),
          ) as TodayMissionResponseStateEnum;
          result.state = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TodayMissionResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TodayMissionResponseBuilder();
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

class TodayMissionResponseStateEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'no_due')
  static const TodayMissionResponseStateEnum noDue =
      _$todayMissionResponseStateEnum_noDue;
  @BuiltValueEnumConst(wireName: r'mission_ready')
  static const TodayMissionResponseStateEnum missionReady =
      _$todayMissionResponseStateEnum_missionReady;
  @BuiltValueEnumConst(wireName: r'mission_in_progress')
  static const TodayMissionResponseStateEnum missionInProgress =
      _$todayMissionResponseStateEnum_missionInProgress;
  @BuiltValueEnumConst(wireName: r'mission_complete')
  static const TodayMissionResponseStateEnum missionComplete =
      _$todayMissionResponseStateEnum_missionComplete;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const TodayMissionResponseStateEnum unknownDefaultOpenApi =
      _$todayMissionResponseStateEnum_unknownDefaultOpenApi;

  static Serializer<TodayMissionResponseStateEnum> get serializer =>
      _$todayMissionResponseStateEnumSerializer;

  const TodayMissionResponseStateEnum._(String name) : super(name);

  static BuiltSet<TodayMissionResponseStateEnum> get values =>
      _$todayMissionResponseStateEnumValues;
  static TodayMissionResponseStateEnum valueOf(String name) =>
      _$todayMissionResponseStateEnumValueOf(name);
}
