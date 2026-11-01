import 'package:flutter/foundation.dart';

/// Account status domain model.
enum AccountStatusDomain {
  active,
  suspended,
  deletionPending,
  deleted,
  unknown;

  bool get canAccessApp => this == AccountStatusDomain.active;
  bool get isBlocked =>
      this == AccountStatusDomain.suspended ||
      this == AccountStatusDomain.deletionPending ||
      this == AccountStatusDomain.deleted ||
      this == AccountStatusDomain.unknown;
}

/// Profile summary domain model.
@immutable
class ProfileSummaryDomain {
  final String userId;
  final String displayName;
  final bool onboardingCompleted;
  final String? activeSubjectId;
  final String? curriculumVersionId;
  final String email;
  final int streakDays;

  const ProfileSummaryDomain({
    required this.userId,
    required this.displayName,
    this.onboardingCompleted = false,
    this.activeSubjectId,
    this.curriculumVersionId,
    this.email = '',
    this.streakDays = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileSummaryDomain &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          displayName == other.displayName &&
          onboardingCompleted == other.onboardingCompleted &&
          activeSubjectId == other.activeSubjectId &&
          curriculumVersionId == other.curriculumVersionId &&
          email == other.email &&
          streakDays == other.streakDays;

  @override
  int get hashCode => Object.hash(
    userId,
    displayName,
    onboardingCompleted,
    activeSubjectId,
    curriculumVersionId,
    email,
    streakDays,
  );
}

/// Consent decision domain model.
@immutable
class ConsentDecisionDomain {
  final String policyId;
  final String policyVersion;
  final String? decision;
  final bool isCurrent;
  final bool isRequired;
  final DateTime? decidedAt;

  const ConsentDecisionDomain({
    required this.policyId,
    required this.policyVersion,
    this.decision,
    required this.isCurrent,
    required this.isRequired,
    this.decidedAt,
  });

  bool get requiresAction =>
      isRequired && (!isCurrent || decision != 'granted');
}

/// Aggregated consent status domain model.
@immutable
class ConsentStatusDomain {
  final bool requiresReview;
  final List<ConsentDecisionDomain> decisions;

  const ConsentStatusDomain({
    required this.requiresReview,
    this.decisions = const <ConsentDecisionDomain>[],
  });
}

/// Authorized subject summary domain model.
@immutable
class SubjectSummaryDomain {
  final String id;
  final String code;
  final String name;
  final String curriculumEditionCode;
  final String curriculumVersionId;

  const SubjectSummaryDomain({
    required this.id,
    required this.code,
    required this.name,
    required this.curriculumEditionCode,
    required this.curriculumVersionId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectSummaryDomain &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          name == other.name &&
          curriculumEditionCode == other.curriculumEditionCode &&
          curriculumVersionId == other.curriculumVersionId;

  @override
  int get hashCode =>
      Object.hash(id, code, name, curriculumEditionCode, curriculumVersionId);
}

/// Active mission summary domain model.
@immutable
class ActiveMissionSummaryDomain {
  final String id;
  final String subjectId;
  final String missionDate;
  final String status;

  const ActiveMissionSummaryDomain({
    required this.id,
    required this.subjectId,
    required this.missionDate,
    required this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveMissionSummaryDomain &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          subjectId == other.subjectId &&
          missionDate == other.missionDate &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, subjectId, missionDate, status);
}

/// Summary of a pending learning update or privacy request.
@immutable
class PendingResourceSummaryDomain {
  final String id;
  final String status;
  final DateTime updatedAt;

  const PendingResourceSummaryDomain({
    required this.id,
    required this.status,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingResourceSummaryDomain &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(id, status, updatedAt);
}

/// Server capability flags domain model.
@immutable
class CapabilityFlagsDomain {
  final bool canStartMission;
  final bool canAddLearningMaterial;
  final bool canRegisterNotifications;

  const CapabilityFlagsDomain({
    this.canStartMission = false,
    this.canAddLearningMaterial = false,
    this.canRegisterNotifications = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CapabilityFlagsDomain &&
          runtimeType == other.runtimeType &&
          canStartMission == other.canStartMission &&
          canAddLearningMaterial == other.canAddLearningMaterial &&
          canRegisterNotifications == other.canRegisterNotifications;

  @override
  int get hashCode => Object.hash(
    canStartMission,
    canAddLearningMaterial,
    canRegisterNotifications,
  );
}

/// Immutable aggregated session bootstrap domain state.
@immutable
class BootstrapData {
  final AccountStatusDomain accountStatus;
  final ProfileSummaryDomain profileSummary;
  final ConsentStatusDomain consentStatus;
  final List<SubjectSummaryDomain> subjects;
  final ActiveMissionSummaryDomain? activeMission;
  final List<PendingResourceSummaryDomain> pendingUpdates;
  final List<PendingResourceSummaryDomain> pendingPrivacyRequests;
  final CapabilityFlagsDomain capabilities;
  final DateTime serverTime;
  final bool isStale;

  const BootstrapData({
    required this.accountStatus,
    required this.profileSummary,
    required this.consentStatus,
    required this.subjects,
    this.activeMission,
    this.pendingUpdates = const <PendingResourceSummaryDomain>[],
    this.pendingPrivacyRequests = const <PendingResourceSummaryDomain>[],
    required this.capabilities,
    required this.serverTime,
    this.isStale = false,
  });

  bool get hasActiveMission => activeMission != null;
  bool get hasSubjects => subjects.isNotEmpty;
  bool get hasPendingWork =>
      pendingUpdates.isNotEmpty || pendingPrivacyRequests.isNotEmpty;

  BootstrapData copyWith({
    AccountStatusDomain? accountStatus,
    ProfileSummaryDomain? profileSummary,
    ConsentStatusDomain? consentStatus,
    List<SubjectSummaryDomain>? subjects,
    ActiveMissionSummaryDomain? activeMission,
    List<PendingResourceSummaryDomain>? pendingUpdates,
    List<PendingResourceSummaryDomain>? pendingPrivacyRequests,
    CapabilityFlagsDomain? capabilities,
    DateTime? serverTime,
    bool? isStale,
  }) {
    return BootstrapData(
      accountStatus: accountStatus ?? this.accountStatus,
      profileSummary: profileSummary ?? this.profileSummary,
      consentStatus: consentStatus ?? this.consentStatus,
      subjects: subjects ?? this.subjects,
      activeMission: activeMission ?? this.activeMission,
      pendingUpdates: pendingUpdates ?? this.pendingUpdates,
      pendingPrivacyRequests:
          pendingPrivacyRequests ?? this.pendingPrivacyRequests,
      capabilities: capabilities ?? this.capabilities,
      serverTime: serverTime ?? this.serverTime,
      isStale: isStale ?? this.isStale,
    );
  }
}
