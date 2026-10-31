//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:memora_api_client/src/date_serializer.dart';
import 'package:memora_api_client/src/model/date.dart';

import 'package:memora_api_client/src/model/accessibility_preferences.dart';
import 'package:memora_api_client/src/model/account_status.dart';
import 'package:memora_api_client/src/model/active_mission_summary.dart';
import 'package:memora_api_client/src/model/async_operation.dart';
import 'package:memora_api_client/src/model/candidate_list_response.dart';
import 'package:memora_api_client/src/model/candidate_response.dart';
import 'package:memora_api_client/src/model/candidate_status.dart';
import 'package:memora_api_client/src/model/capability_flags.dart';
import 'package:memora_api_client/src/model/concept_history_response.dart';
import 'package:memora_api_client/src/model/concept_progress_item.dart';
import 'package:memora_api_client/src/model/consent_acceptance_request.dart';
import 'package:memora_api_client/src/model/consent_acceptance_response.dart';
import 'package:memora_api_client/src/model/consent_decision.dart';
import 'package:memora_api_client/src/model/consent_response.dart';
import 'package:memora_api_client/src/model/consent_status.dart';
import 'package:memora_api_client/src/model/consent_type.dart';
import 'package:memora_api_client/src/model/create_learning_update_request.dart';
import 'package:memora_api_client/src/model/declared_file.dart';
import 'package:memora_api_client/src/model/deletion_proof_summary.dart';
import 'package:memora_api_client/src/model/deletion_status.dart';
import 'package:memora_api_client/src/model/device_registration_request.dart';
import 'package:memora_api_client/src/model/device_registration_response.dart';
import 'package:memora_api_client/src/model/due_reason_explanation.dart';
import 'package:memora_api_client/src/model/error_detail.dart';
import 'package:memora_api_client/src/model/error_envelope.dart';
import 'package:memora_api_client/src/model/evidence_summary.dart';
import 'package:memora_api_client/src/model/field_error.dart';
import 'package:memora_api_client/src/model/finalize_upload_request.dart';
import 'package:memora_api_client/src/model/first_mission_summary.dart';
import 'package:memora_api_client/src/model/health_response.dart';
import 'package:memora_api_client/src/model/health_status.dart';
import 'package:memora_api_client/src/model/idempotency_headers.dart';
import 'package:memora_api_client/src/model/input_type.dart';
import 'package:memora_api_client/src/model/knowledge_commit_response.dart';
import 'package:memora_api_client/src/model/learning_path_preview_concept.dart';
import 'package:memora_api_client/src/model/learning_path_preview_response.dart';
import 'package:memora_api_client/src/model/learning_update_list_response.dart';
import 'package:memora_api_client/src/model/learning_update_response.dart';
import 'package:memora_api_client/src/model/learning_update_status.dart';
import 'package:memora_api_client/src/model/page_concept_progress_item.dart';
import 'package:memora_api_client/src/model/page_meta.dart';
import 'package:memora_api_client/src/model/page_params.dart';
import 'package:memora_api_client/src/model/page_question_report_summary.dart';
import 'package:memora_api_client/src/model/pending_resource_summary.dart';
import 'package:memora_api_client/src/model/privacy_deletion_cancel_request.dart';
import 'package:memora_api_client/src/model/privacy_deletion_request.dart';
import 'package:memora_api_client/src/model/privacy_deletion_response.dart';
import 'package:memora_api_client/src/model/privacy_export_request.dart';
import 'package:memora_api_client/src/model/privacy_export_response.dart';
import 'package:memora_api_client/src/model/profile_preferences_response.dart';
import 'package:memora_api_client/src/model/profile_preferences_update_request.dart';
import 'package:memora_api_client/src/model/profile_response.dart';
import 'package:memora_api_client/src/model/profile_summary.dart';
import 'package:memora_api_client/src/model/profile_update_request.dart';
import 'package:memora_api_client/src/model/question_report_create_request.dart';
import 'package:memora_api_client/src/model/question_report_response.dart';
import 'package:memora_api_client/src/model/question_report_summary.dart';
import 'package:memora_api_client/src/model/request_headers.dart';
import 'package:memora_api_client/src/model/retry_learning_update_request.dart';
import 'package:memora_api_client/src/model/scheduling_explanation.dart';
import 'package:memora_api_client/src/model/session_bootstrap_response.dart';
import 'package:memora_api_client/src/model/session_revocation_scope.dart';
import 'package:memora_api_client/src/model/session_revoke_request.dart';
import 'package:memora_api_client/src/model/source_upload_summary.dart';
import 'package:memora_api_client/src/model/subject_summary.dart';
import 'package:memora_api_client/src/model/submit_verification_decisions_request.dart';
import 'package:memora_api_client/src/model/submit_verification_decisions_response.dart';
import 'package:memora_api_client/src/model/update_learning_update_request.dart';
import 'package:memora_api_client/src/model/upload_grant_request.dart';
import 'package:memora_api_client/src/model/upload_grant_response.dart';
import 'package:memora_api_client/src/model/upload_status.dart';
import 'package:memora_api_client/src/model/verification_decision.dart';
import 'package:memora_api_client/src/model/verification_decision_result.dart';
import 'package:memora_api_client/src/model/verification_decision_value.dart';

