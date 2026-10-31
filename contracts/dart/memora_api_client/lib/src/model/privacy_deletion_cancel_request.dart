//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'privacy_deletion_cancel_request.g.dart';

/// PrivacyDeletionCancelRequest
///
/// Properties:
/// * [reason]
@BuiltValue()
abstract class PrivacyDeletionCancelRequest
    implements
        Built<PrivacyDeletionCancelRequest,
            PrivacyDeletionCancelRequestBuilder> {
  @BuiltValueField(wireName: r'reason')
  Optional<String?> get reason;

  PrivacyDeletionCancelRequest._();

  factory PrivacyDeletionCancelRequest(
          [void updates(PrivacyDeletionCancelRequestBuilder b)]) =
      _$PrivacyDeletionCancelRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PrivacyDeletionCancelRequestBuilder b) =>
      b..reason = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<PrivacyDeletionCancelRequest> get serializer =>
      _$PrivacyDeletionCancelRequestSerializer();
}

class _$PrivacyDeletionCancelRequestSerializer
    implements PrimitiveSerializer<PrivacyDeletionCancelRequest> {
  @override
  final Iterable<Type> types = const [
    PrivacyDeletionCancelRequest,
    _$PrivacyDeletionCancelRequest
  ];

  @override
  final String wireName = r'PrivacyDeletionCancelRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PrivacyDeletionCancelRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.reason.isPresent) {
      yield r'reason';
      final optionalValue = object.reason.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PrivacyDeletionCancelRequest object, {
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
    required PrivacyDeletionCancelRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.reason = Optional.present(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PrivacyDeletionCancelRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PrivacyDeletionCancelRequestBuilder();
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
