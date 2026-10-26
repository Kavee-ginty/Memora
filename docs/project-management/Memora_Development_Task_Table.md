# Memora Development Task Table

**Status:** Execution-ready baseline  
**Companion plan:** `./Memora_Development_Network_Plan.md`  
**Ownership:** Claimed dynamically by any available developer

## 1 What developers must follow

The team does not follow the CPM diagram alone. Each task must use all applicable authorities in this order:

1. `../specifications/Memora_PRD.md` for product scope and rules.
2. `../specifications/Memora_TRD.md` for architecture and non-functional requirements.
3. `../specifications/Memora_UI_UX_Design_Specification.md` for interface behavior, accessibility and copy.
4. `../specifications/Memora_Backend_Schema_and_Data_Model.md` for persisted entities and constraints.
5. `../specifications/Memora_App_Flow_and_Screen_State_Specification.md` for routes, guards and state transitions.
6. `../specifications/Memora_API_and_Integration_Contract.md` for endpoint and integration contracts.
7. `../screens/*.png` for visual composition of the matching screen.
8. `./Memora_Development_Network_Plan.md` for task order, dependencies and criticality.

If two sources appear inconsistent, stop implementation and resolve the conflict against this authority order. Do not silently invent a new product rule or shared contract.

## 2 Board rules

- Status values are **Blocked**, **Ready**, **In Progress**, **Review**, **Done** and **Cancelled**.
- Only `T01` is initially Ready. A task becomes Ready only after every dependency is Done.
- Replace the Owner dash when claiming a task. One task has one accountable owner even when several developers pair on it.
- Use the listed branch. One task should normally produce one pull request.
- A pull request must list the task ID, relevant specification sections, tests run and any approved deviation.
- A task is not Done until its code, tests, migrations/generated files and documentation are merged.
- When a task becomes Done, recheck its successors and move newly unblocked tasks to Ready.

## 3 Master tracking table

