//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'profile_update_request.g.dart';

/// ProfileUpdateRequest
///
/// Properties:
/// * [displayName]
/// * [locale]
/// * [timezone]
/// * [version]
@BuiltValue()
abstract class ProfileUpdateRequest
    implements Built<ProfileUpdateRequest, ProfileUpdateRequestBuilder> {
  @BuiltValueField(wireName: r'display_name')
  Optional<String?> get displayName;

  @BuiltValueField(wireName: r'locale')
  Optional<String?> get locale;

  @BuiltValueField(wireName: r'timezone')
  Optional<String?> get timezone;

  @BuiltValueField(wireName: r'version')
  int get version;

  ProfileUpdateRequest._();

  factory ProfileUpdateRequest([void updates(ProfileUpdateRequestBuilder b)]) =
      _$ProfileUpdateRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProfileUpdateRequestBuilder b) => b
    ..displayName = Optional.absent()
    ..locale = Optional.absent()
    ..timezone = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<ProfileUpdateRequest> get serializer =>
      _$ProfileUpdateRequestSerializer();
}

class _$ProfileUpdateRequestSerializer
    implements PrimitiveSerializer<ProfileUpdateRequest> {
  @override
  final Iterable<Type> types = const [
    ProfileUpdateRequest,
    _$ProfileUpdateRequest
  ];

  @override
  final String wireName = r'ProfileUpdateRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProfileUpdateRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.displayName.isPresent) {
      yield r'display_name';
      final optionalValue = object.displayName.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    if (object.locale.isPresent) {
      yield r'locale';
      final optionalValue = object.locale.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    if (object.timezone.isPresent) {
      yield r'timezone';
      final optionalValue = object.timezone.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    yield r'version';
    yield serializers.serialize(
      object.version,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProfileUpdateRequest object, {
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
    required ProfileUpdateRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'display_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.displayName = Optional.present(valueDes);
          break;
        case r'locale':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.locale = Optional.present(valueDes);
          break;
        case r'timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.timezone = Optional.present(valueDes);
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
  ProfileUpdateRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProfileUpdateRequestBuilder();
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
