//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'public_response_config.g.dart';

/// PublicResponseConfig
///
/// Properties:
/// * [inputHint]
/// * [maxCharacters]
/// * [maxSelections]
/// * [minSelections]
/// * [type]
/// * [unitAffordance]
/// * [unitOptions]
@BuiltValue()
abstract class PublicResponseConfig
    implements Built<PublicResponseConfig, PublicResponseConfigBuilder> {
  @BuiltValueField(wireName: r'input_hint')
  Optional<String?> get inputHint;

  @BuiltValueField(wireName: r'max_characters')
  Optional<int?> get maxCharacters;

  @BuiltValueField(wireName: r'max_selections')
  Optional<int?> get maxSelections;

  @BuiltValueField(wireName: r'min_selections')
  Optional<int?> get minSelections;

  @BuiltValueField(wireName: r'type')
  PublicResponseConfigTypeEnum get type;
  // enum typeEnum {  single_choice,  multiple_choice,  numeric,  short_answer,  };

  @BuiltValueField(wireName: r'unit_affordance')
  Optional<bool?> get unitAffordance;

  @BuiltValueField(wireName: r'unit_options')
  BuiltList<String> get unitOptions;

  PublicResponseConfig._();

  factory PublicResponseConfig([void updates(PublicResponseConfigBuilder b)]) =
      _$PublicResponseConfig;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PublicResponseConfigBuilder b) => b
    ..inputHint = Optional.absent()
    ..maxCharacters = Optional.absent()
    ..maxSelections = Optional.absent()
    ..minSelections = Optional.absent()
    ..unitAffordance = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<PublicResponseConfig> get serializer =>
      _$PublicResponseConfigSerializer();
}

class _$PublicResponseConfigSerializer
    implements PrimitiveSerializer<PublicResponseConfig> {
  @override
  final Iterable<Type> types = const [
    PublicResponseConfig,
    _$PublicResponseConfig
  ];

  @override
  final String wireName = r'PublicResponseConfig';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PublicResponseConfig object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.inputHint.isPresent) {
      yield r'input_hint';
      final optionalValue = object.inputHint.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    if (object.maxCharacters.isPresent) {
      yield r'max_characters';
      final optionalValue = object.maxCharacters.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(int),
        );
      }
    }
    if (object.maxSelections.isPresent) {
      yield r'max_selections';
      final optionalValue = object.maxSelections.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(int),
        );
      }
    }
    if (object.minSelections.isPresent) {
      yield r'min_selections';
      final optionalValue = object.minSelections.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(int),
        );
      }
    }
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PublicResponseConfigTypeEnum),
    );
    if (object.unitAffordance.isPresent) {
      yield r'unit_affordance';
      final optionalValue = object.unitAffordance.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(bool),
        );
      }
    }
    yield r'unit_options';
    yield serializers.serialize(
      object.unitOptions,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PublicResponseConfig object, {
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
    required PublicResponseConfigBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'input_hint':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.inputHint = Optional.present(valueDes);
          break;
        case r'max_characters':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          result.maxCharacters = Optional.present(valueDes);
          break;
        case r'max_selections':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          result.maxSelections = Optional.present(valueDes);
          break;
        case r'min_selections':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          result.minSelections = Optional.present(valueDes);
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PublicResponseConfigTypeEnum),
          ) as PublicResponseConfigTypeEnum;
          result.type = valueDes;
          break;
        case r'unit_affordance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          result.unitAffordance = Optional.present(valueDes);
          break;
        case r'unit_options':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.unitOptions.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PublicResponseConfig deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PublicResponseConfigBuilder();
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

class PublicResponseConfigTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'single_choice')
  static const PublicResponseConfigTypeEnum singleChoice =
      _$publicResponseConfigTypeEnum_singleChoice;
  @BuiltValueEnumConst(wireName: r'multiple_choice')
  static const PublicResponseConfigTypeEnum multipleChoice =
      _$publicResponseConfigTypeEnum_multipleChoice;
  @BuiltValueEnumConst(wireName: r'numeric')
  static const PublicResponseConfigTypeEnum numeric =
      _$publicResponseConfigTypeEnum_numeric;
  @BuiltValueEnumConst(wireName: r'short_answer')
  static const PublicResponseConfigTypeEnum shortAnswer =
      _$publicResponseConfigTypeEnum_shortAnswer;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const PublicResponseConfigTypeEnum unknownDefaultOpenApi =
      _$publicResponseConfigTypeEnum_unknownDefaultOpenApi;

  static Serializer<PublicResponseConfigTypeEnum> get serializer =>
      _$publicResponseConfigTypeEnumSerializer;

  const PublicResponseConfigTypeEnum._(String name) : super(name);

  static BuiltSet<PublicResponseConfigTypeEnum> get values =>
      _$publicResponseConfigTypeEnumValues;
  static PublicResponseConfigTypeEnum valueOf(String name) =>
      _$publicResponseConfigTypeEnumValueOf(name);
}
