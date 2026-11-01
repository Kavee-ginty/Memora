//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mission_summary.g.dart';

/// MissionSummary
///
/// Properties:
/// * [completedItemCount]
/// * [currentItemId]
/// * [dueReason]
/// * [estimatedMinutes]
/// * [expiresAt]
/// * [id]
/// * [missionDate]
/// * [missionTimezone]
/// * [plannedItemCount]
/// * [status]
/// * [subjectId]
/// * [version]
@BuiltValue()
abstract class MissionSummary
    implements Built<MissionSummary, MissionSummaryBuilder> {
  @BuiltValueField(wireName: r'completed_item_count')
  int get completedItemCount;

  @BuiltValueField(wireName: r'current_item_id')
  String? get currentItemId;

  @BuiltValueField(wireName: r'due_reason')
  String get dueReason;

  @BuiltValueField(wireName: r'estimated_minutes')
  int get estimatedMinutes;

  @BuiltValueField(wireName: r'expires_at')
  String get expiresAt;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'mission_date')
  Date get missionDate;

  @BuiltValueField(wireName: r'mission_timezone')
  String get missionTimezone;

  @BuiltValueField(wireName: r'planned_item_count')
  int get plannedItemCount;

  @BuiltValueField(wireName: r'status')
  MissionSummaryStatusEnum get status;
  // enum statusEnum {  planned,  started,  paused,  completed,  expired,  abandoned,  };

  @BuiltValueField(wireName: r'subject_id')
  String get subjectId;

  @BuiltValueField(wireName: r'version')
  int get version;

  MissionSummary._();

  factory MissionSummary([void updates(MissionSummaryBuilder b)]) =
      _$MissionSummary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MissionSummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MissionSummary> get serializer =>
      _$MissionSummarySerializer();
}

class _$MissionSummarySerializer
    implements PrimitiveSerializer<MissionSummary> {
  @override
  final Iterable<Type> types = const [MissionSummary, _$MissionSummary];

  @override
  final String wireName = r'MissionSummary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MissionSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'completed_item_count';
    yield serializers.serialize(
      object.completedItemCount,
      specifiedType: const FullType(int),
    );
    yield r'current_item_id';
    yield object.currentItemId == null
        ? null
        : serializers.serialize(
            object.currentItemId,
            specifiedType: const FullType.nullable(String),
          );
    yield r'due_reason';
    yield serializers.serialize(
      object.dueReason,
      specifiedType: const FullType(String),
    );
    yield r'estimated_minutes';
    yield serializers.serialize(
      object.estimatedMinutes,
      specifiedType: const FullType(int),
    );
    yield r'expires_at';
    yield serializers.serialize(
      object.expiresAt,
      specifiedType: const FullType(String),
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
    yield r'mission_timezone';
    yield serializers.serialize(
      object.missionTimezone,
      specifiedType: const FullType(String),
    );
    yield r'planned_item_count';
    yield serializers.serialize(
      object.plannedItemCount,
      specifiedType: const FullType(int),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(MissionSummaryStatusEnum),
    );
    yield r'subject_id';
    yield serializers.serialize(
      object.subjectId,
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
    MissionSummary object, {
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
    required MissionSummaryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'completed_item_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.completedItemCount = valueDes;
          break;
        case r'current_item_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.currentItemId = valueDes;
          break;
        case r'due_reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.dueReason = valueDes;
          break;
        case r'estimated_minutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.estimatedMinutes = valueDes;
          break;
        case r'expires_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.expiresAt = valueDes;
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
        case r'mission_timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.missionTimezone = valueDes;
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
            specifiedType: const FullType(MissionSummaryStatusEnum),
          ) as MissionSummaryStatusEnum;
          result.status = valueDes;
          break;
        case r'subject_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.subjectId = valueDes;
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
  MissionSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MissionSummaryBuilder();
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

class MissionSummaryStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'planned')
  static const MissionSummaryStatusEnum planned =
      _$missionSummaryStatusEnum_planned;
  @BuiltValueEnumConst(wireName: r'started')
  static const MissionSummaryStatusEnum started =
      _$missionSummaryStatusEnum_started;
  @BuiltValueEnumConst(wireName: r'paused')
  static const MissionSummaryStatusEnum paused =
      _$missionSummaryStatusEnum_paused;
  @BuiltValueEnumConst(wireName: r'completed')
  static const MissionSummaryStatusEnum completed =
      _$missionSummaryStatusEnum_completed;
  @BuiltValueEnumConst(wireName: r'expired')
  static const MissionSummaryStatusEnum expired =
      _$missionSummaryStatusEnum_expired;
  @BuiltValueEnumConst(wireName: r'abandoned')
  static const MissionSummaryStatusEnum abandoned =
      _$missionSummaryStatusEnum_abandoned;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MissionSummaryStatusEnum unknownDefaultOpenApi =
      _$missionSummaryStatusEnum_unknownDefaultOpenApi;

  static Serializer<MissionSummaryStatusEnum> get serializer =>
      _$missionSummaryStatusEnumSerializer;

  const MissionSummaryStatusEnum._(String name) : super(name);

  static BuiltSet<MissionSummaryStatusEnum> get values =>
      _$missionSummaryStatusEnumValues;
  static MissionSummaryStatusEnum valueOf(String name) =>
      _$missionSummaryStatusEnumValueOf(name);
}
