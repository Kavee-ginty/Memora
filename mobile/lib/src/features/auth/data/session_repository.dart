import 'package:dio/dio.dart';
import 'package:memora_api_client/memora_api_client.dart';

import '../../../configuration/app_configuration.dart';
import '../../common/ids.dart';
import '../domain/app_session_state.dart';
import '../domain/bootstrap_state.dart';
import 'api_error_mapper.dart';
import 'auth_repository.dart';

export '../../common/ids.dart' show generateUuid;

/// Contract for Memora API session operations.
abstract class SessionRepository {
  Future<BootstrapData> bootstrapSession({required String accessToken});
  Future<void> revokeSession({
    required String accessToken,
    required String idempotencyKey,
    SessionRevocationScope scope = SessionRevocationScope.current,
  });
}

/// Generated client implementation of [SessionRepository].
class MemoraSessionRepository implements SessionRepository {
  final MemoraApiClient apiClient;
  final AppConfiguration configuration;
  final AuthRepository? authRepository;

  const MemoraSessionRepository({
    required this.apiClient,
    required this.configuration,
    this.authRepository,
  });

  @override
  Future<BootstrapData> bootstrapSession({required String accessToken}) async {
    return _executeWithRefresh(
      accessToken: accessToken,
      operation: (token) async {
        _setAuthToken(token);
        final response = await apiClient.getSessionApi().bootstrapSession(
          xCorrelationID: generateUuid(),
          xClientVersion: configuration.clientVersion,
          xPlatform: configuration.platform,
        );

        final data = response.data;
        if (data == null) {
          throw AuthFailure.unknown('Empty bootstrap response from server.');
        }

        return _mapBootstrapResponse(data);
      },
    );
  }

