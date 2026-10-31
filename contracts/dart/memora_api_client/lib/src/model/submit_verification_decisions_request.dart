//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/verification_decision.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'submit_verification_decisions_request.g.dart';

/// SubmitVerificationDecisionsRequest
///
/// Properties:
/// * [decisions]
@BuiltValue()
abstract class SubmitVerificationDecisionsRequest
    implements
        Built<SubmitVerificationDecisionsRequest,
            SubmitVerificationDecisionsRequestBuilder> {
  @BuiltValueField(wireName: r'decisions')
  BuiltList<VerificationDecision> get decisions;

  SubmitVerificationDecisionsRequest._();

  factory SubmitVerificationDecisionsRequest(
          [void updates(SubmitVerificationDecisionsRequestBuilder b)]) =
      _$SubmitVerificationDecisionsRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SubmitVerificationDecisionsRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SubmitVerificationDecisionsRequest> get serializer =>
      _$SubmitVerificationDecisionsRequestSerializer();
}

class _$SubmitVerificationDecisionsRequestSerializer
    implements PrimitiveSerializer<SubmitVerificationDecisionsRequest> {
  @override
  final Iterable<Type> types = const [
    SubmitVerificationDecisionsRequest,
    _$SubmitVerificationDecisionsRequest
  ];

  @override
  final String wireName = r'SubmitVerificationDecisionsRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SubmitVerificationDecisionsRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'decisions';
    yield serializers.serialize(
      object.decisions,
      specifiedType:
          const FullType(BuiltList, [FullType(VerificationDecision)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SubmitVerificationDecisionsRequest object, {
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
    required SubmitVerificationDecisionsRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'decisions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(BuiltList, [FullType(VerificationDecision)]),
          ) as BuiltList<VerificationDecision>;
          result.decisions.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SubmitVerificationDecisionsRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SubmitVerificationDecisionsRequestBuilder();
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
