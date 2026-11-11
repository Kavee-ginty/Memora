import 'package:flutter/foundation.dart';

/// Server-reported privacy request lifecycle.
///
/// The generated client can expose additive enum values through its
/// `unknown_default_open_api` fallback. Those values map to [unknown] and are
/// never treated as complete, failed or pending.
enum PrivacyRequestStatus {
  requested,
  verifying,
  processing,
  completed,
  failed,
  cancelled,
  unknown;

  bool get isPending =>
      this == PrivacyRequestStatus.requested ||
      this == PrivacyRequestStatus.verifying ||
      this == PrivacyRequestStatus.processing;

  bool get isTerminal =>
      this == PrivacyRequestStatus.completed ||
      this == PrivacyRequestStatus.failed ||
      this == PrivacyRequestStatus.cancelled;

  /// Cancellation is only permitted while T20 still accepts it.
  bool get canCancelDeletion =>
      this == PrivacyRequestStatus.requested ||
      this == PrivacyRequestStatus.verifying;
}

/// One verified deletion scope returned on completion.
@immutable
class DeletionProof {
  final String id;
  final String scope;
  final String provider;
  final String result;
  final DateTime? verifiedAt;

  const DeletionProof({
    required this.id,
    required this.scope,
    required this.provider,
    required this.result,
    this.verifiedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeletionProof &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          scope == other.scope &&
          provider == other.provider &&
          result == other.result &&
          verifiedAt == other.verifiedAt;

  @override
  int get hashCode => Object.hash(id, scope, provider, result, verifiedAt);
}

/// Export request status and its ephemeral retrieval details.
@immutable
class PrivacyExport {
  final String id;
  final PrivacyRequestStatus status;
  final DateTime? requestedAt;
  final DateTime? completedAt;
  final Uri? downloadUri;
  final DateTime? downloadExpiresAt;
  final String? failureCode;

  const PrivacyExport({
    required this.id,
    required this.status,
    this.requestedAt,
    this.completedAt,
    this.downloadUri,
    this.downloadExpiresAt,
    this.failureCode,
  });

  bool get hasDownload => downloadUri != null;

  /// True only when the server returned a completed export, a signed URL and a
  /// server-supplied expiry that is still in the future at [now].
  ///
  /// A URL without an expiry is not treated as ready: the contract says the
  /// ready state provides both the retrieval action and its expiry, so the app
  /// must not invite a download whose lifetime it cannot confirm.
  bool hasActiveDownload(DateTime now) {
    if (status != PrivacyRequestStatus.completed || downloadUri == null) {
      return false;
    }
    final expiresAt = downloadExpiresAt;
    return expiresAt != null && expiresAt.isAfter(now);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivacyExport &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          requestedAt == other.requestedAt &&
          completedAt == other.completedAt &&
          downloadUri == other.downloadUri &&
          downloadExpiresAt == other.downloadExpiresAt &&
          failureCode == other.failureCode;

  @override
  int get hashCode => Object.hash(
    id,
    status,
    requestedAt,
    completedAt,
    downloadUri,
    downloadExpiresAt,
    failureCode,
  );
}

/// Deletion request status, proof state and documented retention exceptions.
@immutable
class PrivacyDeletion {
  final String id;
  final PrivacyRequestStatus status;
  final DateTime? requestedAt;
  final DateTime? completedAt;
  final String? failureCode;
  final List<DeletionProof> proofs;
  final List<String> retentionExceptions;

  const PrivacyDeletion({
    required this.id,
    required this.status,
    this.requestedAt,
    this.completedAt,
    this.failureCode,
    this.proofs = const <DeletionProof>[],
    this.retentionExceptions = const <String>[],
  });

  /// Completion is only confirmed when the server also returns proof state.
  bool get isConfirmedComplete =>
      status == PrivacyRequestStatus.completed && proofs.isNotEmpty;

  bool get canCancel => status.canCancelDeletion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivacyDeletion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          requestedAt == other.requestedAt &&
          completedAt == other.completedAt &&
          failureCode == other.failureCode &&
          listEquals(proofs, other.proofs) &&
          listEquals(retentionExceptions, other.retentionExceptions);

  @override
  int get hashCode => Object.hash(
    id,
    status,
    requestedAt,
    completedAt,
    failureCode,
    Object.hashAll(proofs),
    Object.hashAll(retentionExceptions),
  );
}

/// The mutation that triggered recent-authentication recovery.
enum PrivacyPendingAction { export, deletion, cancellation }
