//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'reward_grant.g.dart';

/// RewardGrant
///
/// Properties:
/// * [assetKey]
/// * [grantId]
/// * [grantedAt]
/// * [permittedActions]
/// * [placedSubjectId]
/// * [placementSlot]
/// * [placementState]
/// * [rewardCode]
/// * [rewardType]
/// * [title]
/// * [version]
@BuiltValue()
abstract class RewardGrant implements Built<RewardGrant, RewardGrantBuilder> {
  @BuiltValueField(wireName: r'asset_key')
  String get assetKey;

  @BuiltValueField(wireName: r'grant_id')
  String get grantId;

  @BuiltValueField(wireName: r'granted_at')
  String get grantedAt;

  @BuiltValueField(wireName: r'permitted_actions')
  BuiltList<RewardGrantPermittedActionsEnum> get permittedActions;
  // enum permittedActionsEnum {  place,  move,  remove,  };

  @BuiltValueField(wireName: r'placed_subject_id')
  String? get placedSubjectId;

  @BuiltValueField(wireName: r'placement_slot')
  String? get placementSlot;

  @BuiltValueField(wireName: r'placement_state')
  RewardGrantPlacementStateEnum get placementState;
  // enum placementStateEnum {  unplaced,  placed,  };

  @BuiltValueField(wireName: r'reward_code')
  String get rewardCode;

  @BuiltValueField(wireName: r'reward_type')
  RewardGrantRewardTypeEnum get rewardType;
  // enum rewardTypeEnum {  decoration,  mora_cosmetic,  };

  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'version')
  int get version;

  RewardGrant._();

  factory RewardGrant([void updates(RewardGrantBuilder b)]) = _$RewardGrant;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RewardGrantBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RewardGrant> get serializer => _$RewardGrantSerializer();
}

class _$RewardGrantSerializer implements PrimitiveSerializer<RewardGrant> {
  @override
  final Iterable<Type> types = const [RewardGrant, _$RewardGrant];

  @override
  final String wireName = r'RewardGrant';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RewardGrant object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'asset_key';
    yield serializers.serialize(
      object.assetKey,
      specifiedType: const FullType(String),
    );
    yield r'grant_id';
    yield serializers.serialize(
      object.grantId,
      specifiedType: const FullType(String),
    );
    yield r'granted_at';
    yield serializers.serialize(
      object.grantedAt,
      specifiedType: const FullType(String),
    );
    yield r'permitted_actions';
    yield serializers.serialize(
      object.permittedActions,
      specifiedType: const FullType(
          BuiltList, [FullType(RewardGrantPermittedActionsEnum)]),
    );
    yield r'placed_subject_id';
    yield object.placedSubjectId == null
        ? null
        : serializers.serialize(
            object.placedSubjectId,
            specifiedType: const FullType.nullable(String),
          );
    yield r'placement_slot';
    yield object.placementSlot == null
        ? null
        : serializers.serialize(
            object.placementSlot,
            specifiedType: const FullType.nullable(String),
          );
    yield r'placement_state';
    yield serializers.serialize(
      object.placementState,
      specifiedType: const FullType(RewardGrantPlacementStateEnum),
    );
    yield r'reward_code';
    yield serializers.serialize(
      object.rewardCode,
      specifiedType: const FullType(String),
    );
    yield r'reward_type';
    yield serializers.serialize(
      object.rewardType,
      specifiedType: const FullType(RewardGrantRewardTypeEnum),
    );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    yield r'version';
    yield serializers.serialize(
      object.version,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RewardGrant object, {
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
    required RewardGrantBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'asset_key':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.assetKey = valueDes;
          break;
        case r'grant_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.grantId = valueDes;
          break;
        case r'granted_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.grantedAt = valueDes;
          break;
        case r'permitted_actions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(
                BuiltList, [FullType(RewardGrantPermittedActionsEnum)]),
          ) as BuiltList<RewardGrantPermittedActionsEnum>;
          result.permittedActions.replace(valueDes);
          break;
        case r'placed_subject_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.placedSubjectId = valueDes;
          break;
        case r'placement_slot':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.placementSlot = valueDes;
          break;
        case r'placement_state':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RewardGrantPlacementStateEnum),
          ) as RewardGrantPlacementStateEnum;
          result.placementState = valueDes;
          break;
        case r'reward_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.rewardCode = valueDes;
          break;
        case r'reward_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RewardGrantRewardTypeEnum),
          ) as RewardGrantRewardTypeEnum;
          result.rewardType = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.version = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RewardGrant deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RewardGrantBuilder();
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

class RewardGrantPermittedActionsEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'place')
  static const RewardGrantPermittedActionsEnum place =
      _$rewardGrantPermittedActionsEnum_place;
  @BuiltValueEnumConst(wireName: r'move')
  static const RewardGrantPermittedActionsEnum move =
      _$rewardGrantPermittedActionsEnum_move;
  @BuiltValueEnumConst(wireName: r'remove')
  static const RewardGrantPermittedActionsEnum remove =
      _$rewardGrantPermittedActionsEnum_remove;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const RewardGrantPermittedActionsEnum unknownDefaultOpenApi =
      _$rewardGrantPermittedActionsEnum_unknownDefaultOpenApi;

  static Serializer<RewardGrantPermittedActionsEnum> get serializer =>
      _$rewardGrantPermittedActionsEnumSerializer;

  const RewardGrantPermittedActionsEnum._(String name) : super(name);

  static BuiltSet<RewardGrantPermittedActionsEnum> get values =>
      _$rewardGrantPermittedActionsEnumValues;
  static RewardGrantPermittedActionsEnum valueOf(String name) =>
      _$rewardGrantPermittedActionsEnumValueOf(name);
}

class RewardGrantPlacementStateEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'unplaced')
  static const RewardGrantPlacementStateEnum unplaced =
      _$rewardGrantPlacementStateEnum_unplaced;
  @BuiltValueEnumConst(wireName: r'placed')
  static const RewardGrantPlacementStateEnum placed =
      _$rewardGrantPlacementStateEnum_placed;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const RewardGrantPlacementStateEnum unknownDefaultOpenApi =
      _$rewardGrantPlacementStateEnum_unknownDefaultOpenApi;

  static Serializer<RewardGrantPlacementStateEnum> get serializer =>
      _$rewardGrantPlacementStateEnumSerializer;

  const RewardGrantPlacementStateEnum._(String name) : super(name);

  static BuiltSet<RewardGrantPlacementStateEnum> get values =>
      _$rewardGrantPlacementStateEnumValues;
  static RewardGrantPlacementStateEnum valueOf(String name) =>
      _$rewardGrantPlacementStateEnumValueOf(name);
}

class RewardGrantRewardTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'decoration')
  static const RewardGrantRewardTypeEnum decoration =
      _$rewardGrantRewardTypeEnum_decoration;
  @BuiltValueEnumConst(wireName: r'mora_cosmetic')
  static const RewardGrantRewardTypeEnum moraCosmetic =
      _$rewardGrantRewardTypeEnum_moraCosmetic;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const RewardGrantRewardTypeEnum unknownDefaultOpenApi =
      _$rewardGrantRewardTypeEnum_unknownDefaultOpenApi;

  static Serializer<RewardGrantRewardTypeEnum> get serializer =>
      _$rewardGrantRewardTypeEnumSerializer;

  const RewardGrantRewardTypeEnum._(String name) : super(name);

  static BuiltSet<RewardGrantRewardTypeEnum> get values =>
      _$rewardGrantRewardTypeEnumValues;
  static RewardGrantRewardTypeEnum valueOf(String name) =>
      _$rewardGrantRewardTypeEnumValueOf(name);
}
