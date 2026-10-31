//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/verification_decision_result.dart';
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/learning_update_response.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'submit_verification_decisions_response.g.dart';

/// SubmitVerificationDecisionsResponse
///
/// Properties:
/// * [learningUpdate] 
/// * [results] 
@BuiltValue()
abstract class SubmitVerificationDecisionsResponse implements Built<SubmitVerificationDecisionsResponse, SubmitVerificationDecisionsResponseBuilder> {
  @BuiltValueField(wireName: r'learning_update')
  LearningUpdateResponse get learningUpdate;

  @BuiltValueField(wireName: r'results')
  BuiltList<VerificationDecisionResult> get results;

  SubmitVerificationDecisionsResponse._();

  factory SubmitVerificationDecisionsResponse([void updates(SubmitVerificationDecisionsResponseBuilder b)]) = _$SubmitVerificationDecisionsResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SubmitVerificationDecisionsResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SubmitVerificationDecisionsResponse> get serializer => _$SubmitVerificationDecisionsResponseSerializer();
}

class _$SubmitVerificationDecisionsResponseSerializer implements PrimitiveSerializer<SubmitVerificationDecisionsResponse> {
  @override
  final Iterable<Type> types = const [SubmitVerificationDecisionsResponse, _$SubmitVerificationDecisionsResponse];

  @override
  final String wireName = r'SubmitVerificationDecisionsResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SubmitVerificationDecisionsResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'learning_update';
    yield serializers.serialize(
      object.learningUpdate,
      specifiedType: const FullType(LearningUpdateResponse),
    );
    yield r'results';
    yield serializers.serialize(
      object.results,
      specifiedType: const FullType(BuiltList, [FullType(VerificationDecisionResult)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SubmitVerificationDecisionsResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SubmitVerificationDecisionsResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'learning_update':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(LearningUpdateResponse),
          ) as LearningUpdateResponse;
          result.learningUpdate.replace(valueDes);
          break;
        case r'results':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(VerificationDecisionResult)]),
          ) as BuiltList<VerificationDecisionResult>;
          result.results.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SubmitVerificationDecisionsResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SubmitVerificationDecisionsResponseBuilder();
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


