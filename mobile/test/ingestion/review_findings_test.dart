import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/ingestion/application/ingestion_flow_controller.dart';
import 'package:memora_mobile/src/features/ingestion/application/verification_controller.dart';
import 'package:memora_mobile/src/features/ingestion/data/ingestion_draft_store.dart';
import 'package:memora_mobile/src/features/ingestion/data/ingestion_repository.dart';
import 'package:memora_mobile/src/features/ingestion/data/source_picker.dart';
import 'package:memora_mobile/src/features/ingestion/data/upload_client.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_failure.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_models.dart';

/// Regression tests for the T10 bug-hunt findings (Commit 10). Each group
/// locks one finding: durable key scoping, create-collision recovery,
/// persisted verification decisions (UIX-033) and conflict reloads keeping
/// decisions beyond the first candidate page.

const String _accountId = 'account-a';
const String _subjectId = '22222222-2222-4222-8222-222222222222';
const String _updateId = '11111111-1111-4111-8111-111111111111';
const String _otherUpdateId = '33333333-3333-4333-8333-333333333333';

const IngestionFailure _reusedKey = IngestionFailure(
  code: 'idempotency_key_reused',
  message: 'That request has already been completed.',
  nextAction: 'Start this step again as a new attempt.',
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
  );
}

CandidateItem _reviewCandidate(String id, {int version = 1}) {
  return CandidateItem(
    id: id,
    candidateType: 'concept',
    displayTitle: 'Concept $id',
    displaySummary: 'Extracted from this learning update.',
    sourceContext: 'From your text',
    confidence: 0.62,
    band: ConfidenceBand.medium,
    requiresVerification: true,
    status: CandidateState.needsVerification,
    candidateVersion: version,
  );
}

/// Reads the durable operation-key map so tests can assert on identity
/// scoping and cleanup directly.
Future<Map<String, String>> _storedOperationKeys(
  InMemorySecureKeyStore keyStore,
) async {
  final raw = await keyStore.read(
    IngestionDraftStore.operationsStorageKey(_accountId),
  );
  if (raw == null) return <String, String>{};
  final record = jsonDecode(raw) as Map<String, dynamic>;
  final keys = record['keys'] as Map<String, dynamic>;
  return <String, String>{
    for (final entry in keys.entries) entry.key: entry.value as String,
  };
}

Future<String> _seedOtherUpdateState(IngestionDraftStore draftStore) async {
  await draftStore.saveDecisionDrafts(
    accountId: _accountId,
    updateId: _otherUpdateId,
    drafts: <String, DecisionDraft>{
      'c-other': const DecisionDraft(
        candidateId: 'c-other',
        candidateVersion: 1,
        kind: VerificationDecisionKind.accept,
      ),
    },
  );
  return draftStore.operationKey(
    accountId: _accountId,
    operation: 'commit:$_otherUpdateId',
  );
}

Future<void> _expectOtherUpdatePreserved(
  IngestionDraftStore draftStore,
  String key,
) async {
  final decisions = await draftStore.readDecisionDrafts(_accountId);
  expect(decisions.containsKey(_otherUpdateId), isTrue);
  expect(
    await draftStore.operationKey(
      accountId: _accountId,
      operation: 'commit:$_otherUpdateId',
    ),
    key,
  );
}

class _RecordingRepository extends MockIngestionRepository {
  _RecordingRepository() : super(autoAdvanceProcessing: false);

  final List<String> createIdempotencyKeys = <String>[];
  final List<String> grantKeys = <String>[];
  final List<String> finalizeKeys = <String>[];
  final List<List<DecisionDraft>> decisionBatches = <List<DecisionDraft>>[];

