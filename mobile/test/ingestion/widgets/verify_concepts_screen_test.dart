import 'dart:async';

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
import 'package:memora_mobile/src/features/ingestion/presentation/verify_concepts_screen.dart';
import 'package:memora_mobile/src/features/ingestion/presentation/widgets/candidate_card.dart';

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
  required String title,
  int version = 1,
}) {
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
    required this.controller,
  });

  final _RecordingRepository repository;
  final SessionController session;
  final VerificationController controller;

  void dispose() {
    controller.dispose();
    session.dispose();
  }
}

_Harness _harness({
  List<CandidateItem>? candidates,
  bool seedUpdate = true,
  IngestionFailure? getFailure,
  int pageSize = 20,
  _RecordingRepository? repository,
}) {
  final repo = repository ?? _RecordingRepository();
  if (seedUpdate) {
    repo.seedUpdate(_snapshot(), candidates: candidates);
  }
  if (getFailure != null) {
    repo.failures[IngestionOperation.get] = getFailure;
  }
  final session = _sessionController();
  final controller = VerificationController(
    repository: repo,
    draftStore: IngestionDraftStore(keyStore: InMemorySecureKeyStore()),
    sessionController: session,
    updateId: _updateId,
    pageSize: pageSize,
  );
  return _Harness(repository: repo, session: session, controller: controller);
}

