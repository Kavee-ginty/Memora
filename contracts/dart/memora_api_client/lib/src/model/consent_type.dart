//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'consent_type.g.dart';

class ConsentType extends EnumClass {

  @BuiltValueEnumConst(wireName: r'terms')
  static const ConsentType terms = _$terms;
  @BuiltValueEnumConst(wireName: r'privacy')
  static const ConsentType privacy = _$privacy;
  @BuiltValueEnumConst(wireName: r'material_processing')
  static const ConsentType materialProcessing = _$materialProcessing;
  @BuiltValueEnumConst(wireName: r'model_processing')
  static const ConsentType modelProcessing = _$modelProcessing;
  @BuiltValueEnumConst(wireName: r'notifications')
  static const ConsentType notifications = _$notifications;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ConsentType unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<ConsentType> get serializer => _$consentTypeSerializer;

  const ConsentType._(String name): super(name);

  static BuiltSet<ConsentType> get values => _$values;
  static ConsentType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ConsentTypeMixin = Object with _$ConsentTypeMixin;

