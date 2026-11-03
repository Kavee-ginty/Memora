import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/ingestion/application/ingestion_flow_controller.dart';
import 'package:memora_mobile/src/features/ingestion/data/ingestion_draft_store.dart';
import 'package:memora_mobile/src/features/ingestion/data/ingestion_repository.dart';
import 'package:memora_mobile/src/features/ingestion/data/source_picker.dart';
import 'package:memora_mobile/src/features/ingestion/data/upload_client.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_failure.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_models.dart';

const String _accountId = 'account-a';
const String _otherAccountId = 'account-b';
const String _subjectId = '22222222-2222-4222-8222-222222222222';
const String _otherSubjectId = '33333333-3333-4333-8333-333333333333';
const String _updateId = '11111111-1111-4111-8111-111111111111';

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
      SubjectSummaryDomain(
        id: _otherSubjectId,
        code: 'AL-CHEM',
        name: 'A/L Chemistry',
        curriculumEditionCode: '2026',
        curriculumVersionId: 'cur_2',
      ),
    ],
    capabilities: const CapabilityFlagsDomain(),
    serverTime: DateTime.utc(2026, 11, 1),
  );
}

SessionController _sessionController({String userId = _accountId}) {
  return SessionController(
    authRepository: MockAuthRepository(),
    sessionRepository: MockSessionRepository(),
    localStorage: AppLocalStorage(InMemorySecureKeyStore()),
    initialState: AppSessionState.active(
      session: AuthSession(accessToken: 'access-token', userId: userId),
      bootstrapData: _bootstrap(),
    ),
  );
}

class _FakeSourcePicker implements SourcePicker {
  PickedSource? nextDocument;
  PickedSource? nextCamera;
  PickedSource? nextGallery;

  @override
  Future<PickedSource?> pickDocument() async => nextDocument;

  @override
  Future<PickedSource?> pickCamera() async => nextCamera;

  @override
  Future<PickedSource?> pickGallery() async => nextGallery;
}

class _FakeUploadClient implements UploadClient {
  final UploadClient _prepareClient = PresignedUploadClient();
  IngestionFailure? uploadFailure;
  int uploadCount = 0;
  int lastReportedBytes = 0;

  @override
  Future<PreparedUpload> prepare(UploadSource source) {
    return _prepareClient.prepare(source);
  }

