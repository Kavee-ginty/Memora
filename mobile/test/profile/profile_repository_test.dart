import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_api_client/memora_api_client.dart';
import 'package:memora_mobile/src/configuration/app_configuration.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/profile/data/profile_repository.dart';
import 'package:memora_mobile/src/features/profile/domain/profile_settings.dart';

import 'profile_fixtures.dart';

void main() {
  late Dio dio;
  late MemoraProfileRepository repository;
  late List<RequestOptions> calls;
  late ({int status, Map<String, Object?> data}) Function(RequestOptions)
  respond;
  late int refreshes;
  const access = (
    session: AuthSession(accessToken: 'test-token', userId: 'provider-owner'),
    owner: 'app-owner',
  );
  const profile = <String, Object?>{
    'user_id': 'app-owner',
    'display_name': 'Amani Perera',
    'locale': 'en-LK',
    'timezone': 'Asia/Colombo',
    'active_subject_id': null,
    'curriculum_version_id': null,
    'version': 1,
  };
  const preferences = <String, Object?>{
    'accessibility': {'schema_version': '1', 'sound_enabled': false},
    'lock_screen_detail': 'minimal',
    'max_daily_reminders': 1,
    'notifications_enabled': false,
    'mission_enabled': true,
    'reward_enabled': true,
    'streak_enabled': true,
    'timezone': 'Asia/Colombo',
    'version': 2,
    'quiet_start_local': '22:00:00',
    'quiet_end_local': '07:00:00',
    'preferred_window_start_local': null,
    'preferred_window_end_local': null,
  };
  Map<String, Object?> error(String code) => {
    'error': {
      'code': code,
      'message': 'private-token-should-never-appear',
      'request_id': 'test-request',
      'retryable': false,
      'field_errors': [
        {'field': 'timezone', 'code': 'invalid', 'message': 'private-value'},
      ],
      'retry_after_seconds': null,
    },
  };

  setUp(() {
    calls = [];
    refreshes = 0;
    respond = (request) => (
      status: 200,
      data: request.path.endsWith('/preferences') ? preferences : profile,
    );
    dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          calls.add(options);
          final reply = respond(options);
          final response = Response(
            requestOptions: options,
            statusCode: reply.status,
            data: reply.data,
          );
          if (reply.status >= 400) {
            handler.reject(
              DioException.badResponse(
                statusCode: reply.status,
                requestOptions: options,
                response: response,
              ),
            );
          } else {
            handler.resolve(response);
          }
        },
      ),
    );
    repository = MemoraProfileRepository(
      MemoraApiClient(dio: dio, interceptors: const []).getProfileApi(),
      AppConfiguration.fromEnvironment(),
      (_) async {
        refreshes++;
        return const AuthSession(
          accessToken: 'test-refreshed',
          userId: 'provider-owner',
        );
      },
    );
  });
  tearDown(() => dio.close());

  test(
    'loads generated profile and preferences with scoped bearer credentials',
    () async {
      final result = await repository.load(access);
      expect(result.profile.fields, profileFields);
      expect(result.preferences.fields.notifications, notificationFields);
      expect(result.preferences.fields.accessibility.soundEnabled, isFalse);
      expect(calls.map((request) => request.path), [
        '/v1/profile',
        '/v1/profile/preferences',
      ]);
      expect(
        calls.every(
          (request) => request.headers['Authorization'] == 'Bearer test-token',
        ),
        isTrue,
      );
    },
  );

  test('wrong owner response is rejected before loading preferences', () async {
    respond = (_) => (status: 200, data: {...profile, 'user_id': 'other-user'});
    await expectLater(repository.load(access), throwsA(isA<ProfileFailure>()));
    expect(calls, hasLength(1));
  });

  test(
    'profile PATCH sends only the edited fields, version and idempotency key',
    () async {
      await repository.saveProfile(access, confirmedSettings.profile, (
        displayName: 'Updated name',
        locale: 'en-LK',
        timezone: 'Asia/Colombo',
      ), 'logical-key');
      expect(calls.single.method, 'PATCH');
      expect(calls.single.headers['Idempotency-Key'], 'logical-key');
      expect(calls.single.data, {'version': 1, 'display_name': 'Updated name'});
    },
  );

  test('clearing quiet hours sends explicit nulls for both ends and omits other fields', () async {
    const next = (
      enabled: false,
      mission: true,
      reward: true,
      streak: true,
      quiet: null,
      preferred: null,
      timezone: 'Asia/Colombo',
      preview: PreviewDetail.minimal,
      dailyLimit: 1,
    );
    await repository.savePreferences(access, confirmedSettings.preferences, (
      notifications: next,
      accessibility: accessibilityFields,
    ), 'settings-key');
    expect(calls.single.data, {
      'version': 1,
      'quiet_start_local': null,
      'quiet_end_local': null,
    });
    expect(calls.single.headers['Idempotency-Key'], 'settings-key');
  });

  test('401 refreshes once and repeats the same idempotent request', () async {
    respond = (request) =>
        request.headers['Authorization'] == 'Bearer test-token'
        ? (status: 401, data: error('token_expired'))
        : (status: 200, data: profile);
    await repository.saveProfile(access, confirmedSettings.profile, (
      displayName: 'Updated name',
      locale: 'en-LK',
      timezone: 'Asia/Colombo',
    ), 'same-operation');
    expect(refreshes, 1);
    expect(calls, hasLength(2));
    expect(calls.first.data, calls.last.data);
    expect(calls.map((call) => call.headers['Idempotency-Key']), [
      'same-operation',
      'same-operation',
    ]);
  });

  test(
    'maps field errors and version conflicts without exposing server text',
    () async {
      for (final entry in {
        422: 'validation_failed',
        409: 'version_conflict',
      }.entries) {
        respond = (_) => (status: entry.key, data: error(entry.value));
        await expectLater(
          repository.load(access),
          throwsA(
            isA<ProfileFailure>()
                .having((failure) => failure.code, 'code', entry.value)
                .having(
                  (failure) => failure.fields,
                  'fields',
                  contains('timezone'),
                )
                .having(
                  (failure) => failure.message,
                  'message',
                  isNot(contains('private-token')),
                ),
          ),
        );
      }
    },
  );
}
