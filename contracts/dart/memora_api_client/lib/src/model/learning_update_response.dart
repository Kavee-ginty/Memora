//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/deletion_status.dart';
import 'package:memora_api_client/src/model/input_type.dart';
import 'package:memora_api_client/src/model/learning_update_status.dart';
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/source_upload_summary.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'learning_update_response.g.dart';

/// LearningUpdateResponse
///
/// Properties:
/// * [createdAt]
/// * [curriculumVersionId]
/// * [expiresAt]
/// * [failureCode]
/// * [hasManualText]
/// * [id]
/// * [inputType]
/// * [learnedAt]
/// * [rowVersion]
/// * [sourceDeletionStatus]
/// * [status]
/// * [subjectId]
/// * [updatedAt]
/// * [uploads]
@BuiltValue()
abstract class LearningUpdateResponse
    implements Built<LearningUpdateResponse, LearningUpdateResponseBuilder> {
  @BuiltValueField(wireName: r'created_at')
  String get createdAt;

  @BuiltValueField(wireName: r'curriculum_version_id')
  String get curriculumVersionId;

  @BuiltValueField(wireName: r'expires_at')
  String? get expiresAt;

  @BuiltValueField(wireName: r'failure_code')
  String? get failureCode;

  @BuiltValueField(wireName: r'has_manual_text')
  bool get hasManualText;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'input_type')
  InputType get inputType;
  // enum inputTypeEnum {  manual_text,  pdf,  image,  mixed,  };

  @BuiltValueField(wireName: r'learned_at')
  String get learnedAt;

  @BuiltValueField(wireName: r'row_version')
  int get rowVersion;

  @BuiltValueField(wireName: r'source_deletion_status')
  DeletionStatus get sourceDeletionStatus;
  // enum sourceDeletionStatusEnum {  not_required,  pending,  deleted,  failed,  };

  @BuiltValueField(wireName: r'status')
  LearningUpdateStatus get status;
  // enum statusEnum {  draft,  uploading,  processing,  verification_required,  committed,  failed,  expired,  deleted,  };

  @BuiltValueField(wireName: r'subject_id')
  String get subjectId;

  @BuiltValueField(wireName: r'updated_at')
  String get updatedAt;

  @BuiltValueField(wireName: r'uploads')
  BuiltList<SourceUploadSummary> get uploads;

  LearningUpdateResponse._();

  factory LearningUpdateResponse(
          [void updates(LearningUpdateResponseBuilder b)]) =
      _$LearningUpdateResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LearningUpdateResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LearningUpdateResponse> get serializer =>
      _$LearningUpdateResponseSerializer();
}

class _$LearningUpdateResponseSerializer
    implements PrimitiveSerializer<LearningUpdateResponse> {
  @override
  final Iterable<Type> types = const [
    LearningUpdateResponse,
    _$LearningUpdateResponse
  ];

  @override
  final String wireName = r'LearningUpdateResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LearningUpdateResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(String),
    );
    yield r'curriculum_version_id';
    yield serializers.serialize(
      object.curriculumVersionId,
      specifiedType: const FullType(String),
    );
    yield r'expires_at';
    yield object.expiresAt == null
        ? null
        : serializers.serialize(
            object.expiresAt,
            specifiedType: const FullType.nullable(String),
          );
    yield r'failure_code';
    yield object.failureCode == null
        ? null
        : serializers.serialize(
            object.failureCode,
            specifiedType: const FullType.nullable(String),
          );
    yield r'has_manual_text';
    yield serializers.serialize(
      object.hasManualText,
      specifiedType: const FullType(bool),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'input_type';
    yield serializers.serialize(
      object.inputType,
      specifiedType: const FullType(InputType),
    );
    yield r'learned_at';
    yield serializers.serialize(
      object.learnedAt,
      specifiedType: const FullType(String),
    );
    yield r'row_version';
    yield serializers.serialize(
      object.rowVersion,
      specifiedType: const FullType(int),
    );
    yield r'source_deletion_status';
    yield serializers.serialize(
      object.sourceDeletionStatus,
      specifiedType: const FullType(DeletionStatus),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(LearningUpdateStatus),
    );
    yield r'subject_id';
    yield serializers.serialize(
      object.subjectId,
      specifiedType: const FullType(String),
    );
    yield r'updated_at';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(String),
    );
    yield r'uploads';
    yield serializers.serialize(
      object.uploads,
      specifiedType: const FullType(BuiltList, [FullType(SourceUploadSummary)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    LearningUpdateResponse object, {
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
    required LearningUpdateResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.createdAt = valueDes;
          break;
        case r'curriculum_version_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.curriculumVersionId = valueDes;
          break;
        case r'expires_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.expiresAt = valueDes;
          break;
        case r'failure_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.failureCode = valueDes;
          break;
        case r'has_manual_text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.hasManualText = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'input_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(InputType),
          ) as InputType;
          result.inputType = valueDes;
          break;
        case r'learned_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.learnedAt = valueDes;
          break;
        case r'row_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.rowVersion = valueDes;
          break;
        case r'source_deletion_status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DeletionStatus),
          ) as DeletionStatus;
          result.sourceDeletionStatus = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(LearningUpdateStatus),
          ) as LearningUpdateStatus;
          result.status = valueDes;
          break;
        case r'subject_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.subjectId = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.updatedAt = valueDes;
          break;
        case r'uploads':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(BuiltList, [FullType(SourceUploadSummary)]),
          ) as BuiltList<SourceUploadSummary>;
          result.uploads.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  LearningUpdateResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LearningUpdateResponseBuilder();
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