| ID | Task | Status | Owner | Days | Dependencies | Branch | Primary area |
| --- | --- | --- | --- | ---: | --- | --- | --- |
| T01 | Architecture baseline and repository scaffold | **Done** | Codex | 2 | None | `task/T01-repo-baseline` | Repository-wide |
| T02 | CI and development environments | **Done** | Codex | 3 | T01 | `task/T02-ci-environments` | CI and infrastructure |
| T03 | Flutter design system and app shell | **In Progress** | Antigravity | 5 | T01 | `task/T03-flutter-design-system` | Mobile shared UI |
| T04 | PostgreSQL migrations and seed framework | **Done** | Codex | 6 | T01 | `task/T04-database-schema` | Backend database |
| T05 | OpenAPI models and generated client pipeline | **Done** | Dasun Jayasanka | 4 | T01 | `task/T05-openapi-pipeline` | API contracts |
| T06 | Identity and session backend | **In Progress** | Codex | 4 | T02, T04, T05 | `task/T06-identity-session` | Backend API |
| T07 | Auth bootstrap mobile and guarded routes | Blocked | - | 5 | T03, T05, T06 | `task/T07-mobile-auth-routes` | Mobile navigation |
| T08 | Curriculum and knowledge graph seed | **Done** | Antigravity | 5 | T04, T05 | `task/T08-curriculum-graph` | Data and knowledge |
| T09 | Learning ingestion backend | Blocked | - | 7 | T05, T06, T08 | `task/T09-ingestion-backend` | API and worker |
| T10 | Learning ingestion mobile | Blocked | - | 6 | T07, T09 | `task/T10-ingestion-mobile` | Mobile feature |
| T11 | Memory engine v1 | **Ready** | - | 7 | T08 | `task/T11-memory-engine` | Learning engine |
| T12 | Question bank and grading backend | **Ready** | - | 7 | T08, T05 | `task/T12-questions-grading` | Backend learning |
| T13 | Mission assembly and completion backend | Blocked | - | 7 | T06, T11, T12 | `task/T13-mission-backend` | Backend learning |
| T14 | Mission mobile experience | Blocked | - | 7 | T07, T13 | `task/T14-mission-mobile` | Mobile feature |
| T15 | Progress XP streak and reef backend | Blocked | - | 5 | T11, T13 | `task/T15-progress-backend` | Backend engagement |
| T16 | Progress mobile experience | Blocked | - | 5 | T07, T15 | `task/T16-progress-mobile` | Mobile feature |
| T17 | Profile preferences and notifications backend | Blocked | - | 4 | T06 | `task/T17-profile-backend` | Backend account |
| T18 | Profile and settings mobile | Blocked | - | 4 | T07, T17 | `task/T18-profile-mobile` | Mobile feature |
| T19 | Push notifications and deep links | Blocked | - | 4 | T07, T17 | `task/T19-push-deep-links` | Mobile and backend |
| T20 | Privacy export and deletion backend | Blocked | - | 5 | T06, T04 | `task/T20-privacy-backend` | Backend privacy |
| T21 | Privacy mobile experience | Blocked | - | 3 | T07, T20 | `task/T21-privacy-mobile` | Mobile feature |
| T22 | Offline sync and idempotency hardening | Blocked | - | 6 | T09, T13, T07 | `task/T22-offline-idempotency` | Cross-platform |
| T23 | Observability and security hardening | Blocked | - | 5 | T02, T09, T13, T17, T20 | `task/T23-security-observability` | Platform |
| T24 | Verified Physics pilot content | Blocked | - | 6 | T08, T12 | `task/T24-physics-content` | Academic content |
| T25 | API contract and authorization tests | Blocked | - | 5 | T09, T13, T15, T17, T20 | `task/T25-api-auth-tests` | QA and backend |
| T26 | Cross-feature end-to-end integration | Blocked | - | 6 | T10, T14, T16, T18, T19, T21, T22, T25 | `task/T26-e2e-integration` | Integration |
| T27 | Accessibility and visual QA | Blocked | - | 5 | T10, T14, T16, T18, T19, T21 | `task/T27-accessibility-visual-qa` | QA and mobile |
| T28 | Load security and failure testing | Blocked | - | 5 | T23, T26 | `task/T28-load-security-tests` | QA and platform |
| T29 | Staging release and UAT | Blocked | - | 4 | T24, T26, T27, T28 | `task/T29-staging-uat` | Release |
| T30 | Pilot fixes and release candidate | Blocked | - | 5 | T29 | `task/T30-release-candidate` | Repository-wide |
| T31 | Production pilot launch | Blocked | - | 2 | T30 | `task/T31-pilot-launch` | Release operations |

## 4 Detailed task contracts

### Foundation

