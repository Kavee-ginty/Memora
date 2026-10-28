// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retry_learning_update_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RetryLearningUpdateRequestStageEnum
    _$retryLearningUpdateRequestStageEnum_extraction =
    const RetryLearningUpdateRequestStageEnum._('extraction');
const RetryLearningUpdateRequestStageEnum
    _$retryLearningUpdateRequestStageEnum_deletion =
    const RetryLearningUpdateRequestStageEnum._('deletion');
const RetryLearningUpdateRequestStageEnum
    _$retryLearningUpdateRequestStageEnum_unknownDefaultOpenApi =
    const RetryLearningUpdateRequestStageEnum._('unknownDefaultOpenApi');

RetryLearningUpdateRequestStageEnum
    _$retryLearningUpdateRequestStageEnumValueOf(String name) {
  switch (name) {
    case 'extraction':
      return _$retryLearningUpdateRequestStageEnum_extraction;
    case 'deletion':
      return _$retryLearningUpdateRequestStageEnum_deletion;
    case 'unknownDefaultOpenApi':
      return _$retryLearningUpdateRequestStageEnum_unknownDefaultOpenApi;
    default:
      return _$retryLearningUpdateRequestStageEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<RetryLearningUpdateRequestStageEnum>
    _$retryLearningUpdateRequestStageEnumValues = BuiltSet<
        RetryLearningUpdateRequestStageEnum>(const <RetryLearningUpdateRequestStageEnum>[
  _$retryLearningUpdateRequestStageEnum_extraction,
  _$retryLearningUpdateRequestStageEnum_deletion,
  _$retryLearningUpdateRequestStageEnum_unknownDefaultOpenApi,
]);

Serializer<RetryLearningUpdateRequestStageEnum>
    _$retryLearningUpdateRequestStageEnumSerializer =
    _$RetryLearningUpdateRequestStageEnumSerializer();

class _$RetryLearningUpdateRequestStageEnumSerializer
    implements PrimitiveSerializer<RetryLearningUpdateRequestStageEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'extraction': 'extraction',
    'deletion': 'deletion',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'extraction': 'extraction',
    'deletion': 'deletion',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    RetryLearningUpdateRequestStageEnum
  ];
  @override
  final String wireName = 'RetryLearningUpdateRequestStageEnum';

  @override
  Object serialize(
          Serializers serializers, RetryLearningUpdateRequestStageEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  RetryLearningUpdateRequestStageEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      RetryLearningUpdateRequestStageEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$RetryLearningUpdateRequest extends RetryLearningUpdateRequest {
  @override
  final RetryLearningUpdateRequestStageEnum stage;

  factory _$RetryLearningUpdateRequest(
          [void Function(RetryLearningUpdateRequestBuilder)? updates]) =>
      (RetryLearningUpdateRequestBuilder()..update(updates))._build();

  _$RetryLearningUpdateRequest._({required this.stage}) : super._();
  @override
  RetryLearningUpdateRequest rebuild(
          void Function(RetryLearningUpdateRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RetryLearningUpdateRequestBuilder toBuilder() =>
      RetryLearningUpdateRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RetryLearningUpdateRequest && stage == other.stage;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, stage.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RetryLearningUpdateRequest')
          ..add('stage', stage))
        .toString();
  }
}

class RetryLearningUpdateRequestBuilder
    implements
        Builder<RetryLearningUpdateRequest, RetryLearningUpdateRequestBuilder> {
  _$RetryLearningUpdateRequest? _$v;

  RetryLearningUpdateRequestStageEnum? _stage;
  RetryLearningUpdateRequestStageEnum? get stage => _$this._stage;
  set stage(RetryLearningUpdateRequestStageEnum? stage) =>
      _$this._stage = stage;

  RetryLearningUpdateRequestBuilder() {
    RetryLearningUpdateRequest._defaults(this);
  }

  RetryLearningUpdateRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _stage = $v.stage;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RetryLearningUpdateRequest other) {
    _$v = other as _$RetryLearningUpdateRequest;
  }

  @override
  void update(void Function(RetryLearningUpdateRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RetryLearningUpdateRequest build() => _build();

  _$RetryLearningUpdateRequest _build() {
    final _$result = _$v ??
        _$RetryLearningUpdateRequest._(
          stage: BuiltValueNullFieldError.checkNotNull(
              stage, r'RetryLearningUpdateRequest', 'stage'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
