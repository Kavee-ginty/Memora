//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/learning_update_status.dart';
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/learning_path_preview_concept.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'learning_path_preview_response.g.dart';

/// LearningPathPreviewResponse
///
/// Properties:
/// * [blockedReason] 
/// * [canCommit] 
/// * [conceptCount] 
/// * [estimatedFirstMissionMinutes] 
/// * [firstConcepts] 
/// * [status] 
/// * [updateId] 
@BuiltValue()
abstract class LearningPathPreviewResponse implements Built<LearningPathPreviewResponse, LearningPathPreviewResponseBuilder> {
  @BuiltValueField(wireName: r'blocked_reason')
  String? get blockedReason;

  @BuiltValueField(wireName: r'can_commit')
  bool get canCommit;

  @BuiltValueField(wireName: r'concept_count')
  int get conceptCount;

  @BuiltValueField(wireName: r'estimated_first_mission_minutes')
  int? get estimatedFirstMissionMinutes;

  @BuiltValueField(wireName: r'first_concepts')
  BuiltList<LearningPathPreviewConcept> get firstConcepts;

  @BuiltValueField(wireName: r'status')
  LearningUpdateStatus get status;
  // enum statusEnum {  draft,  uploading,  processing,  verification_required,  committed,  failed,  expired,  deleted,  };

  @BuiltValueField(wireName: r'update_id')
  String get updateId;

  LearningPathPreviewResponse._();

  factory LearningPathPreviewResponse([void updates(LearningPathPreviewResponseBuilder b)]) = _$LearningPathPreviewResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LearningPathPreviewResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LearningPathPreviewResponse> get serializer => _$LearningPathPreviewResponseSerializer();
}

class _$LearningPathPreviewResponseSerializer implements PrimitiveSerializer<LearningPathPreviewResponse> {
  @override
  final Iterable<Type> types = const [LearningPathPreviewResponse, _$LearningPathPreviewResponse];

  @override
  final String wireName = r'LearningPathPreviewResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LearningPathPreviewResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'blocked_reason';
    yield object.blockedReason == null ? null : serializers.serialize(
      object.blockedReason,
      specifiedType: const FullType.nullable(String),
    );
    yield r'can_commit';
    yield serializers.serialize(
      object.canCommit,
      specifiedType: const FullType(bool),
    );
    yield r'concept_count';
    yield serializers.serialize(
      object.conceptCount,
      specifiedType: const FullType(int),
    );
    yield r'estimated_first_mission_minutes';
    yield object.estimatedFirstMissionMinutes == null ? null : serializers.serialize(
      object.estimatedFirstMissionMinutes,
      specifiedType: const FullType.nullable(int),
    );
    yield r'first_concepts';
    yield serializers.serialize(
      object.firstConcepts,
      specifiedType: const FullType(BuiltList, [FullType(LearningPathPreviewConcept)]),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(LearningUpdateStatus),
    );
    yield r'update_id';
    yield serializers.serialize(
      object.updateId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    LearningPathPreviewResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LearningPathPreviewResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'blocked_reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.blockedReason = valueDes;
          break;
        case r'can_commit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.canCommit = valueDes;
          break;
        case r'concept_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.conceptCount = valueDes;
          break;
        case r'estimated_first_mission_minutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.estimatedFirstMissionMinutes = valueDes;
          break;
        case r'first_concepts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(LearningPathPreviewConcept)]),
          ) as BuiltList<LearningPathPreviewConcept>;
          result.firstConcepts.replace(valueDes);
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(LearningUpdateStatus),
          ) as LearningUpdateStatus;
          result.status = valueDes;
          break;
        case r'update_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.updateId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  LearningPathPreviewResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LearningPathPreviewResponseBuilder();
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


