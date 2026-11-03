import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/ingestion/data/source_picker.dart';
import 'package:memora_mobile/src/features/ingestion/data/upload_client.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_failure.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_models.dart';

const String evidenceAccountId = 'account-a';
const String evidenceSubjectId = '22222222-2222-4222-8222-222222222222';
const String evidenceUpdateId = '11111111-1111-4111-8111-111111111111';
const String evidenceUploadId = '44444444-4444-4444-8444-444444444444';

const IngestionFailure evidenceOfflineFailure = IngestionFailure(
  code: 'network_error',
  message: 'Memora could not reach the server.',
  nextAction: 'Check your connection and try again.',
  retryable: true,
);

const IngestionFailure evidenceExtractionFailure = IngestionFailure(
  code: 'extraction_failed',
  message: 'Memora could not extract concepts from this material.',
  nextAction: 'Try extracting again.',
  retryable: true,
);

const IngestionFailure evidenceServerFailure = IngestionFailure(
  code: 'temporarily_unavailable',
  message: 'Memora could not refresh this material.',
  nextAction: 'Try again in a moment.',
  retryable: true,
);

BootstrapData evidenceBootstrap() {
  return BootstrapData(
    accountStatus: AccountStatusDomain.active,
    profileSummary: const ProfileSummaryDomain(
      userId: evidenceAccountId,
      displayName: 'Amani Perera',
      activeSubjectId: evidenceSubjectId,
    ),
    consentStatus: const ConsentStatusDomain(requiresReview: false),
    subjects: const <SubjectSummaryDomain>[
      SubjectSummaryDomain(
        id: evidenceSubjectId,
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

SessionController evidenceSessionController() {
  return SessionController(
    authRepository: MockAuthRepository(),
    sessionRepository: MockSessionRepository(),
    localStorage: AppLocalStorage(InMemorySecureKeyStore()),
    initialState: AppSessionState.active(
      session: const AuthSession(
        accessToken: 'synthetic-access-token',
        userId: evidenceAccountId,
      ),
      bootstrapData: evidenceBootstrap(),
    ),
  );
}

UpdateSnapshot evidenceSnapshot({
  LearningUpdateState state = LearningUpdateState.verificationRequired,
  IngestionFailure? failure,
  List<SourceItem> uploads = const <SourceItem>[],
  SourceDeletionStatus deletionStatus = SourceDeletionStatus.notRequired,
}) {
  return UpdateSnapshot(
    id: evidenceUpdateId,
    subjectId: evidenceSubjectId,
    inputType: uploads.isEmpty
        ? IngestionInputType.manualText
        : IngestionInputType.pdf,
    state: state,
    failure: failure,
    hasManualText: uploads.isEmpty,
    learnedAt: DateTime.utc(2026, 11, 1),
    createdAt: DateTime.utc(2026, 11, 1),
    updatedAt: DateTime.utc(2026, 11, 1),
    rowVersion: 1,
    sourceDeletionStatus: deletionStatus,
    uploads: uploads,
  );
}

const SourceItem evidenceDeletionPendingUpload = SourceItem(
  id: evidenceUploadId,
  declaredName: 'physics-notes.pdf',
  declaredMediaType: 'application/pdf',
  byteSize: 2048,
  status: SourceUploadState.deleting,
  deletionStatus: SourceDeletionStatus.pending,
);

const SourceItem evidenceValidatedPdf = SourceItem(
  id: evidenceUploadId,
  declaredName: 'physics-notes.pdf',
  declaredMediaType: 'application/pdf',
  byteSize: 2048,
  status: SourceUploadState.validated,
  deletionStatus: SourceDeletionStatus.notRequired,
);

const CandidateItem evidenceHighCandidate = CandidateItem(
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

CandidateItem evidenceReviewCandidate(
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

CandidateItem evidenceLowCandidate(String id, {required String title}) {
  return CandidateItem(
    id: id,
    candidateType: 'concept',
    displayTitle: title,
    displaySummary: 'Extracted from this learning update.',
    sourceContext: 'From your text',
    confidence: 0.32,
    band: ConfidenceBand.low,
    requiresVerification: true,
    status: CandidateState.needsVerification,
    candidateVersion: 1,
  );
}

CandidateItem evidenceCommittedCandidate(CandidateItem candidate) {
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

/// Source picker for text-only evidence, with an opt-in rejected pick.
class EvidenceSourcePicker implements SourcePicker {
  PickedSource? next;

  @override
  Future<PickedSource?> pickCamera() async => next;

  @override
  Future<PickedSource?> pickDocument() async => next;

  @override
  Future<PickedSource?> pickGallery() async => next;
}

const IngestionFailure evidenceUnsupportedSourceFailure = IngestionFailure(
  code: 'unsupported_media_type',
  message: 'That file type is not supported.',
  nextAction: 'Use a PDF, PNG, or JPEG file.',
);

/// Upload transport for text-only evidence; any file use fails the test loudly.
class EvidenceUploadClient implements UploadClient {
  @override
  Future<PreparedUpload> prepare(UploadSource source) {
    throw UnsupportedError('Visual evidence fixtures are text-only.');
  }

  @override
  Future<void> upload({
    required UploadGrant grant,
    required PreparedUpload upload,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) {
    throw UnsupportedError('Visual evidence fixtures are text-only.');
  }
}

/// Font loading shared by the Windows visual-evidence captures.
Future<void> loadEvidenceFonts() async {
  await (FontLoader(
    'Exo',
  )..addFont(rootBundle.load('assets/fonts/Exo-400.ttf'))).load();
  await (FontLoader(
    'Inter',
  )..addFont(rootBundle.load('assets/fonts/Inter-400.ttf'))).load();

  var flutterCache = File(Platform.resolvedExecutable).parent;
  while (flutterCache.path.split(Platform.pathSeparator).last.toLowerCase() !=
      'cache') {
    final parent = flutterCache.parent;
    if (parent.path == flutterCache.path) {
      throw StateError('Flutter cache not found from Dart executable.');
    }
    flutterCache = parent;
  }
  final materialIcons =
      <File>[
        File(
          '${flutterCache.path}/artifacts/material_fonts/materialicons-regular.otf',
        ),
        File(
          '${flutterCache.path}/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ),
      ].firstWhere(
        (file) => file.existsSync(),
        orElse: () => throw StateError('Material Icons font not found.'),
      );
  final iconBytes = await materialIcons.readAsBytes();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future<ByteData>.value(ByteData.sublistView(iconBytes)))).load();
}
