// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_mission.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const HomeMissionStatusEnum _$homeMissionStatusEnum_planned =
    const HomeMissionStatusEnum._('planned');
const HomeMissionStatusEnum _$homeMissionStatusEnum_started =
    const HomeMissionStatusEnum._('started');
const HomeMissionStatusEnum _$homeMissionStatusEnum_paused =
    const HomeMissionStatusEnum._('paused');
const HomeMissionStatusEnum _$homeMissionStatusEnum_completed =
    const HomeMissionStatusEnum._('completed');
const HomeMissionStatusEnum _$homeMissionStatusEnum_expired =
    const HomeMissionStatusEnum._('expired');
const HomeMissionStatusEnum _$homeMissionStatusEnum_abandoned =
    const HomeMissionStatusEnum._('abandoned');
const HomeMissionStatusEnum _$homeMissionStatusEnum_unknownDefaultOpenApi =
    const HomeMissionStatusEnum._('unknownDefaultOpenApi');

HomeMissionStatusEnum _$homeMissionStatusEnumValueOf(String name) {
  switch (name) {
    case 'planned':
      return _$homeMissionStatusEnum_planned;
    case 'started':
      return _$homeMissionStatusEnum_started;
    case 'paused':
      return _$homeMissionStatusEnum_paused;
    case 'completed':
      return _$homeMissionStatusEnum_completed;
    case 'expired':
      return _$homeMissionStatusEnum_expired;
    case 'abandoned':
      return _$homeMissionStatusEnum_abandoned;
    case 'unknownDefaultOpenApi':
      return _$homeMissionStatusEnum_unknownDefaultOpenApi;
    default:
      return _$homeMissionStatusEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<HomeMissionStatusEnum> _$homeMissionStatusEnumValues =
    BuiltSet<HomeMissionStatusEnum>(const <HomeMissionStatusEnum>[
  _$homeMissionStatusEnum_planned,
  _$homeMissionStatusEnum_started,
  _$homeMissionStatusEnum_paused,
  _$homeMissionStatusEnum_completed,
  _$homeMissionStatusEnum_expired,
  _$homeMissionStatusEnum_abandoned,
  _$homeMissionStatusEnum_unknownDefaultOpenApi,
]);

Serializer<HomeMissionStatusEnum> _$homeMissionStatusEnumSerializer =
    _$HomeMissionStatusEnumSerializer();

class _$HomeMissionStatusEnumSerializer
    implements PrimitiveSerializer<HomeMissionStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'planned': 'planned',
    'started': 'started',
    'paused': 'paused',
    'completed': 'completed',
    'expired': 'expired',
    'abandoned': 'abandoned',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'planned': 'planned',
    'started': 'started',
    'paused': 'paused',
    'completed': 'completed',
    'expired': 'expired',
    'abandoned': 'abandoned',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[HomeMissionStatusEnum];
  @override
  final String wireName = 'HomeMissionStatusEnum';

  @override
  Object serialize(Serializers serializers, HomeMissionStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  HomeMissionStatusEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      HomeMissionStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$HomeMission extends HomeMission {
  @override
  final Optional<MissionCompletionResult?> completionSummary;
  @override
  final int estimatedMinutes;
  @override
  final String id;
  @override
  final Date missionDate;
  @override
  final int plannedItemCount;
  @override
  final HomeMissionStatusEnum status;
  @override
  final String subjectId;

  factory _$HomeMission([void Function(HomeMissionBuilder)? updates]) =>
      (HomeMissionBuilder()..update(updates))._build();

  _$HomeMission._(
      {required this.completionSummary,
      required this.estimatedMinutes,
      required this.id,
      required this.missionDate,
      required this.plannedItemCount,
      required this.status,
      required this.subjectId})
      : super._();
  @override
  HomeMission rebuild(void Function(HomeMissionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  HomeMissionBuilder toBuilder() => HomeMissionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is HomeMission &&
        completionSummary == other.completionSummary &&
        estimatedMinutes == other.estimatedMinutes &&
        id == other.id &&
        missionDate == other.missionDate &&
        plannedItemCount == other.plannedItemCount &&
        status == other.status &&
        subjectId == other.subjectId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, completionSummary.hashCode);
    _$hash = $jc(_$hash, estimatedMinutes.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, missionDate.hashCode);
    _$hash = $jc(_$hash, plannedItemCount.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, subjectId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'HomeMission')
          ..add('completionSummary', completionSummary)
          ..add('estimatedMinutes', estimatedMinutes)
          ..add('id', id)
          ..add('missionDate', missionDate)
          ..add('plannedItemCount', plannedItemCount)
          ..add('status', status)
          ..add('subjectId', subjectId))
        .toString();
  }
}

class HomeMissionBuilder implements Builder<HomeMission, HomeMissionBuilder> {
  _$HomeMission? _$v;

  Optional<MissionCompletionResult?>? _completionSummary;
  Optional<MissionCompletionResult?>? get completionSummary =>
      _$this._completionSummary;
  set completionSummary(
          Optional<MissionCompletionResult?>? completionSummary) =>
      _$this._completionSummary = completionSummary;

  int? _estimatedMinutes;
  int? get estimatedMinutes => _$this._estimatedMinutes;
  set estimatedMinutes(int? estimatedMinutes) =>
      _$this._estimatedMinutes = estimatedMinutes;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  Date? _missionDate;
  Date? get missionDate => _$this._missionDate;
  set missionDate(Date? missionDate) => _$this._missionDate = missionDate;

  int? _plannedItemCount;
  int? get plannedItemCount => _$this._plannedItemCount;
  set plannedItemCount(int? plannedItemCount) =>
      _$this._plannedItemCount = plannedItemCount;

  HomeMissionStatusEnum? _status;
  HomeMissionStatusEnum? get status => _$this._status;
  set status(HomeMissionStatusEnum? status) => _$this._status = status;

  String? _subjectId;
  String? get subjectId => _$this._subjectId;
  set subjectId(String? subjectId) => _$this._subjectId = subjectId;

  HomeMissionBuilder() {
    HomeMission._defaults(this);
  }

  HomeMissionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _completionSummary = $v.completionSummary;
      _estimatedMinutes = $v.estimatedMinutes;
      _id = $v.id;
      _missionDate = $v.missionDate;
      _plannedItemCount = $v.plannedItemCount;
      _status = $v.status;
      _subjectId = $v.subjectId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(HomeMission other) {
    _$v = other as _$HomeMission;
  }

  @override
  void update(void Function(HomeMissionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  HomeMission build() => _build();

  _$HomeMission _build() {
    final _$result = _$v ??
        _$HomeMission._(
          completionSummary: BuiltValueNullFieldError.checkNotNull(
              completionSummary, r'HomeMission', 'completionSummary'),
          estimatedMinutes: BuiltValueNullFieldError.checkNotNull(
              estimatedMinutes, r'HomeMission', 'estimatedMinutes'),
          id: BuiltValueNullFieldError.checkNotNull(id, r'HomeMission', 'id'),
          missionDate: BuiltValueNullFieldError.checkNotNull(
              missionDate, r'HomeMission', 'missionDate'),
          plannedItemCount: BuiltValueNullFieldError.checkNotNull(
              plannedItemCount, r'HomeMission', 'plannedItemCount'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'HomeMission', 'status'),
          subjectId: BuiltValueNullFieldError.checkNotNull(
              subjectId, r'HomeMission', 'subjectId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
