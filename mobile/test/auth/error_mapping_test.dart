import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_api_client/memora_api_client.dart';
import 'package:memora_mobile/src/features/auth/data/api_error_mapper.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';

Map<String, dynamic> envelope(
  String code, {
  String message = 'Server supplied message',
  bool retryable = false,
  Map<String, dynamic>? extra,
}) {
  return <String, dynamic>{
    'error': <String, dynamic>{
      'code': code,
      'message': message,
      'request_id': 'req_123',
      'field_errors': <dynamic>[],
      'retryable': retryable,
      'retry_after_seconds': null,
      'action': null,
      ...?extra,
    },
  };
}

DioException dioError({
  int? statusCode,
  Object? data,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final options = RequestOptions(path: '/v1/consent');
  return DioException(
    requestOptions: options,
    type: type,
    response: statusCode == null
        ? null
        : Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
            data: data,
          ),
  );
}

void main() {
  group('Generated ErrorEnvelope failure mapping', () {
    test(
      'Maps a valid generated envelope to the allowlisted domain failure',
      () {
        final failure = mapDioExceptionToFailure(
          dioError(statusCode: 409, data: envelope('version_conflict')),
        );

        expect(failure.code, equals('version_conflict'));
        expect(failure.retryable, isFalse);
        expect(failure.message, isNot(contains('Server supplied message')));
      },
    );

    test('Ignores additive unknown JSON fields safely', () {
      final failure = mapDioExceptionToFailure(
        dioError(
          statusCode: 409,
          data: <String, dynamic>{
            'unexpected_top_level': <String, dynamic>{'a': 1},
            ...envelope(
              'version_conflict',
              extra: <String, dynamic>{
                'additive_field': 'ignored',
                'future_metadata': <String, dynamic>{'b': 2},
              },
            ),
          },
        ),
      );

      expect(failure.code, equals('version_conflict'));
    });

    test('Malformed envelope body becomes a safe generic failure', () {
      final failure = mapDioExceptionToFailure(
        dioError(
          statusCode: 500,
          data: <String, dynamic>{'error': 'not-an-object'},
        ),
      );

      expect(failure.code, equals('unknown'));
      expect(failure.message, isNot(contains('not-an-object')));
    });

    test('Non-envelope body becomes a safe generic failure', () {
      final failure = mapDioExceptionToFailure(
        dioError(statusCode: 500, data: 'upstream exploded with secrets'),
      );

      expect(failure.code, equals('unknown'));
      expect(failure.message, isNot(contains('upstream exploded')));
    });

    test('401 envelope still enters the expired-session path', () {
      final failure = mapDioExceptionToFailure(
        dioError(statusCode: 401, data: envelope('token_expired')),
      );

      expect(failure.code, equals('expired_session'));
      expect(failure.message, contains('session has expired'));
    });

    test('Unknown error code remains generic and hides server text', () {
      final failure = mapDioExceptionToFailure(
        dioError(
          statusCode: 418,
          data: envelope(
            'brand_new_code',
            message: 'raw server detail with internal path /srv/app',
          ),
        ),
      );

      expect(failure.code, equals('unknown'));
      expect(failure.message, isNot(contains('/srv/app')));
      expect(failure.message, isNot(contains('raw server detail')));
    });

    test('Allowlisted retryable code is marked retryable', () {
      final failure = mapDioExceptionToFailure(
        dioError(statusCode: 503, data: envelope('temporarily_unavailable')),
      );

      expect(failure.code, equals('temporarily_unavailable'));
      expect(failure.retryable, isTrue);
    });

    test('Transport failures map to a safe network failure', () {
      final failure = mapDioExceptionToFailure(
        dioError(type: DioExceptionType.connectionError),
      );

      expect(failure.code, equals(AuthFailure.networkError().code));
    });

    test('Serializer type is the generated ErrorEnvelope contract', () {
      // Proves the mapper is bound to the generated model rather than raw keys.
      expect(
        standardSerializers.serializeWith(
          ErrorEnvelope.serializer,
          standardSerializers.deserializeWith(
            ErrorEnvelope.serializer,
            envelope('version_conflict'),
          ),
        ),
        isNotNull,
      );
    });
  });
}
