import 'package:dio/dio.dart';
import 'package:memora_api_client/memora_api_client.dart';

import '../../../configuration/app_configuration.dart';
import '../../auth/data/api_error_mapper.dart';
import '../../auth/domain/app_session_state.dart';
import '../../common/ids.dart';
import '../domain/privacy_models.dart';

/// Contract for the T20 privacy export and deletion endpoints.
abstract class PrivacyRepository {
  Future<PrivacyExport> createExport({
    required String accessToken,
    required String idempotencyKey,
  });

  Future<PrivacyExport> getExport({
    required String accessToken,
    required String requestId,
  });

  Future<PrivacyDeletion> createDeletion({
    required String accessToken,
    required String idempotencyKey,
    required bool confirmed,
  });

  Future<PrivacyDeletion> getDeletion({
    required String accessToken,
    required String requestId,
  });

  Future<PrivacyDeletion> cancelDeletion({
    required String accessToken,
    required String requestId,
    required String idempotencyKey,
    String? reason,
  });
}

/// Generated-client implementation of [PrivacyRepository].
class MemoraPrivacyRepository implements PrivacyRepository {
  const MemoraPrivacyRepository({
    required this.apiClient,
    required this.configuration,
  });

  final MemoraApiClient apiClient;
  final AppConfiguration configuration;

  PrivacyApi get _api => apiClient.getPrivacyApi();

  @override
  Future<PrivacyExport> createExport({
    required String accessToken,
    required String idempotencyKey,
  }) async {
    return _guard(() async {
      _setAuthToken(accessToken);
      final request = PrivacyExportRequest(
        (builder) => builder..format = Optional.present('json'),
      );
      final response = await _api.createPrivacyExport(
        xCorrelationID: generateUuid(),
        xClientVersion: configuration.clientVersion,
        xPlatform: configuration.platform,
        idempotencyKey: idempotencyKey,
        privacyExportRequest: request,
      );
      return _mapExport(response.data);
    });
  }

  @override
  Future<PrivacyExport> getExport({
    required String accessToken,
    required String requestId,
  }) async {
    return _guard(() async {
      _setAuthToken(accessToken);
      final response = await _api.getPrivacyExport(
        requestId: requestId,
        xCorrelationID: generateUuid(),
        xClientVersion: configuration.clientVersion,
        xPlatform: configuration.platform,
      );
      return _mapExport(response.data);
    });
  }

  @override
  Future<PrivacyDeletion> createDeletion({
    required String accessToken,
    required String idempotencyKey,
    required bool confirmed,
  }) async {
    return _guard(() async {
      _setAuthToken(accessToken);
      final request = PrivacyDeletionRequest(
        (builder) => builder..confirmed = Optional.present(confirmed),
      );
      final response = await _api.createPrivacyDeletion(
        xCorrelationID: generateUuid(),
        xClientVersion: configuration.clientVersion,
        xPlatform: configuration.platform,
        idempotencyKey: idempotencyKey,
        privacyDeletionRequest: request,
      );
      return _mapDeletion(response.data);
    });
  }

  @override
  Future<PrivacyDeletion> getDeletion({
    required String accessToken,
    required String requestId,
  }) async {
    return _guard(() async {
      _setAuthToken(accessToken);
      final response = await _api.getPrivacyDeletion(
        requestId: requestId,
        xCorrelationID: generateUuid(),
        xClientVersion: configuration.clientVersion,
        xPlatform: configuration.platform,
      );
      return _mapDeletion(response.data);
    });
  }

  @override
  Future<PrivacyDeletion> cancelDeletion({
    required String accessToken,
    required String requestId,
    required String idempotencyKey,
    String? reason,
  }) async {
    return _guard(() async {
      _setAuthToken(accessToken);
      final request = PrivacyDeletionCancelRequest(
        (builder) =>
            builder..reason = Optional.present(reason ?? 'user_requested'),
      );
      final response = await _api.cancelPrivacyDeletion(
        requestId: requestId,
        xCorrelationID: generateUuid(),
        xClientVersion: configuration.clientVersion,
        xPlatform: configuration.platform,
        idempotencyKey: idempotencyKey,
        privacyDeletionCancelRequest: request,
      );
      return _mapDeletion(response.data);
    });
  }

