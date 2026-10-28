import 'package:dio/dio.dart';
import 'package:memora_api_client/memora_api_client.dart';

import '../domain/app_session_state.dart';

/// Approved, non-sensitive copy for allowlisted contract error codes.
///
/// The server `message` field is intentionally ignored: clients branch on the
/// stable `code`, and unknown codes must never surface raw server text.
const Map<String, String> _safeMessages = <String, String>{
  'invalid_cursor': 'That request could not be completed. Please try again.',
  'invalid_state': 'That action is not available right now.',
  'malformed_request': 'That request could not be completed.',
  'token_missing': 'Your session has expired. Please sign in again.',
  'token_invalid': 'Your session has expired. Please sign in again.',
  'token_expired': 'Your session has expired. Please sign in again.',
  'consent_required': 'Review the current policies to continue.',
  'recent_authentication_required':
      'Please confirm your credentials to continue.',
  'operation_not_allowed': 'That action is not allowed for this account.',
  'resource_not_found': 'The requested item was not found.',
  'version_conflict': 'This information has changed. Please review it again.',
  'idempotency_key_reused': 'That request has already been completed.',
  'mission_state_changed': 'This mission has changed. Please reload it.',
  'payload_too_large': 'That file is too large to use.',
  'unsupported_media_type': 'That file type is not supported.',
  'validation_failed': 'Please check the highlighted details and try again.',
  'rate_limited': 'Too many attempts. Please wait before trying again.',
  'temporarily_unavailable':
      'Memora is temporarily unavailable. Please try again shortly.',
  'operation_in_progress': 'That request is still processing. Please wait.',
};

/// Failure codes that always map to an expired-session outcome.
const Set<String> _sessionCodes = <String>{
  'token_missing',
  'token_invalid',
  'token_expired',
};

/// Retryable allowlisted codes.
const Set<String> _retryableCodes = <String>{
  'temporarily_unavailable',
  'rate_limited',
  'operation_in_progress',
};

/// Central safe error boundary for generated API calls.
///
/// Parses the generated [ErrorEnvelope] instead of reading raw JSON fields and
/// returns only allowlisted domain failures. Malformed bodies, unknown codes and
/// transport failures collapse to safe generic failures.
AuthFailure mapDioExceptionToFailure(DioException error) {
  final status = error.response?.statusCode;

  final envelope = _parseEnvelope(error.response?.data);

  if (envelope != null) {
    final code = envelope.error.code;
    final safeMessage = _safeMessages[code];

    if (safeMessage == null) {
      // Unknown or additive code: stay generic, never echo server text.
      return status == 401
          ? AuthFailure.expiredSession()
          : AuthFailure.unknown();
    }

    if (_sessionCodes.contains(code) || status == 401) {
      return AuthFailure.expiredSession(safeMessage);
    }

    return AuthFailure(
      code: code,
      message: safeMessage,
      retryable: _retryableCodes.contains(code),
    );
  }

  if (status == 401) {
    return AuthFailure.expiredSession();
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.connectionError) {
    return AuthFailure.networkError();
  }

  return AuthFailure.unknown();
}

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
