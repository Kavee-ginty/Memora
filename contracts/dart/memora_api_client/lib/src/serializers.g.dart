// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers = (Serializers().toBuilder()
      ..add(AccountStatus.serializer)
      ..add(ActiveMissionSummary.serializer)
      ..add(ActiveMissionSummaryStatusEnum.serializer)
      ..add(AsyncOperation.serializer)
      ..add(CandidateListResponse.serializer)
      ..add(CandidateResponse.serializer)
      ..add(CandidateResponseConfidenceBandEnum.serializer)
      ..add(CandidateStatus.serializer)
      ..add(CapabilityFlags.serializer)
      ..add(ConceptHistoryResponse.serializer)
      ..add(ConceptHistoryResponseStateBandEnum.serializer)
      ..add(ConceptProgressItem.serializer)
      ..add(ConceptProgressItemConfidenceBandEnum.serializer)
      ..add(ConceptProgressItemReviewWindowEnum.serializer)
      ..add(ConceptProgressItemStateBandEnum.serializer)
      ..add(ConsentAcceptanceRequest.serializer)
      ..add(ConsentAcceptanceResponse.serializer)
      ..add(ConsentDecision.serializer)
      ..add(ConsentResponse.serializer)
      ..add(ConsentStatus.serializer)
      ..add(ConsentType.serializer)
      ..add(CreateLearningUpdateRequest.serializer)
      ..add(DeclaredFile.serializer)
      ..add(DeletionStatus.serializer)
      ..add(DeviceRegistrationRequest.serializer)
      ..add(DeviceRegistrationRequestPlatformEnum.serializer)
      ..add(DeviceRegistrationResponse.serializer)
      ..add(DeviceRegistrationResponsePlatformEnum.serializer)
      ..add(DueReasonExplanation.serializer)
      ..add(DueReasonExplanationReasonCodeEnum.serializer)
      ..add(DueReasonExplanationTemplateKeyEnum.serializer)
      ..add(ErrorDetail.serializer)
      ..add(ErrorEnvelope.serializer)
      ..add(EvidenceSummary.serializer)
      ..add(EvidenceSummaryConfidenceBandEnum.serializer)
      ..add(FieldError.serializer)
      ..add(FinalizeUploadRequest.serializer)
      ..add(FirstMissionSummary.serializer)
      ..add(HealthResponse.serializer)
      ..add(HealthStatus.serializer)
      ..add(IdempotencyHeaders.serializer)
      ..add(InputType.serializer)
      ..add(KnowledgeCommitResponse.serializer)
      ..add(LearningPathPreviewConcept.serializer)
      ..add(LearningPathPreviewResponse.serializer)
      ..add(LearningUpdateListResponse.serializer)
      ..add(LearningUpdateResponse.serializer)
      ..add(LearningUpdateStatus.serializer)
      ..add(PageConceptProgressItem.serializer)
      ..add(PageMeta.serializer)
      ..add(PageParams.serializer)
      ..add(PageQuestionReportSummary.serializer)
      ..add(PendingResourceSummary.serializer)
      ..add(ProfileSummary.serializer)
      ..add(QuestionReportCreateRequest.serializer)
      ..add(QuestionReportCreateRequestReportTypeEnum.serializer)
      ..add(QuestionReportResponse.serializer)
      ..add(QuestionReportResponseEvidenceStateEnum.serializer)
      ..add(QuestionReportResponseReportTypeEnum.serializer)
      ..add(QuestionReportResponseStatusEnum.serializer)
      ..add(QuestionReportSummary.serializer)
      ..add(QuestionReportSummaryEvidenceStateEnum.serializer)
      ..add(QuestionReportSummaryReportTypeEnum.serializer)
      ..add(QuestionReportSummaryStatusEnum.serializer)
      ..add(RequestHeaders.serializer)
      ..add(RequestHeadersXPlatformEnum.serializer)
      ..add(RetryLearningUpdateRequest.serializer)
      ..add(RetryLearningUpdateRequestStageEnum.serializer)
      ..add(SchedulingExplanation.serializer)
      ..add(SchedulingExplanationReasonCodesEnum.serializer)
      ..add(SchedulingExplanationTemplateKeyEnum.serializer)
      ..add(SchedulingExplanationTriggerEventTypeEnum.serializer)
      ..add(SessionBootstrapResponse.serializer)
      ..add(SessionRevocationScope.serializer)
      ..add(SessionRevokeRequest.serializer)
      ..add(SourceUploadSummary.serializer)
      ..add(SubjectSummary.serializer)
      ..add(SubmitVerificationDecisionsRequest.serializer)
      ..add(SubmitVerificationDecisionsResponse.serializer)
      ..add(UpdateLearningUpdateRequest.serializer)
      ..add(UploadGrantRequest.serializer)
      ..add(UploadGrantResponse.serializer)
      ..add(UploadGrantResponseMethodEnum.serializer)
      ..add(UploadStatus.serializer)
      ..add(VerificationDecision.serializer)
      ..add(VerificationDecisionResult.serializer)
      ..add(VerificationDecisionValue.serializer)
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(CandidateResponse)]),
          () => ListBuilder<CandidateResponse>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(ConceptProgressItem)]),
          () => ListBuilder<ConceptProgressItem>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(ConsentStatus)]),
          () => ListBuilder<ConsentStatus>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(ConsentStatus)]),
          () => ListBuilder<ConsentStatus>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(PendingResourceSummary)]),
          () => ListBuilder<PendingResourceSummary>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(PendingResourceSummary)]),
          () => ListBuilder<PendingResourceSummary>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(SubjectSummary)]),
          () => ListBuilder<SubjectSummary>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(DeclaredFile)]),
          () => ListBuilder<DeclaredFile>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(FieldError)]),
          () => ListBuilder<FieldError>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(LearningPathPreviewConcept)]),
          () => ListBuilder<LearningPathPreviewConcept>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(LearningUpdateResponse)]),
          () => ListBuilder<LearningUpdateResponse>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(QuestionReportSummary)]),
          () => ListBuilder<QuestionReportSummary>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(SchedulingExplanation)]),
          () => ListBuilder<SchedulingExplanation>())
      ..addBuilderFactory(
          const FullType(BuiltList,
              const [const FullType(SchedulingExplanationReasonCodesEnum)]),
          () => ListBuilder<SchedulingExplanationReasonCodesEnum>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(SourceUploadSummary)]),
          () => ListBuilder<SourceUploadSummary>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(VerificationDecision)]),
          () => ListBuilder<VerificationDecision>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(VerificationDecisionResult)]),
          () => ListBuilder<VerificationDecisionResult>())
      ..addBuilderFactory(
          const FullType(
              BuiltMap, const [const FullType(String), const FullType(String)]),
          () => MapBuilder<String, String>())
      ..addBuilderFactory(
          const FullType(
              BuiltMap, const [const FullType(String), const FullType(int)]),
          () => MapBuilder<String, int>())
      ..addBuilderFactory(
          const FullType(
              BuiltMap, const [const FullType(String), const FullType(int)]),
          () => MapBuilder<String, int>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(LearningPathPreviewConcept)]),
          () => ListBuilder<LearningPathPreviewConcept>())
      ..addBuilderFactory(
          const FullType(BuiltMap, const [
            const FullType(String),
            const FullType.nullable(JsonObject)
          ]),
          () => MapBuilder<String, JsonObject?>())
      ..addBuilderFactory(
          const FullType(BuiltMap, const [
            const FullType(String),
            const FullType.nullable(JsonObject)
          ]),
          () => MapBuilder<String, JsonObject?>()))
    .build();

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
