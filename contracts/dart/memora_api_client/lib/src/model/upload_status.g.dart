// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UploadStatus _$authorized = const UploadStatus._('authorized');
const UploadStatus _$uploaded = const UploadStatus._('uploaded');
const UploadStatus _$validated = const UploadStatus._('validated');
const UploadStatus _$processing = const UploadStatus._('processing');
const UploadStatus _$deleting = const UploadStatus._('deleting');
const UploadStatus _$deleted = const UploadStatus._('deleted');
const UploadStatus _$rejected = const UploadStatus._('rejected');
const UploadStatus _$expired = const UploadStatus._('expired');
const UploadStatus _$unknownDefaultOpenApi =
    const UploadStatus._('unknownDefaultOpenApi');

UploadStatus _$valueOf(String name) {
  switch (name) {
    case 'authorized':
      return _$authorized;
    case 'uploaded':
      return _$uploaded;
    case 'validated':
      return _$validated;
    case 'processing':
      return _$processing;
    case 'deleting':
      return _$deleting;
    case 'deleted':
      return _$deleted;
    case 'rejected':
      return _$rejected;
    case 'expired':
      return _$expired;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<UploadStatus> _$values =
    BuiltSet<UploadStatus>(const <UploadStatus>[
  _$authorized,
  _$uploaded,
  _$validated,
  _$processing,
  _$deleting,
  _$deleted,
  _$rejected,
  _$expired,
  _$unknownDefaultOpenApi,
]);

class _$UploadStatusMeta {
  const _$UploadStatusMeta();
  UploadStatus get authorized => _$authorized;
  UploadStatus get uploaded => _$uploaded;
  UploadStatus get validated => _$validated;
  UploadStatus get processing => _$processing;
  UploadStatus get deleting => _$deleting;
  UploadStatus get deleted => _$deleted;
  UploadStatus get rejected => _$rejected;
  UploadStatus get expired => _$expired;
  UploadStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  UploadStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<UploadStatus> get values => _$values;
}

mixin _$UploadStatusMixin {
  // ignore: non_constant_identifier_names
  _$UploadStatusMeta get UploadStatus => const _$UploadStatusMeta();
}

Serializer<UploadStatus> _$uploadStatusSerializer = _$UploadStatusSerializer();

class _$UploadStatusSerializer implements PrimitiveSerializer<UploadStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'authorized': 'authorized',
    'uploaded': 'uploaded',
    'validated': 'validated',
    'processing': 'processing',
    'deleting': 'deleting',
    'deleted': 'deleted',
    'rejected': 'rejected',
    'expired': 'expired',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'authorized': 'authorized',
    'uploaded': 'uploaded',
    'validated': 'validated',
    'processing': 'processing',
    'deleting': 'deleting',
    'deleted': 'deleted',
    'rejected': 'rejected',
    'expired': 'expired',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[UploadStatus];
  @override
  final String wireName = 'UploadStatus';

  @override
  Object serialize(Serializers serializers, UploadStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UploadStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UploadStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
