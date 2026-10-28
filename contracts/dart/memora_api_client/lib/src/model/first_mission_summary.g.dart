// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'first_mission_summary.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FirstMissionSummary extends FirstMissionSummary {
  @override
  final String missionId;
  @override
  final String status;

  factory _$FirstMissionSummary(
          [void Function(FirstMissionSummaryBuilder)? updates]) =>
      (FirstMissionSummaryBuilder()..update(updates))._build();

  _$FirstMissionSummary._({required this.missionId, required this.status})
      : super._();
  @override
  FirstMissionSummary rebuild(
          void Function(FirstMissionSummaryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FirstMissionSummaryBuilder toBuilder() =>
      FirstMissionSummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FirstMissionSummary &&
        missionId == other.missionId &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, missionId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FirstMissionSummary')
          ..add('missionId', missionId)
          ..add('status', status))
        .toString();
  }
}

class FirstMissionSummaryBuilder
    implements Builder<FirstMissionSummary, FirstMissionSummaryBuilder> {
  _$FirstMissionSummary? _$v;

  String? _missionId;
  String? get missionId => _$this._missionId;
  set missionId(String? missionId) => _$this._missionId = missionId;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  FirstMissionSummaryBuilder() {
    FirstMissionSummary._defaults(this);
  }

  FirstMissionSummaryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _missionId = $v.missionId;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FirstMissionSummary other) {
    _$v = other as _$FirstMissionSummary;
  }

  @override
  void update(void Function(FirstMissionSummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FirstMissionSummary build() => _build();

  _$FirstMissionSummary _build() {
    final _$result = _$v ??
        _$FirstMissionSummary._(
          missionId: BuiltValueNullFieldError.checkNotNull(
              missionId, r'FirstMissionSummary', 'missionId'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'FirstMissionSummary', 'status'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
