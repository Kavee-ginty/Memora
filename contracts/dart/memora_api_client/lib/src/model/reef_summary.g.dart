// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reef_summary.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ReefSummaryConditionEnum _$reefSummaryConditionEnum_new_ =
    const ReefSummaryConditionEnum._('new_');
const ReefSummaryConditionEnum _$reefSummaryConditionEnum_thriving =
    const ReefSummaryConditionEnum._('thriving');
const ReefSummaryConditionEnum _$reefSummaryConditionEnum_healthy =
    const ReefSummaryConditionEnum._('healthy');
const ReefSummaryConditionEnum _$reefSummaryConditionEnum_needsCare =
    const ReefSummaryConditionEnum._('needsCare');
const ReefSummaryConditionEnum _$reefSummaryConditionEnum_dormant =
    const ReefSummaryConditionEnum._('dormant');
const ReefSummaryConditionEnum
    _$reefSummaryConditionEnum_unknownDefaultOpenApi =
    const ReefSummaryConditionEnum._('unknownDefaultOpenApi');

ReefSummaryConditionEnum _$reefSummaryConditionEnumValueOf(String name) {
  switch (name) {
    case 'new_':
      return _$reefSummaryConditionEnum_new_;
    case 'thriving':
      return _$reefSummaryConditionEnum_thriving;
    case 'healthy':
      return _$reefSummaryConditionEnum_healthy;
    case 'needsCare':
      return _$reefSummaryConditionEnum_needsCare;
    case 'dormant':
      return _$reefSummaryConditionEnum_dormant;
    case 'unknownDefaultOpenApi':
      return _$reefSummaryConditionEnum_unknownDefaultOpenApi;
    default:
      return _$reefSummaryConditionEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<ReefSummaryConditionEnum> _$reefSummaryConditionEnumValues =
    BuiltSet<ReefSummaryConditionEnum>(const <ReefSummaryConditionEnum>[
  _$reefSummaryConditionEnum_new_,
  _$reefSummaryConditionEnum_thriving,
  _$reefSummaryConditionEnum_healthy,
  _$reefSummaryConditionEnum_needsCare,
  _$reefSummaryConditionEnum_dormant,
  _$reefSummaryConditionEnum_unknownDefaultOpenApi,
]);

Serializer<ReefSummaryConditionEnum> _$reefSummaryConditionEnumSerializer =
    _$ReefSummaryConditionEnumSerializer();

class _$ReefSummaryConditionEnumSerializer
    implements PrimitiveSerializer<ReefSummaryConditionEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'new_': 'new',
    'thriving': 'thriving',
    'healthy': 'healthy',
    'needsCare': 'needs_care',
    'dormant': 'dormant',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'new': 'new_',
    'thriving': 'thriving',
    'healthy': 'healthy',
    'needs_care': 'needsCare',
    'dormant': 'dormant',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[ReefSummaryConditionEnum];
  @override
  final String wireName = 'ReefSummaryConditionEnum';

  @override
  Object serialize(Serializers serializers, ReefSummaryConditionEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ReefSummaryConditionEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ReefSummaryConditionEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ReefSummary extends ReefSummary {
  @override
  final ReefSummaryConditionEnum condition;
  @override
  final int dueMemoryCount;
  @override
  final num healthScore;
  @override
  final String projectedAt;
  @override
  final String projectionVersion;
  @override
  final String sourceWatermark;
  @override
  final String subjectId;

  factory _$ReefSummary([void Function(ReefSummaryBuilder)? updates]) =>
      (ReefSummaryBuilder()..update(updates))._build();

  _$ReefSummary._(
      {required this.condition,
      required this.dueMemoryCount,
      required this.healthScore,
      required this.projectedAt,
      required this.projectionVersion,
      required this.sourceWatermark,
      required this.subjectId})
      : super._();
  @override
  ReefSummary rebuild(void Function(ReefSummaryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReefSummaryBuilder toBuilder() => ReefSummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReefSummary &&
        condition == other.condition &&
        dueMemoryCount == other.dueMemoryCount &&
        healthScore == other.healthScore &&
        projectedAt == other.projectedAt &&
        projectionVersion == other.projectionVersion &&
        sourceWatermark == other.sourceWatermark &&
        subjectId == other.subjectId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, condition.hashCode);
    _$hash = $jc(_$hash, dueMemoryCount.hashCode);
    _$hash = $jc(_$hash, healthScore.hashCode);
    _$hash = $jc(_$hash, projectedAt.hashCode);
    _$hash = $jc(_$hash, projectionVersion.hashCode);
    _$hash = $jc(_$hash, sourceWatermark.hashCode);
    _$hash = $jc(_$hash, subjectId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReefSummary')
          ..add('condition', condition)
          ..add('dueMemoryCount', dueMemoryCount)
          ..add('healthScore', healthScore)
          ..add('projectedAt', projectedAt)
          ..add('projectionVersion', projectionVersion)
          ..add('sourceWatermark', sourceWatermark)
          ..add('subjectId', subjectId))
        .toString();
  }
}

class ReefSummaryBuilder implements Builder<ReefSummary, ReefSummaryBuilder> {
  _$ReefSummary? _$v;

  ReefSummaryConditionEnum? _condition;
  ReefSummaryConditionEnum? get condition => _$this._condition;
  set condition(ReefSummaryConditionEnum? condition) =>
      _$this._condition = condition;

  int? _dueMemoryCount;
  int? get dueMemoryCount => _$this._dueMemoryCount;
  set dueMemoryCount(int? dueMemoryCount) =>
      _$this._dueMemoryCount = dueMemoryCount;

  num? _healthScore;
  num? get healthScore => _$this._healthScore;
  set healthScore(num? healthScore) => _$this._healthScore = healthScore;

  String? _projectedAt;
  String? get projectedAt => _$this._projectedAt;
  set projectedAt(String? projectedAt) => _$this._projectedAt = projectedAt;

  String? _projectionVersion;
  String? get projectionVersion => _$this._projectionVersion;
  set projectionVersion(String? projectionVersion) =>
      _$this._projectionVersion = projectionVersion;

  String? _sourceWatermark;
  String? get sourceWatermark => _$this._sourceWatermark;
  set sourceWatermark(String? sourceWatermark) =>
      _$this._sourceWatermark = sourceWatermark;

  String? _subjectId;
  String? get subjectId => _$this._subjectId;
  set subjectId(String? subjectId) => _$this._subjectId = subjectId;

  ReefSummaryBuilder() {
    ReefSummary._defaults(this);
  }

  ReefSummaryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _condition = $v.condition;
      _dueMemoryCount = $v.dueMemoryCount;
      _healthScore = $v.healthScore;
      _projectedAt = $v.projectedAt;
      _projectionVersion = $v.projectionVersion;
      _sourceWatermark = $v.sourceWatermark;
      _subjectId = $v.subjectId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReefSummary other) {
    _$v = other as _$ReefSummary;
  }

  @override
  void update(void Function(ReefSummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReefSummary build() => _build();

  _$ReefSummary _build() {
    final _$result = _$v ??
        _$ReefSummary._(
          condition: BuiltValueNullFieldError.checkNotNull(
              condition, r'ReefSummary', 'condition'),
          dueMemoryCount: BuiltValueNullFieldError.checkNotNull(
              dueMemoryCount, r'ReefSummary', 'dueMemoryCount'),
          healthScore: BuiltValueNullFieldError.checkNotNull(
              healthScore, r'ReefSummary', 'healthScore'),
          projectedAt: BuiltValueNullFieldError.checkNotNull(
              projectedAt, r'ReefSummary', 'projectedAt'),
          projectionVersion: BuiltValueNullFieldError.checkNotNull(
              projectionVersion, r'ReefSummary', 'projectionVersion'),
          sourceWatermark: BuiltValueNullFieldError.checkNotNull(
              sourceWatermark, r'ReefSummary', 'sourceWatermark'),
          subjectId: BuiltValueNullFieldError.checkNotNull(
              subjectId, r'ReefSummary', 'subjectId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