  @override
  Future<UpdateSnapshot> createUpdate({
    required String accessToken,
    required String subjectId,
    required IngestionInputType inputType,
    required DateTime learnedAt,
    required String clientOperationId,
    required String idempotencyKey,
    String? manualText,
    List<DeclaredSource> files = const <DeclaredSource>[],
  }) {
    createIdempotencyKeys.add(idempotencyKey);
    return super.createUpdate(
      accessToken: accessToken,
      subjectId: subjectId,
      inputType: inputType,
      learnedAt: learnedAt,
      clientOperationId: clientOperationId,
      idempotencyKey: idempotencyKey,
      manualText: manualText,
      files: files,
    );
  }

  @override
  Future<UploadGrant> createUploadGrant({
    required String accessToken,
    required String updateId,
    required DeclaredSource source,
    required String idempotencyKey,
  }) {
    grantKeys.add(idempotencyKey);
    return super.createUploadGrant(
      accessToken: accessToken,
      updateId: updateId,
      source: source,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<UpdateSnapshot> finalizeUpload({
    required String accessToken,
    required String updateId,
    required String uploadId,
    required int observedSize,
    required String contentSha256,
    required String clientOperationId,
    required String idempotencyKey,
  }) {
    finalizeKeys.add(idempotencyKey);
    return super.finalizeUpload(
      accessToken: accessToken,
      updateId: updateId,
      uploadId: uploadId,
      observedSize: observedSize,
      contentSha256: contentSha256,
      clientOperationId: clientOperationId,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<VerificationOutcome> submitDecisions({
    required String accessToken,
    required String updateId,
    required List<DecisionDraft> decisions,
    required String idempotencyKey,
  }) {
    decisionBatches.add(List<DecisionDraft>.of(decisions));
    return super.submitDecisions(
      accessToken: accessToken,
      updateId: updateId,
      decisions: decisions,
      idempotencyKey: idempotencyKey,
    );
  }
}

class _FakeSourcePicker implements SourcePicker {
  PickedSource? nextDocument;

  @override
  Future<PickedSource?> pickDocument() async => nextDocument;

  @override
  Future<PickedSource?> pickCamera() async => null;

  @override
  Future<PickedSource?> pickGallery() async => null;
}

class _FakeUploadClient implements UploadClient {
  final UploadClient _prepareClient = PresignedUploadClient();

  @override
  Future<PreparedUpload> prepare(UploadSource source) {
    return _prepareClient.prepare(source);
  }

  @override
  Future<void> upload({
    required UploadGrant grant,
    required PreparedUpload upload,
    void Function(int sent, int total)? onProgress,
    dynamic cancelToken,
  }) async {}
}

PickedSource _pdf() {
  return PickedSource(
    name: 'notes.pdf',
    mediaType: 'application/pdf',
    byteSize: 4,
    bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
  );
}

void main() {
  group('Finding 1: upload identities are scoped per update and file', () {
    test(
      'a failed upload persists its key under the update-scoped name only',
      () async {
        final keyStore = InMemorySecureKeyStore();
        final draftStore = IngestionDraftStore(keyStore: keyStore);
        final repository = _RecordingRepository()
          ..failures[IngestionOperation.grant] = _offline;
        final picker = _FakeSourcePicker()..nextDocument = _pdf();
        final session = _sessionController();
        final controller = IngestionFlowController(
          repository: repository,
          uploadClient: _FakeUploadClient(),
          sourcePicker: picker,
          draftStore: draftStore,
          sessionController: session,
          subjectId: _subjectId,
          draftDebounce: Duration.zero,
        );
        addTearDown(controller.dispose);
        addTearDown(session.dispose);

        await controller.initialize();
        await controller.addDocument();
        await controller.extractConcepts();

        final updateId = controller.currentState.updateId;
        expect(updateId, isNotNull);
        final sha = sha256.convert(<int>[1, 2, 3, 4]).toString();
        final keys = await _storedOperationKeys(keyStore);

        expect(
          keys.containsKey('grant:$updateId:$sha'),
          isTrue,
          reason: 'the durable grant key survives for the retry',
        );
        expect(
          keys.containsKey('grant:$sha'),
          isFalse,
          reason:
              'the key is scoped per update so another update can never '
              'reuse it with a different body',
        );
        expect(keys.containsKey('finalize:$updateId:$sha'), isFalse);
      },
    );

    test('a reused-key grant failure clears the identity so the retry '
        'starts a fresh operation', () async {
      final keyStore = InMemorySecureKeyStore();
      final draftStore = IngestionDraftStore(keyStore: keyStore);
      final repository = _RecordingRepository()
        ..failures[IngestionOperation.grant] = _reusedKey;
      final picker = _FakeSourcePicker()..nextDocument = _pdf();
      final session = _sessionController();
      final controller = IngestionFlowController(
        repository: repository,
        uploadClient: _FakeUploadClient(),
        sourcePicker: picker,
        draftStore: draftStore,
        sessionController: session,
        subjectId: _subjectId,
        draftDebounce: Duration.zero,
      );
      addTearDown(controller.dispose);
      addTearDown(session.dispose);

      await controller.initialize();
      await controller.addDocument();
      await controller.extractConcepts();

      expect(
        controller.currentState.sources.single.failure?.code,
        'idempotency_key_reused',
      );
      final updateId = controller.currentState.updateId;
      final sha = sha256.convert(<int>[1, 2, 3, 4]).toString();
      final keysAfterFailure = await _storedOperationKeys(keyStore);
      expect(
        keysAfterFailure.containsKey('grant:$updateId:$sha'),
        isFalse,
        reason: 'the stale identity is dropped for a fresh attempt',
      );

      repository.failures.remove(IngestionOperation.grant);
      await controller.retrySubmission();

      expect(controller.currentState.stage, IngestionFlowStage.submitted);
      expect(repository.grantKeys, hasLength(2));
      expect(
        repository.grantKeys[0],
        isNot(equals(repository.grantKeys[1])),
        reason: 'the retry must not replay the collided identity',
      );
    });
  });

  group('Finding 2: a create identity collision recovers with the draft '
      'preserved', () {
    test(
      'the stale create identity is cleared and the next attempt creates',
      () async {
        final keyStore = InMemorySecureKeyStore();
        final draftStore = IngestionDraftStore(keyStore: keyStore);
        final repository = _RecordingRepository()
          ..failures[IngestionOperation.create] = _reusedKey;
        final session = _sessionController();
        final controller = IngestionFlowController(
          repository: repository,
          uploadClient: _FakeUploadClient(),
          sourcePicker: _FakeSourcePicker(),
          draftStore: draftStore,
          sessionController: session,
          subjectId: _subjectId,
          draftDebounce: Duration.zero,
        );
        addTearDown(controller.dispose);
        addTearDown(session.dispose);

        await controller.initialize();
        controller.onManualTextChanged('Newton first law');
        await controller.extractConcepts();

        // The collision surfaces as a restartable failure; the draft survives.
        expect(controller.currentState.stage, IngestionFlowStage.editing);
        expect(controller.currentState.failure?.code, 'idempotency_key_reused');
        final restored = await draftStore.readDraft(_accountId);
        expect(restored?.manualText, 'Newton first law');
        final keysAfterFailure = await _storedOperationKeys(keyStore);
        expect(keysAfterFailure.containsKey('create'), isFalse);
        expect(keysAfterFailure.containsKey('create_operation'), isFalse);

        repository.failures.remove(IngestionOperation.create);
        await controller.extractConcepts();

        expect(controller.currentState.stage, IngestionFlowStage.submitted);
        expect(repository.createIdempotencyKeys, hasLength(2));
        expect(
          repository.createIdempotencyKeys[0],
          isNot(equals(repository.createIdempotencyKeys[1])),
          reason:
              'the retry creates a fresh update instead of replaying the '
              'collided identity',
        );
      },
    );
  });

  group('Finding 3: unsent verification decisions persist (UIX-033)', () {
    test(
      'decisions survive a controller recreation and submit once restored',
      () async {
        final keyStore = InMemorySecureKeyStore();
        final draftStore = IngestionDraftStore(keyStore: keyStore);
        final repository = _RecordingRepository();
        repository.seedUpdate(
          _snapshot(),
          candidates: <CandidateItem>[_reviewCandidate('c1')],
        );
        final session = _sessionController();

        final first = VerificationController(
          repository: repository,
          draftStore: draftStore,
          sessionController: session,
          updateId: _updateId,
        );
        await first.initialize();
        first.accept('c1');
        await first.flushPersistedDraftsForTest();
        first.dispose();

        final second = VerificationController(
          repository: repository,
          draftStore: draftStore,
          sessionController: session,
          updateId: _updateId,
        );
        await second.initialize();

        expect(second.currentState.drafts.keys, <String>['c1']);
        final submitted = await second.submitAndContinue();
        expect(submitted, isTrue);
        expect(
          repository.decisionBatches.single.map((draft) => draft.candidateId),
          <String>['c1'],
        );
        expect(second.currentState.drafts, isEmpty);
        final persisted = await draftStore.readDecisionDrafts(_accountId);
        expect(
          persisted.containsKey(_updateId),
          isFalse,
          reason: 'submitted decisions no longer persist locally',
        );
        second.dispose();
        session.dispose();
      },
    );

    test('a non-verifiable update forgets its persisted decisions', () async {
      final keyStore = InMemorySecureKeyStore();
      final draftStore = IngestionDraftStore(keyStore: keyStore);
      final repository = _RecordingRepository();
      repository.seedUpdate(_snapshot(state: LearningUpdateState.committed));
      final session = _sessionController();
      final controller = VerificationController(
        repository: repository,
        draftStore: draftStore,
        sessionController: session,
        updateId: _updateId,
      );

      await draftStore.saveDecisionDrafts(
        accountId: _accountId,
        updateId: _updateId,
        drafts: <String, DecisionDraft>{
          'c1': const DecisionDraft(
            candidateId: 'c1',
            candidateVersion: 1,
            kind: VerificationDecisionKind.accept,
          ),
        },
      );

      await controller.initialize();

      expect(controller.currentState.isInvalidState, isTrue);
      final persisted = await draftStore.readDecisionDrafts(_accountId);
      expect(persisted.containsKey(_updateId), isFalse);
      controller.dispose();
      session.dispose();
    });

    test('a successful commit forgets the persisted decisions', () async {
      final keyStore = InMemorySecureKeyStore();
      final draftStore = IngestionDraftStore(keyStore: keyStore);
      final repository = _RecordingRepository();
      repository.seedUpdate(
        _snapshot(),
        candidates: <CandidateItem>[
          CandidateItem(
            id: 'c-accepted',
            candidateType: 'concept',
            displayTitle: 'Newton first law',
            confidence: 0.94,
            band: ConfidenceBand.high,
            requiresVerification: false,
            status: CandidateState.accepted,
            candidateVersion: 1,
          ),
        ],
      );
      final session = _sessionController();
      final controller = PathPreviewController(
        repository: repository,
        draftStore: draftStore,
        sessionController: session,
        updateId: _updateId,
      );

      await draftStore.saveDecisionDrafts(
        accountId: _accountId,
        updateId: _updateId,
        drafts: <String, DecisionDraft>{
          'c1': const DecisionDraft(
            candidateId: 'c1',
            candidateVersion: 1,
            kind: VerificationDecisionKind.accept,
          ),
        },
      );

      await controller.initialize();
      final committed = await controller.commit();

      expect(committed, isTrue);
      final persisted = await draftStore.readDecisionDrafts(_accountId);
      expect(persisted.containsKey(_updateId), isFalse);
      controller.dispose();
      session.dispose();
    });
  });

  group(
    'Finding 4: a conflict reload keeps decisions beyond the first page',
    () {
      test(
        'fetches further pages until preserved decisions are found',
        () async {
          final keyStore = InMemorySecureKeyStore();
          final draftStore = IngestionDraftStore(keyStore: keyStore);
          final repository = _RecordingRepository();
          repository.seedUpdate(
            _snapshot(),
            candidates: List<CandidateItem>.generate(
              25,
              (index) => _reviewCandidate('c-${index + 1}'),
            ),
          );
          final session = _sessionController();
          final controller = VerificationController(
            repository: repository,
            draftStore: draftStore,
            sessionController: session,
            updateId: _updateId,
            pageSize: 20,
          );
          addTearDown(controller.dispose);
          addTearDown(session.dispose);

          await controller.initialize();
          await controller.loadMore();
          controller.accept('c-21');
          await controller.flushPersistedDraftsForTest();

          repository.failures[IngestionOperation
              .decisions] = const IngestionFailure(
            code: 'version_conflict',
            message: 'This information has changed. Please review it again.',
          );
          final submitted = await controller.submitAndContinue();

          expect(submitted, isFalse);
          expect(controller.currentState.conflictNotice, isNotNull);
          // The reload pulled the second page so the preserved decision stayed.
          expect(controller.currentState.candidates, hasLength(25));
          expect(controller.currentState.drafts.containsKey('c-21'), isTrue);

          repository.failures.remove(IngestionOperation.decisions);
          final retried = await controller.submitAndContinue();

          expect(retried, isTrue);
          expect(
            repository.decisionBatches.last.map((draft) => draft.candidateId),
            contains('c-21'),
          );
          expect(controller.currentState.drafts, isEmpty);
        },
      );
    },
  );

  group('Finding 5: submission cleanup keeps other updates intact', () {
    test(
      'a completed submission keeps another update\'s decisions and keys',
      () async {
        final keyStore = InMemorySecureKeyStore();
        final draftStore = IngestionDraftStore(keyStore: keyStore);
        final repository = _RecordingRepository();
        final session = _sessionController();
        final controller = IngestionFlowController(
          repository: repository,
          uploadClient: _FakeUploadClient(),
          sourcePicker: _FakeSourcePicker(),
          draftStore: draftStore,
          sessionController: session,
          subjectId: _subjectId,
          draftDebounce: Duration.zero,
        );
        addTearDown(controller.dispose);
        addTearDown(session.dispose);
        final otherKey = await _seedOtherUpdateState(draftStore);

        await controller.initialize();
        controller.onManualTextChanged('Newton first law');
        await controller.extractConcepts();

        expect(controller.currentState.stage, IngestionFlowStage.submitted);
        expect(await draftStore.readDraft(_accountId), isNull);
        await _expectOtherUpdatePreserved(draftStore, otherKey);
      },
    );

    test('discard keeps another update\'s decisions and keys', () async {
      final keyStore = InMemorySecureKeyStore();
      final draftStore = IngestionDraftStore(keyStore: keyStore);
      final repository = _RecordingRepository();
      final snapshot = _snapshot(state: LearningUpdateState.draft);
      repository.seedUpdate(snapshot);
      await draftStore.saveDraft(
        _accountId,
        IngestionDraft(
          subjectId: _subjectId,
          manualText: 'Newton first law',
          learnedAt: DateTime.utc(2026, 11, 1, 10),
        ),
      );
      final session = _sessionController();
      final controller = IngestionFlowController(
        repository: repository,
        uploadClient: _FakeUploadClient(),
        sourcePicker: _FakeSourcePicker(),
        draftStore: draftStore,
        sessionController: session,
        subjectId: _subjectId,
        resumedDraft: snapshot,
        draftDebounce: Duration.zero,
      );
      addTearDown(controller.dispose);
      addTearDown(session.dispose);
      final otherKey = await _seedOtherUpdateState(draftStore);

      await controller.initialize();
      final discarded = await controller.discard();

      expect(discarded, isTrue);
      expect(await draftStore.readDraft(_accountId), isNull);
      await _expectOtherUpdatePreserved(draftStore, otherKey);
    });
  });
}

const IngestionFailure _offline = IngestionFailure(
  code: 'network_error',
  message: 'Memora could not reach the server.',
  nextAction: 'Check your connection and try again.',
  retryable: true,
);
