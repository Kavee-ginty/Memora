// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DeletionStatus _$notRequired = const DeletionStatus._('notRequired');
const DeletionStatus _$pending = const DeletionStatus._('pending');
const DeletionStatus _$deleted = const DeletionStatus._('deleted');
const DeletionStatus _$failed = const DeletionStatus._('failed');
const DeletionStatus _$unknownDefaultOpenApi =
    const DeletionStatus._('unknownDefaultOpenApi');

DeletionStatus _$valueOf(String name) {
  switch (name) {
    case 'notRequired':
      return _$notRequired;
    case 'pending':
      return _$pending;
    case 'deleted':
      return _$deleted;
    case 'failed':
      return _$failed;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<DeletionStatus> _$values =
    BuiltSet<DeletionStatus>(const <DeletionStatus>[
  _$notRequired,
  _$pending,
  _$deleted,
  _$failed,
  _$unknownDefaultOpenApi,
]);

class _$DeletionStatusMeta {
  const _$DeletionStatusMeta();
  DeletionStatus get notRequired => _$notRequired;
  DeletionStatus get pending => _$pending;
  DeletionStatus get deleted => _$deleted;
  DeletionStatus get failed => _$failed;
  DeletionStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  DeletionStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<DeletionStatus> get values => _$values;
}

mixin _$DeletionStatusMixin {
  // ignore: non_constant_identifier_names
  _$DeletionStatusMeta get DeletionStatus => const _$DeletionStatusMeta();
}

Serializer<DeletionStatus> _$deletionStatusSerializer =
    _$DeletionStatusSerializer();

class _$DeletionStatusSerializer
    implements PrimitiveSerializer<DeletionStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'notRequired': 'not_required',
    'pending': 'pending',
    'deleted': 'deleted',
    'failed': 'failed',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'not_required': 'notRequired',
    'pending': 'pending',
    'deleted': 'deleted',
    'failed': 'failed',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[DeletionStatus];
  @override
  final String wireName = 'DeletionStatus';

  @override
  Object serialize(Serializers serializers, DeletionStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  DeletionStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      DeletionStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
