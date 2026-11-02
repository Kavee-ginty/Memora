// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_summary.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const MissionSummaryStatusEnum _$missionSummaryStatusEnum_planned =
    const MissionSummaryStatusEnum._('planned');
const MissionSummaryStatusEnum _$missionSummaryStatusEnum_started =
    const MissionSummaryStatusEnum._('started');
const MissionSummaryStatusEnum _$missionSummaryStatusEnum_paused =
    const MissionSummaryStatusEnum._('paused');
const MissionSummaryStatusEnum _$missionSummaryStatusEnum_completed =
    const MissionSummaryStatusEnum._('completed');
const MissionSummaryStatusEnum _$missionSummaryStatusEnum_expired =
    const MissionSummaryStatusEnum._('expired');
const MissionSummaryStatusEnum _$missionSummaryStatusEnum_abandoned =
    const MissionSummaryStatusEnum._('abandoned');
const MissionSummaryStatusEnum
    _$missionSummaryStatusEnum_unknownDefaultOpenApi =
    const MissionSummaryStatusEnum._('unknownDefaultOpenApi');

MissionSummaryStatusEnum _$missionSummaryStatusEnumValueOf(String name) {
  switch (name) {
    case 'planned':
      return _$missionSummaryStatusEnum_planned;
    case 'started':
      return _$missionSummaryStatusEnum_started;
    case 'paused':
      return _$missionSummaryStatusEnum_paused;
    case 'completed':
      return _$missionSummaryStatusEnum_completed;
    case 'expired':
      return _$missionSummaryStatusEnum_expired;
    case 'abandoned':
      return _$missionSummaryStatusEnum_abandoned;
    case 'unknownDefaultOpenApi':
      return _$missionSummaryStatusEnum_unknownDefaultOpenApi;
    default:
      return _$missionSummaryStatusEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<MissionSummaryStatusEnum> _$missionSummaryStatusEnumValues =
    BuiltSet<MissionSummaryStatusEnum>(const <MissionSummaryStatusEnum>[
  _$missionSummaryStatusEnum_planned,
  _$missionSummaryStatusEnum_started,
  _$missionSummaryStatusEnum_paused,
  _$missionSummaryStatusEnum_completed,
  _$missionSummaryStatusEnum_expired,
  _$missionSummaryStatusEnum_abandoned,
  _$missionSummaryStatusEnum_unknownDefaultOpenApi,
]);

Serializer<MissionSummaryStatusEnum> _$missionSummaryStatusEnumSerializer =
    _$MissionSummaryStatusEnumSerializer();

class _$MissionSummaryStatusEnumSerializer
    implements PrimitiveSerializer<MissionSummaryStatusEnum> {
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
  final Iterable<Type> types = const <Type>[MissionSummaryStatusEnum];
  @override
  final String wireName = 'MissionSummaryStatusEnum';

  @override
  Object serialize(Serializers serializers, MissionSummaryStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  MissionSummaryStatusEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      MissionSummaryStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$MissionSummary extends MissionSummary {
  @override
  final int completedItemCount;
  @override
  final String? currentItemId;
  @override
  final String dueReason;
  @override
  final int estimatedMinutes;
  @override
  final String expiresAt;
  @override
  final String id;
  @override
  final Date missionDate;
  @override
  final String missionTimezone;
  @override
  final int plannedItemCount;
  @override
  final MissionSummaryStatusEnum status;
  @override
  final String subjectId;
  @override
  final int version;

  factory _$MissionSummary([void Function(MissionSummaryBuilder)? updates]) =>
      (MissionSummaryBuilder()..update(updates))._build();

  _$MissionSummary._(
      {required this.completedItemCount,
      this.currentItemId,
      required this.dueReason,
      required this.estimatedMinutes,
      required this.expiresAt,
      required this.id,
      required this.missionDate,
      required this.missionTimezone,
      required this.plannedItemCount,
      required this.status,
      required this.subjectId,
      required this.version})
      : super._();
  @override
  MissionSummary rebuild(void Function(MissionSummaryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MissionSummaryBuilder toBuilder() => MissionSummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MissionSummary &&
        completedItemCount == other.completedItemCount &&
        currentItemId == other.currentItemId &&
        dueReason == other.dueReason &&
        estimatedMinutes == other.estimatedMinutes &&
        expiresAt == other.expiresAt &&
        id == other.id &&
        missionDate == other.missionDate &&
        missionTimezone == other.missionTimezone &&
        plannedItemCount == other.plannedItemCount &&
        status == other.status &&
        subjectId == other.subjectId &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, completedItemCount.hashCode);
    _$hash = $jc(_$hash, currentItemId.hashCode);
    _$hash = $jc(_$hash, dueReason.hashCode);
    _$hash = $jc(_$hash, estimatedMinutes.hashCode);
    _$hash = $jc(_$hash, expiresAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, missionDate.hashCode);
    _$hash = $jc(_$hash, missionTimezone.hashCode);
    _$hash = $jc(_$hash, plannedItemCount.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, subjectId.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MissionSummary')
          ..add('completedItemCount', completedItemCount)
          ..add('currentItemId', currentItemId)
          ..add('dueReason', dueReason)
          ..add('estimatedMinutes', estimatedMinutes)
          ..add('expiresAt', expiresAt)
          ..add('id', id)
          ..add('missionDate', missionDate)
          ..add('missionTimezone', missionTimezone)
          ..add('plannedItemCount', plannedItemCount)
          ..add('status', status)
          ..add('subjectId', subjectId)
          ..add('version', version))
        .toString();
  }
}

class MissionSummaryBuilder
    implements Builder<MissionSummary, MissionSummaryBuilder> {
  _$MissionSummary? _$v;

  int? _completedItemCount;
  int? get completedItemCount => _$this._completedItemCount;
  set completedItemCount(int? completedItemCount) =>
      _$this._completedItemCount = completedItemCount;

  String? _currentItemId;
  String? get currentItemId => _$this._currentItemId;
  set currentItemId(String? currentItemId) =>
      _$this._currentItemId = currentItemId;

  String? _dueReason;
  String? get dueReason => _$this._dueReason;
  set dueReason(String? dueReason) => _$this._dueReason = dueReason;

  int? _estimatedMinutes;
  int? get estimatedMinutes => _$this._estimatedMinutes;
  set estimatedMinutes(int? estimatedMinutes) =>
      _$this._estimatedMinutes = estimatedMinutes;

  String? _expiresAt;
  String? get expiresAt => _$this._expiresAt;
  set expiresAt(String? expiresAt) => _$this._expiresAt = expiresAt;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  Date? _missionDate;
  Date? get missionDate => _$this._missionDate;
  set missionDate(Date? missionDate) => _$this._missionDate = missionDate;

  String? _missionTimezone;
  String? get missionTimezone => _$this._missionTimezone;
  set missionTimezone(String? missionTimezone) =>
      _$this._missionTimezone = missionTimezone;

  int? _plannedItemCount;
  int? get plannedItemCount => _$this._plannedItemCount;
  set plannedItemCount(int? plannedItemCount) =>
      _$this._plannedItemCount = plannedItemCount;

  MissionSummaryStatusEnum? _status;
  MissionSummaryStatusEnum? get status => _$this._status;
  set status(MissionSummaryStatusEnum? status) => _$this._status = status;

  String? _subjectId;
  String? get subjectId => _$this._subjectId;
  set subjectId(String? subjectId) => _$this._subjectId = subjectId;

  int? _version;
  int? get version => _$this._version;
  set version(int? version) => _$this._version = version;

  MissionSummaryBuilder() {
    MissionSummary._defaults(this);
  }

  MissionSummaryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _completedItemCount = $v.completedItemCount;
      _currentItemId = $v.currentItemId;
      _dueReason = $v.dueReason;
      _estimatedMinutes = $v.estimatedMinutes;
      _expiresAt = $v.expiresAt;
      _id = $v.id;
      _missionDate = $v.missionDate;
      _missionTimezone = $v.missionTimezone;
      _plannedItemCount = $v.plannedItemCount;
      _status = $v.status;
      _subjectId = $v.subjectId;
      _version = $v.version;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MissionSummary other) {
    _$v = other as _$MissionSummary;
  }

  @override
  void update(void Function(MissionSummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MissionSummary build() => _build();

  _$MissionSummary _build() {
    final _$result = _$v ??
        _$MissionSummary._(
          completedItemCount: BuiltValueNullFieldError.checkNotNull(
              completedItemCount, r'MissionSummary', 'completedItemCount'),
          currentItemId: currentItemId,
          dueReason: BuiltValueNullFieldError.checkNotNull(
              dueReason, r'MissionSummary', 'dueReason'),
          estimatedMinutes: BuiltValueNullFieldError.checkNotNull(
              estimatedMinutes, r'MissionSummary', 'estimatedMinutes'),
          expiresAt: BuiltValueNullFieldError.checkNotNull(
              expiresAt, r'MissionSummary', 'expiresAt'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'MissionSummary', 'id'),
          missionDate: BuiltValueNullFieldError.checkNotNull(
              missionDate, r'MissionSummary', 'missionDate'),
          missionTimezone: BuiltValueNullFieldError.checkNotNull(
              missionTimezone, r'MissionSummary', 'missionTimezone'),
          plannedItemCount: BuiltValueNullFieldError.checkNotNull(
              plannedItemCount, r'MissionSummary', 'plannedItemCount'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'MissionSummary', 'status'),
          subjectId: BuiltValueNullFieldError.checkNotNull(
              subjectId, r'MissionSummary', 'subjectId'),
          version: BuiltValueNullFieldError.checkNotNull(
              version, r'MissionSummary', 'version'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