  void _setAuthToken(String token) {
    apiClient.setBearerAuth('bearerAuth', token);
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DioException catch (error) {
      throw mapDioExceptionToFailure(error);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw AuthFailure.unknown();
    }
  }

  PrivacyExport _mapExport(PrivacyExportResponse? response) {
    if (response == null) {
      throw AuthFailure.unknown();
    }
    final rawUrl = response.downloadUrl.isPresent
        ? response.downloadUrl.value
        : null;
    return PrivacyExport(
      id: response.id,
      status: _mapExportStatus(response.status),
      requestedAt: _parseDate(response.requestedAt),
      completedAt: _optionalDate(response.completedAt),
      downloadUri: _resolveDownloadUri(rawUrl),
      downloadExpiresAt: _optionalDate(response.downloadExpiresAt),
      failureCode: response.failureCode.isPresent
          ? response.failureCode.value
          : null,
    );
  }

  PrivacyDeletion _mapDeletion(PrivacyDeletionResponse? response) {
    if (response == null) {
      throw AuthFailure.unknown();
    }
    return PrivacyDeletion(
      id: response.id,
      status: _mapDeletionStatus(response.status),
      requestedAt: _parseDate(response.requestedAt),
      completedAt: _optionalDate(response.completedAt),
      failureCode: response.failureCode.isPresent
          ? response.failureCode.value
          : null,
      proofs: response.proofs
          .map(
            (proof) => DeletionProof(
              id: proof.id,
              scope: proof.scope,
              provider: proof.provider,
              result: proof.result,
              verifiedAt: _parseDate(proof.verifiedAt),
            ),
          )
          .toList(growable: false),
      retentionExceptions: response.retentionExceptions.toList(growable: false),
    );
  }

  PrivacyRequestStatus _mapExportStatus(
    PrivacyExportResponseStatusEnum status,
  ) {
    if (status == PrivacyExportResponseStatusEnum.requested) {
      return PrivacyRequestStatus.requested;
    }
    if (status == PrivacyExportResponseStatusEnum.verifying) {
      return PrivacyRequestStatus.verifying;
    }
    if (status == PrivacyExportResponseStatusEnum.processing) {
      return PrivacyRequestStatus.processing;
    }
    if (status == PrivacyExportResponseStatusEnum.completed) {
      return PrivacyRequestStatus.completed;
    }
    if (status == PrivacyExportResponseStatusEnum.failed) {
      return PrivacyRequestStatus.failed;
    }
    if (status == PrivacyExportResponseStatusEnum.cancelled) {
      return PrivacyRequestStatus.cancelled;
    }
    return PrivacyRequestStatus.unknown;
  }

  PrivacyRequestStatus _mapDeletionStatus(
    PrivacyDeletionResponseStatusEnum status,
  ) {
    if (status == PrivacyDeletionResponseStatusEnum.requested) {
      return PrivacyRequestStatus.requested;
    }
    if (status == PrivacyDeletionResponseStatusEnum.verifying) {
      return PrivacyRequestStatus.verifying;
    }
    if (status == PrivacyDeletionResponseStatusEnum.processing) {
      return PrivacyRequestStatus.processing;
    }
    if (status == PrivacyDeletionResponseStatusEnum.completed) {
      return PrivacyRequestStatus.completed;
    }
    if (status == PrivacyDeletionResponseStatusEnum.failed) {
      return PrivacyRequestStatus.failed;
    }
    if (status == PrivacyDeletionResponseStatusEnum.cancelled) {
      return PrivacyRequestStatus.cancelled;
    }
    return PrivacyRequestStatus.unknown;
  }

