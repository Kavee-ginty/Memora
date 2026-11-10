import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/ingestion/application/ingestion_flow_controller.dart';
import 'package:memora_mobile/src/features/ingestion/application/update_status_controller.dart';
import 'package:memora_mobile/src/features/ingestion/application/verification_controller.dart';
import 'package:memora_mobile/src/features/ingestion/data/ingestion_draft_store.dart';
import 'package:memora_mobile/src/features/ingestion/data/ingestion_repository.dart';
import 'package:memora_mobile/src/features/ingestion/data/source_picker.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_failure.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_models.dart';
import 'package:memora_mobile/src/features/ingestion/presentation/add_material_screen.dart';
import 'package:memora_mobile/src/features/ingestion/presentation/material_status_screen.dart';
import 'package:memora_mobile/src/features/ingestion/presentation/path_preview_screen.dart';
import 'package:memora_mobile/src/features/ingestion/presentation/verify_concepts_screen.dart';
import 'package:memora_mobile/src/routing/app_router.dart';

import 'support/ingestion_evidence_fixtures.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(800, 1600),
  double textScale = 1.0,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: MemoraTheme.light(),
      home: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: disableAnimations,
            ),
            child: screen,
          );
        },
      ),
    ),
  );
  await tester.pump();
}

void _expectSingleHeader(WidgetTester tester, String title) {
  final headers = find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.header == true,
  );
  expect(headers, findsOneWidget);
  expect(find.bySemanticsLabel(RegExp(RegExp.escape(title))), findsWidgets);
}

Future<IngestionFlowController> _addMaterialController({
  MockIngestionRepository? repository,
  EvidenceSourcePicker? picker,
}) async {
  final session = evidenceSessionController();
  addTearDown(session.dispose);
  final controller = IngestionFlowController(
    repository:
        repository ?? MockIngestionRepository(autoAdvanceProcessing: false),
    uploadClient: EvidenceUploadClient(),
    sourcePicker: picker ?? EvidenceSourcePicker(),
    draftStore: IngestionDraftStore(keyStore: InMemorySecureKeyStore()),
    sessionController: session,
    subjectId: evidenceSubjectId,
    draftDebounce: Duration.zero,
  );
  addTearDown(controller.dispose);
  await controller.initialize();
  return controller;
}

Future<UpdateStatusController> _statusController({
  UpdateSnapshot? snapshot,
  IngestionFailure? getFailure,
}) async {
  final repository = MockIngestionRepository(autoAdvanceProcessing: false);
  if (snapshot != null) repository.seedUpdate(snapshot);
  if (getFailure != null) {
    repository.failures[IngestionOperation.get] = getFailure;
  }
  final session = evidenceSessionController();
  addTearDown(session.dispose);
  final controller = UpdateStatusController(
    repository: repository,
    draftStore: IngestionDraftStore(keyStore: InMemorySecureKeyStore()),
    sessionController: session,
    updateId: evidenceUpdateId,
  );
  addTearDown(() {
    if (controller.mounted) controller.dispose();
  });
  await controller.initialize();
  return controller;
}

Future<VerificationController> _verificationController({
  List<CandidateItem>? candidates,
  IngestionFailure? getFailure,
}) async {
  final repository = MockIngestionRepository(autoAdvanceProcessing: false)
    ..seedUpdate(
      evidenceSnapshot(),
      candidates: candidates ?? const <CandidateItem>[],
    );
  if (getFailure != null) {
    repository.failures[IngestionOperation.get] = getFailure;
  }
  final session = evidenceSessionController();
  addTearDown(session.dispose);
  final controller = VerificationController(
    repository: repository,
    draftStore: IngestionDraftStore(keyStore: InMemorySecureKeyStore()),
    sessionController: session,
    updateId: evidenceUpdateId,
  );
  addTearDown(controller.dispose);
  await controller.initialize();
  return controller;
}

