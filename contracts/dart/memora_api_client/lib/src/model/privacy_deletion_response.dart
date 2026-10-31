//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/deletion_proof_summary.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'privacy_deletion_response.g.dart';

/// PrivacyDeletionResponse
///
/// Properties:
/// * [completedAt] 
/// * [failureCode] 
/// * [id] 
/// * [proofs] 
/// * [requestType] 
/// * [requestedAt] 
/// * [retentionExceptions] 
/// * [status] 
@BuiltValue()
abstract class PrivacyDeletionResponse implements Built<PrivacyDeletionResponse, PrivacyDeletionResponseBuilder> {
  @BuiltValueField(wireName: r'completed_at')
  Optional<String?> get completedAt;

  @BuiltValueField(wireName: r'failure_code')
  Optional<String?> get failureCode;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'proofs')
  BuiltList<DeletionProofSummary> get proofs;

  @BuiltValueField(wireName: r'request_type')
  String get requestType;

  @BuiltValueField(wireName: r'requested_at')
  String get requestedAt;

  @BuiltValueField(wireName: r'retention_exceptions')
  BuiltList<String> get retentionExceptions;

  @BuiltValueField(wireName: r'status')
  PrivacyDeletionResponseStatusEnum get status;
  // enum statusEnum {  requested,  verifying,  processing,  completed,  failed,  cancelled,  };

  PrivacyDeletionResponse._();

  factory PrivacyDeletionResponse([void updates(PrivacyDeletionResponseBuilder b)]) = _$PrivacyDeletionResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PrivacyDeletionResponseBuilder b) => b
      ..completedAt = Optional.absent()
      ..failureCode = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<PrivacyDeletionResponse> get serializer => _$PrivacyDeletionResponseSerializer();
}

class _$PrivacyDeletionResponseSerializer implements PrimitiveSerializer<PrivacyDeletionResponse> {
  @override
  final Iterable<Type> types = const [PrivacyDeletionResponse, _$PrivacyDeletionResponse];

  @override
  final String wireName = r'PrivacyDeletionResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PrivacyDeletionResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.completedAt.isPresent) {
      yield r'completed_at';
      final optionalValue = object.completedAt.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    if (object.failureCode.isPresent) {
      yield r'failure_code';
      final optionalValue = object.failureCode.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'proofs';
    yield serializers.serialize(
      object.proofs,
      specifiedType: const FullType(BuiltList, [FullType(DeletionProofSummary)]),
    );
    yield r'request_type';
    yield serializers.serialize(
      object.requestType,
      specifiedType: const FullType(String),
    );
    yield r'requested_at';
    yield serializers.serialize(
      object.requestedAt,
      specifiedType: const FullType(String),
    );
    yield r'retention_exceptions';
    yield serializers.serialize(
      object.retentionExceptions,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(PrivacyDeletionResponseStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PrivacyDeletionResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PrivacyDeletionResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'completed_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.completedAt = Optional.present(valueDes);
          break;
        case r'failure_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.failureCode = Optional.present(valueDes);
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'proofs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(DeletionProofSummary)]),
          ) as BuiltList<DeletionProofSummary>;
          result.proofs.replace(valueDes);
          break;
        case r'request_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.requestType = valueDes;
          break;
        case r'requested_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.requestedAt = valueDes;
          break;
        case r'retention_exceptions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.retentionExceptions.replace(valueDes);
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PrivacyDeletionResponseStatusEnum),
          ) as PrivacyDeletionResponseStatusEnum;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PrivacyDeletionResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PrivacyDeletionResponseBuilder();
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


class PrivacyDeletionResponseStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'requested')
  static const PrivacyDeletionResponseStatusEnum requested = _$privacyDeletionResponseStatusEnum_requested;
  @BuiltValueEnumConst(wireName: r'verifying')
  static const PrivacyDeletionResponseStatusEnum verifying = _$privacyDeletionResponseStatusEnum_verifying;
  @BuiltValueEnumConst(wireName: r'processing')
  static const PrivacyDeletionResponseStatusEnum processing = _$privacyDeletionResponseStatusEnum_processing;
  @BuiltValueEnumConst(wireName: r'completed')
  static const PrivacyDeletionResponseStatusEnum completed = _$privacyDeletionResponseStatusEnum_completed;
  @BuiltValueEnumConst(wireName: r'failed')
  static const PrivacyDeletionResponseStatusEnum failed = _$privacyDeletionResponseStatusEnum_failed;
  @BuiltValueEnumConst(wireName: r'cancelled')
  static const PrivacyDeletionResponseStatusEnum cancelled = _$privacyDeletionResponseStatusEnum_cancelled;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const PrivacyDeletionResponseStatusEnum unknownDefaultOpenApi = _$privacyDeletionResponseStatusEnum_unknownDefaultOpenApi;

  static Serializer<PrivacyDeletionResponseStatusEnum> get serializer => _$privacyDeletionResponseStatusEnumSerializer;

  const PrivacyDeletionResponseStatusEnum._(String name): super(name);

  static BuiltSet<PrivacyDeletionResponseStatusEnum> get values => _$privacyDeletionResponseStatusEnumValues;
  static PrivacyDeletionResponseStatusEnum valueOf(String name) => _$privacyDeletionResponseStatusEnumValueOf(name);
}

