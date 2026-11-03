import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/ingestion/application/verification_controller.dart';
import 'package:memora_mobile/src/features/ingestion/data/ingestion_draft_store.dart';
import 'package:memora_mobile/src/features/ingestion/data/ingestion_repository.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_failure.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_models.dart';

const String _accountId = 'account-a';
const String _subjectId = '22222222-2222-4222-8222-222222222222';
const String _updateId = '11111111-1111-4111-8111-111111111111';

const IngestionFailure _offline = IngestionFailure(
  code: 'network_error',
  message: 'Memora could not reach the server.',
  nextAction: 'Check your connection and try again.',
  retryable: true,
);

const CandidateItem _highConfidence = CandidateItem(
  id: 'candidate-high',
  candidateType: 'concept',
  displayTitle: 'Newton first law',
  displaySummary:
      'An object remains at rest or in uniform motion unless acted on.',
  sourceContext: 'From your text',
  confidence: 0.94,
  band: ConfidenceBand.high,
  requiresVerification: false,
  status: CandidateState.accepted,
  candidateVersion: 1,
);

CandidateItem _reviewCandidate(
  String id, {
  String? title,
  int version = 1,
  CandidateState status = CandidateState.needsVerification,
}) {
  return CandidateItem(
    id: id,
    candidateType: 'concept',
    displayTitle: title ?? 'Concept $id',
    displaySummary: 'Extracted from this learning update.',
    sourceContext: 'From your text',
    confidence: 0.62,
    band: ConfidenceBand.medium,
    requiresVerification: true,
    status: status,
    candidateVersion: version,
  );
}

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
  LearningUpdateState state = LearningUpdateState.verificationRequired,
}) {
  return UpdateSnapshot(
    id: _updateId,
    subjectId: _subjectId,
    inputType: IngestionInputType.manualText,
    state: state,
    hasManualText: true,
    learnedAt: DateTime.utc(2026, 11, 1),
    createdAt: DateTime.utc(2026, 11, 1),
    updatedAt: DateTime.utc(2026, 11, 1),
    rowVersion: 1,
    sourceDeletionStatus: SourceDeletionStatus.notRequired,
    uploads: const <SourceItem>[],
  );
}

class _RecordingRepository extends MockIngestionRepository {
  _RecordingRepository() : super(autoAdvanceProcessing: false);

  final List<List<DecisionDraft>> decisionBatches = <List<DecisionDraft>>[];
  final List<String> decisionKeys = <String>[];

  @override
  Future<VerificationOutcome> submitDecisions({
    required String accessToken,
    required String updateId,
    required List<DecisionDraft> decisions,
    required String idempotencyKey,
  }) {
    decisionBatches.add(List<DecisionDraft>.of(decisions));
    decisionKeys.add(idempotencyKey);
    return super.submitDecisions(
      accessToken: accessToken,
      updateId: updateId,
      decisions: decisions,
      idempotencyKey: idempotencyKey,
    );
  }
}

class _BlockingRepository extends _RecordingRepository {
  final Completer<void> gate = Completer<void>();

  @override
  Future<VerificationOutcome> submitDecisions({
    required String accessToken,
    required String updateId,
    required List<DecisionDraft> decisions,
    required String idempotencyKey,
  }) async {
    await gate.future;
    return super.submitDecisions(
      accessToken: accessToken,
      updateId: updateId,
      decisions: decisions,
      idempotencyKey: idempotencyKey,
    );
  }
}

class _Harness {
  _Harness({
    required this.repository,
    required this.session,
    required this.keyStore,
    required this.draftStore,
    required this.controller,
  });

  final _RecordingRepository repository;
  final SessionController session;
  final InMemorySecureKeyStore keyStore;
  final IngestionDraftStore draftStore;
  final VerificationController controller;

  void dispose() {
    controller.dispose();
    session.dispose();
  }
}

_Harness _harness({
  List<CandidateItem>? candidates,
  LearningUpdateState state = LearningUpdateState.verificationRequired,
  int pageSize = 20,
  _RecordingRepository? repository,
  bool seedUpdate = true,
}) {
  final repo = repository ?? _RecordingRepository();
  if (seedUpdate) {
    repo.seedUpdate(_snapshot(state: state), candidates: candidates);
  }
  final session = _sessionController();
  final keyStore = InMemorySecureKeyStore();
  final draftStore = IngestionDraftStore(keyStore: keyStore);
  final controller = VerificationController(
    repository: repo,
    draftStore: draftStore,
    sessionController: session,
    updateId: _updateId,
    pageSize: pageSize,
  );
  return _Harness(
    repository: repo,
    session: session,
    keyStore: keyStore,
    draftStore: draftStore,
    controller: controller,
  );
}

