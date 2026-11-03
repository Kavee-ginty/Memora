import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';
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
import 'package:memora_mobile/src/features/ingestion/presentation/add_material_screen.dart';

const String _accountId = 'account-a';
const String _subjectId = '22222222-2222-4222-8222-222222222222';
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

class _FakeSourcePicker implements SourcePicker {
  PickedSource? next;

  @override
  Future<PickedSource?> pickDocument() async => next;

  @override
  Future<PickedSource?> pickCamera() async => next;

  @override
  Future<PickedSource?> pickGallery() async => next;
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
    CancelToken? cancelToken,
  }) async {
    onProgress?.call(upload.source.byteSize, upload.source.byteSize);
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

UpdateSnapshot _draftSnapshot({int rowVersion = 3}) {
  return UpdateSnapshot(
    id: _updateId,
    subjectId: _subjectId,
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
  late MockIngestionRepository repository;
  late _FakeSourcePicker picker;
  late _FakeUploadClient uploadClient;
  late SessionController session;
  late IngestionFlowController controller;

  void build({UpdateSnapshot? resumedDraft}) {
    session = _sessionController();
    controller = IngestionFlowController(
      repository: repository,
      uploadClient: uploadClient,
      sourcePicker: picker,
      draftStore: draftStore,
      sessionController: session,
      subjectId: _subjectId,
      resumedDraft: resumedDraft,
      draftDebounce: Duration.zero,
    );
    addTearDown(controller.dispose);
    addTearDown(session.dispose);
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    VoidCallback? onClose,
    ValueChanged<String>? onViewStatus,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: MemoraTheme.light(),
        home: AddMaterialScreen(
          controller: controller,
          onClose: onClose,
          onViewStatus: onViewStatus,
        ),
      ),
    );
    await tester.pump();
  }

  MemoraButton buttonWithLabel(WidgetTester tester, String label) {
    return tester.widget<MemoraButton>(
      find.widgetWithText(MemoraButton, label),
    );
  }

  setUp(() {
    keyStore = InMemorySecureKeyStore();
    draftStore = IngestionDraftStore(keyStore: keyStore);
    repository = MockIngestionRepository();
    picker = _FakeSourcePicker();
    uploadClient = _FakeUploadClient();
  });

  testWidgets('renders the approved add-material composition', (tester) async {
    build();
    await controller.initialize();

    await pumpScreen(tester);

    expect(find.text('Add learning material'), findsOneWidget);
    expect(find.text('Subject'), findsOneWidget);
    expect(find.text('A/L Physics'), findsOneWidget);
    expect(find.text('Upload material'), findsOneWidget);
    expect(find.text('Paste your notes'), findsOneWidget);
    expect(find.textContaining('Your files are temporary'), findsOneWidget);
    expect(find.text('Extract concepts'), findsOneWidget);
    expect(find.text('Save draft'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Learning'), findsWidgets);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('empty material disables Extract concepts with a reason', (
    tester,
  ) async {
    build();
    await controller.initialize();

    await pumpScreen(tester);

    expect(buttonWithLabel(tester, 'Extract concepts').onPressed, isNull);
    expect(find.text('Add a file or paste text to continue.'), findsOneWidget);
  });

  testWidgets('typing enables Extract concepts', (tester) async {
    build();
    await controller.initialize();
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'Newton first law');
    await tester.pump();

    expect(buttonWithLabel(tester, 'Extract concepts').onPressed, isNotNull);
    expect(find.textContaining('of 20,000 characters'), findsOneWidget);
  });

  testWidgets('a selected source shows its state and confirms removal', (
    tester,
  ) async {
    build();
    await controller.initialize();
    picker.next = _pdf();
    await controller.addDocument();
    await pumpScreen(tester);

    expect(find.text('notes.pdf'), findsOneWidget);
    expect(find.text('4 B · Queued'), findsOneWidget);
    expect(buttonWithLabel(tester, 'Extract concepts').onPressed, isNotNull);

    await tester.tap(find.byTooltip('Remove notes.pdf'));
    await tester.pumpAndSettle();

    expect(find.text('Remove file?'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('notes.pdf'), findsNothing);
    expect(buttonWithLabel(tester, 'Extract concepts').onPressed, isNull);
  });

  testWidgets(
    'an unsupported source explains the problem and blocks extraction',
    (tester) async {
      build();
      await controller.initialize();
      picker.next = PickedSource.rejected(
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
      await pumpScreen(tester);

      expect(find.textContaining('Unsupported'), findsOneWidget);
      expect(find.text('That file type is not supported.'), findsOneWidget);
      expect(find.text('Use a PDF, PNG, or JPEG file.'), findsOneWidget);
      expect(buttonWithLabel(tester, 'Extract concepts').onPressed, isNull);
      expect(
        find.text('Remove or retry the failed file to continue.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('offline failure shows the banner and disables the action', (
    tester,
  ) async {
    build();
    await controller.initialize();
    repository.failures[IngestionOperation.create] = IngestionFailure.network();
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'Newton first law');
    await tester.pump();
    await tester.tap(find.text('Extract concepts'));
    await tester.pumpAndSettle();

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Reconnect to extract concepts.'), findsOneWidget);
    expect(buttonWithLabel(tester, 'Extract concepts').onPressed, isNull);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'Newton first law');
  });

  testWidgets('a stale server draft reports the conflict and keeps text', (
    tester,
  ) async {
    repository.seedUpdate(_draftSnapshot(rowVersion: 4));
    build(resumedDraft: _draftSnapshot(rowVersion: 3));
    await controller.initialize();
    await pumpScreen(tester);

    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();

    expect(find.text('Could not finish this step'), findsOneWidget);
    expect(find.textContaining('This information has changed'), findsOneWidget);
    expect(
      find.text(
        'Save this draft, then start a new update to extract concepts.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'submitted state shows receipt copy, status action and closes back',
    (tester) async {
      var closed = false;
      String? viewedUpdateId;
      build();
      await controller.initialize();
      controller.onManualTextChanged('Newton first law');
      await controller.extractConcepts();
      await pumpScreen(
        tester,
        onClose: () => closed = true,
        onViewStatus: (updateId) => viewedUpdateId = updateId,
      );

      expect(find.text('Material received'), findsOneWidget);
      expect(find.text('View status'), findsOneWidget);
      expect(find.text('Back to Learning'), findsOneWidget);

      await tester.tap(find.text('View status'));
      await tester.pump();

      expect(viewedUpdateId, controller.currentState.updateId);

      await tester.tap(find.text('Back to Learning'));
      await tester.pump();

      expect(closed, isTrue);
    },
  );
}
