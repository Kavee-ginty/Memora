import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_api_client/memora_api_client.dart';
import 'package:memora_mobile/src/configuration/app_configuration.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/consent/data/consent_repository.dart';
import 'package:memora_mobile/src/features/consent/domain/consent_policy.dart';

Map<String, dynamic> _errorEnvelope(String code) {
  return <String, dynamic>{
    'error': <String, dynamic>{
      'code': code,
      'message': 'Raw server text must never reach the UI.',
      'request_id': 'req_1',
      'retryable': false,
      'field_errors': <Map<String, dynamic>>[],
    },
  };
}

Map<String, dynamic> _consentResponse() {
  return <String, dynamic>{
    'policies': <Map<String, dynamic>>[
      <String, dynamic>{
        'policy_id': 'terms',
        'policy_version': '2026-10-01',
        'required': true,
        'is_current': false,
      },
      <String, dynamic>{
        'policy_id': 'privacy',
        'policy_version': '2026-09-15',
        'required': false,
        'is_current': true,
        'decision': 'granted',
        'decided_at': '2026-09-16T08:00:00Z',
      },
    ],
  };
}

Map<String, dynamic> _acceptanceResponse() {
  return <String, dynamic>{
    'id': 'cns_1',
    'policy_id': 'terms',
    'policy_version': '2026-10-01',
    'decision': 'granted',
    'accepted_scopes': <String>['terms'],
    'decided_at': '2026-10-28T12:00:00Z',
  };
}

void main() {
  group('MemoraConsentRepository contract mapping', () {
    late Dio dio;
    late MemoraApiClient apiClient;
    late MemoraConsentRepository repository;

    const configuration = AppConfiguration(
      supabaseUrl: 'https://test.supabase.co',
      supabasePublishableKey: 'test-key',
      apiBaseUrl: 'http://127.0.0.1:8000',
      oauthRedirectUri: 'com.kaveeginty.memora://login-callback',
      clientVersion: '0.1.0',
      platform: 'android',
    );

    setUp(() {
      dio = Dio();
      apiClient = MemoraApiClient(dio: dio);
      repository = MemoraConsentRepository(
        apiClient: apiClient,
        configuration: configuration,
      );
    });

    test(
      'GET attaches bearer and metadata headers and maps policies',
      () async {
        String? recordedAuth;
        String? recordedCorrelation;
        String? recordedVersion;
        String? recordedPlatform;
        String? recordedMethod;
        String? recordedPath;

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              recordedMethod = options.method;
              recordedPath = options.path;
              recordedAuth = options.headers['Authorization'] as String?;
              recordedCorrelation =
                  options.headers['X-Correlation-ID'] as String?;
              recordedVersion = options.headers['X-Client-Version'] as String?;
              recordedPlatform = options.headers['X-Platform'] as String?;
              return handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: _consentResponse(),
                ),
              );
            },
          ),
        );

        final policies = await repository.fetchConsent(
          accessToken: 'token_xyz_123',
        );

        expect(recordedMethod, 'GET');
        expect(recordedPath, '/v1/consent');
        expect(recordedAuth, 'Bearer token_xyz_123');
        expect(recordedCorrelation, isNotEmpty);
        expect(recordedVersion, '0.1.0');
        expect(recordedPlatform, 'android');

        expect(policies, hasLength(2));
        final terms = policies.first;
        expect(terms.kind, ConsentPolicyKind.terms);
        expect(terms.wireId, 'terms');
        expect(terms.label, 'Terms of Use');
        expect(terms.version, '2026-10-01');
        expect(terms.isRequired, isTrue);
        expect(terms.isCurrent, isFalse);
        expect(terms.decision, isNull);
        expect(terms.requiresAction, isTrue);

        final privacy = policies.last;
        expect(privacy.kind, ConsentPolicyKind.privacy);
        expect(privacy.decision, 'granted');
        expect(privacy.requiresAction, isFalse);
      },
    );

    test(
      'Unknown policy wire identifiers map to a non-acceptable kind',
      () async {
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              return handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: <String, dynamic>{
                    'policies': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'policy_id': 'future_policy',
                        'policy_version': '2027-01-01',
                        'required': true,
                        'is_current': false,
                      },
                    ],
                  },
                ),
              );
            },
          ),
        );

        final policies = await repository.fetchConsent(accessToken: 'token');

        expect(policies, hasLength(1));
        expect(policies.single.isKnown, isFalse);
        expect(policies.single.kind, ConsentPolicyKind.unknown);
        expect(policies.single.requiresAction, isTrue);
      },
    );

    test(
      'POST sends accepted scopes, wire policy id and idempotency key',
      () async {
        Map<String, dynamic>? recordedBody;
        String? recordedKey;
        String? recordedAuth;
        String? recordedPath;

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              recordedBody = Map<String, dynamic>.from(
                options.data as Map<dynamic, dynamic>,
              );
              recordedKey = options.headers['Idempotency-Key'] as String?;
              recordedAuth = options.headers['Authorization'] as String?;
              recordedPath = options.path;
              return handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 201,
                  data: _acceptanceResponse(),
                ),
              );
            },
          ),
        );

        const idempotencyKey = '0192e4a2-1111-7000-8000-000000000001';
        await repository.acceptConsent(
          accessToken: 'token_xyz_123',
          kind: ConsentPolicyKind.materialProcessing,
          wireId: 'material_processing',
          policyVersion: '2026-10-01',
          idempotencyKey: idempotencyKey,
        );

        expect(recordedPath, '/v1/consent/acceptances');
        expect(recordedAuth, 'Bearer token_xyz_123');
        expect(recordedKey, idempotencyKey);
        expect(recordedBody, isNotNull);
        expect(recordedBody!['accepted_scopes'], <String>[
          'material_processing',
        ]);
        expect(recordedBody!['policy_id'], 'material_processing');
        expect(recordedBody!['policy_version'], '2026-10-01');
      },
    );

    test('Unknown policy kinds are never sent to the server', () async {
      var requestCount = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestCount++;
            return handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 201,
                data: _acceptanceResponse(),
              ),
            );
          },
        ),
      );

      await expectLater(
        repository.acceptConsent(
          accessToken: 'token',
          kind: ConsentPolicyKind.unknown,
          wireId: 'future_policy',
          policyVersion: '2027-01-01',
          idempotencyKey: 'key',
        ),
        throwsA(isA<AuthFailure>()),
      );
      expect(requestCount, 0);
    });

    test('409 version_conflict maps to the stable failure code', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 409,
                  data: _errorEnvelope('version_conflict'),
                ),
              ),
            );
          },
        ),
      );

      await expectLater(
        repository.acceptConsent(
          accessToken: 'token',
          kind: ConsentPolicyKind.terms,
          wireId: 'terms',
          policyVersion: '2026-10-01',
          idempotencyKey: 'key',
        ),
        throwsA(
          isA<AuthFailure>()
              .having((f) => f.code, 'code', 'version_conflict')
              .having(
                (f) => f.message,
                'message',
                isNot(contains('Raw server text')),
              ),
        ),
      );
    });

    test('401 without an envelope maps to expired_session', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<void>(
                  requestOptions: options,
                  statusCode: 401,
                ),
              ),
            );
          },
        ),
      );

      await expectLater(
        repository.fetchConsent(accessToken: 'expired'),
        throwsA(
          isA<AuthFailure>().having((f) => f.code, 'code', 'expired_session'),
        ),
      );
    });
  });
}