Future<void> _pump(
  WidgetTester tester,
  VerificationController controller, {
  VoidCallback? onBack,
  VoidCallback? onPreview,
  VoidCallback? onInvalidState,
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
            child: VerifyConceptsScreen(
              controller: controller,
              onBack: onBack,
              onPreview: onPreview,
              onInvalidState: onInvalidState,
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

Finder _cardFor(String title) {
  return find.ancestor(
    of: find.text(title),
    matching: find.byType(CandidateCard),
  );
}

Finder get _previewButton =>
    find.widgetWithText(MemoraButton, 'Preview learning path');

void main() {
  testWidgets(
    'renders confidence groups, Check this markers and no bottom nav',
    (tester) async {
      final harness = _harness(
        candidates: <CandidateItem>[
          _highConfidence,
          _reviewCandidate('c-medium', title: 'Ohm law'),
          _reviewCandidate('c-low', title: 'Power formula', version: 2),
        ],
      );
      await harness.controller.initialize();
      await _pump(tester, harness.controller);

      expect(find.text('Verify concepts'), findsOneWidget);
      expect(find.text('Review the concepts Memora found'), findsOneWidget);
      expect(find.text('Check this (2)'), findsOneWidget);
      expect(find.text('Included (1)'), findsOneWidget);
      expect(find.text('Newton first law'), findsOneWidget);
      expect(find.text('Ohm law'), findsOneWidget);
      expect(find.text('Power formula'), findsOneWidget);
      expect(find.text('High confidence'), findsOneWidget);
      expect(find.text('Medium confidence'), findsNWidgets(2));
      expect(find.text('Check this'), findsNWidgets(2));
      expect(
        find.text('1 concept included. 2 concepts need a check.'),
        findsOneWidget,
      );
      expect(find.text('Preview learning path'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
      expect(find.text('Learning'), findsNothing);
      expect(find.text('Progress'), findsNothing);
      expect(find.text('Profile'), findsNothing);

      await _dispose(tester, harness);
    },
  );

  testWidgets('confident concepts have no decision controls', (tester) async {
    final harness = _harness(
      candidates: <CandidateItem>[
        _highConfidence,
        _reviewCandidate('c-one', title: 'Ohm law'),
      ],
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    final highCard = _cardFor('Newton first law');
    expect(
      find.descendant(
        of: highCard,
        matching: find.text('Included in your learning path'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: highCard,
        matching: find.widgetWithText(MemoraButton, 'Accept'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: highCard,
        matching: find.widgetWithText(MemoraButton, 'Remove'),
      ),
      findsNothing,
    );

    final reviewCard = _cardFor('Ohm law');
    expect(
      find.descendant(of: reviewCard, matching: find.text('Check this')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: reviewCard,
        matching: find.widgetWithText(MemoraButton, 'Accept'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: reviewCard,
        matching: find.widgetWithText(MemoraButton, 'Edit title'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: reviewCard,
        matching: find.widgetWithText(MemoraButton, 'Remove'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: reviewCard,
        matching: find.widgetWithText(MemoraButton, 'Merge'),
      ),
      findsOneWidget,
    );

    await _dispose(tester, harness);
  });

  testWidgets('accept and undo update the summary and keep preview available', (
    tester,
  ) async {
    final harness = _harness(
      candidates: <CandidateItem>[
        _highConfidence,
        _reviewCandidate('c-one', title: 'Ohm law'),
      ],
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    await tester.tap(
      find.descendant(
        of: _cardFor('Ohm law'),
        matching: find.widgetWithText(MemoraButton, 'Accept'),
      ),
    );
    await tester.pump();

    expect(find.text('Accepted'), findsOneWidget);
    expect(
      find.text('2 concepts included. 0 concepts need a check.'),
      findsOneWidget,
    );
    expect(tester.widget<MemoraButton>(_previewButton).onPressed, isNotNull);

    await tester.tap(
      find.descendant(
        of: _cardFor('Ohm law'),
        matching: find.widgetWithText(MemoraButton, 'Undo'),
      ),
    );
    await tester.pump();

    expect(find.text('Check this'), findsOneWidget);
    expect(
      find.text('1 concept included. 1 concept needs a check.'),
      findsOneWidget,
    );
    expect(tester.widget<MemoraButton>(_previewButton).onPressed, isNotNull);

    await _dispose(tester, harness);
  });

  testWidgets('editing shows the corrected title and submits one edit', (
    tester,
  ) async {
    var previews = 0;
    final harness = _harness(
      candidates: <CandidateItem>[
        _highConfidence,
        _reviewCandidate('c-one', title: 'Ohm law'),
      ],
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller, onPreview: () => previews++);

    await tester.tap(
      find.descendant(
        of: _cardFor('Ohm law'),
        matching: find.widgetWithText(MemoraButton, 'Edit title'),
      ),
    );
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Concept title'), findsOneWidget);
    expect(find.widgetWithText(MemoraButton, 'Save title'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Corrected Ohm law');
    await tester.pump();
    await tester.tap(find.widgetWithText(MemoraButton, 'Save title'));
    await tester.pump();

    expect(find.text('Corrected Ohm law'), findsOneWidget);
    expect(find.text('Edited and accepted'), findsOneWidget);
    expect(
      harness.controller.currentState.draftFor('c-one')?.editedTitle,
      'Corrected Ohm law',
    );

    await tester.tap(_previewButton);
    await tester.pumpAndSettle();

    expect(previews, 1);
    expect(harness.repository.decisionBatches, hasLength(1));
    expect(
      harness.repository.decisionBatches.single.single.kind,
      VerificationDecisionKind.edit,
    );
    expect(
      harness.repository.decisionBatches.single.single.editedTitle,
      'Corrected Ohm law',
    );

    await _dispose(tester, harness);
  });

  testWidgets('removing every concept disables preview and explains why', (
    tester,
  ) async {
    final harness = _harness(
      candidates: <CandidateItem>[_reviewCandidate('c-one', title: 'Ohm law')],
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    await tester.tap(
      find.descendant(
        of: _cardFor('Ohm law'),
        matching: find.widgetWithText(MemoraButton, 'Remove'),
      ),
    );
    await tester.pump();

    expect(find.text('Removed'), findsOneWidget);
    expect(
      find.text('Keep at least one concept to preview your learning path.'),
      findsOneWidget,
    );
    expect(tester.widget<MemoraButton>(_previewButton).onPressed, isNull);

    await tester.tap(
      find.descendant(
        of: _cardFor('Ohm law'),
        matching: find.widgetWithText(MemoraButton, 'Undo'),
      ),
    );
    await tester.pump();

    expect(
      find.text('Keep at least one concept to preview your learning path.'),
      findsOneWidget,
    );
    expect(tester.widget<MemoraButton>(_previewButton).onPressed, isNull);

    await tester.tap(
      find.descendant(
        of: _cardFor('Ohm law'),
        matching: find.widgetWithText(MemoraButton, 'Accept'),
      ),
    );
    await tester.pump();

    expect(
      find.text('Keep at least one concept to preview your learning path.'),
      findsNothing,
    );
    expect(tester.widget<MemoraButton>(_previewButton).onPressed, isNotNull);

    await _dispose(tester, harness);
  });

  testWidgets('merging combines a duplicate into the chosen concept', (
    tester,
  ) async {
    final harness = _harness(
      candidates: <CandidateItem>[
        _highConfidence,
        _reviewCandidate('c-one', title: 'Duplicate force idea'),
      ],
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller, onPreview: () {});

    await tester.tap(
      find.descendant(
        of: _cardFor('Duplicate force idea'),
        matching: find.widgetWithText(MemoraButton, 'Merge'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Merge this concept'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(MemoraBottomSheet),
        matching: find.text('Newton first law'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Merged into Newton first law'), findsOneWidget);
    expect(
      harness.controller.currentState.draftFor('c-one')?.mergeIntoCandidateId,
      _highConfidence.id,
    );

    await tester.tap(_previewButton);
    await tester.pumpAndSettle();

    expect(
      harness.repository.decisionBatches.single.single.kind,
      VerificationDecisionKind.merge,
    );
    expect(
      harness.repository.decisionBatches.single.single.mergeIntoCandidateId,
      _highConfidence.id,
    );

    await _dispose(tester, harness);
  });

  testWidgets('a conflict refreshes and keeps a safe edit', (tester) async {
    var previews = 0;
    final harness = _harness(
      candidates: <CandidateItem>[_reviewCandidate('c-one', title: 'Ohm law')],
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller, onPreview: () => previews++);

    await tester.tap(
      find.descendant(
        of: _cardFor('Ohm law'),
        matching: find.widgetWithText(MemoraButton, 'Edit title'),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'My safe edit');
    await tester.pump();
    await tester.tap(find.widgetWithText(MemoraButton, 'Save title'));
    await tester.pump();

    harness.repository.seedUpdate(
      _snapshot(),
      candidates: <CandidateItem>[
        _reviewCandidate('c-one', title: 'Ohm law', version: 2),
      ],
    );

    await tester.tap(_previewButton);
    await tester.pumpAndSettle();

    expect(previews, 0);
    expect(find.text('Concepts refreshed'), findsOneWidget);
    expect(
      find.textContaining('changed while you were reviewing'),
      findsOneWidget,
    );
    expect(find.text('My safe edit'), findsOneWidget);
    expect(
      harness.controller.currentState.draftFor('c-one')?.candidateVersion,
      2,
    );

    await _dispose(tester, harness);
  });

  testWidgets('shows loading skeletons before the first read', (tester) async {
    final harness = _harness(
      candidates: <CandidateItem>[_reviewCandidate('c-one', title: 'Ohm law')],
    );
    await _pump(tester, harness.controller);

    expect(find.byType(MemoraSkeleton), findsWidgets);
    expect(find.text('Review the concepts Memora found'), findsNothing);

    await harness.controller.initialize();
    await tester.pump();

    expect(find.text('Review the concepts Memora found'), findsOneWidget);

    await _dispose(tester, harness);
  });

  testWidgets('a first-read failure explains the state and recovers', (
    tester,
  ) async {
    final harness = _harness(
      candidates: <CandidateItem>[_reviewCandidate('c-one', title: 'Ohm law')],
      getFailure: _offline,
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Could not load these concepts'), findsOneWidget);
    expect(find.textContaining(_offline.message), findsWidgets);
    expect(find.text('Back to material status'), findsOneWidget);

    harness.repository.failures.remove(IngestionOperation.get);
    await tester.tap(find.widgetWithText(TextButton, 'Try again').first);
    await tester.pumpAndSettle();

    expect(find.text('Review the concepts Memora found'), findsOneWidget);
    expect(find.text('Ohm law'), findsOneWidget);
    expect(find.text("You're offline"), findsNothing);

    await _dispose(tester, harness);
  });

  testWidgets('a missing or wrong-owner update shows shared not-found', (
    tester,
  ) async {
    final harness = _harness(seedUpdate: false);
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    expect(find.text('We could not find that page'), findsOneWidget);
    expect(find.text('Verify concepts'), findsNothing);

    await _dispose(tester, harness);
  });

  testWidgets('a wrong update state explains and redirects safely', (
    tester,
  ) async {
    var redirects = 0;
    final harness = _harness(
      candidates: <CandidateItem>[_reviewCandidate('c-one', title: 'Ohm law')],
    );
    await harness.controller.initialize();
    harness.repository.seedUpdate(
      _snapshot(state: LearningUpdateState.committed),
    );
    await harness.controller.refresh();

    await _pump(tester, harness.controller, onInvalidState: () => redirects++);

    expect(redirects, 1);
    expect(
      find.text('This material is no longer ready for review'),
      findsOneWidget,
    );
    expect(find.text('Back to material status'), findsOneWidget);

    await _dispose(tester, harness);
  });

  testWidgets('an offline refresh keeps concepts and disables preview', (
    tester,
  ) async {
    final harness = _harness(
      candidates: <CandidateItem>[
        _highConfidence,
        _reviewCandidate('c-one', title: 'Ohm law'),
      ],
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    harness.repository.failures[IngestionOperation.get] = _offline;
    await harness.controller.refresh();
    await tester.pump();

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Ohm law'), findsOneWidget);
    expect(
      find.text('Reconnect to preview your learning path.'),
      findsOneWidget,
    );
    expect(tester.widget<MemoraButton>(_previewButton).onPressed, isNull);

    harness.repository.failures.remove(IngestionOperation.get);
    await tester.tap(find.widgetWithText(TextButton, 'Try again'));
    await tester.pumpAndSettle();

    expect(find.text("You're offline"), findsNothing);
    expect(tester.widget<MemoraButton>(_previewButton).onPressed, isNotNull);

    await _dispose(tester, harness);
  });

  testWidgets('an empty candidate page explains why preview is disabled', (
    tester,
  ) async {
    final harness = _harness(candidates: const <CandidateItem>[]);
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    expect(find.text('No concepts to check'), findsOneWidget);
    expect(
      find.text('No concepts were found in this material.'),
      findsOneWidget,
    );
    expect(tester.widget<MemoraButton>(_previewButton).onPressed, isNull);

    await _dispose(tester, harness);
  });

  testWidgets('load more appends the next candidate page', (tester) async {
    final harness = _harness(
      candidates: <CandidateItem>[
        _reviewCandidate('c-one', title: 'Concept one'),
        _reviewCandidate('c-two', title: 'Concept two'),
        _reviewCandidate('c-three', title: 'Concept three'),
      ],
      pageSize: 2,
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    expect(find.text('Concept one'), findsOneWidget);
    expect(find.text('Concept two'), findsOneWidget);
    expect(find.text('Concept three'), findsNothing);
    expect(find.text('Load more concepts'), findsOneWidget);

    await tester.tap(find.widgetWithText(MemoraButton, 'Load more concepts'));
    await tester.pumpAndSettle();

    expect(find.text('Concept three'), findsOneWidget);
    expect(find.text('Load more concepts'), findsNothing);

    await _dispose(tester, harness);
  });

  testWidgets('a double preview tap submits one decision batch', (
    tester,
  ) async {
    var previews = 0;
    final repository = _BlockingRepository();
    final harness = _harness(
      repository: repository,
      candidates: <CandidateItem>[
        _highConfidence,
        _reviewCandidate('c-one', title: 'Ohm law'),
      ],
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller, onPreview: () => previews++);

    await tester.tap(
      find.descendant(
        of: _cardFor('Ohm law'),
        matching: find.widgetWithText(MemoraButton, 'Accept'),
      ),
    );
    await tester.pump();

    await tester.tap(_previewButton);
    await tester.pump();
    await tester.tap(_previewButton);
    await tester.pump();

    expect(previews, 0);
    expect(repository.decisionBatches, isEmpty);
    expect(tester.widget<MemoraButton>(_previewButton).isLoading, isTrue);

    repository.gate.complete();
    await tester.pumpAndSettle();

    expect(previews, 1);
    expect(repository.decisionBatches, hasLength(1));

    await _dispose(tester, harness);
  });

  testWidgets('semantics announce confidence, state and title', (tester) async {
    final semantics = tester.ensureSemantics();
    final harness = _harness(
      candidates: <CandidateItem>[
        _highConfidence,
        _reviewCandidate('c-one', title: 'Ohm law'),
      ],
    );
    await harness.controller.initialize();
    await _pump(tester, harness.controller);

    expect(
      find.bySemanticsLabel(
        RegExp(r'High confidence\. Included in your learning path\. Newton'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp(r'Medium confidence\. Check this\. Ohm law'),
      ),
      findsOneWidget,
    );
    expect(find.text('Check this'), findsOneWidget);
    expect(find.text('Included in your learning path'), findsOneWidget);

    semantics.dispose();
    await _dispose(tester, harness);
  });

  testWidgets('renders at 320 px and 200 percent text without overflow', (
    tester,
  ) async {
    final harness = _harness(
      candidates: <CandidateItem>[
        _highConfidence,
        _reviewCandidate(
          'c-long',
          title:
              'The relationship between electric current, resistance and '
              'potential difference in a closed circuit',
        ),
      ],
    );
    await harness.controller.initialize();
    await _pump(
      tester,
      harness.controller,
      size: const Size(320, 640),
      textScale: 2.0,
    );

    expect(find.text('Verify concepts'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.textContaining('The relationship between'),
      240,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    expect(find.textContaining('The relationship between'), findsOneWidget);
    expect(find.text('Preview learning path'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _dispose(tester, harness);
  });
}
