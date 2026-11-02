// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attempt_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AttemptResultGradingStatusEnum _$attemptResultGradingStatusEnum_graded =
    const AttemptResultGradingStatusEnum._('graded');
const AttemptResultGradingStatusEnum _$attemptResultGradingStatusEnum_skipped =
    const AttemptResultGradingStatusEnum._('skipped');
const AttemptResultGradingStatusEnum
    _$attemptResultGradingStatusEnum_unknownDefaultOpenApi =
    const AttemptResultGradingStatusEnum._('unknownDefaultOpenApi');

AttemptResultGradingStatusEnum _$attemptResultGradingStatusEnumValueOf(
    String name) {
  switch (name) {
    case 'graded':
      return _$attemptResultGradingStatusEnum_graded;
    case 'skipped':
      return _$attemptResultGradingStatusEnum_skipped;
    case 'unknownDefaultOpenApi':
      return _$attemptResultGradingStatusEnum_unknownDefaultOpenApi;
    default:
      return _$attemptResultGradingStatusEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<AttemptResultGradingStatusEnum>
    _$attemptResultGradingStatusEnumValues = BuiltSet<
        AttemptResultGradingStatusEnum>(const <AttemptResultGradingStatusEnum>[
  _$attemptResultGradingStatusEnum_graded,
  _$attemptResultGradingStatusEnum_skipped,
  _$attemptResultGradingStatusEnum_unknownDefaultOpenApi,
]);

const AttemptResultOutcomeEnum _$attemptResultOutcomeEnum_recalled =
    const AttemptResultOutcomeEnum._('recalled');
const AttemptResultOutcomeEnum _$attemptResultOutcomeEnum_partial =
    const AttemptResultOutcomeEnum._('partial');
const AttemptResultOutcomeEnum _$attemptResultOutcomeEnum_uncertain =
    const AttemptResultOutcomeEnum._('uncertain');
const AttemptResultOutcomeEnum _$attemptResultOutcomeEnum_weak =
    const AttemptResultOutcomeEnum._('weak');
const AttemptResultOutcomeEnum _$attemptResultOutcomeEnum_skipped =
    const AttemptResultOutcomeEnum._('skipped');
const AttemptResultOutcomeEnum
    _$attemptResultOutcomeEnum_unknownDefaultOpenApi =
    const AttemptResultOutcomeEnum._('unknownDefaultOpenApi');

AttemptResultOutcomeEnum _$attemptResultOutcomeEnumValueOf(String name) {
  switch (name) {
    case 'recalled':
      return _$attemptResultOutcomeEnum_recalled;
    case 'partial':
      return _$attemptResultOutcomeEnum_partial;
    case 'uncertain':
      return _$attemptResultOutcomeEnum_uncertain;
    case 'weak':
      return _$attemptResultOutcomeEnum_weak;
    case 'skipped':
      return _$attemptResultOutcomeEnum_skipped;
    case 'unknownDefaultOpenApi':
      return _$attemptResultOutcomeEnum_unknownDefaultOpenApi;
    default:
      return _$attemptResultOutcomeEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<AttemptResultOutcomeEnum> _$attemptResultOutcomeEnumValues =
    BuiltSet<AttemptResultOutcomeEnum>(const <AttemptResultOutcomeEnum>[
  _$attemptResultOutcomeEnum_recalled,
  _$attemptResultOutcomeEnum_partial,
  _$attemptResultOutcomeEnum_uncertain,
  _$attemptResultOutcomeEnum_weak,
  _$attemptResultOutcomeEnum_skipped,
  _$attemptResultOutcomeEnum_unknownDefaultOpenApi,
]);

const AttemptResultRepairActionEnum _$attemptResultRepairActionEnum_none =
    const AttemptResultRepairActionEnum._('none');
const AttemptResultRepairActionEnum
    _$attemptResultRepairActionEnum_repairInserted =
    const AttemptResultRepairActionEnum._('repairInserted');
const AttemptResultRepairActionEnum
    _$attemptResultRepairActionEnum_reviewConcept =
    const AttemptResultRepairActionEnum._('reviewConcept');
const AttemptResultRepairActionEnum
    _$attemptResultRepairActionEnum_confirmOrAppeal =
    const AttemptResultRepairActionEnum._('confirmOrAppeal');
const AttemptResultRepairActionEnum
    _$attemptResultRepairActionEnum_unknownDefaultOpenApi =
    const AttemptResultRepairActionEnum._('unknownDefaultOpenApi');

AttemptResultRepairActionEnum _$attemptResultRepairActionEnumValueOf(
    String name) {
  switch (name) {
    case 'none':
      return _$attemptResultRepairActionEnum_none;
    case 'repairInserted':
      return _$attemptResultRepairActionEnum_repairInserted;
    case 'reviewConcept':
      return _$attemptResultRepairActionEnum_reviewConcept;
    case 'confirmOrAppeal':
      return _$attemptResultRepairActionEnum_confirmOrAppeal;
    case 'unknownDefaultOpenApi':
      return _$attemptResultRepairActionEnum_unknownDefaultOpenApi;
    default:
      return _$attemptResultRepairActionEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<AttemptResultRepairActionEnum>
    _$attemptResultRepairActionEnumValues = BuiltSet<
        AttemptResultRepairActionEnum>(const <AttemptResultRepairActionEnum>[
  _$attemptResultRepairActionEnum_none,
  _$attemptResultRepairActionEnum_repairInserted,
  _$attemptResultRepairActionEnum_reviewConcept,
  _$attemptResultRepairActionEnum_confirmOrAppeal,
  _$attemptResultRepairActionEnum_unknownDefaultOpenApi,
]);

Serializer<AttemptResultGradingStatusEnum>
    _$attemptResultGradingStatusEnumSerializer =
    _$AttemptResultGradingStatusEnumSerializer();
Serializer<AttemptResultOutcomeEnum> _$attemptResultOutcomeEnumSerializer =
    _$AttemptResultOutcomeEnumSerializer();
Serializer<AttemptResultRepairActionEnum>
    _$attemptResultRepairActionEnumSerializer =
    _$AttemptResultRepairActionEnumSerializer();

class _$AttemptResultGradingStatusEnumSerializer
    implements PrimitiveSerializer<AttemptResultGradingStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'graded': 'graded',
    'skipped': 'skipped',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'graded': 'graded',
    'skipped': 'skipped',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[AttemptResultGradingStatusEnum];
  @override
  final String wireName = 'AttemptResultGradingStatusEnum';

  @override
  Object serialize(
          Serializers serializers, AttemptResultGradingStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AttemptResultGradingStatusEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AttemptResultGradingStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$AttemptResultOutcomeEnumSerializer
    implements PrimitiveSerializer<AttemptResultOutcomeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'recalled': 'recalled',
    'partial': 'partial',
    'uncertain': 'uncertain',
    'weak': 'weak',
    'skipped': 'skipped',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'recalled': 'recalled',
    'partial': 'partial',
    'uncertain': 'uncertain',
    'weak': 'weak',
    'skipped': 'skipped',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[AttemptResultOutcomeEnum];
  @override
  final String wireName = 'AttemptResultOutcomeEnum';

  @override
  Object serialize(Serializers serializers, AttemptResultOutcomeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AttemptResultOutcomeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AttemptResultOutcomeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$AttemptResultRepairActionEnumSerializer
    implements PrimitiveSerializer<AttemptResultRepairActionEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'none': 'none',
    'repairInserted': 'repair_inserted',
    'reviewConcept': 'review_concept',
    'confirmOrAppeal': 'confirm_or_appeal',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'none': 'none',
    'repair_inserted': 'repairInserted',
    'review_concept': 'reviewConcept',
    'confirm_or_appeal': 'confirmOrAppeal',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[AttemptResultRepairActionEnum];
  @override
  final String wireName = 'AttemptResultRepairActionEnum';

  @override
  Object serialize(
          Serializers serializers, AttemptResultRepairActionEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AttemptResultRepairActionEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AttemptResultRepairActionEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$AttemptResult extends AttemptResult {
  @override
  final String? attemptId;
  @override
  final bool canComplete;
  @override
  final String? explanation;
  @override
  final bool explanationAvailable;
  @override
  final String feedback;
  @override
  final AttemptResultGradingStatusEnum gradingStatus;
  @override
  final bool influenceLimited;
  @override
  final String? nextItemId;
  @override
  final AttemptResultOutcomeEnum outcome;
  @override
  final AttemptResultRepairActionEnum repairAction;

  factory _$AttemptResult([void Function(AttemptResultBuilder)? updates]) =>
      (AttemptResultBuilder()..update(updates))._build();

  _$AttemptResult._(
      {this.attemptId,
      required this.canComplete,
      this.explanation,
      required this.explanationAvailable,
      required this.feedback,
      required this.gradingStatus,
      required this.influenceLimited,
      this.nextItemId,
      required this.outcome,
      required this.repairAction})
      : super._();
  @override
  AttemptResult rebuild(void Function(AttemptResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AttemptResultBuilder toBuilder() => AttemptResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AttemptResult &&
        attemptId == other.attemptId &&
        canComplete == other.canComplete &&
        explanation == other.explanation &&
        explanationAvailable == other.explanationAvailable &&
        feedback == other.feedback &&
        gradingStatus == other.gradingStatus &&
        influenceLimited == other.influenceLimited &&
        nextItemId == other.nextItemId &&
        outcome == other.outcome &&
        repairAction == other.repairAction;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, attemptId.hashCode);
    _$hash = $jc(_$hash, canComplete.hashCode);
    _$hash = $jc(_$hash, explanation.hashCode);
    _$hash = $jc(_$hash, explanationAvailable.hashCode);
    _$hash = $jc(_$hash, feedback.hashCode);
    _$hash = $jc(_$hash, gradingStatus.hashCode);
    _$hash = $jc(_$hash, influenceLimited.hashCode);
    _$hash = $jc(_$hash, nextItemId.hashCode);
    _$hash = $jc(_$hash, outcome.hashCode);
    _$hash = $jc(_$hash, repairAction.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AttemptResult')
          ..add('attemptId', attemptId)
          ..add('canComplete', canComplete)
          ..add('explanation', explanation)
          ..add('explanationAvailable', explanationAvailable)
          ..add('feedback', feedback)
          ..add('gradingStatus', gradingStatus)
          ..add('influenceLimited', influenceLimited)
          ..add('nextItemId', nextItemId)
          ..add('outcome', outcome)
          ..add('repairAction', repairAction))
        .toString();
  }
}

class AttemptResultBuilder
    implements Builder<AttemptResult, AttemptResultBuilder> {
  _$AttemptResult? _$v;

  String? _attemptId;
  String? get attemptId => _$this._attemptId;
  set attemptId(String? attemptId) => _$this._attemptId = attemptId;

  bool? _canComplete;
  bool? get canComplete => _$this._canComplete;
  set canComplete(bool? canComplete) => _$this._canComplete = canComplete;

  String? _explanation;
  String? get explanation => _$this._explanation;
  set explanation(String? explanation) => _$this._explanation = explanation;

  bool? _explanationAvailable;
  bool? get explanationAvailable => _$this._explanationAvailable;
  set explanationAvailable(bool? explanationAvailable) =>
      _$this._explanationAvailable = explanationAvailable;

  String? _feedback;
  String? get feedback => _$this._feedback;
  set feedback(String? feedback) => _$this._feedback = feedback;

  AttemptResultGradingStatusEnum? _gradingStatus;
  AttemptResultGradingStatusEnum? get gradingStatus => _$this._gradingStatus;
  set gradingStatus(AttemptResultGradingStatusEnum? gradingStatus) =>
      _$this._gradingStatus = gradingStatus;

  bool? _influenceLimited;
  bool? get influenceLimited => _$this._influenceLimited;
  set influenceLimited(bool? influenceLimited) =>
      _$this._influenceLimited = influenceLimited;

  String? _nextItemId;
  String? get nextItemId => _$this._nextItemId;
  set nextItemId(String? nextItemId) => _$this._nextItemId = nextItemId;

  AttemptResultOutcomeEnum? _outcome;
  AttemptResultOutcomeEnum? get outcome => _$this._outcome;
  set outcome(AttemptResultOutcomeEnum? outcome) => _$this._outcome = outcome;

  AttemptResultRepairActionEnum? _repairAction;
  AttemptResultRepairActionEnum? get repairAction => _$this._repairAction;
  set repairAction(AttemptResultRepairActionEnum? repairAction) =>
      _$this._repairAction = repairAction;

  AttemptResultBuilder() {
    AttemptResult._defaults(this);
  }

  AttemptResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _attemptId = $v.attemptId;
      _canComplete = $v.canComplete;
      _explanation = $v.explanation;
      _explanationAvailable = $v.explanationAvailable;
      _feedback = $v.feedback;
      _gradingStatus = $v.gradingStatus;
      _influenceLimited = $v.influenceLimited;
      _nextItemId = $v.nextItemId;
      _outcome = $v.outcome;
      _repairAction = $v.repairAction;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AttemptResult other) {
    _$v = other as _$AttemptResult;
  }

  @override
  void update(void Function(AttemptResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AttemptResult build() => _build();

  _$AttemptResult _build() {
    final _$result = _$v ??
        _$AttemptResult._(
          attemptId: attemptId,
          canComplete: BuiltValueNullFieldError.checkNotNull(
              canComplete, r'AttemptResult', 'canComplete'),
          explanation: explanation,
          explanationAvailable: BuiltValueNullFieldError.checkNotNull(
              explanationAvailable, r'AttemptResult', 'explanationAvailable'),
          feedback: BuiltValueNullFieldError.checkNotNull(
              feedback, r'AttemptResult', 'feedback'),
          gradingStatus: BuiltValueNullFieldError.checkNotNull(
              gradingStatus, r'AttemptResult', 'gradingStatus'),
          influenceLimited: BuiltValueNullFieldError.checkNotNull(
              influenceLimited, r'AttemptResult', 'influenceLimited'),
          nextItemId: nextItemId,
          outcome: BuiltValueNullFieldError.checkNotNull(
              outcome, r'AttemptResult', 'outcome'),
          repairAction: BuiltValueNullFieldError.checkNotNull(
              repairAction, r'AttemptResult', 'repairAction'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
