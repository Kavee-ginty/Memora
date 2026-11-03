import 'package:flutter/foundation.dart';

import 'ingestion_failure.dart';

/// Durable state of a learning update, mirroring the public contract states
/// (API §11.3) with a safe [unknown] fallback for additive server values.
///
/// Screen logic branches on this enum only; generated transport enums never
/// reach presentation code.
enum LearningUpdateState {
  draft,
  uploading,
  processing,
  verificationRequired,
  committed,
  failed,
  expired,
  deleted,
  unknown;

  /// Parses the wire representation. Unrecognized, additive or null values
  /// fall back to [unknown] so screens can fail safely (FLOW-001).
  static LearningUpdateState fromWireName(String? wire) => switch (wire) {
    'draft' => draft,
    'uploading' => uploading,
    'processing' => processing,
    'verification_required' => verificationRequired,
    'committed' => committed,
    'failed' => failed,
    'expired' => expired,
    'deleted' => deleted,
    _ => unknown,
  };

  /// Terminal states never move backward (Flow §9.2); retry and edit affordances
  /// are hidden for them.
  bool get isTerminal =>
      this == committed || this == deleted || this == expired;

  /// Server-side work is advancing; the student may leave and return.
  bool get isInFlight => this == uploading || this == processing;

  /// Only drafts accept metadata and text edits (API §11.1).
  bool get isEditable => this == draft;
}

/// Lifecycle of one temporary source upload bound to a learning update.
enum SourceUploadState {
  authorized,
  uploaded,
  validated,
  processing,
  deleting,
  deleted,
  rejected,
  expired,
  unknown;

  static SourceUploadState fromWireName(String? wire) => switch (wire) {
    'authorized' => authorized,
    'uploaded' => uploaded,
    'validated' => validated,
    'processing' => processing,
    'deleting' => deleting,
    'deleted' => deleted,
    'rejected' => rejected,
    'expired' => expired,
    _ => unknown,
  };
}

/// Deletion state of a temporary source, tracked separately from the retained
/// knowledge status (API §11.3).
enum SourceDeletionStatus {
  notRequired,
  pending,
  deleted,
  failed,
  unknown;

  static SourceDeletionStatus fromWireName(String? wire) => switch (wire) {
    'not_required' => notRequired,
    'pending' => pending,
    'deleted' => deleted,
    'failed' => failed,
    _ => unknown,
  };
}

/// Lifecycle of one extraction candidate (API §12).
enum CandidateState {
  candidate,
  needsVerification,
  accepted,
  rejected,
  committed,
  expired,
  unknown;

  static CandidateState fromWireName(String? wire) => switch (wire) {
    'candidate' => candidate,
    'needs_verification' => needsVerification,
    'accepted' => accepted,
    'rejected' => rejected,
    'committed' => committed,
    'expired' => expired,
    _ => unknown,
  };
}

/// Banded extraction confidence. A band is never a calibrated probability
/// (PRD 009), so it is rendered with text and icon, never color alone.
enum ConfidenceBand {
  high,
  medium,
  low,
  unknown;

  static ConfidenceBand fromWireName(String? wire) => switch (wire) {
    'high' => high,
    'medium' => medium,
    'low' => low,
    _ => unknown,
  };
}

/// Declared input composition of a learning update.
enum IngestionInputType {
  manualText,
  pdf,
  image,
  mixed,
  unknown;

  static IngestionInputType fromWireName(String? wire) => switch (wire) {
    'manual_text' => manualText,
    'pdf' => pdf,
    'image' => image,
    'mixed' => mixed,
    _ => unknown,
  };
}

/// Why the preview cannot proceed to commit (API §12 `blocked_reason`).
enum PreviewBlockReason {
  verificationPending,
  noValidConcept,
  invalidState,
  unknown;

  static PreviewBlockReason fromWireName(String? wire) => switch (wire) {
    'verification_pending' => verificationPending,
    'no_valid_concept' => noValidConcept,
    'invalid_state' => invalidState,
    _ => unknown,
  };
}

/// What the student chose to do with one candidate (API §12).
enum VerificationDecisionKind { accept, edit, reject, merge }

/// Protected local draft for pasted text (Flow §9.1, D8).
///
/// The draft holds only the subject, the manual text and the learning time.
/// File bytes and picked-file paths are never part of this model.
@immutable
class IngestionDraft {
  final String subjectId;
  final String manualText;
  final DateTime learnedAt;

  const IngestionDraft({
    required this.subjectId,
    required this.manualText,
    required this.learnedAt,
  });

