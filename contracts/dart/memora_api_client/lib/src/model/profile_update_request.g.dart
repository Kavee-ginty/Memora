// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_update_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProfileUpdateRequest extends ProfileUpdateRequest {
  @override
  final Optional<String?> displayName;
  @override
  final Optional<String?> locale;
  @override
  final Optional<String?> timezone;
  @override
  final int version;

  factory _$ProfileUpdateRequest(
          [void Function(ProfileUpdateRequestBuilder)? updates]) =>
      (ProfileUpdateRequestBuilder()..update(updates))._build();

  _$ProfileUpdateRequest._(
      {required this.displayName,
      required this.locale,
      required this.timezone,
      required this.version})
      : super._();
  @override
  ProfileUpdateRequest rebuild(
          void Function(ProfileUpdateRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProfileUpdateRequestBuilder toBuilder() =>
      ProfileUpdateRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProfileUpdateRequest &&
        displayName == other.displayName &&
        locale == other.locale &&
        timezone == other.timezone &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProfileUpdateRequest')
          ..add('displayName', displayName)
          ..add('locale', locale)
          ..add('timezone', timezone)
          ..add('version', version))
        .toString();
  }
}

class ProfileUpdateRequestBuilder
    implements Builder<ProfileUpdateRequest, ProfileUpdateRequestBuilder> {
  _$ProfileUpdateRequest? _$v;

  Optional<String?>? _displayName;
  Optional<String?>? get displayName => _$this._displayName;
  set displayName(Optional<String?>? displayName) =>
      _$this._displayName = displayName;

  Optional<String?>? _locale;
  Optional<String?>? get locale => _$this._locale;
  set locale(Optional<String?>? locale) => _$this._locale = locale;

  Optional<String?>? _timezone;
  Optional<String?>? get timezone => _$this._timezone;
  set timezone(Optional<String?>? timezone) => _$this._timezone = timezone;

  int? _version;
  int? get version => _$this._version;
  set version(int? version) => _$this._version = version;

  ProfileUpdateRequestBuilder() {
    ProfileUpdateRequest._defaults(this);
  }

  ProfileUpdateRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _displayName = $v.displayName;
      _locale = $v.locale;
      _timezone = $v.timezone;
      _version = $v.version;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProfileUpdateRequest other) {
    _$v = other as _$ProfileUpdateRequest;
  }

  @override
  void update(void Function(ProfileUpdateRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProfileUpdateRequest build() => _build();

  _$ProfileUpdateRequest _build() {
    final _$result = _$v ??
        _$ProfileUpdateRequest._(
          displayName: BuiltValueNullFieldError.checkNotNull(
              displayName, r'ProfileUpdateRequest', 'displayName'),
          locale: BuiltValueNullFieldError.checkNotNull(
              locale, r'ProfileUpdateRequest', 'locale'),
          timezone: BuiltValueNullFieldError.checkNotNull(
              timezone, r'ProfileUpdateRequest', 'timezone'),
          version: BuiltValueNullFieldError.checkNotNull(
              version, r'ProfileUpdateRequest', 'version'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
