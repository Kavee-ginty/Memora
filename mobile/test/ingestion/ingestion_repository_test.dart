import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_api_client/memora_api_client.dart';
import 'package:memora_mobile/src/configuration/app_configuration.dart';
import 'package:memora_mobile/src/features/ingestion/data/ingestion_repository.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_failure.dart';
import 'package:memora_mobile/src/features/ingestion/domain/ingestion_models.dart';

const String _updateId = '11111111-1111-4111-8111-111111111111';
const String _subjectId = '22222222-2222-4222-8222-222222222222';
const String _uploadId = '44444444-4444-4444-8444-444444444444';

Map<String, dynamic> _uploadJson({
  String status = 'validated',
  String deletionStatus = 'not_required',
  String? deletedAt,
}) {
  return <String, dynamic>{
    'id': _uploadId,
    'declared_name': 'notes.pdf',
    'declared_media_type': 'application/pdf',
    'detected_media_type': 'application/pdf',
    'byte_size': 2048,
    'status': status,
    'expires_at': '2026-11-02T10:00:00Z',
    'deleted_at': deletedAt,
    'deletion_status': deletionStatus,
  };
}

Map<String, dynamic> _updateJson({
  String status = 'processing',
  String inputType = 'manual_text',
  String? failureCode,
  bool hasManualText = true,
  int rowVersion = 1,
  String sourceDeletionStatus = 'not_required',
  List<Map<String, dynamic>>? uploads,
  String? expiresAt,
}) {
  return <String, dynamic>{
    'id': _updateId,
    'subject_id': _subjectId,
    'curriculum_version_id': '33333333-3333-4333-8333-333333333333',
    'input_type': inputType,
    'status': status,
    'failure_code': ?failureCode,
    'has_manual_text': hasManualText,
    'learned_at': '2026-11-01T10:00:00Z',
    'expires_at': ?expiresAt,
    'created_at': '2026-11-01T10:01:00Z',
    'updated_at': '2026-11-01T10:02:00Z',
    'row_version': rowVersion,
    'source_deletion_status': sourceDeletionStatus,
    'uploads': uploads ?? <Map<String, dynamic>>[],
  };
}

Map<String, dynamic> _candidateJson({
  String id = 'candidate-1',
  String band = 'high',
  bool requiresVerification = false,
  String status = 'candidate',
  int version = 3,
  Map<String, dynamic>? locator,
}) {
  return <String, dynamic>{
    'id': id,
    'candidate_type': 'concept',
    'display_title': 'Newton first law',
    'display_summary': 'An object stays at rest unless acted on.',
    'confidence': 0.9,
    'confidence_band': band,
    'requires_verification': requiresVerification,
    'status': status,
    'source_locator':
        locator ??
        <String, dynamic>{'kind': 'text_range', 'start': 0, 'end': 10},
    'candidate_version': version,
  };
}

Map<String, dynamic> _previewConceptJson({String candidateId = 'candidate-1'}) {
  return <String, dynamic>{
    'candidate_id': candidateId,
    'title': 'Newton first law',
    'candidate_type': 'concept',
    'concept_id': '55555555-5555-4555-8555-555555555555',
    'concept_version_id': '66666666-6666-4666-8666-666666666666',
  };
}

Map<String, dynamic> _previewJson({
  bool canCommit = true,
  String? blockedReason,
  String status = 'verification_required',
}) {
  return <String, dynamic>{
    'update_id': _updateId,
    'status': status,
    'concept_count': 2,
    'first_concepts': <Map<String, dynamic>>[
      _previewConceptJson(),
      _previewConceptJson(candidateId: 'candidate-2'),
    ],
    'estimated_first_mission_minutes': 6,
    'can_commit': canCommit,
    'blocked_reason': blockedReason,
  };
}