| ID | Required work and deliverables | Acceptance gate | Main authorities |
| --- | --- | --- | --- |
| T01 | Create the agreed repository layout for Flutter, FastAPI API, worker, shared contracts, infrastructure, tests and docs. Add root README, contribution workflow, environment template, formatting/lint configuration, dependency strategy, AGENTS instructions and ownership boundaries. | Mobile and backend skeletons build; no secrets committed; commands for setup, test and generation are documented; shared locations and branch rules are explicit. | TRD 3, 5, 18; all document paths |
| T02 | Add local development services and CI jobs for format, lint, unit tests, migration checks, OpenAPI drift, dependency/secret scanning and build artifacts. Define development, staging and production configuration boundaries. | Fresh clone reaches a green CI baseline; local PostgreSQL/pgvector and required services start from documented commands; CI fails on lint, tests, secrets or contract drift. | TRD 2, 16, 18, 19 |
| T03 | Convert UI tokens into Flutter theme primitives. Build responsive app scaffold, headers, bottom navigation, buttons, cards, form fields, banners, dialogs, sheets, skeletons and Mora placement interfaces with accessibility semantics. | Component catalog covers required states at 320 px and 200% text scale; contrast, focus, touch targets and reduced motion pass component tests; no feature-specific business logic. | UI/UX 3-7, 12, 14; screen PNGs |
| T04 | Implement reviewed forward migrations for identity, curriculum, ingestion, questions, memory, missions, engagement, governance and privacy tables. Add constraints, indexes, RLS policies and seed framework. | Empty and previous-schema migration tests pass; cross-user constraints and status checks are tested; rollback or roll-forward recovery is documented; schema matches Document 4. | Schema 3-18; TRD 7, 14-16 |
| T05 | Define shared Pydantic request/response/error models and stable FastAPI operation IDs. Generate and validate OpenAPI, then generate the Dart API client without manual edits. Add schema-drift and serialization tests. | OpenAPI includes common errors, auth, idempotency and examples; Dart client compiles; regenerated output is deterministic; CI rejects undocumented API changes. | API 1-7, 20-22; TRD 6 |
| T06 | Integrate the approved OIDC contract, token validation, request context, scoped repositories, session bootstrap/revocation, device registration and consent status. Add recent-authentication handling. | Invalid tokens fail safely; private reads are server-scoped; bootstrap returns the contracted summary; negative authorization and session-expiry tests pass; tokens are absent from logs. | API 4, 8-9; Schema 6; Flow 4-6; TRD 14 |
| T07 | Implement splash/bootstrap resolution, onboarding/auth routes, root shell, guarded routes, one-time return locations, session refresh and safe sign-out clearing. Consume generated DTOs through repositories. | Every guarded route has tested signed-out, expired-session, invalid-owner and invalid-state behavior; process restart restores only approved state; visual implementation follows matching PNGs. | Flow 3-6; UI/UX 8-9.7; API 8-10 |
| T08 | Seed the approved Physics subject/curriculum framework, typed concepts, aliases, claims, objectives and edge allowlist. Implement bounded authorized knowledge access methods and seed validation. | Seeds are versioned and environment-safe; cycles/invalid edge types fail; curriculum mapping and provenance tests pass; no production user or secret appears in seed data. | PRD 9; TRD 8; Schema 7, 18 |

### T06 Definition of Done

This expands the acceptance gate in Section 4 for T06. It does not replace the board rule in Section 2.

| Area | Done criteria | Evidence |
| --- | --- | --- |
| Supabase identity | Google sign-in access tokens are verified against the configured Supabase issuer and JWKS with exact audience, expiry, subject, authenticated role and session checks. Invalid or expired tokens return the shared safe error envelope and token values are never logged. | `security.py`; identity security tests |
| Request scope | Authentication context derives the local user from the validated provider subject. Every private query applies the user RLS context and explicit ownership predicate; cross-user device access is rejected. | identity repository; migration authorization test |
| Session lifecycle | Bootstrap returns the bounded account, profile, consent, curriculum, active mission, pending work and capability summary. Revocation supports current, other and all Supabase sessions, is idempotent, requires recent interactive authentication and records a safe audit event. | identity service/routes; bootstrap and recent-auth tests |
| Consent and devices | Consent reads expose configured current policy versions and append immutable acceptance records. Device registration validates locale/timezone, encrypts push tokens with AES-256-GCM, stores only an independent HMAC fingerprint and supports owner-scoped deletion. | identity schemas/service/repository; encryption and policy tests |
| Shared contract | The six T06 operations use permanent T05 operation IDs, shared headers and error models. OpenAPI and the generated Dart client are regenerated together and drift checks pass. | `memora-v1.json`; generated Dart client; contract checks |
| Verification and documentation | Affected lint, unit, integration, migration, OpenAPI and generated-client checks pass. Deployment variables and the T06 design/security decisions are documented without secrets. | validation commands; environment guide; T06 study note |

### T05 Definition of Done

This expands the acceptance gate in Section 4 for T05. It does not replace the board rule in Section 2.