void main() {
  group('VerificationController', () {
    test('loads candidates and separates confident from Check this', () async {
      final harness = _harness(
        candidates: <CandidateItem>[
          _highConfidence,
          _reviewCandidate('c-medium'),
          _reviewCandidate('c-low', version: 3),
        ],
      );
      addTearDown(harness.dispose);

      await harness.controller.initialize();

      final state = harness.controller.currentState;
      expect(state.stage, VerificationStage.ready);
      expect(state.update?.state, LearningUpdateState.verificationRequired);
      expect(state.candidates, hasLength(3));
      expect(state.readyCandidates.map((candidate) => candidate.id), <String>[
        _highConfidence.id,
      ]);
      expect(state.reviewCandidates.map((candidate) => candidate.id), <String>[
        'c-medium',
        'c-low',
      ]);
      expect(state.includedCount, 1);
      expect(state.unresolvedCount, 2);
      expect(state.canPreview, isTrue);
      expect(state.previewDisabledReason, isNull);
      expect(harness.repository.operations, <IngestionOperation>[
        IngestionOperation.get,
        IngestionOperation.candidates,
      ]);
    });

    test('loads the next page without discarding local decisions', () async {
      final harness = _harness(
        candidates: <CandidateItem>[
          _reviewCandidate('c-one'),
          _reviewCandidate('c-two'),
          _reviewCandidate('c-three'),
        ],
        pageSize: 2,
      );
      addTearDown(harness.dispose);

      await harness.controller.initialize();
      expect(harness.controller.currentState.candidates, hasLength(2));
      expect(harness.controller.currentState.hasMore, isTrue);
      expect(harness.controller.currentState.nextCursor, '2');

      harness.controller.accept('c-one');
      await harness.controller.loadMore();

      final state = harness.controller.currentState;
      expect(state.candidates, hasLength(3));
      expect(state.hasMore, isFalse);
      expect(state.nextCursor, isNull);
      expect(state.draftFor('c-one')?.kind, VerificationDecisionKind.accept);
      expect(
        harness.repository.operations.where(
          (operation) => operation == IngestionOperation.candidates,
        ),
        hasLength(2),
      );
    });

    test(
      'keeps accept, edit, reject and merge local until one batch',
      () async {
        final harness = _harness(
          candidates: <CandidateItem>[
            _highConfidence,
            _reviewCandidate('c-accept'),
            _reviewCandidate('c-edit'),
            _reviewCandidate('c-reject'),
            _reviewCandidate('c-merge'),
          ],
        );
        addTearDown(harness.dispose);

        await harness.controller.initialize();
        harness.controller.accept('c-accept');
        harness.controller.editTitle('c-edit', '  Corrected concept  ');
        harness.controller.reject('c-reject');
        harness.controller.mergeInto('c-merge', _highConfidence.id);

        final drafts = harness.controller.currentState.drafts;
        expect(drafts['c-accept']?.kind, VerificationDecisionKind.accept);
        expect(drafts['c-accept']?.editedTitle, isNull);
        expect(drafts['c-edit']?.kind, VerificationDecisionKind.edit);
        expect(drafts['c-edit']?.editedTitle, 'Corrected concept');
        expect(drafts['c-reject']?.kind, VerificationDecisionKind.reject);
        expect(drafts['c-merge']?.kind, VerificationDecisionKind.merge);
        expect(drafts['c-merge']?.mergeIntoCandidateId, _highConfidence.id);
        expect(harness.repository.decisionBatches, isEmpty);

        expect(await harness.controller.submitAndContinue(), isTrue);

        expect(harness.repository.decisionBatches, hasLength(1));
        final submitted = <String, DecisionDraft>{
          for (final decision in harness.repository.decisionBatches.single)
            decision.candidateId: decision,
        };
        expect(submitted, hasLength(4));
        expect(submitted['c-accept']?.kind, VerificationDecisionKind.accept);
        expect(submitted['c-edit']?.editedTitle, 'Corrected concept');
        expect(submitted['c-reject']?.kind, VerificationDecisionKind.reject);
        expect(submitted['c-merge']?.mergeIntoCandidateId, _highConfidence.id);

        final state = harness.controller.currentState;
        expect(state.drafts, isEmpty);
        expect(state.isSubmitting, isFalse);
        expect(state.lockedCandidateIds, isEmpty);
        expect(state.candidates.first.status, CandidateState.accepted);
        final edited = state.candidates.firstWhere(
          (candidate) => candidate.id == 'c-edit',
        );
        expect(edited.displayTitle, 'Corrected concept');
        expect(edited.status, CandidateState.accepted);
        expect(edited.requiresVerification, isFalse);
        expect(
          state.candidates
              .firstWhere((candidate) => candidate.id == 'c-reject')
              .status,
          CandidateState.rejected,
        );
        expect(state.includedCount, 4);

        final raw = await harness.keyStore.read(
          IngestionDraftStore.operationsStorageKey(_accountId),
        );
        expect(
          raw == null || !raw.contains(harness.repository.decisionKeys.single),
          isTrue,
        );
      },
    );

    test(
      'a double tap submits one batch and locks only affected controls',
      () async {
        final repository = _BlockingRepository();
        final harness = _harness(
          repository: repository,
          candidates: <CandidateItem>[
            _reviewCandidate('c-one'),
            _reviewCandidate('c-two'),
          ],
        );
        addTearDown(harness.dispose);

        await harness.controller.initialize();
        harness.controller.accept('c-one');

        final first = harness.controller.submitAndContinue();
        final second = harness.controller.submitAndContinue();

        expect(await second, isFalse);
        expect(harness.controller.currentState.isSubmitting, isTrue);
        expect(harness.controller.currentState.lockedCandidateIds, <String>{
          'c-one',
        });
        expect(
          harness.controller.currentState.lockedCandidateIds,
          isNot(contains('c-two')),
        );
        expect(repository.decisionBatches, isEmpty);

        repository.gate.complete();

        expect(await first, isTrue);
        expect(repository.decisionBatches, hasLength(1));
        expect(repository.decisionKeys, hasLength(1));
        expect(harness.controller.currentState.lockedCandidateIds, isEmpty);
      },
    );

    test('retrying the same batch reuses the durable key', () async {
      final harness = _harness(
        candidates: <CandidateItem>[_reviewCandidate('c-one')],
      );
      addTearDown(harness.dispose);

      await harness.controller.initialize();
      harness.controller.accept('c-one');

      harness.repository.failures[IngestionOperation.decisions] = _offline;
      expect(await harness.controller.submitAndContinue(), isFalse);

      var state = harness.controller.currentState;
      expect(state.failure?.code, 'network_error');
      expect(state.isOffline, isTrue);
      expect(state.isSubmitting, isFalse);
      expect(state.lockedCandidateIds, isEmpty);
      expect(state.draftFor('c-one')?.kind, VerificationDecisionKind.accept);

      harness.repository.failures.remove(IngestionOperation.decisions);
      expect(await harness.controller.submitAndContinue(), isTrue);

      expect(harness.repository.decisionKeys, hasLength(2));
      expect(
        harness.repository.decisionKeys[0],
        harness.repository.decisionKeys[1],
      );

      state = harness.controller.currentState;
      expect(state.failure, isNull);
      expect(state.isOffline, isFalse);
      expect(state.draftFor('c-one'), isNull);
      expect(state.candidates.single.status, CandidateState.accepted);
      expect(state.candidates.single.requiresVerification, isFalse);

      final raw = await harness.keyStore.read(
        IngestionDraftStore.operationsStorageKey(_accountId),
      );
      expect(
        raw == null || !raw.contains(harness.repository.decisionKeys.last),
        isTrue,
      );
    });

    test('a changed batch gets a new durable key', () async {
      final harness = _harness(
        candidates: <CandidateItem>[_reviewCandidate('c-one')],
      );
      addTearDown(harness.dispose);

      await harness.controller.initialize();
      harness.controller.accept('c-one');

      harness.repository.failures[IngestionOperation.decisions] = _offline;
      expect(await harness.controller.submitAndContinue(), isFalse);
      harness.repository.failures.remove(IngestionOperation.decisions);

      harness.controller.editTitle('c-one', 'A corrected title');
      expect(await harness.controller.submitAndContinue(), isTrue);

      expect(harness.repository.decisionKeys, hasLength(2));
      expect(
        harness.repository.decisionKeys[0],
        isNot(harness.repository.decisionKeys[1]),
      );
      expect(
        harness.controller.currentState.candidates.single.displayTitle,
        'A corrected title',
      );
    });

    test('a version conflict refreshes and keeps only safe edits', () async {
      final harness = _harness(
        candidates: <CandidateItem>[
          _reviewCandidate('c-same', title: 'Unchanged concept'),
          _reviewCandidate('c-changed', title: 'Original title'),
        ],
      );
      addTearDown(harness.dispose);

      await harness.controller.initialize();
      harness.controller.editTitle('c-same', 'My safe edit');
      harness.controller.editTitle('c-changed', 'My stale edit');

      harness.repository.seedUpdate(
        _snapshot(),
        candidates: <CandidateItem>[
          _reviewCandidate('c-same', title: 'Unchanged concept', version: 2),
          _reviewCandidate(
            'c-changed',
            title: 'Server changed this title',
            version: 2,
          ),
        ],
      );

      expect(await harness.controller.submitAndContinue(), isFalse);

      final state = harness.controller.currentState;
      expect(state.stage, VerificationStage.ready);
      expect(state.conflictNotice, isNotNull);
      expect(
        state.conflictNotice,
        contains('changed while you were reviewing'),
      );
      expect(state.isSubmitting, isFalse);
      expect(state.lockedCandidateIds, isEmpty);
      expect(state.draftFor('c-same')?.editedTitle, 'My safe edit');
      expect(state.draftFor('c-same')?.candidateVersion, 2);
      expect(state.draftFor('c-changed'), isNull);
      expect(
        state.candidates
            .firstWhere((candidate) => candidate.id == 'c-changed')
            .displayTitle,
        'Server changed this title',
      );
      expect(harness.repository.decisionKeys, hasLength(1));
    });

    test(
      'a merge draft is dropped when its target is no longer valid',
      () async {
        final harness = _harness(
          candidates: <CandidateItem>[
            _reviewCandidate('c-source'),
            _highConfidence,
          ],
        );
        addTearDown(harness.dispose);

        await harness.controller.initialize();
        harness.controller.mergeInto('c-source', _highConfidence.id);
        expect(
          harness.controller.currentState.draftFor('c-source')?.kind,
          VerificationDecisionKind.merge,
        );

        harness.repository.seedUpdate(
          _snapshot(),
          candidates: <CandidateItem>[
            _reviewCandidate('c-source', version: 2),
            CandidateItem(
              id: _highConfidence.id,
              candidateType: _highConfidence.candidateType,
              displayTitle: _highConfidence.displayTitle,
              displaySummary: _highConfidence.displaySummary,
              sourceContext: _highConfidence.sourceContext,
              confidence: _highConfidence.confidence,
              band: _highConfidence.band,
              requiresVerification: false,
              status: CandidateState.rejected,
              candidateVersion: 2,
            ),
          ],
        );

        expect(await harness.controller.submitAndContinue(), isFalse);

        final state = harness.controller.currentState;
        expect(state.draftFor('c-source'), isNull);
        expect(state.conflictNotice, isNotNull);
        expect(state.isSubmitting, isFalse);
      },
    );

    test(
      'a wrong update state becomes invalidState for a safe redirect',
      () async {
        final harness = _harness(
          candidates: <CandidateItem>[_reviewCandidate('c-one')],
        );
        addTearDown(harness.dispose);

        await harness.controller.initialize();
        expect(harness.controller.currentState.stage, VerificationStage.ready);

        harness.repository.seedUpdate(
          _snapshot(state: LearningUpdateState.committed),
        );
        await harness.controller.refresh();

        final state = harness.controller.currentState;
        expect(state.stage, VerificationStage.invalidState);
        expect(state.isInvalidState, isTrue);
        expect(state.update?.state, LearningUpdateState.committed);
        expect(state.failure, isNull);
        expect(
          harness.repository.operations.where(
            (operation) => operation == IngestionOperation.get,
          ),
          hasLength(2),
        );
      },
    );

    test('a refresh failure keeps candidates and local edits', () async {
      final harness = _harness(
        candidates: <CandidateItem>[_reviewCandidate('c-one')],
      );
      addTearDown(harness.dispose);

      await harness.controller.initialize();
      harness.controller.editTitle('c-one', 'My edit');

      harness.repository.failures[IngestionOperation.get] = _offline;
      await harness.controller.refresh();

      var state = harness.controller.currentState;
      expect(state.stage, VerificationStage.ready);
      expect(state.isOffline, isTrue);
      expect(state.failure?.code, 'network_error');
      expect(state.candidates, hasLength(1));
      expect(state.draftFor('c-one')?.editedTitle, 'My edit');

      harness.repository.failures.remove(IngestionOperation.get);
      await harness.controller.refresh();

      state = harness.controller.currentState;
      expect(state.isOffline, isFalse);
      expect(state.failure, isNull);
      expect(state.draftFor('c-one')?.editedTitle, 'My edit');
    });

    test(
      'preview stays disabled until at least one concept is included',
      () async {
        final harness = _harness(
          candidates: <CandidateItem>[
            _reviewCandidate('c-one'),
            _reviewCandidate('c-two'),
          ],
        );
        addTearDown(harness.dispose);

        await harness.controller.initialize();
        harness.controller.reject('c-one');
        harness.controller.reject('c-two');

        var state = harness.controller.currentState;
        expect(state.includedCount, 0);
        expect(state.canPreview, isFalse);
        expect(
          state.previewDisabledReason,
          'Keep at least one concept to preview your learning path.',
        );

        harness.controller.accept('c-one');
        state = harness.controller.currentState;
        expect(state.includedCount, 1);
        expect(state.canPreview, isTrue);
        expect(state.previewDisabledReason, isNull);
      },
    );

    test('an empty candidate page explains why preview is disabled', () async {
      final harness = _harness(candidates: const <CandidateItem>[]);
      addTearDown(harness.dispose);

      await harness.controller.initialize();

      final state = harness.controller.currentState;
      expect(state.stage, VerificationStage.ready);
      expect(state.candidates, isEmpty);
      expect(state.canPreview, isFalse);
      expect(
        state.previewDisabledReason,
        'No concepts were found in this material.',
      );
    });

    test(
      'confident candidates reject review controls and invalid edits',
      () async {
        final harness = _harness(
          candidates: <CandidateItem>[
            _highConfidence,
            _reviewCandidate('c-one'),
          ],
        );
        addTearDown(harness.dispose);

        await harness.controller.initialize();

        harness.controller.accept(_highConfidence.id);
        harness.controller.reject(_highConfidence.id);
        harness.controller.editTitle(_highConfidence.id, 'Should not apply');
        expect(harness.controller.currentState.drafts, isEmpty);

        harness.controller.editTitle('c-one', '   ');
        harness.controller.editTitle('c-one', 'x' * 241);
        expect(harness.controller.currentState.drafts, isEmpty);

        harness.controller.editTitle('c-one', '  Valid title  ');
        expect(
          harness.controller.currentState.draftFor('c-one')?.editedTitle,
          'Valid title',
        );

        harness.controller.mergeInto('c-one', 'c-one');
        harness.controller.mergeInto('c-one', 'missing-candidate');
        expect(
          harness.controller.currentState.draftFor('c-one')?.kind,
          VerificationDecisionKind.edit,
        );

        harness.controller.mergeInto('c-one', _highConfidence.id);
        expect(
          harness.controller.currentState.draftFor('c-one')?.kind,
          VerificationDecisionKind.merge,
        );
        expect(
          harness.controller.currentState
              .draftFor('c-one')
              ?.mergeIntoCandidateId,
          _highConfidence.id,
        );

        harness.controller.clearDecision('c-one');
        expect(harness.controller.currentState.drafts, isEmpty);
      },
    );

    test(
      'confident-only updates continue without a decisions request',
      () async {
        final harness = _harness(candidates: <CandidateItem>[_highConfidence]);
        addTearDown(harness.dispose);

        await harness.controller.initialize();

        expect(await harness.controller.submitAndContinue(), isTrue);
        expect(harness.repository.decisionKeys, isEmpty);
        expect(
          harness.repository.operations,
          isNot(contains(IngestionOperation.decisions)),
        );
      },
    );

    test('a first-read failure is recoverable', () async {
      final repository = _RecordingRepository()
        ..failures[IngestionOperation.get] = _offline;
      final harness = _harness(repository: repository);
      addTearDown(harness.dispose);

      await harness.controller.initialize();

      var state = harness.controller.currentState;
      expect(state.stage, VerificationStage.failed);
      expect(state.isOffline, isTrue);
      expect(state.failure?.code, 'network_error');

      repository.failures.remove(IngestionOperation.get);
      await harness.controller.refresh();

      state = harness.controller.currentState;
      expect(state.stage, VerificationStage.ready);
      expect(state.isOffline, isFalse);
      expect(state.failure, isNull);
    });

    test('a missing or wrong-owner update is a safe not-found', () async {
      final harness = _harness(seedUpdate: false);
      addTearDown(harness.dispose);

      await harness.controller.initialize();

      final state = harness.controller.currentState;
      expect(state.stage, VerificationStage.notFound);
      expect(state.isNotFound, isTrue);
      expect(state.failure, isNull);
    });
  });
}