Future<PathPreviewController> _previewController({
  LearningUpdateState state = LearningUpdateState.verificationRequired,
  List<CandidateItem>? candidates,
  List<SourceItem> uploads = const <SourceItem>[],
  SourceDeletionStatus deletion = SourceDeletionStatus.notRequired,
  IngestionFailure? getFailure,
}) async {
  final repository = MockIngestionRepository(autoAdvanceProcessing: false)
    ..seedUpdate(
      evidenceSnapshot(
        state: state,
        uploads: uploads,
        deletionStatus: deletion,
      ),
      candidates: candidates,
    );
  if (getFailure != null) {
    repository.failures[IngestionOperation.get] = getFailure;
  }
  final session = evidenceSessionController();
  addTearDown(session.dispose);
  final controller = PathPreviewController(
    repository: repository,
    draftStore: IngestionDraftStore(keyStore: InMemorySecureKeyStore()),
    sessionController: session,
    updateId: evidenceUpdateId,
  );
  addTearDown(controller.dispose);
  await controller.initialize();
  return controller;
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  group('Primary headings', () {
    testWidgets('add material exposes one primary heading', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = await _addMaterialController();
      await _pump(tester, AddMaterialScreen(controller: controller));

      _expectSingleHeader(tester, 'Add learning material');

      semantics.dispose();
      await _dispose(tester);
    });

    testWidgets('material status exposes one primary heading', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = await _statusController(snapshot: evidenceSnapshot());
      await _pump(tester, MaterialStatusScreen(controller: controller));

      _expectSingleHeader(tester, 'Material status');

      semantics.dispose();
      await _dispose(tester);
    });

    testWidgets('verify concepts exposes one primary heading', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = await _verificationController(
        candidates: const <CandidateItem>[evidenceHighCandidate],
      );
      await _pump(tester, VerifyConceptsScreen(controller: controller));

      _expectSingleHeader(tester, 'Verify concepts');

      semantics.dispose();
      await _dispose(tester);
    });

    testWidgets('learning-path preview exposes one primary heading', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = await _previewController(
        candidates: const <CandidateItem>[evidenceHighCandidate],
      );
      await _pump(tester, PathPreviewScreen(controller: controller));

      _expectSingleHeader(tester, 'Learning path preview');

      semantics.dispose();
      await _dispose(tester);
    });
  });

  testWidgets('material progress is announced to assistive technology', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = await _statusController(
      snapshot: evidenceSnapshot(state: LearningUpdateState.processing),
    );
    await _pump(tester, MaterialStatusScreen(controller: controller));

    final progress = find.byType(LinearProgressIndicator);
    expect(progress, findsOneWidget);
    expect(
      tester.getSemantics(progress).label,
      contains('Extracting concepts'),
    );

    semantics.dispose();
    await _dispose(tester);
    controller.dispose();
  });

  testWidgets('confidence bands carry text and icons, never colour alone', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = await _verificationController(
      candidates: <CandidateItem>[
        evidenceHighCandidate,
        evidenceReviewCandidate('c-medium', title: 'Ohm law'),
        evidenceLowCandidate('c-low', title: 'Power formula'),
      ],
    );
    await _pump(tester, VerifyConceptsScreen(controller: controller));

    expect(find.text('High confidence'), findsOneWidget);
    expect(find.text('Medium confidence'), findsOneWidget);
    expect(find.text('Low confidence'), findsOneWidget);
    expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('High confidence')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Medium confidence')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Low confidence')), findsOneWidget);

    semantics.dispose();
    await _dispose(tester);
  });

  group('320 px and 200 percent text', () {
    testWidgets('add material remains usable', (tester) async {
      final controller = await _addMaterialController();
      await _pump(
        tester,
        AddMaterialScreen(controller: controller),
        size: const Size(320, 640),
        textScale: 2.0,
      );

      expect(find.text('Add learning material'), findsOneWidget);
      expect(find.text('Extract concepts'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _dispose(tester);
    });

    testWidgets('material status remains usable', (tester) async {
      final controller = await _statusController(snapshot: evidenceSnapshot());
      await _pump(
        tester,
        MaterialStatusScreen(controller: controller),
        size: const Size(320, 640),
        textScale: 2.0,
      );

      expect(find.text('Material status'), findsOneWidget);
      expect(find.text('Concepts ready'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _dispose(tester);
    });

    testWidgets('verify concepts remains usable', (tester) async {
      final controller = await _verificationController(
        candidates: <CandidateItem>[
          evidenceHighCandidate,
          evidenceReviewCandidate(
            'c-long',
            title:
                'The relationship between electric current, resistance and '
                'potential difference in a closed circuit',
          ),
        ],
      );
      await _pump(
        tester,
        VerifyConceptsScreen(controller: controller),
        size: const Size(320, 640),
        textScale: 2.0,
      );

      expect(find.text('Verify concepts'), findsOneWidget);
      expect(find.text('Preview learning path'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _dispose(tester);
    });

    testWidgets('learning-path preview remains usable', (tester) async {
      final controller = await _previewController(
        candidates: const <CandidateItem>[evidenceHighCandidate],
      );
      await _pump(
        tester,
        PathPreviewScreen(controller: controller),
        size: const Size(320, 640),
        textScale: 2.0,
      );

      expect(find.text('Learning path preview'), findsOneWidget);
      expect(find.text('Add to my learning path'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _dispose(tester);
    });
  });

  group('Reduced motion', () {
    testWidgets('route pages become immediate when motion is disabled', (
      tester,
    ) async {
      late Page<void> reduced;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                reduced = buildRoutePage(
                  context: context,
                  key: const ValueKey<String>('ingestion-route'),
                  child: const SizedBox(),
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(reduced, isA<NoTransitionPage<void>>());
    });

    testWidgets('ingestion skeletons stop animating when motion is disabled', (
      tester,
    ) async {
      final session = evidenceSessionController();
      addTearDown(session.dispose);
      final controller = VerificationController(
        repository: MockIngestionRepository(autoAdvanceProcessing: false),
        draftStore: IngestionDraftStore(keyStore: InMemorySecureKeyStore()),
        sessionController: session,
        updateId: evidenceUpdateId,
      );
      addTearDown(controller.dispose);

      await _pump(
        tester,
        VerifyConceptsScreen(controller: controller),
        disableAnimations: true,
      );

      expect(find.byType(MemoraSkeleton), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(MemoraSkeleton),
          matching: find.byType(AnimatedBuilder),
        ),
        findsNothing,
      );

      await _dispose(tester);
    });
  });

  group('UI/UX 13 state matrix', () {
    testWidgets('add material covers empty, offline and blocking states', (
      tester,
    ) async {
      final repository = MockIngestionRepository(autoAdvanceProcessing: false);
      repository.failures[IngestionOperation.create] = evidenceOfflineFailure;
      final picker = EvidenceSourcePicker();
      final controller = await _addMaterialController(
        repository: repository,
        picker: picker,
      );
      await _pump(tester, AddMaterialScreen(controller: controller));

      expect(
        find.text('Add a file or paste text to continue.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'Newton first law');
      await tester.pump();
      await tester.tap(find.widgetWithText(MemoraButton, 'Extract concepts'));
      await tester.pumpAndSettle();

      expect(find.text("You're offline"), findsOneWidget);
      expect(
        tester
            .widget<MemoraButton>(
              find.widgetWithText(MemoraButton, 'Extract concepts'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'Newton first law',
      );

      await _dispose(tester);

      final blockingController = await _addMaterialController(picker: picker);
      picker.next = PickedSource.rejected(
        name: 'scan.exe',
        mediaType: 'application/octet-stream',
        byteSize: 12,
        failure: evidenceUnsupportedSourceFailure,
      );
      await blockingController.addDocument();
      await _pump(tester, AddMaterialScreen(controller: blockingController));

      expect(find.textContaining('Unsupported'), findsOneWidget);
      expect(
        find.text('Remove or retry the failed file to continue.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<MemoraButton>(
              find.widgetWithText(MemoraButton, 'Extract concepts'),
            )
            .onPressed,
        isNull,
      );

      await _dispose(tester);
    });

    testWidgets('material status covers loading, error and deletion pending', (
      tester,
    ) async {
      final loading = UpdateStatusController(
        repository: MockIngestionRepository(autoAdvanceProcessing: false),
        draftStore: IngestionDraftStore(keyStore: InMemorySecureKeyStore()),
        sessionController: evidenceSessionController(),
        updateId: evidenceUpdateId,
      );
      addTearDown(loading.dispose);
      await _pump(tester, MaterialStatusScreen(controller: loading));
      expect(find.text('Loading material status…'), findsOneWidget);
      expect(find.byType(MemoraSkeleton), findsWidgets);
      await _dispose(tester);

      final error = await _statusController(getFailure: evidenceOfflineFailure);
      await _pump(tester, MaterialStatusScreen(controller: error));
      expect(find.text("You're offline"), findsOneWidget);
      expect(find.text('Could not load this material'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Try again'), findsOneWidget);
      expect(find.widgetWithText(MemoraButton, 'Try again'), findsNothing);
      await _dispose(tester);

      final deletion = await _statusController(
        snapshot: evidenceSnapshot(
          state: LearningUpdateState.committed,
          uploads: const <SourceItem>[evidenceDeletionPendingUpload],
          deletionStatus: SourceDeletionStatus.pending,
        ),
      );
      await _pump(tester, MaterialStatusScreen(controller: deletion));
      expect(find.text('Learning path ready'), findsOneWidget);
      expect(find.text('Temporary source'), findsOneWidget);
      expect(
        find.text('Memora is removing the temporary source.'),
        findsOneWidget,
      );
      await _dispose(tester);
    });

    testWidgets('verify concepts covers loading, empty and offline states', (
      tester,
    ) async {
      final loading = VerificationController(
        repository: MockIngestionRepository(autoAdvanceProcessing: false),
        draftStore: IngestionDraftStore(keyStore: InMemorySecureKeyStore()),
        sessionController: evidenceSessionController(),
        updateId: evidenceUpdateId,
      );
      addTearDown(loading.dispose);
      await _pump(tester, VerifyConceptsScreen(controller: loading));
      expect(find.byType(MemoraSkeleton), findsWidgets);
      await _dispose(tester);

      final empty = await _verificationController(
        candidates: const <CandidateItem>[],
      );
      await _pump(tester, VerifyConceptsScreen(controller: empty));
      expect(find.text('No concepts to check'), findsOneWidget);
      expect(
        tester
            .widget<MemoraButton>(
              find.widgetWithText(MemoraButton, 'Preview learning path'),
            )
            .onPressed,
        isNull,
      );
      await _dispose(tester);

      final offline = await _verificationController(
        getFailure: evidenceOfflineFailure,
      );
      await _pump(tester, VerifyConceptsScreen(controller: offline));
      expect(find.text("You're offline"), findsOneWidget);
      expect(find.text('Could not load these concepts'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Try again'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('preview covers loading, error and deletion pending states', (
      tester,
    ) async {
      final loading = PathPreviewController(
        repository: MockIngestionRepository(autoAdvanceProcessing: false),
        draftStore: IngestionDraftStore(keyStore: InMemorySecureKeyStore()),
        sessionController: evidenceSessionController(),
        updateId: evidenceUpdateId,
      );
      addTearDown(loading.dispose);
      await _pump(tester, PathPreviewScreen(controller: loading));
      expect(find.byType(MemoraSkeleton), findsWidgets);
      await _dispose(tester);

      final error = await _previewController(
        getFailure: evidenceOfflineFailure,
      );
      await _pump(tester, PathPreviewScreen(controller: error));
      expect(find.text("You're offline"), findsOneWidget);
      expect(find.text('Could not load your learning path'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Try again'), findsOneWidget);
      await _dispose(tester);

      final deletion = await _previewController(
        state: LearningUpdateState.committed,
        uploads: const <SourceItem>[evidenceDeletionPendingUpload],
        deletion: SourceDeletionStatus.pending,
        candidates: <CandidateItem>[
          evidenceCommittedCandidate(evidenceHighCandidate),
        ],
      );
      await _pump(tester, PathPreviewScreen(controller: deletion));
      expect(find.text('Your learning path is ready'), findsOneWidget);
      expect(find.text('Temporary source'), findsOneWidget);
      expect(
        find.text(
          'Memora is removing the temporary source. Your learning path is not '
          'affected.',
        ),
        findsOneWidget,
      );
      await _dispose(tester);
    });
  });
}
