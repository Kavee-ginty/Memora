// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_decision_value.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const VerificationDecisionValue _$accept =
    const VerificationDecisionValue._('accept');
const VerificationDecisionValue _$edit =
    const VerificationDecisionValue._('edit');
const VerificationDecisionValue _$reject =
    const VerificationDecisionValue._('reject');
const VerificationDecisionValue _$merge =
    const VerificationDecisionValue._('merge');
const VerificationDecisionValue _$unknownDefaultOpenApi =
    const VerificationDecisionValue._('unknownDefaultOpenApi');

VerificationDecisionValue _$valueOf(String name) {
  switch (name) {
    case 'accept':
      return _$accept;
    case 'edit':
      return _$edit;
    case 'reject':
      return _$reject;
    case 'merge':
      return _$merge;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<VerificationDecisionValue> _$values =
    BuiltSet<VerificationDecisionValue>(const <VerificationDecisionValue>[
  _$accept,
  _$edit,
  _$reject,
  _$merge,
  _$unknownDefaultOpenApi,
]);

class _$VerificationDecisionValueMeta {
  const _$VerificationDecisionValueMeta();
  VerificationDecisionValue get accept => _$accept;
  VerificationDecisionValue get edit => _$edit;
  VerificationDecisionValue get reject => _$reject;
  VerificationDecisionValue get merge => _$merge;
  VerificationDecisionValue get unknownDefaultOpenApi =>
      _$unknownDefaultOpenApi;
  VerificationDecisionValue valueOf(String name) => _$valueOf(name);
  BuiltSet<VerificationDecisionValue> get values => _$values;
}

mixin _$VerificationDecisionValueMixin {
  // ignore: non_constant_identifier_names
  _$VerificationDecisionValueMeta get VerificationDecisionValue =>
      const _$VerificationDecisionValueMeta();
}

Serializer<VerificationDecisionValue> _$verificationDecisionValueSerializer =
    _$VerificationDecisionValueSerializer();

class _$VerificationDecisionValueSerializer
    implements PrimitiveSerializer<VerificationDecisionValue> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'accept': 'accept',
    'edit': 'edit',
    'reject': 'reject',
    'merge': 'merge',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'accept': 'accept',
    'edit': 'edit',
    'reject': 'reject',
    'merge': 'merge',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[VerificationDecisionValue];
  @override
  final String wireName = 'VerificationDecisionValue';

  @override
  Object serialize(Serializers serializers, VerificationDecisionValue object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  VerificationDecisionValue deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      VerificationDecisionValue.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
