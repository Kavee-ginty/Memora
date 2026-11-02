// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submit_attempt_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SubmitAttemptRequest extends SubmitAttemptRequest {
  @override
  final DateTime answeredAt;
  @override
  final String clientOperationId;
  @override
  final Optional<int?> elapsedMs;
  @override
  final Optional<bool?> offlineSubmission;
  @override
  final String questionVersionId;
  @override
  final AnswerPayload response;

  factory _$SubmitAttemptRequest(
          [void Function(SubmitAttemptRequestBuilder)? updates]) =>
      (SubmitAttemptRequestBuilder()..update(updates))._build();

  _$SubmitAttemptRequest._(
      {required this.answeredAt,
      required this.clientOperationId,
      required this.elapsedMs,
      required this.offlineSubmission,
      required this.questionVersionId,
      required this.response})
      : super._();
  @override
  SubmitAttemptRequest rebuild(
          void Function(SubmitAttemptRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SubmitAttemptRequestBuilder toBuilder() =>
      SubmitAttemptRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SubmitAttemptRequest &&
        answeredAt == other.answeredAt &&
        clientOperationId == other.clientOperationId &&
        elapsedMs == other.elapsedMs &&
        offlineSubmission == other.offlineSubmission &&
        questionVersionId == other.questionVersionId &&
        response == other.response;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, answeredAt.hashCode);
    _$hash = $jc(_$hash, clientOperationId.hashCode);
    _$hash = $jc(_$hash, elapsedMs.hashCode);
    _$hash = $jc(_$hash, offlineSubmission.hashCode);
    _$hash = $jc(_$hash, questionVersionId.hashCode);
    _$hash = $jc(_$hash, response.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SubmitAttemptRequest')
          ..add('answeredAt', answeredAt)
          ..add('clientOperationId', clientOperationId)
          ..add('elapsedMs', elapsedMs)
          ..add('offlineSubmission', offlineSubmission)
          ..add('questionVersionId', questionVersionId)
          ..add('response', response))
        .toString();
  }
}

class SubmitAttemptRequestBuilder
    implements Builder<SubmitAttemptRequest, SubmitAttemptRequestBuilder> {
  _$SubmitAttemptRequest? _$v;

  DateTime? _answeredAt;
  DateTime? get answeredAt => _$this._answeredAt;
  set answeredAt(DateTime? answeredAt) => _$this._answeredAt = answeredAt;

  String? _clientOperationId;
  String? get clientOperationId => _$this._clientOperationId;
  set clientOperationId(String? clientOperationId) =>
      _$this._clientOperationId = clientOperationId;

  Optional<int?>? _elapsedMs;
  Optional<int?>? get elapsedMs => _$this._elapsedMs;
  set elapsedMs(Optional<int?>? elapsedMs) => _$this._elapsedMs = elapsedMs;

  Optional<bool?>? _offlineSubmission;
  Optional<bool?>? get offlineSubmission => _$this._offlineSubmission;
  set offlineSubmission(Optional<bool?>? offlineSubmission) =>
      _$this._offlineSubmission = offlineSubmission;

  String? _questionVersionId;
  String? get questionVersionId => _$this._questionVersionId;
  set questionVersionId(String? questionVersionId) =>
      _$this._questionVersionId = questionVersionId;

  AnswerPayloadBuilder? _response;
  AnswerPayloadBuilder get response =>
      _$this._response ??= AnswerPayloadBuilder();
  set response(AnswerPayloadBuilder? response) => _$this._response = response;

  SubmitAttemptRequestBuilder() {
    SubmitAttemptRequest._defaults(this);
  }

  SubmitAttemptRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _answeredAt = $v.answeredAt;
      _clientOperationId = $v.clientOperationId;
      _elapsedMs = $v.elapsedMs;
      _offlineSubmission = $v.offlineSubmission;
      _questionVersionId = $v.questionVersionId;
      _response = $v.response.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SubmitAttemptRequest other) {
    _$v = other as _$SubmitAttemptRequest;
  }

  @override
  void update(void Function(SubmitAttemptRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SubmitAttemptRequest build() => _build();

  _$SubmitAttemptRequest _build() {
    _$SubmitAttemptRequest _$result;
    try {
      _$result = _$v ??
          _$SubmitAttemptRequest._(
            answeredAt: BuiltValueNullFieldError.checkNotNull(
                answeredAt, r'SubmitAttemptRequest', 'answeredAt'),
            clientOperationId: BuiltValueNullFieldError.checkNotNull(
                clientOperationId,
                r'SubmitAttemptRequest',
                'clientOperationId'),
            elapsedMs: BuiltValueNullFieldError.checkNotNull(
                elapsedMs, r'SubmitAttemptRequest', 'elapsedMs'),
            offlineSubmission: BuiltValueNullFieldError.checkNotNull(
                offlineSubmission,
                r'SubmitAttemptRequest',
                'offlineSubmission'),
            questionVersionId: BuiltValueNullFieldError.checkNotNull(
                questionVersionId,
                r'SubmitAttemptRequest',
                'questionVersionId'),
            response: response.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'response';
        response.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'SubmitAttemptRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
