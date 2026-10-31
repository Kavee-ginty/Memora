//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/consent_decision.dart';
import 'package:memora_api_client/src/model/consent_type.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'consent_acceptance_response.g.dart';

/// ConsentAcceptanceResponse
///
/// Properties:
/// * [acceptedScopes]
/// * [decidedAt]
/// * [decision]
/// * [id]
/// * [policyId]
/// * [policyVersion]
@BuiltValue()
abstract class ConsentAcceptanceResponse
    implements
        Built<ConsentAcceptanceResponse, ConsentAcceptanceResponseBuilder> {
  @BuiltValueField(wireName: r'accepted_scopes')
  BuiltList<String> get acceptedScopes;

  @BuiltValueField(wireName: r'decided_at')
  DateTime get decidedAt;

  @BuiltValueField(wireName: r'decision')
  ConsentDecision get decision;
  // enum decisionEnum {  granted,  declined,  withdrawn,  };

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'policy_id')
  ConsentType get policyId;
  // enum policyIdEnum {  terms,  privacy,  material_processing,  model_processing,  notifications,  };

  @BuiltValueField(wireName: r'policy_version')
  String get policyVersion;

  ConsentAcceptanceResponse._();

  factory ConsentAcceptanceResponse(
          [void updates(ConsentAcceptanceResponseBuilder b)]) =
      _$ConsentAcceptanceResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ConsentAcceptanceResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ConsentAcceptanceResponse> get serializer =>
      _$ConsentAcceptanceResponseSerializer();
}

class _$ConsentAcceptanceResponseSerializer
    implements PrimitiveSerializer<ConsentAcceptanceResponse> {
  @override
  final Iterable<Type> types = const [
    ConsentAcceptanceResponse,
    _$ConsentAcceptanceResponse
  ];

  @override
  final String wireName = r'ConsentAcceptanceResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ConsentAcceptanceResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'accepted_scopes';
    yield serializers.serialize(
      object.acceptedScopes,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'decided_at';
    yield serializers.serialize(
      object.decidedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'decision';
    yield serializers.serialize(
      object.decision,
      specifiedType: const FullType(ConsentDecision),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'policy_id';
    yield serializers.serialize(
      object.policyId,
      specifiedType: const FullType(ConsentType),
    );
    yield r'policy_version';
    yield serializers.serialize(
      object.policyVersion,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ConsentAcceptanceResponse object, {
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
    required ConsentAcceptanceResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'accepted_scopes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.acceptedScopes.replace(valueDes);
          break;
        case r'decided_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.decidedAt = valueDes;
          break;
        case r'decision':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ConsentDecision),
          ) as ConsentDecision;
          result.decision = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'policy_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ConsentType),
          ) as ConsentType;
          result.policyId = valueDes;
          break;
        case r'policy_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.policyVersion = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ConsentAcceptanceResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ConsentAcceptanceResponseBuilder();
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
