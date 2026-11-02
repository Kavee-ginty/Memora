//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/public_question.dart';
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/attempt_result.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mission_item_response.g.dart';

/// MissionItemResponse
///
/// Properties:
/// * [dueReason]
/// * [id]
/// * [missionId]
/// * [missionType]
/// * [position]
/// * [question]
/// * [result]
/// * [selectionReasonCodes]
/// * [status]
@BuiltValue()
abstract class MissionItemResponse
    implements Built<MissionItemResponse, MissionItemResponseBuilder> {
  @BuiltValueField(wireName: r'due_reason')
  String get dueReason;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'mission_id')
  String get missionId;

  @BuiltValueField(wireName: r'mission_type')
  MissionItemResponseMissionTypeEnum get missionType;
  // enum missionTypeEnum {  protect,  repair,  recover,  discover,  challenge,  };

  @BuiltValueField(wireName: r'position')
  int get position;

  @BuiltValueField(wireName: r'question')
  PublicQuestion get question;

  @BuiltValueField(wireName: r'result')
  AttemptResult? get result;

  @BuiltValueField(wireName: r'selection_reason_codes')
  BuiltList<String> get selectionReasonCodes;

  @BuiltValueField(wireName: r'status')
  MissionItemResponseStatusEnum get status;
  // enum statusEnum {  pending,  presented,  answered,  skipped,  cancelled,  };

  MissionItemResponse._();

  factory MissionItemResponse([void updates(MissionItemResponseBuilder b)]) =
      _$MissionItemResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MissionItemResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MissionItemResponse> get serializer =>
      _$MissionItemResponseSerializer();
}

class _$MissionItemResponseSerializer
    implements PrimitiveSerializer<MissionItemResponse> {
  @override
  final Iterable<Type> types = const [
    MissionItemResponse,
    _$MissionItemResponse
  ];

  @override
  final String wireName = r'MissionItemResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MissionItemResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'due_reason';
    yield serializers.serialize(
      object.dueReason,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'mission_id';
    yield serializers.serialize(
      object.missionId,
      specifiedType: const FullType(String),
    );
    yield r'mission_type';
    yield serializers.serialize(
      object.missionType,
      specifiedType: const FullType(MissionItemResponseMissionTypeEnum),
    );
    yield r'position';
    yield serializers.serialize(
      object.position,
      specifiedType: const FullType(int),
    );
    yield r'question';
    yield serializers.serialize(
      object.question,
      specifiedType: const FullType(PublicQuestion),
    );
    yield r'result';
    yield object.result == null
        ? null
        : serializers.serialize(
            object.result,
            specifiedType: const FullType.nullable(AttemptResult),
          );
    yield r'selection_reason_codes';
    yield serializers.serialize(
      object.selectionReasonCodes,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(MissionItemResponseStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MissionItemResponse object, {
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
    required MissionItemResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'due_reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.dueReason = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'mission_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.missionId = valueDes;
          break;
        case r'mission_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MissionItemResponseMissionTypeEnum),
          ) as MissionItemResponseMissionTypeEnum;
          result.missionType = valueDes;
          break;
        case r'position':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.position = valueDes;
          break;
        case r'question':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PublicQuestion),
          ) as PublicQuestion;
          result.question.replace(valueDes);
          break;
        case r'result':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(AttemptResult),
          ) as AttemptResult?;
          if (valueDes == null) continue;
          result.result.replace(valueDes);
          break;
        case r'selection_reason_codes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.selectionReasonCodes.replace(valueDes);
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MissionItemResponseStatusEnum),
          ) as MissionItemResponseStatusEnum;
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
  MissionItemResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MissionItemResponseBuilder();
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

class MissionItemResponseMissionTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'protect')
  static const MissionItemResponseMissionTypeEnum protect =
      _$missionItemResponseMissionTypeEnum_protect;
  @BuiltValueEnumConst(wireName: r'repair')
  static const MissionItemResponseMissionTypeEnum repair =
      _$missionItemResponseMissionTypeEnum_repair;
  @BuiltValueEnumConst(wireName: r'recover')
  static const MissionItemResponseMissionTypeEnum recover =
      _$missionItemResponseMissionTypeEnum_recover;
  @BuiltValueEnumConst(wireName: r'discover')
  static const MissionItemResponseMissionTypeEnum discover =
      _$missionItemResponseMissionTypeEnum_discover;
  @BuiltValueEnumConst(wireName: r'challenge')
  static const MissionItemResponseMissionTypeEnum challenge =
      _$missionItemResponseMissionTypeEnum_challenge;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MissionItemResponseMissionTypeEnum unknownDefaultOpenApi =
      _$missionItemResponseMissionTypeEnum_unknownDefaultOpenApi;

  static Serializer<MissionItemResponseMissionTypeEnum> get serializer =>
      _$missionItemResponseMissionTypeEnumSerializer;

  const MissionItemResponseMissionTypeEnum._(String name) : super(name);

  static BuiltSet<MissionItemResponseMissionTypeEnum> get values =>
      _$missionItemResponseMissionTypeEnumValues;
  static MissionItemResponseMissionTypeEnum valueOf(String name) =>
      _$missionItemResponseMissionTypeEnumValueOf(name);
}

class MissionItemResponseStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'pending')
  static const MissionItemResponseStatusEnum pending =
      _$missionItemResponseStatusEnum_pending;
  @BuiltValueEnumConst(wireName: r'presented')
  static const MissionItemResponseStatusEnum presented =
      _$missionItemResponseStatusEnum_presented;
  @BuiltValueEnumConst(wireName: r'answered')
  static const MissionItemResponseStatusEnum answered =
      _$missionItemResponseStatusEnum_answered;
  @BuiltValueEnumConst(wireName: r'skipped')
  static const MissionItemResponseStatusEnum skipped =
      _$missionItemResponseStatusEnum_skipped;
  @BuiltValueEnumConst(wireName: r'cancelled')
  static const MissionItemResponseStatusEnum cancelled =
      _$missionItemResponseStatusEnum_cancelled;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MissionItemResponseStatusEnum unknownDefaultOpenApi =
      _$missionItemResponseStatusEnum_unknownDefaultOpenApi;

  static Serializer<MissionItemResponseStatusEnum> get serializer =>
      _$missionItemResponseStatusEnumSerializer;

  const MissionItemResponseStatusEnum._(String name) : super(name);

  static BuiltSet<MissionItemResponseStatusEnum> get values =>
      _$missionItemResponseStatusEnumValues;
  static MissionItemResponseStatusEnum valueOf(String name) =>
      _$missionItemResponseStatusEnumValueOf(name);
}
