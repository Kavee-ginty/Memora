//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'public_question_option.g.dart';

/// PublicQuestionOption
///
/// Properties:
/// * [accessibleImageRef]
/// * [displayOrder]
/// * [displayText]
/// * [optionKey]
@BuiltValue()
abstract class PublicQuestionOption
    implements Built<PublicQuestionOption, PublicQuestionOptionBuilder> {
  @BuiltValueField(wireName: r'accessible_image_ref')
  String? get accessibleImageRef;

  @BuiltValueField(wireName: r'display_order')
  int get displayOrder;

  @BuiltValueField(wireName: r'display_text')
  String get displayText;

  @BuiltValueField(wireName: r'option_key')
  String get optionKey;

  PublicQuestionOption._();

  factory PublicQuestionOption([void updates(PublicQuestionOptionBuilder b)]) =
      _$PublicQuestionOption;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PublicQuestionOptionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PublicQuestionOption> get serializer =>
      _$PublicQuestionOptionSerializer();
}

class _$PublicQuestionOptionSerializer
    implements PrimitiveSerializer<PublicQuestionOption> {
  @override
  final Iterable<Type> types = const [
    PublicQuestionOption,
    _$PublicQuestionOption
  ];

  @override
  final String wireName = r'PublicQuestionOption';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PublicQuestionOption object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'accessible_image_ref';
    yield object.accessibleImageRef == null
        ? null
        : serializers.serialize(
            object.accessibleImageRef,
            specifiedType: const FullType.nullable(String),
          );
    yield r'display_order';
    yield serializers.serialize(
      object.displayOrder,
      specifiedType: const FullType(int),
    );
    yield r'display_text';
    yield serializers.serialize(
      object.displayText,
      specifiedType: const FullType(String),
    );
    yield r'option_key';
    yield serializers.serialize(
      object.optionKey,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PublicQuestionOption object, {
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
    required PublicQuestionOptionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'accessible_image_ref':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.accessibleImageRef = valueDes;
          break;
        case r'display_order':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.displayOrder = valueDes;
          break;
        case r'display_text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.displayText = valueDes;
          break;
        case r'option_key':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.optionKey = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PublicQuestionOption deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PublicQuestionOptionBuilder();
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
