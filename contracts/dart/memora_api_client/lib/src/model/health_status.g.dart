// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const HealthStatus _$ok = const HealthStatus._('ok');
const HealthStatus _$unknownDefaultOpenApi =
    const HealthStatus._('unknownDefaultOpenApi');

HealthStatus _$valueOf(String name) {
  switch (name) {
    case 'ok':
      return _$ok;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<HealthStatus> _$values =
    BuiltSet<HealthStatus>(const <HealthStatus>[
  _$ok,
  _$unknownDefaultOpenApi,
]);

class _$HealthStatusMeta {
  const _$HealthStatusMeta();
  HealthStatus get ok => _$ok;
  HealthStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  HealthStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<HealthStatus> get values => _$values;
}

mixin _$HealthStatusMixin {
  // ignore: non_constant_identifier_names
  _$HealthStatusMeta get HealthStatus => const _$HealthStatusMeta();
}

Serializer<HealthStatus> _$healthStatusSerializer = _$HealthStatusSerializer();

class _$HealthStatusSerializer implements PrimitiveSerializer<HealthStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ok': 'ok',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ok': 'ok',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[HealthStatus];
  @override
  final String wireName = 'HealthStatus';

  @override
  Object serialize(Serializers serializers, HealthStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  HealthStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      HealthStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
