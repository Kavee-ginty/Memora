//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mission_reward_grant.g.dart';

/// MissionRewardGrant
///
/// Properties:
/// * [grantId]
/// * [rewardCode]
@BuiltValue()
abstract class MissionRewardGrant
    implements Built<MissionRewardGrant, MissionRewardGrantBuilder> {
  @BuiltValueField(wireName: r'grant_id')
  String get grantId;

  @BuiltValueField(wireName: r'reward_code')
  String get rewardCode;

  MissionRewardGrant._();

  factory MissionRewardGrant([void updates(MissionRewardGrantBuilder b)]) =
      _$MissionRewardGrant;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MissionRewardGrantBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MissionRewardGrant> get serializer =>
      _$MissionRewardGrantSerializer();
}

class _$MissionRewardGrantSerializer
    implements PrimitiveSerializer<MissionRewardGrant> {
  @override
  final Iterable<Type> types = const [MissionRewardGrant, _$MissionRewardGrant];

  @override
  final String wireName = r'MissionRewardGrant';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MissionRewardGrant object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'grant_id';
    yield serializers.serialize(
      object.grantId,
      specifiedType: const FullType(String),
    );
    yield r'reward_code';
    yield serializers.serialize(
      object.rewardCode,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MissionRewardGrant object, {
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
    required MissionRewardGrantBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'grant_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.grantId = valueDes;
          break;
        case r'reward_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.rewardCode = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MissionRewardGrant deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MissionRewardGrantBuilder();
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