Map<String, dynamic> _commitJson({Map<String, dynamic>? firstMission}) {
  return <String, dynamic>{
    'knowledge_commit_id': 'commit-1',
    'commit_version': 1,
    'committed_counts': <String, int>{'concept': 2, 'formula': 1},
    'concept_mappings': <Map<String, dynamic>>[_previewConceptJson()],
    'private_knowledge_count': 0,
    'first_mission': firstMission,
    'source_deletion_status': 'deleted',
    'learning_update': _updateJson(
      status: 'committed',
      sourceDeletionStatus: 'deleted',
    ),
  };
}

Map<String, dynamic> _errorEnvelope(String code) {
  return <String, dynamic>{
    'error': <String, dynamic>{
      'code': code,
      'message': 'Raw server text must never reach the UI.',
      'request_id': 'req_1',
      'retryable': false,
      'field_errors': <Map<String, dynamic>>[],
    },
  };
}

void _resolve(
  Dio dio,
  Object? data, {
  int statusCode = 200,
  void Function(RequestOptions options)? onRequest,
}) {
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest?.call(options);
        return handler.resolve(
          Response<Object?>(
            requestOptions: options,
            statusCode: statusCode,
            data: data,
          ),
        );
      },
    ),
  );
}

void _reject(Dio dio, int statusCode, String code) {
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: statusCode,
              data: _errorEnvelope(code),
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  late Dio dio;
  late MemoraIngestionRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.memora.test'));
    repository = MemoraIngestionRepository(
      apiClient: MemoraApiClient(dio: dio),
      configuration: const AppConfiguration(
        supabaseUrl: 'https://placeholder.supabase.co',
        supabasePublishableKey: 'key',
        apiBaseUrl: 'https://api.memora.test',
        oauthRedirectUri: 'memora://auth',
        platform: 'android',
      ),
    );
  });

  group('MemoraIngestionRepository', () {
    test('create sends declared metadata and maps the update', () async {
      late RequestOptions request;
      late Map<dynamic, dynamic> body;

      _resolve(
        dio,
        _updateJson(status: 'processing'),
        statusCode: 201,
        onRequest: (options) {
          request = options;
          body = Map<dynamic, dynamic>.from(options.data as Map);
        },
      );

      final snapshot = await repository.createUpdate(
        accessToken: 'token_xyz',
        subjectId: _subjectId,
        inputType: IngestionInputType.manualText,
        learnedAt: DateTime.utc(2026, 11, 1, 10),
        clientOperationId: 'operation-1',
        idempotencyKey: 'idem-create',
        manualText: 'Newton first law',
      );

      expect(request.method, 'POST');
      expect(request.path, '/v1/learning-updates');
      expect(request.headers['Authorization'], 'Bearer token_xyz');
      expect(request.headers['X-Correlation-ID'], isNotEmpty);
      expect(request.headers['X-Client-Version'], '0.1.0');
      expect(request.headers['X-Platform'], 'android');
      expect(request.headers['Idempotency-Key'], 'idem-create');

      expect(body['client_operation_id'], 'operation-1');
      expect(body['subject_id'], _subjectId);
      expect(body['input_type'], 'manual_text');
      expect(body['manual_text'], 'Newton first law');
      expect(body['files'], isEmpty);
      expect(
        DateTime.parse(body['learned_at'] as String),
        DateTime.utc(2026, 11, 1, 10),
      );

      expect(snapshot.id, _updateId);
      expect(snapshot.subjectId, _subjectId);
      expect(snapshot.inputType, IngestionInputType.manualText);
      expect(snapshot.state, LearningUpdateState.processing);
      expect(snapshot.failure, isNull);
      expect(snapshot.hasManualText, isTrue);
      expect(snapshot.learnedAt, DateTime.utc(2026, 11, 1, 10));
      expect(snapshot.rowVersion, 1);
      expect(snapshot.sourceDeletionStatus, SourceDeletionStatus.notRequired);
    });

    test('create sends declared files for an upload-backed update', () async {
      late Map<dynamic, dynamic> body;
      _resolve(
        dio,
        _updateJson(status: 'uploading', inputType: 'pdf'),
        statusCode: 201,
        onRequest: (options) {
          body = Map<dynamic, dynamic>.from(options.data as Map);
        },
      );

      final snapshot = await repository.createUpdate(
        accessToken: 'token',
        subjectId: _subjectId,
        inputType: IngestionInputType.pdf,
        learnedAt: DateTime.utc(2026, 11, 1, 10),
        clientOperationId: 'operation-2',
        idempotencyKey: 'idem-create-2',
        files: const <DeclaredSource>[
          DeclaredSource(
            declaredName: 'notes.pdf',
            declaredMediaType: 'application/pdf',
            byteSize: 2048,
            contentSha256: 'abc123',
          ),
        ],
      );

      final files = body['files'] as List<dynamic>;
      expect(files, hasLength(1));
      final file = Map<dynamic, dynamic>.from(files.single as Map);
      expect(file['declared_name'], 'notes.pdf');
      expect(file['declared_media_type'], 'application/pdf');
      expect(file['byte_size'], 2048);
      expect(file['content_sha256'], 'abc123');
      expect(body.containsKey('manual_text'), isFalse);
      expect(snapshot.state, LearningUpdateState.uploading);
    });

    test('list maps pagination and forwards the cursor', () async {
      final cursors = <String?>[];
      _resolve(
        dio,
        <String, dynamic>{
          'items': <Map<String, dynamic>>[
            _updateJson(status: 'processing'),
            _updateJson(status: 'committed'),
          ],
          'has_more': true,
          'next_cursor': 'next-page',
        },
        onRequest: (options) {
          cursors.add(options.queryParameters['cursor'] as String?);
          expect(options.queryParameters['limit'], 20);
        },
      );

      final page = await repository.listUpdates(accessToken: 'token');

      expect(cursors.single, isNull);
      expect(page.items, hasLength(2));
      expect(page.items.last.state, LearningUpdateState.committed);
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'next-page');
    });

    test('get maps uploads, deletion state and failure copy', () async {
      _resolve(
        dio,
        _updateJson(
          status: 'failed',
          failureCode: 'extraction_failed',
          sourceDeletionStatus: 'pending',
          uploads: <Map<String, dynamic>>[
            _uploadJson(status: 'processing', deletionStatus: 'pending'),
          ],
          expiresAt: '2026-11-02T10:00:00Z',
        ),
      );

      final snapshot = await repository.getUpdate(
        accessToken: 'token',
        updateId: _updateId,
      );

      expect(snapshot.state, LearningUpdateState.failed);
      expect(snapshot.failure?.code, 'extraction_failed');
      expect(snapshot.failure?.retryable, isTrue);
      expect(snapshot.sourceDeletionStatus, SourceDeletionStatus.pending);
      expect(snapshot.expiresAt, DateTime.utc(2026, 11, 2, 10));
      expect(snapshot.uploads, hasLength(1));
      final upload = snapshot.uploads.single;
      expect(upload.id, _uploadId);
      expect(upload.status, SourceUploadState.processing);
      expect(upload.deletionStatus, SourceDeletionStatus.pending);
      expect(upload.expiresAt, DateTime.utc(2026, 11, 2, 10));
      expect(upload.deletionRetryAvailable, isFalse);
    });

    test('unknown wire values fall back safely', () async {
      _resolve(
        dio,
        _updateJson(
          status: 'future_state',
          inputType: 'hologram',
          sourceDeletionStatus: 'future_deletion',
          uploads: <Map<String, dynamic>>[
            _uploadJson(
              status: 'future_upload',
              deletionStatus: 'future_deletion',
            ),
          ],
        ),
      );

      final snapshot = await repository.getUpdate(
        accessToken: 'token',
        updateId: _updateId,
      );

      expect(snapshot.state, LearningUpdateState.unknown);
      expect(snapshot.inputType, IngestionInputType.unknown);
      expect(snapshot.sourceDeletionStatus, SourceDeletionStatus.unknown);
      expect(snapshot.uploads.single.status, SourceUploadState.unknown);
      expect(
        snapshot.uploads.single.deletionStatus,
        SourceDeletionStatus.unknown,
      );
    });

    test(
      'updateDraft sends the row version and maps the new version',
      () async {
        late RequestOptions request;
        late Map<dynamic, dynamic> body;
        _resolve(
          dio,
          _updateJson(status: 'draft', rowVersion: 2),
          onRequest: (options) {
            request = options;
            body = Map<dynamic, dynamic>.from(options.data as Map);
          },
        );

        final snapshot = await repository.updateDraft(
          accessToken: 'token',
          updateId: _updateId,
          version: 1,
          idempotencyKey: 'idem-patch',
          learnedAt: DateTime.utc(2026, 11, 2),
          manualText: 'Updated text',
        );

        expect(request.method, 'PATCH');
        expect(request.path, '/v1/learning-updates/$_updateId');
        expect(request.headers['Idempotency-Key'], 'idem-patch');
        expect(body['version'], 1);
        expect(body['manual_text'], 'Updated text');
        expect(
          DateTime.parse(body['learned_at'] as String),
          DateTime.utc(2026, 11, 2),
        );
        expect(snapshot.state, LearningUpdateState.draft);
        expect(snapshot.rowVersion, 2);
      },
    );

    test('updateDraft omits absent optional fields', () async {
      late Map<dynamic, dynamic> body;
      _resolve(
        dio,
        _updateJson(status: 'draft', rowVersion: 2),
        onRequest: (options) {
          body = Map<dynamic, dynamic>.from(options.data as Map);
        },
      );

      await repository.updateDraft(
        accessToken: 'token',
        updateId: _updateId,
        version: 1,
        idempotencyKey: 'idem-patch',
      );

      expect(body.containsKey('manual_text'), isFalse);
      expect(body.containsKey('learned_at'), isFalse);
    });

    test('delete sends the durable operation key', () async {
      late RequestOptions request;
      _resolve(
        dio,
        null,
        statusCode: 204,
        onRequest: (options) {
          request = options;
        },
      );

      await repository.deleteUpdate(
        accessToken: 'token',
        updateId: _updateId,
        idempotencyKey: 'idem-delete',
      );

      expect(request.method, 'DELETE');
      expect(request.path, '/v1/learning-updates/$_updateId');
      expect(request.headers['Idempotency-Key'], 'idem-delete');
    });

    test('createUploadGrant maps the exact grant contract', () async {
      late Map<dynamic, dynamic> body;
      _resolve(
        dio,
        <String, dynamic>{
          'upload_id': _uploadId,
          'url': 'https://storage.memora.test/object',
          'method': 'PUT',
          'required_headers': <String, String>{
            'x-upload-token': 'signed',
            'content-type': 'application/pdf',
          },
          'max_bytes': 10485760,
          'expires_at': '2026-11-01T10:10:00Z',
          'checksum_rule': 'SHA-256 hex digest of the exact uploaded bytes',
        },
        statusCode: 201,
        onRequest: (options) {
          body = Map<dynamic, dynamic>.from(options.data as Map);
        },
      );

      final grant = await repository.createUploadGrant(
        accessToken: 'token',
        updateId: _updateId,
        source: const DeclaredSource(
          declaredName: 'notes.pdf',
          declaredMediaType: 'application/pdf',
          byteSize: 2048,
          contentSha256: 'abc123',
        ),
        idempotencyKey: 'idem-grant',
      );

      expect(body['declared_name'], 'notes.pdf');
      expect(body['declared_media_type'], 'application/pdf');
      expect(body['byte_size'], 2048);
      expect(body['content_sha256'], 'abc123');
      expect(grant.uploadId, _uploadId);
      expect(grant.url, 'https://storage.memora.test/object');
      expect(grant.method, 'PUT');
      expect(grant.requiredHeaders, <String, String>{
        'x-upload-token': 'signed',
        'content-type': 'application/pdf',
      });
      expect(grant.maxBytes, 10485760);
      expect(grant.expiresAt, DateTime.utc(2026, 11, 1, 10, 10));
    });

    test('finalize sends the observed size and checksum', () async {
      late RequestOptions request;
      late Map<dynamic, dynamic> body;
      _resolve(
        dio,
        _updateJson(status: 'processing'),
        statusCode: 202,
        onRequest: (options) {
          request = options;
          body = Map<dynamic, dynamic>.from(options.data as Map);
        },
      );

      final snapshot = await repository.finalizeUpload(
        accessToken: 'token',
        updateId: _updateId,
        uploadId: _uploadId,
        observedSize: 2048,
        contentSha256: 'abc123',
        clientOperationId: 'operation-1',
        idempotencyKey: 'idem-finalize',
      );

      expect(
        request.path,
        '/v1/learning-updates/$_updateId/uploads/$_uploadId/finalize',
      );
      expect(request.headers['Idempotency-Key'], 'idem-finalize');
      expect(body['observed_size'], 2048);
      expect(body['content_sha256'], 'abc123');
      expect(body['client_operation_id'], 'operation-1');
      expect(snapshot.state, LearningUpdateState.processing);
    });

    test('retry sends the eligible stage', () async {
      late Map<dynamic, dynamic> body;
      _resolve(
        dio,
        _updateJson(status: 'processing'),
        statusCode: 202,
        onRequest: (options) {
          body = Map<dynamic, dynamic>.from(options.data as Map);
        },
      );

      final snapshot = await repository.retryUpdate(
        accessToken: 'token',
        updateId: _updateId,
        stage: IngestionRetryStage.extraction,
        idempotencyKey: 'idem-retry',
      );

      expect(body['stage'], 'extraction');
      expect(snapshot.state, LearningUpdateState.processing);
    });

    test('listCandidates maps bands, locator context and pagination', () async {
      late RequestOptions request;
      _resolve(
        dio,
        <String, dynamic>{
          'items': <Map<String, dynamic>>[
            _candidateJson(),
            _candidateJson(
              id: 'candidate-2',
              band: 'low',
              requiresVerification: true,
              status: 'needs_verification',
              version: 4,
              locator: <String, dynamic>{'kind': 'page', 'page': 2},
            ),
          ],
          'has_more': true,
          'next_cursor': 'candidate-page-2',
        },
        onRequest: (options) {
          request = options;
        },
      );

      final page = await repository.listCandidates(
        accessToken: 'token',
        updateId: _updateId,
        cursor: 'candidate-page-1',
        limit: 2,
      );

      expect(request.path, '/v1/learning-updates/$_updateId/candidates');
      expect(request.queryParameters['cursor'], 'candidate-page-1');
      expect(request.queryParameters['limit'], 2);
      expect(page.items, hasLength(2));
      expect(page.nextCursor, 'candidate-page-2');

      final first = page.items.first;
      expect(first.band, ConfidenceBand.high);
      expect(first.sourceContext, 'From your text');
      expect(first.confidence, 0.9);
      expect(first.candidateVersion, 3);

      final second = page.items.last;
      expect(second.band, ConfidenceBand.low);
      expect(second.status, CandidateState.needsVerification);
      expect(second.needsReview, isTrue);
      expect(second.sourceContext, 'Page 2');
    });

    test('unknown confidence band falls back safely', () async {
      _resolve(dio, <String, dynamic>{
        'items': <Map<String, dynamic>>[_candidateJson(band: 'certain')],
        'has_more': false,
        'next_cursor': null,
      });

      final page = await repository.listCandidates(
        accessToken: 'token',
        updateId: _updateId,
      );

      expect(page.items.single.band, ConfidenceBand.unknown);
      expect(page.hasMore, isFalse);
    });

    test('submitDecisions sends the contracted payload shapes', () async {
      late Map<dynamic, dynamic> body;
      _resolve(
        dio,
        <String, dynamic>{
          'learning_update': _updateJson(
            status: 'verification_required',
            rowVersion: 2,
          ),
          'results': <Map<String, dynamic>>[
            <String, dynamic>{
              'candidate_id': 'c1',
              'candidate_status': 'accepted',
              'requires_verification': false,
            },
            <String, dynamic>{
              'candidate_id': 'c2',
              'candidate_status': 'rejected',
              'requires_verification': false,
            },
          ],
        },
        onRequest: (options) {
          body = Map<dynamic, dynamic>.from(options.data as Map);
        },
      );

      final outcome = await repository.submitDecisions(
        accessToken: 'token',
        updateId: _updateId,
        idempotencyKey: 'idem-decisions',
        decisions: const <DecisionDraft>[
          DecisionDraft(
            candidateId: 'c1',
            candidateVersion: 3,
            kind: VerificationDecisionKind.accept,
          ),
          DecisionDraft(
            candidateId: 'c2',
            candidateVersion: 1,
            kind: VerificationDecisionKind.reject,
          ),
          DecisionDraft(
            candidateId: 'c3',
            candidateVersion: 2,
            kind: VerificationDecisionKind.edit,
            editedTitle: 'Corrected title',
          ),
          DecisionDraft(
            candidateId: 'c4',
            candidateVersion: 5,
            kind: VerificationDecisionKind.merge,
            mergeIntoCandidateId: 'c1',
          ),
        ],
      );

      final decisions = (body['decisions'] as List<dynamic>)
          .map((item) => Map<dynamic, dynamic>.from(item as Map))
          .toList(growable: false);
      expect(decisions, hasLength(4));

      expect(decisions[0]['decision'], 'accept');
      expect(
        Map<dynamic, dynamic>.from(decisions[0]['corrected_payload'] as Map),
        isEmpty,
      );
      expect(decisions[1]['decision'], 'reject');
      expect(
        Map<dynamic, dynamic>.from(decisions[1]['corrected_payload'] as Map),
        isEmpty,
      );
      expect(decisions[2]['decision'], 'edit');
      expect(
        Map<dynamic, dynamic>.from(decisions[2]['corrected_payload'] as Map),
        <dynamic, dynamic>{'title': 'Corrected title'},
      );
      expect(decisions[3]['decision'], 'merge');
      expect(
        Map<dynamic, dynamic>.from(decisions[3]['corrected_payload'] as Map),
        <dynamic, dynamic>{'merge_into_candidate_id': 'c1'},
      );

      expect(outcome.update.state, LearningUpdateState.verificationRequired);
      expect(outcome.update.rowVersion, 2);
      expect(outcome.outcomes, hasLength(2));
      expect(outcome.outcomes.first.state, CandidateState.accepted);
      expect(outcome.outcomes.last.state, CandidateState.rejected);
    });

    test('preview maps the authoritative gate and blocked reason', () async {
      _resolve(
        dio,
        _previewJson(canCommit: false, blockedReason: 'verification_pending'),
      );

      final preview = await repository.previewPath(
        accessToken: 'token',
        updateId: _updateId,
      );

      expect(preview.updateId, _updateId);
      expect(preview.state, LearningUpdateState.verificationRequired);
      expect(preview.conceptCount, 2);
      expect(preview.firstConcepts, hasLength(2));
      expect(preview.firstConcepts.first.title, 'Newton first law');
      expect(preview.firstConcepts.first.conceptId, isNotNull);
      expect(preview.estimatedFirstMissionMinutes, 6);
      expect(preview.canCommit, isFalse);
      expect(preview.blockedReason, PreviewBlockReason.verificationPending);
    });

    test('commit maps counts, mappings and a null first mission', () async {
      late RequestOptions request;
      _resolve(
        dio,
        _commitJson(),
        onRequest: (options) {
          request = options;
        },
      );

      final outcome = await repository.commitUpdate(
        accessToken: 'token',
        updateId: _updateId,
        idempotencyKey: 'idem-commit',
      );

      expect(request.path, '/v1/learning-updates/$_updateId/commit');
      expect(request.headers['Idempotency-Key'], 'idem-commit');
      expect(outcome.knowledgeCommitId, 'commit-1');
      expect(outcome.commitVersion, 1);
      expect(outcome.committedCounts, <String, int>{
        'concept': 2,
        'formula': 1,
      });
      expect(outcome.conceptMappings, hasLength(1));
      expect(outcome.privateKnowledgeCount, 0);
      expect(outcome.firstMission, isNull);
      expect(outcome.sourceDeletionStatus, SourceDeletionStatus.deleted);
    });

    test('commit maps a present first mission summary', () async {
      _resolve(
        dio,
        _commitJson(
          firstMission: <String, dynamic>{
            'mission_id': 'mission-1',
            'status': 'planned',
          },
        ),
      );

      final outcome = await repository.commitUpdate(
        accessToken: 'token',
        updateId: _updateId,
        idempotencyKey: 'idem-commit-2',
      );

      expect(outcome.firstMission?.missionId, 'mission-1');
      expect(outcome.firstMission?.status, 'planned');
    });

    test('409 version_conflict maps to the approved failure copy', () async {
      _reject(dio, 409, 'version_conflict');

      await expectLater(
        repository.updateDraft(
          accessToken: 'token',
          updateId: _updateId,
          version: 1,
          idempotencyKey: 'idem-patch',
          manualText: 'text',
        ),
        throwsA(
          isA<IngestionFailure>()
              .having((failure) => failure.code, 'code', 'version_conflict')
              .having(
                (failure) => failure.message,
                'message',
                'This information has changed. Please review it again.',
              )
              .having(
                (failure) => failure.nextAction,
                'nextAction',
                'Review the latest version and try again.',
              )
              .having((failure) => failure.retryable, 'retryable', isFalse),
        ),
      );
    });

    test('transport failures map to a retryable network failure', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );

      await expectLater(
        repository.getUpdate(accessToken: 'token', updateId: _updateId),
        throwsA(
          isA<IngestionFailure>()
              .having((failure) => failure.code, 'code', 'network_error')
              .having((failure) => failure.retryable, 'retryable', isTrue),
        ),
      );
    });
  });

  group('MockIngestionRepository', () {
    test('manual-text flow reaches commit and replays idempotently', () async {
      final mock = MockIngestionRepository();

      final created = await mock.createUpdate(
        accessToken: 'token',
        subjectId: _subjectId,
        inputType: IngestionInputType.manualText,
        learnedAt: DateTime.utc(2026, 11, 1),
        clientOperationId: 'operation-1',
        idempotencyKey: 'idem-create',
        manualText: 'Newton first law. Force equals mass times acceleration.',
      );
      expect(created.state, LearningUpdateState.processing);

      final processing = await mock.getUpdate(
        accessToken: 'token',
        updateId: created.id,
      );
      expect(processing.state, LearningUpdateState.verificationRequired);

      final candidates = await mock.listCandidates(
        accessToken: 'token',
        updateId: created.id,
      );
      expect(candidates.items, hasLength(2));

      final decisions = await mock.submitDecisions(
        accessToken: 'token',
        updateId: created.id,
        idempotencyKey: 'idem-decisions',
        decisions: candidates.items
            .map(
              (candidate) => DecisionDraft(
                candidateId: candidate.id,
                candidateVersion: candidate.candidateVersion,
                kind: VerificationDecisionKind.accept,
              ),
            )
            .toList(growable: false),
      );
      expect(decisions.outcomes, hasLength(2));

      final preview = await mock.previewPath(
        accessToken: 'token',
        updateId: created.id,
      );
      expect(preview.canCommit, isTrue);
      expect(preview.conceptCount, 2);
      expect(preview.blockedReason, isNull);

      final committed = await mock.commitUpdate(
        accessToken: 'token',
        updateId: created.id,
        idempotencyKey: 'idem-commit',
      );
      final replay = await mock.commitUpdate(
        accessToken: 'token',
        updateId: created.id,
        idempotencyKey: 'idem-commit',
      );
      expect(replay.knowledgeCommitId, committed.knowledgeCommitId);

      final finalState = await mock.getUpdate(
        accessToken: 'token',
        updateId: created.id,
      );
      expect(finalState.state, LearningUpdateState.committed);
      expect(mock.operations, contains(IngestionOperation.commit));
    });

    test('create replay with one operation id creates one row', () async {
      final mock = MockIngestionRepository();

      final first = await mock.createUpdate(
        accessToken: 'token',
        subjectId: _subjectId,
        inputType: IngestionInputType.manualText,
        learnedAt: DateTime.utc(2026, 11, 1),
        clientOperationId: 'operation-1',
        idempotencyKey: 'idem-create',
        manualText: 'Text',
      );
      final second = await mock.createUpdate(
        accessToken: 'token',
        subjectId: _subjectId,
        inputType: IngestionInputType.manualText,
        learnedAt: DateTime.utc(2026, 11, 1),
        clientOperationId: 'operation-1',
        idempotencyKey: 'idem-create-retry',
        manualText: 'Text',
      );

      expect(second.id, first.id);
      final page = await mock.listUpdates(accessToken: 'token');
      expect(page.items, hasLength(1));
    });

    test('file flow grants, finalizes and reaches verification', () async {
      final mock = MockIngestionRepository();
      const source = DeclaredSource(
        declaredName: 'notes.pdf',
        declaredMediaType: 'application/pdf',
        byteSize: 2048,
        contentSha256: 'abc123',
      );

      final created = await mock.createUpdate(
        accessToken: 'token',
        subjectId: _subjectId,
        inputType: IngestionInputType.pdf,
        learnedAt: DateTime.utc(2026, 11, 1),
        clientOperationId: 'operation-1',
        idempotencyKey: 'idem-create',
        files: const <DeclaredSource>[source],
      );
      expect(created.state, LearningUpdateState.uploading);

      final grant = await mock.createUploadGrant(
        accessToken: 'token',
        updateId: created.id,
        source: source,
        idempotencyKey: 'idem-grant',
      );
      expect(grant.method, 'PUT');

      final finalized = await mock.finalizeUpload(
        accessToken: 'token',
        updateId: created.id,
        uploadId: grant.uploadId,
        observedSize: source.byteSize,
        contentSha256: source.contentSha256,
        clientOperationId: 'operation-1',
        idempotencyKey: 'idem-finalize',
      );
      expect(finalized.state, LearningUpdateState.processing);

      final processing = await mock.getUpdate(
        accessToken: 'token',
        updateId: created.id,
      );
      expect(processing.state, LearningUpdateState.verificationRequired);
      expect(processing.uploads.single.status, SourceUploadState.validated);
    });

    test('draft edits enforce the row version', () async {
      final mock = MockIngestionRepository();
      mock.seedUpdate(
        UpdateSnapshot(
          id: _updateId,
          subjectId: _subjectId,
          inputType: IngestionInputType.manualText,
          state: LearningUpdateState.draft,
          hasManualText: true,
          learnedAt: DateTime.utc(2026, 11, 1),
          rowVersion: 1,
          sourceDeletionStatus: SourceDeletionStatus.notRequired,
        ),
      );

      final updated = await mock.updateDraft(
        accessToken: 'token',
        updateId: _updateId,
        version: 1,
        idempotencyKey: 'idem-patch',
        manualText: 'Changed',
      );
      expect(updated.rowVersion, 2);

      await expectLater(
        mock.updateDraft(
          accessToken: 'token',
          updateId: _updateId,
          version: 1,
          idempotencyKey: 'idem-patch-2',
          manualText: 'Changed again',
        ),
        throwsA(
          isA<IngestionFailure>().having(
            (failure) => failure.code,
            'code',
            'version_conflict',
          ),
        ),
      );
    });

    test('configured failures are thrown before state changes', () async {
      final failure = IngestionFailure.network();
      final mock = MockIngestionRepository(
        failures: <IngestionOperation, IngestionFailure>{
          IngestionOperation.create: failure,
        },
      );

      await expectLater(
        mock.createUpdate(
          accessToken: 'token',
          subjectId: _subjectId,
          inputType: IngestionInputType.manualText,
          learnedAt: DateTime.utc(2026, 11, 1),
          clientOperationId: 'operation-1',
          idempotencyKey: 'idem-create',
          manualText: 'Text',
        ),
        throwsA(same(failure)),
      );
      final page = await mock.listUpdates(accessToken: 'token');
      expect(page.items, isEmpty);
    });
  });
}
