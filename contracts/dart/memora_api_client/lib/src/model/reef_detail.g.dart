// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reef_detail.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ReefDetailConditionEnum _$reefDetailConditionEnum_new_ =
    const ReefDetailConditionEnum._('new_');
const ReefDetailConditionEnum _$reefDetailConditionEnum_thriving =
    const ReefDetailConditionEnum._('thriving');
const ReefDetailConditionEnum _$reefDetailConditionEnum_healthy =
    const ReefDetailConditionEnum._('healthy');
const ReefDetailConditionEnum _$reefDetailConditionEnum_needsCare =
    const ReefDetailConditionEnum._('needsCare');
const ReefDetailConditionEnum _$reefDetailConditionEnum_dormant =
    const ReefDetailConditionEnum._('dormant');
const ReefDetailConditionEnum _$reefDetailConditionEnum_unknownDefaultOpenApi =
    const ReefDetailConditionEnum._('unknownDefaultOpenApi');

ReefDetailConditionEnum _$reefDetailConditionEnumValueOf(String name) {
  switch (name) {
    case 'new_':
      return _$reefDetailConditionEnum_new_;
    case 'thriving':
      return _$reefDetailConditionEnum_thriving;
    case 'healthy':
      return _$reefDetailConditionEnum_healthy;
    case 'needsCare':
      return _$reefDetailConditionEnum_needsCare;
    case 'dormant':
      return _$reefDetailConditionEnum_dormant;
    case 'unknownDefaultOpenApi':
      return _$reefDetailConditionEnum_unknownDefaultOpenApi;
    default:
      return _$reefDetailConditionEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<ReefDetailConditionEnum> _$reefDetailConditionEnumValues =
    BuiltSet<ReefDetailConditionEnum>(const <ReefDetailConditionEnum>[
  _$reefDetailConditionEnum_new_,
  _$reefDetailConditionEnum_thriving,
  _$reefDetailConditionEnum_healthy,
  _$reefDetailConditionEnum_needsCare,
  _$reefDetailConditionEnum_dormant,
  _$reefDetailConditionEnum_unknownDefaultOpenApi,
]);

Serializer<ReefDetailConditionEnum> _$reefDetailConditionEnumSerializer =
    _$ReefDetailConditionEnumSerializer();

class _$ReefDetailConditionEnumSerializer
    implements PrimitiveSerializer<ReefDetailConditionEnum> {
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
  final Iterable<Type> types = const <Type>[ReefDetailConditionEnum];
  @override
  final String wireName = 'ReefDetailConditionEnum';

  @override
  Object serialize(Serializers serializers, ReefDetailConditionEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ReefDetailConditionEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ReefDetailConditionEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ReefDetail extends ReefDetail {
  @override
  final ReefDetailConditionEnum condition;
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
  final BuiltList<RewardGrant> rewards;
  @override
  final String sourceWatermark;
  @override
  final String subjectId;
  @override
  final String subjectName;

  factory _$ReefDetail([void Function(ReefDetailBuilder)? updates]) =>
      (ReefDetailBuilder()..update(updates))._build();

  _$ReefDetail._(
      {required this.condition,
      required this.dueMemoryCount,
      required this.healthScore,
      required this.prerequisiteRisk,
      required this.projectedAt,
      required this.projectionVersion,
      required this.recentEvidenceScore,
      required this.rewards,
      required this.sourceWatermark,
      required this.subjectId,
      required this.subjectName})
      : super._();
  @override
  ReefDetail rebuild(void Function(ReefDetailBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReefDetailBuilder toBuilder() => ReefDetailBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReefDetail &&
        condition == other.condition &&
        dueMemoryCount == other.dueMemoryCount &&
        healthScore == other.healthScore &&
        prerequisiteRisk == other.prerequisiteRisk &&
        projectedAt == other.projectedAt &&
        projectionVersion == other.projectionVersion &&
        recentEvidenceScore == other.recentEvidenceScore &&
        rewards == other.rewards &&
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
    _$hash = $jc(_$hash, rewards.hashCode);
    _$hash = $jc(_$hash, sourceWatermark.hashCode);
    _$hash = $jc(_$hash, subjectId.hashCode);
    _$hash = $jc(_$hash, subjectName.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReefDetail')
          ..add('condition', condition)
          ..add('dueMemoryCount', dueMemoryCount)
          ..add('healthScore', healthScore)
          ..add('prerequisiteRisk', prerequisiteRisk)
          ..add('projectedAt', projectedAt)
          ..add('projectionVersion', projectionVersion)
          ..add('recentEvidenceScore', recentEvidenceScore)
          ..add('rewards', rewards)
          ..add('sourceWatermark', sourceWatermark)
          ..add('subjectId', subjectId)
          ..add('subjectName', subjectName))
        .toString();
  }
}

class ReefDetailBuilder implements Builder<ReefDetail, ReefDetailBuilder> {
  _$ReefDetail? _$v;

  ReefDetailConditionEnum? _condition;
  ReefDetailConditionEnum? get condition => _$this._condition;
  set condition(ReefDetailConditionEnum? condition) =>
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

  ListBuilder<RewardGrant>? _rewards;
  ListBuilder<RewardGrant> get rewards =>
      _$this._rewards ??= ListBuilder<RewardGrant>();
  set rewards(ListBuilder<RewardGrant>? rewards) => _$this._rewards = rewards;

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

  ReefDetailBuilder() {
    ReefDetail._defaults(this);
  }

  ReefDetailBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _condition = $v.condition;
      _dueMemoryCount = $v.dueMemoryCount;
      _healthScore = $v.healthScore;
      _prerequisiteRisk = $v.prerequisiteRisk;
      _projectedAt = $v.projectedAt;
      _projectionVersion = $v.projectionVersion;
      _recentEvidenceScore = $v.recentEvidenceScore;
      _rewards = $v.rewards.toBuilder();
      _sourceWatermark = $v.sourceWatermark;
      _subjectId = $v.subjectId;
      _subjectName = $v.subjectName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReefDetail other) {
    _$v = other as _$ReefDetail;
  }

  @override
  void update(void Function(ReefDetailBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReefDetail build() => _build();

  _$ReefDetail _build() {
    _$ReefDetail _$result;
    try {
      _$result = _$v ??
          _$ReefDetail._(
            condition: BuiltValueNullFieldError.checkNotNull(
                condition, r'ReefDetail', 'condition'),
            dueMemoryCount: BuiltValueNullFieldError.checkNotNull(
                dueMemoryCount, r'ReefDetail', 'dueMemoryCount'),
            healthScore: BuiltValueNullFieldError.checkNotNull(
                healthScore, r'ReefDetail', 'healthScore'),
            prerequisiteRisk: BuiltValueNullFieldError.checkNotNull(
                prerequisiteRisk, r'ReefDetail', 'prerequisiteRisk'),
            projectedAt: BuiltValueNullFieldError.checkNotNull(
                projectedAt, r'ReefDetail', 'projectedAt'),
            projectionVersion: BuiltValueNullFieldError.checkNotNull(
                projectionVersion, r'ReefDetail', 'projectionVersion'),
            recentEvidenceScore: BuiltValueNullFieldError.checkNotNull(
                recentEvidenceScore, r'ReefDetail', 'recentEvidenceScore'),
            rewards: rewards.build(),
            sourceWatermark: BuiltValueNullFieldError.checkNotNull(
                sourceWatermark, r'ReefDetail', 'sourceWatermark'),
            subjectId: BuiltValueNullFieldError.checkNotNull(
                subjectId, r'ReefDetail', 'subjectId'),
            subjectName: BuiltValueNullFieldError.checkNotNull(
                subjectName, r'ReefDetail', 'subjectName'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'rewards';
        rewards.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ReefDetail', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
