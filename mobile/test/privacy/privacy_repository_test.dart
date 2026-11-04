import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_api_client/memora_api_client.dart';
import 'package:memora_mobile/src/configuration/app_configuration.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/privacy/data/privacy_repository.dart';
import 'package:memora_mobile/src/features/privacy/domain/privacy_models.dart';

Map<String, dynamic> _errorEnvelope(String code) {
  return <String, dynamic>{
    'error': <String, dynamic>{
      'code': code,
      'message': 'Raw server text must never reach the UI.',
      'request_id': 'req_privacy_1',
      'retryable': false,
      'field_errors': <Map<String, dynamic>>[],
    },
  };
}

Map<String, dynamic> _exportResponse({
  String status = 'requested',
  String? downloadUrl,
  String? downloadExpiresAt,
}) {
  return <String, dynamic>{
    'id': 'exp_1',
    'request_type': 'export',
    'status': status,
    'requested_at': '2026-11-01T10:00:00Z',
    'completed_at': status == 'completed' ? '2026-11-01T10:05:00Z' : null,
    'download_url': downloadUrl,
    'download_expires_at': downloadExpiresAt,
    'failure_code': status == 'failed' ? 'export_failed' : null,
  };
}

Map<String, dynamic> _deletionResponse({
  String status = 'requested',
  List<Map<String, dynamic>> proofs = const <Map<String, dynamic>>[],
  List<String> retentionExceptions = const <String>[],
}) {
  return <String, dynamic>{
    'id': 'del_1',
    'request_type': 'delete',
    'status': status,
    'requested_at': '2026-11-01T10:00:00Z',
    'completed_at': status == 'completed' ? '2026-11-01T10:05:00Z' : null,
    'proofs': proofs,
    'retention_exceptions': retentionExceptions,
    'failure_code': null,
  };
}

Map<String, dynamic> _proof() {
  return <String, dynamic>{
    'id': 'prf_1',
    'scope': 'profile',
    'provider': 'postgres',
    'target_fingerprint': 'sha256:redacted',
    'result': 'deleted',
    'verified_at': '2026-11-01T10:04:00Z',
  };
}

