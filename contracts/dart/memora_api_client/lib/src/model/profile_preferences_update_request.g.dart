// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_preferences_update_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProfilePreferencesUpdateRequest
    extends ProfilePreferencesUpdateRequest {
  @override
  final Optional<AccessibilityPreferences?> accessibility;
  @override
  final Optional<String?> lockScreenDetail;
  @override
  final Optional<int?> maxDailyReminders;
  @override
  final Optional<bool?> missionEnabled;
  @override
  final Optional<bool?> notificationsEnabled;
  @override
  final Optional<String?> preferredWindowEndLocal;
  @override
  final Optional<String?> preferredWindowStartLocal;
  @override
  final Optional<String?> quietEndLocal;
  @override
  final Optional<String?> quietStartLocal;
  @override
  final Optional<bool?> rewardEnabled;
  @override
  final Optional<bool?> streakEnabled;
  @override
  final Optional<String?> timezone;
  @override
  final int version;

  factory _$ProfilePreferencesUpdateRequest(
          [void Function(ProfilePreferencesUpdateRequestBuilder)? updates]) =>
      (ProfilePreferencesUpdateRequestBuilder()..update(updates))._build();

  _$ProfilePreferencesUpdateRequest._(
      {required this.accessibility,
      required this.lockScreenDetail,
      required this.maxDailyReminders,
      required this.missionEnabled,
      required this.notificationsEnabled,
      required this.preferredWindowEndLocal,
      required this.preferredWindowStartLocal,
      required this.quietEndLocal,
      required this.quietStartLocal,
      required this.rewardEnabled,
      required this.streakEnabled,
      required this.timezone,
      required this.version})
      : super._();
  @override
  ProfilePreferencesUpdateRequest rebuild(
          void Function(ProfilePreferencesUpdateRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProfilePreferencesUpdateRequestBuilder toBuilder() =>
      ProfilePreferencesUpdateRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProfilePreferencesUpdateRequest &&
        accessibility == other.accessibility &&
        lockScreenDetail == other.lockScreenDetail &&
        maxDailyReminders == other.maxDailyReminders &&
        missionEnabled == other.missionEnabled &&
        notificationsEnabled == other.notificationsEnabled &&
        preferredWindowEndLocal == other.preferredWindowEndLocal &&
        preferredWindowStartLocal == other.preferredWindowStartLocal &&
        quietEndLocal == other.quietEndLocal &&
        quietStartLocal == other.quietStartLocal &&
        rewardEnabled == other.rewardEnabled &&
        streakEnabled == other.streakEnabled &&
        timezone == other.timezone &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accessibility.hashCode);
    _$hash = $jc(_$hash, lockScreenDetail.hashCode);
    _$hash = $jc(_$hash, maxDailyReminders.hashCode);
    _$hash = $jc(_$hash, missionEnabled.hashCode);
    _$hash = $jc(_$hash, notificationsEnabled.hashCode);
    _$hash = $jc(_$hash, preferredWindowEndLocal.hashCode);
    _$hash = $jc(_$hash, preferredWindowStartLocal.hashCode);
    _$hash = $jc(_$hash, quietEndLocal.hashCode);
    _$hash = $jc(_$hash, quietStartLocal.hashCode);
    _$hash = $jc(_$hash, rewardEnabled.hashCode);
    _$hash = $jc(_$hash, streakEnabled.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProfilePreferencesUpdateRequest')
          ..add('accessibility', accessibility)
          ..add('lockScreenDetail', lockScreenDetail)
          ..add('maxDailyReminders', maxDailyReminders)
          ..add('missionEnabled', missionEnabled)
          ..add('notificationsEnabled', notificationsEnabled)
          ..add('preferredWindowEndLocal', preferredWindowEndLocal)
          ..add('preferredWindowStartLocal', preferredWindowStartLocal)
          ..add('quietEndLocal', quietEndLocal)
          ..add('quietStartLocal', quietStartLocal)
          ..add('rewardEnabled', rewardEnabled)
          ..add('streakEnabled', streakEnabled)
          ..add('timezone', timezone)
          ..add('version', version))
        .toString();
  }
}

