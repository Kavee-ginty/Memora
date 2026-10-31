//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/consent_type.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'consent_acceptance_request.g.dart';

/// ConsentAcceptanceRequest
///
/// Properties:
/// * [acceptedScopes] 
/// * [policyId] 
/// * [policyVersion] 
@BuiltValue()
abstract class ConsentAcceptanceRequest implements Built<ConsentAcceptanceRequest, ConsentAcceptanceRequestBuilder> {
  @BuiltValueField(wireName: r'accepted_scopes')
  BuiltList<String> get acceptedScopes;

  @BuiltValueField(wireName: r'policy_id')
  ConsentType get policyId;
  // enum policyIdEnum {  terms,  privacy,  material_processing,  model_processing,  notifications,  };

  @BuiltValueField(wireName: r'policy_version')
  String get policyVersion;

  ConsentAcceptanceRequest._();

  factory ConsentAcceptanceRequest([void updates(ConsentAcceptanceRequestBuilder b)]) = _$ConsentAcceptanceRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ConsentAcceptanceRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ConsentAcceptanceRequest> get serializer => _$ConsentAcceptanceRequestSerializer();
}

class _$ConsentAcceptanceRequestSerializer implements PrimitiveSerializer<ConsentAcceptanceRequest> {
  @override
  final Iterable<Type> types = const [ConsentAcceptanceRequest, _$ConsentAcceptanceRequest];

  @override
  final String wireName = r'ConsentAcceptanceRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ConsentAcceptanceRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'accepted_scopes';
    yield serializers.serialize(
      object.acceptedScopes,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
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
    ConsentAcceptanceRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ConsentAcceptanceRequestBuilder result,
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
  ConsentAcceptanceRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ConsentAcceptanceRequestBuilder();
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