  @override
  Future<void> revokeSession({
    required String accessToken,
    required String idempotencyKey,
    SessionRevocationScope scope = SessionRevocationScope.current,
  }) async {
    try {
      _setAuthToken(accessToken);
      final request = SessionRevokeRequest(
        (b) => b..scope = Optional.present(scope),
      );

      await apiClient.getSessionApi().revokeSession(
        xCorrelationID: generateUuid(),
        xClientVersion: configuration.clientVersion,
        xPlatform: configuration.platform,
        idempotencyKey: idempotencyKey,
        sessionRevokeRequest: request,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (_) {
      throw AuthFailure.networkError();
    }
  }

  void _setAuthToken(String token) {
    apiClient.setBearerAuth('bearerAuth', token);
  }

  Future<T> _executeWithRefresh<T>({
    required String accessToken,
    required Future<T> Function(String token) operation,
  }) async {
    try {
      return await operation(accessToken);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && authRepository != null) {
        // Attempt single-flight refresh
        final refreshed = await authRepository!.refreshSession();
        if (refreshed != null && refreshed.accessToken.isNotEmpty) {
          try {
            return await operation(refreshed.accessToken);
          } on DioException catch (secondError) {
            throw _mapDioError(secondError);
          }
        }
        throw AuthFailure.expiredSession();
      }
      throw _mapDioError(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure.networkError();
    }
  }

  /// Maps the OpenAPI [SessionBootstrapResponse] DTO to the domain [BootstrapData].
  BootstrapData mapBootstrapResponse(SessionBootstrapResponse response) =>
      _mapBootstrapResponse(response);

  BootstrapData _mapBootstrapResponse(SessionBootstrapResponse response) {
    // Map account status with safe unknown fallback
    final accountStatus = _mapAccountStatus(response.accountStatus);

    // Map profile summary
    final profile = ProfileSummaryDomain(
      userId: response.profileSummary.userId,
      displayName: response.profileSummary.displayName,
      onboardingCompleted: response.profileSummary.onboardingCompleted,
      activeSubjectId: response.profileSummary.activeSubjectId,
      curriculumVersionId: response.profileSummary.curriculumVersionId,
    );

    // Map consent status list
    final consentDecisions = response.consentStatus
        .map(
          (d) => ConsentDecisionDomain(
            policyId: d.policyId.name,
            policyVersion: d.policyVersion,
            decision: d.decision?.name,
            isCurrent: d.isCurrent,
            isRequired: d.required_,
            decidedAt: d.decidedAt,
          ),
        )
        .toList();

    final requiresReview = consentDecisions.any((d) => d.requiresAction);
    final consentStatus = ConsentStatusDomain(
      requiresReview: requiresReview,
      decisions: consentDecisions,
    );

    // Map subjects
    final subjects = response.subjects
        .map(
          (s) => SubjectSummaryDomain(
            id: s.id,
            code: s.code,
            name: s.name,
            curriculumEditionCode: s.curriculumEditionCode,
            curriculumVersionId: s.curriculumVersionId,
          ),
        )
        .toList();

    // Map active mission if present
    ActiveMissionSummaryDomain? activeMission;
    final serverMission = response.activeMission;
    if (serverMission != null) {
      activeMission = ActiveMissionSummaryDomain(
        id: serverMission.id,
        subjectId: serverMission.subjectId,
        missionDate: serverMission.missionDate.toString(),
        status: serverMission.status.name,
      );
    }

    // Map pending updates
    final pendingUpdates = response.pendingLearningUpdates
        .map(
          (p) => PendingResourceSummaryDomain(
            id: p.id,
            status: p.status,
            updatedAt: p.updatedAt,
          ),
        )
        .toList();

    // Map pending privacy requests
    final pendingPrivacy = response.pendingPrivacyRequests
        .map(
          (p) => PendingResourceSummaryDomain(
            id: p.id,
            status: p.status,
            updatedAt: p.updatedAt,
          ),
        )
        .toList();

    // Map capabilities (all default to false safely if unknown)
    final capabilities = CapabilityFlagsDomain(
      canStartMission: response.capabilityFlags.canStartMission,
      canAddLearningMaterial: response.capabilityFlags.canAddLearningMaterial,
      canRegisterNotifications:
          response.capabilityFlags.canRegisterNotifications.orElse(false) ??
          false,
    );

    return BootstrapData(
      accountStatus: accountStatus,
      profileSummary: profile,
      consentStatus: consentStatus,
      subjects: subjects,
      activeMission: activeMission,
      pendingUpdates: pendingUpdates,
      pendingPrivacyRequests: pendingPrivacy,
      capabilities: capabilities,
      serverTime: response.serverTime,
    );
  }

  AccountStatusDomain _mapAccountStatus(AccountStatus status) {
    if (status == AccountStatus.active) return AccountStatusDomain.active;
    if (status == AccountStatus.suspended) return AccountStatusDomain.suspended;
    if (status == AccountStatus.deletionPending) {
      return AccountStatusDomain.deletionPending;
    }
    if (status == AccountStatus.deleted) return AccountStatusDomain.deleted;
    return AccountStatusDomain.unknown;
  }

  AuthFailure _mapDioError(DioException error) =>
      mapDioExceptionToFailure(error);
}

/// In-memory mock [SessionRepository] for deterministic testing.
class MockSessionRepository implements SessionRepository {
  BootstrapData? configuredBootstrap;
  bool shouldFailBootstrap = false;
  bool should401 = false;
  AuthFailure? configuredFailure;
  int bootstrapCallCount = 0;
  int revokeCallCount = 0;
  String? lastRevokeIdempotencyKey;

  MockSessionRepository({this.configuredBootstrap});

  @override
  Future<BootstrapData> bootstrapSession({required String accessToken}) async {
    bootstrapCallCount++;
    if (should401) {
      throw AuthFailure.expiredSession();
    }
    if (shouldFailBootstrap) {
      throw configuredFailure ?? AuthFailure.networkError();
    }

    return configuredBootstrap ??
        BootstrapData(
          accountStatus: AccountStatusDomain.active,
          profileSummary: const ProfileSummaryDomain(
            userId: 'usr_mock_123',
            displayName: 'Kasun Bandara',
            email: 'kasun@memora.internal',
            streakDays: 7,
          ),
          consentStatus: const ConsentStatusDomain(requiresReview: false),
          subjects: const <SubjectSummaryDomain>[
            SubjectSummaryDomain(
              id: 'sbj_physics_al',
              code: 'AL-PHYS',
              name: 'A/L Physics',
              curriculumEditionCode: 'AL-2026',
              curriculumVersionId: 'cur_al_v1',
            ),
          ],
          capabilities: const CapabilityFlagsDomain(
            canStartMission: true,
            canAddLearningMaterial: true,
          ),
          serverTime: DateTime.now(),
        );
  }

  @override
  Future<void> revokeSession({
    required String accessToken,
    required String idempotencyKey,
    SessionRevocationScope scope = SessionRevocationScope.current,
  }) async {
    revokeCallCount++;
    lastRevokeIdempotencyKey = idempotencyKey;
    if (shouldFailBootstrap) {
      throw configuredFailure ?? AuthFailure.networkError();
    }
  }
}
