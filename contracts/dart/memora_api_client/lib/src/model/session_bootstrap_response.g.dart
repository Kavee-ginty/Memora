// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_bootstrap_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SessionBootstrapResponse extends SessionBootstrapResponse {
  @override
  final AccountStatus accountStatus;
  @override
  final ActiveMissionSummary? activeMission;
  @override
  final CapabilityFlags capabilityFlags;
  @override
  final BuiltList<ConsentStatus> consentStatus;
  @override
  final BuiltList<PendingResourceSummary> pendingLearningUpdates;
  @override
  final BuiltList<PendingResourceSummary> pendingPrivacyRequests;
  @override
  final ProfileSummary profileSummary;
  @override
  final DateTime serverTime;
  @override
  final BuiltList<SubjectSummary> subjects;

  factory _$SessionBootstrapResponse(
          [void Function(SessionBootstrapResponseBuilder)? updates]) =>
      (SessionBootstrapResponseBuilder()..update(updates))._build();

  _$SessionBootstrapResponse._(
      {required this.accountStatus,
      this.activeMission,
      required this.capabilityFlags,
      required this.consentStatus,
      required this.pendingLearningUpdates,
      required this.pendingPrivacyRequests,
      required this.profileSummary,
      required this.serverTime,
      required this.subjects})
      : super._();
  @override
  SessionBootstrapResponse rebuild(
          void Function(SessionBootstrapResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SessionBootstrapResponseBuilder toBuilder() =>
      SessionBootstrapResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SessionBootstrapResponse &&
        accountStatus == other.accountStatus &&
        activeMission == other.activeMission &&
        capabilityFlags == other.capabilityFlags &&
        consentStatus == other.consentStatus &&
        pendingLearningUpdates == other.pendingLearningUpdates &&
        pendingPrivacyRequests == other.pendingPrivacyRequests &&
        profileSummary == other.profileSummary &&
        serverTime == other.serverTime &&
        subjects == other.subjects;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accountStatus.hashCode);
    _$hash = $jc(_$hash, activeMission.hashCode);
    _$hash = $jc(_$hash, capabilityFlags.hashCode);
    _$hash = $jc(_$hash, consentStatus.hashCode);
    _$hash = $jc(_$hash, pendingLearningUpdates.hashCode);
    _$hash = $jc(_$hash, pendingPrivacyRequests.hashCode);
    _$hash = $jc(_$hash, profileSummary.hashCode);
    _$hash = $jc(_$hash, serverTime.hashCode);
    _$hash = $jc(_$hash, subjects.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SessionBootstrapResponse')
          ..add('accountStatus', accountStatus)
          ..add('activeMission', activeMission)
          ..add('capabilityFlags', capabilityFlags)
          ..add('consentStatus', consentStatus)
          ..add('pendingLearningUpdates', pendingLearningUpdates)
          ..add('pendingPrivacyRequests', pendingPrivacyRequests)
          ..add('profileSummary', profileSummary)
          ..add('serverTime', serverTime)
          ..add('subjects', subjects))
        .toString();
  }
}

