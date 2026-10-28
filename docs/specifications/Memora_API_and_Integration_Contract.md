# Memora API and Integration Contract

**Document 6 of 6**  
**Status:** Canonical implementation specification  
**Version:** 1.0  
**Prepared:** 22 October 2026  
**Audience:** Mobile, backend, data, security, QA and AI coding agents  
**Applies to:** Student-first Sri Lankan GCE Advanced Level Physics MVP  
**Related documents:** `./Memora_PRD.md`, `./Memora_TRD.md`, `./Memora_UI_UX_Design_Specification.md`, `./Memora_Backend_Schema_and_Data_Model.md` and `./Memora_App_Flow_and_Screen_State_Specification.md`

## 1 Purpose and authority

This document defines the versioned HTTP contract between the Memora Flutter application, FastAPI backend, temporary object storage and notification/deep-link integrations. It names the MVP endpoints, request and response shapes, authorization rules, idempotency behavior, failure semantics and contract-test gates.

The PRD governs product behavior. The TRD governs architecture. The backend schema governs durable integrity. The app-flow specification governs client transitions. This document is authoritative for externally visible API behavior. Generated OpenAPI must match it, and deployed behavior must match generated OpenAPI.

### 1.1 Required outcome

An implementation is conformant when a typed client can be generated from OpenAPI, all private resources are owner-scoped by the server, retries cannot duplicate learning evidence or rewards, errors are safe and actionable, and every mobile flow has a complete API path.

### 1.2 Non-goals

This contract does not expose internal repository models, worker queues, model prompts, hidden candidate pools, answer keys before submission, administrative review APIs or provider-specific identity internals.

## 2 API principles

### API-001 Server-derived identity

The authenticated user and roles come only from a validated access token. Student request bodies never contain `user_id` as authorization evidence.

### API-002 Explicit versioning

All student endpoints use `/v1`. Breaking semantic or structural changes require a new major path. Additive optional fields are allowed only when old clients can ignore them safely.

### API-003 Idempotent mutations

Any mutation that may be retried accepts `Idempotency-Key` or a documented stable `client_operation_id`. Reuse with the same normalized request returns the original logical result. Reuse with a different request hash returns `409 idempotency_key_reused`.

### API-004 Safe bounded responses

Collections use cursor pagination and documented maximum sizes. The API never returns hidden answer keys, raw model reasoning, secrets, unrelated private data or unbounded graph traversals.

### API-005 Authoritative state

The backend owns mission selection, grading, memory schedules, XP, streaks, reef projections, consent status and deletion completion. Client timestamps are evidence only.

### API-006 Traceable failures

Every failure returns a stable safe code and request ID. Validation errors point to fields. Retry guidance is machine-readable. Internal exceptions and provider payloads are never returned.

### API-007 Minimum sensitive transfer

Endpoints receive and return only the content required for the action. Learning text, answers and source excerpts are excluded from URLs, analytics fields and normal logs.

## 3 Transport representation and compatibility

| Concern | Contract |
| --- | --- |
| Transport | HTTPS using TLS 1.2 or later |
| Base path | `/v1` |
| Media type | `application/json; charset=utf-8` |
| Upload bytes | Direct signed HTTPS request to temporary object storage |
| Field naming | `snake_case` |
| Identifiers | Opaque UUID strings; never ordered by UUID value |
| Time | ISO 8601 UTC with `Z`; server timestamps authoritative |
| Dates | ISO 8601 calendar date in the user's resolved timezone context |
| Numbers | JSON numbers; decimal meaning documented per field |
| Null | Used only where absence is meaningful; omitted optional fields remain distinct |
| Unknown enum | Client shows safe neutral fallback and records telemetry |

Requests larger than the endpoint limit return `413 payload_too_large`. Unsupported media types return `415 unsupported_media_type`. JSON bodies with unknown required semantics fail validation; additive unknown response fields must be ignored by clients.

## 4 Authentication authorization and request context

### 4.1 Authentication