| Area | Done criteria | Evidence |
| --- | --- | --- |
| Shared models | The shared Pydantic models define the documented error envelope, field errors, pagination, request headers, idempotency header, async operation and UTC datetime shapes. Validation rejects inconsistent pagination metadata and out-of-range values. | `backend/src/memora/api/v1/schemas/`; `backend/tests/test_api_contract_models.py` |
| Contract surface | All 52 operations have permanent, unique IDs that match the inventory. The OpenAPI artifact is valid 3.1 and canonical, with shared security, tags and components. Guards reject undocumented operations, duplicate IDs, missing metadata, unsecured `/v1` operations, non-envelope errors and mutations without idempotency semantics. | `operation_ids.py`; `openapi.py`; `memora-v1.json`; `test_openapi_contract.py`; `test_openapi_artifact.py` |
| Generated client | The generator is pinned by version and SHA-256. Regeneration is deterministic, `--check` produces no diff, dependency resolution is locked, the single template override is documented, and the client compiles without manual edits. | `tools/contracts/`; `contracts/dart/`; `generate_contracts.py --check` |
| Tests | Backend model, guard and artifact tests pass, including negative authorization, idempotency and error-response checks at the contract level. Dart serialization tests pass for the error envelope, additive fields, pagination, async operation, optional values, the health enum and the unknown platform fallback. The contract workflow runs these checks plus drift detection and an analyzer warning baseline. | 63 backend contract tests; 10 Dart serialization tests; `.github/workflows/contracts.yml` |
| Documentation | Contract, OpenAPI, Dart, backend and tools documentation covers regeneration, drift checks, change rules, the generator pin, the template override and generator constraints. The T05 study note records the design, trade-offs and follow-ups. | `contracts/**/README.md`; `backend/README.md`; `tools/README.md`; `docs/learning/T05_Study_Note.md` |
| Generator representation | `HealthStatus` is emitted as a named one-value enum rather than an inline `const`, so responses remain limited to `ok`. Unknown additive response fields are tolerated and ignored per approved API §21 policy. | T05 study note |

### Learning ingestion and intelligence

| ID | Required work and deliverables | Acceptance gate | Main authorities |
| --- | --- | --- | --- |
| T09 | Implement learning-update creation, text input, signed upload grants, finalize/status/retry, validation/scanning hooks, extraction workflow, candidate storage, verification decisions, commit transaction and deletion reconciliation. | Duplicate finalize/commit requests converge; unsupported or malicious files fail safely; uncertain candidates require verification; raw files are deleted with proof; full ingestion contract tests pass. | PRD 005-010; TRD 10-11; Schema 8, 13; API 11-12 |
| T10 | Build Add material, upload progress/status, Verify concepts and Learning-path preview screens. Preserve safe drafts and edits, support leave-and-return processing, and surface deletion status separately. | All update states render; retry retains input; unavailable actions explain connectivity; source PNG composition and UI copy are followed; mobile integration tests cover text and file paths. | UI/UX 9.9-9.11; Flow 9; API 11-12; screen PNGs |
| T11 | Implement versioned FSRS-style learner-concept state, memory events, memory decisions, first-review policy, due selection inputs, prerequisite signals and explanation output. Add deterministic expert safeguards and calibration fixtures. | Same inputs/version reproduce the same decision; one concept update cannot affect another; no model directly sets due dates; overdue and comeback cases are bounded and tested. | PRD 011-016; TRD 9; Schema 10 |
| T12 | Import/version verified questions, options, rubrics and concept mappings. Implement source precedence plus deterministic MCQ/numeric grading and bounded short-answer grading if enabled. Add report/dispute hooks. | Question versions remain immutable after use; answers are hidden before submission; grading fixtures cover correctness, partial/uncertain outcomes, units and tolerance; low confidence has limited influence. | PRD 017-022; TRD 12; Schema 9, 11.4; API 13, 15 |

### Missions and progress

