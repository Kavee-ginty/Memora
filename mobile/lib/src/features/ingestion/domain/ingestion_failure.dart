import 'package:flutter/foundation.dart';

/// Safe, approved failure representation for ingestion operations.
///
/// Copy is allowlisted: the server `message` field is never rendered (UIX-021)
/// and raw codes never appear in student-facing copy. Every failure carries
/// retry eligibility and a next action (API §11.3).
@immutable
class IngestionFailure {
  final String code;

  /// Approved copy only; never the server-supplied message.
  final String message;

  /// Approved copy describing the next useful action, when one exists.
  final String? nextAction;

  /// Whether retrying the same step can plausibly succeed. State-level retry
  /// affordances (failed update, deletion cleanup) are derived from
  /// [UpdateSnapshot], not from this flag.
  final bool retryable;

  const IngestionFailure({
    required this.code,
    required this.message,
    this.nextAction,
    this.retryable = false,
  });

  /// The device could not reach Memora. Connectivity is derived from the
  /// failed request; no connectivity plugin is used.
  factory IngestionFailure.network([String? message]) => IngestionFailure(
    code: 'network_error',
    message:
        message ??
        'You appear to be offline. Memora will keep your work where possible.',
    nextAction: 'Check your connection and try again.',
    retryable: true,
  );

  factory IngestionFailure.expiredSession([String? message]) => IngestionFailure(
    code: 'expired_session',
    message: message ?? 'Your session has expired. Please sign in again.',
    retryable: false,
  );

  factory IngestionFailure.unknown([String? message]) => IngestionFailure(
    code: 'unknown',
    message: message ?? 'Something went wrong. Please try again.',
    nextAction: 'Try again.',
    retryable: true,
  );

  /// Maps a durable update `failure_code` (API §11.3) to approved copy.
  ///
  /// Retryability reflects whether repeating the failed step can plausibly
  /// succeed; unknown or additive codes collapse to a safe generic failure.
  factory IngestionFailure.fromUpdateCode(String? code) {
    switch (code) {
      case 'cancelled':
        return const IngestionFailure(
          code: 'cancelled',
          message: 'You cancelled this material.',
          nextAction: 'Start a new update when you are ready.',
        );
      case 'deletion_failed':
        return const IngestionFailure(
          code: 'deletion_failed',
          message:
              'Your material is safe, but the temporary source could not be '
              'removed yet.',
          nextAction: 'Memora will keep trying. You can also retry the cleanup.',
          retryable: true,
        );
      case 'extraction_failed':
        return const IngestionFailure(
          code: 'extraction_failed',
          message: 'Memora could not finish reading this material.',
          nextAction: 'Try again.',
          retryable: true,
        );
      case 'extraction_unavailable':
        return const IngestionFailure(
          code: 'extraction_unavailable',
          message: 'The reading service is temporarily unavailable.',
          nextAction: 'Try again in a moment.',
          retryable: true,
        );
      case 'internal_error':
        return const IngestionFailure(
          code: 'internal_error',
          message: 'Something went wrong while Memora worked on this material.',
          nextAction: 'Try again in a moment.',
          retryable: true,
        );
      case 'no_extractable_content':
        return const IngestionFailure(
          code: 'no_extractable_content',
          message: 'Memora could not find study concepts in this material.',
          nextAction: 'Try a clearer or longer source.',
        );
      case 'payload_too_large':
        return const IngestionFailure(
          code: 'payload_too_large',
          message: 'That file is larger than Memora can process.',
          nextAction: 'Choose a smaller file and try again.',
        );
      case 'source_unavailable':
        return const IngestionFailure(
          code: 'source_unavailable',
          message: 'The original file could not be read.',
          nextAction: 'Try again, or replace the source.',
          retryable: true,
        );
      case 'unsupported_media_type':
        return const IngestionFailure(
          code: 'unsupported_media_type',
          message: 'That file type is not supported.',
          nextAction: 'Use a PDF, PNG, or JPEG file.',
        );
      case 'validation_failed':
        return const IngestionFailure(
          code: 'validation_failed',
          message: 'Memora could not use this material as provided.',
          nextAction: 'Check the source and try again.',
        );
      default:
        // Unknown or additive code: stay generic, never echo server text.
        return IngestionFailure(
          code: code ?? 'unknown',
          message: 'Something went wrong while processing this material.',
          nextAction: 'Try again in a moment.',
          retryable: true,
        );
    }
  }
}
