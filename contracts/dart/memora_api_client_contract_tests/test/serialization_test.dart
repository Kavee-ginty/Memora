import 'dart:convert';

import 'package:memora_api_client/memora_api_client.dart';
import 'package:test/test.dart';

Map<String, dynamic> _documentedErrorExample() => <String, dynamic>{
      'error': <String, dynamic>{
        'action': 'correct_input',
        'code': 'validation_failed',
        'field_errors': <dynamic>[
          <String, dynamic>{
            'code': 'invalid_time',
            'field': 'preferred_time',
            'message': 'Enter a valid local time.',
          },
        ],
        'message': 'Check the highlighted fields and try again.',
        'request_id': '01J0000000000000000000000',
        'retry_after_seconds': null,
        'retryable': false,
      },
    };

Map<String, dynamic> _encode(Object? value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

void main() {
  group('ErrorEnvelope', () {
    test('deserializes the documented example', () {
      final envelope = standardSerializers.deserializeWith(
        ErrorEnvelope.serializer,
        _documentedErrorExample(),
      )!;

      expect(envelope.error.code, 'validation_failed');
      expect(envelope.error.action, 'correct_input');
      expect(envelope.error.message,
          'Check the highlighted fields and try again.');
      expect(envelope.error.requestId, '01J0000000000000000000000');
      expect(envelope.error.retryAfterSeconds, isNull);
      expect(envelope.error.retryable, isFalse);
      expect(envelope.error.fieldErrors, hasLength(1));
      expect(envelope.error.fieldErrors.single.field, 'preferred_time');
      expect(envelope.error.fieldErrors.single.code, 'invalid_time');
      expect(
        envelope.error.fieldErrors.single.message,
        'Enter a valid local time.',
      );

      expect(
        _encode(standardSerializers.serializeWith(
          ErrorEnvelope.serializer,
          envelope,
        )),
        equals(_documentedErrorExample()),
      );
    });

    test('ignores unknown additive fields in the envelope and error', () {
      final payload = _documentedErrorExample();
      payload['future_envelope_field'] = <String, dynamic>{'added': true};
      final detail = payload['error']! as Map<String, dynamic>;
      detail['future_error_field'] = 'ignored';

      final envelope = standardSerializers.deserializeWith(
        ErrorEnvelope.serializer,
        payload,
      )!;

      expect(envelope.error.code, 'validation_failed');
      expect(envelope.error.fieldErrors.single.field, 'preferred_time');
    });
  });

  group('PageMeta', () {
    test('deserializes a terminal page with a null cursor', () {
      final meta = standardSerializers.deserializeWith(
        PageMeta.serializer,
        <String, dynamic>{'has_more': false, 'next_cursor': null},
      )!;

      expect(meta.hasMore, isFalse);
      expect(meta.nextCursor, isNull);
      expect(
        _encode(standardSerializers.serializeWith(PageMeta.serializer, meta)),
        equals(<String, dynamic>{'has_more': false, 'next_cursor': null}),
      );
    });

    test('deserializes a continued page with a cursor', () {
      final meta = standardSerializers.deserializeWith(
        PageMeta.serializer,
        <String, dynamic>{'has_more': true, 'next_cursor': 'cursor-2'},
      )!;

      expect(meta.hasMore, isTrue);
      expect(meta.nextCursor, 'cursor-2');
      expect(
        _encode(standardSerializers.serializeWith(PageMeta.serializer, meta)),
        equals(<String, dynamic>{'has_more': true, 'next_cursor': 'cursor-2'}),
      );
    });
  });

  test('AsyncOperation round-trips a UTC timestamp', () {
    const resourceId = '00000000-0000-4000-8000-000000000001';
    final operation = standardSerializers.deserializeWith(
      AsyncOperation.serializer,
      <String, dynamic>{
        'resource_id': resourceId,
        'retry_after_seconds': null,
        'status': 'processing',
        'status_url': '/v1/learning-updates/$resourceId',
        'updated_at': '2026-01-02T03:04:05Z',
      },
    )!;

    expect(operation.updatedAt.isUtc, isTrue);
    expect(operation.updatedAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
    expect(operation.retryAfterSeconds, isNull);

    final encoded = _encode(
      standardSerializers.serializeWith(AsyncOperation.serializer, operation),
    );
    final updatedAt = encoded['updated_at'] as String;

    expect(updatedAt.endsWith('Z'), isTrue);
    expect(DateTime.parse(updatedAt), DateTime.utc(2026, 1, 2, 3, 4, 5));
  });

  group('Optional', () {
    test('omits an absent value', () {
      final response = HealthResponse();

      expect(response.status.isPresent, isFalse);
      expect(
        _encode(standardSerializers.serializeWith(
          HealthResponse.serializer,
          response,
        )),
        isEmpty,
      );
    });

    test('preserves a present null value', () {
      final response = HealthResponse(
        (builder) => builder.status = const Optional.present(null),
      );

      expect(response.status.isPresent, isTrue);
      expect(response.status.value, isNull);
      expect(
        _encode(standardSerializers.serializeWith(
          HealthResponse.serializer,
          response,
        )),
        equals(<String, dynamic>{'status': null}),
      );
    });

    test('round-trips a present value', () {
      final response = HealthResponse(
        (builder) => builder.status = const Optional.present('ok'),
      );
      final encoded = _encode(
        standardSerializers.serializeWith(HealthResponse.serializer, response),
      );
      final decoded = standardSerializers.deserializeWith(
        HealthResponse.serializer,
        encoded,
      )!;

      expect(encoded, equals(<String, dynamic>{'status': 'ok'}));
      expect(decoded.status.isPresent, isTrue);
      expect(decoded.status.value, 'ok');
    });
  });
}