| ID | Required work and deliverables | Acceptance gate | Main authorities |
| --- | --- | --- | --- |
| T13 | Implement Today's Mission selection, bounded item creation, mission start/resume, item pinning, attempt submission, skip/pause, repair insertion policy and idempotent completion. Connect grading and memory evidence through outbox events. | Candidate ranking obeys workload and trust rules; duplicate starts/answers/completions create one result; pinned versions do not change; mission lifecycle and failure recovery tests pass. | PRD 013-022; TRD 9, 12-13; Schema 11; API 13 |
| T14 | Build mission preview, active question formats, pending answer state, recalled/weak/uncertain feedback, explanation, one bounded repair, report dialog and mission results. Hide root navigation during the mission. | Selection does not auto-submit; offline pending state never reveals grading; feedback is announced accessibly; resume uses authoritative item; results match server totals and source screens. | UI/UX 9.12-9.16; Flow 10; API 13; quiz PNGs |
| T15 | Implement append-only XP, streak/grace logic, permanent reward grants and rebuildable reef projection using the five canonical states. Produce Home/progress/statistics read models. | One event awards once; missed days never remove rewards; projection is deterministic; new reefs are neutral; Home and completion responses use authoritative state. | PRD 023-030; TRD 13; Schema 12; API 10, 14 |
| T16 | Build Home mission/reef states, continuous seabed, reef detail sheet, learning statistics, reward display and transitions from mission results. | Five reef states are distinguishable without color; cached state is labeled; queued answers do not alter the reef locally; charts have summaries; source PNG composition is respected. | UI/UX 9.7, 9.17-9.19, 10; Flow 7, 11; API 14 |

### Account notifications and privacy

| ID | Required work and deliverables | Acceptance gate | Main authorities |
| --- | --- | --- | --- |
| T17 | Implement profile/preferences APIs, notification settings, quiet hours, category controls, accessibility settings persistence and safe device-token lifecycle. | Patch/version conflicts are handled; denial of notifications does not block use; tokens are encrypted and redacted; preference and authorization tests pass. | PRD 004, 031-032; Schema 6; API 8-9, 16 |
| T18 | Build Profile, edit profile, notification settings, accessibility/mission settings, validation and save/retry states. Apply local-safe accessibility changes immediately. | Settings survive restart; failed persistence restores confirmed values; 200% text and screen reader pass; Profile does not duplicate Progress. | UI/UX 9.20-9.22; Flow 12; profile/notification PNGs |
| T19 | Integrate push provider adapter, foreground notices and validated deep links for missions, verification, learning path, rewards and privacy status. | Push contains no sensitive detail; expired/wrong-owner links fall back safely; active answers are not interrupted; each link intent is consumed once and tested. | PRD 031-032; Flow 13; API 16 |
| T20 | Implement recent-authenticated export and deletion workflows, durable jobs, status endpoints, cancellation rules, provider deletion steps, proofs and reconciliation. | Duplicate requests converge; completion is never inferred; all scopes produce proof or documented exception; sensitive operations are audited; restore/reconciliation tests pass. | PRD 033-035; TRD 15-16; Schema 13, 17; API 17 |
| T21 | Build retained-data overview, export request/status/download, deletion explanation/confirmation/status and reauthentication recovery screens. | The app states pending versus complete truthfully; destructive confirmation is explicit; offline actions are disabled with reason; account/session clearing follows confirmed state. | Flow 12, 14; UI/UX Profile/state rules; API 17 |

### Hardening content and integration