Authenticated calls use `Authorization: Bearer <access_token>`. Tokens are issued by the approved OIDC provider, are short-lived and are validated for signature, issuer, audience, expiry and required claims. Refresh material never reaches the Memora API request body.

### 4.2 Authorization

The API loads each private resource through an owner-scoped query. A random identifier does not grant access. To avoid leaking resource existence, a resource absent from the authorized scope normally returns `404 resource_not_found`. Privileged academic or operational APIs use separate roles and are outside this student contract.

### 4.3 Recent authentication

Export, account deletion, sensitive profile changes and session revocation may require a provider-issued recent-authentication claim. Failure returns `403 recent_authentication_required` with a safe reauthentication action.

### 4.4 Required request headers

| Header | Required | Rule |
| --- | --- | --- |
| `Authorization` | Authenticated endpoints | OIDC bearer token |
| `X-Correlation-ID` | Yes | Client UUID; server generates one when invalid or absent |
| `Idempotency-Key` | Documented mutations | UUID or high-entropy opaque value |
| `X-Client-Version` | Yes | Released application version |
| `X-Platform` | Yes | `android` or `ios` |
| `Accept-Language` | Optional | BCP 47 language preference |
| `If-None-Match` | Optional reads | ETag cache validation |

The server echoes the effective correlation identifier in `X-Correlation-ID` and returns a distinct `X-Request-ID` for support and tracing.

## 5 Common response contracts

### 5.1 Single-resource response

Successful resource reads return the resource directly rather than wrapping it in a generic `data` property. Stable metadata needed for interpretation belongs in the resource schema.

### 5.2 Collection response

| Field | Type | Rule |
| --- | --- | --- |
| `items` | array | Ordered by the endpoint's documented stable order |
| `next_cursor` | string or null | Opaque; null when complete |
| `has_more` | boolean | Consistent with `next_cursor` |

Clients pass `cursor` and optional `limit`. Default limit is endpoint-specific and never exceeds 100. Invalid or expired cursors return `400 invalid_cursor`. Cursors cannot be edited or used across users, endpoints or materially different filters.

### 5.3 Async operation reference

Long-running workflows return:

| Field | Type | Meaning |
| --- | --- | --- |
| `resource_id` | uuid | Durable business resource |
| `status` | enum | Current public workflow state |
| `status_url` | path | Authorized polling endpoint |
| `retry_after_seconds` | integer or null | Earliest useful poll |
| `updated_at` | timestamp | Server state-change time |

### 5.4 Successful mutation status codes

| Status | Use |
| --- | --- |
| `200 OK` | Existing resource updated or idempotent result replayed |
| `201 Created` | New durable resource created |
| `202 Accepted` | Durable async workflow accepted |
| `204 No Content` | Successful action with no response representation |

## 6 Error contract

