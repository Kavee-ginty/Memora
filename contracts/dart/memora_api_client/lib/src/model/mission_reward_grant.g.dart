// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_reward_grant.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MissionRewardGrant extends MissionRewardGrant {
  @override
  final String grantId;
  @override
  final String rewardCode;

  factory _$MissionRewardGrant(
          [void Function(MissionRewardGrantBuilder)? updates]) =>
      (MissionRewardGrantBuilder()..update(updates))._build();

  _$MissionRewardGrant._({required this.grantId, required this.rewardCode})
      : super._();
  @override
  MissionRewardGrant rebuild(
          void Function(MissionRewardGrantBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MissionRewardGrantBuilder toBuilder() =>
      MissionRewardGrantBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MissionRewardGrant &&
        grantId == other.grantId &&
        rewardCode == other.rewardCode;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, grantId.hashCode);
    _$hash = $jc(_$hash, rewardCode.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MissionRewardGrant')
          ..add('grantId', grantId)
          ..add('rewardCode', rewardCode))
        .toString();
  }
}

class MissionRewardGrantBuilder
    implements Builder<MissionRewardGrant, MissionRewardGrantBuilder> {
  _$MissionRewardGrant? _$v;

  String? _grantId;
  String? get grantId => _$this._grantId;
  set grantId(String? grantId) => _$this._grantId = grantId;

  String? _rewardCode;
  String? get rewardCode => _$this._rewardCode;
  set rewardCode(String? rewardCode) => _$this._rewardCode = rewardCode;

  MissionRewardGrantBuilder() {
    MissionRewardGrant._defaults(this);
  }

  MissionRewardGrantBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _grantId = $v.grantId;
      _rewardCode = $v.rewardCode;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MissionRewardGrant other) {
    _$v = other as _$MissionRewardGrant;
  }

  @override
  void update(void Function(MissionRewardGrantBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MissionRewardGrant build() => _build();

  _$MissionRewardGrant _build() {
    final _$result = _$v ??
        _$MissionRewardGrant._(
          grantId: BuiltValueNullFieldError.checkNotNull(
              grantId, r'MissionRewardGrant', 'grantId'),
          rewardCode: BuiltValueNullFieldError.checkNotNull(
              rewardCode, r'MissionRewardGrant', 'rewardCode'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
