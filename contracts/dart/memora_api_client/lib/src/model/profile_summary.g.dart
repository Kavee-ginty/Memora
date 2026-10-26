// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_summary.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProfileSummary extends ProfileSummary {
  @override
  final String? activeSubjectId;
  @override
  final String? curriculumVersionId;
  @override
  final String displayName;
  @override
  final bool onboardingCompleted;
  @override
  final String userId;

  factory _$ProfileSummary([void Function(ProfileSummaryBuilder)? updates]) =>
      (ProfileSummaryBuilder()..update(updates))._build();

  _$ProfileSummary._(
      {this.activeSubjectId,
      this.curriculumVersionId,
      required this.displayName,
      required this.onboardingCompleted,
      required this.userId})
      : super._();
  @override
  ProfileSummary rebuild(void Function(ProfileSummaryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProfileSummaryBuilder toBuilder() => ProfileSummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProfileSummary &&
        activeSubjectId == other.activeSubjectId &&
        curriculumVersionId == other.curriculumVersionId &&
        displayName == other.displayName &&
        onboardingCompleted == other.onboardingCompleted &&
        userId == other.userId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, activeSubjectId.hashCode);
    _$hash = $jc(_$hash, curriculumVersionId.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, onboardingCompleted.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProfileSummary')
          ..add('activeSubjectId', activeSubjectId)
          ..add('curriculumVersionId', curriculumVersionId)
          ..add('displayName', displayName)
          ..add('onboardingCompleted', onboardingCompleted)
          ..add('userId', userId))
        .toString();
  }
}

class ProfileSummaryBuilder
    implements Builder<ProfileSummary, ProfileSummaryBuilder> {
  _$ProfileSummary? _$v;

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

  bool? _onboardingCompleted;
  bool? get onboardingCompleted => _$this._onboardingCompleted;
  set onboardingCompleted(bool? onboardingCompleted) =>
      _$this._onboardingCompleted = onboardingCompleted;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  ProfileSummaryBuilder() {
    ProfileSummary._defaults(this);
  }

  ProfileSummaryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _activeSubjectId = $v.activeSubjectId;
      _curriculumVersionId = $v.curriculumVersionId;
      _displayName = $v.displayName;
      _onboardingCompleted = $v.onboardingCompleted;
      _userId = $v.userId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProfileSummary other) {
    _$v = other as _$ProfileSummary;
  }

  @override
  void update(void Function(ProfileSummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProfileSummary build() => _build();

  _$ProfileSummary _build() {
    final _$result = _$v ??
        _$ProfileSummary._(
          activeSubjectId: activeSubjectId,
          curriculumVersionId: curriculumVersionId,
          displayName: BuiltValueNullFieldError.checkNotNull(
              displayName, r'ProfileSummary', 'displayName'),
          onboardingCompleted: BuiltValueNullFieldError.checkNotNull(
              onboardingCompleted, r'ProfileSummary', 'onboardingCompleted'),
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'ProfileSummary', 'userId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
