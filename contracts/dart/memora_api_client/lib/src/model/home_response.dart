//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/home_mission.dart';
import 'package:memora_api_client/src/model/reef_summary.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'home_response.g.dart';

/// HomeResponse
///
/// Properties:
/// * [mission]
/// * [reef]
/// * [serverTime]
/// * [state]
/// * [streakDays]
/// * [xpBalance]
@BuiltValue()
abstract class HomeResponse
    implements Built<HomeResponse, HomeResponseBuilder> {
  @BuiltValueField(wireName: r'mission')
  HomeMission? get mission;

  @BuiltValueField(wireName: r'reef')
  ReefSummary? get reef;

  @BuiltValueField(wireName: r'server_time')
  String get serverTime;

  @BuiltValueField(wireName: r'state')
  HomeResponseStateEnum get state;
  // enum stateEnum {  setup,  mission_ready,  mission_in_progress,  mission_complete,  cared_for,  };

  @BuiltValueField(wireName: r'streak_days')
  int get streakDays;

  @BuiltValueField(wireName: r'xp_balance')
  int get xpBalance;

  HomeResponse._();

  factory HomeResponse([void updates(HomeResponseBuilder b)]) = _$HomeResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(HomeResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<HomeResponse> get serializer => _$HomeResponseSerializer();
}

class _$HomeResponseSerializer implements PrimitiveSerializer<HomeResponse> {
  @override
  final Iterable<Type> types = const [HomeResponse, _$HomeResponse];

  @override
  final String wireName = r'HomeResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    HomeResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'mission';
    yield object.mission == null
        ? null
        : serializers.serialize(
            object.mission,
            specifiedType: const FullType.nullable(HomeMission),
          );
    yield r'reef';
    yield object.reef == null
        ? null
        : serializers.serialize(
            object.reef,
            specifiedType: const FullType.nullable(ReefSummary),
          );
    yield r'server_time';
    yield serializers.serialize(
      object.serverTime,
      specifiedType: const FullType(String),
    );
    yield r'state';
    yield serializers.serialize(
      object.state,
      specifiedType: const FullType(HomeResponseStateEnum),
    );
    yield r'streak_days';
    yield serializers.serialize(
      object.streakDays,
      specifiedType: const FullType(int),
    );
    yield r'xp_balance';
    yield serializers.serialize(
      object.xpBalance,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    HomeResponse object, {
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
    required HomeResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'mission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(HomeMission),
          ) as HomeMission?;
          if (valueDes == null) continue;
          result.mission.replace(valueDes);
          break;
        case r'reef':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(ReefSummary),
          ) as ReefSummary?;
          if (valueDes == null) continue;
          result.reef.replace(valueDes);
          break;
        case r'server_time':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.serverTime = valueDes;
          break;
        case r'state':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(HomeResponseStateEnum),
          ) as HomeResponseStateEnum;
          result.state = valueDes;
          break;
        case r'streak_days':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.streakDays = valueDes;
          break;
        case r'xp_balance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.xpBalance = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  HomeResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = HomeResponseBuilder();
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

class HomeResponseStateEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'setup')
  static const HomeResponseStateEnum setup = _$homeResponseStateEnum_setup;
  @BuiltValueEnumConst(wireName: r'mission_ready')
  static const HomeResponseStateEnum missionReady =
      _$homeResponseStateEnum_missionReady;
  @BuiltValueEnumConst(wireName: r'mission_in_progress')
  static const HomeResponseStateEnum missionInProgress =
      _$homeResponseStateEnum_missionInProgress;
  @BuiltValueEnumConst(wireName: r'mission_complete')
  static const HomeResponseStateEnum missionComplete =
      _$homeResponseStateEnum_missionComplete;
  @BuiltValueEnumConst(wireName: r'cared_for')
  static const HomeResponseStateEnum caredFor =
      _$homeResponseStateEnum_caredFor;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const HomeResponseStateEnum unknownDefaultOpenApi =
      _$homeResponseStateEnum_unknownDefaultOpenApi;

  static Serializer<HomeResponseStateEnum> get serializer =>
      _$homeResponseStateEnumSerializer;

  const HomeResponseStateEnum._(String name) : super(name);

  static BuiltSet<HomeResponseStateEnum> get values =>
      _$homeResponseStateEnumValues;
  static HomeResponseStateEnum valueOf(String name) =>
      _$homeResponseStateEnumValueOf(name);
}
