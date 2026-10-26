// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_mission_summary.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ActiveMissionSummaryStatusEnum _$activeMissionSummaryStatusEnum_planned =
    const ActiveMissionSummaryStatusEnum._('planned');
const ActiveMissionSummaryStatusEnum _$activeMissionSummaryStatusEnum_started =
    const ActiveMissionSummaryStatusEnum._('started');
const ActiveMissionSummaryStatusEnum _$activeMissionSummaryStatusEnum_paused =
    const ActiveMissionSummaryStatusEnum._('paused');
const ActiveMissionSummaryStatusEnum
    _$activeMissionSummaryStatusEnum_unknownDefaultOpenApi =
    const ActiveMissionSummaryStatusEnum._('unknownDefaultOpenApi');

ActiveMissionSummaryStatusEnum _$activeMissionSummaryStatusEnumValueOf(
    String name) {
  switch (name) {
    case 'planned':
      return _$activeMissionSummaryStatusEnum_planned;
    case 'started':
      return _$activeMissionSummaryStatusEnum_started;
    case 'paused':
      return _$activeMissionSummaryStatusEnum_paused;
    case 'unknownDefaultOpenApi':
      return _$activeMissionSummaryStatusEnum_unknownDefaultOpenApi;
    default:
      return _$activeMissionSummaryStatusEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<ActiveMissionSummaryStatusEnum>
    _$activeMissionSummaryStatusEnumValues = BuiltSet<
        ActiveMissionSummaryStatusEnum>(const <ActiveMissionSummaryStatusEnum>[
  _$activeMissionSummaryStatusEnum_planned,
  _$activeMissionSummaryStatusEnum_started,
  _$activeMissionSummaryStatusEnum_paused,
  _$activeMissionSummaryStatusEnum_unknownDefaultOpenApi,
]);

Serializer<ActiveMissionSummaryStatusEnum>
    _$activeMissionSummaryStatusEnumSerializer =
    _$ActiveMissionSummaryStatusEnumSerializer();

class _$ActiveMissionSummaryStatusEnumSerializer
    implements PrimitiveSerializer<ActiveMissionSummaryStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'planned': 'planned',
    'started': 'started',
    'paused': 'paused',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'planned': 'planned',
    'started': 'started',
    'paused': 'paused',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[ActiveMissionSummaryStatusEnum];
  @override
  final String wireName = 'ActiveMissionSummaryStatusEnum';

  @override
  Object serialize(
          Serializers serializers, ActiveMissionSummaryStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ActiveMissionSummaryStatusEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ActiveMissionSummaryStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ActiveMissionSummary extends ActiveMissionSummary {
  @override
  final String id;
  @override
  final Date missionDate;
  @override
  final ActiveMissionSummaryStatusEnum status;
  @override
  final String subjectId;

  factory _$ActiveMissionSummary(
          [void Function(ActiveMissionSummaryBuilder)? updates]) =>
      (ActiveMissionSummaryBuilder()..update(updates))._build();

  _$ActiveMissionSummary._(
      {required this.id,
      required this.missionDate,
      required this.status,
      required this.subjectId})
      : super._();
  @override
  ActiveMissionSummary rebuild(
          void Function(ActiveMissionSummaryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ActiveMissionSummaryBuilder toBuilder() =>
      ActiveMissionSummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ActiveMissionSummary &&
        id == other.id &&
        missionDate == other.missionDate &&
        status == other.status &&
        subjectId == other.subjectId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, missionDate.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, subjectId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ActiveMissionSummary')
          ..add('id', id)
          ..add('missionDate', missionDate)
          ..add('status', status)
          ..add('subjectId', subjectId))
        .toString();
  }
}

class ActiveMissionSummaryBuilder
    implements Builder<ActiveMissionSummary, ActiveMissionSummaryBuilder> {
  _$ActiveMissionSummary? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  Date? _missionDate;
  Date? get missionDate => _$this._missionDate;
  set missionDate(Date? missionDate) => _$this._missionDate = missionDate;

  ActiveMissionSummaryStatusEnum? _status;
  ActiveMissionSummaryStatusEnum? get status => _$this._status;
  set status(ActiveMissionSummaryStatusEnum? status) => _$this._status = status;

  String? _subjectId;
  String? get subjectId => _$this._subjectId;
  set subjectId(String? subjectId) => _$this._subjectId = subjectId;

  ActiveMissionSummaryBuilder() {
    ActiveMissionSummary._defaults(this);
  }

  ActiveMissionSummaryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _missionDate = $v.missionDate;
      _status = $v.status;
      _subjectId = $v.subjectId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ActiveMissionSummary other) {
    _$v = other as _$ActiveMissionSummary;
  }

  @override
  void update(void Function(ActiveMissionSummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ActiveMissionSummary build() => _build();

  _$ActiveMissionSummary _build() {
    final _$result = _$v ??
        _$ActiveMissionSummary._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'ActiveMissionSummary', 'id'),
          missionDate: BuiltValueNullFieldError.checkNotNull(
              missionDate, r'ActiveMissionSummary', 'missionDate'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'ActiveMissionSummary', 'status'),
          subjectId: BuiltValueNullFieldError.checkNotNull(
              subjectId, r'ActiveMissionSummary', 'subjectId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