  bool get isEmpty => manualText.trim().isEmpty;

  IngestionDraft copyWith({
    String? subjectId,
    String? manualText,
    DateTime? learnedAt,
  }) {
    return IngestionDraft(
      subjectId: subjectId ?? this.subjectId,
      manualText: manualText ?? this.manualText,
      learnedAt: learnedAt ?? this.learnedAt,
    );
  }
}

/// Server-side stage that a failed update can retry (API §11.1).
enum IngestionRetryStage { extraction, deletion }

/// One file the client declares before requesting an upload grant (API §11.1).
///
/// The checksum and size are computed from the exact bytes before the grant is
/// requested; the bytes themselves are never persisted by the client.
@immutable
class DeclaredSource {
  final String declaredName;
  final String declaredMediaType;
  final int byteSize;
  final String contentSha256;

  const DeclaredSource({
    required this.declaredName,
    required this.declaredMediaType,
    required this.byteSize,
    required this.contentSha256,
  });
}

/// Short-lived, single-purpose permission to upload one temporary source
/// object (API §11.2).
@immutable
class UploadGrant {
  final String uploadId;
  final String url;

  /// HTTP method the storage endpoint accepts. The client only proceeds for
  /// `PUT`; any other value is treated as an unsupported grant.
  final String method;
  final Map<String, String> requiredHeaders;
  final int maxBytes;

  /// Null when the server value could not be parsed. The upload client refuses
  /// to start without a usable expiry.
  final DateTime? expiresAt;
  final String checksumRule;

  UploadGrant({
    required this.uploadId,
    required this.url,
    required this.method,
    required Map<String, String> requiredHeaders,
    required this.maxBytes,
    required this.expiresAt,
    required this.checksumRule,
  }) : requiredHeaders = Map<String, String>.unmodifiable(requiredHeaders);
}

/// One page of the student's learning updates (API §5.2).
@immutable
class UpdatePage {
  final List<UpdateSnapshot> items;
  final bool hasMore;
  final String? nextCursor;

  const UpdatePage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });
}

/// One page of extraction candidates (API §5.2).
@immutable
class CandidatePage {
  final List<CandidateItem> items;
  final bool hasMore;
  final String? nextCursor;

  const CandidatePage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });
}

/// One temporary source upload shown in the source list.
@immutable
class SourceItem {
  final String id;
  final String declaredName;
  final String declaredMediaType;
  final String? detectedMediaType;
  final int byteSize;
  final SourceUploadState status;
  final DateTime? expiresAt;
  final DateTime? deletedAt;
  final SourceDeletionStatus deletionStatus;

  const SourceItem({
    required this.id,
    required this.declaredName,
    required this.declaredMediaType,
    required this.byteSize,
    required this.status,
    required this.deletionStatus,
    this.detectedMediaType,
    this.expiresAt,
    this.deletedAt,
  });

  /// Mirrors the backend deletion-retry eligibility: an upload is only waiting
  /// for a retriable deletion while it is in `deleting`, `expired` or
  /// `rejected` and no deletion has been recorded.
  bool get deletionRetryAvailable =>
      (status == SourceUploadState.deleting ||
          status == SourceUploadState.expired ||
          status == SourceUploadState.rejected) &&
      deletedAt == null;
}

/// Authoritative snapshot of a learning update as returned by the server.
///
/// The manual text itself is never echoed by the API (only [hasManualText]);
/// editable text lives in the protected local draft.
@immutable
class UpdateSnapshot {
  final String id;
  final String subjectId;
  final IngestionInputType inputType;
  final LearningUpdateState state;

  /// Present when [state] is failed; built from the safe `failure_code`.
  final IngestionFailure? failure;
  final bool hasManualText;
  final DateTime? learnedAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int rowVersion;
  final SourceDeletionStatus sourceDeletionStatus;
  final List<SourceItem> uploads;

  const UpdateSnapshot({
    required this.id,
    required this.subjectId,
    required this.inputType,
    required this.state,
    required this.hasManualText,
    required this.rowVersion,
    required this.sourceDeletionStatus,
    this.failure,
    this.learnedAt,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
    this.uploads = const <SourceItem>[],
  });

  /// Deletion cleanup can be retried while any upload is waiting for it. This
  /// is independent of [state]: a committed update may still need deletion
  /// recovery after a provider outage.
  bool get deletionRetryAvailable =>
      uploads.any((upload) => upload.deletionRetryAvailable);

  SourceItem? uploadById(String uploadId) {
    for (final upload in uploads) {
      if (upload.id == uploadId) return upload;
    }
    return null;
  }
}

