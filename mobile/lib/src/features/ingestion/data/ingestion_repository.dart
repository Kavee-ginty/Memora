import 'package:dio/dio.dart';
import 'package:memora_api_client/memora_api_client.dart';

import '../../../configuration/app_configuration.dart';
import '../../common/ids.dart';
import '../domain/ingestion_failure.dart';
import '../domain/ingestion_models.dart';
import 'ingestion_error_mapper.dart';

/// Contract for every learning-ingestion operation in API §11-12.
///
/// The repository is the only layer that talks to the generated client. It
/// converts transport DTOs into immutable domain models and collapses every
/// failure into an allowlisted [IngestionFailure].
abstract class IngestionRepository {
  /// Lists the student's learning updates, newest first.
  Future<UpdatePage> listUpdates({
    required String accessToken,
    String? cursor,
    int limit = 20,
  });

  /// Creates a text- or file-backed update.
  ///
  /// [clientOperationId] must stay stable while the same creation attempt is
  /// unresolved so a retry converges on one server row (FLOW-002).
  Future<UpdateSnapshot> createUpdate({
    required String accessToken,
    required String subjectId,
    required IngestionInputType inputType,
    required DateTime learnedAt,
    required String clientOperationId,
    required String idempotencyKey,
    String? manualText,
    List<DeclaredSource> files = const <DeclaredSource>[],
  });

  /// Reads the authoritative update snapshot.
  Future<UpdateSnapshot> getUpdate({
    required String accessToken,
    required String updateId,
  });

  /// Edits an eligible draft using optimistic concurrency.
  Future<UpdateSnapshot> updateDraft({
    required String accessToken,
    required String updateId,
    required int version,
    required String idempotencyKey,
    DateTime? learnedAt,
    String? manualText,
  });

  /// Discards an eligible draft or cancels a workflow.
  Future<void> deleteUpdate({
    required String accessToken,
    required String updateId,
    required String idempotencyKey,
  });

  /// Requests a short-lived presigned upload grant for one declared source.
  Future<UploadGrant> createUploadGrant({
    required String accessToken,
    required String updateId,
    required DeclaredSource source,
    required String idempotencyKey,
  });

  /// Confirms the uploaded object so the server can queue processing.
  Future<UpdateSnapshot> finalizeUpload({
    required String accessToken,
    required String updateId,
    required String uploadId,
    required int observedSize,
    required String contentSha256,
    required String clientOperationId,
    required String idempotencyKey,
  });

  /// Retries one eligible failed stage.
  Future<UpdateSnapshot> retryUpdate({
    required String accessToken,
    required String updateId,
    required IngestionRetryStage stage,
    required String idempotencyKey,
  });

  /// Lists extraction candidates for one update.
  Future<CandidatePage> listCandidates({
    required String accessToken,
    required String updateId,
    String? cursor,
    int limit = 20,
  });

  /// Submits one batch of versioned verification decisions.
  Future<VerificationOutcome> submitDecisions({
    required String accessToken,
    required String updateId,
    required List<DecisionDraft> decisions,
    required String idempotencyKey,
  });

  /// Reads the authoritative learning-path preview.
  Future<PathPreview> previewPath({
    required String accessToken,
    required String updateId,
  });

  /// Commits accepted knowledge exactly once for a durable operation key.
  Future<CommitOutcome> commitUpdate({
    required String accessToken,
    required String updateId,
    required String idempotencyKey,
  });
}

/// Generated-client implementation of [IngestionRepository].
class MemoraIngestionRepository implements IngestionRepository {
  const MemoraIngestionRepository({
    required this.apiClient,
    required this.configuration,
  });

  final MemoraApiClient apiClient;
  final AppConfiguration configuration;

  LearningUpdatesApi get _updates => apiClient.getLearningUpdatesApi();
  VerificationApi get _verification => apiClient.getVerificationApi();

  String get _correlationId => generateUuid();
  String get _clientVersion => configuration.clientVersion;
  String get _platform => configuration.platform;

