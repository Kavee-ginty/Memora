// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_report_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const QuestionReportResponseEvidenceStateEnum
    _$questionReportResponseEvidenceStateEnum_recorded =
    const QuestionReportResponseEvidenceStateEnum._('recorded');
const QuestionReportResponseEvidenceStateEnum
    _$questionReportResponseEvidenceStateEnum_limitedPendingReview =
    const QuestionReportResponseEvidenceStateEnum._('limitedPendingReview');
const QuestionReportResponseEvidenceStateEnum
    _$questionReportResponseEvidenceStateEnum_unknownDefaultOpenApi =
    const QuestionReportResponseEvidenceStateEnum._('unknownDefaultOpenApi');

QuestionReportResponseEvidenceStateEnum
    _$questionReportResponseEvidenceStateEnumValueOf(String name) {
  switch (name) {
    case 'recorded':
      return _$questionReportResponseEvidenceStateEnum_recorded;
    case 'limitedPendingReview':
      return _$questionReportResponseEvidenceStateEnum_limitedPendingReview;
    case 'unknownDefaultOpenApi':
      return _$questionReportResponseEvidenceStateEnum_unknownDefaultOpenApi;
    default:
      return _$questionReportResponseEvidenceStateEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<QuestionReportResponseEvidenceStateEnum>
    _$questionReportResponseEvidenceStateEnumValues = BuiltSet<
        QuestionReportResponseEvidenceStateEnum>(const <QuestionReportResponseEvidenceStateEnum>[
  _$questionReportResponseEvidenceStateEnum_recorded,
  _$questionReportResponseEvidenceStateEnum_limitedPendingReview,
  _$questionReportResponseEvidenceStateEnum_unknownDefaultOpenApi,
]);

const QuestionReportResponseReportTypeEnum
    _$questionReportResponseReportTypeEnum_questionError =
    const QuestionReportResponseReportTypeEnum._('questionError');
const QuestionReportResponseReportTypeEnum
    _$questionReportResponseReportTypeEnum_answerError =
    const QuestionReportResponseReportTypeEnum._('answerError');
const QuestionReportResponseReportTypeEnum
    _$questionReportResponseReportTypeEnum_explanationError =
    const QuestionReportResponseReportTypeEnum._('explanationError');
const QuestionReportResponseReportTypeEnum
    _$questionReportResponseReportTypeEnum_gradingDispute =
    const QuestionReportResponseReportTypeEnum._('gradingDispute');
const QuestionReportResponseReportTypeEnum
    _$questionReportResponseReportTypeEnum_accessibility =
    const QuestionReportResponseReportTypeEnum._('accessibility');
const QuestionReportResponseReportTypeEnum
    _$questionReportResponseReportTypeEnum_unknownDefaultOpenApi =
    const QuestionReportResponseReportTypeEnum._('unknownDefaultOpenApi');

QuestionReportResponseReportTypeEnum
    _$questionReportResponseReportTypeEnumValueOf(String name) {
  switch (name) {
    case 'questionError':
      return _$questionReportResponseReportTypeEnum_questionError;
    case 'answerError':
      return _$questionReportResponseReportTypeEnum_answerError;
    case 'explanationError':
      return _$questionReportResponseReportTypeEnum_explanationError;
    case 'gradingDispute':
      return _$questionReportResponseReportTypeEnum_gradingDispute;
    case 'accessibility':
      return _$questionReportResponseReportTypeEnum_accessibility;
    case 'unknownDefaultOpenApi':
      return _$questionReportResponseReportTypeEnum_unknownDefaultOpenApi;
    default:
      return _$questionReportResponseReportTypeEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<QuestionReportResponseReportTypeEnum>
    _$questionReportResponseReportTypeEnumValues = BuiltSet<
        QuestionReportResponseReportTypeEnum>(const <QuestionReportResponseReportTypeEnum>[
  _$questionReportResponseReportTypeEnum_questionError,
  _$questionReportResponseReportTypeEnum_answerError,
  _$questionReportResponseReportTypeEnum_explanationError,
  _$questionReportResponseReportTypeEnum_gradingDispute,
  _$questionReportResponseReportTypeEnum_accessibility,
  _$questionReportResponseReportTypeEnum_unknownDefaultOpenApi,
]);

const QuestionReportResponseStatusEnum
    _$questionReportResponseStatusEnum_submitted =
    const QuestionReportResponseStatusEnum._('submitted');
const QuestionReportResponseStatusEnum
    _$questionReportResponseStatusEnum_triaged =
    const QuestionReportResponseStatusEnum._('triaged');
const QuestionReportResponseStatusEnum
    _$questionReportResponseStatusEnum_underReview =
    const QuestionReportResponseStatusEnum._('underReview');
const QuestionReportResponseStatusEnum
    _$questionReportResponseStatusEnum_resolved =
    const QuestionReportResponseStatusEnum._('resolved');
const QuestionReportResponseStatusEnum
    _$questionReportResponseStatusEnum_dismissed =
    const QuestionReportResponseStatusEnum._('dismissed');
const QuestionReportResponseStatusEnum
    _$questionReportResponseStatusEnum_unknownDefaultOpenApi =
    const QuestionReportResponseStatusEnum._('unknownDefaultOpenApi');

QuestionReportResponseStatusEnum _$questionReportResponseStatusEnumValueOf(
    String name) {
  switch (name) {
    case 'submitted':
      return _$questionReportResponseStatusEnum_submitted;
    case 'triaged':
      return _$questionReportResponseStatusEnum_triaged;
    case 'underReview':
      return _$questionReportResponseStatusEnum_underReview;
    case 'resolved':
      return _$questionReportResponseStatusEnum_resolved;
    case 'dismissed':
      return _$questionReportResponseStatusEnum_dismissed;
    case 'unknownDefaultOpenApi':
      return _$questionReportResponseStatusEnum_unknownDefaultOpenApi;
    default:
      return _$questionReportResponseStatusEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<QuestionReportResponseStatusEnum>
    _$questionReportResponseStatusEnumValues = BuiltSet<
        QuestionReportResponseStatusEnum>(const <QuestionReportResponseStatusEnum>[
  _$questionReportResponseStatusEnum_submitted,
  _$questionReportResponseStatusEnum_triaged,
  _$questionReportResponseStatusEnum_underReview,
  _$questionReportResponseStatusEnum_resolved,
  _$questionReportResponseStatusEnum_dismissed,
  _$questionReportResponseStatusEnum_unknownDefaultOpenApi,
]);

Serializer<QuestionReportResponseEvidenceStateEnum>
    _$questionReportResponseEvidenceStateEnumSerializer =
    _$QuestionReportResponseEvidenceStateEnumSerializer();
Serializer<QuestionReportResponseReportTypeEnum>
    _$questionReportResponseReportTypeEnumSerializer =
    _$QuestionReportResponseReportTypeEnumSerializer();
Serializer<QuestionReportResponseStatusEnum>
    _$questionReportResponseStatusEnumSerializer =
    _$QuestionReportResponseStatusEnumSerializer();

class _$QuestionReportResponseEvidenceStateEnumSerializer
    implements PrimitiveSerializer<QuestionReportResponseEvidenceStateEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'recorded': 'recorded',
    'limitedPendingReview': 'limited_pending_review',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'recorded': 'recorded',
    'limited_pending_review': 'limitedPendingReview',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    QuestionReportResponseEvidenceStateEnum
  ];
  @override
  final String wireName = 'QuestionReportResponseEvidenceStateEnum';

  @override
  Object serialize(Serializers serializers,
          QuestionReportResponseEvidenceStateEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  QuestionReportResponseEvidenceStateEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      QuestionReportResponseEvidenceStateEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$QuestionReportResponseReportTypeEnumSerializer
    implements PrimitiveSerializer<QuestionReportResponseReportTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'questionError': 'question_error',
    'answerError': 'answer_error',
    'explanationError': 'explanation_error',
    'gradingDispute': 'grading_dispute',
    'accessibility': 'accessibility',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'question_error': 'questionError',
    'answer_error': 'answerError',
    'explanation_error': 'explanationError',
    'grading_dispute': 'gradingDispute',
    'accessibility': 'accessibility',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    QuestionReportResponseReportTypeEnum
  ];
  @override
  final String wireName = 'QuestionReportResponseReportTypeEnum';

  @override
  Object serialize(
          Serializers serializers, QuestionReportResponseReportTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  QuestionReportResponseReportTypeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      QuestionReportResponseReportTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$QuestionReportResponseStatusEnumSerializer
    implements PrimitiveSerializer<QuestionReportResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'submitted': 'submitted',
    'triaged': 'triaged',
    'underReview': 'under_review',
    'resolved': 'resolved',
    'dismissed': 'dismissed',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'submitted': 'submitted',
    'triaged': 'triaged',
    'under_review': 'underReview',
    'resolved': 'resolved',
    'dismissed': 'dismissed',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[QuestionReportResponseStatusEnum];
  @override
  final String wireName = 'QuestionReportResponseStatusEnum';

  @override
  Object serialize(
          Serializers serializers, QuestionReportResponseStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  QuestionReportResponseStatusEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      QuestionReportResponseStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$QuestionReportResponse extends QuestionReportResponse {
  @override
  final String? attemptId;
  @override
  final bool descriptionPresent;
  @override
  final QuestionReportResponseEvidenceStateEnum evidenceState;
  @override
  final String id;
  @override
  final String questionVersionId;
  @override
  final QuestionReportResponseReportTypeEnum reportType;
  @override
  final String? resolutionCode;
  @override
  final String? resolvedAt;
  @override
  final bool reviewRequired;
  @override
  final QuestionReportResponseStatusEnum status;
  @override
  final String submittedAt;

  factory _$QuestionReportResponse(
          [void Function(QuestionReportResponseBuilder)? updates]) =>
      (QuestionReportResponseBuilder()..update(updates))._build();

  _$QuestionReportResponse._(
      {this.attemptId,
      required this.descriptionPresent,
      required this.evidenceState,
      required this.id,
      required this.questionVersionId,
      required this.reportType,
      this.resolutionCode,
      this.resolvedAt,
      required this.reviewRequired,
      required this.status,
      required this.submittedAt})
      : super._();
  @override
  QuestionReportResponse rebuild(
          void Function(QuestionReportResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  QuestionReportResponseBuilder toBuilder() =>
      QuestionReportResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is QuestionReportResponse &&
        attemptId == other.attemptId &&
        descriptionPresent == other.descriptionPresent &&
        evidenceState == other.evidenceState &&
        id == other.id &&
        questionVersionId == other.questionVersionId &&
        reportType == other.reportType &&
        resolutionCode == other.resolutionCode &&
        resolvedAt == other.resolvedAt &&
        reviewRequired == other.reviewRequired &&
        status == other.status &&
        submittedAt == other.submittedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, attemptId.hashCode);
    _$hash = $jc(_$hash, descriptionPresent.hashCode);
    _$hash = $jc(_$hash, evidenceState.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, questionVersionId.hashCode);
    _$hash = $jc(_$hash, reportType.hashCode);
    _$hash = $jc(_$hash, resolutionCode.hashCode);
    _$hash = $jc(_$hash, resolvedAt.hashCode);
    _$hash = $jc(_$hash, reviewRequired.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, submittedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'QuestionReportResponse')
          ..add('attemptId', attemptId)
          ..add('descriptionPresent', descriptionPresent)
          ..add('evidenceState', evidenceState)
          ..add('id', id)
          ..add('questionVersionId', questionVersionId)
          ..add('reportType', reportType)
          ..add('resolutionCode', resolutionCode)
          ..add('resolvedAt', resolvedAt)
          ..add('reviewRequired', reviewRequired)
          ..add('status', status)
          ..add('submittedAt', submittedAt))
        .toString();
  }
}

class QuestionReportResponseBuilder
    implements Builder<QuestionReportResponse, QuestionReportResponseBuilder> {
  _$QuestionReportResponse? _$v;

  String? _attemptId;
  String? get attemptId => _$this._attemptId;
  set attemptId(String? attemptId) => _$this._attemptId = attemptId;

  bool? _descriptionPresent;
  bool? get descriptionPresent => _$this._descriptionPresent;
  set descriptionPresent(bool? descriptionPresent) =>
      _$this._descriptionPresent = descriptionPresent;

  QuestionReportResponseEvidenceStateEnum? _evidenceState;
  QuestionReportResponseEvidenceStateEnum? get evidenceState =>
      _$this._evidenceState;
  set evidenceState(QuestionReportResponseEvidenceStateEnum? evidenceState) =>
      _$this._evidenceState = evidenceState;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _questionVersionId;
  String? get questionVersionId => _$this._questionVersionId;
  set questionVersionId(String? questionVersionId) =>
      _$this._questionVersionId = questionVersionId;

  QuestionReportResponseReportTypeEnum? _reportType;
  QuestionReportResponseReportTypeEnum? get reportType => _$this._reportType;
  set reportType(QuestionReportResponseReportTypeEnum? reportType) =>
      _$this._reportType = reportType;

  String? _resolutionCode;
  String? get resolutionCode => _$this._resolutionCode;
  set resolutionCode(String? resolutionCode) =>
      _$this._resolutionCode = resolutionCode;

  String? _resolvedAt;
  String? get resolvedAt => _$this._resolvedAt;
  set resolvedAt(String? resolvedAt) => _$this._resolvedAt = resolvedAt;

  bool? _reviewRequired;
  bool? get reviewRequired => _$this._reviewRequired;
  set reviewRequired(bool? reviewRequired) =>
      _$this._reviewRequired = reviewRequired;

  QuestionReportResponseStatusEnum? _status;
  QuestionReportResponseStatusEnum? get status => _$this._status;
  set status(QuestionReportResponseStatusEnum? status) =>
      _$this._status = status;

  String? _submittedAt;
  String? get submittedAt => _$this._submittedAt;
  set submittedAt(String? submittedAt) => _$this._submittedAt = submittedAt;

  QuestionReportResponseBuilder() {
    QuestionReportResponse._defaults(this);
  }

  QuestionReportResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _attemptId = $v.attemptId;
      _descriptionPresent = $v.descriptionPresent;
      _evidenceState = $v.evidenceState;
      _id = $v.id;
      _questionVersionId = $v.questionVersionId;
      _reportType = $v.reportType;
      _resolutionCode = $v.resolutionCode;
      _resolvedAt = $v.resolvedAt;
      _reviewRequired = $v.reviewRequired;
      _status = $v.status;
      _submittedAt = $v.submittedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(QuestionReportResponse other) {
    _$v = other as _$QuestionReportResponse;
  }

  @override
  void update(void Function(QuestionReportResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  QuestionReportResponse build() => _build();

  _$QuestionReportResponse _build() {
    final _$result = _$v ??
        _$QuestionReportResponse._(
          attemptId: attemptId,
          descriptionPresent: BuiltValueNullFieldError.checkNotNull(
              descriptionPresent,
              r'QuestionReportResponse',
              'descriptionPresent'),
          evidenceState: BuiltValueNullFieldError.checkNotNull(
              evidenceState, r'QuestionReportResponse', 'evidenceState'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'QuestionReportResponse', 'id'),
          questionVersionId: BuiltValueNullFieldError.checkNotNull(
              questionVersionId,
              r'QuestionReportResponse',
              'questionVersionId'),
          reportType: BuiltValueNullFieldError.checkNotNull(
              reportType, r'QuestionReportResponse', 'reportType'),
          resolutionCode: resolutionCode,
          resolvedAt: resolvedAt,
          reviewRequired: BuiltValueNullFieldError.checkNotNull(
              reviewRequired, r'QuestionReportResponse', 'reviewRequired'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'QuestionReportResponse', 'status'),
          submittedAt: BuiltValueNullFieldError.checkNotNull(
              submittedAt, r'QuestionReportResponse', 'submittedAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
