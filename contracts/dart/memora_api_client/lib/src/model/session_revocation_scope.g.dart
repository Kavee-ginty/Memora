// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_revocation_scope.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const SessionRevocationScope _$current =
    const SessionRevocationScope._('current');
const SessionRevocationScope _$otherSessions =
    const SessionRevocationScope._('otherSessions');
const SessionRevocationScope _$all = const SessionRevocationScope._('all');
const SessionRevocationScope _$unknownDefaultOpenApi =
    const SessionRevocationScope._('unknownDefaultOpenApi');

SessionRevocationScope _$valueOf(String name) {
  switch (name) {
    case 'current':
      return _$current;
    case 'otherSessions':
      return _$otherSessions;
    case 'all':
      return _$all;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<SessionRevocationScope> _$values =
    BuiltSet<SessionRevocationScope>(const <SessionRevocationScope>[
  _$current,
  _$otherSessions,
  _$all,
  _$unknownDefaultOpenApi,
]);

class _$SessionRevocationScopeMeta {
  const _$SessionRevocationScopeMeta();
  SessionRevocationScope get current => _$current;
  SessionRevocationScope get otherSessions => _$otherSessions;
  SessionRevocationScope get all => _$all;
  SessionRevocationScope get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  SessionRevocationScope valueOf(String name) => _$valueOf(name);
  BuiltSet<SessionRevocationScope> get values => _$values;
}

mixin _$SessionRevocationScopeMixin {
  // ignore: non_constant_identifier_names
  _$SessionRevocationScopeMeta get SessionRevocationScope =>
      const _$SessionRevocationScopeMeta();
}

Serializer<SessionRevocationScope> _$sessionRevocationScopeSerializer =
    _$SessionRevocationScopeSerializer();

class _$SessionRevocationScopeSerializer
    implements PrimitiveSerializer<SessionRevocationScope> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'current': 'current',
    'otherSessions': 'other_sessions',
    'all': 'all',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'current': 'current',
    'other_sessions': 'otherSessions',
    'all': 'all',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[SessionRevocationScope];
  @override
  final String wireName = 'SessionRevocationScope';

  @override
  Object serialize(Serializers serializers, SessionRevocationScope object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  SessionRevocationScope deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      SessionRevocationScope.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