part 'serializers.g.dart';

@SerializersFor([
  AccessibilityPreferences,
  AccountStatus,
  ActiveMissionSummary,
  AsyncOperation,
  CandidateListResponse,
  CandidateResponse,
  CandidateStatus,
  CapabilityFlags,
  ConceptHistoryResponse,
  ConceptProgressItem,
  ConsentAcceptanceRequest,
  ConsentAcceptanceResponse,
  ConsentDecision,
  ConsentResponse,
  ConsentStatus,
  ConsentType,
  CreateLearningUpdateRequest,
  DeclaredFile,
  DeletionProofSummary,
  DeletionStatus,
  DeviceRegistrationRequest,
  DeviceRegistrationResponse,
  DueReasonExplanation,
  ErrorDetail,
  ErrorEnvelope,
  EvidenceSummary,
  FieldError,
  FinalizeUploadRequest,
  FirstMissionSummary,
  HealthResponse,
  HealthStatus,
  IdempotencyHeaders,
  InputType,
  KnowledgeCommitResponse,
  LearningPathPreviewConcept,
  LearningPathPreviewResponse,
  LearningUpdateListResponse,
  LearningUpdateResponse,
  LearningUpdateStatus,
  PageConceptProgressItem,
  PageMeta,
  PageParams,
  PageQuestionReportSummary,
  PendingResourceSummary,
  PrivacyDeletionCancelRequest,
  PrivacyDeletionRequest,
  PrivacyDeletionResponse,
  PrivacyExportRequest,
  PrivacyExportResponse,
  ProfilePreferencesResponse,
  ProfilePreferencesUpdateRequest,
  ProfileResponse,
  ProfileSummary,
  ProfileUpdateRequest,
  QuestionReportCreateRequest,
  QuestionReportResponse,
  QuestionReportSummary,
  RequestHeaders,
  RetryLearningUpdateRequest,
  SchedulingExplanation,
  SessionBootstrapResponse,
  SessionRevocationScope,
  SessionRevokeRequest,
  SourceUploadSummary,
  SubjectSummary,
  SubmitVerificationDecisionsRequest,
  SubmitVerificationDecisionsResponse,
  UpdateLearningUpdateRequest,
  UploadGrantRequest,
  UploadGrantResponse,
  UploadStatus,
  VerificationDecision,
  VerificationDecisionResult,
  VerificationDecisionValue,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(SubjectSummary)]),
        () => ListBuilder<SubjectSummary>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltMap, [FullType(String), FullType(String)]),
        () => MapBuilder<String, String>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(FieldError)]),
        () => ListBuilder<FieldError>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(LearningUpdateResponse)]),
        () => ListBuilder<LearningUpdateResponse>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(QuestionReportSummary)]),
        () => ListBuilder<QuestionReportSummary>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(VerificationDecision)]),
        () => ListBuilder<VerificationDecision>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(DeclaredFile)]),
        () => ListBuilder<DeclaredFile>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(LearningPathPreviewConcept)]),
        () => ListBuilder<LearningPathPreviewConcept>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(DeletionProofSummary)]),
        () => ListBuilder<DeletionProofSummary>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ConsentStatus)]),
        () => ListBuilder<ConsentStatus>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(VerificationDecisionResult)]),
        () => ListBuilder<VerificationDecisionResult>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PendingResourceSummary)]),
        () => ListBuilder<PendingResourceSummary>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(CandidateResponse)]),
        () => ListBuilder<CandidateResponse>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
        () => MapBuilder<String, JsonObject?>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltMap, [FullType(String), FullType(int)]),
        () => MapBuilder<String, int>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(SchedulingExplanation)]),
        () => ListBuilder<SchedulingExplanation>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(String)]),
        () => ListBuilder<String>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(SourceUploadSummary)]),
        () => ListBuilder<SourceUploadSummary>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ConceptProgressItem)]),
        () => ListBuilder<ConceptProgressItem>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer())
    ).build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
