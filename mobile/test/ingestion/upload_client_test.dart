import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/ingestion/data/upload_client.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_failure.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_models.dart';

UploadSource _source({
  String name = 'notes.pdf',
  String mediaType = 'application/pdf',
  List<int>? bytes,
}) {
  return UploadSource(
    declaredName: name,
    declaredMediaType: mediaType,
    bytes: Uint8List.fromList(bytes ?? utf8.encode('hello')),
  );
}

UploadGrant _grant({
  String url = 'https://storage.memora.test/object',
  String method = 'PUT',
  Map<String, String>? headers,
  int maxBytes = 1024 * 1024,
  DateTime? expiresAt,
}) {
  return UploadGrant(
    uploadId: 'upload-1',
    url: url,
    method: method,
    requiredHeaders:
        headers ??
        <String, String>{
          'x-upload-token': 'signed',
          'content-type': 'application/pdf',
        },
    maxBytes: maxBytes,
    expiresAt: expiresAt ?? DateTime.utc(2030),
    checksumRule: 'SHA-256 hex digest of the exact uploaded bytes',
  );
}

Dio _countingDio(void Function(RequestOptions options)? onRequest) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest?.call(options);
        return handler.resolve(
          Response<Object?>(
            requestOptions: options,
            statusCode: 200,
            data: '',
          ),
        );
      },
    ),
  );
  return dio;
}

