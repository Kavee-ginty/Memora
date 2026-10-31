//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'profile_summary.g.dart';

/// ProfileSummary
///
/// Properties:
/// * [activeSubjectId] 
/// * [curriculumVersionId] 
/// * [displayName] 
/// * [onboardingCompleted] 
/// * [userId] 
@BuiltValue()
abstract class ProfileSummary implements Built<ProfileSummary, ProfileSummaryBuilder> {
  @BuiltValueField(wireName: r'active_subject_id')
  String? get activeSubjectId;

  @BuiltValueField(wireName: r'curriculum_version_id')
  String? get curriculumVersionId;

  @BuiltValueField(wireName: r'display_name')
  String get displayName;

  @BuiltValueField(wireName: r'onboarding_completed')
  bool get onboardingCompleted;

  @BuiltValueField(wireName: r'user_id')
  String get userId;

  ProfileSummary._();

  factory ProfileSummary([void updates(ProfileSummaryBuilder b)]) = _$ProfileSummary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProfileSummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProfileSummary> get serializer => _$ProfileSummarySerializer();
}

class _$ProfileSummarySerializer implements PrimitiveSerializer<ProfileSummary> {
  @override
  final Iterable<Type> types = const [ProfileSummary, _$ProfileSummary];

  @override
  final String wireName = r'ProfileSummary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProfileSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'active_subject_id';
    yield object.activeSubjectId == null ? null : serializers.serialize(
      object.activeSubjectId,
      specifiedType: const FullType.nullable(String),
    );
    yield r'curriculum_version_id';
    yield object.curriculumVersionId == null ? null : serializers.serialize(
      object.curriculumVersionId,
      specifiedType: const FullType.nullable(String),
    );
    yield r'display_name';
    yield serializers.serialize(
      object.displayName,
      specifiedType: const FullType(String),
    );
    yield r'onboarding_completed';
    yield serializers.serialize(
      object.onboardingCompleted,
      specifiedType: const FullType(bool),
    );
    yield r'user_id';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProfileSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProfileSummaryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'active_subject_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.activeSubjectId = valueDes;
          break;
        case r'curriculum_version_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.curriculumVersionId = valueDes;
          break;
        case r'display_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.displayName = valueDes;
          break;
        case r'onboarding_completed':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.onboardingCompleted = valueDes;
          break;
        case r'user_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.userId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProfileSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProfileSummaryBuilder();
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


