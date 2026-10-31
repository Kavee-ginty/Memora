// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_deletion_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PrivacyDeletionResponseRequestTypeEnum
    _$privacyDeletionResponseRequestTypeEnum_delete =
    const PrivacyDeletionResponseRequestTypeEnum._('delete');
const PrivacyDeletionResponseRequestTypeEnum
    _$privacyDeletionResponseRequestTypeEnum_unknownDefaultOpenApi =
    const PrivacyDeletionResponseRequestTypeEnum._('unknownDefaultOpenApi');

PrivacyDeletionResponseRequestTypeEnum
    _$privacyDeletionResponseRequestTypeEnumValueOf(String name) {
  switch (name) {
    case 'delete':
      return _$privacyDeletionResponseRequestTypeEnum_delete;
    case 'unknownDefaultOpenApi':
      return _$privacyDeletionResponseRequestTypeEnum_unknownDefaultOpenApi;
    default:
      return _$privacyDeletionResponseRequestTypeEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<PrivacyDeletionResponseRequestTypeEnum>
    _$privacyDeletionResponseRequestTypeEnumValues = BuiltSet<
        PrivacyDeletionResponseRequestTypeEnum>(const <PrivacyDeletionResponseRequestTypeEnum>[
  _$privacyDeletionResponseRequestTypeEnum_delete,
  _$privacyDeletionResponseRequestTypeEnum_unknownDefaultOpenApi,
]);

const PrivacyDeletionResponseStatusEnum
    _$privacyDeletionResponseStatusEnum_requested =
    const PrivacyDeletionResponseStatusEnum._('requested');
const PrivacyDeletionResponseStatusEnum
    _$privacyDeletionResponseStatusEnum_verifying =
    const PrivacyDeletionResponseStatusEnum._('verifying');
const PrivacyDeletionResponseStatusEnum
    _$privacyDeletionResponseStatusEnum_processing =
    const PrivacyDeletionResponseStatusEnum._('processing');
const PrivacyDeletionResponseStatusEnum
    _$privacyDeletionResponseStatusEnum_completed =
    const PrivacyDeletionResponseStatusEnum._('completed');
const PrivacyDeletionResponseStatusEnum
    _$privacyDeletionResponseStatusEnum_failed =
    const PrivacyDeletionResponseStatusEnum._('failed');
const PrivacyDeletionResponseStatusEnum
    _$privacyDeletionResponseStatusEnum_cancelled =
    const PrivacyDeletionResponseStatusEnum._('cancelled');
const PrivacyDeletionResponseStatusEnum
    _$privacyDeletionResponseStatusEnum_unknownDefaultOpenApi =
    const PrivacyDeletionResponseStatusEnum._('unknownDefaultOpenApi');

PrivacyDeletionResponseStatusEnum _$privacyDeletionResponseStatusEnumValueOf(
    String name) {
  switch (name) {
    case 'requested':
      return _$privacyDeletionResponseStatusEnum_requested;
    case 'verifying':
      return _$privacyDeletionResponseStatusEnum_verifying;
    case 'processing':
      return _$privacyDeletionResponseStatusEnum_processing;
    case 'completed':
      return _$privacyDeletionResponseStatusEnum_completed;
    case 'failed':
      return _$privacyDeletionResponseStatusEnum_failed;
    case 'cancelled':
      return _$privacyDeletionResponseStatusEnum_cancelled;
    case 'unknownDefaultOpenApi':
      return _$privacyDeletionResponseStatusEnum_unknownDefaultOpenApi;
    default:
      return _$privacyDeletionResponseStatusEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<PrivacyDeletionResponseStatusEnum>
    _$privacyDeletionResponseStatusEnumValues = BuiltSet<
        PrivacyDeletionResponseStatusEnum>(const <PrivacyDeletionResponseStatusEnum>[
  _$privacyDeletionResponseStatusEnum_requested,
  _$privacyDeletionResponseStatusEnum_verifying,
  _$privacyDeletionResponseStatusEnum_processing,
  _$privacyDeletionResponseStatusEnum_completed,
  _$privacyDeletionResponseStatusEnum_failed,
  _$privacyDeletionResponseStatusEnum_cancelled,
  _$privacyDeletionResponseStatusEnum_unknownDefaultOpenApi,
]);

Serializer<PrivacyDeletionResponseRequestTypeEnum>
    _$privacyDeletionResponseRequestTypeEnumSerializer =
    _$PrivacyDeletionResponseRequestTypeEnumSerializer();
Serializer<PrivacyDeletionResponseStatusEnum>
    _$privacyDeletionResponseStatusEnumSerializer =
    _$PrivacyDeletionResponseStatusEnumSerializer();

class _$PrivacyDeletionResponseRequestTypeEnumSerializer
    implements PrimitiveSerializer<PrivacyDeletionResponseRequestTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'delete': 'delete',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'delete': 'delete',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PrivacyDeletionResponseRequestTypeEnum
  ];
  @override
  final String wireName = 'PrivacyDeletionResponseRequestTypeEnum';

  @override
  Object serialize(Serializers serializers,
          PrivacyDeletionResponseRequestTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  PrivacyDeletionResponseRequestTypeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      PrivacyDeletionResponseRequestTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$PrivacyDeletionResponseStatusEnumSerializer
    implements PrimitiveSerializer<PrivacyDeletionResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'requested': 'requested',
    'verifying': 'verifying',
    'processing': 'processing',
    'completed': 'completed',
    'failed': 'failed',
    'cancelled': 'cancelled',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'requested': 'requested',
    'verifying': 'verifying',
    'processing': 'processing',
    'completed': 'completed',
    'failed': 'failed',
    'cancelled': 'cancelled',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[PrivacyDeletionResponseStatusEnum];
  @override
  final String wireName = 'PrivacyDeletionResponseStatusEnum';

  @override
  Object serialize(
          Serializers serializers, PrivacyDeletionResponseStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  PrivacyDeletionResponseStatusEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      PrivacyDeletionResponseStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$PrivacyDeletionResponse extends PrivacyDeletionResponse {
  @override
  final Optional<String?> completedAt;
  @override
  final Optional<String?> failureCode;
  @override
  final String id;
  @override
  final BuiltList<DeletionProofSummary> proofs;
  @override
  final Optional<PrivacyDeletionResponseRequestTypeEnum?> requestType;
  @override
  final String requestedAt;
  @override
  final BuiltList<String> retentionExceptions;
  @override
  final PrivacyDeletionResponseStatusEnum status;

  factory _$PrivacyDeletionResponse(
          [void Function(PrivacyDeletionResponseBuilder)? updates]) =>
      (PrivacyDeletionResponseBuilder()..update(updates))._build();

  _$PrivacyDeletionResponse._(
      {required this.completedAt,
      required this.failureCode,
      required this.id,
      required this.proofs,
      required this.requestType,
      required this.requestedAt,
      required this.retentionExceptions,
      required this.status})
      : super._();
  @override
  PrivacyDeletionResponse rebuild(
          void Function(PrivacyDeletionResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PrivacyDeletionResponseBuilder toBuilder() =>
      PrivacyDeletionResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PrivacyDeletionResponse &&
        completedAt == other.completedAt &&
        failureCode == other.failureCode &&
        id == other.id &&
        proofs == other.proofs &&
        requestType == other.requestType &&
        requestedAt == other.requestedAt &&
        retentionExceptions == other.retentionExceptions &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, completedAt.hashCode);
    _$hash = $jc(_$hash, failureCode.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, proofs.hashCode);
    _$hash = $jc(_$hash, requestType.hashCode);
    _$hash = $jc(_$hash, requestedAt.hashCode);
    _$hash = $jc(_$hash, retentionExceptions.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PrivacyDeletionResponse')
          ..add('completedAt', completedAt)
          ..add('failureCode', failureCode)
          ..add('id', id)
          ..add('proofs', proofs)
          ..add('requestType', requestType)
          ..add('requestedAt', requestedAt)
          ..add('retentionExceptions', retentionExceptions)
          ..add('status', status))
        .toString();
  }
}

class PrivacyDeletionResponseBuilder
    implements
        Builder<PrivacyDeletionResponse, PrivacyDeletionResponseBuilder> {
  _$PrivacyDeletionResponse? _$v;

  Optional<String?>? _completedAt;
  Optional<String?>? get completedAt => _$this._completedAt;
  set completedAt(Optional<String?>? completedAt) =>
      _$this._completedAt = completedAt;

  Optional<String?>? _failureCode;
  Optional<String?>? get failureCode => _$this._failureCode;
  set failureCode(Optional<String?>? failureCode) =>
      _$this._failureCode = failureCode;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  ListBuilder<DeletionProofSummary>? _proofs;
  ListBuilder<DeletionProofSummary> get proofs =>
      _$this._proofs ??= ListBuilder<DeletionProofSummary>();
  set proofs(ListBuilder<DeletionProofSummary>? proofs) =>
      _$this._proofs = proofs;

  Optional<PrivacyDeletionResponseRequestTypeEnum?>? _requestType;
  Optional<PrivacyDeletionResponseRequestTypeEnum?>? get requestType =>
      _$this._requestType;
  set requestType(
          Optional<PrivacyDeletionResponseRequestTypeEnum?>? requestType) =>
      _$this._requestType = requestType;

  String? _requestedAt;
  String? get requestedAt => _$this._requestedAt;
  set requestedAt(String? requestedAt) => _$this._requestedAt = requestedAt;

  ListBuilder<String>? _retentionExceptions;
  ListBuilder<String> get retentionExceptions =>
      _$this._retentionExceptions ??= ListBuilder<String>();
  set retentionExceptions(ListBuilder<String>? retentionExceptions) =>
      _$this._retentionExceptions = retentionExceptions;

  PrivacyDeletionResponseStatusEnum? _status;
  PrivacyDeletionResponseStatusEnum? get status => _$this._status;
  set status(PrivacyDeletionResponseStatusEnum? status) =>
      _$this._status = status;

  PrivacyDeletionResponseBuilder() {
    PrivacyDeletionResponse._defaults(this);
  }

  PrivacyDeletionResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _completedAt = $v.completedAt;
      _failureCode = $v.failureCode;
      _id = $v.id;
      _proofs = $v.proofs.toBuilder();
      _requestType = $v.requestType;
      _requestedAt = $v.requestedAt;
      _retentionExceptions = $v.retentionExceptions.toBuilder();
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PrivacyDeletionResponse other) {
    _$v = other as _$PrivacyDeletionResponse;
  }

  @override
  void update(void Function(PrivacyDeletionResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PrivacyDeletionResponse build() => _build();

  _$PrivacyDeletionResponse _build() {
    _$PrivacyDeletionResponse _$result;
    try {
      _$result = _$v ??
          _$PrivacyDeletionResponse._(
            completedAt: BuiltValueNullFieldError.checkNotNull(
                completedAt, r'PrivacyDeletionResponse', 'completedAt'),
            failureCode: BuiltValueNullFieldError.checkNotNull(
                failureCode, r'PrivacyDeletionResponse', 'failureCode'),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'PrivacyDeletionResponse', 'id'),
            proofs: proofs.build(),
            requestType: BuiltValueNullFieldError.checkNotNull(
                requestType, r'PrivacyDeletionResponse', 'requestType'),
            requestedAt: BuiltValueNullFieldError.checkNotNull(
                requestedAt, r'PrivacyDeletionResponse', 'requestedAt'),
            retentionExceptions: retentionExceptions.build(),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'PrivacyDeletionResponse', 'status'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'proofs';
        proofs.build();

        _$failedField = 'retentionExceptions';
        retentionExceptions.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PrivacyDeletionResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
