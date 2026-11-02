// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProfileResponse extends ProfileResponse {
  @override
  final String? activeSubjectId;
  @override
  final String? curriculumVersionId;
  @override
  final String displayName;
  @override
  final String locale;
  @override
  final String timezone;
  @override
  final String userId;
  @override
  final int version;

  factory _$ProfileResponse([void Function(ProfileResponseBuilder)? updates]) =>
      (ProfileResponseBuilder()..update(updates))._build();

  _$ProfileResponse._(
      {this.activeSubjectId,
      this.curriculumVersionId,
      required this.displayName,
      required this.locale,
      required this.timezone,
      required this.userId,
      required this.version})
      : super._();
  @override
  ProfileResponse rebuild(void Function(ProfileResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProfileResponseBuilder toBuilder() => ProfileResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProfileResponse &&
        activeSubjectId == other.activeSubjectId &&
        curriculumVersionId == other.curriculumVersionId &&
        displayName == other.displayName &&
        locale == other.locale &&
        timezone == other.timezone &&
        userId == other.userId &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, activeSubjectId.hashCode);
    _$hash = $jc(_$hash, curriculumVersionId.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProfileResponse')
          ..add('activeSubjectId', activeSubjectId)
          ..add('curriculumVersionId', curriculumVersionId)
          ..add('displayName', displayName)
          ..add('locale', locale)
          ..add('timezone', timezone)
          ..add('userId', userId)
          ..add('version', version))
        .toString();
  }
}

class ProfileResponseBuilder
    implements Builder<ProfileResponse, ProfileResponseBuilder> {
  _$ProfileResponse? _$v;

  String? _activeSubjectId;
  String? get activeSubjectId => _$this._activeSubjectId;
  set activeSubjectId(String? activeSubjectId) =>
      _$this._activeSubjectId = activeSubjectId;

  String? _curriculumVersionId;
  String? get curriculumVersionId => _$this._curriculumVersionId;
  set curriculumVersionId(String? curriculumVersionId) =>
      _$this._curriculumVersionId = curriculumVersionId;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  String? _locale;
  String? get locale => _$this._locale;
  set locale(String? locale) => _$this._locale = locale;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(String? timezone) => _$this._timezone = timezone;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  int? _version;
  int? get version => _$this._version;
  set version(int? version) => _$this._version = version;

  ProfileResponseBuilder() {
    ProfileResponse._defaults(this);
  }

  ProfileResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _activeSubjectId = $v.activeSubjectId;
      _curriculumVersionId = $v.curriculumVersionId;
      _displayName = $v.displayName;
      _locale = $v.locale;
      _timezone = $v.timezone;
      _userId = $v.userId;
      _version = $v.version;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProfileResponse other) {
    _$v = other as _$ProfileResponse;
  }

  @override
  void update(void Function(ProfileResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProfileResponse build() => _build();

  _$ProfileResponse _build() {
    final _$result = _$v ??
        _$ProfileResponse._(
          activeSubjectId: activeSubjectId,
          curriculumVersionId: curriculumVersionId,
          displayName: BuiltValueNullFieldError.checkNotNull(
              displayName, r'ProfileResponse', 'displayName'),
          locale: BuiltValueNullFieldError.checkNotNull(
              locale, r'ProfileResponse', 'locale'),
          timezone: BuiltValueNullFieldError.checkNotNull(
              timezone, r'ProfileResponse', 'timezone'),
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'ProfileResponse', 'userId'),
          version: BuiltValueNullFieldError.checkNotNull(
              version, r'ProfileResponse', 'version'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
