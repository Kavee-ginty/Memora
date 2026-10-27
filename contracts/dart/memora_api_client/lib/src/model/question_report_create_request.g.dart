// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_report_create_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const QuestionReportCreateRequestReportTypeEnum
    _$questionReportCreateRequestReportTypeEnum_questionError =
    const QuestionReportCreateRequestReportTypeEnum._('questionError');
const QuestionReportCreateRequestReportTypeEnum
    _$questionReportCreateRequestReportTypeEnum_answerError =
    const QuestionReportCreateRequestReportTypeEnum._('answerError');
const QuestionReportCreateRequestReportTypeEnum
    _$questionReportCreateRequestReportTypeEnum_explanationError =
    const QuestionReportCreateRequestReportTypeEnum._('explanationError');
const QuestionReportCreateRequestReportTypeEnum
    _$questionReportCreateRequestReportTypeEnum_gradingDispute =
    const QuestionReportCreateRequestReportTypeEnum._('gradingDispute');
const QuestionReportCreateRequestReportTypeEnum
    _$questionReportCreateRequestReportTypeEnum_accessibility =
    const QuestionReportCreateRequestReportTypeEnum._('accessibility');
const QuestionReportCreateRequestReportTypeEnum
    _$questionReportCreateRequestReportTypeEnum_unknownDefaultOpenApi =
    const QuestionReportCreateRequestReportTypeEnum._('unknownDefaultOpenApi');

QuestionReportCreateRequestReportTypeEnum
    _$questionReportCreateRequestReportTypeEnumValueOf(String name) {
  switch (name) {
    case 'questionError':
      return _$questionReportCreateRequestReportTypeEnum_questionError;
    case 'answerError':
      return _$questionReportCreateRequestReportTypeEnum_answerError;
    case 'explanationError':
      return _$questionReportCreateRequestReportTypeEnum_explanationError;
    case 'gradingDispute':
      return _$questionReportCreateRequestReportTypeEnum_gradingDispute;
    case 'accessibility':
      return _$questionReportCreateRequestReportTypeEnum_accessibility;
    case 'unknownDefaultOpenApi':
      return _$questionReportCreateRequestReportTypeEnum_unknownDefaultOpenApi;
    default:
      return _$questionReportCreateRequestReportTypeEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<QuestionReportCreateRequestReportTypeEnum>
    _$questionReportCreateRequestReportTypeEnumValues = BuiltSet<
        QuestionReportCreateRequestReportTypeEnum>(const <QuestionReportCreateRequestReportTypeEnum>[
  _$questionReportCreateRequestReportTypeEnum_questionError,
  _$questionReportCreateRequestReportTypeEnum_answerError,
  _$questionReportCreateRequestReportTypeEnum_explanationError,
  _$questionReportCreateRequestReportTypeEnum_gradingDispute,
  _$questionReportCreateRequestReportTypeEnum_accessibility,
  _$questionReportCreateRequestReportTypeEnum_unknownDefaultOpenApi,
]);

Serializer<QuestionReportCreateRequestReportTypeEnum>
    _$questionReportCreateRequestReportTypeEnumSerializer =
    _$QuestionReportCreateRequestReportTypeEnumSerializer();

class _$QuestionReportCreateRequestReportTypeEnumSerializer
    implements PrimitiveSerializer<QuestionReportCreateRequestReportTypeEnum> {
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
    QuestionReportCreateRequestReportTypeEnum
  ];
  @override
  final String wireName = 'QuestionReportCreateRequestReportTypeEnum';

  @override
  Object serialize(Serializers serializers,
          QuestionReportCreateRequestReportTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  QuestionReportCreateRequestReportTypeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      QuestionReportCreateRequestReportTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$QuestionReportCreateRequest extends QuestionReportCreateRequest {
  @override
  final Optional<String?> attemptId;
  @override
  final Optional<String?> description;
  @override
  final QuestionReportCreateRequestReportTypeEnum reportType;

  factory _$QuestionReportCreateRequest(
          [void Function(QuestionReportCreateRequestBuilder)? updates]) =>
      (QuestionReportCreateRequestBuilder()..update(updates))._build();

  _$QuestionReportCreateRequest._(
      {required this.attemptId,
      required this.description,
      required this.reportType})
      : super._();
  @override
  QuestionReportCreateRequest rebuild(
          void Function(QuestionReportCreateRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  QuestionReportCreateRequestBuilder toBuilder() =>
      QuestionReportCreateRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is QuestionReportCreateRequest &&
        attemptId == other.attemptId &&
        description == other.description &&
        reportType == other.reportType;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, attemptId.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, reportType.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'QuestionReportCreateRequest')
          ..add('attemptId', attemptId)
          ..add('description', description)
          ..add('reportType', reportType))
        .toString();
  }
}

class QuestionReportCreateRequestBuilder
    implements
        Builder<QuestionReportCreateRequest,
            QuestionReportCreateRequestBuilder> {
  _$QuestionReportCreateRequest? _$v;

  Optional<String?>? _attemptId;
  Optional<String?>? get attemptId => _$this._attemptId;
  set attemptId(Optional<String?>? attemptId) => _$this._attemptId = attemptId;

  Optional<String?>? _description;
  Optional<String?>? get description => _$this._description;
  set description(Optional<String?>? description) =>
      _$this._description = description;

  QuestionReportCreateRequestReportTypeEnum? _reportType;
  QuestionReportCreateRequestReportTypeEnum? get reportType =>
      _$this._reportType;
  set reportType(QuestionReportCreateRequestReportTypeEnum? reportType) =>
      _$this._reportType = reportType;

  QuestionReportCreateRequestBuilder() {
    QuestionReportCreateRequest._defaults(this);
  }

  QuestionReportCreateRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _attemptId = $v.attemptId;
      _description = $v.description;
      _reportType = $v.reportType;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(QuestionReportCreateRequest other) {
    _$v = other as _$QuestionReportCreateRequest;
  }

  @override
  void update(void Function(QuestionReportCreateRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  QuestionReportCreateRequest build() => _build();

  _$QuestionReportCreateRequest _build() {
    final _$result = _$v ??
        _$QuestionReportCreateRequest._(
          attemptId: BuiltValueNullFieldError.checkNotNull(
              attemptId, r'QuestionReportCreateRequest', 'attemptId'),
          description: BuiltValueNullFieldError.checkNotNull(
              description, r'QuestionReportCreateRequest', 'description'),
          reportType: BuiltValueNullFieldError.checkNotNull(
              reportType, r'QuestionReportCreateRequest', 'reportType'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
