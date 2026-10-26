// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capability_flags.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CapabilityFlags extends CapabilityFlags {
  @override
  final bool canAddLearningMaterial;
  @override
  final Optional<bool?> canRegisterNotifications;
  @override
  final bool canStartMission;

  factory _$CapabilityFlags([void Function(CapabilityFlagsBuilder)? updates]) =>
      (CapabilityFlagsBuilder()..update(updates))._build();

  _$CapabilityFlags._(
      {required this.canAddLearningMaterial,
      required this.canRegisterNotifications,
      required this.canStartMission})
      : super._();
  @override
  CapabilityFlags rebuild(void Function(CapabilityFlagsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CapabilityFlagsBuilder toBuilder() => CapabilityFlagsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CapabilityFlags &&
        canAddLearningMaterial == other.canAddLearningMaterial &&
        canRegisterNotifications == other.canRegisterNotifications &&
        canStartMission == other.canStartMission;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, canAddLearningMaterial.hashCode);
    _$hash = $jc(_$hash, canRegisterNotifications.hashCode);
    _$hash = $jc(_$hash, canStartMission.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CapabilityFlags')
          ..add('canAddLearningMaterial', canAddLearningMaterial)
          ..add('canRegisterNotifications', canRegisterNotifications)
          ..add('canStartMission', canStartMission))
        .toString();
  }
}

class CapabilityFlagsBuilder
    implements Builder<CapabilityFlags, CapabilityFlagsBuilder> {
  _$CapabilityFlags? _$v;

  bool? _canAddLearningMaterial;
  bool? get canAddLearningMaterial => _$this._canAddLearningMaterial;
  set canAddLearningMaterial(bool? canAddLearningMaterial) =>
      _$this._canAddLearningMaterial = canAddLearningMaterial;

  Optional<bool?>? _canRegisterNotifications;
  Optional<bool?>? get canRegisterNotifications =>
      _$this._canRegisterNotifications;
  set canRegisterNotifications(Optional<bool?>? canRegisterNotifications) =>
      _$this._canRegisterNotifications = canRegisterNotifications;

  bool? _canStartMission;
  bool? get canStartMission => _$this._canStartMission;
  set canStartMission(bool? canStartMission) =>
      _$this._canStartMission = canStartMission;

  CapabilityFlagsBuilder() {
    CapabilityFlags._defaults(this);
  }

  CapabilityFlagsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _canAddLearningMaterial = $v.canAddLearningMaterial;
      _canRegisterNotifications = $v.canRegisterNotifications;
      _canStartMission = $v.canStartMission;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CapabilityFlags other) {
    _$v = other as _$CapabilityFlags;
  }

  @override
  void update(void Function(CapabilityFlagsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CapabilityFlags build() => _build();

  _$CapabilityFlags _build() {
    final _$result = _$v ??
        _$CapabilityFlags._(
          canAddLearningMaterial: BuiltValueNullFieldError.checkNotNull(
              canAddLearningMaterial,
              r'CapabilityFlags',
              'canAddLearningMaterial'),
          canRegisterNotifications: BuiltValueNullFieldError.checkNotNull(
              canRegisterNotifications,
              r'CapabilityFlags',
              'canRegisterNotifications'),
          canStartMission: BuiltValueNullFieldError.checkNotNull(
              canStartMission, r'CapabilityFlags', 'canStartMission'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
