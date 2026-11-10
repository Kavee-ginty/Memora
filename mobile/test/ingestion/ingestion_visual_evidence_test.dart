@TestOn('windows')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/ingestion/application/ingestion_flow_controller.dart';
import 'package:memora_mobile/src/features/ingestion/application/update_status_controller.dart';
import 'package:memora_mobile/src/features/ingestion/application/verification_controller.dart';
import 'package:memora_mobile/src/features/ingestion/data/ingestion_draft_store.dart';
import 'package:memora_mobile/src/features/ingestion/data/ingestion_repository.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_models.dart';
import 'package:memora_mobile/src/features/ingestion/presentation/add_material_screen.dart';
import 'package:memora_mobile/src/features/ingestion/presentation/material_status_screen.dart';
import 'package:memora_mobile/src/features/ingestion/presentation/path_preview_screen.dart';
import 'package:memora_mobile/src/features/ingestion/presentation/verify_concepts_screen.dart';
import 'package:memora_mobile/src/theme/memora_theme.dart';

import 'support/ingestion_evidence_fixtures.dart';

const _captureKey = Key('t10_visual_evidence');

Widget _testApp(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MemoraTheme.light(),
    home: RepaintBoundary(key: _captureKey, child: child),
  );
}

Future<void> _capture(
  WidgetTester tester,
  Widget screen,
  String fileName,
) async {
  tester.view.physicalSize = const Size(402, 1001);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_testApp(screen));
  await tester.pumpAndSettle();

  await expectLater(
    find.byKey(_captureKey),
    matchesGoldenFile('goldens/t10/$fileName.png'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadEvidenceFonts);

  testWidgets('captures the empty add-material state', (tester) async {
    final session = evidenceSessionController();
    addTearDown(session.dispose);
    final controller = IngestionFlowController(
      repository: MockIngestionRepository(autoAdvanceProcessing: false),
      uploadClient: EvidenceUploadClient(),
      sourcePicker: EvidenceSourcePicker(),
      draftStore: IngestionDraftStore(keyStore: InMemorySecureKeyStore()),
      sessionController: session,
      subjectId: evidenceSubjectId,
      draftDebounce: Duration.zero,
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await _capture(
      tester,
      AddMaterialScreen(controller: controller),
      'add_material_empty',
    );
  });

  testWidgets('captures the submitted add-material receipt', (tester) async {
    final session = evidenceSessionController();
    addTearDown(session.dispose);
    final controller = IngestionFlowController(
      repository: MockIngestionRepository(autoAdvanceProcessing: false),
      uploadClient: EvidenceUploadClient(),
      sourcePicker: EvidenceSourcePicker(),
      draftStore: IngestionDraftStore(keyStore: InMemorySecureKeyStore()),
      sessionController: session,
      subjectId: evidenceSubjectId,
      draftDebounce: Duration.zero,
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    controller.onManualTextChanged(
      'Newton first law: an object remains at rest or in uniform motion '
      'unless acted on by a net force.',
    );
    await controller.extractConcepts();

    await _capture(
      tester,
      AddMaterialScreen(controller: controller),
      'add_material_received',
    );
  });

  testWidgets('captures material status with concepts ready', (tester) async {
    final repository = MockIngestionRepository(autoAdvanceProcessing: false)
      ..seedUpdate(
        evidenceSnapshot(),
        candidates: const <CandidateItem>[evidenceHighCandidate],
      );
    final session = evidenceSessionController();
    addTearDown(session.dispose);
    final controller = UpdateStatusController(
      repository: repository,
      draftStore: IngestionDraftStore(keyStore: InMemorySecureKeyStore()),
      sessionController: session,
      updateId: evidenceUpdateId,
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await _capture(
      tester,
      MaterialStatusScreen(controller: controller),
      'material_status_verification_ready',
    );
  });

  testWidgets('captures material status with deletion pending', (tester) async {
    final repository = MockIngestionRepository(autoAdvanceProcessing: false)
      ..seedUpdate(
        evidenceSnapshot(
          state: LearningUpdateState.committed,
          uploads: const <SourceItem>[evidenceDeletionPendingUpload],
          deletionStatus: SourceDeletionStatus.pending,
        ),
      );
    final session = evidenceSessionController();
    addTearDown(session.dispose);
    final controller = UpdateStatusController(
      repository: repository,
      draftStore: IngestionDraftStore(keyStore: InMemorySecureKeyStore()),
      sessionController: session,
      updateId: evidenceUpdateId,
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await _capture(
      tester,
      MaterialStatusScreen(controller: controller),
      'material_status_deletion_pending',
    );
  });

  testWidgets('captures concept review with every confidence band', (
    tester,
  ) async {
    final repository = MockIngestionRepository(autoAdvanceProcessing: false)
      ..seedUpdate(
        evidenceSnapshot(),
        candidates: <CandidateItem>[
          evidenceHighCandidate,
          evidenceReviewCandidate('c-medium', title: 'Ohm law'),
          evidenceLowCandidate('c-low', title: 'Power formula'),
        ],
      );
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

    await _capture(
      tester,
      VerifyConceptsScreen(controller: controller),
      'verify_concepts_review',
    );
  });

  testWidgets('captures the empty verify-concepts state', (tester) async {
    final repository = MockIngestionRepository(autoAdvanceProcessing: false)
      ..seedUpdate(evidenceSnapshot(), candidates: const <CandidateItem>[]);
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

    await _capture(
      tester,
      VerifyConceptsScreen(controller: controller),
      'verify_concepts_empty',
    );
  });

  testWidgets('captures the ready-to-add learning-path preview', (
    tester,
  ) async {
    final repository = MockIngestionRepository(autoAdvanceProcessing: false)
      ..seedUpdate(
        evidenceSnapshot(uploads: const <SourceItem>[evidenceValidatedPdf]),
        candidates: const <CandidateItem>[evidenceHighCandidate],
      );
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

    await _capture(
      tester,
      PathPreviewScreen(controller: controller),
      'path_preview_ready',
    );
  });

  testWidgets('captures the blocked learning-path preview', (tester) async {
    final repository = MockIngestionRepository(autoAdvanceProcessing: false)
      ..seedUpdate(
        evidenceSnapshot(),
        candidates: <CandidateItem>[
          evidenceHighCandidate,
          evidenceReviewCandidate('c-review', title: 'Ohm law'),
        ],
      );
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

    await _capture(
      tester,
      PathPreviewScreen(controller: controller),
      'path_preview_blocked',
    );
  });

  testWidgets('captures the committed preview with deletion pending', (
    tester,
  ) async {
    final repository = MockIngestionRepository(autoAdvanceProcessing: false)
      ..seedUpdate(
        evidenceSnapshot(
          state: LearningUpdateState.committed,
          uploads: const <SourceItem>[evidenceDeletionPendingUpload],
          deletionStatus: SourceDeletionStatus.pending,
        ),
        candidates: <CandidateItem>[
          evidenceCommittedCandidate(evidenceHighCandidate),
        ],
      );
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

    await _capture(
      tester,
      PathPreviewScreen(controller: controller),
      'path_preview_committed_deletion_pending',
    );
  });
}
