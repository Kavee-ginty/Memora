import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';
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
import 'package:memora_mobile/src/features/ingestion/presentation/path_preview_screen.dart';

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

CandidateItem _reviewCandidate(String id, {required String title}) {
  return CandidateItem(
    id: id,
    candidateType: 'concept',
    displayTitle: title,
    displaySummary: 'Extracted from this learning update.',
    sourceContext: 'From your text',
    confidence: 0.62,
    band: ConfidenceBand.medium,
    requiresVerification: true,
    status: CandidateState.needsVerification,
    candidateVersion: 1,
  );
}

CandidateItem _committed(CandidateItem candidate) {
  return CandidateItem(
    id: candidate.id,
    candidateType: candidate.candidateType,
    displayTitle: candidate.displayTitle,
    displaySummary: candidate.displaySummary,
    sourceContext: candidate.sourceContext,
    confidence: candidate.confidence,
    band: candidate.band,
    requiresVerification: false,
    status: CandidateState.committed,
    candidateVersion: candidate.candidateVersion,
  );
}

const SourceItem _pdfSource = SourceItem(
  id: 'source-1',
  declaredName: 'physics-notes.pdf',
  declaredMediaType: 'application/pdf',
  byteSize: 2048,
  status: SourceUploadState.validated,
  deletionStatus: SourceDeletionStatus.notRequired,
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
  SourceDeletionStatus deletion = SourceDeletionStatus.notRequired,
  List<SourceItem> uploads = const <SourceItem>[],
}) {
  return UpdateSnapshot(
    id: _updateId,
    subjectId: _subjectId,
    inputType: uploads.isEmpty
        ? IngestionInputType.manualText
        : IngestionInputType.pdf,
    state: state,
    hasManualText: uploads.isEmpty,
    learnedAt: DateTime.utc(2026, 11, 1),
    createdAt: DateTime.utc(2026, 11, 1),
    updatedAt: DateTime.utc(2026, 11, 1),
    rowVersion: 1,
    sourceDeletionStatus: deletion,
    uploads: uploads,
  );
}

class _RecordingRepository extends MockIngestionRepository {
  _RecordingRepository() : super(autoAdvanceProcessing: false);

  final List<String> commitKeys = <String>[];

  @override
  Future<CommitOutcome> commitUpdate({
    required String accessToken,
    required String updateId,
    required String idempotencyKey,
  }) {
    commitKeys.add(idempotencyKey);
    return super.commitUpdate(
      accessToken: accessToken,
      updateId: updateId,
      idempotencyKey: idempotencyKey,
    );
  }
}

class _Harness {
  _Harness({
    required this.repository,
    required this.session,
    required this.controller,
  });

  final _RecordingRepository repository;
  final SessionController session;
  final PathPreviewController controller;

  void dispose() {
    controller.dispose();
    session.dispose();
  }
}

_Harness _harness({
  List<CandidateItem>? candidates,
  LearningUpdateState state = LearningUpdateState.verificationRequired,
  SourceDeletionStatus deletion = SourceDeletionStatus.notRequired,
  List<SourceItem> uploads = const <SourceItem>[],
  IngestionFailure? getFailure,
  IngestionFailure? commitFailure,
  bool seedUpdate = true,
  _RecordingRepository? repository,
}) {
  final repo = repository ?? _RecordingRepository();
  if (seedUpdate) {
    repo.seedUpdate(
      _snapshot(state: state, deletion: deletion, uploads: uploads),
      candidates: candidates,
    );
  }
  if (getFailure != null) {
    repo.failures[IngestionOperation.get] = getFailure;
  }
  if (commitFailure != null) {
    repo.failures[IngestionOperation.commit] = commitFailure;
  }
  final session = _sessionController();
  final controller = PathPreviewController(
    repository: repo,
    draftStore: IngestionDraftStore(keyStore: InMemorySecureKeyStore()),
    sessionController: session,
    updateId: _updateId,
  );
  return _Harness(repository: repo, session: session, controller: controller);
}

