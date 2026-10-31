//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'consent_decision.g.dart';

class ConsentDecision extends EnumClass {
  @BuiltValueEnumConst(wireName: r'granted')
  static const ConsentDecision granted = _$granted;
  @BuiltValueEnumConst(wireName: r'declined')
  static const ConsentDecision declined = _$declined;
  @BuiltValueEnumConst(wireName: r'withdrawn')
  static const ConsentDecision withdrawn = _$withdrawn;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ConsentDecision unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<ConsentDecision> get serializer =>
      _$consentDecisionSerializer;

  const ConsentDecision._(String name) : super(name);

  static BuiltSet<ConsentDecision> get values => _$values;
  static ConsentDecision valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ConsentDecisionMixin = Object with _$ConsentDecisionMixin;
