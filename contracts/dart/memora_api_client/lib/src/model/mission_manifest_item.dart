//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mission_manifest_item.g.dart';

/// MissionManifestItem
///
/// Properties:
/// * [id]
/// * [missionType]
/// * [position]
/// * [questionType]
/// * [status]
@BuiltValue()
abstract class MissionManifestItem
    implements Built<MissionManifestItem, MissionManifestItemBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'mission_type')
  MissionManifestItemMissionTypeEnum get missionType;
  // enum missionTypeEnum {  protect,  repair,  recover,  discover,  challenge,  };

  @BuiltValueField(wireName: r'position')
  int get position;

  @BuiltValueField(wireName: r'question_type')
  MissionManifestItemQuestionTypeEnum get questionType;
  // enum questionTypeEnum {  single_choice,  multiple_choice,  numeric,  };

  @BuiltValueField(wireName: r'status')
  MissionManifestItemStatusEnum get status;
  // enum statusEnum {  pending,  presented,  answered,  skipped,  cancelled,  };

  MissionManifestItem._();

  factory MissionManifestItem([void updates(MissionManifestItemBuilder b)]) =
      _$MissionManifestItem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MissionManifestItemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MissionManifestItem> get serializer =>
      _$MissionManifestItemSerializer();
}

class _$MissionManifestItemSerializer
    implements PrimitiveSerializer<MissionManifestItem> {
  @override
  final Iterable<Type> types = const [
    MissionManifestItem,
    _$MissionManifestItem
  ];

  @override
  final String wireName = r'MissionManifestItem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MissionManifestItem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'mission_type';
    yield serializers.serialize(
      object.missionType,
      specifiedType: const FullType(MissionManifestItemMissionTypeEnum),
    );
    yield r'position';
    yield serializers.serialize(
      object.position,
      specifiedType: const FullType(int),
    );
    yield r'question_type';
    yield serializers.serialize(
      object.questionType,
      specifiedType: const FullType(MissionManifestItemQuestionTypeEnum),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(MissionManifestItemStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MissionManifestItem object, {
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
    required MissionManifestItemBuilder result,
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
        case r'mission_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MissionManifestItemMissionTypeEnum),
          ) as MissionManifestItemMissionTypeEnum;
          result.missionType = valueDes;
          break;
        case r'position':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.position = valueDes;
          break;
        case r'question_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MissionManifestItemQuestionTypeEnum),
          ) as MissionManifestItemQuestionTypeEnum;
          result.questionType = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MissionManifestItemStatusEnum),
          ) as MissionManifestItemStatusEnum;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MissionManifestItem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MissionManifestItemBuilder();
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

class MissionManifestItemMissionTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'protect')
  static const MissionManifestItemMissionTypeEnum protect =
      _$missionManifestItemMissionTypeEnum_protect;
  @BuiltValueEnumConst(wireName: r'repair')
  static const MissionManifestItemMissionTypeEnum repair =
      _$missionManifestItemMissionTypeEnum_repair;
  @BuiltValueEnumConst(wireName: r'recover')
  static const MissionManifestItemMissionTypeEnum recover =
      _$missionManifestItemMissionTypeEnum_recover;
  @BuiltValueEnumConst(wireName: r'discover')
  static const MissionManifestItemMissionTypeEnum discover =
      _$missionManifestItemMissionTypeEnum_discover;
  @BuiltValueEnumConst(wireName: r'challenge')
  static const MissionManifestItemMissionTypeEnum challenge =
      _$missionManifestItemMissionTypeEnum_challenge;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MissionManifestItemMissionTypeEnum unknownDefaultOpenApi =
      _$missionManifestItemMissionTypeEnum_unknownDefaultOpenApi;

  static Serializer<MissionManifestItemMissionTypeEnum> get serializer =>
      _$missionManifestItemMissionTypeEnumSerializer;

  const MissionManifestItemMissionTypeEnum._(String name) : super(name);

  static BuiltSet<MissionManifestItemMissionTypeEnum> get values =>
      _$missionManifestItemMissionTypeEnumValues;
  static MissionManifestItemMissionTypeEnum valueOf(String name) =>
      _$missionManifestItemMissionTypeEnumValueOf(name);
}

class MissionManifestItemQuestionTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'single_choice')
  static const MissionManifestItemQuestionTypeEnum singleChoice =
      _$missionManifestItemQuestionTypeEnum_singleChoice;
  @BuiltValueEnumConst(wireName: r'multiple_choice')
  static const MissionManifestItemQuestionTypeEnum multipleChoice =
      _$missionManifestItemQuestionTypeEnum_multipleChoice;
  @BuiltValueEnumConst(wireName: r'numeric')
  static const MissionManifestItemQuestionTypeEnum numeric =
      _$missionManifestItemQuestionTypeEnum_numeric;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MissionManifestItemQuestionTypeEnum unknownDefaultOpenApi =
      _$missionManifestItemQuestionTypeEnum_unknownDefaultOpenApi;

  static Serializer<MissionManifestItemQuestionTypeEnum> get serializer =>
      _$missionManifestItemQuestionTypeEnumSerializer;

  const MissionManifestItemQuestionTypeEnum._(String name) : super(name);

  static BuiltSet<MissionManifestItemQuestionTypeEnum> get values =>
      _$missionManifestItemQuestionTypeEnumValues;
  static MissionManifestItemQuestionTypeEnum valueOf(String name) =>
      _$missionManifestItemQuestionTypeEnumValueOf(name);
}

class MissionManifestItemStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'pending')
  static const MissionManifestItemStatusEnum pending =
      _$missionManifestItemStatusEnum_pending;
  @BuiltValueEnumConst(wireName: r'presented')
  static const MissionManifestItemStatusEnum presented =
      _$missionManifestItemStatusEnum_presented;
  @BuiltValueEnumConst(wireName: r'answered')
  static const MissionManifestItemStatusEnum answered =
      _$missionManifestItemStatusEnum_answered;
  @BuiltValueEnumConst(wireName: r'skipped')
  static const MissionManifestItemStatusEnum skipped =
      _$missionManifestItemStatusEnum_skipped;
  @BuiltValueEnumConst(wireName: r'cancelled')
  static const MissionManifestItemStatusEnum cancelled =
      _$missionManifestItemStatusEnum_cancelled;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MissionManifestItemStatusEnum unknownDefaultOpenApi =
      _$missionManifestItemStatusEnum_unknownDefaultOpenApi;

  static Serializer<MissionManifestItemStatusEnum> get serializer =>
      _$missionManifestItemStatusEnumSerializer;

  const MissionManifestItemStatusEnum._(String name) : super(name);

  static BuiltSet<MissionManifestItemStatusEnum> get values =>
      _$missionManifestItemStatusEnumValues;
  static MissionManifestItemStatusEnum valueOf(String name) =>
      _$missionManifestItemStatusEnumValueOf(name);
}
