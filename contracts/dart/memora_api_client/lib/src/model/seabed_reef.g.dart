// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seabed_reef.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const SeabedReefConditionEnum _$seabedReefConditionEnum_new_ =
    const SeabedReefConditionEnum._('new_');
const SeabedReefConditionEnum _$seabedReefConditionEnum_thriving =
    const SeabedReefConditionEnum._('thriving');
const SeabedReefConditionEnum _$seabedReefConditionEnum_healthy =
    const SeabedReefConditionEnum._('healthy');
const SeabedReefConditionEnum _$seabedReefConditionEnum_needsCare =
    const SeabedReefConditionEnum._('needsCare');
const SeabedReefConditionEnum _$seabedReefConditionEnum_dormant =
    const SeabedReefConditionEnum._('dormant');
const SeabedReefConditionEnum _$seabedReefConditionEnum_unknownDefaultOpenApi =
    const SeabedReefConditionEnum._('unknownDefaultOpenApi');

SeabedReefConditionEnum _$seabedReefConditionEnumValueOf(String name) {
  switch (name) {
    case 'new_':
      return _$seabedReefConditionEnum_new_;
    case 'thriving':
      return _$seabedReefConditionEnum_thriving;
    case 'healthy':
      return _$seabedReefConditionEnum_healthy;
    case 'needsCare':
      return _$seabedReefConditionEnum_needsCare;
    case 'dormant':
      return _$seabedReefConditionEnum_dormant;
    case 'unknownDefaultOpenApi':
      return _$seabedReefConditionEnum_unknownDefaultOpenApi;
    default:
      return _$seabedReefConditionEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<SeabedReefConditionEnum> _$seabedReefConditionEnumValues =
    BuiltSet<SeabedReefConditionEnum>(const <SeabedReefConditionEnum>[
  _$seabedReefConditionEnum_new_,
  _$seabedReefConditionEnum_thriving,
  _$seabedReefConditionEnum_healthy,
  _$seabedReefConditionEnum_needsCare,
  _$seabedReefConditionEnum_dormant,
  _$seabedReefConditionEnum_unknownDefaultOpenApi,
]);

Serializer<SeabedReefConditionEnum> _$seabedReefConditionEnumSerializer =
    _$SeabedReefConditionEnumSerializer();

class _$SeabedReefConditionEnumSerializer
    implements PrimitiveSerializer<SeabedReefConditionEnum> {
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
  final Iterable<Type> types = const <Type>[SeabedReefConditionEnum];
  @override
  final String wireName = 'SeabedReefConditionEnum';

  @override
  Object serialize(Serializers serializers, SeabedReefConditionEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  SeabedReefConditionEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      SeabedReefConditionEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$SeabedReef extends SeabedReef {
  @override
  final SeabedReefConditionEnum condition;
  @override
  final int dueMemoryCount;
  @override
  final num healthScore;
  @override
  final num prerequisiteRisk;
  @override
  final String projectedAt;
  @override
  final String projectionVersion;
  @override
  final num recentEvidenceScore;
  @override
  final String sourceWatermark;
  @override
  final String subjectId;
  @override
  final String subjectName;

  factory _$SeabedReef([void Function(SeabedReefBuilder)? updates]) =>
      (SeabedReefBuilder()..update(updates))._build();

  _$SeabedReef._(
      {required this.condition,
      required this.dueMemoryCount,
      required this.healthScore,
      required this.prerequisiteRisk,
      required this.projectedAt,
      required this.projectionVersion,
      required this.recentEvidenceScore,
      required this.sourceWatermark,
      required this.subjectId,
      required this.subjectName})
      : super._();
  @override
  SeabedReef rebuild(void Function(SeabedReefBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SeabedReefBuilder toBuilder() => SeabedReefBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SeabedReef &&
        condition == other.condition &&
        dueMemoryCount == other.dueMemoryCount &&
        healthScore == other.healthScore &&
        prerequisiteRisk == other.prerequisiteRisk &&
        projectedAt == other.projectedAt &&
        projectionVersion == other.projectionVersion &&
        recentEvidenceScore == other.recentEvidenceScore &&
        sourceWatermark == other.sourceWatermark &&
        subjectId == other.subjectId &&
        subjectName == other.subjectName;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, condition.hashCode);
    _$hash = $jc(_$hash, dueMemoryCount.hashCode);
    _$hash = $jc(_$hash, healthScore.hashCode);
    _$hash = $jc(_$hash, prerequisiteRisk.hashCode);
    _$hash = $jc(_$hash, projectedAt.hashCode);
    _$hash = $jc(_$hash, projectionVersion.hashCode);
    _$hash = $jc(_$hash, recentEvidenceScore.hashCode);
    _$hash = $jc(_$hash, sourceWatermark.hashCode);
    _$hash = $jc(_$hash, subjectId.hashCode);
    _$hash = $jc(_$hash, subjectName.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SeabedReef')
          ..add('condition', condition)
          ..add('dueMemoryCount', dueMemoryCount)
          ..add('healthScore', healthScore)
          ..add('prerequisiteRisk', prerequisiteRisk)
          ..add('projectedAt', projectedAt)
          ..add('projectionVersion', projectionVersion)
          ..add('recentEvidenceScore', recentEvidenceScore)
          ..add('sourceWatermark', sourceWatermark)
          ..add('subjectId', subjectId)
          ..add('subjectName', subjectName))
        .toString();
  }
}

class SeabedReefBuilder implements Builder<SeabedReef, SeabedReefBuilder> {
  _$SeabedReef? _$v;

  SeabedReefConditionEnum? _condition;
  SeabedReefConditionEnum? get condition => _$this._condition;
  set condition(SeabedReefConditionEnum? condition) =>
      _$this._condition = condition;

  int? _dueMemoryCount;
  int? get dueMemoryCount => _$this._dueMemoryCount;
  set dueMemoryCount(int? dueMemoryCount) =>
      _$this._dueMemoryCount = dueMemoryCount;

  num? _healthScore;
  num? get healthScore => _$this._healthScore;
  set healthScore(num? healthScore) => _$this._healthScore = healthScore;

  num? _prerequisiteRisk;
  num? get prerequisiteRisk => _$this._prerequisiteRisk;
  set prerequisiteRisk(num? prerequisiteRisk) =>
      _$this._prerequisiteRisk = prerequisiteRisk;

  String? _projectedAt;
  String? get projectedAt => _$this._projectedAt;
  set projectedAt(String? projectedAt) => _$this._projectedAt = projectedAt;

  String? _projectionVersion;
  String? get projectionVersion => _$this._projectionVersion;
  set projectionVersion(String? projectionVersion) =>
      _$this._projectionVersion = projectionVersion;

  num? _recentEvidenceScore;
  num? get recentEvidenceScore => _$this._recentEvidenceScore;
  set recentEvidenceScore(num? recentEvidenceScore) =>
      _$this._recentEvidenceScore = recentEvidenceScore;

  String? _sourceWatermark;
  String? get sourceWatermark => _$this._sourceWatermark;
  set sourceWatermark(String? sourceWatermark) =>
      _$this._sourceWatermark = sourceWatermark;

  String? _subjectId;
  String? get subjectId => _$this._subjectId;
  set subjectId(String? subjectId) => _$this._subjectId = subjectId;

  String? _subjectName;
  String? get subjectName => _$this._subjectName;
  set subjectName(String? subjectName) => _$this._subjectName = subjectName;

  SeabedReefBuilder() {
    SeabedReef._defaults(this);
  }

  SeabedReefBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _condition = $v.condition;
      _dueMemoryCount = $v.dueMemoryCount;
      _healthScore = $v.healthScore;
      _prerequisiteRisk = $v.prerequisiteRisk;
      _projectedAt = $v.projectedAt;
      _projectionVersion = $v.projectionVersion;
      _recentEvidenceScore = $v.recentEvidenceScore;
      _sourceWatermark = $v.sourceWatermark;
      _subjectId = $v.subjectId;
      _subjectName = $v.subjectName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SeabedReef other) {
    _$v = other as _$SeabedReef;
  }

  @override
  void update(void Function(SeabedReefBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SeabedReef build() => _build();

  _$SeabedReef _build() {
    final _$result = _$v ??
        _$SeabedReef._(
          condition: BuiltValueNullFieldError.checkNotNull(
              condition, r'SeabedReef', 'condition'),
          dueMemoryCount: BuiltValueNullFieldError.checkNotNull(
              dueMemoryCount, r'SeabedReef', 'dueMemoryCount'),
          healthScore: BuiltValueNullFieldError.checkNotNull(
              healthScore, r'SeabedReef', 'healthScore'),
          prerequisiteRisk: BuiltValueNullFieldError.checkNotNull(
              prerequisiteRisk, r'SeabedReef', 'prerequisiteRisk'),
          projectedAt: BuiltValueNullFieldError.checkNotNull(
              projectedAt, r'SeabedReef', 'projectedAt'),
          projectionVersion: BuiltValueNullFieldError.checkNotNull(
              projectionVersion, r'SeabedReef', 'projectionVersion'),
          recentEvidenceScore: BuiltValueNullFieldError.checkNotNull(
              recentEvidenceScore, r'SeabedReef', 'recentEvidenceScore'),
          sourceWatermark: BuiltValueNullFieldError.checkNotNull(
              sourceWatermark, r'SeabedReef', 'sourceWatermark'),
          subjectId: BuiltValueNullFieldError.checkNotNull(
              subjectId, r'SeabedReef', 'subjectId'),
          subjectName: BuiltValueNullFieldError.checkNotNull(
              subjectName, r'SeabedReef', 'subjectName'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
