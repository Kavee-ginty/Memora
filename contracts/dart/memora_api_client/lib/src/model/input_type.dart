//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'input_type.g.dart';

class InputType extends EnumClass {
  @BuiltValueEnumConst(wireName: r'manual_text')
  static const InputType manualText = _$manualText;
  @BuiltValueEnumConst(wireName: r'pdf')
  static const InputType pdf = _$pdf;
  @BuiltValueEnumConst(wireName: r'image')
  static const InputType image = _$image;
  @BuiltValueEnumConst(wireName: r'mixed')
  static const InputType mixed = _$mixed;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const InputType unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<InputType> get serializer => _$inputTypeSerializer;

  const InputType._(String name) : super(name);

  static BuiltSet<InputType> get values => _$values;
  static InputType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class InputTypeMixin = Object with _$InputTypeMixin;
