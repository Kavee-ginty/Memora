// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_decision.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ConsentDecision _$granted = const ConsentDecision._('granted');
const ConsentDecision _$declined = const ConsentDecision._('declined');
const ConsentDecision _$withdrawn = const ConsentDecision._('withdrawn');
const ConsentDecision _$unknownDefaultOpenApi =
    const ConsentDecision._('unknownDefaultOpenApi');

ConsentDecision _$valueOf(String name) {
  switch (name) {
    case 'granted':
      return _$granted;
    case 'declined':
      return _$declined;
    case 'withdrawn':
      return _$withdrawn;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<ConsentDecision> _$values =
    BuiltSet<ConsentDecision>(const <ConsentDecision>[
  _$granted,
  _$declined,
  _$withdrawn,
  _$unknownDefaultOpenApi,
]);

class _$ConsentDecisionMeta {
  const _$ConsentDecisionMeta();
  ConsentDecision get granted => _$granted;
  ConsentDecision get declined => _$declined;
  ConsentDecision get withdrawn => _$withdrawn;
  ConsentDecision get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  ConsentDecision valueOf(String name) => _$valueOf(name);
  BuiltSet<ConsentDecision> get values => _$values;
}

mixin _$ConsentDecisionMixin {
  // ignore: non_constant_identifier_names
  _$ConsentDecisionMeta get ConsentDecision => const _$ConsentDecisionMeta();
}

Serializer<ConsentDecision> _$consentDecisionSerializer =
    _$ConsentDecisionSerializer();

class _$ConsentDecisionSerializer
    implements PrimitiveSerializer<ConsentDecision> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'granted': 'granted',
    'declined': 'declined',
    'withdrawn': 'withdrawn',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'granted': 'granted',
    'declined': 'declined',
    'withdrawn': 'withdrawn',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[ConsentDecision];
  @override
  final String wireName = 'ConsentDecision';

  @override
  Object serialize(Serializers serializers, ConsentDecision object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ConsentDecision deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ConsentDecision.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