  @override
  Future<UpdatePage> listUpdates({
    required String accessToken,
    String? cursor,
    int limit = 20,
  }) {
    return _guard(() async {
      _authorize(accessToken);
      final response = await _updates.listLearningUpdates(
        xCorrelationID: _correlationId,
        xClientVersion: _clientVersion,
        xPlatform: _platform,
        cursor: cursor,
        limit: limit,
      );
      final data = _requireData(response.data);
      return UpdatePage(
        items: data.items.map(_mapUpdate).toList(growable: false),
        hasMore: data.hasMore,
        nextCursor: data.nextCursor,
      );
    });
  }

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
    return _guard(() async {
      _authorize(accessToken);
      final request = CreateLearningUpdateRequest((builder) {
        builder
          ..clientOperationId = clientOperationId
          ..inputType = _toGeneratedInputType(inputType)
          ..learnedAt = learnedAt
          ..subjectId = subjectId;
        builder.files.addAll(files.map(_toDeclaredFile));
        if (manualText != null) {
          builder.manualText = Optional<String?>.present(manualText);
        }
      });

      final response = await _updates.createLearningUpdate(
        xCorrelationID: _correlationId,
        xClientVersion: _clientVersion,
        xPlatform: _platform,
        idempotencyKey: idempotencyKey,
        createLearningUpdateRequest: request,
      );
      return _mapUpdate(_requireData(response.data));
    });
  }

  @override
  Future<UpdateSnapshot> getUpdate({
    required String accessToken,
    required String updateId,
  }) {
    return _guard(() async {
      _authorize(accessToken);
      final response = await _updates.getLearningUpdate(
        updateId: updateId,
        xCorrelationID: _correlationId,
        xClientVersion: _clientVersion,
        xPlatform: _platform,
      );
      return _mapUpdate(_requireData(response.data));
    });
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
    return _guard(() async {
      _authorize(accessToken);
      final request = UpdateLearningUpdateRequest((builder) {
        builder.version = version;
        if (learnedAt != null) {
          builder.learnedAt = Optional<DateTime?>.present(learnedAt);
        }
        if (manualText != null) {
          builder.manualText = Optional<String?>.present(manualText);
        }
      });

      final response = await _updates.updateLearningUpdate(
        updateId: updateId,
        xCorrelationID: _correlationId,
        xClientVersion: _clientVersion,
        xPlatform: _platform,
        idempotencyKey: idempotencyKey,
        updateLearningUpdateRequest: request,
      );
      return _mapUpdate(_requireData(response.data));
    });
  }

  @override
  Future<void> deleteUpdate({
    required String accessToken,
    required String updateId,
    required String idempotencyKey,
  }) {
    return _guard(() async {
      _authorize(accessToken);
      await _updates.deleteLearningUpdate(
        updateId: updateId,
        xCorrelationID: _correlationId,
        xClientVersion: _clientVersion,
        xPlatform: _platform,
        idempotencyKey: idempotencyKey,
      );
    });
  }

  @override
  Future<UploadGrant> createUploadGrant({
    required String accessToken,
    required String updateId,
    required DeclaredSource source,
    required String idempotencyKey,
  }) {
    return _guard(() async {
      _authorize(accessToken);
      final request = UploadGrantRequest((builder) {
        builder
          ..byteSize = source.byteSize
          ..contentSha256 = source.contentSha256
          ..declaredMediaType = source.declaredMediaType
          ..declaredName = source.declaredName;
      });

      final response = await _updates.createUploadGrant(
        updateId: updateId,
        xCorrelationID: _correlationId,
        xClientVersion: _clientVersion,
        xPlatform: _platform,
        idempotencyKey: idempotencyKey,
        uploadGrantRequest: request,
      );
      final data = _requireData(response.data);
      return UploadGrant(
        uploadId: data.uploadId,
        url: data.url,
        method: _grantMethodWire(data.method),
        requiredHeaders: data.requiredHeaders.asMap(),
        maxBytes: data.maxBytes,
        expiresAt: _parseDate(data.expiresAt),
        checksumRule: data.checksumRule,
      );
    });
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
    return _guard(() async {
      _authorize(accessToken);
      final request = FinalizeUploadRequest((builder) {
        builder
          ..clientOperationId = clientOperationId
          ..contentSha256 = contentSha256
          ..observedSize = observedSize;
      });

      final response = await _updates.finalizeUpload(
        updateId: updateId,
        uploadId: uploadId,
        xCorrelationID: _correlationId,
        xClientVersion: _clientVersion,
        xPlatform: _platform,
        idempotencyKey: idempotencyKey,
        finalizeUploadRequest: request,
      );
      return _mapUpdate(_requireData(response.data));
    });
  }

  @override
  Future<UpdateSnapshot> retryUpdate({
    required String accessToken,
    required String updateId,
    required IngestionRetryStage stage,
    required String idempotencyKey,
  }) {
    return _guard(() async {
      _authorize(accessToken);
      final request = RetryLearningUpdateRequest((builder) {
        builder.stage = switch (stage) {
          IngestionRetryStage.extraction =>
            RetryLearningUpdateRequestStageEnum.extraction,
          IngestionRetryStage.deletion =>
            RetryLearningUpdateRequestStageEnum.deletion,
        };
      });

      final response = await _updates.retryLearningUpdate(
        updateId: updateId,
        xCorrelationID: _correlationId,
        xClientVersion: _clientVersion,
        xPlatform: _platform,
        idempotencyKey: idempotencyKey,
        retryLearningUpdateRequest: request,
      );
      return _mapUpdate(_requireData(response.data));
    });
  }

  @override
  Future<CandidatePage> listCandidates({
    required String accessToken,
    required String updateId,
    String? cursor,
    int limit = 20,
  }) {
    return _guard(() async {
      _authorize(accessToken);
      final response = await _verification.listExtractionCandidates(
        updateId: updateId,
        xCorrelationID: _correlationId,
        xClientVersion: _clientVersion,
        xPlatform: _platform,
        cursor: cursor,
        limit: limit,
      );
      final data = _requireData(response.data);
      return CandidatePage(
        items: data.items.map(_mapCandidate).toList(growable: false),
        hasMore: data.hasMore,
        nextCursor: data.nextCursor,
      );
    });
  }

  @override
  Future<VerificationOutcome> submitDecisions({
    required String accessToken,
    required String updateId,
    required List<DecisionDraft> decisions,
    required String idempotencyKey,
  }) {
    return _guard(() async {
      if (decisions.isEmpty) {
        throw IngestionFailure.unknown();
      }
      _authorize(accessToken);
      final request = SubmitVerificationDecisionsRequest((builder) {
        builder.decisions.addAll(decisions.map(_toVerificationDecision));
      });

      final response = await _verification.submitVerificationDecisions(
        updateId: updateId,
        xCorrelationID: _correlationId,
        xClientVersion: _clientVersion,
        xPlatform: _platform,
        idempotencyKey: idempotencyKey,
        submitVerificationDecisionsRequest: request,
      );
      final data = _requireData(response.data);
      return VerificationOutcome(
        update: _mapUpdate(data.learningUpdate),
        outcomes: data.results
            .map(
              (result) => DecisionOutcome(
                candidateId: result.candidateId,
                state: CandidateState.fromWireName(
                  _candidateStatusWire(result.candidateStatus),
                ),
                requiresVerification: result.requiresVerification,
              ),
            )
            .toList(growable: false),
      );
    });
  }

  @override
  Future<PathPreview> previewPath({
    required String accessToken,
    required String updateId,
  }) {
    return _guard(() async {
      _authorize(accessToken);
      final response = await _verification.previewLearningPath(
        updateId: updateId,
        xCorrelationID: _correlationId,
        xClientVersion: _clientVersion,
        xPlatform: _platform,
      );
      final data = _requireData(response.data);
      return PathPreview(
        updateId: data.updateId,
        state: LearningUpdateState.fromWireName(_updateStatusWire(data.status)),
        conceptCount: data.conceptCount,
        firstConcepts: data.firstConcepts
            .map(_mapPreviewConcept)
            .toList(growable: false),
        estimatedFirstMissionMinutes: data.estimatedFirstMissionMinutes,
        canCommit: data.canCommit,
        blockedReason: data.blockedReason == null
            ? null
            : PreviewBlockReason.fromWireName(data.blockedReason),
      );
    });
  }

  @override
  Future<CommitOutcome> commitUpdate({
    required String accessToken,
    required String updateId,
    required String idempotencyKey,
  }) {
    return _guard(() async {
      _authorize(accessToken);
      final response = await _verification.commitLearningUpdate(
        updateId: updateId,
        xCorrelationID: _correlationId,
        xClientVersion: _clientVersion,
        xPlatform: _platform,
        idempotencyKey: idempotencyKey,
      );
      final data = _requireData(response.data);
      final firstMission = data.firstMission.isPresent
          ? data.firstMission.value
          : null;
      return CommitOutcome(
        knowledgeCommitId: data.knowledgeCommitId,
        commitVersion: data.commitVersion,
        committedCounts: Map<String, int>.unmodifiable(
          data.committedCounts.asMap(),
        ),
        conceptMappings: data.conceptMappings
            .map(_mapPreviewConcept)
            .toList(growable: false),
        privateKnowledgeCount: data.privateKnowledgeCount,
        firstMission: firstMission == null
            ? null
            : FirstMissionInfo(
                missionId: firstMission.missionId,
                status: firstMission.status,
              ),
        sourceDeletionStatus: SourceDeletionStatus.fromWireName(
          _deletionStatusWire(data.sourceDeletionStatus),
        ),
      );
    });
  }

  void _authorize(String accessToken) {
    apiClient.setBearerAuth('bearerAuth', accessToken);
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw mapDioExceptionToIngestionFailure(error);
    } on IngestionFailure {
      rethrow;
    } catch (_) {
      throw IngestionFailure.unknown();
    }
  }

  T _requireData<T>(T? data) {
    if (data == null) throw IngestionFailure.unknown();
    return data;
  }

  UpdateSnapshot _mapUpdate(LearningUpdateResponse response) {
    final state = LearningUpdateState.fromWireName(
      _updateStatusWire(response.status),
    );
    return UpdateSnapshot(
      id: response.id,
      subjectId: response.subjectId,
      inputType: IngestionInputType.fromWireName(
        _inputTypeWire(response.inputType),
      ),
      state: state,
      failure: state == LearningUpdateState.failed
          ? mapUpdateFailureCode(response.failureCode)
          : null,
      hasManualText: response.hasManualText,
      learnedAt: _parseDate(response.learnedAt),
      expiresAt: _parseDate(response.expiresAt),
      createdAt: _parseDate(response.createdAt),
      updatedAt: _parseDate(response.updatedAt),
      rowVersion: response.rowVersion,
      sourceDeletionStatus: SourceDeletionStatus.fromWireName(
        _deletionStatusWire(response.sourceDeletionStatus),
      ),
      uploads: response.uploads.map(_mapUpload).toList(growable: false),
    );
  }

  SourceItem _mapUpload(SourceUploadSummary upload) {
    return SourceItem(
      id: upload.id,
      declaredName: upload.declaredName,
      declaredMediaType: upload.declaredMediaType,
      detectedMediaType: upload.detectedMediaType,
      byteSize: upload.byteSize,
      status: SourceUploadState.fromWireName(_uploadStatusWire(upload.status)),
      expiresAt: _parseDate(upload.expiresAt),
      deletedAt: _parseDate(upload.deletedAt),
      deletionStatus: SourceDeletionStatus.fromWireName(
        _deletionStatusWire(upload.deletionStatus),
      ),
    );
  }

  CandidateItem _mapCandidate(CandidateResponse candidate) {
    return CandidateItem(
      id: candidate.id,
      candidateType: candidate.candidateType,
      displayTitle: candidate.displayTitle,
      displaySummary: candidate.displaySummary,
      sourceContext: _sourceContext(candidate),
      confidence: candidate.confidence.toDouble(),
      band: ConfidenceBand.fromWireName(
        _confidenceBandWire(candidate.confidenceBand),
      ),
      requiresVerification: candidate.requiresVerification,
      status: CandidateState.fromWireName(_candidateStatusWire(candidate.status)),
      candidateVersion: candidate.candidateVersion,
    );
  }

  PreviewConcept _mapPreviewConcept(LearningPathPreviewConcept concept) {
    return PreviewConcept(
      candidateId: concept.candidateId,
      title: concept.title,
      candidateType: concept.candidateType,
      conceptId: concept.conceptId,
      conceptVersionId: concept.conceptVersionId,
    );
  }

  /// Builds bounded, client-safe context from the candidate locator.
  ///
  /// The API never returns source excerpts, so the client only states where the
  /// candidate came from. It never fabricates or echoes learning text.
  String? _sourceContext(CandidateResponse candidate) {
    final locator = candidate.sourceLocator;
    final kind = locator['kind']?.value;
    if (kind == 'page') {
      final page = locator['page']?.value;
      if (page is int && page > 0) return 'Page $page';
      return 'From a page in your source';
    }
    if (kind == 'text_range') return 'From your text';
    return null;
  }

  DeclaredFile _toDeclaredFile(DeclaredSource source) {
    return DeclaredFile((builder) {
      builder
        ..byteSize = source.byteSize
        ..contentSha256 = source.contentSha256
        ..declaredMediaType = source.declaredMediaType
        ..declaredName = source.declaredName;
    });
  }

  VerificationDecision _toVerificationDecision(DecisionDraft draft) {
    final correctedPayload = <String, dynamic>{};
    switch (draft.kind) {
      case VerificationDecisionKind.accept:
      case VerificationDecisionKind.reject:
        break;
      case VerificationDecisionKind.edit:
        correctedPayload['title'] = draft.editedTitle?.trim();
      case VerificationDecisionKind.merge:
        correctedPayload['merge_into_candidate_id'] =
            draft.mergeIntoCandidateId;
    }

    // Using the generated serializer keeps JsonObject construction inside the
    // generated contract rather than hand-building transport maps.
    final decision = standardSerializers.deserializeWith(
      VerificationDecision.serializer,
      <String, dynamic>{
        'candidate_id': draft.candidateId,
        'candidate_version': draft.candidateVersion,
        'decision': _decisionWireName(draft.kind),
        'corrected_payload': correctedPayload,
      },
    );
    if (decision == null) throw IngestionFailure.unknown();
    return decision;
  }

  InputType _toGeneratedInputType(IngestionInputType inputType) {
    return switch (inputType) {
      IngestionInputType.manualText => InputType.manualText,
      IngestionInputType.pdf => InputType.pdf,
      IngestionInputType.image => InputType.image,
      IngestionInputType.mixed => InputType.mixed,
      IngestionInputType.unknown => throw IngestionFailure.unknown(),
    };
  }

  String _decisionWireName(VerificationDecisionKind kind) {
    return switch (kind) {
      VerificationDecisionKind.accept => 'accept',
      VerificationDecisionKind.edit => 'edit',
      VerificationDecisionKind.reject => 'reject',
      VerificationDecisionKind.merge => 'merge',
    };
  }

  String _updateStatusWire(LearningUpdateStatus value) =>
      standardSerializers.serializeWith(LearningUpdateStatus.serializer, value)
          as String;

  String _inputTypeWire(InputType value) =>
      standardSerializers.serializeWith(InputType.serializer, value) as String;

  String _deletionStatusWire(DeletionStatus value) =>
      standardSerializers.serializeWith(DeletionStatus.serializer, value)
          as String;

  String _uploadStatusWire(UploadStatus value) =>
      standardSerializers.serializeWith(UploadStatus.serializer, value)
          as String;

  String _candidateStatusWire(CandidateStatus value) =>
      standardSerializers.serializeWith(CandidateStatus.serializer, value)
          as String;

  String _confidenceBandWire(CandidateResponseConfidenceBandEnum value) =>
      standardSerializers.serializeWith(
            CandidateResponseConfidenceBandEnum.serializer,
            value,
          )
          as String;

  String _grantMethodWire(UploadGrantResponseMethodEnum value) =>
      standardSerializers.serializeWith(
            UploadGrantResponseMethodEnum.serializer,
            value,
          )
          as String;

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