| ID | Required work and deliverables | Acceptance gate | Main authorities |
| --- | --- | --- | --- |
| T22 | Implement versioned local persistence for drafts, cached mission, pending answer envelopes and dependency-ordered reconciliation. Harden every retriable mutation with stable operation identity. | Process kill and reconnection tests pass; answers sync in order; unknown outcomes resolve without duplicates; data cannot cross accounts; stale projections remain labeled. | TRD 5.2, 16; Flow 14-16; API 7, 18 |
| T23 | Add structured safe logging, correlation IDs, metrics, traces, alerts, rate limits, upload defenses, circuit breakers, secret handling, audit events and operational dashboards. | Redaction tests prove prohibited content absent; alerts cover API/jobs/database/security; threat-model controls are exercised; failure modes preserve safe degraded operation. | TRD 14, 16-18; Schema 13, 16-17; API 18-19 |
| T24 | Produce the minimum reviewed Physics concept/question set for the pilot, including objectives, claims, formulas, units, prerequisites, rubrics, explanations, provenance and coverage reporting. | Qualified review is recorded; every item maps to curriculum and concepts; ambiguity/duplicate checks pass; gaps are explicit; no private student content enters shared seeds. | PRD 9; Schema 7, 9 |
| T25 | Implement provider/consumer contract tests, cross-user negative tests, RLS checks, pagination, errors, idempotency, concurrency and generated-client compatibility across completed API resources. | Every private resource rejects cross-user access; declared examples deserialize; changed idempotency bodies fail; OpenAPI and deployed behavior agree; test suite runs in CI. | API 20-22; TRD 19; Schema 16 |
| T26 | Connect all merged features and run the required new-student-to-updated-reef scenario, including interruption, retry, repair, report and restart. Resolve only integration defects within task scope. | Full scenario passes on production-shaped APIs; no mock remains on the path; analytics and durable rows reconcile; smoke test is repeatable in CI/staging. | PRD 12.1; Flow 20.1; API 22.3 |
| T27 | Test all implemented screens at 320 px, 200% text, screen reader, keyboard/switch access, reduced motion, long copy, loading, empty, error, offline and restored states. Compare against approved PNGs/spec changes. | No critical accessibility defect; WCAG 2.2 AA target checks pass; visual deviations are approved and recorded; every essential state has text/non-color meaning. | UI/UX 12-16; Flow 17, 20.2 |
| T28 | Run production-like load, concurrency, authorization, malicious-upload, prompt-injection, queue retry, provider outage, backup/restore and deletion-reconciliation tests. Tune only against measured bottlenecks. | SLO gates pass or have approved limits; no duplicate evidence/rewards under concurrency; restoration reapplies retention; critical/high security findings are resolved. | TRD 2, 14, 16, 19; API 19, 22 |

### Release

| ID | Required work and deliverables | Acceptance gate | Main authorities |
| --- | --- | --- | --- |
| T29 | Deploy signed builds to staging, run migrations, seed reviewed content, execute smoke/regression/UAT, verify monitoring and collect approval evidence. | All launch gates pass; no critical/high defect remains; rollback/roll-forward and support procedures are rehearsed; product, academic, security and accessibility approvals are recorded. | PRD 12; TRD 18-19, 23 |
| T30 | Fix accepted UAT blockers, add regression tests, regenerate contracts/builds, repeat affected release gates and produce the immutable release candidate. | Every blocker has a test; schema/API artifacts match code; release notes and known limitations are accurate; candidate is signed and reproducible. | Findings from T29 plus all six specs |
| T31 | Run production migration/deployment, verify health and synthetic smoke tests, enable the pilot cohort, monitor alerts and document launch outcome. | Production health, auth, ingestion, mission, progress and privacy checks pass; monitoring and incident ownership are active; rollback decision window closes successfully. | TRD 18; PRD release criteria; release runbook |

## 5 Pull request checklist

Every task pull request must contain:

- Task ID and branch name.
- Short description of the completed acceptance boundary.
- Relevant PRD, TRD, UIX, schema, flow and API sections.
- Tests added and exact commands run.
- Migration, OpenAPI, generated client or seed changes where applicable.
- Screenshots or accessibility evidence for UI tasks.
- Security/privacy impact and confirmation that prohibited data is not logged.
- Any approved deviation, reviewer and follow-up task ID.

## 6 Current next action

T01, T02, T04, T05 and T08 are merged and Done. T03 and T06 are In Progress, while T11 and T12 are Ready. T11 and T12 are the next zero-float critical-path tasks and may proceed in parallel.

