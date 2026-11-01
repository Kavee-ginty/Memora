//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mission_completion_result.g.dart';

/// MissionCompletionResult
///
/// Properties:
/// * [completedAt]
/// * [engagementStatus]
/// * [missionId]
/// * [nextSuggestedAction]
/// * [protectedCount]
/// * [repairedCount]
/// * [skippedCount]
/// * [status]
@BuiltValue()
abstract class MissionCompletionResult
    implements Built<MissionCompletionResult, MissionCompletionResultBuilder> {
  @BuiltValueField(wireName: r'completed_at')
  String get completedAt;

  @BuiltValueField(wireName: r'engagement_status')
  MissionCompletionResultEngagementStatusEnum get engagementStatus;
  // enum engagementStatusEnum {  pending,  };

  @BuiltValueField(wireName: r'mission_id')
  String get missionId;

  @BuiltValueField(wireName: r'next_suggested_action')
  MissionCompletionResultNextSuggestedActionEnum get nextSuggestedAction;
  // enum nextSuggestedActionEnum {  home,  progress,  };

  @BuiltValueField(wireName: r'protected_count')
  int get protectedCount;

  @BuiltValueField(wireName: r'repaired_count')
  int get repairedCount;

  @BuiltValueField(wireName: r'skipped_count')
  int get skippedCount;

  @BuiltValueField(wireName: r'status')
  MissionCompletionResultStatusEnum get status;
  // enum statusEnum {  completed,  };

  MissionCompletionResult._();

  factory MissionCompletionResult(
          [void updates(MissionCompletionResultBuilder b)]) =
      _$MissionCompletionResult;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MissionCompletionResultBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MissionCompletionResult> get serializer =>
      _$MissionCompletionResultSerializer();
}

class _$MissionCompletionResultSerializer
    implements PrimitiveSerializer<MissionCompletionResult> {
  @override
  final Iterable<Type> types = const [
    MissionCompletionResult,
    _$MissionCompletionResult
  ];

  @override
  final String wireName = r'MissionCompletionResult';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MissionCompletionResult object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'completed_at';
    yield serializers.serialize(
      object.completedAt,
      specifiedType: const FullType(String),
    );
    yield r'engagement_status';
    yield serializers.serialize(
      object.engagementStatus,
      specifiedType:
          const FullType(MissionCompletionResultEngagementStatusEnum),
    );
    yield r'mission_id';
    yield serializers.serialize(
      object.missionId,
      specifiedType: const FullType(String),
    );
    yield r'next_suggested_action';
    yield serializers.serialize(
      object.nextSuggestedAction,
      specifiedType:
          const FullType(MissionCompletionResultNextSuggestedActionEnum),
    );
    yield r'protected_count';
    yield serializers.serialize(
      object.protectedCount,
      specifiedType: const FullType(int),
    );
    yield r'repaired_count';
    yield serializers.serialize(
      object.repairedCount,
      specifiedType: const FullType(int),
    );
    yield r'skipped_count';
    yield serializers.serialize(
      object.skippedCount,
      specifiedType: const FullType(int),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(MissionCompletionResultStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MissionCompletionResult object, {
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
    required MissionCompletionResultBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'completed_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.completedAt = valueDes;
          break;
        case r'engagement_status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(MissionCompletionResultEngagementStatusEnum),
          ) as MissionCompletionResultEngagementStatusEnum;
          result.engagementStatus = valueDes;
          break;
        case r'mission_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.missionId = valueDes;
          break;
        case r'next_suggested_action':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(MissionCompletionResultNextSuggestedActionEnum),
          ) as MissionCompletionResultNextSuggestedActionEnum;
          result.nextSuggestedAction = valueDes;
          break;
        case r'protected_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.protectedCount = valueDes;
          break;
        case r'repaired_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.repairedCount = valueDes;
          break;
        case r'skipped_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.skippedCount = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MissionCompletionResultStatusEnum),
          ) as MissionCompletionResultStatusEnum;
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
  MissionCompletionResult deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MissionCompletionResultBuilder();
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

class MissionCompletionResultEngagementStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'pending')
  static const MissionCompletionResultEngagementStatusEnum pending =
      _$missionCompletionResultEngagementStatusEnum_pending;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MissionCompletionResultEngagementStatusEnum
      unknownDefaultOpenApi =
      _$missionCompletionResultEngagementStatusEnum_unknownDefaultOpenApi;

  static Serializer<MissionCompletionResultEngagementStatusEnum>
      get serializer => _$missionCompletionResultEngagementStatusEnumSerializer;

  const MissionCompletionResultEngagementStatusEnum._(String name)
      : super(name);

  static BuiltSet<MissionCompletionResultEngagementStatusEnum> get values =>
      _$missionCompletionResultEngagementStatusEnumValues;
  static MissionCompletionResultEngagementStatusEnum valueOf(String name) =>
      _$missionCompletionResultEngagementStatusEnumValueOf(name);
}

class MissionCompletionResultNextSuggestedActionEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'home')
  static const MissionCompletionResultNextSuggestedActionEnum home =
      _$missionCompletionResultNextSuggestedActionEnum_home;
  @BuiltValueEnumConst(wireName: r'progress')
  static const MissionCompletionResultNextSuggestedActionEnum progress =
      _$missionCompletionResultNextSuggestedActionEnum_progress;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MissionCompletionResultNextSuggestedActionEnum
      unknownDefaultOpenApi =
      _$missionCompletionResultNextSuggestedActionEnum_unknownDefaultOpenApi;

  static Serializer<MissionCompletionResultNextSuggestedActionEnum>
      get serializer =>
          _$missionCompletionResultNextSuggestedActionEnumSerializer;

  const MissionCompletionResultNextSuggestedActionEnum._(String name)
      : super(name);

  static BuiltSet<MissionCompletionResultNextSuggestedActionEnum> get values =>
      _$missionCompletionResultNextSuggestedActionEnumValues;
  static MissionCompletionResultNextSuggestedActionEnum valueOf(String name) =>
      _$missionCompletionResultNextSuggestedActionEnumValueOf(name);
}

class MissionCompletionResultStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'completed')
  static const MissionCompletionResultStatusEnum completed =
      _$missionCompletionResultStatusEnum_completed;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MissionCompletionResultStatusEnum unknownDefaultOpenApi =
      _$missionCompletionResultStatusEnum_unknownDefaultOpenApi;

  static Serializer<MissionCompletionResultStatusEnum> get serializer =>
      _$missionCompletionResultStatusEnumSerializer;

  const MissionCompletionResultStatusEnum._(String name) : super(name);

  static BuiltSet<MissionCompletionResultStatusEnum> get values =>
      _$missionCompletionResultStatusEnumValues;
  static MissionCompletionResultStatusEnum valueOf(String name) =>
      _$missionCompletionResultStatusEnumValueOf(name);
}
