//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'idempotency_headers.g.dart';

/// IdempotencyHeaders
///
/// Properties:
/// * [idempotencyKey] 
@BuiltValue()
abstract class IdempotencyHeaders implements Built<IdempotencyHeaders, IdempotencyHeadersBuilder> {
  @BuiltValueField(wireName: r'Idempotency-Key')
  String get idempotencyKey;

  IdempotencyHeaders._();

  factory IdempotencyHeaders([void updates(IdempotencyHeadersBuilder b)]) = _$IdempotencyHeaders;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(IdempotencyHeadersBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<IdempotencyHeaders> get serializer => _$IdempotencyHeadersSerializer();
}

class _$IdempotencyHeadersSerializer implements PrimitiveSerializer<IdempotencyHeaders> {
  @override
  final Iterable<Type> types = const [IdempotencyHeaders, _$IdempotencyHeaders];

  @override
  final String wireName = r'IdempotencyHeaders';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    IdempotencyHeaders object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'Idempotency-Key';
    yield serializers.serialize(
      object.idempotencyKey,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    IdempotencyHeaders object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required IdempotencyHeadersBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'Idempotency-Key':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.idempotencyKey = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  IdempotencyHeaders deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = IdempotencyHeadersBuilder();
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