All non-2xx JSON errors use this shape:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Check the highlighted fields and try again.",
    "request_id": "01J...",
    "field_errors": [
      {"field": "preferred_time", "code": "invalid_time", "message": "Enter a valid local time."}
    ],
    "retryable": false,
    "retry_after_seconds": null,
    "action": "correct_input"
  }
}
```

| HTTP | Stable code examples | Client behavior |
| --- | --- | --- |
| 400 | invalid_cursor, invalid_state, malformed_request | Correct request or refresh state |
| 401 | token_missing, token_invalid, token_expired | Refresh once, then sign in |
| 403 | consent_required, recent_authentication_required, operation_not_allowed | Complete named recovery action |
| 404 | resource_not_found | Return to stable parent |
| 409 | version_conflict, idempotency_key_reused, mission_state_changed | Refresh authoritative resource |
| 413 | payload_too_large | Reduce source or choose another method |
| 415 | unsupported_media_type | Choose supported type |
| 422 | validation_failed | Display field errors |
| 429 | rate_limited | Respect `Retry-After` |
| 503 | temporarily_unavailable | Preserve context and retry safely |

`message` is safe for direct display but may be replaced by approved localized copy keyed by `code`. Clients branch on `code`, never on message text.

## 7 Idempotency concurrency and caching

### 7.1 Idempotency

Keys are scoped to the authenticated principal and operation. The server stores the request hash and logical result for at least the documented retry window. Concurrent identical requests converge on one result. An in-progress duplicate may return `409 operation_in_progress` with retry guidance or wait for the first result within the request deadline.

### 7.2 Optimistic concurrency

Editable resources expose a `version` integer or strong `ETag`. Updates send the documented version or `If-Match`. A stale update returns `409 version_conflict` with the current safe representation or a URL to refresh.

### 7.3 Caching

Private responses use `Cache-Control: private, no-store` unless a specifically reviewed short-lived cache policy exists. ETags may reduce transfer but do not permit shared caching. Question payloads and source excerpts are never cached by intermediaries.

## 8 Session bootstrap and devices

| Method and path | Purpose | Success | Idempotency |
| --- | --- | --- | --- |
| `GET /v1/session/bootstrap` | Resolve account, consent, subject, active mission and pending state | 200 | Read |
| `POST /v1/session/revoke` | Revoke current or selected session | 204 | Required |
| `POST /v1/devices` | Register or refresh notification device | 200 or 201 | Required |
| `DELETE /v1/devices/{device_id}` | Remove device registration | 204 | Naturally idempotent |

Bootstrap returns `profile_summary`, `account_status`, `consent_status`, `subjects`, `active_mission`, `pending_learning_updates`, `pending_privacy_requests`, `server_time` and capability flags. It excludes full mission questions and learning content.

Device registration accepts platform, push token, token fingerprint metadata, locale, timezone and app version. A push token is encrypted at rest and never returned in full.

## 9 Profile consent and preferences

| Method and path | Purpose | Notes |
| --- | --- | --- |
| `GET /v1/profile` | Current profile and preference summary | Private no-store |
| `PATCH /v1/profile` | Update allowed profile fields | Version required |
| `GET /v1/profile/preferences` | Notification, accessibility and mission settings | Returns confirmed server values |
| `PATCH /v1/profile/preferences` | Update allowed settings | Idempotency and version required |
| `GET /v1/consent` | Current required and accepted policies | No policy text hidden in client constants |
| `POST /v1/consent/acceptances` | Record an acceptance | Idempotency required |

Preference patches use explicit fields; omission means unchanged. Null clears only fields documented as nullable. Consent acceptance includes policy identifier, version and accepted scopes. The server determines whether the policy is current and whether guardian or age rules apply.

## 10 Home subjects and learning paths

| Method and path | Purpose |
| --- | --- |
| `GET /v1/home` | Daily Mission hero, reef summary and next actions |
| `GET /v1/subjects` | Authorized subjects and curriculum identifiers |
| `GET /v1/subjects/{subject_id}` | Subject summary and settings |
| `GET /v1/subjects/{subject_id}/learning-path` | Ordered accessible learning-path projection |
| `GET /v1/subjects/{subject_id}/concept-progress` | Paginated concept progress and due reasons |
| `GET /v1/concepts/{concept_id}/history` | Authorized evidence summary and scheduling explanations |

Home returns authoritative card states: `setup`, `mission_ready`, `mission_in_progress`, `mission_complete` or `cared_for`. The client must not synthesize the state from separate counters. Learning-path nodes include stable ID, label, state, order, accessible reason and permitted action; they do not expose hidden candidate scores.

## 11 Learning updates and temporary uploads

### 11.1 Endpoint inventory

| Method and path | Purpose | Success | Idempotency |
| --- | --- | --- | --- |
| `POST /v1/learning-updates` | Create text or upload-backed update | 201 | Required |
| `GET /v1/learning-updates` | List user's updates | 200 | Read |
| `GET /v1/learning-updates/{update_id}` | Read processing and deletion status | 200 | Read |
| `PATCH /v1/learning-updates/{update_id}` | Edit eligible draft metadata/text | 200 | Version required |
| `DELETE /v1/learning-updates/{update_id}` | Discard eligible draft or cancel workflow | 202 or 204 | Required |
| `POST /v1/learning-updates/{update_id}/uploads` | Request signed upload grant | 201 | Required |
| `POST /v1/learning-updates/{update_id}/uploads/{upload_id}/finalize` | Verify object and queue processing | 202 | Required |
| `POST /v1/learning-updates/{update_id}/retry` | Retry eligible failed stage | 202 | Required |

Create accepts `subject_id`, `source_type`, `learned_at`, optional bounded `manual_text` and declared file metadata. It returns the update and, for file sources, enough information to request an upload grant. Raw file bytes never pass through the API service.

### 11.2 Signed upload grant

The grant response contains `upload_id`, HTTPS URL, allowed method, exact required headers, maximum byte size, expiry and object checksum rule. The URL is single-purpose, short-lived and bound to the authorized update. It never permits list, overwrite of another object or arbitrary content type.

Finalize accepts observed size, checksum and client operation ID. The server independently verifies object identity, size, type and scanning status. A successful response returns `202` with update status `processing` and polling guidance.

### 11.3 Public update states

`draft`, `uploading`, `processing`, `verification_required`, `committed`, `failed`, `expired` and `deleted` match the backend data contract. Failure responses include only a safe `failure_code`, retry eligibility and next action. Source deletion status is separate from retained knowledge status.

## 12 Extraction verification and learning-path commit

| Method and path | Purpose | Success |
| --- | --- | --- |
| `GET /v1/learning-updates/{update_id}/candidates` | Paginated authorized candidates | 200 |
| `POST /v1/learning-updates/{update_id}/verification-decisions` | Submit accept, edit, reject or merge decisions | 200 |
| `GET /v1/learning-updates/{update_id}/preview` | Preview validated learning path | 200 |
| `POST /v1/learning-updates/{update_id}/commit` | Commit accepted knowledge and exposure | 200 or 201 |

Candidate responses contain candidate ID, type, normalized display fields, confidence band, `requires_verification`, bounded source context and version. They never claim model confidence is calibrated probability.

Decision submission accepts an array of candidate-version decisions. Each decision is `accept`, `edit`, `reject` or `merge`, with corrected structured payload only where allowed. The whole request validates ownership and versions before any terminal decision is written. A stale candidate returns `409 version_conflict`.

Commit is idempotent. It returns concept mappings, private retained items where applicable, first-mission summary, deletion status and authoritative update state. Replaying commit never duplicates exposure, memory events or missions.

## 13 Missions questions and answers

### 13.1 Mission endpoints

| Method and path | Purpose | Success | Idempotency |
| --- | --- | --- | --- |
| `GET /v1/missions/today` | Current bounded Daily Mission summary | 200 | Read |
| `GET /v1/missions/{mission_id}` | Mission preview, state and current item pointer | 200 | Read |
| `POST /v1/missions/{mission_id}/start` | Pin content and start or resume | 200 | Required |
| `GET /v1/missions/{mission_id}/items/{item_id}` | Authorized current item payload | 200 | Read |
| `POST /v1/missions/{mission_id}/items/{item_id}/attempts` | Submit one answer envelope | 200 or 202 | `client_operation_id` |
| `POST /v1/missions/{mission_id}/items/{item_id}/skip` | Record a permitted skip | 200 | Required |
| `POST /v1/missions/{mission_id}/pause` | Pause an active mission | 200 | Required |
| `POST /v1/missions/{mission_id}/complete` | Complete from persisted eligible items | 200 | Required |
| `GET /v1/missions/{mission_id}/results` | Read stable completion results | 200 | Read |

Today returns either a mission summary or the explicit no-due state. `start` returns a bounded mission manifest with item IDs, item positions, question format metadata required for offline continuation and current progress. It excludes correct responses, grading rubrics and future items beyond the approved offline boundary.

### 13.2 Question payload

| Field | Rule |
| --- | --- |
| `question_version_id` | Immutable version pinned to the mission item |
| `question_type` | `single_choice`, `multiple_choice`, `numeric` or `short_answer` when enabled |
| `prompt` | Display text; no embedded executable markup |
| `media` | Authorized short-lived references plus accessibility text |
| `options` | Stable option keys and display content; no correctness flag |
| `response_config` | Input shape, unit affordance and public constraints |
| `trust_label` | Approved source class shown to student where required |
| `due_reason` | Plain-language authorized explanation |

### 13.3 Answer submission

```json
{
  "client_operation_id": "2cd3a72d-3c93-4df4-9b27-78ca08e3cce8",
  "question_version_id": "6fd0c54f-8538-4e0a-8867-b094d7768e69",
  "response": {"type": "single_choice", "option_keys": ["b"]},
  "answered_at": "2026-10-22T12:30:00Z",
  "offline_submission": false
}
```

The server verifies mission ownership, current item eligibility, question version and response schema. Client time never decides lateness or reward. An accepted but asynchronously graded answer returns `202` with attempt ID and status URL. A duplicate operation returns the same attempt and result.

### 13.4 Grading response

The public result includes `attempt_id`, `grading_status`, outcome `recalled`, `partial`, `uncertain`, `weak` or `skipped`, concise feedback, optional explanation availability, repair action, influence limit when confidence is low and the next permitted route. It never returns hidden chain-of-thought or unrestricted rubric internals.

### 13.5 Completion response

Completion returns mission status, protected and repaired counts, XP delta and balance, streak state, reef before/after descriptors, stable reward grants and next suggested action. All fields come from persisted authoritative state. Replaying the request returns the same logical result without another ledger entry.

## 14 Progress seabed rewards and history

| Method and path | Purpose |
| --- | --- |
| `GET /v1/seabed` | Current continuous-seabed projection and subject reefs |
| `GET /v1/seabed/reefs/{subject_id}` | Reef detail and permitted actions |
| `GET /v1/progress/statistics` | Student-readable aggregate statistics |
| `GET /v1/rewards` | Permanent reward inventory and placement state |
| `PATCH /v1/rewards/{reward_grant_id}` | Change permitted cosmetic placement |

Reef condition is exactly `new`, `thriving`, `healthy`, `needs_care` or `dormant`. Responses include projection version, source watermark and projected time. Clients do not combine queued answers with a cached projection. Reward placement changes cannot affect learning priority.

Statistics use an explicit period and timezone context. Charts receive accessible summary text and bounded series. The API does not describe model estimates as measured brain activity.

## 15 Reports disputes and corrections

| Method and path | Purpose | Success |
| --- | --- | --- |
| `POST /v1/questions/{question_version_id}/reports` | Report question, answer, explanation, grading or accessibility problem | 201 |
| `GET /v1/question-reports` | List the student's reports | 200 |
| `GET /v1/question-reports/{report_id}` | Read status and safe resolution | 200 |

Create accepts report type, bounded student description, related attempt ID when applicable and the `Idempotency-Key` header. It never edits the historical question or grading result in place. The response confirms submission and explains whether the disputed evidence is limited pending review. Reviewer identity and internal notes are not exposed.

## 16 Notification integration

### 16.1 Preferences and registration

Notification settings are managed through profile preferences; device tokens use `/v1/devices`. The server enforces quiet hours, frequency caps, category choice and lock-screen preview detail.

### 16.2 Push payload

Push payloads contain only a notification category, opaque resource identifier, route intent, expiry and localization key with safe parameters. They do not contain note text, answers, misconception details or access tokens. The app validates the referenced resource through the API before navigation.

### 16.3 Status delivery

Polling is the baseline MVP mechanism for ingestion and privacy workflows. Push may signal that state changed but is not authoritative. The client always reads the status endpoint. Server-sent events or WebSockets require a later approved contract and are not required.

## 17 Privacy export and account deletion

| Method and path | Purpose | Success |
| --- | --- | --- |
| `POST /v1/privacy/exports` | Begin one export workflow | 202 |
| `GET /v1/privacy/exports/{request_id}` | Read export status and expiry | 200 |
| `POST /v1/privacy/deletions` | Begin verified account deletion | 202 |
| `GET /v1/privacy/deletions/{request_id}` | Read deletion status | 200 |
| `POST /v1/privacy/deletions/{request_id}/cancel` | Cancel only when server permits | 200 |

Both create endpoints require recent authentication and idempotency. Export download uses a short-lived, single-purpose URL after authorization; the API does not stream the archive through normal JSON. Deletion states are `requested`, `verifying`, `processing`, `completed`, `failed` or `cancelled`. The app cannot infer completion from sign-out or missing rows.

Status responses state any approved retention exception without exposing security-sensitive detail. A completed deletion response contains proof reference and completion time, not deleted content.

## 18 Retry timeouts and rate limits

### 18.1 Client retry rules

| Request class | Automatic retry |
| --- | --- |
| Idempotent read | Network failure, selected 502/503/504, exponential backoff with jitter |
| Idempotent mutation | Only with the same idempotency key and unchanged body |
| Answer submission | Same `client_operation_id` until acknowledged |
| Validation, auth or permission error | Never without completing the required recovery |
| Rate limit | Only after `Retry-After` |

The mobile client uses bounded deadlines and never retries indefinitely. A response timeout after a mutation is an unknown outcome, so the client resolves using the operation identity or resource status rather than sending a new logical operation.

### 18.2 Rate limiting

Limits apply by authenticated principal, IP risk and operation cost. Responses use `429`, `Retry-After` and safe limit category. Sensitive exact abuse thresholds need not be public OpenAPI descriptions. Upload grants, model-backed ingestion, reports, exports and deletion have tighter quotas than reads.

## 19 Security and privacy requirements

- Validate every body, path parameter, query parameter and uploaded object's declared and detected type.
- Apply strict upload size, decompression, page and processing-time limits.
- Treat uploaded text as untrusted data; it cannot change system or tool authority.
- Never log authorization headers, signed URLs, source text, answer text, push tokens or provider responses.
- Redact field values from validation telemetry unless allowlisted as non-sensitive.
- Return CORS headers only for approved web origins if a web client is introduced.
- Use short-lived signed media URLs bound to scope and purpose.
- Audit consent, export, deletion, session revocation and privileged review actions.
- Apply row ownership in service authorization and database defense in depth.
- Reject mass-assignment fields not explicitly writable.

## 20 OpenAPI source of truth

FastAPI generates OpenAPI from typed request, response and error models, but generated output is committed or published as a reviewed artifact. Every operation defines:

- Stable `operationId` suitable for Dart client generation.
- Summary and behavior, including authorization and idempotency.
- Complete request and success schemas.
- Shared error schemas and documented status codes.
- Enum values, formats, bounds and nullability.
- Safe examples using synthetic identifiers and content.
- Deprecation metadata and replacement operation when applicable.

CI fails when the generated schema differs from the reviewed schema artifact, contains an undocumented operation, exposes an internal model or removes a compatible field without a major-version decision.

## 21 Client generation and integration boundaries

The Flutter client is generated from the reviewed OpenAPI schema, then wrapped by small feature repositories that map transport DTOs to domain state. Screens and Riverpod providers do not construct URLs or parse raw error JSON.

Generated code is not manually edited. A schema change regenerates the client and runs compile, serialization and contract tests. Date/time, decimal, union and nullable handling receive explicit tests. The client tolerates and ignores unknown additive response fields without treating them as authoritative, and uses a safe fallback for unknown enums.

Object-storage upload is the only approved direct third-party data path from the mobile app for learning sources. OIDC and push notification SDKs are separate provider integrations. All business state still resolves through the Memora API.

## 22 Contract test suite

### 22.1 Provider tests

- Every documented operation returns only declared response shapes.
- Authentication, ownership, recent-authentication and consent failures use the shared error contract.
- Idempotency replay returns the same logical result; changed bodies are rejected.
- Cursor pagination is stable and owner scoped.
- Async status transitions never move backward from terminal state.
- Answer keys and private fields are absent before submission.
- Logs and traces contain no prohibited payload values.

### 22.2 Consumer tests

- Generated Dart models deserialize every success and error example.
- Unknown additive fields do not break current clients.
- Unknown enum values produce neutral fallback behavior.
- A timed-out mutation is reconciled by operation identity.
- `401` refresh is attempted once and does not duplicate mutation delivery.
- `409` refreshes authoritative state and preserves safe user input.
- Deep-link resources are validated before navigation.

### 22.3 Required end to end contract scenario

1. Bootstrap an authenticated new student.
2. Create a Physics learning update and obtain an upload grant.
3. Finalize the upload twice with the same idempotency key and receive one workflow.
4. Poll until verification is required.
5. Submit versioned decisions and commit once.
6. Start the first mission twice and receive the same active mission.
7. Submit an answer, simulate timeout and replay the same client operation ID.
8. Complete the mission twice and confirm one XP source event.
9. Read the updated reef projection and submit a question report.
10. Request an export, verify step-up enforcement and observe terminal status.

## 23 Requirement traceability

| API area | Product requirements | Technical sections | Data domains | App-flow sections |
| --- | --- | --- | --- | --- |
| Session profile consent | PRD 001-004, 035 | TRD 5, 6, 14 | Identity and consent | 4-6, 12 |
| Learning updates | PRD 005-010 | TRD 6.3, 10, 11 | Ingestion and commits | 9 |
| Missions grading | PRD 011-022 | TRD 9, 12, 13 | Missions, attempts, memory | 10 |
| Progress rewards | PRD 023-030 | TRD 13 | Ledgers, streaks, projections | 7, 8, 11 |
| Notifications | PRD 031-032 | TRD 5, 16 | Devices and preferences | 13 |
| Privacy | PRD 033-035 | TRD 14-16 | Privacy requests and proofs | 12, 14 |

## 24 Implementation order

1. Define shared identifiers, timestamps, pagination, error and idempotency models.
2. Implement token validation, request context, authorization helpers and safe logging.
3. Implement bootstrap, profile, consent, subjects and Home reads.
4. Implement learning updates, signed uploads, status and verification.
5. Implement commit, mission, attempt, grading and completion operations.
6. Implement seabed, statistics, rewards and reports.
7. Implement devices, notification intents and privacy workflows.
8. Generate the Dart client and feature repositories.
9. Add provider, consumer, authorization, retry and end-to-end contract tests.
10. Publish versioned OpenAPI and block incompatible drift in CI.

## 25 Definition of done

Document 6 is implemented when:

- Every mobile flow maps to documented operations and terminal outcomes.
- OpenAPI contains all request, response, error and security schemas.
- Generated Dart code compiles without manual patches.
- Cross-user negative tests cover every private resource class.
- Duplicate delivery cannot duplicate attempts, commits, XP, rewards, reports or privacy requests.
- Upload bytes bypass the API and signed grants remain narrow and temporary.
- Offline answer replay and unknown-outcome reconciliation pass.
- Logs, traces, analytics and push payloads pass sensitive-data tests.
- Contract, integration and required end-to-end scenarios pass in CI.
- Breaking changes require a reviewed major-version decision.

## 26 Open decisions inherited from earlier documents

- Final OIDC provider, token audience and recent-authentication window.
- Supported upload types, sizes, page limits and multi-source policy.
- Endpoint-specific pagination defaults, quotas and request deadlines.
- Whether short-answer grading is enabled at MVP launch.
- Exact export package format, availability window and retention exception copy.
- Push provider configuration, localization set and lock-screen preview default.
- OpenAPI publication location and generated Dart package name.


