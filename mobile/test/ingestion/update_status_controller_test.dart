import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/ingestion/application/update_status_controller.dart';
import 'package:memora_mobile/src/features/ingestion/data/ingestion_draft_store.dart';
import 'package:memora_mobile/src/features/ingestion/data/ingestion_repository.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_failure.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_models.dart';

const String _accountId = 'account-a';
const String _subjectId = '22222222-2222-4222-8222-222222222222';
const String _updateId = '11111111-1111-4111-8111-111111111111';
const String _uploadId = '44444444-4444-4444-8444-444444444444';

const IngestionFailure _offline = IngestionFailure(
  code: 'network_error',
  message: 'Memora could not reach the server.',
  nextAction: 'Check your connection and try again.',
  retryable: true,
);

const IngestionFailure _retryableExtraction = IngestionFailure(
  code: 'extraction_failed',
  message: 'Memora could not extract concepts from this material.',
  nextAction: 'Try extracting again.',
  retryable: true,
);

const IngestionFailure _terminalExtraction = IngestionFailure(
  code: 'no_extractable_content',
  message: 'Memora could not find enough study content in this material.',
  nextAction: 'Add different material.',
);

BootstrapData _bootstrap() {
  return BootstrapData(
    accountStatus: AccountStatusDomain.active,
    profileSummary: const ProfileSummaryDomain(
      userId: _accountId,
      displayName: 'Amani Perera',
      activeSubjectId: _subjectId,
    ),
    consentStatus: const ConsentStatusDomain(requiresReview: false),
    subjects: const <SubjectSummaryDomain>[
      SubjectSummaryDomain(
        id: _subjectId,
        code: 'AL-PHYS',
        name: 'A/L Physics',
        curriculumEditionCode: '2026',
        curriculumVersionId: 'cur_1',
      ),
    ],
    capabilities: const CapabilityFlagsDomain(),
    serverTime: DateTime.utc(2026, 11, 1),
  );
}

SessionController _sessionController() {
  return SessionController(
    authRepository: MockAuthRepository(),
    sessionRepository: MockSessionRepository(),
    localStorage: AppLocalStorage(InMemorySecureKeyStore()),
    initialState: AppSessionState.active(
      session: const AuthSession(
        accessToken: 'access-token',
        userId: _accountId,
      ),
      bootstrapData: _bootstrap(),
    ),
  );
}

UpdateSnapshot _snapshot({
  LearningUpdateState state = LearningUpdateState.processing,
  IngestionFailure? failure,
  List<SourceItem> uploads = const <SourceItem>[],
  SourceDeletionStatus deletionStatus = SourceDeletionStatus.notRequired,
}) {
  return UpdateSnapshot(
    id: _updateId,
    subjectId: _subjectId,
    inputType: IngestionInputType.manualText,
    state: state,
    failure: failure,
    hasManualText: true,
    learnedAt: DateTime.utc(2026, 11, 1),
    createdAt: DateTime.utc(2026, 11, 1),
    updatedAt: DateTime.utc(2026, 11, 1),
    rowVersion: 1,
    sourceDeletionStatus: deletionStatus,
    uploads: uploads,
  );
}

SourceItem _upload({
  SourceUploadState status = SourceUploadState.deleting,
  SourceDeletionStatus deletionStatus = SourceDeletionStatus.pending,
}) {
  return SourceItem(
    id: _uploadId,
    declaredName: 'notes.pdf',
    declaredMediaType: 'application/pdf',
    byteSize: 2048,
    status: status,
    deletionStatus: deletionStatus,
  );
}

class _RecordingRepository extends MockIngestionRepository {
  _RecordingRepository() : super(autoAdvanceProcessing: false);

  final List<String> retryKeys = <String>[];
  final List<IngestionRetryStage> retryStages = <IngestionRetryStage>[];

  @override
  Future<UpdateSnapshot> retryUpdate({
    required String accessToken,
    required String updateId,
    required IngestionRetryStage stage,
    required String idempotencyKey,
  }) {
    retryKeys.add(idempotencyKey);
    retryStages.add(stage);
    return super.retryUpdate(
      accessToken: accessToken,
      updateId: updateId,
      stage: stage,
      idempotencyKey: idempotencyKey,
    );
  }
}

UpdateStatusController _controller({
  required IngestionRepository repository,
  SessionController? sessionController,
  IngestionDraftStore? draftStore,
}) {
  return UpdateStatusController(
    repository: repository,
    draftStore:
        draftStore ?? IngestionDraftStore(keyStore: InMemorySecureKeyStore()),
    sessionController: sessionController ?? _sessionController(),
    updateId: _updateId,
  );
}

