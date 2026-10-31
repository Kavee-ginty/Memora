//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'privacy_export_response.g.dart';

/// PrivacyExportResponse
///
/// Properties:
/// * [completedAt] 
/// * [downloadExpiresAt] 
/// * [downloadUrl] 
/// * [failureCode] 
/// * [id] 
/// * [requestType] 
/// * [requestedAt] 
/// * [status] 
@BuiltValue()
abstract class PrivacyExportResponse implements Built<PrivacyExportResponse, PrivacyExportResponseBuilder> {
  @BuiltValueField(wireName: r'completed_at')
  Optional<String?> get completedAt;

  @BuiltValueField(wireName: r'download_expires_at')
  Optional<String?> get downloadExpiresAt;

  @BuiltValueField(wireName: r'download_url')
  Optional<String?> get downloadUrl;

  @BuiltValueField(wireName: r'failure_code')
  Optional<String?> get failureCode;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'request_type')
  String get requestType;

  @BuiltValueField(wireName: r'requested_at')
  String get requestedAt;

  @BuiltValueField(wireName: r'status')
  PrivacyExportResponseStatusEnum get status;
  // enum statusEnum {  requested,  verifying,  processing,  completed,  failed,  cancelled,  };

  PrivacyExportResponse._();

  factory PrivacyExportResponse([void updates(PrivacyExportResponseBuilder b)]) = _$PrivacyExportResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PrivacyExportResponseBuilder b) => b
      ..completedAt = Optional.absent()
      ..downloadExpiresAt = Optional.absent()
      ..downloadUrl = Optional.absent()
      ..failureCode = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<PrivacyExportResponse> get serializer => _$PrivacyExportResponseSerializer();
}

class _$PrivacyExportResponseSerializer implements PrimitiveSerializer<PrivacyExportResponse> {
  @override
  final Iterable<Type> types = const [PrivacyExportResponse, _$PrivacyExportResponse];

  @override
  final String wireName = r'PrivacyExportResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PrivacyExportResponse object, {
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
    if (object.downloadExpiresAt.isPresent) {
      yield r'download_expires_at';
      final optionalValue = object.downloadExpiresAt.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    if (object.downloadUrl.isPresent) {
      yield r'download_url';
      final optionalValue = object.downloadUrl.value;
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
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(PrivacyExportResponseStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PrivacyExportResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PrivacyExportResponseBuilder result,
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
        case r'download_expires_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.downloadExpiresAt = Optional.present(valueDes);
          break;
        case r'download_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.downloadUrl = Optional.present(valueDes);
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
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PrivacyExportResponseStatusEnum),
          ) as PrivacyExportResponseStatusEnum;
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
  PrivacyExportResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PrivacyExportResponseBuilder();
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


class PrivacyExportResponseStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'requested')
  static const PrivacyExportResponseStatusEnum requested = _$privacyExportResponseStatusEnum_requested;
  @BuiltValueEnumConst(wireName: r'verifying')
  static const PrivacyExportResponseStatusEnum verifying = _$privacyExportResponseStatusEnum_verifying;
  @BuiltValueEnumConst(wireName: r'processing')
  static const PrivacyExportResponseStatusEnum processing = _$privacyExportResponseStatusEnum_processing;
  @BuiltValueEnumConst(wireName: r'completed')
  static const PrivacyExportResponseStatusEnum completed = _$privacyExportResponseStatusEnum_completed;
  @BuiltValueEnumConst(wireName: r'failed')
  static const PrivacyExportResponseStatusEnum failed = _$privacyExportResponseStatusEnum_failed;
  @BuiltValueEnumConst(wireName: r'cancelled')
  static const PrivacyExportResponseStatusEnum cancelled = _$privacyExportResponseStatusEnum_cancelled;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const PrivacyExportResponseStatusEnum unknownDefaultOpenApi = _$privacyExportResponseStatusEnum_unknownDefaultOpenApi;

  static Serializer<PrivacyExportResponseStatusEnum> get serializer => _$privacyExportResponseStatusEnumSerializer;

  const PrivacyExportResponseStatusEnum._(String name): super(name);

  static BuiltSet<PrivacyExportResponseStatusEnum> get values => _$privacyExportResponseStatusEnumValues;
  static PrivacyExportResponseStatusEnum valueOf(String name) => _$privacyExportResponseStatusEnumValueOf(name);
}

