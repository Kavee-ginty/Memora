// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AccountStatus _$active = const AccountStatus._('active');
const AccountStatus _$suspended = const AccountStatus._('suspended');
const AccountStatus _$deletionPending =
    const AccountStatus._('deletionPending');
const AccountStatus _$deleted = const AccountStatus._('deleted');
const AccountStatus _$unknownDefaultOpenApi =
    const AccountStatus._('unknownDefaultOpenApi');

AccountStatus _$valueOf(String name) {
  switch (name) {
    case 'active':
      return _$active;
    case 'suspended':
      return _$suspended;
    case 'deletionPending':
      return _$deletionPending;
    case 'deleted':
      return _$deleted;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<AccountStatus> _$values =
    BuiltSet<AccountStatus>(const <AccountStatus>[
  _$active,
  _$suspended,
  _$deletionPending,
  _$deleted,
  _$unknownDefaultOpenApi,
]);

class _$AccountStatusMeta {
  const _$AccountStatusMeta();
  AccountStatus get active => _$active;
  AccountStatus get suspended => _$suspended;
  AccountStatus get deletionPending => _$deletionPending;
  AccountStatus get deleted => _$deleted;
  AccountStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  AccountStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<AccountStatus> get values => _$values;
}

mixin _$AccountStatusMixin {
  // ignore: non_constant_identifier_names
  _$AccountStatusMeta get AccountStatus => const _$AccountStatusMeta();
}

Serializer<AccountStatus> _$accountStatusSerializer =
    _$AccountStatusSerializer();

class _$AccountStatusSerializer implements PrimitiveSerializer<AccountStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'active': 'active',
    'suspended': 'suspended',
    'deletionPending': 'deletion_pending',
    'deleted': 'deleted',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'active': 'active',
    'suspended': 'suspended',
    'deletion_pending': 'deletionPending',
    'deleted': 'deleted',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[AccountStatus];
  @override
  final String wireName = 'AccountStatus';

  @override
  Object serialize(Serializers serializers, AccountStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AccountStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AccountStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
