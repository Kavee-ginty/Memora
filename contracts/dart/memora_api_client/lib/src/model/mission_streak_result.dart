//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mission_streak_result.g.dart';

/// MissionStreakResult
///
/// Properties:
/// * [currentDays]
/// * [graceUsed]
/// * [policyVersion]
/// * [qualification]
@BuiltValue()
abstract class MissionStreakResult
    implements Built<MissionStreakResult, MissionStreakResultBuilder> {
  @BuiltValueField(wireName: r'current_days')
  int get currentDays;

  @BuiltValueField(wireName: r'grace_used')
  bool get graceUsed;

  @BuiltValueField(wireName: r'policy_version')
  String get policyVersion;

  @BuiltValueField(wireName: r'qualification')
  MissionStreakResultQualificationEnum get qualification;
  // enum qualificationEnum {  mission_completed,  comeback_completed,  };

  MissionStreakResult._();

  factory MissionStreakResult([void updates(MissionStreakResultBuilder b)]) =
      _$MissionStreakResult;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MissionStreakResultBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MissionStreakResult> get serializer =>
      _$MissionStreakResultSerializer();
}

class _$MissionStreakResultSerializer
    implements PrimitiveSerializer<MissionStreakResult> {
  @override
  final Iterable<Type> types = const [
    MissionStreakResult,
    _$MissionStreakResult
  ];

  @override
  final String wireName = r'MissionStreakResult';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MissionStreakResult object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'current_days';
    yield serializers.serialize(
      object.currentDays,
      specifiedType: const FullType(int),
    );
    yield r'grace_used';
    yield serializers.serialize(
      object.graceUsed,
      specifiedType: const FullType(bool),
    );
    yield r'policy_version';
    yield serializers.serialize(
      object.policyVersion,
      specifiedType: const FullType(String),
    );
    yield r'qualification';
    yield serializers.serialize(
      object.qualification,
      specifiedType: const FullType(MissionStreakResultQualificationEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MissionStreakResult object, {
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
    required MissionStreakResultBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'current_days':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.currentDays = valueDes;
          break;
        case r'grace_used':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.graceUsed = valueDes;
          break;
        case r'policy_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.policyVersion = valueDes;
          break;
        case r'qualification':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MissionStreakResultQualificationEnum),
          ) as MissionStreakResultQualificationEnum;
          result.qualification = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MissionStreakResult deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MissionStreakResultBuilder();
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

class MissionStreakResultQualificationEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'mission_completed')
  static const MissionStreakResultQualificationEnum missionCompleted =
      _$missionStreakResultQualificationEnum_missionCompleted;
  @BuiltValueEnumConst(wireName: r'comeback_completed')
  static const MissionStreakResultQualificationEnum comebackCompleted =
      _$missionStreakResultQualificationEnum_comebackCompleted;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MissionStreakResultQualificationEnum unknownDefaultOpenApi =
      _$missionStreakResultQualificationEnum_unknownDefaultOpenApi;

  static Serializer<MissionStreakResultQualificationEnum> get serializer =>
      _$missionStreakResultQualificationEnumSerializer;

  const MissionStreakResultQualificationEnum._(String name) : super(name);

  static BuiltSet<MissionStreakResultQualificationEnum> get values =>
      _$missionStreakResultQualificationEnumValues;
  static MissionStreakResultQualificationEnum valueOf(String name) =>
      _$missionStreakResultQualificationEnumValueOf(name);
}
