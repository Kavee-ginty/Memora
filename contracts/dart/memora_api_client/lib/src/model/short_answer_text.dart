//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'short_answer_text.g.dart';

/// ShortAnswerText
///
/// Properties:
/// * [text]
/// * [type]
@BuiltValue()
abstract class ShortAnswerText
    implements Built<ShortAnswerText, ShortAnswerTextBuilder> {
  @BuiltValueField(wireName: r'text')
  String get text;

  @BuiltValueField(wireName: r'type')
  ShortAnswerTextTypeEnum get type;
  // enum typeEnum {  short_answer,  };

  ShortAnswerText._();

  factory ShortAnswerText([void updates(ShortAnswerTextBuilder b)]) =
      _$ShortAnswerText;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ShortAnswerTextBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ShortAnswerText> get serializer =>
      _$ShortAnswerTextSerializer();
}

class _$ShortAnswerTextSerializer
    implements PrimitiveSerializer<ShortAnswerText> {
  @override
  final Iterable<Type> types = const [ShortAnswerText, _$ShortAnswerText];

  @override
  final String wireName = r'ShortAnswerText';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ShortAnswerText object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'text';
    yield serializers.serialize(
      object.text,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(ShortAnswerTextTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ShortAnswerText object, {
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
    required ShortAnswerTextBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.text = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ShortAnswerTextTypeEnum),
          ) as ShortAnswerTextTypeEnum;
          result.type = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ShortAnswerText deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ShortAnswerTextBuilder();
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

class ShortAnswerTextTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'short_answer')
  static const ShortAnswerTextTypeEnum shortAnswer =
      _$shortAnswerTextTypeEnum_shortAnswer;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ShortAnswerTextTypeEnum unknownDefaultOpenApi =
      _$shortAnswerTextTypeEnum_unknownDefaultOpenApi;

  static Serializer<ShortAnswerTextTypeEnum> get serializer =>
      _$shortAnswerTextTypeEnumSerializer;

  const ShortAnswerTextTypeEnum._(String name) : super(name);

  static BuiltSet<ShortAnswerTextTypeEnum> get values =>
      _$shortAnswerTextTypeEnumValues;
  static ShortAnswerTextTypeEnum valueOf(String name) =>
      _$shortAnswerTextTypeEnumValueOf(name);
}
