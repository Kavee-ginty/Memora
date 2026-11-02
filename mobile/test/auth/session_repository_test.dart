import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_api_client/memora_api_client.dart';
import 'package:memora_mobile/src/configuration/app_configuration.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';

void main() {
  group('MemoraSessionRepository Integration and Interceptor Tests', () {
    late Dio dio;
    late MemoraApiClient apiClient;
    late AppConfiguration configuration;
    late MockAuthRepository mockAuthRepo;

    setUp(() {
      dio = Dio();
      apiClient = MemoraApiClient(dio: dio);
      configuration = const AppConfiguration(
        supabaseUrl: 'https://test.supabase.co',
        supabasePublishableKey: 'test-key',
        apiBaseUrl: 'http://127.0.0.1:8000',
        oauthRedirectUri: 'com.kaveeginty.memora://login-callback',
        clientVersion: '0.1.0',
        platform: 'android',
      );
      mockAuthRepo = MockAuthRepository(
        initialSession: const AuthSession(
          accessToken: 'initial_token',
          refreshToken: 'initial_refresh',
          userId: 'usr_1',
          email: 'student@memora.internal',
        ),
      );
    });

    test(
      'Attaches Authorization header and required metadata headers',
      () async {
        String? recordedAuth;
        String? recordedCorrelation;
        String? recordedVersion;
        String? recordedPlatform;

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              recordedAuth = options.headers['Authorization'] as String?;
              recordedCorrelation =
                  options.headers['X-Correlation-ID'] as String?;
              recordedVersion = options.headers['X-Client-Version'] as String?;
              recordedPlatform = options.headers['X-Platform'] as String?;

              return handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: <String, dynamic>{
                    'account_status': 'active',
                    'profile_summary': <String, dynamic>{
                      'user_id': 'usr_1',
                      'display_name': 'Kasun Bandara',
                      'onboarding_completed': true,
                    },
                    'consent_status': <Map<String, dynamic>>[],
                    'subjects': <Map<String, dynamic>>[],
                    'pending_learning_updates': <Map<String, dynamic>>[],
                    'pending_privacy_requests': <Map<String, dynamic>>[],
                    'capability_flags': <String, dynamic>{
                      'can_start_mission': true,
                      'can_add_learning_material': true,
                    },
                    'server_time': '2026-10-28T12:00:00Z',
                  },
                ),
              );
            },
          ),
        );

        final repository = MemoraSessionRepository(
          apiClient: apiClient,
          configuration: configuration,
          authRepository: mockAuthRepo,
        );

        final bootstrap = await repository.bootstrapSession(
          accessToken: 'token_xyz_123',
        );

        expect(recordedAuth, equals('Bearer token_xyz_123'));
        expect(recordedCorrelation, isNotEmpty);
        expect(recordedVersion, equals('0.1.0'));
        expect(recordedPlatform, equals('android'));
        expect(bootstrap.profileSummary.displayName, equals('Kasun Bandara'));
      },
    );

    test('401 Unauthorized triggers single-flight token refresh and replays read once', () async {
      int requestCount = 0;
      final List<String?> tokensUsed = [];

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestCount++;
            tokensUsed.add(options.headers['Authorization'] as String?);

            if (requestCount == 1) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response<dynamic>(
                    requestOptions: options,
                    statusCode: 401,
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
            }

            return handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'account_status': 'active',
                  'profile_summary': <String, dynamic>{
                    'user_id': 'usr_1',
                    'display_name': 'Kasun Bandara',
                    'onboarding_completed': true,
                  },
                  'consent_status': <Map<String, dynamic>>[],
                  'subjects': <Map<String, dynamic>>[],
                  'pending_learning_updates': <Map<String, dynamic>>[],
                  'pending_privacy_requests': <Map<String, dynamic>>[],
                  'capability_flags': <String, dynamic>{
                    'can_start_mission': true,
                    'can_add_learning_material': true,
                  },
                  'server_time': '2026-10-28T12:00:00Z',
                },
              ),
            );
          },
        ),
      );

      final repository = MemoraSessionRepository(
        apiClient: apiClient,
        configuration: configuration,
        authRepository: mockAuthRepo,
      );

      final bootstrap = await repository.bootstrapSession(
        accessToken: 'expired_token',
      );

      expect(requestCount, equals(2));
      expect(tokensUsed[0], equals('Bearer expired_token'));
      expect(tokensUsed[1], contains('Bearer refreshed_access_token_'));
      expect(bootstrap.profileSummary.displayName, equals('Kasun Bandara'));
    });

    test(
      'Failed refresh throws safe AuthFailure.expiredSession without looping',
      () async {
        mockAuthRepo.shouldFailRefresh = true;

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response<dynamic>(
                    requestOptions: options,
                    statusCode: 401,
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
            },
          ),
        );

        final repository = MemoraSessionRepository(
          apiClient: apiClient,
          configuration: configuration,
          authRepository: mockAuthRepo,
        );

        expect(
          () => repository.bootstrapSession(accessToken: 'expired_token'),
          throwsA(
            isA<AuthFailure>().having(
              (f) => f.code,
              'code',
              equals('expired_session'),
            ),
          ),
        );
      },
    );

    test('RevokeSession retains idempotency key in request headers', () async {
      String? recordedKey;
      String? recordedMethod;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            recordedKey = options.headers['Idempotency-Key'] as String?;
            recordedMethod = options.method;
            return handler.resolve(
              Response<void>(requestOptions: options, statusCode: 204),
            );
          },
        ),
      );

      final repository = MemoraSessionRepository(
        apiClient: apiClient,
        configuration: configuration,
      );

      const idempotencyKey = '0192e4a2-1111-7000-8000-000000000001';
      await repository.revokeSession(
        accessToken: 'valid_token',
        idempotencyKey: idempotencyKey,
      );

      expect(recordedKey, equals(idempotencyKey));
      expect(recordedMethod, equals('POST'));
    });
  });
}
