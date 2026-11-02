// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_preferences_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ProfilePreferencesResponseLockScreenDetailEnum
    _$profilePreferencesResponseLockScreenDetailEnum_minimal =
    const ProfilePreferencesResponseLockScreenDetailEnum._('minimal');
const ProfilePreferencesResponseLockScreenDetailEnum
    _$profilePreferencesResponseLockScreenDetailEnum_subject =
    const ProfilePreferencesResponseLockScreenDetailEnum._('subject');
const ProfilePreferencesResponseLockScreenDetailEnum
    _$profilePreferencesResponseLockScreenDetailEnum_detailed =
    const ProfilePreferencesResponseLockScreenDetailEnum._('detailed');
const ProfilePreferencesResponseLockScreenDetailEnum
    _$profilePreferencesResponseLockScreenDetailEnum_unknownDefaultOpenApi =
    const ProfilePreferencesResponseLockScreenDetailEnum._(
        'unknownDefaultOpenApi');

ProfilePreferencesResponseLockScreenDetailEnum
    _$profilePreferencesResponseLockScreenDetailEnumValueOf(String name) {
  switch (name) {
    case 'minimal':
      return _$profilePreferencesResponseLockScreenDetailEnum_minimal;
    case 'subject':
      return _$profilePreferencesResponseLockScreenDetailEnum_subject;
    case 'detailed':
      return _$profilePreferencesResponseLockScreenDetailEnum_detailed;
    case 'unknownDefaultOpenApi':
      return _$profilePreferencesResponseLockScreenDetailEnum_unknownDefaultOpenApi;
    default:
      return _$profilePreferencesResponseLockScreenDetailEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<ProfilePreferencesResponseLockScreenDetailEnum>
    _$profilePreferencesResponseLockScreenDetailEnumValues = BuiltSet<
        ProfilePreferencesResponseLockScreenDetailEnum>(const <ProfilePreferencesResponseLockScreenDetailEnum>[
  _$profilePreferencesResponseLockScreenDetailEnum_minimal,
  _$profilePreferencesResponseLockScreenDetailEnum_subject,
  _$profilePreferencesResponseLockScreenDetailEnum_detailed,
  _$profilePreferencesResponseLockScreenDetailEnum_unknownDefaultOpenApi,
]);

Serializer<ProfilePreferencesResponseLockScreenDetailEnum>
    _$profilePreferencesResponseLockScreenDetailEnumSerializer =
    _$ProfilePreferencesResponseLockScreenDetailEnumSerializer();

class _$ProfilePreferencesResponseLockScreenDetailEnumSerializer
    implements
        PrimitiveSerializer<ProfilePreferencesResponseLockScreenDetailEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'minimal': 'minimal',
    'subject': 'subject',
    'detailed': 'detailed',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'minimal': 'minimal',
    'subject': 'subject',
    'detailed': 'detailed',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    ProfilePreferencesResponseLockScreenDetailEnum
  ];
  @override
  final String wireName = 'ProfilePreferencesResponseLockScreenDetailEnum';

  @override
  Object serialize(Serializers serializers,
          ProfilePreferencesResponseLockScreenDetailEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ProfilePreferencesResponseLockScreenDetailEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ProfilePreferencesResponseLockScreenDetailEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ProfilePreferencesResponse extends ProfilePreferencesResponse {
  @override
  final AccessibilityPreferences accessibility;
  @override
  final ProfilePreferencesResponseLockScreenDetailEnum lockScreenDetail;
  @override
  final int maxDailyReminders;
  @override
  final bool missionEnabled;
  @override
  final bool notificationsEnabled;
  @override
  final String? preferredWindowEndLocal;
  @override
  final String? preferredWindowStartLocal;
  @override
  final String? quietEndLocal;
  @override
  final String? quietStartLocal;
  @override
  final bool rewardEnabled;
  @override
  final bool streakEnabled;
  @override
  final String timezone;
  @override
  final int version;

  factory _$ProfilePreferencesResponse(
          [void Function(ProfilePreferencesResponseBuilder)? updates]) =>
      (ProfilePreferencesResponseBuilder()..update(updates))._build();

  _$ProfilePreferencesResponse._(
      {required this.accessibility,
      required this.lockScreenDetail,
      required this.maxDailyReminders,
      required this.missionEnabled,
      required this.notificationsEnabled,
      this.preferredWindowEndLocal,
      this.preferredWindowStartLocal,
      this.quietEndLocal,
      this.quietStartLocal,
      required this.rewardEnabled,
      required this.streakEnabled,
      required this.timezone,
      required this.version})
      : super._();
  @override
  ProfilePreferencesResponse rebuild(
          void Function(ProfilePreferencesResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProfilePreferencesResponseBuilder toBuilder() =>
      ProfilePreferencesResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProfilePreferencesResponse &&
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
    return (newBuiltValueToStringHelper(r'ProfilePreferencesResponse')
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

class ProfilePreferencesResponseBuilder
    implements
        Builder<ProfilePreferencesResponse, ProfilePreferencesResponseBuilder> {
  _$ProfilePreferencesResponse? _$v;

  AccessibilityPreferencesBuilder? _accessibility;
  AccessibilityPreferencesBuilder get accessibility =>
      _$this._accessibility ??= AccessibilityPreferencesBuilder();
  set accessibility(AccessibilityPreferencesBuilder? accessibility) =>
      _$this._accessibility = accessibility;

  ProfilePreferencesResponseLockScreenDetailEnum? _lockScreenDetail;
  ProfilePreferencesResponseLockScreenDetailEnum? get lockScreenDetail =>
      _$this._lockScreenDetail;
  set lockScreenDetail(
          ProfilePreferencesResponseLockScreenDetailEnum? lockScreenDetail) =>
      _$this._lockScreenDetail = lockScreenDetail;

  int? _maxDailyReminders;
  int? get maxDailyReminders => _$this._maxDailyReminders;
  set maxDailyReminders(int? maxDailyReminders) =>
      _$this._maxDailyReminders = maxDailyReminders;

  bool? _missionEnabled;
  bool? get missionEnabled => _$this._missionEnabled;
  set missionEnabled(bool? missionEnabled) =>
      _$this._missionEnabled = missionEnabled;

  bool? _notificationsEnabled;
  bool? get notificationsEnabled => _$this._notificationsEnabled;
  set notificationsEnabled(bool? notificationsEnabled) =>
      _$this._notificationsEnabled = notificationsEnabled;

  String? _preferredWindowEndLocal;
  String? get preferredWindowEndLocal => _$this._preferredWindowEndLocal;
  set preferredWindowEndLocal(String? preferredWindowEndLocal) =>
      _$this._preferredWindowEndLocal = preferredWindowEndLocal;

  String? _preferredWindowStartLocal;
  String? get preferredWindowStartLocal => _$this._preferredWindowStartLocal;
  set preferredWindowStartLocal(String? preferredWindowStartLocal) =>
      _$this._preferredWindowStartLocal = preferredWindowStartLocal;

  String? _quietEndLocal;
  String? get quietEndLocal => _$this._quietEndLocal;
  set quietEndLocal(String? quietEndLocal) =>
      _$this._quietEndLocal = quietEndLocal;

  String? _quietStartLocal;
  String? get quietStartLocal => _$this._quietStartLocal;
  set quietStartLocal(String? quietStartLocal) =>
      _$this._quietStartLocal = quietStartLocal;

  bool? _rewardEnabled;
  bool? get rewardEnabled => _$this._rewardEnabled;
  set rewardEnabled(bool? rewardEnabled) =>
      _$this._rewardEnabled = rewardEnabled;

  bool? _streakEnabled;
  bool? get streakEnabled => _$this._streakEnabled;
  set streakEnabled(bool? streakEnabled) =>
      _$this._streakEnabled = streakEnabled;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(String? timezone) => _$this._timezone = timezone;

  int? _version;
  int? get version => _$this._version;
  set version(int? version) => _$this._version = version;

  ProfilePreferencesResponseBuilder() {
    ProfilePreferencesResponse._defaults(this);
  }

  ProfilePreferencesResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accessibility = $v.accessibility.toBuilder();
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
  void replace(ProfilePreferencesResponse other) {
    _$v = other as _$ProfilePreferencesResponse;
  }

  @override
  void update(void Function(ProfilePreferencesResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProfilePreferencesResponse build() => _build();

  _$ProfilePreferencesResponse _build() {
    _$ProfilePreferencesResponse _$result;
    try {
      _$result = _$v ??
          _$ProfilePreferencesResponse._(
            accessibility: accessibility.build(),
            lockScreenDetail: BuiltValueNullFieldError.checkNotNull(
                lockScreenDetail,
                r'ProfilePreferencesResponse',
                'lockScreenDetail'),
            maxDailyReminders: BuiltValueNullFieldError.checkNotNull(
                maxDailyReminders,
                r'ProfilePreferencesResponse',
                'maxDailyReminders'),
            missionEnabled: BuiltValueNullFieldError.checkNotNull(
                missionEnabled,
                r'ProfilePreferencesResponse',
                'missionEnabled'),
            notificationsEnabled: BuiltValueNullFieldError.checkNotNull(
                notificationsEnabled,
                r'ProfilePreferencesResponse',
                'notificationsEnabled'),
            preferredWindowEndLocal: preferredWindowEndLocal,
            preferredWindowStartLocal: preferredWindowStartLocal,
            quietEndLocal: quietEndLocal,
            quietStartLocal: quietStartLocal,
            rewardEnabled: BuiltValueNullFieldError.checkNotNull(
                rewardEnabled, r'ProfilePreferencesResponse', 'rewardEnabled'),
            streakEnabled: BuiltValueNullFieldError.checkNotNull(
                streakEnabled, r'ProfilePreferencesResponse', 'streakEnabled'),
            timezone: BuiltValueNullFieldError.checkNotNull(
                timezone, r'ProfilePreferencesResponse', 'timezone'),
            version: BuiltValueNullFieldError.checkNotNull(
                version, r'ProfilePreferencesResponse', 'version'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'accessibility';
        accessibility.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ProfilePreferencesResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
