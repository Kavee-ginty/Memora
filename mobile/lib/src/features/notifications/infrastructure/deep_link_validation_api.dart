import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:memora_api_client/memora_api_client.dart';

import '../../../configuration/app_configuration.dart';
import '../../common/ids.dart';

/// Server-side resource state for a deep-link target (API §16.3: the client
/// always validates through the API before navigation; push is never
/// authoritative).
enum DeepLinkResourceState {
  /// The resource exists, belongs to the signed-in student and is in a
  /// workflow state the destination expects.
  valid,

  /// The resource exists but the workflow moved on (completed, committed
  /// elsewhere, expired) — resolve to the stable parent with an explanation.
  invalidState,

  /// Unknown, expired or owned by someone else — indistinguishable on
  /// purpose (server-derived 404/403).
  missing,

  /// The check itself could not complete (network); resolve safely.
  unavailable,
}

/// Validated today's mission for mission intents.
@immutable
class MissionValidation {
  final bool valid;
  final String? missionId;

  const MissionValidation.valid(this.missionId) : valid = true;

  const MissionValidation.invalid() : valid = false, missionId = null;
}

abstract class DeepLinkValidationApi {
  Future<MissionValidation> todayMission();

  /// Validates a learning update in the [requiredStatus] workflow state:
  /// verification taps demand `verification_required`, learning-path taps
  /// demand `committed` (review finding 4).
  Future<DeepLinkResourceState> learningUpdate(
    String updateId, {
    required LearningUpdateStatus requiredStatus,
  });

  /// Validates a privacy export; only a `completed` request is actionable
  /// for an "export ready" tap.
  Future<DeepLinkResourceState> privacyExport(String requestId);
}

class MemoraDeepLinkValidationApi implements DeepLinkValidationApi {
  final MemoraApiClient apiClient;
  final AppConfiguration configuration;

  const MemoraDeepLinkValidationApi({
    required this.apiClient,
    required this.configuration,
  });

  @override
  Future<MissionValidation> todayMission() async {
    try {
      final response = await apiClient.getMissionsApi().getTodayMission(
        xCorrelationID: generateUuid(),
        xClientVersion: configuration.clientVersion,
        xPlatform: configuration.platform,
      );
      final mission = response.data?.mission;
      final state = response.data?.state;
      if (mission == null ||
          state == TodayMissionResponseStateEnum.noDue ||
          state == TodayMissionResponseStateEnum.missionComplete) {
        return const MissionValidation.invalid();
      }
      return MissionValidation.valid(mission.id);
    } on DioException catch (error) {
      final code = error.response?.statusCode ?? 0;
      if (code == 404 || code == 403) {
        return const MissionValidation.invalid();
      }
      return const MissionValidation.invalid();
    }
  }

  @override
  Future<DeepLinkResourceState> learningUpdate(
    String updateId, {
    required LearningUpdateStatus requiredStatus,
  }) async {
    try {
      final response = await apiClient
          .getLearningUpdatesApi()
          .getLearningUpdate(
            updateId: updateId,
            xCorrelationID: generateUuid(),
            xClientVersion: configuration.clientVersion,
            xPlatform: configuration.platform,
          );
      final update = response.data;
      if (update == null) {
        return DeepLinkResourceState.missing;
      }
      if (update.status != requiredStatus) {
        return DeepLinkResourceState.invalidState;
      }
      return DeepLinkResourceState.valid;
    } on DioException catch (error) {
      return _mapError(error);
    }
  }

  @override
  Future<DeepLinkResourceState> privacyExport(String requestId) async {
    try {
      final response = await apiClient.getPrivacyApi().getPrivacyExport(
        requestId: requestId,
        xCorrelationID: generateUuid(),
        xClientVersion: configuration.clientVersion,
        xPlatform: configuration.platform,
      );
      final request = response.data;
      if (request == null) {
        return DeepLinkResourceState.missing;
      }
      // An "export ready" tap is actionable only for a completed request
      // with a download reference (review finding 4); pending, failed or
      // cancelled states fall back to the privacy parent.
      final download = request.downloadUrl;
      if (request.status != PrivacyExportResponseStatusEnum.completed ||
          !download.isPresent ||
          download.value == null) {
        return DeepLinkResourceState.invalidState;
      }
      return DeepLinkResourceState.valid;
    } on DioException catch (error) {
      return _mapError(error);
    }
  }

  DeepLinkResourceState _mapError(DioException error) {
    final code = error.response?.statusCode ?? 0;
    if (code == 404 || code == 403) {
      return DeepLinkResourceState.missing;
    }
    return DeepLinkResourceState.unavailable;
  }
}
