// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accessibility_preferences.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AccessibilityPreferences extends AccessibilityPreferences {
  @override
  final Optional<bool?> hapticsEnabled;
  @override
  final Optional<bool?> highContrast;
  @override
  final Optional<bool?> reducedMotion;
  @override
  final Optional<String?> schemaVersion;
  @override
  final Optional<bool?> soundEnabled;
  @override
  final Optional<bool?> timerVisible;

  factory _$AccessibilityPreferences(
          [void Function(AccessibilityPreferencesBuilder)? updates]) =>
      (AccessibilityPreferencesBuilder()..update(updates))._build();

  _$AccessibilityPreferences._(
      {required this.hapticsEnabled,
      required this.highContrast,
      required this.reducedMotion,
      required this.schemaVersion,
      required this.soundEnabled,
      required this.timerVisible})
      : super._();
  @override
  AccessibilityPreferences rebuild(
          void Function(AccessibilityPreferencesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AccessibilityPreferencesBuilder toBuilder() =>
      AccessibilityPreferencesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AccessibilityPreferences &&
        hapticsEnabled == other.hapticsEnabled &&
        highContrast == other.highContrast &&
        reducedMotion == other.reducedMotion &&
        schemaVersion == other.schemaVersion &&
        soundEnabled == other.soundEnabled &&
        timerVisible == other.timerVisible;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, hapticsEnabled.hashCode);
    _$hash = $jc(_$hash, highContrast.hashCode);
    _$hash = $jc(_$hash, reducedMotion.hashCode);
    _$hash = $jc(_$hash, schemaVersion.hashCode);
    _$hash = $jc(_$hash, soundEnabled.hashCode);
    _$hash = $jc(_$hash, timerVisible.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AccessibilityPreferences')
          ..add('hapticsEnabled', hapticsEnabled)
          ..add('highContrast', highContrast)
          ..add('reducedMotion', reducedMotion)
          ..add('schemaVersion', schemaVersion)
          ..add('soundEnabled', soundEnabled)
          ..add('timerVisible', timerVisible))
        .toString();
  }
}

class AccessibilityPreferencesBuilder
    implements
        Builder<AccessibilityPreferences, AccessibilityPreferencesBuilder> {
  _$AccessibilityPreferences? _$v;

  Optional<bool?>? _hapticsEnabled;
  Optional<bool?>? get hapticsEnabled => _$this._hapticsEnabled;
  set hapticsEnabled(Optional<bool?>? hapticsEnabled) =>
      _$this._hapticsEnabled = hapticsEnabled;

  Optional<bool?>? _highContrast;
  Optional<bool?>? get highContrast => _$this._highContrast;
  set highContrast(Optional<bool?>? highContrast) =>
      _$this._highContrast = highContrast;

  Optional<bool?>? _reducedMotion;
  Optional<bool?>? get reducedMotion => _$this._reducedMotion;
  set reducedMotion(Optional<bool?>? reducedMotion) =>
      _$this._reducedMotion = reducedMotion;

  Optional<String?>? _schemaVersion;
  Optional<String?>? get schemaVersion => _$this._schemaVersion;
  set schemaVersion(Optional<String?>? schemaVersion) =>
      _$this._schemaVersion = schemaVersion;

  Optional<bool?>? _soundEnabled;
  Optional<bool?>? get soundEnabled => _$this._soundEnabled;
  set soundEnabled(Optional<bool?>? soundEnabled) =>
      _$this._soundEnabled = soundEnabled;

  Optional<bool?>? _timerVisible;
  Optional<bool?>? get timerVisible => _$this._timerVisible;
  set timerVisible(Optional<bool?>? timerVisible) =>
      _$this._timerVisible = timerVisible;

  AccessibilityPreferencesBuilder() {
    AccessibilityPreferences._defaults(this);
  }

  AccessibilityPreferencesBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _hapticsEnabled = $v.hapticsEnabled;
      _highContrast = $v.highContrast;
      _reducedMotion = $v.reducedMotion;
      _schemaVersion = $v.schemaVersion;
      _soundEnabled = $v.soundEnabled;
      _timerVisible = $v.timerVisible;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AccessibilityPreferences other) {
    _$v = other as _$AccessibilityPreferences;
  }

  @override
  void update(void Function(AccessibilityPreferencesBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AccessibilityPreferences build() => _build();

  _$AccessibilityPreferences _build() {
    final _$result = _$v ??
        _$AccessibilityPreferences._(
          hapticsEnabled: BuiltValueNullFieldError.checkNotNull(
              hapticsEnabled, r'AccessibilityPreferences', 'hapticsEnabled'),
          highContrast: BuiltValueNullFieldError.checkNotNull(
              highContrast, r'AccessibilityPreferences', 'highContrast'),
          reducedMotion: BuiltValueNullFieldError.checkNotNull(
              reducedMotion, r'AccessibilityPreferences', 'reducedMotion'),
          schemaVersion: BuiltValueNullFieldError.checkNotNull(
              schemaVersion, r'AccessibilityPreferences', 'schemaVersion'),
          soundEnabled: BuiltValueNullFieldError.checkNotNull(
              soundEnabled, r'AccessibilityPreferences', 'soundEnabled'),
          timerVisible: BuiltValueNullFieldError.checkNotNull(
              timerVisible, r'AccessibilityPreferences', 'timerVisible'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
