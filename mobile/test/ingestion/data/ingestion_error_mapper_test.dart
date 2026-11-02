import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_api_client/memora_api_client.dart';
import 'package:memora_mobile/src/features/ingestion/data/ingestion_error_mapper.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_failure.dart';

Map<String, dynamic> envelope(
  String code, {
  String message = 'Server supplied message',
  bool retryable = false,
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
    },
  };
}

DioException dioError({
  int? statusCode,
  Object? data,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final options = RequestOptions(path: '/v1/learning-updates');
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
  group('Update failure code mapping (API §11.3)', () {
    const retryableCodes = <String>{
      'deletion_failed',
      'extraction_failed',
      'extraction_unavailable',
      'internal_error',
      'source_unavailable',
    };
    const nonRetryableCodes = <String>{
      'cancelled',
      'no_extractable_content',
      'payload_too_large',
      'unsupported_media_type',
      'validation_failed',
    };

    test('Every contracted failure code maps to approved copy with a next action',
        () {
      for (final code in <String>{...retryableCodes, ...nonRetryableCodes}) {
        final failure = IngestionFailure.fromUpdateCode(code);

        expect(failure.code, equals(code), reason: 'code preserved for $code');
        expect(failure.message, isNotEmpty, reason: 'message present for $code');
        // UIX-021: raw codes never appear in student-facing copy.
        expect(
          failure.message.contains('_'),
          isFalse,
          reason: 'no raw code in copy for $code',
        );
        expect(
          failure.nextAction,
          isNotEmpty,
          reason: 'next action present for $code',
        );
      }
    });

    test('Retry eligibility follows the failure taxonomy', () {
      for (final code in retryableCodes) {
        expect(
          IngestionFailure.fromUpdateCode(code).retryable,
          isTrue,
          reason: '$code is retryable',
        );
      }
      for (final code in nonRetryableCodes) {
        expect(
          IngestionFailure.fromUpdateCode(code).retryable,
          isFalse,
          reason: '$code is not retryable',
        );
      }
    });

    test('Unknown and null codes collapse to safe generic copy', () {
      for (final code in <String?>{null, 'mystery_failure', 'extraction_v2_failed'}) {
        final failure = IngestionFailure.fromUpdateCode(code);

        expect(
          failure.message,
          equals('Something went wrong while processing this material.'),
        );
        expect(failure.message, isNot(contains('mystery_failure')));
        expect(failure.retryable, isTrue);
      }
      expect(
        IngestionFailure.fromUpdateCode('mystery_failure').code,
        equals('mystery_failure'),
        reason: 'the code itself stays available for diagnostics',
      );
    });
  });

  group('Transport error mapping', () {
    test('Maps a valid generated envelope to the allowlisted domain failure', () {
      final failure = mapDioExceptionToIngestionFailure(
        dioError(statusCode: 409, data: envelope('version_conflict')),
      );

      expect(failure.code, equals('version_conflict'));
      expect(failure.retryable, isFalse);
      expect(failure.message, equals('This information has changed. Please review it again.'));
      expect(failure.nextAction, isNotEmpty);
      expect(failure.message, isNot(contains('Server supplied message')));
    });

    test('Ignores additive unknown JSON fields safely', () {
      final failure = mapDioExceptionToIngestionFailure(
        dioError(
          statusCode: 409,
          data: <String, dynamic>{
            'unexpected_top_level': <String, dynamic>{'a': 1},
            'error': <String, dynamic>{
              ...envelope('version_conflict')['error']! as Map<String, dynamic>,
              'additive_field': 'ignored',
              'future_metadata': <String, dynamic>{'b': 2},
            },
          },
        ),
      );

      expect(failure.code, equals('version_conflict'));
    });

    test('Retryable contract codes set the retryable flag', () {
      for (final code in <String>{
        'temporarily_unavailable',
        'rate_limited',
        'operation_in_progress',
      }) {
        expect(
          mapDioExceptionToIngestionFailure(
            dioError(statusCode: 503, data: envelope(code)),
          ).retryable,
          isTrue,
          reason: '$code is retryable',
        );
      }
    });

    test('Unknown envelope codes stay generic and never echo server text', () {
      final failure = mapDioExceptionToIngestionFailure(
        dioError(statusCode: 422, data: envelope('brand_new_code')),
      );

      expect(failure.code, equals('unknown'));
      expect(failure.message, isNot(contains('brand_new_code')));
      expect(failure.message, isNot(contains('Server supplied message')));
    });

    test('Session codes and 401 responses map to expired session', () {
      for (final code in <String>{'token_missing', 'token_invalid', 'token_expired'}) {
        expect(
          mapDioExceptionToIngestionFailure(
            dioError(statusCode: 401, data: envelope(code)),
          ).code,
          equals('expired_session'),
          reason: '$code expires the session',
        );
      }

      expect(
        mapDioExceptionToIngestionFailure(dioError(statusCode: 401)).code,
        equals('expired_session'),
      );
    });

    test('Connection failures map to the offline failure', () {
      for (final type in <DioExceptionType>{
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.connectionError,
      }) {
        final failure = mapDioExceptionToIngestionFailure(
          dioError(type: type),
        );

        expect(failure.code, equals('network_error'), reason: '$type is offline');
        expect(failure.retryable, isTrue);
        expect(failure.nextAction, isNotEmpty);
      }
    });

    test('Non-envelope responses collapse to the unknown failure', () {
      final failure = mapDioExceptionToIngestionFailure(
        dioError(statusCode: 500, data: 'not an envelope'),
      );

      expect(failure.code, equals('unknown'));
      expect(failure.message, isNot(contains('not an envelope')));
    });
  });

  group('Update failure code mapper entry point', () {
    test('Delegates to the domain factory', () {
      final failure = mapUpdateFailureCode('no_extractable_content');

      expect(failure.code, equals('no_extractable_content'));
      expect(failure.retryable, isFalse);
      expect(failure.nextAction, isNotEmpty);
    });
  });
}