/// Operations that a mock or test can make fail deterministically.
enum IngestionOperation {
  create,
  list,
  get,
  update,
  delete,
  grant,
  finalize,
  retry,
  candidates,
  decisions,
  preview,
  commit,
}

/// Deterministic in-memory repository used by tests and the local baseline.
///
/// It mirrors the server state machine closely enough to exercise the screens:
/// text creation starts in `processing`, file creation in `uploading`, finalize
/// moves to `processing`, and the next read advances to
/// `verification_required` when [autoAdvanceProcessing] is true.
class MockIngestionRepository implements IngestionRepository {
  MockIngestionRepository({
    this.delay = Duration.zero,
    this.autoAdvanceProcessing = true,
    Map<IngestionOperation, IngestionFailure>? failures,
  }) : failures = failures ?? <IngestionOperation, IngestionFailure>{};

  final Duration delay;
  final bool autoAdvanceProcessing;
  final Map<IngestionOperation, IngestionFailure> failures;

  final Map<String, UpdateSnapshot> _updates = <String, UpdateSnapshot>{};
  final Map<String, String> _manualTexts = <String, String>{};
  final Map<String, List<CandidateItem>> _candidates =
      <String, List<CandidateItem>>{};
  final Map<String, String> _createByOperation = <String, String>{};
  final Map<String, VerificationOutcome> _decisionsByKey =
      <String, VerificationOutcome>{};
  final Map<String, CommitOutcome> _commitsByKey = <String, CommitOutcome>{};
  final Map<String, CommitOutcome> _committedByUpdate = <String, CommitOutcome>{};

