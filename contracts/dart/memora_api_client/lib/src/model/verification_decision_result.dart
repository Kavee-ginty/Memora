//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/candidate_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'verification_decision_result.g.dart';

/// VerificationDecisionResult
///
/// Properties:
/// * [candidateId] 
/// * [candidateStatus] 
/// * [requiresVerification] 
@BuiltValue()
abstract class VerificationDecisionResult implements Built<VerificationDecisionResult, VerificationDecisionResultBuilder> {
  @BuiltValueField(wireName: r'candidate_id')
  String get candidateId;

  @BuiltValueField(wireName: r'candidate_status')
  CandidateStatus get candidateStatus;
  // enum candidateStatusEnum {  candidate,  needs_verification,  accepted,  rejected,  committed,  expired,  };

  @BuiltValueField(wireName: r'requires_verification')
  bool get requiresVerification;

  VerificationDecisionResult._();

  factory VerificationDecisionResult([void updates(VerificationDecisionResultBuilder b)]) = _$VerificationDecisionResult;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VerificationDecisionResultBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<VerificationDecisionResult> get serializer => _$VerificationDecisionResultSerializer();
}

class _$VerificationDecisionResultSerializer implements PrimitiveSerializer<VerificationDecisionResult> {
  @override
  final Iterable<Type> types = const [VerificationDecisionResult, _$VerificationDecisionResult];

  @override
  final String wireName = r'VerificationDecisionResult';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    VerificationDecisionResult object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'candidate_id';
    yield serializers.serialize(
      object.candidateId,
      specifiedType: const FullType(String),
    );
    yield r'candidate_status';
    yield serializers.serialize(
      object.candidateStatus,
      specifiedType: const FullType(CandidateStatus),
    );
    yield r'requires_verification';
    yield serializers.serialize(
      object.requiresVerification,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    VerificationDecisionResult object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required VerificationDecisionResultBuilder result,
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
        case r'candidate_status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CandidateStatus),
          ) as CandidateStatus;
          result.candidateStatus = valueDes;
          break;
        case r'requires_verification':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.requiresVerification = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  VerificationDecisionResult deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VerificationDecisionResultBuilder();
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


