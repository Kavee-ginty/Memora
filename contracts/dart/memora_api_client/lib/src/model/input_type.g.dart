// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const InputType _$manualText = const InputType._('manualText');
const InputType _$pdf = const InputType._('pdf');
const InputType _$image = const InputType._('image');
const InputType _$mixed = const InputType._('mixed');
const InputType _$unknownDefaultOpenApi =
    const InputType._('unknownDefaultOpenApi');

InputType _$valueOf(String name) {
  switch (name) {
    case 'manualText':
      return _$manualText;
    case 'pdf':
      return _$pdf;
    case 'image':
      return _$image;
    case 'mixed':
      return _$mixed;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<InputType> _$values = BuiltSet<InputType>(const <InputType>[
  _$manualText,
  _$pdf,
  _$image,
  _$mixed,
  _$unknownDefaultOpenApi,
]);

class _$InputTypeMeta {
  const _$InputTypeMeta();
  InputType get manualText => _$manualText;
  InputType get pdf => _$pdf;
  InputType get image => _$image;
  InputType get mixed => _$mixed;
  InputType get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  InputType valueOf(String name) => _$valueOf(name);
  BuiltSet<InputType> get values => _$values;
}

mixin _$InputTypeMixin {
  // ignore: non_constant_identifier_names
  _$InputTypeMeta get InputType => const _$InputTypeMeta();
}

Serializer<InputType> _$inputTypeSerializer = _$InputTypeSerializer();

class _$InputTypeSerializer implements PrimitiveSerializer<InputType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'manualText': 'manual_text',
    'pdf': 'pdf',
    'image': 'image',
    'mixed': 'mixed',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'manual_text': 'manualText',
    'pdf': 'pdf',
    'image': 'image',
    'mixed': 'mixed',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[InputType];
  @override
  final String wireName = 'InputType';

  @override
  Object serialize(Serializers serializers, InputType object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  InputType deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      InputType.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