  /// Ordered log of operations the screens triggered.
  final List<IngestionOperation> operations = <IngestionOperation>[];

  /// Seeds a server-shaped update for tests that need a non-default state.
  void seedUpdate(UpdateSnapshot update, {List<CandidateItem>? candidates}) {
    _updates[update.id] = update;
    if (candidates != null) {
      _candidates[update.id] = List<CandidateItem>.of(candidates);
    }
  }

  @override
  Future<UpdatePage> listUpdates({
    required String accessToken,
    String? cursor,
    int limit = 20,
  }) async {
    await _enter(IngestionOperation.list);
    final all = _updates.values.toList()
      ..sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });

    final pageSize = limit < 1 ? 20 : limit;
    var start = int.tryParse(cursor ?? '') ?? 0;
    if (start < 0) start = 0;
    if (start > all.length) start = all.length;
    var end = start + pageSize;
    if (end > all.length) end = all.length;

    return UpdatePage(
      items: all.sublist(start, end),
      hasMore: end < all.length,
      nextCursor: end < all.length ? '$end' : null,
    );
  }

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
  }) async {
    await _enter(IngestionOperation.create);
    final existingId = _createByOperation[clientOperationId];
    if (existingId != null) return _requireUpdate(existingId);

    final now = DateTime.now().toUtc();
    final updateId = generateUuid();
    final uploads = <SourceItem>[
      for (final file in files)
        SourceItem(
          id: generateUuid(),
          declaredName: file.declaredName,
          declaredMediaType: file.declaredMediaType,
          byteSize: file.byteSize,
          status: SourceUploadState.authorized,
          expiresAt: now.add(const Duration(hours: 24)),
          deletionStatus: SourceDeletionStatus.notRequired,
        ),
    ];

    final update = UpdateSnapshot(
      id: updateId,
      subjectId: subjectId,
      inputType: inputType,
      state: files.isEmpty
          ? LearningUpdateState.processing
          : LearningUpdateState.uploading,
      hasManualText: manualText != null && manualText.trim().isNotEmpty,
      learnedAt: learnedAt,
      expiresAt: now.add(const Duration(hours: 24)),
      createdAt: now,
      updatedAt: now,
      rowVersion: 1,
      sourceDeletionStatus: SourceDeletionStatus.notRequired,
      uploads: uploads,
    );

    _updates[updateId] = update;
    if (manualText != null) _manualTexts[updateId] = manualText;
    _createByOperation[clientOperationId] = updateId;
    return update;
  }

  @override
  Future<UpdateSnapshot> getUpdate({
    required String accessToken,
    required String updateId,
  }) async {
    await _enter(IngestionOperation.get);
    final update = _requireUpdate(updateId);
    if (!autoAdvanceProcessing ||
        update.state != LearningUpdateState.processing) {
      return update;
    }

    final candidates = _candidates.putIfAbsent(
      updateId,
      () => _extractCandidates(update),
    );
    if (candidates.isEmpty) return update;

    final next = _copyUpdate(
      update,
      state: LearningUpdateState.verificationRequired,
      rowVersion: update.rowVersion + 1,
      updatedAt: DateTime.now().toUtc(),
    );
    _updates[updateId] = next;
    return next;
  }

  @override
  Future<UpdateSnapshot> updateDraft({
    required String accessToken,
    required String updateId,
    required int version,
    required String idempotencyKey,
    DateTime? learnedAt,
    String? manualText,
  }) async {
    await _enter(IngestionOperation.update);
    final update = _requireUpdate(updateId);
    if (update.state != LearningUpdateState.draft) {
      throw _invalidState();
    }
    if (update.rowVersion != version) {
      throw _versionConflict();
    }

    if (manualText != null) _manualTexts[updateId] = manualText;
    final next = _copyUpdate(
      update,
      learnedAt: learnedAt ?? update.learnedAt,
      hasManualText: manualText == null
          ? update.hasManualText
          : manualText.trim().isNotEmpty,
      rowVersion: update.rowVersion + 1,
      updatedAt: DateTime.now().toUtc(),
    );
    _updates[updateId] = next;
    return next;
  }

  @override
  Future<void> deleteUpdate({
    required String accessToken,
    required String updateId,
    required String idempotencyKey,
  }) async {
    await _enter(IngestionOperation.delete);
    final update = _requireUpdate(updateId);
    if (update.state == LearningUpdateState.deleted) return;

    final now = DateTime.now().toUtc();
    final uploads = update.uploads
        .map(
          (upload) => _copySource(
            upload,
            status: SourceUploadState.deleted,
            deletionStatus: SourceDeletionStatus.deleted,
            deletedAt: now,
          ),
        )
        .toList(growable: false);
    _updates[updateId] = _copyUpdate(
      update,
      state: LearningUpdateState.deleted,
      rowVersion: update.rowVersion + 1,
      updatedAt: now,
      sourceDeletionStatus: SourceDeletionStatus.deleted,
      uploads: uploads,
    );
  }

  @override
  Future<UploadGrant> createUploadGrant({
    required String accessToken,
    required String updateId,
    required DeclaredSource source,
    required String idempotencyKey,
  }) async {
    await _enter(IngestionOperation.grant);
    final update = _requireUpdate(updateId);
    if (update.state != LearningUpdateState.uploading) {
      throw _invalidState();
    }

    SourceItem? target;
    for (final upload in update.uploads) {
      if (upload.status == SourceUploadState.authorized &&
          upload.declaredName == source.declaredName &&
          upload.byteSize == source.byteSize) {
        target = upload;
        break;
      }
    }
    if (target == null) throw _invalidState();

    return UploadGrant(
      uploadId: target.id,
      url: 'https://uploads.memora.test/${target.id}',
      method: 'PUT',
      requiredHeaders: <String, String>{
        'x-memora-upload': 'mock-grant',
        'content-type': source.declaredMediaType,
      },
      maxBytes: 25 * 1024 * 1024,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
      checksumRule: 'SHA-256 hex digest of the exact uploaded bytes',
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
  }) async {
    await _enter(IngestionOperation.finalize);
    final update = _requireUpdate(updateId);
    final target = update.uploadById(uploadId);
    if (target == null) throw _notFound();
    if (target.status == SourceUploadState.validated ||
        target.status == SourceUploadState.processing) {
      return update;
    }
    if (update.state != LearningUpdateState.uploading) {
      throw _invalidState();
    }

    final uploads = update.uploads
        .map(
          (upload) => upload.id == uploadId
              ? _copySource(
                  upload,
                  status: SourceUploadState.validated,
                  detectedMediaType: upload.declaredMediaType,
                )
              : upload,
        )
        .toList(growable: false);
    // A multi-file update stays `uploading` until every declared file is
    // finalized; only then does the worker start extraction.
    final allValidated = uploads.every(
      (upload) =>
          upload.status == SourceUploadState.validated ||
          upload.status == SourceUploadState.processing,
    );
    final next = _copyUpdate(
      update,
      state: allValidated
          ? LearningUpdateState.processing
          : LearningUpdateState.uploading,
      uploads: uploads,
      rowVersion: update.rowVersion + 1,
      updatedAt: DateTime.now().toUtc(),
    );
    _updates[updateId] = next;
    return next;
  }

  @override
  Future<UpdateSnapshot> retryUpdate({
    required String accessToken,
    required String updateId,
    required IngestionRetryStage stage,
    required String idempotencyKey,
  }) async {
    await _enter(IngestionOperation.retry);
    final update = _requireUpdate(updateId);

    if (stage == IngestionRetryStage.extraction) {
      if (update.state != LearningUpdateState.failed) throw _invalidState();
      final next = _copyUpdate(
        update,
        state: LearningUpdateState.processing,
        rowVersion: update.rowVersion + 1,
        updatedAt: DateTime.now().toUtc(),
      );
      _updates[updateId] = next;
      return next;
    }

    // Source deletion is independent of the retained update's state, so
    // cleanup recovery must also work for a committed update (D9).
    final retriable = update.uploads.where((upload) {
      return upload.deletedAt == null &&
          (upload.status == SourceUploadState.deleting ||
              upload.status == SourceUploadState.expired ||
              upload.status == SourceUploadState.rejected);
    }).toList(growable: false);
    if (retriable.isEmpty) throw _invalidState();

    final now = DateTime.now().toUtc();
    final ids = retriable.map((upload) => upload.id).toSet();
    final uploads = update.uploads
        .map(
          (upload) => ids.contains(upload.id)
              ? _copySource(
                  upload,
                  status: SourceUploadState.deleted,
                  deletionStatus: SourceDeletionStatus.deleted,
                  deletedAt: now,
                )
              : upload,
        )
        .toList(growable: false);
    final next = _copyUpdate(
      update,
      uploads: uploads,
      sourceDeletionStatus: SourceDeletionStatus.deleted,
      rowVersion: update.rowVersion + 1,
      updatedAt: now,
    );
    _updates[updateId] = next;
    return next;
  }

  @override
  Future<CandidatePage> listCandidates({
    required String accessToken,
    required String updateId,
    String? cursor,
    int limit = 20,
  }) async {
    await _enter(IngestionOperation.candidates);
    final update = _requireUpdate(updateId);
    if (update.state != LearningUpdateState.verificationRequired &&
        update.state != LearningUpdateState.committed) {
      throw _invalidState();
    }

    final all = _candidates[updateId] ?? const <CandidateItem>[];
    final pageSize = limit < 1 ? 20 : limit;
    var start = int.tryParse(cursor ?? '') ?? 0;
    if (start < 0) start = 0;
    if (start > all.length) start = all.length;
    var end = start + pageSize;
    if (end > all.length) end = all.length;

    return CandidatePage(
      items: all.sublist(start, end),
      hasMore: end < all.length,
      nextCursor: end < all.length ? '$end' : null,
    );
  }

  @override
  Future<VerificationOutcome> submitDecisions({
    required String accessToken,
    required String updateId,
    required List<DecisionDraft> decisions,
    required String idempotencyKey,
  }) async {
    await _enter(IngestionOperation.decisions);
    final existing = _decisionsByKey[idempotencyKey];
    if (existing != null) return existing;

    final update = _requireUpdate(updateId);
    if (update.state != LearningUpdateState.verificationRequired) {
      throw _invalidState();
    }
    if (decisions.isEmpty) throw _invalidState();

    final current = _candidates[updateId] ?? const <CandidateItem>[];
    final byId = <String, CandidateItem>{
      for (final candidate in current) candidate.id: candidate,
    };
    for (final decision in decisions) {
      final candidate = byId[decision.candidateId];
      if (candidate == null) throw _notFound();
      if (candidate.candidateVersion != decision.candidateVersion) {
        throw _versionConflict();
      }
      if (!decision.isValid) throw _validationFailed();
    }

    final nextCandidates = List<CandidateItem>.of(current);
    final outcomes = <DecisionOutcome>[];
    for (final decision in decisions) {
      final index = nextCandidates.indexWhere(
        (candidate) => candidate.id == decision.candidateId,
      );
      final candidate = nextCandidates[index];
      final updated = switch (decision.kind) {
        VerificationDecisionKind.accept => _copyCandidate(
          candidate,
          status: CandidateState.accepted,
        ),
        VerificationDecisionKind.reject => _copyCandidate(
          candidate,
          status: CandidateState.rejected,
        ),
        VerificationDecisionKind.edit => _copyCandidate(
          candidate,
          displayTitle: decision.editedTitle?.trim(),
          status: CandidateState.accepted,
        ),
        VerificationDecisionKind.merge => _copyCandidate(
          candidate,
          status: CandidateState.accepted,
        ),
      };
      nextCandidates[index] = updated;
      outcomes.add(
        DecisionOutcome(
          candidateId: updated.id,
          state: updated.status,
          requiresVerification: updated.requiresVerification,
        ),
      );
    }

    _candidates[updateId] = nextCandidates;
    final nextUpdate = _copyUpdate(
      update,
      rowVersion: update.rowVersion + 1,
      updatedAt: DateTime.now().toUtc(),
    );
    _updates[updateId] = nextUpdate;
    final outcome = VerificationOutcome(update: nextUpdate, outcomes: outcomes);
    _decisionsByKey[idempotencyKey] = outcome;
    return outcome;
  }

  @override
  Future<PathPreview> previewPath({
    required String accessToken,
    required String updateId,
  }) async {
    await _enter(IngestionOperation.preview);
    final update = _requireUpdate(updateId);
    final candidates = _candidates[updateId] ?? const <CandidateItem>[];
    final accepted = candidates
        .where((candidate) => candidate.status == CandidateState.accepted)
        .toList(growable: false);
    final pending = candidates.any(
      (candidate) =>
          candidate.requiresVerification &&
          (candidate.status == CandidateState.candidate ||
              candidate.status == CandidateState.needsVerification),
    );

    final canCommit =
        update.state == LearningUpdateState.verificationRequired &&
        accepted.isNotEmpty &&
        !pending;

    PreviewBlockReason? blockedReason;
    if (pending) {
      blockedReason = PreviewBlockReason.verificationPending;
    } else if (accepted.isEmpty) {
      blockedReason = PreviewBlockReason.noValidConcept;
    } else if (update.state != LearningUpdateState.verificationRequired) {
      blockedReason = PreviewBlockReason.invalidState;
    }

    final estimate = accepted.length * 2;
    return PathPreview(
      updateId: updateId,
      state: update.state,
      conceptCount: accepted.length,
      firstConcepts: accepted
          .take(5)
          .map(
            (candidate) => PreviewConcept(
              candidateId: candidate.id,
              title: candidate.displayTitle,
              candidateType: candidate.candidateType,
            ),
          )
          .toList(growable: false),
      estimatedFirstMissionMinutes: accepted.isEmpty
          ? null
          : (estimate < 5 ? 5 : (estimate > 20 ? 20 : estimate)),
      canCommit: canCommit,
      blockedReason: blockedReason,
    );
  }

  @override
  Future<CommitOutcome> commitUpdate({
    required String accessToken,
    required String updateId,
    required String idempotencyKey,
  }) async {
    await _enter(IngestionOperation.commit);
    final existing = _commitsByKey[idempotencyKey];
    if (existing != null) return existing;

    final alreadyCommitted = _committedByUpdate[updateId];
    if (alreadyCommitted != null) {
      _commitsByKey[idempotencyKey] = alreadyCommitted;
      return alreadyCommitted;
    }

    final update = _requireUpdate(updateId);
    final preview = await _buildPreview(update);
    if (!preview.canCommit) throw _invalidState();

    final accepted = (_candidates[updateId] ?? const <CandidateItem>[])
        .where((candidate) => candidate.status == CandidateState.accepted)
        .toList(growable: false);
    final counts = <String, int>{};
    for (final candidate in accepted) {
      counts.update(
        candidate.candidateType,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final outcome = CommitOutcome(
      knowledgeCommitId: generateUuid(),
      commitVersion: 1,
      committedCounts: Map<String, int>.unmodifiable(counts),
      conceptMappings: accepted
          .map(
            (candidate) => PreviewConcept(
              candidateId: candidate.id,
              title: candidate.displayTitle,
              candidateType: candidate.candidateType,
            ),
          )
          .toList(growable: false),
      privateKnowledgeCount: 0,
      sourceDeletionStatus: update.sourceDeletionStatus,
    );

    _candidates[updateId] = (_candidates[updateId] ?? const <CandidateItem>[])
        .map(
          (candidate) => candidate.status == CandidateState.accepted
              ? _copyCandidate(candidate, status: CandidateState.committed)
              : candidate,
        )
        .toList(growable: false);
    _updates[updateId] = _copyUpdate(
      update,
      state: LearningUpdateState.committed,
      rowVersion: update.rowVersion + 1,
      updatedAt: DateTime.now().toUtc(),
    );
    _commitsByKey[idempotencyKey] = outcome;
    _committedByUpdate[updateId] = outcome;
    return outcome;
  }

  Future<void> _enter(IngestionOperation operation) async {
    operations.add(operation);
    final failure = failures[operation];
    if (failure != null) throw failure;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }

  UpdateSnapshot _requireUpdate(String updateId) {
    final update = _updates[updateId];
    if (update == null) throw _notFound();
    return update;
  }

  Future<PathPreview> _buildPreview(UpdateSnapshot update) async {
    final candidates = _candidates[update.id] ?? const <CandidateItem>[];
    final accepted = candidates
        .where((candidate) => candidate.status == CandidateState.accepted)
        .toList(growable: false);
    final pending = candidates.any(
      (candidate) =>
          candidate.requiresVerification &&
          (candidate.status == CandidateState.candidate ||
              candidate.status == CandidateState.needsVerification),
    );
    final canCommit =
        update.state == LearningUpdateState.verificationRequired &&
        accepted.isNotEmpty &&
        !pending;
    final estimate = accepted.length * 2;
    return PathPreview(
      updateId: update.id,
      state: update.state,
      conceptCount: accepted.length,
      firstConcepts: accepted
          .take(5)
          .map(
            (candidate) => PreviewConcept(
              candidateId: candidate.id,
              title: candidate.displayTitle,
              candidateType: candidate.candidateType,
            ),
          )
          .toList(growable: false),
      estimatedFirstMissionMinutes: accepted.isEmpty
          ? null
          : (estimate < 5 ? 5 : (estimate > 20 ? 20 : estimate)),
      canCommit: canCommit,
      blockedReason: canCommit
          ? null
          : (pending
                ? PreviewBlockReason.verificationPending
                : PreviewBlockReason.noValidConcept),
    );
  }

  List<CandidateItem> _extractCandidates(UpdateSnapshot update) {
    final text = _manualTexts[update.id];
    final titles = <String>[];
    if (text != null) {
      for (final part in text.split(RegExp(r'[\n.!?]+'))) {
        final title = part.trim();
        if (title.length < 4) continue;
        titles.add(title.length > 80 ? title.substring(0, 80) : title);
        if (titles.length >= 8) break;
      }
    }
    if (titles.isEmpty) {
      final count = update.uploads.isEmpty ? 1 : update.uploads.length;
      for (var index = 0; index < count; index++) {
        titles.add('Extracted concept ${index + 1}');
      }
    }

    return <CandidateItem>[
      for (var index = 0; index < titles.length; index++)
        CandidateItem(
          id: generateUuid(),
          candidateType: 'concept',
          displayTitle: titles[index],
          displaySummary: 'Extracted from this learning update.',
          sourceContext: text == null ? 'From your file' : 'From your text',
          confidence: index == 0 ? 0.9 : 0.7,
          band: index == 0 ? ConfidenceBand.high : ConfidenceBand.medium,
          requiresVerification: index != 0,
          status: CandidateState.candidate,
          candidateVersion: 1,
        ),
    ];
  }

  UpdateSnapshot _copyUpdate(
    UpdateSnapshot update, {
    LearningUpdateState? state,
    IngestionFailure? failure,
    bool? hasManualText,
    DateTime? learnedAt,
    DateTime? expiresAt,
    DateTime? updatedAt,
    int? rowVersion,
    SourceDeletionStatus? sourceDeletionStatus,
    List<SourceItem>? uploads,
  }) {
    final nextState = state ?? update.state;
    return UpdateSnapshot(
      id: update.id,
      subjectId: update.subjectId,
      inputType: update.inputType,
      state: nextState,
      failure: nextState == LearningUpdateState.failed
          ? (failure ?? update.failure)
          : null,
      hasManualText: hasManualText ?? update.hasManualText,
      learnedAt: learnedAt ?? update.learnedAt,
      expiresAt: expiresAt ?? update.expiresAt,
      createdAt: update.createdAt,
      updatedAt: updatedAt ?? update.updatedAt,
      rowVersion: rowVersion ?? update.rowVersion,
      sourceDeletionStatus:
          sourceDeletionStatus ?? update.sourceDeletionStatus,
      uploads: uploads ?? update.uploads,
    );
  }

  SourceItem _copySource(
    SourceItem source, {
    SourceUploadState? status,
    SourceDeletionStatus? deletionStatus,
    String? detectedMediaType,
    DateTime? deletedAt,
  }) {
    return SourceItem(
      id: source.id,
      declaredName: source.declaredName,
      declaredMediaType: source.declaredMediaType,
      detectedMediaType: detectedMediaType ?? source.detectedMediaType,
      byteSize: source.byteSize,
      status: status ?? source.status,
      expiresAt: source.expiresAt,
      deletedAt: deletedAt ?? source.deletedAt,
      deletionStatus: deletionStatus ?? source.deletionStatus,
    );
  }

  CandidateItem _copyCandidate(
    CandidateItem candidate, {
    String? displayTitle,
    CandidateState? status,
  }) {
    return CandidateItem(
      id: candidate.id,
      candidateType: candidate.candidateType,
      displayTitle: displayTitle ?? candidate.displayTitle,
      displaySummary: candidate.displaySummary,
      sourceContext: candidate.sourceContext,
      confidence: candidate.confidence,
      band: candidate.band,
      requiresVerification: candidate.requiresVerification,
      status: status ?? candidate.status,
      candidateVersion: candidate.candidateVersion,
    );
  }

  IngestionFailure _notFound() {
    return const IngestionFailure(
      code: 'resource_not_found',
      message: 'The requested item was not found.',
    );
  }

  IngestionFailure _invalidState() {
    return const IngestionFailure(
      code: 'invalid_state',
      message: 'That action is not available right now.',
      nextAction: 'Refresh this material and try again.',
    );
  }

  IngestionFailure _versionConflict() {
    return const IngestionFailure(
      code: 'version_conflict',
      message: 'This information has changed. Please review it again.',
      nextAction: 'Review the latest version and try again.',
    );
  }

  IngestionFailure _validationFailed() {
    return const IngestionFailure(
      code: 'validation_failed',
      message: 'Please check the highlighted details and try again.',
    );
  }
}