  @override
  Future<void> upload({
    required UploadGrant grant,
    required PreparedUpload upload,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    uploadCount++;
    lastReportedBytes = upload.source.byteSize;
    onProgress?.call(upload.source.byteSize, upload.source.byteSize);
    final failure = uploadFailure;
    if (failure != null) throw failure;
  }
}

class _RecordingRepository extends MockIngestionRepository {
  final List<IngestionInputType> createInputTypes = <IngestionInputType>[];
  final List<String> createOperationIds = <String>[];
  final List<String> createIdempotencyKeys = <String>[];
  final List<String> grantKeys = <String>[];
  final List<String> finalizeKeys = <String>[];
  final List<int> draftVersions = <int>[];

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
    createInputTypes.add(inputType);
    createOperationIds.add(clientOperationId);
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
  Future<UpdateSnapshot> updateDraft({
    required String accessToken,
    required String updateId,
    required int version,
    required String idempotencyKey,
    DateTime? learnedAt,
    String? manualText,
  }) {
    draftVersions.add(version);
    return super.updateDraft(
      accessToken: accessToken,
      updateId: updateId,
      version: version,
      idempotencyKey: idempotencyKey,
      learnedAt: learnedAt,
      manualText: manualText,
    );
  }
}

PickedSource _pdf({String name = 'notes.pdf'}) {
  return PickedSource(
    name: name,
    mediaType: 'application/pdf',
    byteSize: 4,
    bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
  );
}

PickedSource _image({String name = 'diagram.png'}) {
  return PickedSource(
    name: name,
    mediaType: 'image/png',
    byteSize: 3,
    bytes: Uint8List.fromList(<int>[9, 8, 7]),
  );
}

UpdateSnapshot _draftSnapshot({
  int rowVersion = 3,
  String subjectId = _subjectId,
}) {
  return UpdateSnapshot(
    id: _updateId,
    subjectId: subjectId,
    inputType: IngestionInputType.manualText,
    state: LearningUpdateState.draft,
    hasManualText: true,
    rowVersion: rowVersion,
    sourceDeletionStatus: SourceDeletionStatus.notRequired,
  );
}

void main() {
  late InMemorySecureKeyStore keyStore;
  late IngestionDraftStore draftStore;
  late _RecordingRepository repository;
  late _FakeSourcePicker picker;
  late _FakeUploadClient uploadClient;
  late SessionController session;
  late IngestionFlowController controller;

  void build({
    String userId = _accountId,
    String subjectId = _subjectId,
    UpdateSnapshot? resumedDraft,
  }) {
    session = _sessionController(userId: userId);
    controller = IngestionFlowController(
      repository: repository,
      uploadClient: uploadClient,
      sourcePicker: picker,
      draftStore: draftStore,
      sessionController: session,
      subjectId: subjectId,
      resumedDraft: resumedDraft,
      draftDebounce: Duration.zero,
    );
    addTearDown(controller.dispose);
    addTearDown(session.dispose);
  }

  setUp(() {
    keyStore = InMemorySecureKeyStore();
    draftStore = IngestionDraftStore(keyStore: keyStore);
    repository = _RecordingRepository();
    picker = _FakeSourcePicker();
    uploadClient = _FakeUploadClient();
  });

  group('Draft lifecycle', () {
    test('restores the account draft for the same subject', () async {
      await draftStore.saveDraft(
        _accountId,
        IngestionDraft(
          subjectId: _subjectId,
          manualText: 'Newton first law',
          learnedAt: DateTime.utc(2026, 11, 1, 10),
        ),
      );
      build();

      await controller.initialize();

      expect(controller.currentState.stage, IngestionFlowStage.editing);
      expect(controller.currentState.manualText, 'Newton first law');
      expect(controller.currentState.savedLocally, isTrue);
      expect(controller.currentState.restoredRevision, 1);
    });

    test('ignores a draft saved for another subject', () async {
      await draftStore.saveDraft(
        _accountId,
        IngestionDraft(
          subjectId: _otherSubjectId,
          manualText: 'Chemistry notes',
          learnedAt: DateTime.utc(2026, 11, 1, 10),
        ),
      );
      build();

      await controller.initialize();

      expect(controller.currentState.manualText, isEmpty);
      expect(controller.currentState.savedLocally, isFalse);
    });

    test('never reads another account draft', () async {
      await draftStore.saveDraft(
        _otherAccountId,
        IngestionDraft(
          subjectId: _subjectId,
          manualText: 'Other student notes',
          learnedAt: DateTime.utc(2026, 11, 1, 10),
        ),
      );
      build(userId: _accountId);

      await controller.initialize();

      expect(controller.currentState.manualText, isEmpty);
    });

    test('typing persists a protected local draft', () async {
      build();
      await controller.initialize();

      controller.onManualTextChanged('Newton second law');
      await controller.flushDraft();

      final saved = await draftStore.readDraft(_accountId);
      expect(saved?.manualText, 'Newton second law');
      expect(controller.currentState.savedLocally, isTrue);
    });

    test('text over the server limit blocks extraction', () async {
      build();
      await controller.initialize();

      controller.onManualTextChanged('x' * (maxManualTextChars + 1));

      expect(controller.currentState.isOverTextLimit, isTrue);
      expect(controller.currentState.canExtract, isFalse);
    });
  });

  group('Source selection', () {
    test('adds and removes a supported source', () async {
      build();
      await controller.initialize();
      picker.nextDocument = _pdf();

      await controller.addDocument();

      expect(controller.currentState.sources, hasLength(1));
      expect(
        controller.currentState.sources.single.status,
        LocalSourceState.queued,
      );
      expect(controller.currentState.hasContent, isTrue);
      expect(controller.currentState.canExtract, isTrue);

      controller.removeSource(controller.currentState.sources.single.id);

      expect(controller.currentState.sources, isEmpty);
      expect(controller.currentState.canExtract, isFalse);
    });

    test(
      'an unsupported pick is retained with its reason and blocks extraction',
      () async {
        build();
        await controller.initialize();
        picker.nextDocument = PickedSource.rejected(
          name: 'scan.exe',
          mediaType: 'application/octet-stream',
          byteSize: 12,
          failure: const IngestionFailure(
            code: 'unsupported_media_type',
            message: 'That file type is not supported.',
            nextAction: 'Use a PDF, PNG, or JPEG file.',
          ),
        );

        await controller.addDocument();

        expect(
          controller.currentState.sources.single.status,
          LocalSourceState.unsupported,
        );
        expect(controller.currentState.hasBlockingSource, isTrue);
        expect(controller.currentState.canExtract, isFalse);
      },
    );

    test('stops adding at the five-file contract limit', () async {
      build();
      await controller.initialize();
      for (var index = 0; index < maxSourceCount; index++) {
        picker.nextDocument = _pdf(name: 'notes-$index.pdf');
        await controller.addDocument();
      }

      picker.nextDocument = _pdf(name: 'extra.pdf');
      await controller.addDocument();

      expect(controller.currentState.sources, hasLength(maxSourceCount));
    });
  });

  group('Extraction submission', () {
    test(
      'text-only extraction creates one update and clears the draft',
      () async {
        build();
        await controller.initialize();
        controller.onManualTextChanged('Newton first law');

        await controller.extractConcepts();

        expect(controller.currentState.stage, IngestionFlowStage.submitted);
        expect(controller.currentState.updateId, isNotNull);
        expect(
          controller.currentState.updateState,
          LearningUpdateState.processing,
        );
        expect(controller.currentState.isLocked, isTrue);
        expect(repository.createInputTypes, <IngestionInputType>[
          IngestionInputType.manualText,
        ]);
        expect(repository.operations, <IngestionOperation>[
          IngestionOperation.create,
        ]);
        expect(await draftStore.readDraft(_accountId), isNull);
      },
    );

    test(
      'a file extraction follows create, grant, upload and finalize',
      () async {
        build();
        await controller.initialize();
        picker.nextDocument = _pdf();

        await controller.addDocument();
        await controller.extractConcepts();

        expect(repository.operations, <IngestionOperation>[
          IngestionOperation.create,
          IngestionOperation.grant,
          IngestionOperation.finalize,
        ]);
        expect(uploadClient.uploadCount, 1);
        expect(
          controller.currentState.sources.single.status,
          LocalSourceState.ready,
        );
        expect(controller.currentState.sources.single.bytes, isNull);
        expect(controller.currentState.sources.single.progress, 1);
        expect(controller.currentState.stage, IngestionFlowStage.submitted);
      },
    );

    test('text plus a file declares mixed input', () async {
      build();
      await controller.initialize();
      controller.onManualTextChanged('Newton first law');
      picker.nextDocument = _pdf();
      await controller.addDocument();

      await controller.extractConcepts();

      expect(repository.createInputTypes, <IngestionInputType>[
        IngestionInputType.mixed,
      ]);
    });

    test('a PDF and an image declare mixed input', () async {
      build();
      await controller.initialize();
      picker.nextDocument = _pdf();
      await controller.addDocument();
      picker.nextGallery = _image();
      await controller.addGallery();

      await controller.extractConcepts();

      expect(repository.createInputTypes, <IngestionInputType>[
        IngestionInputType.mixed,
      ]);
      expect(
        repository.operations.where((op) => op == IngestionOperation.grant),
        hasLength(2),
      );
      expect(
        repository.operations.where((op) => op == IngestionOperation.finalize),
        hasLength(2),
      );
    });

    test(
      'a network failure keeps input and retries with the same create identity',
      () async {
        build();
        await controller.initialize();
        controller.onManualTextChanged('Newton first law');
        repository.failures[IngestionOperation.create] =
            IngestionFailure.network();

        await controller.extractConcepts();

        expect(controller.currentState.isOffline, isTrue);
        expect(controller.currentState.stage, IngestionFlowStage.editing);
        expect(controller.currentState.canExtract, isFalse);
        expect(controller.currentState.manualText, 'Newton first law');

        repository.failures.remove(IngestionOperation.create);
        await controller.retryAfterFailure();

        expect(controller.currentState.stage, IngestionFlowStage.submitted);
        expect(repository.createOperationIds, hasLength(2));
        expect(
          repository.createOperationIds[0],
          repository.createOperationIds[1],
        );
        expect(
          repository.createIdempotencyKeys[0],
          repository.createIdempotencyKeys[1],
        );
      },
    );

    test(
      'a failed grant retries the same file without a second create',
      () async {
        build();
        await controller.initialize();
        picker.nextDocument = _pdf();
        await controller.addDocument();
        repository.failures[IngestionOperation.grant] =
            IngestionFailure.network();

        await controller.extractConcepts();

        expect(controller.currentState.stage, IngestionFlowStage.editing);
        expect(controller.currentState.isLocked, isTrue);
        expect(
          controller.currentState.sources.single.status,
          LocalSourceState.failed,
        );
        expect(
          repository.operations.where((op) => op == IngestionOperation.create),
          hasLength(1),
        );

        repository.failures.remove(IngestionOperation.grant);
        await controller.retryAfterFailure();

        expect(controller.currentState.stage, IngestionFlowStage.submitted);
        expect(
          controller.currentState.sources.single.status,
          LocalSourceState.ready,
        );
        expect(
          repository.operations.where((op) => op == IngestionOperation.create),
          hasLength(1),
        );
        expect(repository.grantKeys, hasLength(2));
        expect(repository.grantKeys[0], repository.grantKeys[1]);
      },
    );

    test(
      'an upload transport failure retains bytes for a per-file retry',
      () async {
        build();
        await controller.initialize();
        picker.nextDocument = _pdf();
        await controller.addDocument();
        uploadClient.uploadFailure = IngestionFailure.network();

        await controller.extractConcepts();

        expect(
          controller.currentState.sources.single.status,
          LocalSourceState.failed,
        );
        expect(controller.currentState.sources.single.bytes, isNotNull);
        expect(controller.currentState.isLocked, isTrue);

        uploadClient.uploadFailure = null;
        await controller.retrySource(controller.currentState.sources.single.id);

        expect(
          controller.currentState.sources.single.status,
          LocalSourceState.ready,
        );
        expect(controller.currentState.stage, IngestionFlowStage.submitted);
        expect(repository.grantKeys, hasLength(2));
        expect(repository.grantKeys[0], repository.grantKeys[1]);
      },
    );
  });

  group('Server draft editing', () {
    test(
      'a stale PATCH refreshes the row version and reports a conflict',
      () async {
        repository.seedUpdate(_draftSnapshot(rowVersion: 4));
        build(resumedDraft: _draftSnapshot(rowVersion: 3));
        await controller.initialize();

        await controller.saveDraft();

        expect(repository.draftVersions, <int>[3]);
        expect(controller.currentState.rowVersion, 4);
        expect(controller.currentState.failure?.code, 'version_conflict');
        expect(controller.currentState.isSaving, isFalse);
        expect(controller.currentState.savedLocally, isTrue);
      },
    );
  });

  group('Discard', () {
    test('deletes the server update and clears the local draft', () async {
      build();
      await controller.initialize();
      controller.onManualTextChanged('Newton first law');
      await controller.extractConcepts();

      final discarded = await controller.discard();

      expect(discarded, isTrue);
      expect(repository.operations, contains(IngestionOperation.delete));
      expect(await draftStore.readDraft(_accountId), isNull);
      final latest = await repository.getUpdate(
        accessToken: 'access-token',
        updateId: controller.currentState.updateId!,
      );
      expect(latest.state, LearningUpdateState.deleted);
    });

    test('a delete failure keeps the draft and reports the failure', () async {
      repository.seedUpdate(_draftSnapshot());
      await draftStore.saveDraft(
        _accountId,
        IngestionDraft(
          subjectId: _subjectId,
          manualText: 'Newton first law',
          learnedAt: DateTime.utc(2026, 11, 1, 10),
        ),
      );
      build(resumedDraft: _draftSnapshot());
      await controller.initialize();
      repository.failures[IngestionOperation.delete] =
          IngestionFailure.network();

      final discarded = await controller.discard();

      expect(discarded, isFalse);
      expect(controller.currentState.isOffline, isTrue);
      expect(controller.currentState.failure?.code, 'network_error');
      expect(await draftStore.readDraft(_accountId), isNotNull);
    });
  });
}
