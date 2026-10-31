//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/field_error.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'error_detail.g.dart';

/// ErrorDetail
///
/// Properties:
/// * [action] 
/// * [code] 
/// * [fieldErrors] 
/// * [message] 
/// * [requestId] 
/// * [retryAfterSeconds] 
/// * [retryable] 
@BuiltValue()
abstract class ErrorDetail implements Built<ErrorDetail, ErrorDetailBuilder> {
  @BuiltValueField(wireName: r'action')
  String? get action;

  @BuiltValueField(wireName: r'code')
  String get code;

  @BuiltValueField(wireName: r'field_errors')
  BuiltList<FieldError> get fieldErrors;

  @BuiltValueField(wireName: r'message')
  String get message;

  @BuiltValueField(wireName: r'request_id')
  String get requestId;

  @BuiltValueField(wireName: r'retry_after_seconds')
  int? get retryAfterSeconds;

  @BuiltValueField(wireName: r'retryable')
  bool get retryable;

  ErrorDetail._();

  factory ErrorDetail([void updates(ErrorDetailBuilder b)]) = _$ErrorDetail;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ErrorDetailBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ErrorDetail> get serializer => _$ErrorDetailSerializer();
}

class _$ErrorDetailSerializer implements PrimitiveSerializer<ErrorDetail> {
  @override
  final Iterable<Type> types = const [ErrorDetail, _$ErrorDetail];

  @override
  final String wireName = r'ErrorDetail';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ErrorDetail object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'action';
    yield object.action == null ? null : serializers.serialize(
      object.action,
      specifiedType: const FullType.nullable(String),
    );
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
    yield r'field_errors';
    yield serializers.serialize(
      object.fieldErrors,
      specifiedType: const FullType(BuiltList, [FullType(FieldError)]),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
    yield r'request_id';
    yield serializers.serialize(
      object.requestId,
      specifiedType: const FullType(String),
    );
    yield r'retry_after_seconds';
    yield object.retryAfterSeconds == null ? null : serializers.serialize(
      object.retryAfterSeconds,
      specifiedType: const FullType.nullable(int),
    );
    yield r'retryable';
    yield serializers.serialize(
      object.retryable,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ErrorDetail object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ErrorDetailBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'action':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.action = valueDes;
          break;
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.code = valueDes;
          break;
        case r'field_errors':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(FieldError)]),
          ) as BuiltList<FieldError>;
          result.fieldErrors.replace(valueDes);
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        case r'request_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.requestId = valueDes;
          break;
        case r'retry_after_seconds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.retryAfterSeconds = valueDes;
          break;
        case r'retryable':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.retryable = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ErrorDetail deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ErrorDetailBuilder();
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


