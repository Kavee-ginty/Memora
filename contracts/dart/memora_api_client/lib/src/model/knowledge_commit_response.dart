//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/deletion_status.dart';
import 'package:memora_api_client/src/model/first_mission_summary.dart';
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/learning_path_preview_concept.dart';
import 'package:memora_api_client/src/model/learning_update_response.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'knowledge_commit_response.g.dart';

/// KnowledgeCommitResponse
///
/// Properties:
/// * [commitVersion] 
/// * [committedCounts] 
/// * [conceptMappings] 
/// * [firstMission] 
/// * [knowledgeCommitId] 
/// * [learningUpdate] 
/// * [privateKnowledgeCount] 
/// * [sourceDeletionStatus] 
@BuiltValue()
abstract class KnowledgeCommitResponse implements Built<KnowledgeCommitResponse, KnowledgeCommitResponseBuilder> {
  @BuiltValueField(wireName: r'commit_version')
  int get commitVersion;

  @BuiltValueField(wireName: r'committed_counts')
  BuiltMap<String, int> get committedCounts;

  @BuiltValueField(wireName: r'concept_mappings')
  BuiltList<LearningPathPreviewConcept> get conceptMappings;

  @BuiltValueField(wireName: r'first_mission')
  Optional<FirstMissionSummary?> get firstMission;

  @BuiltValueField(wireName: r'knowledge_commit_id')
  String get knowledgeCommitId;

  @BuiltValueField(wireName: r'learning_update')
  LearningUpdateResponse get learningUpdate;

  @BuiltValueField(wireName: r'private_knowledge_count')
  int get privateKnowledgeCount;

  @BuiltValueField(wireName: r'source_deletion_status')
  DeletionStatus get sourceDeletionStatus;
  // enum sourceDeletionStatusEnum {  not_required,  pending,  deleted,  failed,  };

  KnowledgeCommitResponse._();

  factory KnowledgeCommitResponse([void updates(KnowledgeCommitResponseBuilder b)]) = _$KnowledgeCommitResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(KnowledgeCommitResponseBuilder b) => b
      ..firstMission = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<KnowledgeCommitResponse> get serializer => _$KnowledgeCommitResponseSerializer();
}

class _$KnowledgeCommitResponseSerializer implements PrimitiveSerializer<KnowledgeCommitResponse> {
  @override
  final Iterable<Type> types = const [KnowledgeCommitResponse, _$KnowledgeCommitResponse];

  @override
  final String wireName = r'KnowledgeCommitResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    KnowledgeCommitResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commit_version';
    yield serializers.serialize(
      object.commitVersion,
      specifiedType: const FullType(int),
    );
    yield r'committed_counts';
    yield serializers.serialize(
      object.committedCounts,
      specifiedType: const FullType(BuiltMap, [FullType(String), FullType(int)]),
    );
    yield r'concept_mappings';
    yield serializers.serialize(
      object.conceptMappings,
      specifiedType: const FullType(BuiltList, [FullType(LearningPathPreviewConcept)]),
    );
    if (object.firstMission.isPresent) {
      yield r'first_mission';
      final optionalValue = object.firstMission.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(FirstMissionSummary),
        );
      }
    }
    yield r'knowledge_commit_id';
    yield serializers.serialize(
      object.knowledgeCommitId,
      specifiedType: const FullType(String),
    );
    yield r'learning_update';
    yield serializers.serialize(
      object.learningUpdate,
      specifiedType: const FullType(LearningUpdateResponse),
    );
    yield r'private_knowledge_count';
    yield serializers.serialize(
      object.privateKnowledgeCount,
      specifiedType: const FullType(int),
    );
    yield r'source_deletion_status';
    yield serializers.serialize(
      object.sourceDeletionStatus,
      specifiedType: const FullType(DeletionStatus),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    KnowledgeCommitResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required KnowledgeCommitResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'commit_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.commitVersion = valueDes;
          break;
        case r'committed_counts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType(int)]),
          ) as BuiltMap<String, int>;
          result.committedCounts.replace(valueDes);
          break;
        case r'concept_mappings':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(LearningPathPreviewConcept)]),
          ) as BuiltList<LearningPathPreviewConcept>;
          result.conceptMappings.replace(valueDes);
          break;
        case r'first_mission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(FirstMissionSummary),
          ) as FirstMissionSummary?;
          result.firstMission = Optional.present(valueDes);
          break;
        case r'knowledge_commit_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.knowledgeCommitId = valueDes;
          break;
        case r'learning_update':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(LearningUpdateResponse),
          ) as LearningUpdateResponse;
          result.learningUpdate.replace(valueDes);
          break;
        case r'private_knowledge_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.privateKnowledgeCount = valueDes;
          break;
        case r'source_deletion_status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DeletionStatus),
          ) as DeletionStatus;
          result.sourceDeletionStatus = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  KnowledgeCommitResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = KnowledgeCommitResponseBuilder();
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


