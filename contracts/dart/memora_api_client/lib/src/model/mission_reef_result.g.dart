// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_reef_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const MissionReefResultConditionEnum _$missionReefResultConditionEnum_new_ =
    const MissionReefResultConditionEnum._('new_');
const MissionReefResultConditionEnum _$missionReefResultConditionEnum_thriving =
    const MissionReefResultConditionEnum._('thriving');
const MissionReefResultConditionEnum _$missionReefResultConditionEnum_healthy =
    const MissionReefResultConditionEnum._('healthy');
const MissionReefResultConditionEnum
    _$missionReefResultConditionEnum_needsCare =
    const MissionReefResultConditionEnum._('needsCare');
const MissionReefResultConditionEnum _$missionReefResultConditionEnum_dormant =
    const MissionReefResultConditionEnum._('dormant');
const MissionReefResultConditionEnum
    _$missionReefResultConditionEnum_unknownDefaultOpenApi =
    const MissionReefResultConditionEnum._('unknownDefaultOpenApi');

MissionReefResultConditionEnum _$missionReefResultConditionEnumValueOf(
    String name) {
  switch (name) {
    case 'new_':
      return _$missionReefResultConditionEnum_new_;
    case 'thriving':
      return _$missionReefResultConditionEnum_thriving;
    case 'healthy':
      return _$missionReefResultConditionEnum_healthy;
    case 'needsCare':
      return _$missionReefResultConditionEnum_needsCare;
    case 'dormant':
      return _$missionReefResultConditionEnum_dormant;
    case 'unknownDefaultOpenApi':
      return _$missionReefResultConditionEnum_unknownDefaultOpenApi;
    default:
      return _$missionReefResultConditionEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<MissionReefResultConditionEnum>
    _$missionReefResultConditionEnumValues = BuiltSet<
        MissionReefResultConditionEnum>(const <MissionReefResultConditionEnum>[
  _$missionReefResultConditionEnum_new_,
  _$missionReefResultConditionEnum_thriving,
  _$missionReefResultConditionEnum_healthy,
  _$missionReefResultConditionEnum_needsCare,
  _$missionReefResultConditionEnum_dormant,
  _$missionReefResultConditionEnum_unknownDefaultOpenApi,
]);

Serializer<MissionReefResultConditionEnum>
    _$missionReefResultConditionEnumSerializer =
    _$MissionReefResultConditionEnumSerializer();

class _$MissionReefResultConditionEnumSerializer
    implements PrimitiveSerializer<MissionReefResultConditionEnum> {
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
  final Iterable<Type> types = const <Type>[MissionReefResultConditionEnum];
  @override
  final String wireName = 'MissionReefResultConditionEnum';

  @override
  Object serialize(
          Serializers serializers, MissionReefResultConditionEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  MissionReefResultConditionEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      MissionReefResultConditionEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$MissionReefResult extends MissionReefResult {
  @override
  final MissionReefResultConditionEnum condition;
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

  factory _$MissionReefResult(
          [void Function(MissionReefResultBuilder)? updates]) =>
      (MissionReefResultBuilder()..update(updates))._build();

  _$MissionReefResult._(
      {required this.condition,
      required this.dueMemoryCount,
      required this.healthScore,
      required this.projectedAt,
      required this.projectionVersion,
      required this.sourceWatermark,
      required this.subjectId})
      : super._();
  @override
  MissionReefResult rebuild(void Function(MissionReefResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MissionReefResultBuilder toBuilder() =>
      MissionReefResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MissionReefResult &&
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
    return (newBuiltValueToStringHelper(r'MissionReefResult')
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

class MissionReefResultBuilder
    implements Builder<MissionReefResult, MissionReefResultBuilder> {
  _$MissionReefResult? _$v;

  MissionReefResultConditionEnum? _condition;
  MissionReefResultConditionEnum? get condition => _$this._condition;
  set condition(MissionReefResultConditionEnum? condition) =>
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

  MissionReefResultBuilder() {
    MissionReefResult._defaults(this);
  }

  MissionReefResultBuilder get _$this {
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
  void replace(MissionReefResult other) {
    _$v = other as _$MissionReefResult;
  }

  @override
  void update(void Function(MissionReefResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MissionReefResult build() => _build();

  _$MissionReefResult _build() {
    final _$result = _$v ??
        _$MissionReefResult._(
          condition: BuiltValueNullFieldError.checkNotNull(
              condition, r'MissionReefResult', 'condition'),
          dueMemoryCount: BuiltValueNullFieldError.checkNotNull(
              dueMemoryCount, r'MissionReefResult', 'dueMemoryCount'),
          healthScore: BuiltValueNullFieldError.checkNotNull(
              healthScore, r'MissionReefResult', 'healthScore'),
          projectedAt: BuiltValueNullFieldError.checkNotNull(
              projectedAt, r'MissionReefResult', 'projectedAt'),
          projectionVersion: BuiltValueNullFieldError.checkNotNull(
              projectionVersion, r'MissionReefResult', 'projectionVersion'),
          sourceWatermark: BuiltValueNullFieldError.checkNotNull(
              sourceWatermark, r'MissionReefResult', 'sourceWatermark'),
          subjectId: BuiltValueNullFieldError.checkNotNull(
              subjectId, r'MissionReefResult', 'subjectId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
