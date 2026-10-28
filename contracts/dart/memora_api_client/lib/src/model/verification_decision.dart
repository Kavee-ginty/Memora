//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/verification_decision_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'verification_decision.g.dart';

/// VerificationDecision
///
/// Properties:
/// * [candidateId]
/// * [candidateVersion]
/// * [correctedPayload]
/// * [decision]
@BuiltValue()
abstract class VerificationDecision
    implements Built<VerificationDecision, VerificationDecisionBuilder> {
  @BuiltValueField(wireName: r'candidate_id')
  String get candidateId;

  @BuiltValueField(wireName: r'candidate_version')
  int get candidateVersion;

  @BuiltValueField(wireName: r'corrected_payload')
  BuiltMap<String, JsonObject?> get correctedPayload;

  @BuiltValueField(wireName: r'decision')
  VerificationDecisionValue get decision;
  // enum decisionEnum {  accept,  edit,  reject,  merge,  };

  VerificationDecision._();

  factory VerificationDecision([void updates(VerificationDecisionBuilder b)]) =
      _$VerificationDecision;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VerificationDecisionBuilder b) =>
      b..correctedPayload = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<VerificationDecision> get serializer =>
      _$VerificationDecisionSerializer();
}

class _$VerificationDecisionSerializer
    implements PrimitiveSerializer<VerificationDecision> {
  @override
  final Iterable<Type> types = const [
    VerificationDecision,
    _$VerificationDecision
  ];

  @override
  final String wireName = r'VerificationDecision';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    VerificationDecision object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'candidate_id';
    yield serializers.serialize(
      object.candidateId,
      specifiedType: const FullType(String),
    );
    yield r'candidate_version';
    yield serializers.serialize(
      object.candidateVersion,
      specifiedType: const FullType(int),
    );
    if (object.correctedPayload.isPresent) {
      yield r'corrected_payload';
      final optionalValue = object.correctedPayload.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType(
              BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
        );
      }
    }
    yield r'decision';
    yield serializers.serialize(
      object.decision,
      specifiedType: const FullType(VerificationDecisionValue),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    VerificationDecision object, {
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
    required VerificationDecisionBuilder result,
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
        case r'candidate_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.candidateVersion = valueDes;
          break;
        case r'corrected_payload':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(
                BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
          ) as BuiltMap<String, JsonObject>?;
          result.correctedPayload = Optional.present(valueDes);
          break;
        case r'decision':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(VerificationDecisionValue),
          ) as VerificationDecisionValue;
          result.decision = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  VerificationDecision deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VerificationDecisionBuilder();
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
