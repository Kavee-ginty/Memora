import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';
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
import 'package:memora_mobile/src/features/ingestion/presentation/material_status_screen.dart';

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

const IngestionFailure _serverFailure = IngestionFailure(
  code: 'temporarily_unavailable',
  message: 'Memora could not refresh this material.',
  nextAction: 'Try again in a moment.',
  retryable: true,
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

SourceItem _deletingUpload() {
  return const SourceItem(
    id: _uploadId,
    declaredName: 'notes.pdf',
    declaredMediaType: 'application/pdf',
    byteSize: 2048,
    status: SourceUploadState.deleting,
    deletionStatus: SourceDeletionStatus.pending,
  );
}

class _Harness {
  _Harness({
    required this.repository,
    required this.session,
    required this.controller,
  });

  final MockIngestionRepository repository;
  final SessionController session;
  final UpdateStatusController controller;

  void dispose() {
    controller.dispose();
    session.dispose();
  }
}

_Harness _harness({
  UpdateSnapshot? snapshot,
  IngestionFailure? getFailure,
  IngestionDraftStore? draftStore,
}) {
  final repository = MockIngestionRepository(autoAdvanceProcessing: false);
  if (snapshot != null) repository.seedUpdate(snapshot);
  if (getFailure != null) {
    repository.failures[IngestionOperation.get] = getFailure;
  }
  final session = _sessionController();
  final controller = UpdateStatusController(
    repository: repository,
    draftStore:
        draftStore ?? IngestionDraftStore(keyStore: InMemorySecureKeyStore()),
    sessionController: session,
    updateId: _updateId,
  );
  return _Harness(
    repository: repository,
    session: session,
    controller: controller,
  );
}

Future<void> _pump(
  WidgetTester tester,
  UpdateStatusController controller, {
  VoidCallback? onLeave,
  VoidCallback? onVerifyConcepts,
  VoidCallback? onPreviewPath,
  VoidCallback? onAddMaterial,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: MemoraTheme.light(),
      home: MaterialStatusScreen(
        controller: controller,
        onLeave: onLeave,
        onVerifyConcepts: onVerifyConcepts,
        onPreviewPath: onPreviewPath,
        onAddMaterial: onAddMaterial,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders every durable update state and the safe fallback', (
    tester,
  ) async {
    const cases = <LearningUpdateState, String>{
      LearningUpdateState.draft: 'Draft material',
      LearningUpdateState.uploading: 'Receiving your material',
      LearningUpdateState.processing: 'Extracting concepts',
      LearningUpdateState.verificationRequired: 'Concepts ready',
      LearningUpdateState.committed: 'Learning path ready',
      LearningUpdateState.failed: 'Memora could not finish this material',
      LearningUpdateState.expired: 'Temporary material unavailable',
      LearningUpdateState.deleted: 'Source removed',
      LearningUpdateState.unknown: 'Material unavailable',
    };

    for (final entry in cases.entries) {
      final harness = _harness(
        snapshot: _snapshot(
          state: entry.key,
          failure: entry.key == LearningUpdateState.failed
              ? _retryableExtraction
              : null,
        ),
      );
      await harness.controller.initialize();
      await _pump(tester, harness.controller);

      expect(
        find.text(entry.value),
        findsOneWidget,
        reason: 'state ${entry.key.name}',
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      harness.dispose();
    }
  });

  testWidgets('shows loading and the UIX-019 timeout actions', (tester) async {
    final harness = _harness();
    await _pump(tester, harness.controller);

    expect(find.text('Loading material status…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));

    expect(find.textContaining('This is taking longer'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Leave'), findsOneWidget);

    harness.dispose();
  });

  testWidgets('shows a safe initial-load failure with recovery actions', (
    tester,
  ) async {
    final harness = _harness(getFailure: _offline);
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Could not load this material'), findsOneWidget);
    expect(find.text(_offline.message), findsWidgets);
    expect(find.widgetWithText(MemoraButton, 'Try again'), findsOneWidget);
    expect(find.text('Back to Learning'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    harness.dispose();
  });

  testWidgets('absent or wrong-owner updates render the shared not-found', (
    tester,
  ) async {
    final harness = _harness();
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    expect(find.text('We could not find that page'), findsOneWidget);
    expect(find.text('Material status'), findsNothing);

    harness.dispose();
  });

  testWidgets('deletion pending is separate from retained knowledge', (
    tester,
  ) async {
    final harness = _harness(
      snapshot: _snapshot(
        state: LearningUpdateState.committed,
        uploads: <SourceItem>[_deletingUpload()],
        deletionStatus: SourceDeletionStatus.pending,
      ),
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    expect(find.text('Learning path ready'), findsOneWidget);
    expect(find.text('Preview learning path'), findsOneWidget);
    expect(find.text('Temporary source'), findsOneWidget);
    expect(find.text('Temporary source: Removing…'), findsOneWidget);
    expect(find.text('Retry source cleanup'), findsOneWidget);
    expect(
      find.text('Memora is removing the temporary source.'),
      findsOneWidget,
    );

    harness.dispose();
  });

  testWidgets('slow processing explains that leaving is safe', (tester) async {
    final harness = _harness(snapshot: _snapshot());
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    expect(find.text('Extracting concepts'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));

    expect(find.text('You can leave this screen'), findsOneWidget);
    expect(find.text('Back to Learning'), findsOneWidget);

    harness.dispose();
  });

  testWidgets('a refresh failure keeps the snapshot and explains retry', (
    tester,
  ) async {
    final harness = _harness(snapshot: _snapshot());
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    harness.repository.failures[IngestionOperation.get] = _serverFailure;
    await harness.controller.refresh();
    await tester.pump();

    expect(find.text('Extracting concepts'), findsOneWidget);
    expect(find.text('Could not refresh this material'), findsOneWidget);
    expect(find.textContaining(_serverFailure.message), findsWidgets);

    harness.dispose();
  });

  testWidgets('verify, preview and add-material actions are wired', (
    tester,
  ) async {
    var verified = 0;
    final verification = _harness(
      snapshot: _snapshot(state: LearningUpdateState.verificationRequired),
    );
    await verification.controller.initialize();
    await _pump(
      tester,
      verification.controller,
      onVerifyConcepts: () => verified++,
    );
    await tester.tap(find.widgetWithText(MemoraButton, 'Verify concepts'));
    expect(verified, 1);
    verification.dispose();

    var previewed = 0;
    final committed = _harness(
      snapshot: _snapshot(state: LearningUpdateState.committed),
    );
    await committed.controller.initialize();
    await _pump(tester, committed.controller, onPreviewPath: () => previewed++);
    await tester.tap(
      find.widgetWithText(MemoraButton, 'Preview learning path'),
    );
    expect(previewed, 1);
    committed.dispose();

    var added = 0;
    final expired = _harness(
      snapshot: _snapshot(state: LearningUpdateState.expired),
    );
    await expired.controller.initialize();
    await _pump(tester, expired.controller, onAddMaterial: () => added++);
    await tester.tap(find.widgetWithText(MemoraButton, 'Start a new update'));
    expect(added, 1);
    expired.dispose();

    var continued = 0;
    final draft = _harness(
      snapshot: _snapshot(state: LearningUpdateState.draft),
    );
    await draft.controller.initialize();
    await _pump(tester, draft.controller, onAddMaterial: () => continued++);
    await tester.tap(find.widgetWithText(MemoraButton, 'Continue editing'));
    expect(continued, 1);
    draft.dispose();
  });

  testWidgets('failed extraction retry returns the update to processing', (
    tester,
  ) async {
    final harness = _harness(
      snapshot: _snapshot(
        state: LearningUpdateState.failed,
        failure: _retryableExtraction,
      ),
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    expect(find.text('Memora could not finish this material'), findsOneWidget);
    expect(find.text('Add different material'), findsOneWidget);

    await tester.tap(find.widgetWithText(MemoraButton, 'Try again'));
    await tester.pump();

    expect(find.text('Extracting concepts'), findsOneWidget);

    harness.dispose();
  });
}
