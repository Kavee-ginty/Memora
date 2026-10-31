//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/consent_decision.dart';
import 'package:memora_api_client/src/model/consent_type.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'consent_status.g.dart';

/// ConsentStatus
///
/// Properties:
/// * [decidedAt] 
/// * [decision] 
/// * [isCurrent] 
/// * [policyId] 
/// * [policyVersion] 
/// * [required_] 
@BuiltValue()
abstract class ConsentStatus implements Built<ConsentStatus, ConsentStatusBuilder> {
  @BuiltValueField(wireName: r'decided_at')
  DateTime? get decidedAt;

  @BuiltValueField(wireName: r'decision')
  ConsentDecision? get decision;
  // enum decisionEnum {  granted,  declined,  withdrawn,  };

  @BuiltValueField(wireName: r'is_current')
  bool get isCurrent;

  @BuiltValueField(wireName: r'policy_id')
  ConsentType get policyId;
  // enum policyIdEnum {  terms,  privacy,  material_processing,  model_processing,  notifications,  };

  @BuiltValueField(wireName: r'policy_version')
  String get policyVersion;

  @BuiltValueField(wireName: r'required')
  bool get required_;

  ConsentStatus._();

  factory ConsentStatus([void updates(ConsentStatusBuilder b)]) = _$ConsentStatus;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ConsentStatusBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ConsentStatus> get serializer => _$ConsentStatusSerializer();
}

class _$ConsentStatusSerializer implements PrimitiveSerializer<ConsentStatus> {
  @override
  final Iterable<Type> types = const [ConsentStatus, _$ConsentStatus];

  @override
  final String wireName = r'ConsentStatus';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ConsentStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'decided_at';
    yield object.decidedAt == null ? null : serializers.serialize(
      object.decidedAt,
      specifiedType: const FullType.nullable(DateTime),
    );
    yield r'decision';
    yield object.decision == null ? null : serializers.serialize(
      object.decision,
      specifiedType: const FullType.nullable(ConsentDecision),
    );
    yield r'is_current';
    yield serializers.serialize(
      object.isCurrent,
      specifiedType: const FullType(bool),
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
    yield r'required';
    yield serializers.serialize(
      object.required_,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ConsentStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ConsentStatusBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'decided_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.decidedAt = valueDes;
          break;
        case r'decision':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(ConsentDecision),
          ) as ConsentDecision?;
          if (valueDes == null) continue;
          result.decision = valueDes;
          break;
        case r'is_current':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isCurrent = valueDes;
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
        case r'required':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.required_ = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ConsentStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ConsentStatusBuilder();
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