Future<void> _pump(
  WidgetTester tester,
  PathPreviewController controller, {
  VoidCallback? onBack,
  VoidCallback? onEditConcepts,
  VoidCallback? onInvalidState,
  VoidCallback? onStartMission,
  Size size = const Size(800, 1600),
  double textScale = 1.0,
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
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: PathPreviewScreen(
              controller: controller,
              onBack: onBack,
              onEditConcepts: onEditConcepts,
              onInvalidState: onInvalidState,
              onStartMission: onStartMission,
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
}

Future<void> _dispose(WidgetTester tester, _Harness harness) async {
  await tester.pumpWidget(const SizedBox.shrink());
  harness.dispose();
}

Finder _button(String label) => find.widgetWithText(MemoraButton, label);

void main() {
  testWidgets('renders the preview summary, actions and no bottom nav', (
    tester,
  ) async {
    final harness = _harness(
      uploads: const <SourceItem>[_pdfSource],
      candidates: <CandidateItem>[_highConfidence],
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    expect(find.text('Learning path preview'), findsOneWidget);
    expect(find.text('Preview your learning path'), findsOneWidget);
    expect(find.text('A/L Physics'), findsOneWidget);
    expect(find.text('physics-notes.pdf'), findsOneWidget);
    expect(find.text('Newton first law'), findsOneWidget);
    expect(find.text('About 5 min'), findsOneWidget);
    expect(find.text('Add to my learning path'), findsOneWidget);
    expect(find.text('Edit concepts'), findsOneWidget);
    expect(
      find.text(
        'Adding this path does not earn XP. You earn XP by completing '
        'retrieval missions.',
      ),
      findsOneWidget,
    );
    expect(find.text('Home'), findsNothing);
    expect(find.text('Learning'), findsNothing);
    expect(find.text('Progress'), findsNothing);
    expect(find.text('Profile'), findsNothing);

    await _dispose(tester, harness);
  });

  testWidgets('a blocked preview disables commit and explains why', (
    tester,
  ) async {
    var edits = 0;
    final harness = _harness(
      candidates: <CandidateItem>[
        _highConfidence,
        _reviewCandidate('c-review', title: 'Ohm law'),
      ],
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller, onEditConcepts: () => edits++);

    expect(find.text('This path is not ready yet'), findsOneWidget);
    expect(
      find.text(
        'Some concepts still need a check. Go back to verify them before '
        'adding this path.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<MemoraButton>(_button('Add to my learning path')).onPressed,
      isNull,
    );
    expect(
      tester.widget<MemoraButton>(_button('Edit concepts')).onPressed,
      isNotNull,
    );

    await tester.tap(_button('Edit concepts'));
    await tester.pump();
    expect(edits, 1);

    await _dispose(tester, harness);
  });

  testWidgets(
    'commit shows the ready state with a disabled first mission and separate deletion',
    (tester) async {
      final harness = _harness(
        candidates: <CandidateItem>[_highConfidence],
        deletion: SourceDeletionStatus.pending,
      );
      await harness.controller.initialize();
      await _pump(tester, harness.controller);

      await tester.tap(_button('Add to my learning path'));
      await tester.pumpAndSettle();

      expect(find.text('Your learning path is ready'), findsOneWidget);
      expect(
        find.text('Your concepts are now part of your learning path.'),
        findsOneWidget,
      );
      expect(find.text('Start first mission'), findsOneWidget);
      expect(
        tester.widget<MemoraButton>(_button('Start first mission')).onPressed,
        isNull,
      );
      expect(
        find.text(
          'The first mission is not available yet. Your learning path is '
          'saved, and you can start missions from Home when they are ready.',
        ),
        findsOneWidget,
      );
      expect(find.text('Temporary source'), findsOneWidget);
      expect(
        find.text(
          'Memora is removing the temporary source. Your learning path is not '
          'affected.',
        ),
        findsOneWidget,
      );
      expect(find.text('Add to my learning path'), findsNothing);
      expect(find.text('Edit concepts'), findsNothing);
      expect(harness.repository.commitKeys, hasLength(1));

      await _dispose(tester, harness);
    },
  );

  testWidgets('a committed update opens the ready state without commit', (
    tester,
  ) async {
    final harness = _harness(
      state: LearningUpdateState.committed,
      candidates: <CandidateItem>[_committed(_highConfidence)],
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    expect(find.text('Your learning path is ready'), findsOneWidget);
    expect(
      find.text('This material is already in your learning path.'),
      findsOneWidget,
    );
    expect(find.text('Start first mission'), findsOneWidget);
    expect(
      tester.widget<MemoraButton>(_button('Start first mission')).onPressed,
      isNull,
    );
    expect(find.text('Add to my learning path'), findsNothing);
    expect(find.text('Edit concepts'), findsNothing);
    expect(harness.repository.commitKeys, isEmpty);

    await _dispose(tester, harness);
  });

  testWidgets('offline load shows the banner and retries', (tester) async {
    final harness = _harness(
      candidates: <CandidateItem>[_highConfidence],
      getFailure: _offline,
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Could not load your learning path'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    harness.repository.failures.remove(IngestionOperation.get);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Preview your learning path'), findsOneWidget);
    expect(find.text('Add to my learning path'), findsOneWidget);

    await _dispose(tester, harness);
  });

  testWidgets('a commit failure keeps the preview and retries', (tester) async {
    const retryable = IngestionFailure(
      code: 'temporarily_unavailable',
      message: 'Memora is temporarily unavailable. Please try again shortly.',
      nextAction: 'Try again.',
      retryable: true,
    );
    final harness = _harness(
      candidates: <CandidateItem>[_highConfidence],
      commitFailure: retryable,
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    await tester.tap(_button('Add to my learning path'));
    await tester.pumpAndSettle();

    expect(find.text('Could not add this learning path'), findsOneWidget);
    expect(find.text('Preview your learning path'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    harness.repository.failures.remove(IngestionOperation.commit);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Your learning path is ready'), findsOneWidget);
    expect(harness.repository.commitKeys, hasLength(2));
    expect(harness.repository.commitKeys[0], harness.repository.commitKeys[1]);

    await _dispose(tester, harness);
  });

  testWidgets('an invalid update state requests a safe redirect', (
    tester,
  ) async {
    var redirects = 0;
    final harness = _harness(
      state: LearningUpdateState.processing,
      candidates: <CandidateItem>[_highConfidence],
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller, onInvalidState: () => redirects++);
    await tester.pumpAndSettle();

    expect(redirects, 1);
    expect(find.text('This material is not ready to preview'), findsOneWidget);

    await _dispose(tester, harness);
  });
}
