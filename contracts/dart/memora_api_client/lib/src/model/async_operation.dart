//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'async_operation.g.dart';

/// AsyncOperation
///
/// Properties:
/// * [resourceId]
/// * [retryAfterSeconds]
/// * [status]
/// * [statusUrl]
/// * [updatedAt]
@BuiltValue()
abstract class AsyncOperation
    implements Built<AsyncOperation, AsyncOperationBuilder> {
  @BuiltValueField(wireName: r'resource_id')
  String get resourceId;

  @BuiltValueField(wireName: r'retry_after_seconds')
  int? get retryAfterSeconds;

  @BuiltValueField(wireName: r'status')
  String get status;

  @BuiltValueField(wireName: r'status_url')
  String get statusUrl;

  @BuiltValueField(wireName: r'updated_at')
  DateTime get updatedAt;

  AsyncOperation._();

  factory AsyncOperation([void updates(AsyncOperationBuilder b)]) =
      _$AsyncOperation;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AsyncOperationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AsyncOperation> get serializer =>
      _$AsyncOperationSerializer();
}

class _$AsyncOperationSerializer
    implements PrimitiveSerializer<AsyncOperation> {
  @override
  final Iterable<Type> types = const [AsyncOperation, _$AsyncOperation];

  @override
  final String wireName = r'AsyncOperation';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AsyncOperation object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'resource_id';
    yield serializers.serialize(
      object.resourceId,
      specifiedType: const FullType(String),
    );
    yield r'retry_after_seconds';
    yield object.retryAfterSeconds == null
        ? null
        : serializers.serialize(
            object.retryAfterSeconds,
            specifiedType: const FullType.nullable(int),
          );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
    yield r'status_url';
    yield serializers.serialize(
      object.statusUrl,
      specifiedType: const FullType(String),
    );
    yield r'updated_at';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AsyncOperation object, {
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
    required AsyncOperationBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'resource_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.resourceId = valueDes;
          break;
        case r'retry_after_seconds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.retryAfterSeconds = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        case r'status_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.statusUrl = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AsyncOperation deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AsyncOperationBuilder();
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
