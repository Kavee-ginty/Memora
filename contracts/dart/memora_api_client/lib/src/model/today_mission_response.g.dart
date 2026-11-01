// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_mission_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TodayMissionResponseStateEnum _$todayMissionResponseStateEnum_noDue =
    const TodayMissionResponseStateEnum._('noDue');
const TodayMissionResponseStateEnum
    _$todayMissionResponseStateEnum_missionReady =
    const TodayMissionResponseStateEnum._('missionReady');
const TodayMissionResponseStateEnum
    _$todayMissionResponseStateEnum_missionInProgress =
    const TodayMissionResponseStateEnum._('missionInProgress');
const TodayMissionResponseStateEnum
    _$todayMissionResponseStateEnum_missionComplete =
    const TodayMissionResponseStateEnum._('missionComplete');
const TodayMissionResponseStateEnum
    _$todayMissionResponseStateEnum_unknownDefaultOpenApi =
    const TodayMissionResponseStateEnum._('unknownDefaultOpenApi');

TodayMissionResponseStateEnum _$todayMissionResponseStateEnumValueOf(
    String name) {
  switch (name) {
    case 'noDue':
      return _$todayMissionResponseStateEnum_noDue;
    case 'missionReady':
      return _$todayMissionResponseStateEnum_missionReady;
    case 'missionInProgress':
      return _$todayMissionResponseStateEnum_missionInProgress;
    case 'missionComplete':
      return _$todayMissionResponseStateEnum_missionComplete;
    case 'unknownDefaultOpenApi':
      return _$todayMissionResponseStateEnum_unknownDefaultOpenApi;
    default:
      return _$todayMissionResponseStateEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<TodayMissionResponseStateEnum>
    _$todayMissionResponseStateEnumValues = BuiltSet<
        TodayMissionResponseStateEnum>(const <TodayMissionResponseStateEnum>[
  _$todayMissionResponseStateEnum_noDue,
  _$todayMissionResponseStateEnum_missionReady,
  _$todayMissionResponseStateEnum_missionInProgress,
  _$todayMissionResponseStateEnum_missionComplete,
  _$todayMissionResponseStateEnum_unknownDefaultOpenApi,
]);

Serializer<TodayMissionResponseStateEnum>
    _$todayMissionResponseStateEnumSerializer =
    _$TodayMissionResponseStateEnumSerializer();

class _$TodayMissionResponseStateEnumSerializer
    implements PrimitiveSerializer<TodayMissionResponseStateEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'noDue': 'no_due',
    'missionReady': 'mission_ready',
    'missionInProgress': 'mission_in_progress',
    'missionComplete': 'mission_complete',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'no_due': 'noDue',
    'mission_ready': 'missionReady',
    'mission_in_progress': 'missionInProgress',
    'mission_complete': 'missionComplete',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[TodayMissionResponseStateEnum];
  @override
  final String wireName = 'TodayMissionResponseStateEnum';

  @override
  Object serialize(
          Serializers serializers, TodayMissionResponseStateEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  TodayMissionResponseStateEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      TodayMissionResponseStateEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$TodayMissionResponse extends TodayMissionResponse {
  @override
  final MissionSummary? mission;
  @override
  final TodayMissionResponseStateEnum state;

  factory _$TodayMissionResponse(
          [void Function(TodayMissionResponseBuilder)? updates]) =>
      (TodayMissionResponseBuilder()..update(updates))._build();

  _$TodayMissionResponse._({this.mission, required this.state}) : super._();
  @override
  TodayMissionResponse rebuild(
          void Function(TodayMissionResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TodayMissionResponseBuilder toBuilder() =>
      TodayMissionResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TodayMissionResponse &&
        mission == other.mission &&
        state == other.state;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mission.hashCode);
    _$hash = $jc(_$hash, state.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TodayMissionResponse')
          ..add('mission', mission)
          ..add('state', state))
        .toString();
  }
}

class TodayMissionResponseBuilder
    implements Builder<TodayMissionResponse, TodayMissionResponseBuilder> {
  _$TodayMissionResponse? _$v;

  MissionSummaryBuilder? _mission;
  MissionSummaryBuilder get mission =>
      _$this._mission ??= MissionSummaryBuilder();
  set mission(MissionSummaryBuilder? mission) => _$this._mission = mission;

  TodayMissionResponseStateEnum? _state;
  TodayMissionResponseStateEnum? get state => _$this._state;
  set state(TodayMissionResponseStateEnum? state) => _$this._state = state;

  TodayMissionResponseBuilder() {
    TodayMissionResponse._defaults(this);
  }

  TodayMissionResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mission = $v.mission?.toBuilder();
      _state = $v.state;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TodayMissionResponse other) {
    _$v = other as _$TodayMissionResponse;
  }

  @override
  void update(void Function(TodayMissionResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TodayMissionResponse build() => _build();

  _$TodayMissionResponse _build() {
    _$TodayMissionResponse _$result;
    try {
      _$result = _$v ??
          _$TodayMissionResponse._(
            mission: _mission?.build(),
            state: BuiltValueNullFieldError.checkNotNull(
                state, r'TodayMissionResponse', 'state'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'mission';
        _mission?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'TodayMissionResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