/// One extracted concept candidate shown during verification.
@immutable
class CandidateItem {
  final String id;
  final String candidateType;
  final String displayTitle;
  final String? displaySummary;

  /// Bounded, client-safe source context built by the repository from the
  /// candidate's source locator. Never contains raw binaries or full text.
  final String? sourceContext;
  final double confidence;
  final ConfidenceBand band;
  final bool requiresVerification;
  final CandidateState status;
  final int candidateVersion;

  const CandidateItem({
    required this.id,
    required this.candidateType,
    required this.displayTitle,
    required this.confidence,
    required this.band,
    required this.requiresVerification,
    required this.status,
    required this.candidateVersion,
    this.displaySummary,
    this.sourceContext,
  });

  /// Uncertain candidates must be resolved before preview can commit.
  bool get needsReview =>
      requiresVerification || status == CandidateState.needsVerification;
}

/// One concept in the learning-path preview (API §12).
@immutable
class PreviewConcept {
  final String candidateId;
  final String title;
  final String candidateType;
  final String? conceptId;
  final String? conceptVersionId;

  const PreviewConcept({
    required this.candidateId,
    required this.title,
    required this.candidateType,
    this.conceptId,
    this.conceptVersionId,
  });
}

/// Authoritative learning-path preview (API §12).
@immutable
class PathPreview {
  final String updateId;
  final LearningUpdateState state;
  final int conceptCount;
  final List<PreviewConcept> firstConcepts;

  /// Null when nothing valid was accepted; otherwise a bounded estimate.
  final int? estimatedFirstMissionMinutes;
  final bool canCommit;
  final PreviewBlockReason? blockedReason;

  const PathPreview({
    required this.updateId,
    required this.state,
    required this.conceptCount,
    required this.firstConcepts,
    required this.canCommit,
    this.estimatedFirstMissionMinutes,
    this.blockedReason,
  });
}

/// Mission reference returned by a successful commit. Null on the current
/// backend until mission wiring lands, so the ready state explains that the
/// first mission is not startable yet.
@immutable
class FirstMissionInfo {
  final String missionId;
  final String status;

  const FirstMissionInfo({required this.missionId, required this.status});
}

/// Authoritative result of an idempotent commit (API §12).
@immutable
class CommitOutcome {
  final String knowledgeCommitId;
  final int commitVersion;
  final Map<String, int> committedCounts;
  final List<PreviewConcept> conceptMappings;
  final int privateKnowledgeCount;
  final FirstMissionInfo? firstMission;
  final SourceDeletionStatus sourceDeletionStatus;

  const CommitOutcome({
    required this.knowledgeCommitId,
    required this.commitVersion,
    required this.committedCounts,
    required this.conceptMappings,
    required this.privateKnowledgeCount,
    required this.sourceDeletionStatus,
    this.firstMission,
  });
}

/// A locally held, not-yet-submitted decision for one candidate.
///
/// Validity mirrors the API contract: `accept` and `reject` carry no payload,
/// `edit` requires a title, and `merge` requires a merge target.
@immutable
class DecisionDraft {
  final String candidateId;
  final int candidateVersion;
  final VerificationDecisionKind kind;
  final String? editedTitle;
  final String? mergeIntoCandidateId;

  const DecisionDraft({
    required this.candidateId,
    required this.candidateVersion,
    required this.kind,
    this.editedTitle,
    this.mergeIntoCandidateId,
  });

  bool get isValid {
    final hasTitle = editedTitle != null && editedTitle!.trim().isNotEmpty;
    final hasMergeTarget =
        mergeIntoCandidateId != null && mergeIntoCandidateId!.trim().isNotEmpty;

    return switch (kind) {
      VerificationDecisionKind.accept => !hasTitle && !hasMergeTarget,
      VerificationDecisionKind.reject => !hasTitle && !hasMergeTarget,
      VerificationDecisionKind.edit => hasTitle && !hasMergeTarget,
      VerificationDecisionKind.merge => hasMergeTarget,
    };
  }
}

/// Server-confirmed outcome for one submitted decision (API §12).
@immutable
class DecisionOutcome {
  final String candidateId;
  final CandidateState state;
  final bool requiresVerification;

  const DecisionOutcome({
    required this.candidateId,
    required this.state,
    required this.requiresVerification,
  });
}

/// Authoritative result of submitting one batch of verification decisions.
@immutable
class VerificationOutcome {
  final UpdateSnapshot update;
  final List<DecisionOutcome> outcomes;

  const VerificationOutcome({required this.update, required this.outcomes});
}
