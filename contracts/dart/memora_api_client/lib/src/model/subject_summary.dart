//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'subject_summary.g.dart';

/// SubjectSummary
///
/// Properties:
/// * [code]
/// * [curriculumEditionCode]
/// * [curriculumVersionId]
/// * [id]
/// * [name]
@BuiltValue()
abstract class SubjectSummary
    implements Built<SubjectSummary, SubjectSummaryBuilder> {
  @BuiltValueField(wireName: r'code')
  String get code;

  @BuiltValueField(wireName: r'curriculum_edition_code')
  String get curriculumEditionCode;

  @BuiltValueField(wireName: r'curriculum_version_id')
  String get curriculumVersionId;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  SubjectSummary._();

  factory SubjectSummary([void updates(SubjectSummaryBuilder b)]) =
      _$SubjectSummary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SubjectSummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SubjectSummary> get serializer =>
      _$SubjectSummarySerializer();
}

class _$SubjectSummarySerializer
    implements PrimitiveSerializer<SubjectSummary> {
  @override
  final Iterable<Type> types = const [SubjectSummary, _$SubjectSummary];

  @override
  final String wireName = r'SubjectSummary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SubjectSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
    yield r'curriculum_edition_code';
    yield serializers.serialize(
      object.curriculumEditionCode,
      specifiedType: const FullType(String),
    );
    yield r'curriculum_version_id';
    yield serializers.serialize(
      object.curriculumVersionId,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SubjectSummary object, {
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
    required SubjectSummaryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.code = valueDes;
          break;
        case r'curriculum_edition_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.curriculumEditionCode = valueDes;
          break;
        case r'curriculum_version_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.curriculumVersionId = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SubjectSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SubjectSummaryBuilder();
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
