//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'learning_path_preview_concept.g.dart';

/// LearningPathPreviewConcept
///
/// Properties:
/// * [candidateId]
/// * [candidateType]
/// * [conceptId]
/// * [conceptVersionId]
/// * [title]
@BuiltValue()
abstract class LearningPathPreviewConcept
    implements
        Built<LearningPathPreviewConcept, LearningPathPreviewConceptBuilder> {
  @BuiltValueField(wireName: r'candidate_id')
  String get candidateId;

  @BuiltValueField(wireName: r'candidate_type')
  String get candidateType;

  @BuiltValueField(wireName: r'concept_id')
  String? get conceptId;

  @BuiltValueField(wireName: r'concept_version_id')
  String? get conceptVersionId;

  @BuiltValueField(wireName: r'title')
  String get title;

  LearningPathPreviewConcept._();

  factory LearningPathPreviewConcept(
          [void updates(LearningPathPreviewConceptBuilder b)]) =
      _$LearningPathPreviewConcept;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LearningPathPreviewConceptBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LearningPathPreviewConcept> get serializer =>
      _$LearningPathPreviewConceptSerializer();
}

class _$LearningPathPreviewConceptSerializer
    implements PrimitiveSerializer<LearningPathPreviewConcept> {
  @override
  final Iterable<Type> types = const [
    LearningPathPreviewConcept,
    _$LearningPathPreviewConcept
  ];

  @override
  final String wireName = r'LearningPathPreviewConcept';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LearningPathPreviewConcept object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'candidate_id';
    yield serializers.serialize(
      object.candidateId,
      specifiedType: const FullType(String),
    );
    yield r'candidate_type';
    yield serializers.serialize(
      object.candidateType,
      specifiedType: const FullType(String),
    );
    yield r'concept_id';
    yield object.conceptId == null
        ? null
        : serializers.serialize(
            object.conceptId,
            specifiedType: const FullType.nullable(String),
          );
    yield r'concept_version_id';
    yield object.conceptVersionId == null
        ? null
        : serializers.serialize(
            object.conceptVersionId,
            specifiedType: const FullType.nullable(String),
          );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    LearningPathPreviewConcept object, {
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
    required LearningPathPreviewConceptBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'candidate_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.candidateId = valueDes;
          break;
        case r'candidate_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.candidateType = valueDes;
          break;
        case r'concept_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.conceptId = valueDes;
          break;
        case r'concept_version_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.conceptVersionId = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  LearningPathPreviewConcept deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LearningPathPreviewConceptBuilder();
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