class SessionBootstrapResponseBuilder
    implements
        Builder<SessionBootstrapResponse, SessionBootstrapResponseBuilder> {
  _$SessionBootstrapResponse? _$v;

  AccountStatus? _accountStatus;
  AccountStatus? get accountStatus => _$this._accountStatus;
  set accountStatus(AccountStatus? accountStatus) =>
      _$this._accountStatus = accountStatus;

  ActiveMissionSummaryBuilder? _activeMission;
  ActiveMissionSummaryBuilder get activeMission =>
      _$this._activeMission ??= ActiveMissionSummaryBuilder();
  set activeMission(ActiveMissionSummaryBuilder? activeMission) =>
      _$this._activeMission = activeMission;

  CapabilityFlagsBuilder? _capabilityFlags;
  CapabilityFlagsBuilder get capabilityFlags =>
      _$this._capabilityFlags ??= CapabilityFlagsBuilder();
  set capabilityFlags(CapabilityFlagsBuilder? capabilityFlags) =>
      _$this._capabilityFlags = capabilityFlags;

  ListBuilder<ConsentStatus>? _consentStatus;
  ListBuilder<ConsentStatus> get consentStatus =>
      _$this._consentStatus ??= ListBuilder<ConsentStatus>();
  set consentStatus(ListBuilder<ConsentStatus>? consentStatus) =>
      _$this._consentStatus = consentStatus;

  ListBuilder<PendingResourceSummary>? _pendingLearningUpdates;
  ListBuilder<PendingResourceSummary> get pendingLearningUpdates =>
      _$this._pendingLearningUpdates ??= ListBuilder<PendingResourceSummary>();
  set pendingLearningUpdates(
          ListBuilder<PendingResourceSummary>? pendingLearningUpdates) =>
      _$this._pendingLearningUpdates = pendingLearningUpdates;

  ListBuilder<PendingResourceSummary>? _pendingPrivacyRequests;
  ListBuilder<PendingResourceSummary> get pendingPrivacyRequests =>
      _$this._pendingPrivacyRequests ??= ListBuilder<PendingResourceSummary>();
  set pendingPrivacyRequests(
          ListBuilder<PendingResourceSummary>? pendingPrivacyRequests) =>
      _$this._pendingPrivacyRequests = pendingPrivacyRequests;

  ProfileSummaryBuilder? _profileSummary;
  ProfileSummaryBuilder get profileSummary =>
      _$this._profileSummary ??= ProfileSummaryBuilder();
  set profileSummary(ProfileSummaryBuilder? profileSummary) =>
      _$this._profileSummary = profileSummary;

  DateTime? _serverTime;
  DateTime? get serverTime => _$this._serverTime;
  set serverTime(DateTime? serverTime) => _$this._serverTime = serverTime;

  ListBuilder<SubjectSummary>? _subjects;
  ListBuilder<SubjectSummary> get subjects =>
      _$this._subjects ??= ListBuilder<SubjectSummary>();
  set subjects(ListBuilder<SubjectSummary>? subjects) =>
      _$this._subjects = subjects;

  SessionBootstrapResponseBuilder() {
    SessionBootstrapResponse._defaults(this);
  }

  SessionBootstrapResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accountStatus = $v.accountStatus;
      _activeMission = $v.activeMission?.toBuilder();
      _capabilityFlags = $v.capabilityFlags.toBuilder();
      _consentStatus = $v.consentStatus.toBuilder();
      _pendingLearningUpdates = $v.pendingLearningUpdates.toBuilder();
      _pendingPrivacyRequests = $v.pendingPrivacyRequests.toBuilder();
      _profileSummary = $v.profileSummary.toBuilder();
      _serverTime = $v.serverTime;
      _subjects = $v.subjects.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SessionBootstrapResponse other) {
    _$v = other as _$SessionBootstrapResponse;
  }

  @override
  void update(void Function(SessionBootstrapResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SessionBootstrapResponse build() => _build();

  _$SessionBootstrapResponse _build() {
    _$SessionBootstrapResponse _$result;
    try {
      _$result = _$v ??
          _$SessionBootstrapResponse._(
            accountStatus: BuiltValueNullFieldError.checkNotNull(
                accountStatus, r'SessionBootstrapResponse', 'accountStatus'),
            activeMission: _activeMission?.build(),
            capabilityFlags: capabilityFlags.build(),
            consentStatus: consentStatus.build(),
            pendingLearningUpdates: pendingLearningUpdates.build(),
            pendingPrivacyRequests: pendingPrivacyRequests.build(),
            profileSummary: profileSummary.build(),
            serverTime: BuiltValueNullFieldError.checkNotNull(
                serverTime, r'SessionBootstrapResponse', 'serverTime'),
            subjects: subjects.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'activeMission';
        _activeMission?.build();
        _$failedField = 'capabilityFlags';
        capabilityFlags.build();
        _$failedField = 'consentStatus';
        consentStatus.build();
        _$failedField = 'pendingLearningUpdates';
        pendingLearningUpdates.build();
        _$failedField = 'pendingPrivacyRequests';
        pendingPrivacyRequests.build();
        _$failedField = 'profileSummary';
        profileSummary.build();

        _$failedField = 'subjects';
        subjects.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'SessionBootstrapResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