void main() {
  group('UpdateStatusController', () {
    test('loads the authoritative snapshot and polls with capped backoff', () {
      fakeAsync((async) {
        final repository = _RecordingRepository()..seedUpdate(_snapshot());
        final controller = _controller(repository: repository);

        controller.initialize();
        async.flushMicrotasks();

        expect(repository.operations, <IngestionOperation>[
          IngestionOperation.get,
        ]);
        expect(
          controller.currentState.snapshot?.state,
          LearningUpdateState.processing,
        );
        expect(controller.currentState.isLoading, isFalse);

        async.elapse(const Duration(seconds: 2));
        expect(repository.operations.length, 2);

        async.elapse(const Duration(seconds: 4));
        expect(repository.operations.length, 3);

        async.elapse(const Duration(seconds: 8));
        expect(repository.operations.length, 4);

        // Backoff doubles only to the 10 second cap.
        async.elapse(const Duration(seconds: 10));
        expect(repository.operations.length, 5);

        async.elapse(const Duration(seconds: 10));
        expect(repository.operations.length, 6);

        controller.dispose();
      });
    });

    test('stops polling and slow messaging on a review state', () {
      fakeAsync((async) {
        final repository = _RecordingRepository()..seedUpdate(_snapshot());
        final controller = _controller(repository: repository);

        controller.initialize();
        async.flushMicrotasks();

        repository.seedUpdate(
          _snapshot(state: LearningUpdateState.verificationRequired),
        );
        async.elapse(const Duration(seconds: 2));
        final callsAfterReview = repository.operations.length;
        expect(
          controller.currentState.snapshot?.state,
          LearningUpdateState.verificationRequired,
        );
        expect(controller.currentState.isSlow, isFalse);

        async.elapse(const Duration(minutes: 10));
        expect(repository.operations.length, callsAfterReview);
        expect(controller.currentState.isSlow, isFalse);
        expect(controller.currentState.shouldLeaveAndReturn, isFalse);

        controller.dispose();
      });
    });

    test(
      'marks slow after 10 seconds and recommends leaving after 10 minutes',
      () {
        fakeAsync((async) {
          final repository = _RecordingRepository()..seedUpdate(_snapshot());
          final controller = _controller(repository: repository);

          controller.initialize();
          async.flushMicrotasks();

          async.elapse(const Duration(seconds: 9));
          expect(controller.currentState.isSlow, isFalse);
          expect(controller.currentState.shouldLeaveAndReturn, isFalse);

          async.elapse(const Duration(seconds: 1));
          expect(controller.currentState.isSlow, isTrue);
          expect(controller.currentState.shouldLeaveAndReturn, isFalse);

          async.elapse(const Duration(minutes: 9, seconds: 50));
          expect(controller.currentState.shouldLeaveAndReturn, isTrue);

          controller.dispose();
        });
      },
    );

    test('refresh re-reads authoritative state and restarts backoff', () {
      fakeAsync((async) {
        final repository = _RecordingRepository()..seedUpdate(_snapshot());
        final controller = _controller(repository: repository);

        controller.initialize();
        async.flushMicrotasks();
        expect(repository.operations.length, 1);

        async.elapse(const Duration(seconds: 2));
        expect(repository.operations.length, 2);

        controller.refresh();
        async.flushMicrotasks();
        expect(repository.operations.length, 3);
        expect(controller.currentState.isRefreshing, isFalse);

        async.elapse(const Duration(seconds: 2));
        expect(repository.operations.length, 4);

        controller.dispose();
      });
    });

    test('absent or wrong-owner updates become not found', () {
      fakeAsync((async) {
        final repository = _RecordingRepository();
        final controller = _controller(repository: repository);

        controller.initialize();
        async.flushMicrotasks();

        expect(controller.currentState.isNotFound, isTrue);
        expect(repository.operations, <IngestionOperation>[
          IngestionOperation.get,
        ]);

        async.elapse(const Duration(minutes: 10));
        expect(repository.operations.length, 1);

        controller.dispose();
      });
    });

    test('first read failure shows an offline state and can recover', () {
      fakeAsync((async) {
        final repository = _RecordingRepository()
          ..failures[IngestionOperation.get] = _offline;
        final controller = _controller(repository: repository);

        controller.initialize();
        async.flushMicrotasks();

        expect(controller.currentState.stage, UpdateStatusStage.failed);
        expect(controller.currentState.isOffline, isTrue);
        expect(controller.currentState.snapshot, isNull);
        expect(controller.currentState.failure?.message, _offline.message);

        repository.failures.remove(IngestionOperation.get);
        repository.seedUpdate(_snapshot());
        controller.refresh();
        async.flushMicrotasks();

        expect(controller.currentState.stage, UpdateStatusStage.ready);
        expect(controller.currentState.isOffline, isFalse);
        expect(controller.currentState.failure, isNull);

        controller.dispose();
      });
    });

    test('refresh failure keeps the last authoritative snapshot visible', () {
      fakeAsync((async) {
        final repository = _RecordingRepository()..seedUpdate(_snapshot());
        final controller = _controller(repository: repository);

        controller.initialize();
        async.flushMicrotasks();

        repository.failures[IngestionOperation.get] = _offline;
        controller.refresh();
        async.flushMicrotasks();

        expect(controller.currentState.stage, UpdateStatusStage.ready);
        expect(controller.currentState.snapshot, isNotNull);
        expect(controller.currentState.isOffline, isTrue);
        expect(controller.currentState.failure?.code, 'network_error');

        repository.failures.remove(IngestionOperation.get);
        controller.refresh();
        async.flushMicrotasks();

        expect(controller.currentState.isOffline, isFalse);
        expect(controller.currentState.failure, isNull);

        controller.dispose();
      });
    });

    test('extraction retry reuses the durable key and creates nothing', () {
      fakeAsync((async) {
        final repository = _RecordingRepository()
          ..seedUpdate(
            _snapshot(
              state: LearningUpdateState.failed,
              failure: _retryableExtraction,
            ),
          );
        final draftStore = IngestionDraftStore(
          keyStore: InMemorySecureKeyStore(),
        );
        final controller = _controller(
          repository: repository,
          draftStore: draftStore,
        );

        controller.initialize();
        async.flushMicrotasks();
        expect(controller.currentState.canRetryExtraction, isTrue);

        repository.failures[IngestionOperation.retry] = _offline;
        controller.retryExtraction();
        async.flushMicrotasks();
        expect(repository.retryKeys, hasLength(1));

        repository.failures.remove(IngestionOperation.retry);
        controller.retryExtraction();
        async.flushMicrotasks();

        expect(repository.retryKeys, hasLength(2));
        expect(repository.retryKeys[0], repository.retryKeys[1]);
        expect(
          repository.retryStages,
          everyElement(IngestionRetryStage.extraction),
        );
        expect(
          repository.operations,
          isNot(contains(IngestionOperation.create)),
        );
        expect(
          repository.operations,
          isNot(contains(IngestionOperation.grant)),
        );
        expect(
          repository.operations,
          isNot(contains(IngestionOperation.finalize)),
        );
        expect(
          controller.currentState.snapshot?.state,
          LearningUpdateState.processing,
        );
        expect(controller.currentState.failure, isNull);

        controller.dispose();
      });
    });

    test('non-retryable extraction failures offer no retry request', () {
      fakeAsync((async) {
        final repository = _RecordingRepository()
          ..seedUpdate(
            _snapshot(
              state: LearningUpdateState.failed,
              failure: _terminalExtraction,
            ),
          );
        final controller = _controller(repository: repository);

        controller.initialize();
        async.flushMicrotasks();

        expect(controller.currentState.canRetryExtraction, isFalse);
        controller.retryExtraction();
        async.flushMicrotasks();
        expect(repository.retryKeys, isEmpty);

        controller.dispose();
      });
    });

    test('source cleanup retry keeps committed knowledge', () {
      fakeAsync((async) {
        final repository = _RecordingRepository()
          ..seedUpdate(
            _snapshot(
              state: LearningUpdateState.committed,
              uploads: <SourceItem>[_upload()],
              deletionStatus: SourceDeletionStatus.pending,
            ),
          );
        final controller = _controller(repository: repository);

        controller.initialize();
        async.flushMicrotasks();
        expect(controller.currentState.canRetryDeletion, isTrue);

        controller.retryDeletion();
        async.flushMicrotasks();

        expect(repository.retryStages, <IngestionRetryStage>[
          IngestionRetryStage.deletion,
        ]);
        final snapshot = controller.currentState.snapshot;
        expect(snapshot?.state, LearningUpdateState.committed);
        expect(snapshot?.sourceDeletionStatus, SourceDeletionStatus.deleted);
        expect(snapshot?.uploads.single.status, SourceUploadState.deleted);
        expect(controller.currentState.canRetryDeletion, isFalse);

        controller.dispose();
      });
    });

    test('invalid retry state refreshes and explains the current state', () {
      fakeAsync((async) {
        final repository = _RecordingRepository()
          ..seedUpdate(
            _snapshot(
              state: LearningUpdateState.failed,
              failure: _retryableExtraction,
            ),
          );
        final controller = _controller(repository: repository);

        controller.initialize();
        async.flushMicrotasks();

        repository.failures[IngestionOperation.retry] = const IngestionFailure(
          code: 'invalid_state',
          message: 'That action is not available right now.',
          nextAction: 'Refresh this material and try again.',
        );
        controller.retryExtraction();
        async.flushMicrotasks();

        // The stale action is explained from a fresh authoritative read.
        expect(
          repository.operations.where((op) => op == IngestionOperation.get),
          hasLength(2),
        );
        expect(controller.currentState.failure?.code, 'invalid_state');
        expect(controller.currentState.isRetrying, isFalse);

        controller.dispose();
      });
    });

    test('dispose cancels every pending poll and timer', () {
      fakeAsync((async) {
        final repository = _RecordingRepository()..seedUpdate(_snapshot());
        final controller = _controller(repository: repository);

        controller.initialize();
        async.flushMicrotasks();
        final calls = repository.operations.length;

        controller.dispose();
        async.elapse(const Duration(hours: 1));

        expect(repository.operations.length, calls);
      });
    });
  });
}
