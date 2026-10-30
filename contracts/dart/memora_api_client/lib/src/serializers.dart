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

import 'package:memora_api_client/src/model/account_status.dart';
import 'package:memora_api_client/src/model/active_mission_summary.dart';
import 'package:memora_api_client/src/model/async_operation.dart';
import 'package:memora_api_client/src/model/capability_flags.dart';
import 'package:memora_api_client/src/model/concept_history_response.dart';
import 'package:memora_api_client/src/model/concept_progress_item.dart';
import 'package:memora_api_client/src/model/consent_acceptance_request.dart';
import 'package:memora_api_client/src/model/consent_acceptance_response.dart';
import 'package:memora_api_client/src/model/consent_decision.dart';
import 'package:memora_api_client/src/model/consent_response.dart';
import 'package:memora_api_client/src/model/consent_status.dart';
import 'package:memora_api_client/src/model/consent_type.dart';
import 'package:memora_api_client/src/model/device_registration_request.dart';
import 'package:memora_api_client/src/model/device_registration_response.dart';
import 'package:memora_api_client/src/model/due_reason_explanation.dart';
import 'package:memora_api_client/src/model/error_detail.dart';
import 'package:memora_api_client/src/model/error_envelope.dart';
import 'package:memora_api_client/src/model/evidence_summary.dart';
import 'package:memora_api_client/src/model/field_error.dart';
import 'package:memora_api_client/src/model/health_response.dart';
import 'package:memora_api_client/src/model/health_status.dart';
import 'package:memora_api_client/src/model/idempotency_headers.dart';
import 'package:memora_api_client/src/model/page_concept_progress_item.dart';
import 'package:memora_api_client/src/model/page_meta.dart';
import 'package:memora_api_client/src/model/page_params.dart';
import 'package:memora_api_client/src/model/page_question_report_summary.dart';
import 'package:memora_api_client/src/model/pending_resource_summary.dart';
import 'package:memora_api_client/src/model/profile_summary.dart';
import 'package:memora_api_client/src/model/question_report_create_request.dart';
import 'package:memora_api_client/src/model/question_report_response.dart';
import 'package:memora_api_client/src/model/question_report_summary.dart';
import 'package:memora_api_client/src/model/request_headers.dart';
import 'package:memora_api_client/src/model/scheduling_explanation.dart';
import 'package:memora_api_client/src/model/session_bootstrap_response.dart';
import 'package:memora_api_client/src/model/session_revocation_scope.dart';
import 'package:memora_api_client/src/model/session_revoke_request.dart';
import 'package:memora_api_client/src/model/subject_summary.dart';

part 'serializers.g.dart';

@SerializersFor([
  AccountStatus,
  ActiveMissionSummary,
  AsyncOperation,
  CapabilityFlags,
  ConceptHistoryResponse,
  ConceptProgressItem,
  ConsentAcceptanceRequest,
  ConsentAcceptanceResponse,
  ConsentDecision,
  ConsentResponse,
  ConsentStatus,
  ConsentType,
  DeviceRegistrationRequest,
  DeviceRegistrationResponse,
  DueReasonExplanation,
  ErrorDetail,
  ErrorEnvelope,
  EvidenceSummary,
  FieldError,
  HealthResponse,
  HealthStatus,
  IdempotencyHeaders,
  PageConceptProgressItem,
  PageMeta,
  PageParams,
  PageQuestionReportSummary,
  PendingResourceSummary,
  ProfileSummary,
  QuestionReportCreateRequest,
  QuestionReportResponse,
  QuestionReportSummary,
  RequestHeaders,
  SchedulingExplanation,
  SessionBootstrapResponse,
  SessionRevocationScope,
  SessionRevokeRequest,
  SubjectSummary,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(SubjectSummary)]),
        () => ListBuilder<SubjectSummary>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ConsentStatus)]),
        () => ListBuilder<ConsentStatus>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(FieldError)]),
        () => ListBuilder<FieldError>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PendingResourceSummary)]),
        () => ListBuilder<PendingResourceSummary>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(QuestionReportSummary)]),
        () => ListBuilder<QuestionReportSummary>(),
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
        const FullType(BuiltList, [FullType(ConceptProgressItem)]),
        () => ListBuilder<ConceptProgressItem>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer()))
    .build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
