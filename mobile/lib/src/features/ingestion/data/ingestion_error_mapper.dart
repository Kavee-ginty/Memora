import 'package:dio/dio.dart';
import 'package:memora_api_client/memora_api_client.dart';

import '../domain/ingestion_failure.dart';

/// Approved, non-sensitive copy for allowlisted contract error codes that
/// ingestion operations can surface.
///
/// The server `message` field is intentionally ignored: clients branch on the
/// stable `code`, and unknown codes must never surface raw server text.
/// Overlapping codes reuse the approved copy from the auth mapper so product
/// voice stays consistent across features.
const Map<String, String> _contractMessages = <String, String>{
  'invalid_cursor': 'That request could not be completed. Please try again.',
  'invalid_state': 'That action is not available right now.',
  'malformed_request': 'That request could not be completed.',
  'consent_required': 'Review the current policies to continue.',
  'recent_authentication_required':
      'Please confirm your credentials to continue.',
  'operation_not_allowed': 'That action is not allowed for this account.',
  'resource_not_found': 'The requested item was not found.',
  'version_conflict': 'This information has changed. Please review it again.',
  'idempotency_key_reused': 'That request has already been completed.',
  'payload_too_large': 'That file is too large to use.',
  'unsupported_media_type': 'That file type is not supported.',
  'validation_failed': 'Please check the highlighted details and try again.',
  'rate_limited': 'Too many attempts. Please wait before trying again.',
  'temporarily_unavailable':
      'Memora is temporarily unavailable. Please try again shortly.',
  'operation_in_progress': 'That request is still processing. Please wait.',
};

/// Approved next-action copy for contract codes where the recovery step is not
/// obvious from the message alone.
const Map<String, String> _contractNextActions = <String, String>{
  'version_conflict': 'Review the latest version and try again.',
  'idempotency_key_reused': 'Start this step again as a new attempt.',
  'payload_too_large': 'Choose a smaller file and try again.',
  'unsupported_media_type': 'Use a PDF, PNG, or JPEG file.',
  'invalid_state': 'Refresh this material and try again.',
};

/// Failure codes that always map to an expired-session outcome.
const Set<String> _sessionCodes = <String>{
  'token_missing',
  'token_invalid',
  'token_expired',
};

/// Retryable allowlisted codes.
const Set<String> _retryableContractCodes = <String>{
  'temporarily_unavailable',
  'rate_limited',
  'operation_in_progress',
};

/// Central safe error boundary for ingestion API calls.
///
/// Parses the generated [ErrorEnvelope] instead of reading raw JSON fields and
/// returns only allowlisted domain failures. Malformed bodies, unknown codes
/// and transport failures collapse to safe generic failures. Mirrors the auth
/// feature's `mapDioExceptionToFailure` boundary.
IngestionFailure mapDioExceptionToIngestionFailure(DioException error) {
  final status = error.response?.statusCode;

  final envelope = _parseEnvelope(error.response?.data);

  if (envelope != null) {
    final code = envelope.error.code;
    final safeMessage = _contractMessages[code];

    if (_sessionCodes.contains(code) ||
        (safeMessage == null && status == 401)) {
      return IngestionFailure.expiredSession();
    }

    if (safeMessage == null) {
      // Unknown or additive code: stay generic, never echo server text.
      return IngestionFailure.unknown();
    }

    return IngestionFailure(
      code: code,
      message: safeMessage,
      nextAction: _contractNextActions[code],
      retryable: _retryableContractCodes.contains(code),
    );
  }

  if (status == 401) {
    return IngestionFailure.expiredSession();
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.connectionError) {
    return IngestionFailure.network();
  }

  return IngestionFailure.unknown();
}

/// Maps a durable update `failure_code` (API §11.3) to approved copy.
IngestionFailure mapUpdateFailureCode(String? code) =>
    IngestionFailure.fromUpdateCode(code);

ErrorEnvelope? _parseEnvelope(Object? data) {
  if (data is! Map) return null;

  try {
    final json = data.map<String, dynamic>(
      (Object? key, Object? value) =>
          MapEntry<String, dynamic>(key?.toString() ?? '', value),
    );
    return standardSerializers.deserializeWith(ErrorEnvelope.serializer, json);
  } catch (_) {
    // Malformed or non-envelope payloads are not an error to surface.
    return null;
  }
}
