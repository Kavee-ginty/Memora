// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_streak_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const MissionStreakResultQualificationEnum
    _$missionStreakResultQualificationEnum_missionCompleted =
    const MissionStreakResultQualificationEnum._('missionCompleted');
const MissionStreakResultQualificationEnum
    _$missionStreakResultQualificationEnum_comebackCompleted =
    const MissionStreakResultQualificationEnum._('comebackCompleted');
const MissionStreakResultQualificationEnum
    _$missionStreakResultQualificationEnum_unknownDefaultOpenApi =
    const MissionStreakResultQualificationEnum._('unknownDefaultOpenApi');

MissionStreakResultQualificationEnum
    _$missionStreakResultQualificationEnumValueOf(String name) {
  switch (name) {
    case 'missionCompleted':
      return _$missionStreakResultQualificationEnum_missionCompleted;
    case 'comebackCompleted':
      return _$missionStreakResultQualificationEnum_comebackCompleted;
    case 'unknownDefaultOpenApi':
      return _$missionStreakResultQualificationEnum_unknownDefaultOpenApi;
    default:
      return _$missionStreakResultQualificationEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<MissionStreakResultQualificationEnum>
    _$missionStreakResultQualificationEnumValues = BuiltSet<
        MissionStreakResultQualificationEnum>(const <MissionStreakResultQualificationEnum>[
  _$missionStreakResultQualificationEnum_missionCompleted,
  _$missionStreakResultQualificationEnum_comebackCompleted,
  _$missionStreakResultQualificationEnum_unknownDefaultOpenApi,
]);

Serializer<MissionStreakResultQualificationEnum>
    _$missionStreakResultQualificationEnumSerializer =
    _$MissionStreakResultQualificationEnumSerializer();

class _$MissionStreakResultQualificationEnumSerializer
    implements PrimitiveSerializer<MissionStreakResultQualificationEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'missionCompleted': 'mission_completed',
    'comebackCompleted': 'comeback_completed',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'mission_completed': 'missionCompleted',
    'comeback_completed': 'comebackCompleted',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    MissionStreakResultQualificationEnum
  ];
  @override
  final String wireName = 'MissionStreakResultQualificationEnum';

  @override
  Object serialize(
          Serializers serializers, MissionStreakResultQualificationEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  MissionStreakResultQualificationEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      MissionStreakResultQualificationEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$MissionStreakResult extends MissionStreakResult {
  @override
  final int currentDays;
  @override
  final bool graceUsed;
  @override
  final String policyVersion;
  @override
  final MissionStreakResultQualificationEnum qualification;

  factory _$MissionStreakResult(
          [void Function(MissionStreakResultBuilder)? updates]) =>
      (MissionStreakResultBuilder()..update(updates))._build();

  _$MissionStreakResult._(
      {required this.currentDays,
      required this.graceUsed,
      required this.policyVersion,
      required this.qualification})
      : super._();
  @override
  MissionStreakResult rebuild(
          void Function(MissionStreakResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MissionStreakResultBuilder toBuilder() =>
      MissionStreakResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MissionStreakResult &&
        currentDays == other.currentDays &&
        graceUsed == other.graceUsed &&
        policyVersion == other.policyVersion &&
        qualification == other.qualification;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, currentDays.hashCode);
    _$hash = $jc(_$hash, graceUsed.hashCode);
    _$hash = $jc(_$hash, policyVersion.hashCode);
    _$hash = $jc(_$hash, qualification.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MissionStreakResult')
          ..add('currentDays', currentDays)
          ..add('graceUsed', graceUsed)
          ..add('policyVersion', policyVersion)
          ..add('qualification', qualification))
        .toString();
  }
}

class MissionStreakResultBuilder
    implements Builder<MissionStreakResult, MissionStreakResultBuilder> {
  _$MissionStreakResult? _$v;

  int? _currentDays;
  int? get currentDays => _$this._currentDays;
  set currentDays(int? currentDays) => _$this._currentDays = currentDays;

  bool? _graceUsed;
  bool? get graceUsed => _$this._graceUsed;
  set graceUsed(bool? graceUsed) => _$this._graceUsed = graceUsed;

  String? _policyVersion;
  String? get policyVersion => _$this._policyVersion;
  set policyVersion(String? policyVersion) =>
      _$this._policyVersion = policyVersion;

  MissionStreakResultQualificationEnum? _qualification;
  MissionStreakResultQualificationEnum? get qualification =>
      _$this._qualification;
  set qualification(MissionStreakResultQualificationEnum? qualification) =>
      _$this._qualification = qualification;

  MissionStreakResultBuilder() {
    MissionStreakResult._defaults(this);
  }

  MissionStreakResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _currentDays = $v.currentDays;
      _graceUsed = $v.graceUsed;
      _policyVersion = $v.policyVersion;
      _qualification = $v.qualification;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MissionStreakResult other) {
    _$v = other as _$MissionStreakResult;
  }

  @override
  void update(void Function(MissionStreakResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MissionStreakResult build() => _build();

  _$MissionStreakResult _build() {
    final _$result = _$v ??
        _$MissionStreakResult._(
          currentDays: BuiltValueNullFieldError.checkNotNull(
              currentDays, r'MissionStreakResult', 'currentDays'),
          graceUsed: BuiltValueNullFieldError.checkNotNull(
              graceUsed, r'MissionStreakResult', 'graceUsed'),
          policyVersion: BuiltValueNullFieldError.checkNotNull(
              policyVersion, r'MissionStreakResult', 'policyVersion'),
          qualification: BuiltValueNullFieldError.checkNotNull(
              qualification, r'MissionStreakResult', 'qualification'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
