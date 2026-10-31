//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'privacy_deletion_request.g.dart';

/// PrivacyDeletionRequest
///
/// Properties:
/// * [confirmed]
@BuiltValue()
abstract class PrivacyDeletionRequest
    implements Built<PrivacyDeletionRequest, PrivacyDeletionRequestBuilder> {
  @BuiltValueField(wireName: r'confirmed')
  Optional<bool?> get confirmed;

  PrivacyDeletionRequest._();

  factory PrivacyDeletionRequest(
          [void updates(PrivacyDeletionRequestBuilder b)]) =
      _$PrivacyDeletionRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PrivacyDeletionRequestBuilder b) =>
      b..confirmed = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<PrivacyDeletionRequest> get serializer =>
      _$PrivacyDeletionRequestSerializer();
}

class _$PrivacyDeletionRequestSerializer
    implements PrimitiveSerializer<PrivacyDeletionRequest> {
  @override
  final Iterable<Type> types = const [
    PrivacyDeletionRequest,
    _$PrivacyDeletionRequest
  ];

  @override
  final String wireName = r'PrivacyDeletionRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PrivacyDeletionRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.confirmed.isPresent) {
      yield r'confirmed';
      final optionalValue = object.confirmed.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(bool),
        );
      }
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PrivacyDeletionRequest object, {
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
    required PrivacyDeletionRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'confirmed':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          result.confirmed = Optional.present(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PrivacyDeletionRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PrivacyDeletionRequestBuilder();
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
