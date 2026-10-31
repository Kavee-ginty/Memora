// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_update_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const LearningUpdateStatus _$draft = const LearningUpdateStatus._('draft');
const LearningUpdateStatus _$uploading =
    const LearningUpdateStatus._('uploading');
const LearningUpdateStatus _$processing =
    const LearningUpdateStatus._('processing');
const LearningUpdateStatus _$verificationRequired =
    const LearningUpdateStatus._('verificationRequired');
const LearningUpdateStatus _$committed =
    const LearningUpdateStatus._('committed');
const LearningUpdateStatus _$failed = const LearningUpdateStatus._('failed');
const LearningUpdateStatus _$expired = const LearningUpdateStatus._('expired');
const LearningUpdateStatus _$deleted = const LearningUpdateStatus._('deleted');
const LearningUpdateStatus _$unknownDefaultOpenApi =
    const LearningUpdateStatus._('unknownDefaultOpenApi');

LearningUpdateStatus _$valueOf(String name) {
  switch (name) {
    case 'draft':
      return _$draft;
    case 'uploading':
      return _$uploading;
    case 'processing':
      return _$processing;
    case 'verificationRequired':
      return _$verificationRequired;
    case 'committed':
      return _$committed;
    case 'failed':
      return _$failed;
    case 'expired':
      return _$expired;
    case 'deleted':
      return _$deleted;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<LearningUpdateStatus> _$values =
    BuiltSet<LearningUpdateStatus>(const <LearningUpdateStatus>[
  _$draft,
  _$uploading,
  _$processing,
  _$verificationRequired,
  _$committed,
  _$failed,
  _$expired,
  _$deleted,
  _$unknownDefaultOpenApi,
]);

class _$LearningUpdateStatusMeta {
  const _$LearningUpdateStatusMeta();
  LearningUpdateStatus get draft => _$draft;
  LearningUpdateStatus get uploading => _$uploading;
  LearningUpdateStatus get processing => _$processing;
  LearningUpdateStatus get verificationRequired => _$verificationRequired;
  LearningUpdateStatus get committed => _$committed;
  LearningUpdateStatus get failed => _$failed;
  LearningUpdateStatus get expired => _$expired;
  LearningUpdateStatus get deleted => _$deleted;
  LearningUpdateStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  LearningUpdateStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<LearningUpdateStatus> get values => _$values;
}

mixin _$LearningUpdateStatusMixin {
  // ignore: non_constant_identifier_names
  _$LearningUpdateStatusMeta get LearningUpdateStatus =>
      const _$LearningUpdateStatusMeta();
}

Serializer<LearningUpdateStatus> _$learningUpdateStatusSerializer =
    _$LearningUpdateStatusSerializer();

class _$LearningUpdateStatusSerializer
    implements PrimitiveSerializer<LearningUpdateStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'draft': 'draft',
    'uploading': 'uploading',
    'processing': 'processing',
    'verificationRequired': 'verification_required',
    'committed': 'committed',
    'failed': 'failed',
    'expired': 'expired',
    'deleted': 'deleted',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'draft': 'draft',
    'uploading': 'uploading',
    'processing': 'processing',
    'verification_required': 'verificationRequired',
    'committed': 'committed',
    'failed': 'failed',
    'expired': 'expired',
    'deleted': 'deleted',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[LearningUpdateStatus];
  @override
  final String wireName = 'LearningUpdateStatus';

  @override
  Object serialize(Serializers serializers, LearningUpdateStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  LearningUpdateStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      LearningUpdateStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
