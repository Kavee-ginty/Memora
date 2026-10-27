// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ConsentType _$terms = const ConsentType._('terms');
const ConsentType _$privacy = const ConsentType._('privacy');
const ConsentType _$materialProcessing =
    const ConsentType._('materialProcessing');
const ConsentType _$modelProcessing = const ConsentType._('modelProcessing');
const ConsentType _$notifications = const ConsentType._('notifications');
const ConsentType _$unknownDefaultOpenApi =
    const ConsentType._('unknownDefaultOpenApi');

ConsentType _$valueOf(String name) {
  switch (name) {
    case 'terms':
      return _$terms;
    case 'privacy':
      return _$privacy;
    case 'materialProcessing':
      return _$materialProcessing;
    case 'modelProcessing':
      return _$modelProcessing;
    case 'notifications':
      return _$notifications;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<ConsentType> _$values =
    BuiltSet<ConsentType>(const <ConsentType>[
  _$terms,
  _$privacy,
  _$materialProcessing,
  _$modelProcessing,
  _$notifications,
  _$unknownDefaultOpenApi,
]);

class _$ConsentTypeMeta {
  const _$ConsentTypeMeta();
  ConsentType get terms => _$terms;
  ConsentType get privacy => _$privacy;
  ConsentType get materialProcessing => _$materialProcessing;
  ConsentType get modelProcessing => _$modelProcessing;
  ConsentType get notifications => _$notifications;
  ConsentType get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  ConsentType valueOf(String name) => _$valueOf(name);
  BuiltSet<ConsentType> get values => _$values;
}

mixin _$ConsentTypeMixin {
  // ignore: non_constant_identifier_names
  _$ConsentTypeMeta get ConsentType => const _$ConsentTypeMeta();
}

Serializer<ConsentType> _$consentTypeSerializer = _$ConsentTypeSerializer();

class _$ConsentTypeSerializer implements PrimitiveSerializer<ConsentType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'terms': 'terms',
    'privacy': 'privacy',
    'materialProcessing': 'material_processing',
    'modelProcessing': 'model_processing',
    'notifications': 'notifications',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'terms': 'terms',
    'privacy': 'privacy',
    'material_processing': 'materialProcessing',
    'model_processing': 'modelProcessing',
    'notifications': 'notifications',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[ConsentType];
  @override
  final String wireName = 'ConsentType';

  @override
  Object serialize(Serializers serializers, ConsentType object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ConsentType deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ConsentType.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
