// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const HomeResponseStateEnum _$homeResponseStateEnum_setup =
    const HomeResponseStateEnum._('setup');
const HomeResponseStateEnum _$homeResponseStateEnum_missionReady =
    const HomeResponseStateEnum._('missionReady');
const HomeResponseStateEnum _$homeResponseStateEnum_missionInProgress =
    const HomeResponseStateEnum._('missionInProgress');
const HomeResponseStateEnum _$homeResponseStateEnum_missionComplete =
    const HomeResponseStateEnum._('missionComplete');
const HomeResponseStateEnum _$homeResponseStateEnum_caredFor =
    const HomeResponseStateEnum._('caredFor');
const HomeResponseStateEnum _$homeResponseStateEnum_unknownDefaultOpenApi =
    const HomeResponseStateEnum._('unknownDefaultOpenApi');

HomeResponseStateEnum _$homeResponseStateEnumValueOf(String name) {
  switch (name) {
    case 'setup':
      return _$homeResponseStateEnum_setup;
    case 'missionReady':
      return _$homeResponseStateEnum_missionReady;
    case 'missionInProgress':
      return _$homeResponseStateEnum_missionInProgress;
    case 'missionComplete':
      return _$homeResponseStateEnum_missionComplete;
    case 'caredFor':
      return _$homeResponseStateEnum_caredFor;
    case 'unknownDefaultOpenApi':
      return _$homeResponseStateEnum_unknownDefaultOpenApi;
    default:
      return _$homeResponseStateEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<HomeResponseStateEnum> _$homeResponseStateEnumValues =
    BuiltSet<HomeResponseStateEnum>(const <HomeResponseStateEnum>[
  _$homeResponseStateEnum_setup,
  _$homeResponseStateEnum_missionReady,
  _$homeResponseStateEnum_missionInProgress,
  _$homeResponseStateEnum_missionComplete,
  _$homeResponseStateEnum_caredFor,
  _$homeResponseStateEnum_unknownDefaultOpenApi,
]);

Serializer<HomeResponseStateEnum> _$homeResponseStateEnumSerializer =
    _$HomeResponseStateEnumSerializer();

class _$HomeResponseStateEnumSerializer
    implements PrimitiveSerializer<HomeResponseStateEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'setup': 'setup',
    'missionReady': 'mission_ready',
    'missionInProgress': 'mission_in_progress',
    'missionComplete': 'mission_complete',
    'caredFor': 'cared_for',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'setup': 'setup',
    'mission_ready': 'missionReady',
    'mission_in_progress': 'missionInProgress',
    'mission_complete': 'missionComplete',
    'cared_for': 'caredFor',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[HomeResponseStateEnum];
  @override
  final String wireName = 'HomeResponseStateEnum';

  @override
  Object serialize(Serializers serializers, HomeResponseStateEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  HomeResponseStateEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      HomeResponseStateEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$HomeResponse extends HomeResponse {
  @override
  final HomeMission? mission;
  @override
  final ReefSummary? reef;
  @override
  final String serverTime;
  @override
  final HomeResponseStateEnum state;
  @override
  final int streakDays;
  @override
  final int xpBalance;

  factory _$HomeResponse([void Function(HomeResponseBuilder)? updates]) =>
      (HomeResponseBuilder()..update(updates))._build();

  _$HomeResponse._(
      {this.mission,
      this.reef,
      required this.serverTime,
      required this.state,
      required this.streakDays,
      required this.xpBalance})
      : super._();
  @override
  HomeResponse rebuild(void Function(HomeResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  HomeResponseBuilder toBuilder() => HomeResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is HomeResponse &&
        mission == other.mission &&
        reef == other.reef &&
        serverTime == other.serverTime &&
        state == other.state &&
        streakDays == other.streakDays &&
        xpBalance == other.xpBalance;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mission.hashCode);
    _$hash = $jc(_$hash, reef.hashCode);
    _$hash = $jc(_$hash, serverTime.hashCode);
    _$hash = $jc(_$hash, state.hashCode);
    _$hash = $jc(_$hash, streakDays.hashCode);
    _$hash = $jc(_$hash, xpBalance.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'HomeResponse')
          ..add('mission', mission)
          ..add('reef', reef)
          ..add('serverTime', serverTime)
          ..add('state', state)
          ..add('streakDays', streakDays)
          ..add('xpBalance', xpBalance))
        .toString();
  }
}

class HomeResponseBuilder
    implements Builder<HomeResponse, HomeResponseBuilder> {
  _$HomeResponse? _$v;

  HomeMissionBuilder? _mission;
  HomeMissionBuilder get mission => _$this._mission ??= HomeMissionBuilder();
  set mission(HomeMissionBuilder? mission) => _$this._mission = mission;

  ReefSummaryBuilder? _reef;
  ReefSummaryBuilder get reef => _$this._reef ??= ReefSummaryBuilder();
  set reef(ReefSummaryBuilder? reef) => _$this._reef = reef;

  String? _serverTime;
  String? get serverTime => _$this._serverTime;
  set serverTime(String? serverTime) => _$this._serverTime = serverTime;

  HomeResponseStateEnum? _state;
  HomeResponseStateEnum? get state => _$this._state;
  set state(HomeResponseStateEnum? state) => _$this._state = state;

  int? _streakDays;
  int? get streakDays => _$this._streakDays;
  set streakDays(int? streakDays) => _$this._streakDays = streakDays;

  int? _xpBalance;
  int? get xpBalance => _$this._xpBalance;
  set xpBalance(int? xpBalance) => _$this._xpBalance = xpBalance;

  HomeResponseBuilder() {
    HomeResponse._defaults(this);
  }

  HomeResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mission = $v.mission?.toBuilder();
      _reef = $v.reef?.toBuilder();
      _serverTime = $v.serverTime;
      _state = $v.state;
      _streakDays = $v.streakDays;
      _xpBalance = $v.xpBalance;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(HomeResponse other) {
    _$v = other as _$HomeResponse;
  }

  @override
  void update(void Function(HomeResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  HomeResponse build() => _build();

  _$HomeResponse _build() {
    _$HomeResponse _$result;
    try {
      _$result = _$v ??
          _$HomeResponse._(
            mission: _mission?.build(),
            reef: _reef?.build(),
            serverTime: BuiltValueNullFieldError.checkNotNull(
                serverTime, r'HomeResponse', 'serverTime'),
            state: BuiltValueNullFieldError.checkNotNull(
                state, r'HomeResponse', 'state'),
            streakDays: BuiltValueNullFieldError.checkNotNull(
                streakDays, r'HomeResponse', 'streakDays'),
            xpBalance: BuiltValueNullFieldError.checkNotNull(
                xpBalance, r'HomeResponse', 'xpBalance'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'mission';
        _mission?.build();
        _$failedField = 'reef';
        _reef?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'HomeResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