void main() {
  group('PresignedUploadClient.prepare', () {
    test('computes the exact byte size and SHA-256 digest', () async {
      final client = PresignedUploadClient();

      final prepared = await client.prepare(
        _source(bytes: utf8.encode('hello')),
      );
      final again = await client.prepare(_source(bytes: utf8.encode('hello')));

      expect(prepared.declaration.byteSize, 5);
      expect(
        prepared.declaration.contentSha256,
        '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
      );
      expect(
        again.declaration.contentSha256,
        prepared.declaration.contentSha256,
      );
      expect(prepared.declaration.declaredMediaType, 'application/pdf');
    });

    test('normalizes a path-like picker name to a basename', () async {
      final client = PresignedUploadClient();

      final prepared = await client.prepare(
        _source(name: r'C:\Users\student\notes.pdf'),
      );

      expect(prepared.declaration.declaredName, 'notes.pdf');
    });

    test('rejects an empty file before any network call', () async {
      var requests = 0;
      final client = PresignedUploadClient(
        transport: _countingDio((_) => requests++),
      );

      await expectLater(
        client.prepare(_source(bytes: const <int>[])),
        throwsA(
          isA<IngestionFailure>().having(
            (failure) => failure.code,
            'code',
            'empty_file',
          ),
        ),
      );
      expect(requests, 0);
    });

    test('rejects an unsupported declared media type', () async {
      final client = PresignedUploadClient();

      await expectLater(
        client.prepare(
          _source(name: 'archive.zip', mediaType: 'application/zip'),
        ),
        throwsA(
          isA<IngestionFailure>()
              .having(
                (failure) => failure.code,
                'code',
                'unsupported_media_type',
              )
              .having(
                (failure) => failure.nextAction,
                'nextAction',
                'Use a PDF, PNG, or JPEG file.',
              ),
        ),
      );
    });

    test('rejects a name whose extension does not match the media type', () async {
      final client = PresignedUploadClient();

      await expectLater(
        client.prepare(_source(name: 'notes.txt')),
        throwsA(
          isA<IngestionFailure>().having(
            (failure) => failure.code,
            'code',
            'unsupported_media_type',
          ),
        ),
      );
    });

    test('accepts JPEG aliases and strips media-type parameters', () async {
      final client = PresignedUploadClient();

      final jpg = await client.prepare(
        _source(
          name: 'photo.JPG',
          mediaType: 'image/jpeg; charset=binary',
        ),
      );
      final jpeg = await client.prepare(
        _source(name: 'photo.jpeg', mediaType: 'image/jpeg'),
      );

      expect(jpg.declaration.declaredMediaType, 'image/jpeg');
      expect(jpeg.declaration.declaredMediaType, 'image/jpeg');
    });
  });

  group('PresignedUploadClient.upload', () {
    test('PUTs to the grant URL with only the grant headers', () async {
      RequestOptions? captured;
      final client = PresignedUploadClient(
        transport: _countingDio((options) => captured = options),
      );
      final prepared = await client.prepare(_source());

      await client.upload(grant: _grant(), upload: prepared);

      expect(captured, isNotNull);
      expect(captured!.method, 'PUT');
      expect(captured!.uri.toString(), 'https://storage.memora.test/object');
      expect(captured!.headers['x-upload-token'], 'signed');
      expect(captured!.headers['content-type'], 'application/pdf');

      for (final forbidden in <String>[
        'Authorization',
        'X-Correlation-ID',
        'X-Client-Version',
        'X-Platform',
        'Idempotency-Key',
      ]) {
        expect(
          captured!.headers.containsKey(forbidden),
          isFalse,
          reason: '$forbidden must never leak to object storage',
        );
      }
    });

    test('reports byte progress through the request stream', () async {
      final adapter = _DrainingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final client = PresignedUploadClient(transport: dio);
      final prepared = await client.prepare(
        _source(bytes: List<int>.filled(4096, 7)),
      );
      final events = <int>[];

      await client.upload(
        grant: _grant(),
        upload: prepared,
        onProgress: (sent, total) {
          expect(total, 4096);
          events.add(sent);
        },
      );

      expect(adapter.received, 4096);
      expect(events, isNotEmpty);
      expect(events.last, 4096);
    });

    test('rejects an expired grant before any network call', () async {
      var requests = 0;
      final client = PresignedUploadClient(
        transport: _countingDio((_) => requests++),
        clock: () => DateTime.utc(2030, 1, 1),
      );
      final prepared = await client.prepare(_source());

      await expectLater(
        client.upload(
          grant: _grant(expiresAt: DateTime.utc(2029, 12, 31)),
          upload: prepared,
        ),
        throwsA(
          isA<IngestionFailure>()
              .having(
                (failure) => failure.code,
                'code',
                'upload_grant_expired',
              )
              .having((failure) => failure.retryable, 'retryable', isTrue),
        ),
      );
      expect(requests, 0);
    });

    test('rejects an oversize source before any network call', () async {
      var requests = 0;
      final client = PresignedUploadClient(
        transport: _countingDio((_) => requests++),
      );
      final prepared = await client.prepare(
        _source(bytes: List<int>.filled(8, 1)),
      );

      await expectLater(
        client.upload(grant: _grant(maxBytes: 4), upload: prepared),
        throwsA(
          isA<IngestionFailure>().having(
            (failure) => failure.code,
            'code',
            'payload_too_large',
          ),
        ),
      );
      expect(requests, 0);
    });

    test('rejects a non-PUT grant', () async {
      final client = PresignedUploadClient(transport: _countingDio(null));
      final prepared = await client.prepare(_source());

      await expectLater(
        client.upload(grant: _grant(method: 'POST'), upload: prepared),
        throwsA(
          isA<IngestionFailure>().having(
            (failure) => failure.code,
            'code',
            'upload_grant_invalid',
          ),
        ),
      );
    });

    test('rejects a non-HTTPS grant URL', () async {
      final client = PresignedUploadClient(transport: _countingDio(null));
      final prepared = await client.prepare(_source());

      await expectLater(
        client.upload(
          grant: _grant(url: 'http://storage.memora.test/object'),
          upload: prepared,
        ),
        throwsA(
          isA<IngestionFailure>().having(
            (failure) => failure.code,
            'code',
            'upload_grant_invalid',
          ),
        ),
      );
    });

    test('storage 403 maps to a re-grant failure', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response<Object?>(
                requestOptions: options,
                statusCode: 403,
              ),
            ),
          ),
        ),
      );
      final client = PresignedUploadClient(transport: dio);
      final prepared = await client.prepare(_source());

      await expectLater(
        client.upload(grant: _grant(), upload: prepared),
        throwsA(
          isA<IngestionFailure>().having(
            (failure) => failure.code,
            'code',
            'upload_grant_expired',
          ),
        ),
      );
    });

    test('storage 413 maps to the payload-too-large failure', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response<Object?>(
                requestOptions: options,
                statusCode: 413,
              ),
            ),
          ),
        ),
      );
      final client = PresignedUploadClient(transport: dio);
      final prepared = await client.prepare(_source());

      await expectLater(
        client.upload(grant: _grant(), upload: prepared),
        throwsA(
          isA<IngestionFailure>().having(
            (failure) => failure.code,
            'code',
            'payload_too_large',
          ),
        ),
      );
    });

    test('transport failure maps to a retryable network failure', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          ),
        ),
      );
      final client = PresignedUploadClient(transport: dio);
      final prepared = await client.prepare(_source());

      await expectLater(
        client.upload(grant: _grant(), upload: prepared),
        throwsA(
          isA<IngestionFailure>()
              .having((failure) => failure.code, 'code', 'network_error')
              .having((failure) => failure.retryable, 'retryable', isTrue),
        ),
      );
    });
  });
}

class _DrainingAdapter implements HttpClientAdapter {
  int received = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        received += chunk.length;
      }
    }
    return ResponseBody.fromString(
      '',
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['text/plain'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
