import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_failure.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_models.dart';

void main() {
  group('LearningUpdateState wire parsing', () {
    test('Parses every contracted wire value', () {
      expect(
        LearningUpdateState.fromWireName('draft'),
        LearningUpdateState.draft,
      );
      expect(
        LearningUpdateState.fromWireName('uploading'),
        LearningUpdateState.uploading,
      );
      expect(
        LearningUpdateState.fromWireName('processing'),
        LearningUpdateState.processing,
      );
      expect(
        LearningUpdateState.fromWireName('verification_required'),
        LearningUpdateState.verificationRequired,
      );
      expect(
        LearningUpdateState.fromWireName('committed'),
        LearningUpdateState.committed,
      );
      expect(
        LearningUpdateState.fromWireName('failed'),
        LearningUpdateState.failed,
      );
      expect(
        LearningUpdateState.fromWireName('expired'),
        LearningUpdateState.expired,
      );
      expect(
        LearningUpdateState.fromWireName('deleted'),
        LearningUpdateState.deleted,
      );
    });

    test('Falls back safely for null, empty and additive values', () {
      expect(
        LearningUpdateState.fromWireName(null),
        LearningUpdateState.unknown,
      );
      expect(LearningUpdateState.fromWireName(''), LearningUpdateState.unknown);
      expect(
        LearningUpdateState.fromWireName('future_additive_state'),
        LearningUpdateState.unknown,
      );
    });

    test('Terminal, in-flight and editable predicates match Flow §9.2', () {
      expect(LearningUpdateState.committed.isTerminal, isTrue);
      expect(LearningUpdateState.deleted.isTerminal, isTrue);
      expect(LearningUpdateState.expired.isTerminal, isTrue);
      expect(LearningUpdateState.failed.isTerminal, isFalse);
      expect(LearningUpdateState.draft.isTerminal, isFalse);

      expect(LearningUpdateState.uploading.isInFlight, isTrue);
      expect(LearningUpdateState.processing.isInFlight, isTrue);
      expect(LearningUpdateState.verificationRequired.isInFlight, isFalse);

      expect(LearningUpdateState.draft.isEditable, isTrue);
      expect(LearningUpdateState.verificationRequired.isEditable, isFalse);
    });
  });

  group('Additive-safe wire parsing for remaining enums', () {
    test('SourceUploadState parses known values and falls back safely', () {
      expect(
        SourceUploadState.fromWireName('needs_review_placeholder'),
        SourceUploadState.unknown,
      );
      expect(
        SourceUploadState.fromWireName('rejected'),
        SourceUploadState.rejected,
      );
      expect(SourceUploadState.fromWireName(null), SourceUploadState.unknown);
    });

    test('SourceDeletionStatus parses known values and falls back safely', () {
      expect(
        SourceDeletionStatus.fromWireName('not_required'),
        SourceDeletionStatus.notRequired,
      );
      expect(
        SourceDeletionStatus.fromWireName('pending'),
        SourceDeletionStatus.pending,
      );
      expect(
        SourceDeletionStatus.fromWireName('gone'),
        SourceDeletionStatus.unknown,
      );
      expect(
        SourceDeletionStatus.fromWireName(null),
        SourceDeletionStatus.unknown,
      );
    });

    test('CandidateState parses known values and falls back safely', () {
      expect(
        CandidateState.fromWireName('needs_verification'),
        CandidateState.needsVerification,
      );
      expect(CandidateState.fromWireName('accepted'), CandidateState.accepted);
      expect(CandidateState.fromWireName('scheduled'), CandidateState.unknown);
      expect(CandidateState.fromWireName(null), CandidateState.unknown);
    });

    test('ConfidenceBand parses known values and falls back safely', () {
      expect(ConfidenceBand.fromWireName('high'), ConfidenceBand.high);
      expect(ConfidenceBand.fromWireName('medium'), ConfidenceBand.medium);
      expect(ConfidenceBand.fromWireName('low'), ConfidenceBand.low);
      expect(ConfidenceBand.fromWireName('certain'), ConfidenceBand.unknown);
      expect(ConfidenceBand.fromWireName(null), ConfidenceBand.unknown);
    });

    test('IngestionInputType parses known values and falls back safely', () {
      expect(
        IngestionInputType.fromWireName('manual_text'),
        IngestionInputType.manualText,
      );
      expect(IngestionInputType.fromWireName('pdf'), IngestionInputType.pdf);
      expect(
        IngestionInputType.fromWireName('image'),
        IngestionInputType.image,
      );
      expect(
        IngestionInputType.fromWireName('mixed'),
        IngestionInputType.mixed,
      );
      expect(
        IngestionInputType.fromWireName('audio'),
        IngestionInputType.unknown,
      );
      expect(IngestionInputType.fromWireName(null), IngestionInputType.unknown);
    });

    test('PreviewBlockReason parses known values and falls back safely', () {
      expect(
        PreviewBlockReason.fromWireName('verification_pending'),
        PreviewBlockReason.verificationPending,
      );
      expect(
        PreviewBlockReason.fromWireName('no_valid_concept'),
        PreviewBlockReason.noValidConcept,
      );
      expect(
        PreviewBlockReason.fromWireName('invalid_state'),
        PreviewBlockReason.invalidState,
      );
      expect(
        PreviewBlockReason.fromWireName('server_only_reason'),
        PreviewBlockReason.unknown,
      );
      expect(PreviewBlockReason.fromWireName(null), PreviewBlockReason.unknown);
    });
  });

  group('SourceItem deletion retry eligibility', () {
    SourceItem buildItem(SourceUploadState status, {DateTime? deletedAt}) {
      return SourceItem(
        id: 'upload-1',
        declaredName: 'notes.pdf',
        declaredMediaType: 'application/pdf',
        byteSize: 1024,
        status: status,
        deletionStatus: SourceDeletionStatus.pending,
        deletedAt: deletedAt,
      );
    }

    test(
      'Is available for deleting, expired and rejected without deletedAt',
      () {
        expect(
          buildItem(SourceUploadState.deleting).deletionRetryAvailable,
          isTrue,
        );
        expect(
          buildItem(SourceUploadState.expired).deletionRetryAvailable,
          isTrue,
        );
        expect(
          buildItem(SourceUploadState.rejected).deletionRetryAvailable,
          isTrue,
        );
      },
    );

    test('Is unavailable once a deletion has been recorded', () {
      final deletedAt = DateTime.utc(2026, 11, 1);
      expect(
        buildItem(
          SourceUploadState.deleting,
          deletedAt: deletedAt,
        ).deletionRetryAvailable,
        isFalse,
      );
    });

    test('Is unavailable for other statuses', () {
      expect(
        buildItem(SourceUploadState.processing).deletionRetryAvailable,
        isFalse,
      );
      expect(
        buildItem(SourceUploadState.authorized).deletionRetryAvailable,
        isFalse,
      );
      expect(
        buildItem(SourceUploadState.deleted).deletionRetryAvailable,
        isFalse,
      );
    });
  });

  group('UpdateSnapshot', () {
    test('Deletion retry is available when any upload waits for it', () {
      const snapshot = UpdateSnapshot(
        id: 'update-1',
        subjectId: 'subject-1',
        inputType: IngestionInputType.pdf,
        state: LearningUpdateState.committed,
        hasManualText: false,
        rowVersion: 3,
        sourceDeletionStatus: SourceDeletionStatus.pending,
      );

      expect(snapshot.deletionRetryAvailable, isFalse);

      final waiting = snapshot.copyWithUploadsForTest(<SourceItem>[
        SourceItem(
          id: 'upload-1',
          declaredName: 'notes.pdf',
          declaredMediaType: 'application/pdf',
          byteSize: 1024,
          status: SourceUploadState.deleting,
          deletionStatus: SourceDeletionStatus.pending,
        ),
      ]);

      expect(waiting.deletionRetryAvailable, isTrue);
    });

    test('uploadById finds a known upload and returns null otherwise', () {
      final upload = SourceItem(
        id: 'upload-1',
        declaredName: 'notes.pdf',
        declaredMediaType: 'application/pdf',
        byteSize: 1024,
        status: SourceUploadState.validated,
        deletionStatus: SourceDeletionStatus.notRequired,
      );
      final snapshot = UpdateSnapshot(
        id: 'update-1',
        subjectId: 'subject-1',
        inputType: IngestionInputType.pdf,
        state: LearningUpdateState.uploading,
        hasManualText: false,
        rowVersion: 1,
        sourceDeletionStatus: SourceDeletionStatus.notRequired,
        uploads: <SourceItem>[upload],
      );

      expect(snapshot.uploadById('upload-1'), same(upload));
      expect(snapshot.uploadById('missing'), isNull);
    });

    test('Carries the safe failure built from the update failure code', () {
      final failure = IngestionFailure.fromUpdateCode('extraction_failed');
      final snapshot = UpdateSnapshot(
        id: 'update-1',
        subjectId: 'subject-1',
        inputType: IngestionInputType.manualText,
        state: LearningUpdateState.failed,
        hasManualText: true,
        rowVersion: 2,
        sourceDeletionStatus: SourceDeletionStatus.notRequired,
        failure: failure,
      );

      expect(snapshot.failure, same(failure));
      expect(snapshot.failure?.message, isNot(contains('extraction_failed')));
    });
  });

  group('CandidateItem review requirement', () {
    test('Uncertain candidates need review', () {
      final flagged = CandidateItem(
        id: 'candidate-1',
        candidateType: 'concept',
        displayTitle: 'Projectile motion',
        confidence: 0.4,
        band: ConfidenceBand.low,
        requiresVerification: true,
        status: CandidateState.needsVerification,
        candidateVersion: 1,
      );
      expect(flagged.needsReview, isTrue);
    });

    test('Accepted high-confidence candidates do not need review', () {
      final accepted = CandidateItem(
        id: 'candidate-2',
        candidateType: 'concept',
        displayTitle: 'Newton\u2019s second law',
        confidence: 0.92,
        band: ConfidenceBand.high,
        requiresVerification: false,
        status: CandidateState.accepted,
        candidateVersion: 1,
      );
      expect(accepted.needsReview, isFalse);
    });
  });

  group('DecisionDraft validity mirrors the API contract', () {
    test('Accept and reject must not carry a payload', () {
      expect(
        const DecisionDraft(
          candidateId: 'c1',
          candidateVersion: 1,
          kind: VerificationDecisionKind.accept,
        ).isValid,
        isTrue,
      );
      expect(
        const DecisionDraft(
          candidateId: 'c1',
          candidateVersion: 1,
          kind: VerificationDecisionKind.reject,
        ).isValid,
        isTrue,
      );
      expect(
        const DecisionDraft(
          candidateId: 'c1',
          candidateVersion: 1,
          kind: VerificationDecisionKind.accept,
          editedTitle: 'A title',
        ).isValid,
        isFalse,
      );
      expect(
        const DecisionDraft(
          candidateId: 'c1',
          candidateVersion: 1,
          kind: VerificationDecisionKind.reject,
          mergeIntoCandidateId: 'c2',
        ).isValid,
        isFalse,
      );
    });

    test('Edit requires a non-empty title and no merge target', () {
      expect(
        const DecisionDraft(
          candidateId: 'c1',
          candidateVersion: 1,
          kind: VerificationDecisionKind.edit,
          editedTitle: 'Momentum conservation',
        ).isValid,
        isTrue,
      );
      expect(
        const DecisionDraft(
          candidateId: 'c1',
          candidateVersion: 1,
          kind: VerificationDecisionKind.edit,
        ).isValid,
        isFalse,
      );
      expect(
        const DecisionDraft(
          candidateId: 'c1',
          candidateVersion: 1,
          kind: VerificationDecisionKind.edit,
          editedTitle: '   ',
        ).isValid,
        isFalse,
      );
      expect(
        const DecisionDraft(
          candidateId: 'c1',
          candidateVersion: 1,
          kind: VerificationDecisionKind.edit,
          editedTitle: 'Momentum conservation',
          mergeIntoCandidateId: 'c2',
        ).isValid,
        isFalse,
      );
    });

    test('Merge requires a merge target', () {
      expect(
        const DecisionDraft(
          candidateId: 'c1',
          candidateVersion: 1,
          kind: VerificationDecisionKind.merge,
          mergeIntoCandidateId: 'c2',
        ).isValid,
        isTrue,
      );
      expect(
        const DecisionDraft(
          candidateId: 'c1',
          candidateVersion: 1,
          kind: VerificationDecisionKind.merge,
        ).isValid,
        isFalse,
      );
    });
  });

  group('Preview and commit models', () {
    test('PathPreview carries bounded reason state', () {
      const preview = PathPreview(
        updateId: 'update-1',
        state: LearningUpdateState.verificationRequired,
        conceptCount: 0,
        firstConcepts: <PreviewConcept>[],
        canCommit: false,
        estimatedFirstMissionMinutes: null,
        blockedReason: PreviewBlockReason.verificationPending,
      );

      expect(preview.canCommit, isFalse);
      expect(preview.blockedReason, PreviewBlockReason.verificationPending);
      expect(preview.estimatedFirstMissionMinutes, isNull);
    });

    test(
      'CommitOutcome defaults firstMission to null before mission wiring',
      () {
        const outcome = CommitOutcome(
          knowledgeCommitId: 'commit-1',
          commitVersion: 1,
          committedCounts: <String, int>{'concepts': 4},
          conceptMappings: <PreviewConcept>[],
          privateKnowledgeCount: 2,
          sourceDeletionStatus: SourceDeletionStatus.pending,
        );

        expect(outcome.firstMission, isNull);
        expect(outcome.committedCounts['concepts'], 4);
      },
    );

    test('FirstMissionInfo carries the mission reference when present', () {
      const outcome = CommitOutcome(
        knowledgeCommitId: 'commit-1',
        commitVersion: 2,
        committedCounts: <String, int>{},
        conceptMappings: <PreviewConcept>[],
        privateKnowledgeCount: 0,
        sourceDeletionStatus: SourceDeletionStatus.deleted,
        firstMission: FirstMissionInfo(missionId: 'mission-1', status: 'ready'),
      );

      expect(outcome.firstMission?.missionId, 'mission-1');
    });
  });
}

extension on UpdateSnapshot {
  /// Test helper replacing the upload list without adding a production
  /// copyWith surface to the immutable model.
  UpdateSnapshot copyWithUploadsForTest(List<SourceItem> uploads) =>
      UpdateSnapshot(
        id: id,
        subjectId: subjectId,
        inputType: inputType,
        state: state,
        hasManualText: hasManualText,
        rowVersion: rowVersion,
        sourceDeletionStatus: sourceDeletionStatus,
        failure: failure,
        learnedAt: learnedAt,
        expiresAt: expiresAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        uploads: uploads,
      );
}