void main() {
  const localConfiguration = AppConfiguration(
    supabaseUrl: 'https://test.supabase.co',
    supabasePublishableKey: 'test-key',
    apiBaseUrl: 'http://127.0.0.1:8000',
    oauthRedirectUri: 'com.kaveeginty.memora://login-callback',
    clientVersion: '0.1.0',
    platform: 'android',
    environment: 'local',
  );

  late Dio dio;
  late MemoraApiClient apiClient;
  late MemoraPrivacyRepository repository;

  void useConfiguration(AppConfiguration configuration) {
    repository = MemoraPrivacyRepository(
      apiClient: apiClient,
      configuration: configuration,
    );
  }

  setUp(() {
    dio = Dio();
    apiClient = MemoraApiClient(dio: dio);
    useConfiguration(localConfiguration);
  });

  group('MemoraPrivacyRepository export requests', () {
    test('POST attaches auth, metadata and idempotency headers', () async {
      String? method;
      String? path;
      String? auth;
      String? correlation;
      String? version;
      String? platform;
      String? idempotencyKey;
      Map<String, dynamic>? body;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            method = options.method;
            path = options.path;
            auth = options.headers['Authorization'] as String?;
            correlation = options.headers['X-Correlation-ID'] as String?;
            version = options.headers['X-Client-Version'] as String?;
            platform = options.headers['X-Platform'] as String?;
            idempotencyKey = options.headers['Idempotency-Key'] as String?;
            body = Map<String, dynamic>.from(
              options.data as Map<dynamic, dynamic>,
            );
            return handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 202,
                data: _exportResponse(),
              ),
            );
          },
        ),
      );

      final export = await repository.createExport(
        accessToken: 'token_abc',
        idempotencyKey: 'idem-export-1',
      );

      expect(method, 'POST');
      expect(path, '/v1/privacy/exports');
      expect(auth, 'Bearer token_abc');
      expect(correlation, isNotEmpty);
      expect(version, '0.1.0');
      expect(platform, 'android');
      expect(idempotencyKey, 'idem-export-1');
      expect(body, <String, dynamic>{'format': 'json'});
      expect(export.id, 'exp_1');
      expect(export.status, PrivacyRequestStatus.requested);
      expect(export.requestedAt, DateTime.utc(2026, 11, 1, 10));
      expect(export.hasDownload, isFalse);
    });

    test(
      'GET maps completed export and resolves the relative download URL',
      () async {
        String? path;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              path = options.path;
              return handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: _exportResponse(
                    status: 'completed',
                    downloadUrl:
                        '/v1/privacy/exports/exp_1/download?token=signed-token',
                    downloadExpiresAt: '2026-11-02T10:05:00Z',
                  ),
                ),
              );
            },
          ),
        );

        final export = await repository.getExport(
          accessToken: 'token_abc',
          requestId: 'exp_1',
        );

        expect(path, '/v1/privacy/exports/exp_1');
        expect(export.status, PrivacyRequestStatus.completed);
        expect(export.completedAt, DateTime.utc(2026, 11, 1, 10, 5));
        expect(
          export.downloadUri,
          Uri.parse(
            'http://127.0.0.1:8000/v1/privacy/exports/exp_1/download'
            '?token=signed-token',
          ),
        );
        expect(export.downloadExpiresAt, DateTime.utc(2026, 11, 2, 10, 5));
        expect(export.hasActiveDownload(DateTime.utc(2026, 11, 1, 12)), isTrue);
        expect(
          export.hasActiveDownload(DateTime.utc(2026, 11, 2, 11)),
          isFalse,
        );
      },
    );

    test(
      'expired or absent download details are never treated as ready',
      () async {
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              return handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: _exportResponse(status: 'completed'),
                ),
              );
            },
          ),
        );

        final export = await repository.getExport(
          accessToken: 'token_abc',
          requestId: 'exp_1',
        );

        expect(export.status, PrivacyRequestStatus.completed);
        expect(export.hasDownload, isFalse);
        expect(
          export.hasActiveDownload(DateTime.utc(2026, 11, 1, 12)),
          isFalse,
        );
      },
    );

    test('unsafe download schemes are rejected', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: _exportResponse(
                  status: 'completed',
                  downloadUrl: 'javascript:alert(1)',
                ),
              ),
            );
          },
        ),
      );

      final export = await repository.getExport(
        accessToken: 'token_abc',
        requestId: 'exp_1',
      );

      expect(export.downloadUri, isNull);
    });

    test('HTTP downloads are local-only and loopback-only', () async {
      useConfiguration(
        const AppConfiguration(
          supabaseUrl: 'https://test.supabase.co',
          supabasePublishableKey: 'test-key',
          apiBaseUrl: 'https://api.memora.example',
          oauthRedirectUri: 'com.kaveeginty.memora://login-callback',
          platform: 'android',
          environment: 'staging',
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: _exportResponse(
                  status: 'completed',
                  downloadUrl: 'http://127.0.0.1:8000/export',
                ),
              ),
            );
          },
        ),
      );

      final httpExport = await repository.getExport(
        accessToken: 'token_abc',
        requestId: 'exp_1',
      );
      expect(httpExport.downloadUri, isNull);

      dio.interceptors.clear();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: _exportResponse(
                  status: 'completed',
                  downloadUrl: 'https://cdn.memora.example/export',
                ),
              ),
            );
          },
        ),
      );

      final httpsExport = await repository.getExport(
        accessToken: 'token_abc',
        requestId: 'exp_1',
      );
      expect(
        httpsExport.downloadUri,
        Uri.parse('https://cdn.memora.example/export'),
      );
    });

    test('unknown additive status maps to unknown, never complete', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: _exportResponse(status: 'unknown_default_open_api'),
              ),
            );
          },
        ),
      );

      final export = await repository.getExport(
        accessToken: 'token_abc',
        requestId: 'exp_1',
      );

      expect(export.status, PrivacyRequestStatus.unknown);
      expect(export.status.isPending, isFalse);
      expect(export.status.isTerminal, isFalse);
    });
  });

  group('MemoraPrivacyRepository deletion requests', () {
    test('POST sends explicit confirmation and idempotency key', () async {
      String? path;
      String? idempotencyKey;
      Map<String, dynamic>? body;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            path = options.path;
            idempotencyKey = options.headers['Idempotency-Key'] as String?;
            body = Map<String, dynamic>.from(
              options.data as Map<dynamic, dynamic>,
            );
            return handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 202,
                data: _deletionResponse(),
              ),
            );
          },
        ),
      );

      final deletion = await repository.createDeletion(
        accessToken: 'token_abc',
        idempotencyKey: 'idem-delete-1',
        confirmed: true,
      );

      expect(path, '/v1/privacy/deletions');
      expect(idempotencyKey, 'idem-delete-1');
      expect(body, <String, dynamic>{'confirmed': true});
      expect(deletion.status, PrivacyRequestStatus.requested);
      expect(deletion.canCancel, isTrue);
      expect(deletion.isConfirmedComplete, isFalse);
    });

    test('GET maps proofs, retention exceptions and completion', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: _deletionResponse(
                  status: 'completed',
                  proofs: <Map<String, dynamic>>[_proof()],
                  retentionExceptions: <String>[
                    'Billing records are retained for seven years.',
                  ],
                ),
              ),
            );
          },
        ),
      );

      final deletion = await repository.getDeletion(
        accessToken: 'token_abc',
        requestId: 'del_1',
      );

      expect(deletion.status, PrivacyRequestStatus.completed);
      expect(deletion.isConfirmedComplete, isTrue);
      expect(deletion.proofs, hasLength(1));
      expect(deletion.proofs.single.scope, 'profile');
      expect(deletion.proofs.single.result, 'deleted');
      expect(
        deletion.proofs.single.verifiedAt,
        DateTime.utc(2026, 11, 1, 10, 4),
      );
      expect(deletion.retentionExceptions, hasLength(1));
      expect(deletion.canCancel, isFalse);
    });

    test('completed without proofs is not confirmed completion', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: _deletionResponse(status: 'completed'),
              ),
            );
          },
        ),
      );

      final deletion = await repository.getDeletion(
        accessToken: 'token_abc',
        requestId: 'del_1',
      );

      expect(deletion.status, PrivacyRequestStatus.completed);
      expect(deletion.isConfirmedComplete, isFalse);
    });

    test('POST cancel sends the stable key and optional reason', () async {
      String? path;
      String? method;
      String? idempotencyKey;
      Map<String, dynamic>? body;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            path = options.path;
            method = options.method;
            idempotencyKey = options.headers['Idempotency-Key'] as String?;
            body = Map<String, dynamic>.from(
              options.data as Map<dynamic, dynamic>,
            );
            return handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: _deletionResponse(status: 'cancelled'),
              ),
            );
          },
        ),
      );

      final deletion = await repository.cancelDeletion(
        accessToken: 'token_abc',
        requestId: 'del_1',
        idempotencyKey: 'idem-cancel-1',
        reason: 'changed_mind',
      );

      expect(method, 'POST');
      expect(path, '/v1/privacy/deletions/del_1/cancel');
      expect(idempotencyKey, 'idem-cancel-1');
      expect(body, <String, dynamic>{'reason': 'changed_mind'});
      expect(deletion.status, PrivacyRequestStatus.cancelled);
      expect(deletion.canCancel, isFalse);
    });

    test('cancel defaults the reason without exposing extra detail', () async {
      Map<String, dynamic>? body;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            body = Map<String, dynamic>.from(
              options.data as Map<dynamic, dynamic>,
            );
            return handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: _deletionResponse(status: 'cancelled'),
              ),
            );
          },
        ),
      );

      await repository.cancelDeletion(
        accessToken: 'token_abc',
        requestId: 'del_1',
        idempotencyKey: 'idem-cancel-1',
      );

      expect(body, <String, dynamic>{'reason': 'user_requested'});
    });
  });

  group('MemoraPrivacyRepository safe failures', () {
    Future<AuthFailure> captureFailure(
      int statusCode,
      String code, {
      bool withEnvelope = true,
    }) async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: statusCode,
                  data: withEnvelope ? _errorEnvelope(code) : null,
                ),
              ),
            );
          },
        ),
      );

      try {
        await repository.createExport(
          accessToken: 'token_abc',
          idempotencyKey: 'idem-export-1',
        );
        fail('Expected an AuthFailure');
      } on AuthFailure catch (failure) {
        return failure;
      }
    }

    test('recent authentication failure keeps its recovery code', () async {
      final failure = await captureFailure(
        403,
        'recent_authentication_required',
      );
      expect(failure.code, 'recent_authentication_required');
      expect(failure.retryable, isFalse);
      expect(failure.message, contains('confirm your credentials'));
    });

    test('cancellation disallowed keeps its safe code', () async {
      final failure = await captureFailure(
        409,
        'deletion_cancellation_disallowed',
      );
      expect(failure.code, 'deletion_cancellation_disallowed');
      expect(failure.message, 'This deletion can no longer be cancelled.');
    });

    test('missing privacy request uses the safe not_found code', () async {
      final failure = await captureFailure(404, 'not_found');
      expect(failure.code, 'not_found');
      expect(failure.message, 'That privacy request was not found.');
    });

    test('401 maps to an expired session', () async {
      final failure = await captureFailure(401, 'token_expired');
      expect(failure.code, 'expired_session');
    });

    test('unknown codes never echo raw server text', () async {
      final failure = await captureFailure(500, 'future_private_code');
      expect(failure.code, 'unknown');
      expect(failure.message, isNot(contains('Raw server text')));
    });
  });
}
