//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'dart:core';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/any_of.dart';

part 'value.g.dart';

/// Value
@BuiltValue()
abstract class Value implements Built<Value, ValueBuilder> {
  /// Any Of [String], [num]
  AnyOf get anyOf;

  Value._();

  factory Value([void updates(ValueBuilder b)]) = _$Value;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ValueBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Value> get serializer => _$ValueSerializer();
}

class _$ValueSerializer implements PrimitiveSerializer<Value> {
  @override
  final Iterable<Type> types = const [Value, _$Value];

  @override
  final String wireName = r'Value';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Value object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {}

  @override
  Object serialize(
    Serializers serializers,
    Value object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final anyOf = object.anyOf;
    return serializers.serialize(anyOf,
        specifiedType: FullType(
            AnyOf, anyOf.types.map((type) => FullType(type)).toList()))!;
  }

  @override
  Value deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ValueBuilder();
    Object? anyOfDataSrc;
    final targetType = const FullType(AnyOf, [
      FullType(num),
      FullType(String),
    ]);
    anyOfDataSrc = serialized;
    result.anyOf = serializers.deserialize(anyOfDataSrc,
        specifiedType: targetType) as AnyOf;
    return result.build();
  }
}