  DateTime? _optionalDate(Optional<String?> value) {
    if (!value.isPresent || value.value == null) return null;
    return _parseDate(value.value!);
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Resolves the server's signed download path and rejects unsafe schemes.
  ///
  /// Production downloads must be HTTPS. A loopback HTTP URL is accepted only
  /// in the local environment so Docker and emulator development can exercise
  /// the real backend. The URL is never logged or persisted by this layer.
  Uri? _resolveDownloadUri(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    final parsed = Uri.tryParse(rawUrl);
    if (parsed == null) return null;

    Uri? resolved = parsed;
    if (!parsed.hasScheme) {
      final base = Uri.tryParse(configuration.apiBaseUrl);
      if (base == null) return null;
      resolved = base.resolveUri(parsed);
    }

    if (!_isAllowedDownloadUri(resolved)) return null;
    return resolved;
  }

  bool _isAllowedDownloadUri(Uri uri) {
    if (uri.scheme == 'https') return true;
    if (uri.scheme != 'http') return false;
    if (configuration.environment != 'local') return false;
    return _isLoopbackHost(uri.host);
  }

  bool _isLoopbackHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '::1';
  }
}

/// Deterministic local implementation used only when the app is unconfigured.
///
/// The running application overrides the provider with
/// [MemoraPrivacyRepository]. Tests can use this class or a purpose-built fake.
class MockPrivacyRepository implements PrivacyRepository {
  static const String mockExportId = '11111111-1111-4111-8111-111111111111';
  static const String mockDeletionId = '22222222-2222-4222-8222-222222222222';

  PrivacyExport? configuredExport;
  PrivacyDeletion? configuredDeletion;
  AuthFailure? failure;

  int createExportCallCount = 0;
  int getExportCallCount = 0;
  int createDeletionCallCount = 0;
  int getDeletionCallCount = 0;
  int cancelDeletionCallCount = 0;

  String? lastCreateExportKey;
  String? lastCreateDeletionKey;
  String? lastCancelDeletionKey;
  String? lastCancelReason;

  @override
  Future<PrivacyExport> createExport({
    required String accessToken,
    required String idempotencyKey,
  }) async {
    createExportCallCount++;
    lastCreateExportKey = idempotencyKey;
    _maybeFail();
    return configuredExport ??
        PrivacyExport(
          id: mockExportId,
          status: PrivacyRequestStatus.requested,
          requestedAt: DateTime.now().toUtc(),
        );
  }

  @override
  Future<PrivacyExport> getExport({
    required String accessToken,
    required String requestId,
  }) async {
    getExportCallCount++;
    _maybeFail();
    return configuredExport ??
        PrivacyExport(
          id: requestId,
          status: PrivacyRequestStatus.requested,
          requestedAt: DateTime.now().toUtc(),
        );
  }

  @override
  Future<PrivacyDeletion> createDeletion({
    required String accessToken,
    required String idempotencyKey,
    required bool confirmed,
  }) async {
    createDeletionCallCount++;
    lastCreateDeletionKey = idempotencyKey;
    _maybeFail();
    return configuredDeletion ??
        PrivacyDeletion(
          id: mockDeletionId,
          status: PrivacyRequestStatus.requested,
          requestedAt: DateTime.now().toUtc(),
        );
  }

  @override
  Future<PrivacyDeletion> getDeletion({
    required String accessToken,
    required String requestId,
  }) async {
    getDeletionCallCount++;
    _maybeFail();
    return configuredDeletion ??
        PrivacyDeletion(
          id: requestId,
          status: PrivacyRequestStatus.requested,
          requestedAt: DateTime.now().toUtc(),
        );
  }

  @override
  Future<PrivacyDeletion> cancelDeletion({
    required String accessToken,
    required String requestId,
    required String idempotencyKey,
    String? reason,
  }) async {
    cancelDeletionCallCount++;
    lastCancelDeletionKey = idempotencyKey;
    lastCancelReason = reason;
    _maybeFail();
    return configuredDeletion ??
        PrivacyDeletion(
          id: requestId,
          status: PrivacyRequestStatus.cancelled,
          requestedAt: DateTime.now().toUtc(),
        );
  }

  void _maybeFail() {
    final configured = failure;
    if (configured != null) throw configured;
  }
}
