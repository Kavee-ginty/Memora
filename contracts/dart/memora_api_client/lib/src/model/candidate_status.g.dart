// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candidate_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CandidateStatus _$candidate = const CandidateStatus._('candidate');
const CandidateStatus _$needsVerification =
    const CandidateStatus._('needsVerification');
const CandidateStatus _$accepted = const CandidateStatus._('accepted');
const CandidateStatus _$rejected = const CandidateStatus._('rejected');
const CandidateStatus _$committed = const CandidateStatus._('committed');
const CandidateStatus _$expired = const CandidateStatus._('expired');
const CandidateStatus _$unknownDefaultOpenApi =
    const CandidateStatus._('unknownDefaultOpenApi');

CandidateStatus _$valueOf(String name) {
  switch (name) {
    case 'candidate':
      return _$candidate;
    case 'needsVerification':
      return _$needsVerification;
    case 'accepted':
      return _$accepted;
    case 'rejected':
      return _$rejected;
    case 'committed':
      return _$committed;
    case 'expired':
      return _$expired;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<CandidateStatus> _$values =
    BuiltSet<CandidateStatus>(const <CandidateStatus>[
  _$candidate,
  _$needsVerification,
  _$accepted,
  _$rejected,
  _$committed,
  _$expired,
  _$unknownDefaultOpenApi,
]);

class _$CandidateStatusMeta {
  const _$CandidateStatusMeta();
  CandidateStatus get candidate => _$candidate;
  CandidateStatus get needsVerification => _$needsVerification;
  CandidateStatus get accepted => _$accepted;
  CandidateStatus get rejected => _$rejected;
  CandidateStatus get committed => _$committed;
  CandidateStatus get expired => _$expired;
  CandidateStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  CandidateStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<CandidateStatus> get values => _$values;
}

mixin _$CandidateStatusMixin {
  // ignore: non_constant_identifier_names
  _$CandidateStatusMeta get CandidateStatus => const _$CandidateStatusMeta();
}

Serializer<CandidateStatus> _$candidateStatusSerializer =
    _$CandidateStatusSerializer();

class _$CandidateStatusSerializer
    implements PrimitiveSerializer<CandidateStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'candidate': 'candidate',
    'needsVerification': 'needs_verification',
    'accepted': 'accepted',
    'rejected': 'rejected',
    'committed': 'committed',
    'expired': 'expired',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'candidate': 'candidate',
    'needs_verification': 'needsVerification',
    'accepted': 'accepted',
    'rejected': 'rejected',
    'committed': 'committed',
    'expired': 'expired',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[CandidateStatus];
  @override
  final String wireName = 'CandidateStatus';

  @override
  Object serialize(Serializers serializers, CandidateStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  CandidateStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      CandidateStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
