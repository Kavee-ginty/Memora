import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../domain/ingestion_failure.dart';
import '../domain/ingestion_models.dart';

/// Bytes selected by the student for one temporary upload.
///
/// The bytes live only in memory for the duration of the upload attempt. They
/// are never written to the draft store, a long-lived cache or a log (D5/D8).
@immutable
class UploadSource {
  final String declaredName;
  final String declaredMediaType;
  final Uint8List bytes;

  const UploadSource({
    required this.declaredName,
    required this.declaredMediaType,
    required this.bytes,
  });

  int get byteSize => bytes.length;
}

/// A source whose exact size and SHA-256 digest have been computed.
///
/// Only [UploadClient.prepare] creates this type so the declaration always
/// matches the bytes that will be uploaded.
@immutable
class PreparedUpload {
  final UploadSource source;
  final DeclaredSource declaration;

  const PreparedUpload._({required this.source, required this.declaration});
}

/// Uploads bytes to a short-lived presigned object-storage URL.
///
/// This transport is deliberately separate from the API client: it carries no
/// bearer token, correlation header, client version, platform or idempotency
/// key. The only request headers are the ones the grant requires (D5).
abstract class UploadClient {
  /// Validates one source and computes its exact size and SHA-256 digest.
  ///
  /// Empty files and unsupported declared types/extensions are rejected before
  /// any network call so the create request is never sent for them.
  Future<PreparedUpload> prepare(UploadSource source);

  /// Uploads [upload] to [grant], reporting byte progress to [onProgress].
  ///
  /// The grant is checked for method, scheme and expiry before the request.
  /// Storage-side 401/403/409 responses map to a re-grant failure rather than
  /// a generic error (Flow §9.3).
  Future<void> upload({
    required UploadGrant grant,
    required PreparedUpload upload,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  });
}

/// Dedicated presigned-URL transport with no API interceptors or auth state.
class PresignedUploadClient implements UploadClient {
  PresignedUploadClient({Dio? transport, DateTime Function()? clock})
    : _dio =
          transport ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(minutes: 5),
              receiveTimeout: const Duration(seconds: 30),
              followRedirects: false,
            ),
          ),
      _clock = clock ?? DateTime.now;

  final Dio _dio;
  final DateTime Function() _clock;

  @override
  Future<PreparedUpload> prepare(UploadSource source) async {
    if (source.bytes.isEmpty) throw _emptyFile();

    final mediaType = source.declaredMediaType
        .split(';')
        .first
        .trim()
        .toLowerCase();
    final allowedExtensions = _supportedExtensions[mediaType];
    if (allowedExtensions == null) throw _unsupportedType();

    final name = _basename(source.declaredName);
    final lowerName = name.toLowerCase();
    if (!allowedExtensions.any(lowerName.endsWith)) {
      throw _unsupportedType();
    }

    return PreparedUpload._(
      source: source,
      declaration: DeclaredSource(
        declaredName: name,
        declaredMediaType: mediaType,
        byteSize: source.bytes.length,
        contentSha256: _sha256Hex(source.bytes),
      ),
    );
  }

  @override
  Future<void> upload({
    required UploadGrant grant,
    required PreparedUpload upload,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    _validateGrant(grant, upload);

    try {
      await _dio.put<Object?>(
        grant.url,
        data: upload.source.bytes,
        cancelToken: cancelToken,
        onSendProgress: onProgress,
        options: Options(
          method: 'PUT',
          headers: Map<String, dynamic>.of(grant.requiredHeaders),
          followRedirects: false,
          responseType: ResponseType.plain,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
      );
    } on DioException catch (error) {
      throw _mapStorageFailure(error);
    } on IngestionFailure {
      rethrow;
    } catch (_) {
      throw IngestionFailure.unknown();
    }
  }

  void _validateGrant(UploadGrant grant, PreparedUpload upload) {
    if (grant.method.toUpperCase() != 'PUT') throw _invalidGrant();

    final uri = Uri.tryParse(grant.url);
    if (uri == null || !uri.isScheme('https')) throw _invalidGrant();

    final expiresAt = grant.expiresAt;
    if (expiresAt == null || !expiresAt.isAfter(_clock().toUtc())) {
      throw _grantExpired();
    }

    if (upload.source.bytes.isEmpty) throw _emptyFile();
    if (upload.source.byteSize > grant.maxBytes) throw _payloadTooLarge();
    if (upload.declaration.byteSize != upload.source.byteSize) {
      throw IngestionFailure.unknown();
    }
  }

  IngestionFailure _mapStorageFailure(DioException error) {
    final status = error.response?.statusCode;

    if (status == 401 || status == 403 || status == 409) {
      return _grantExpired();
    }
    if (status == 413) return _payloadTooLarge();
    if (status == 415) return _unsupportedType();

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return IngestionFailure.network();
    }

    return IngestionFailure.unknown();
  }

  String _sha256Hex(Uint8List bytes) {
    final collector = _DigestCollector();
    final input = sha256.startChunkedConversion(collector);
    const chunkSize = 64 * 1024;

    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = offset + chunkSize < bytes.length
          ? offset + chunkSize
          : bytes.length;
      input.add(Uint8List.sublistView(bytes, offset, end));
    }
    input.close();

    final digest = collector.value;
    if (digest == null) throw IngestionFailure.unknown();
    return digest.toString();
  }

  String _basename(String name) {
    final normalized = name.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index < 0 ? normalized : normalized.substring(index + 1);
  }
}

const Map<String, List<String>> _supportedExtensions = <String, List<String>>{
  'application/pdf': <String>['.pdf'],
  'image/png': <String>['.png'],
  'image/jpeg': <String>['.jpg', '.jpeg'],
};

const IngestionFailure _emptyFileFailure = IngestionFailure(
  code: 'empty_file',
  message: 'That file is empty.',
  nextAction: 'Choose a different file.',
);

const IngestionFailure _unsupportedTypeFailure = IngestionFailure(
  code: 'unsupported_media_type',
  message: 'That file type is not supported.',
  nextAction: 'Use a PDF, PNG, or JPEG file.',
);

const IngestionFailure _payloadTooLargeFailure = IngestionFailure(
  code: 'payload_too_large',
  message: 'That file is larger than Memora can process.',
  nextAction: 'Choose a smaller file and try again.',
);

const IngestionFailure _grantExpiredFailure = IngestionFailure(
  code: 'upload_grant_expired',
  message: 'That upload link expired before the file finished.',
  nextAction: 'Request a new upload link and try again.',
  retryable: true,
);

const IngestionFailure _invalidGrantFailure = IngestionFailure(
  code: 'upload_grant_invalid',
  message: 'The upload link could not be used.',
  nextAction: 'Try again.',
  retryable: true,
);

IngestionFailure _emptyFile() => _emptyFileFailure;
IngestionFailure _unsupportedType() => _unsupportedTypeFailure;
IngestionFailure _payloadTooLarge() => _payloadTooLargeFailure;
IngestionFailure _grantExpired() => _grantExpiredFailure;
IngestionFailure _invalidGrant() => _invalidGrantFailure;

class _DigestCollector implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}