class ProfilePreferencesUpdateRequestBuilder
    implements
        Builder<ProfilePreferencesUpdateRequest,
            ProfilePreferencesUpdateRequestBuilder> {
  _$ProfilePreferencesUpdateRequest? _$v;

  Optional<AccessibilityPreferences?>? _accessibility;
  Optional<AccessibilityPreferences?>? get accessibility =>
      _$this._accessibility;
  set accessibility(Optional<AccessibilityPreferences?>? accessibility) =>
      _$this._accessibility = accessibility;

  Optional<String?>? _lockScreenDetail;
  Optional<String?>? get lockScreenDetail => _$this._lockScreenDetail;
  set lockScreenDetail(Optional<String?>? lockScreenDetail) =>
      _$this._lockScreenDetail = lockScreenDetail;

  Optional<int?>? _maxDailyReminders;
  Optional<int?>? get maxDailyReminders => _$this._maxDailyReminders;
  set maxDailyReminders(Optional<int?>? maxDailyReminders) =>
      _$this._maxDailyReminders = maxDailyReminders;

  Optional<bool?>? _missionEnabled;
  Optional<bool?>? get missionEnabled => _$this._missionEnabled;
  set missionEnabled(Optional<bool?>? missionEnabled) =>
      _$this._missionEnabled = missionEnabled;

  Optional<bool?>? _notificationsEnabled;
  Optional<bool?>? get notificationsEnabled => _$this._notificationsEnabled;
  set notificationsEnabled(Optional<bool?>? notificationsEnabled) =>
      _$this._notificationsEnabled = notificationsEnabled;

  Optional<String?>? _preferredWindowEndLocal;
  Optional<String?>? get preferredWindowEndLocal =>
      _$this._preferredWindowEndLocal;
  set preferredWindowEndLocal(Optional<String?>? preferredWindowEndLocal) =>
      _$this._preferredWindowEndLocal = preferredWindowEndLocal;

  Optional<String?>? _preferredWindowStartLocal;
  Optional<String?>? get preferredWindowStartLocal =>
      _$this._preferredWindowStartLocal;
  set preferredWindowStartLocal(Optional<String?>? preferredWindowStartLocal) =>
      _$this._preferredWindowStartLocal = preferredWindowStartLocal;

  Optional<String?>? _quietEndLocal;
  Optional<String?>? get quietEndLocal => _$this._quietEndLocal;
  set quietEndLocal(Optional<String?>? quietEndLocal) =>
      _$this._quietEndLocal = quietEndLocal;

  Optional<String?>? _quietStartLocal;
  Optional<String?>? get quietStartLocal => _$this._quietStartLocal;
  set quietStartLocal(Optional<String?>? quietStartLocal) =>
      _$this._quietStartLocal = quietStartLocal;

  Optional<bool?>? _rewardEnabled;
  Optional<bool?>? get rewardEnabled => _$this._rewardEnabled;
  set rewardEnabled(Optional<bool?>? rewardEnabled) =>
      _$this._rewardEnabled = rewardEnabled;

  Optional<bool?>? _streakEnabled;
  Optional<bool?>? get streakEnabled => _$this._streakEnabled;
  set streakEnabled(Optional<bool?>? streakEnabled) =>
      _$this._streakEnabled = streakEnabled;

  Optional<String?>? _timezone;
  Optional<String?>? get timezone => _$this._timezone;
  set timezone(Optional<String?>? timezone) => _$this._timezone = timezone;

  int? _version;
  int? get version => _$this._version;
  set version(int? version) => _$this._version = version;

  ProfilePreferencesUpdateRequestBuilder() {
    ProfilePreferencesUpdateRequest._defaults(this);
  }

  ProfilePreferencesUpdateRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accessibility = $v.accessibility;
      _lockScreenDetail = $v.lockScreenDetail;
      _maxDailyReminders = $v.maxDailyReminders;
      _missionEnabled = $v.missionEnabled;
      _notificationsEnabled = $v.notificationsEnabled;
      _preferredWindowEndLocal = $v.preferredWindowEndLocal;
      _preferredWindowStartLocal = $v.preferredWindowStartLocal;
      _quietEndLocal = $v.quietEndLocal;
      _quietStartLocal = $v.quietStartLocal;
      _rewardEnabled = $v.rewardEnabled;
      _streakEnabled = $v.streakEnabled;
      _timezone = $v.timezone;
      _version = $v.version;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProfilePreferencesUpdateRequest other) {
    _$v = other as _$ProfilePreferencesUpdateRequest;
  }

  @override
  void update(void Function(ProfilePreferencesUpdateRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProfilePreferencesUpdateRequest build() => _build();

  _$ProfilePreferencesUpdateRequest _build() {
    final _$result = _$v ??
        _$ProfilePreferencesUpdateRequest._(
          accessibility: BuiltValueNullFieldError.checkNotNull(accessibility,
              r'ProfilePreferencesUpdateRequest', 'accessibility'),
          lockScreenDetail: BuiltValueNullFieldError.checkNotNull(
              lockScreenDetail,
              r'ProfilePreferencesUpdateRequest',
              'lockScreenDetail'),
          maxDailyReminders: BuiltValueNullFieldError.checkNotNull(
              maxDailyReminders,
              r'ProfilePreferencesUpdateRequest',
              'maxDailyReminders'),
          missionEnabled: BuiltValueNullFieldError.checkNotNull(missionEnabled,
              r'ProfilePreferencesUpdateRequest', 'missionEnabled'),
          notificationsEnabled: BuiltValueNullFieldError.checkNotNull(
              notificationsEnabled,
              r'ProfilePreferencesUpdateRequest',
              'notificationsEnabled'),
          preferredWindowEndLocal: BuiltValueNullFieldError.checkNotNull(
              preferredWindowEndLocal,
              r'ProfilePreferencesUpdateRequest',
              'preferredWindowEndLocal'),
          preferredWindowStartLocal: BuiltValueNullFieldError.checkNotNull(
              preferredWindowStartLocal,
              r'ProfilePreferencesUpdateRequest',
              'preferredWindowStartLocal'),
          quietEndLocal: BuiltValueNullFieldError.checkNotNull(quietEndLocal,
              r'ProfilePreferencesUpdateRequest', 'quietEndLocal'),
          quietStartLocal: BuiltValueNullFieldError.checkNotNull(
              quietStartLocal,
              r'ProfilePreferencesUpdateRequest',
              'quietStartLocal'),
          rewardEnabled: BuiltValueNullFieldError.checkNotNull(rewardEnabled,
              r'ProfilePreferencesUpdateRequest', 'rewardEnabled'),
          streakEnabled: BuiltValueNullFieldError.checkNotNull(streakEnabled,
              r'ProfilePreferencesUpdateRequest', 'streakEnabled'),
          timezone: BuiltValueNullFieldError.checkNotNull(
              timezone, r'ProfilePreferencesUpdateRequest', 'timezone'),
          version: BuiltValueNullFieldError.checkNotNull(
              version, r'ProfilePreferencesUpdateRequest', 'version'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
