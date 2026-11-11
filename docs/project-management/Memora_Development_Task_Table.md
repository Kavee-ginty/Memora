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
| T01 | Architecture baseline and repository scaffold | **Done** | Ginodh | 2 | None | `task/T01-repo-baseline` | Repository-wide |
| T02 | CI and development environments | **Done** | Neleesha | 3 | T01 | `task/T02-ci-environments` | CI and infrastructure |
| T03 | Flutter design system and app shell | **Done** | Ginodh | 5 | T01 | `task/T03-flutter-design-system` | Mobile shared UI |
| T04 | PostgreSQL migrations and seed framework | **Done** | Ginodh | 6 | T01 | `task/T04-database-schema` | Backend database |
| T05 | OpenAPI models and generated client pipeline | **Done** | Dasun | 4 | T01 | `task/T05-openapi-pipeline` | API contracts |
| T06 | Identity and session backend | **Done** | Ginodh | 4 | T02, T04, T05 | `task/T06-identity-session` | Backend API |
| T07 | Auth bootstrap mobile and guarded routes | **Done** | Ginodh | 5 | T03, T05, T06 | `task/T07-mobile-auth-routes` | Mobile navigation |
| T08 | Curriculum and knowledge graph seed | **Done** | Dima | 5 | T04, T05 | `task/T08-curriculum-graph` | Data and knowledge |
| T09 | Learning ingestion backend | **Done** | Dasun | 7 | T05, T06, T08 | `task/T09-ingestion-backend` | API and worker |
| T10 | Learning ingestion mobile | **Review** | Dasun | 6 | T07, T09 | `task/T10-ingestion-mobile` | Mobile feature |
| T11 | Memory engine v1 | **Done** | Dasun | 7 | T08 | `task/T11-memory-engine` | Learning engine |
| T12 | Question bank and grading backend | **Done** | Neleesha | 7 | T08, T05 | `task/T12-questions-grading` | Backend learning |
| T13 | Mission assembly and completion backend | **In Progress** | Ginodh | 7 | T06, T11, T12 | `task/T13-mission-backend` | Backend learning |
| T14 | Mission mobile experience | Blocked | - | 7 | T07, T13 | `task/T14-mission-mobile` | Mobile feature |
| T15 | Progress XP streak and reef backend | Blocked | - | 5 | T11, T13 | `task/T15-progress-backend` | Backend engagement |
| T16 | Progress mobile experience | Blocked | - | 5 | T07, T15 | `task/T16-progress-mobile` | Mobile feature |
| T17 | Profile preferences and notifications backend | **Done** | Harsha | 4 | T06 | `task/T17-profile-backend` | Backend account |
| T18 | Profile and settings mobile | **In Progress** | Codex | 4 | T07, T17 | `task/T18-profile-mobile` | Mobile feature |
| T19 | Push notifications and deep links | **Ready** | - | 4 | T07, T17 | `task/T19-push-deep-links` | Mobile and backend |
| T20 | Privacy export and deletion backend | **Done** | Dima | 5 | T06, T04 | `task/T20-privacy-backend` | Backend privacy |
| T21 | Privacy mobile experience | **Review** | Neleesha Peiris | 3 | T07, T20 | `task/T21-privacy-mobile` | Mobile feature |
| T22 | Offline sync and idempotency hardening | Blocked | - | 6 | T09, T13, T07 | `task/T22-offline-idempotency` | Cross-platform |
| T23 | Observability and security hardening | Blocked | - | 5 | T02, T09, T13, T17, T20 | `task/T23-security-observability` | Platform |
| T24 | Verified Physics pilot content | **Review** | Neleesha | 6 | T08, T12 | `task/T24-physics-content` | Academic content |
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

### T07 Definition of Done

This expands the acceptance gate in Section 4 for T07. It does not replace the board rule in Section 2 or the remaining-task evidence rules in Section 5.

| Area | Done criteria | Evidence |
| --- | --- | --- |
| Provider authentication | Supabase email/password, account creation, recovery and Google authentication use the approved provider SDK. Provider sessions are stored through operating-system secure storage; passwords, refresh material and access tokens are absent from application logs and non-secure persistence. | auth repository and secure-storage adapter; provider error-mapping, storage and sign-in/create/recovery tests; Android/iOS callback configuration |
| Bootstrap and session state | Startup restores approved local preferences, restores the provider session, calls the generated session-bootstrap operation and maps account, consent, subject, active-mission, pending-resource and capability fields into immutable Riverpod state. Unknown enum values and blocked accounts fail safely; the splash has no artificial delay. | session repository/controller and DTO mapping; bootstrap success, failure, unknown-value and blocked-account tests |
| Generated-client boundary | Mobile code consumes the committed generated Dart DTOs and session operations through typed repositories. Screens and providers do not construct API URLs, parse raw error JSON or hand-copy transport models; generated client files remain unedited and drift-clean. | mobile dependency and repository wiring; repository/serialization tests; generated-client and OpenAPI drift checks |
| Routes and root shell | Splash, three-step onboarding, sign-in, create-account, recovery and the four authenticated root destinations use named `go_router` routes. Bottom navigation is route-driven, preserves root branch state and is hidden on public or immersive routes. A validated safe return location is consumed once and cannot form a redirect loop or accept an external URL. | router, route definitions and root shell; route inventory, tab-state, back behavior, return-location and redirect-cycle tests |
| Guard enforcement | Guards run in the approved session, account, recent-authentication, consent, ownership and workflow-state order. Every T07 guarded route has signed-out and expired-session coverage; representative private-resource guards prove wrong-owner and invalid-state requests fall back without disclosing resource existence. Malformed identifiers fail before an unnecessary private-resource request. | typed guard results and router matrix; signed-out, refresh-success/failure, wrong-owner, invalid-state and malformed-route tests |
| Refresh and sign-out | One failed authenticated safe read may trigger one single-flight provider refresh and one replay. Mutations are not replayed without their original idempotency contract. Sign-out uses one idempotency key for server revocation when possible, still completes locally on network/revocation failure, clears secure credentials and account-scoped private state, and preserves only approved non-sensitive preferences. | session repository/controller; refresh replay-limit, revocation, pending-work warning and selective-clearing tests |
| Persistence and isolation | Process restart restores onboarding completion, accessibility settings and other explicitly approved non-sensitive state only; it performs a fresh bootstrap instead of restoring stale authoritative data. Passwords are never durable, incompatible local records are discarded safely, consumed return locations do not replay and state from one account cannot restore under another account. | restoration schema/storage code; process-recreation, incompatible-record, return-location and cross-account isolation tests |
| T07 presentation boundary | Splash, onboarding, authentication and bootstrap-backed Home states follow the approved copy and matching PNG composition while honoring the Markdown specifications where they differ. Home never fabricates mission counts, due dates, XP, streak or reef health before T15 provides the authoritative read model; unavailable successor workflows fail explicitly instead of navigating to dead or mocked screens. | screen/widget tests; comparison screenshots for matching source PNGs; Home authoritative-data tests |
| Accessibility and responsive behavior | Every T07 screen exposes one primary heading, logical focus order, screen-reader names/states, at least 48 px targets, inline and focusable validation, and reduced-motion behavior. Applicable loading, error, retry, offline/connection-required and blocked states remain usable at 320 px width and 200 percent text scale. | accessibility and responsive widget tests; recorded screen-reader, focus, reduced-motion, 320 px and 200 percent text evidence |
| Verification and handoff | Flutter formatting, analysis, unit/widget tests and Android debug build pass; affected generated-client checks remain green. The pull request records exact commands, visual/accessibility evidence, security/privacy impact, specification traceability and any approved deviation without claiming T07 Done before merge and board recalculation. | CI run and local command log; screenshots/accessibility record; pull-request checklist and handoff |

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

## 5 Remaining-task definitions of done

These gates apply to every task not already Done: `T10`, `T13`-`T16`, `T18`-`T19` and `T21`-`T31`. The acceptance
gate in Section 4 defines the delivery boundary; this section defines the minimum evidence
required to prove that boundary. A task may be marked **Done** only when all of the following
are true:

1. Every criterion in the task row below is satisfied by the merged implementation, not by a
   mock, local-only result or planned follow-up.
2. The implementation pull request records the successful required CI run and the exact automated
   and manual evidence named below. The later status update links that merged pull request and its
   merge commit. A green CI summary without the required task evidence is not sufficient.
3. All changed shared surfaces are regenerated and drift-clean in the same pull request. This
   includes migrations, OpenAPI, generated clients, design tokens, routes, authentication context,
   error models and CI configuration.
4. Security, privacy, ownership, idempotency and accessibility checks are mandatory whenever the
   task touches those concerns. A skipped mandatory check keeps the task in **Review** or
   **Blocked** unless the governing specification is changed and the deviation is approved.
5. Documentation, runbooks, fixtures and synthetic test data required to operate or reproduce the
   feature are merged with the implementation. No secret, production data or prohibited learning
   content appears in code, logs, fixtures, screenshots or build artifacts.
6. The status update names the merged pull request and confirms that every dependency and successor
   status was recalculated. A task is never marked Done solely because its branch was merged.

### 5.1 Mobile authentication and learning

| ID | Done criteria | Required evidence |
| --- | --- | --- |
| T07 | Bootstrap, onboarding/auth, root-shell and guarded routes use generated DTOs through repositories; signed-out, expired-session, wrong-owner and invalid-state navigation falls back safely; sign-out clears only approved state and process restart restores only approved state. | Router and repository tests for every guard and restoration case; 320 px, 200% text, screen-reader and reduced-motion results for matching screens; screenshots against approved PNG composition; Flutter format, analyze, test and build jobs. |
| T09 | Text and file ingestion cover create, upload grant, finalize, status, retry, extraction, verification, commit and deletion reconciliation; duplicate finalize/commit requests converge; unsupported or malicious input fails safely; uncertain candidates cannot commit without verification; raw-file deletion records proof. | Owner-negative, validation, idempotency, concurrency, worker retry/provider-failure and deletion-proof integration tests; migration and seed checks; OpenAPI and generated-client drift checks; logs proven free of source text, signed URLs and authorization data. |
| T10 | Add-material, progress/status, concept-verification and learning-path-preview screens cover every contracted update state; safe drafts and edits survive interruption; text and file flows can leave and resume; unavailable actions explain connectivity. | Mobile integration tests for text and file paths plus retry/restoration; loading, empty, error, offline and deletion-pending state tests; 320 px, 200% text, semantics and reduced-motion evidence; approved screenshots. Expanded in the T10 Definition of Done subsection below and `docs/learning/T10_Study_Note.md`. |
| T11 | Versioned memory inputs reproduce the same decision; updates are isolated per learner concept; expert bounds control first review, overdue and comeback cases; model output cannot directly set due dates; explanations identify the governing evidence and policy. | Deterministic unit/property tests, versioned calibration fixtures and scheduling simulations covering new, overdue, weak-prerequisite and comeback cases; persistence tests proving append-only evidence and concept isolation; recorded policy and fixture versions. Expanded in the T11 Definition of Done subsection below and `docs/learning/T11_Study_Note.md`. |
| T12 | Verified questions, versions, options, rubrics and concept mappings remain immutable after use; answer keys stay hidden before submission; MCQ and numeric grading are deterministic; enabled short-answer grading is bounded and low-confidence evidence has limited influence; report/dispute hooks preserve provenance. | Import and schema validation tests; authorization and pre-submission response tests; grading fixtures for correct, partial, uncertain, unit and tolerance cases; immutable-version and report/dispute tests; OpenAPI/client drift checks for changed contracts. |

### T10 Definition of Done

This expands the acceptance gate in Section 4 and the T10 row in Section 5.1. It does not replace the board rule in Section 2.

| Area | Done criteria | Evidence |
| --- | --- | --- |
| Screen and state coverage | Add-material, material status, verify-concepts and path-preview screens render every contracted update state (draft, uploading, processing, verification_required, committed, failed, expired, deleted) with loading/empty/error/offline/deletion-pending variants. | per-screen widget tests for all eight states; golden captures for nine states; UI/UX §13 Material state matrix mapping |
| Drafts and edits | Manual-text drafts persist protected and account-scoped; edits use `row_version`; drafts and edits survive interruption and process restart; unsent verification decisions persist across navigation and process death; discard warns before destroying unsaved work. | draft-store isolation/corruption tests; decision persistence/restore tests (UIX-033) |
| Text and file flows | Both paths complete create → grant → upload → finalize → poll → verify → preview → commit; both can leave and resume at any stage; finalize and commit are idempotent with durable, update-scoped operation identity. | flow/repository integration tests for text and file paths; double-submit and key-replay tests |
| Retry and recovery | Failed uploads re-grant retaining update identity and input; failed extraction retries via the retry operation; expired updates start new updates cleanly; terminal states never regress; a create-identity collision recovers with the draft preserved. | retry/restoration tests; expired-state tests; `mobile/test/ingestion/review_findings_test.dart` |
| Connectivity honesty | Unavailable actions are disabled with a connectivity reason after network failure; the offline banner shows; retry preserves input. | offline-state widget tests (decision D12, derived connectivity, reviewer acknowledgement requested) |
| Deletion separation | `source_deletion_status` and per-upload deletion state render separately from knowledge status; committed knowledge is never implied deleted. | status-screen and preview deletion tests |
| Security and privacy | No learning text, file names, draft content, tokens or authorization data in logs/errors; drafts encrypted at rest and account-isolated; upload bytes never cached; the presigned PUT carries zero API headers; generated client untouched. | isolation tests; header-exactness test; grep audit (zero logging hits) |
| Accessibility | One primary heading per screen; semantics for progress, bands and states; 48 px targets; 320 px and 200% text pass; reduced motion honored; no color-only meaning. | `mobile/test/ingestion/ingestion_accessibility_test.dart`; goldens; recorded evidence |
| Contracts | No backend/OpenAPI/client change; `generate_contracts.py --check` green; analyzer warnings at baseline. | contract check exit 0; analyzer clean |

Known cross-task boundaries: `first_mission` stays `null` until T13 wires mission creation into commit, so **Start first mission** is a disabled, explained action; real offline reconciliation lands with T22; the Learning-path screen (UI/UX 9.8) remains a placeholder outside this task; connectivity is derived from failed requests only pending T22.

### T11 Definition of Done

This expands the acceptance gate in Section 4 and the T11 row in Section 5.1. It does not replace the board rule in Section 2.

| Area | Done criteria | Evidence |
| --- | --- | --- |
| Determinism | The same learner state, event, `now`, engine version and policy version reproduce a bit-identical decision. Both versions are stamped on every decision row and every calibration fixture, so a later configuration bump cannot relabel history. | `test_memory_engine.py` determinism and seeded 200-event fuzz tests; `backend/tests/fixtures/memory/calibration_v1.json`; `ENGINE_VERSION` and `POLICY_VERSION` stamped on `memory_decisions` |
| Isolation | One concept update never reads or writes another concept's state, and every memory row stays owner-scoped. Cross-user reads return `404` without disclosing resource existence. | `test_memory_persistence.py` per-concept, per-learner, RLS and worker-grant negative tests; `test_memory_endpoints.py` owner-negative matrix |
| Evidence | Memory events are append-only and deduplicated by the schema uniqueness contract. Invalidation appends a new event and leaves the original event, decision and state rows byte-identical. | `test_memory_persistence.py` sequential and concurrent duplicate delivery, invalidation-append and outbox domain-key uniqueness tests; `memory_events` migration constraints |
| Policy bounds | First review lands near the next day; overdue, comeback and stability intervals stay inside the frozen `EngineConfig` bounds; confidence at or below the floor cannot produce an unbounded stability jump. | `test_memory_policy.py` first-review window, confidence damping, comeback and interval-cap tests; `test_memory_simulation.py` 30-day calendar over the four gate scenarios |
| Authority | No model or AI output can set a due date. Scheduling is deterministic code with no provider adapter, network call, clock read or randomness; due dates come only from `decide()` under the stamped policy. | `modules/memory/engine/` review boundary; engine configuration and policy version stamps; rationale recorded in `docs/learning/T11_Study_Note.md` |
| Selection inputs | T13 receives typed due, urgency, risk, prerequisite and recent-error inputs with capped page sizes. Ranking, diversity and workload caps stay in T13. | `test_memory_selection.py` input bands, reason precedence, caps, cursor scoping and limit boundaries; `memory-selection-inputs/1` contract version |
| Explanations | Every decision carries allowlisted reason codes, a `template_key` and a client-safe summary. Raw event payloads and raw retrievability, stability or forgetting-risk values never leave the backend. | `test_memory_endpoints.py` explanation-copy, band-only response, bounds and `no-store` tests; closed reason and template allowlists in `modules/memory/constants.py` |
| Persistence contract | Decision, state snapshot and outbox event commit in one transaction; duplicate delivery converges; `row_version` moves monotonically. | `test_memory_persistence.py` transaction atomicity, duplicate convergence, engine-version immutability and `SET LOCAL` isolation tests |
| Contracts and docs | Both operations use permanent T05 operation IDs with shared security and error envelopes. OpenAPI and the Dart client are regenerated together and drift-clean; backend documentation and the T11 study note are merged. | `operation_ids.py`; `contracts/openapi/memora-v1.json`; `generate_contracts.py --check`; generated Dart client tests; `backend/README.md`; `docs/learning/T11_Study_Note.md` |

Known cross-task boundaries: exposure ingestion consumes the documented `learning_update.committed` envelope until T09 merges, so T11 exercises it with synthetic outbox rows only. Attempt-graded evidence uses the envelope D9 reserves for T13. `concept-progress` gains reef, XP and streak fields only when T15 extends it additively. Mission assembly, ranking, diversity and workload caps remain T13's boundary.

### 5.2 Missions progress account and privacy

| ID | Done criteria | Required evidence |
| --- | --- | --- |
| T13 | Mission ranking follows workload, due-state, prerequisite and trust rules; start, answer and completion retries produce one logical result; item/question versions remain pinned; pause, skip, repair and completion transitions recover safely; grading and memory evidence publish through the outbox. | Deterministic ranking fixtures; owner-negative, idempotency, concurrency and full lifecycle integration tests; timeout/outbox replay and dependency-failure tests; migration/OpenAPI/client drift checks. |
| T14 | Mission preview, active formats, pending answer, recalled/weak/uncertain feedback, explanation, one bounded repair, reporting and results match authoritative server state; selecting never submits; pending offline work never reveals grading; resume uses the authoritative item; root navigation stays hidden during a mission. | Widget and mobile integration tests for every state and interruption path; duplicate-tap and resume/reconciliation tests; accessible focus/announcement, 320 px, 200% text and reduced-motion evidence; approved screenshots. |
| T15 | Each source event awards XP once; streak/grace rules never remove permanent rewards; the five-state reef projection is deterministic and rebuildable; new reefs are neutral; Home, progress and statistics read models are authoritative. | Ledger uniqueness/idempotency, missed-day/grace, permanent-grant and projection-rebuild tests; deterministic fixtures for all five reef states; owner-negative and migration tests; OpenAPI/client drift checks. |
| T16 | Home and progress render all five reef states without color-only meaning; cached projections are labelled stale; queued answers do not alter the reef locally; continuous seabed, reef detail, statistics summaries and reward transitions use authoritative responses. | Widget/integration tests for fresh, cached, offline, empty, loading and error states; chart text summaries and semantics checks; 320 px, 200% text and reduced-motion evidence; approved screenshots for all reef states. |
| T17 | Profile, preference, notification, quiet-hour, category and accessibility APIs enforce ownership and optimistic concurrency; notification denial never blocks use; device tokens remain encrypted and redacted through registration, refresh and revocation. | Owner-negative, version-conflict, validation, idempotency and device-lifecycle tests; ciphertext/fingerprint and prohibited-log assertions; migration/OpenAPI/generated-client drift checks. |
| T18 | Profile, edit, notification, accessibility and mission settings retain confirmed values across restart; local-safe accessibility changes apply immediately; failed persistence restores confirmed server values; Profile does not duplicate Progress. | Widget/repository/integration tests for save, retry, conflict, restart, offline and rollback; 320 px, 200% text, screen-reader, keyboard/switch and reduced-motion evidence; approved screenshots. |
| T19 | Push payloads contain no sensitive learning detail; foreground handling does not interrupt active answers; mission, verification, learning-path, reward and privacy links validate authentication, ownership, expiry and workflow state; each intent is consumed once. | Provider-adapter contract tests; redaction tests; signed-out, expired, wrong-owner, invalid-state, foreground and consume-once deep-link tests; Android/iOS integration evidence and safe fallback screenshots. |
| T20 | Export and deletion require recent authentication, run as durable idempotent jobs and report pending versus terminal state truthfully; completion requires proof or a documented exception for every scope; provider deletion, cancellation, audit and reconciliation rules are enforced. | Recent-auth and owner-negative tests; duplicate/concurrent request tests; job retry/provider-outage, cancellation, restore and reconciliation tests; deletion-proof and safe-audit assertions; migration/OpenAPI/client drift checks. |
| T21 | Retained-data, export and deletion screens distinguish pending, failed and complete states; the hub names retained categories and separates temporary uploads from verified knowledge; export download requires a completed status, signed URL and non-null future server expiry; destructive confirmation is explicit; offline navigation and operations, including reauthentication and download, are disabled with a reason; account/session data is cleared only after confirmed deletion state; reauthentication recovers safely. | Widget/integration tests for retained data, request, polling, download readiness, reauthentication, cancellation, failure, offline and confirmed clearing; 320 px, 200% text, semantics and focus evidence; approved screenshots. |

### 5.3 Hardening integration and release

| ID | Done criteria | Required evidence |
| --- | --- | --- |
| T22 | Versioned local storage covers drafts, cached mission and pending answers; process kill and reconnection preserve only approved state; reconciliation respects dependency order and stable operation identity; unknown outcomes converge without duplicates; data never crosses accounts; stale projections remain labelled. | Process-recreation, schema-migration, ordered-replay, timeout/unknown-outcome, duplicate-delivery and account-switch isolation tests on production-shaped APIs; offline capability matrix results. |
| T23 | Structured telemetry redacts prohibited content; correlation, metrics, traces and alerts cover API, jobs, database and security; rate limits, upload defenses, circuit breakers, secrets and audit controls preserve safe degraded operation. | Automated redaction and log-capture tests; exercised threat-model controls; alert/dashboard evidence; rate-limit, malicious-upload and provider/database outage tests; reviewed runbooks with no unresolved critical/high security finding. |
| T24 | The pilot Physics set has qualified review, curriculum/objective/concept mapping, formulas, units, prerequisites, rubrics, explanations and provenance; ambiguity, duplicates and coverage gaps are explicit; no private student content enters shared seeds. | Versioned content bundle; reviewer identity/approval record; schema, mapping, provenance, ambiguity, duplicate and coverage-report tests; deterministic seed validation using synthetic/public academic data only. |
| T25 | Every completed private API resource rejects cross-user access; examples deserialize; pagination, errors, idempotency-body mismatch, retry, concurrency and generated-client compatibility match OpenAPI and deployed behavior. | Provider/consumer contract suite covering every completed resource class; RLS and owner-negative matrix; concurrency/idempotency results; canonical OpenAPI/client drift pass in CI. |
| T26 | The complete new-student-to-updated-reef scenario uses production-shaped APIs with no mock on the path and covers interruption, retry, verification, repair, report and restart; analytics, outbox events and durable rows reconcile. | Repeatable CI/staging end-to-end run with synthetic data; operation and durable-row reconciliation report; failure diagnostics proving retries do not duplicate evidence or rewards. |
| T27 | Every implemented screen passes the mandatory state matrix at 320 px, 200% text, screen reader, keyboard/switch, reduced motion and long copy; essential meaning has text/non-color representation; visual deviations are approved; no critical accessibility defect remains. | Device/test matrix, automated semantics results, manual assistive-technology record, comparison screenshots and approved deviation log mapped to `UIX-` requirements and WCAG 2.2 AA targets. |
| T28 | Production-like load, concurrency, authorization, malicious-upload, prompt-injection, queue retry, provider outage, backup/restore and deletion reconciliation are exercised; SLOs pass or have approved limits; concurrency cannot duplicate evidence/rewards; no unresolved critical/high security finding remains. | Versioned load and failure-test plans/results; threat-review closure; backup/restore and retention reconciliation record; measured bottleneck changes with before/after evidence; approved exceptions for any missed SLO. |
| T29 | Signed staging builds, migrations and reviewed content are deployed; smoke, regression and UAT pass; monitoring works; rollback/roll-forward and support procedures are rehearsed; product, academic, security, privacy and accessibility approvals are recorded. | Immutable staging build identifiers; migration/seed logs; test and UAT report; monitoring screenshots/events; rehearsal record and named approval evidence; zero unresolved critical/high defect. |
| T30 | Every accepted UAT blocker is fixed with a regression test; affected gates are rerun; migrations, OpenAPI, clients and builds match source; release notes and known limitations are accurate; the release candidate is signed and reproducible. | Blocker-to-test traceability; successful affected CI/release gates; drift reports; signed artifact hashes and reproducible-build record; approved release notes/limitations. |
| T31 | Production migration and deployment complete from the approved candidate; health, authentication, ingestion, mission, progress and privacy synthetic checks pass; monitoring and incident ownership are active; the rollback decision window closes with a recorded launch outcome. | Production change record and artifact hashes; migration/deployment logs; synthetic smoke results; live alert/owner verification; rollback-window decision and signed launch report. |

## 6 Pull request checklist

Every task pull request must contain:

- Task ID and branch name.
- Short description of the completed acceptance boundary.
- Relevant PRD, TRD, UIX, schema, flow and API sections.
- Tests added and exact commands run.
- Each applicable Section 5 DoD criterion mapped to evidence; `not applicable` requires a documented
  specification reason or approved deviation.
- Migration, OpenAPI, generated client or seed changes where applicable.
- Screenshots or accessibility evidence for UI tasks.
- Security/privacy impact and confirmation that prohibited data is not logged.
- Any approved deviation, reviewer and follow-up task ID.

### T11 pull-request evidence

This records the Section 6 checklist for T11. Pull request #37 was reviewed and merged into `develop` at `4cbde6c`, so the task is **Done**.

| Checklist item | T11 evidence |
| --- | --- |
| Task ID and branch | T11, `task/T11-memory-engine`, one pull request for the task |
| Completed acceptance boundary | Versioned FSRS-style state, memory events and decisions, first-review/overdue/comeback policy, due-selection inputs for T13, prerequisite signals, explanations, the `memory.process_event` outbox consumer and the two owner-scoped read operations. Mission assembly, ranking, XP/reef and mobile rendering stay outside the boundary. |
| Specification sections | PRD 011-016; TRD 3.2-3.3, 4, 9; Schema 2, 3, 10, 13, 14.1-14.2; API 3-7, 10 and the `listConceptProgress`/`getConceptHistory` inventory rows. Traceability is in `docs/learning/T11_Study_Note.md`. |
| Tests and exact commands | `backend\.venv\Scripts\python.exe -m ruff format --check backend`; `-m ruff check backend`; `-m pytest backend\tests` with `MEMORA_TEST_DATABASE_URL`; `tools\contracts\generate_contracts.py --check`; `dart test` in `contracts\dart\memora_api_client`. Latest results: 432 backend tests (182 T11), 171 Dart tests, 91 files format-clean, contract check exit `0`. |
| Section 5 DoD mapping | Every row of `### T11 Definition of Done` names its suites or artifacts. The known cross-task boundaries are listed in the same subsection. |
| Migration, OpenAPI and client changes | `20261029_0007_memory_engine` follows `20261029_0006_runtime_role_switch` and adds the worker access contract; `contracts/openapi/memora-v1.json` and the committed Dart client were regenerated with the two operations and are drift-clean. No seed change. |
| UI and accessibility evidence | Not applicable: T11 has no mobile surface. T14 renders `template_key` and T16 renders progress; their state, 320 px, 200% text and semantics evidence belongs to those tasks. |
| Security and privacy | Ownership is derived from the validated session and enforced by RLS plus explicit predicates; cross-user reads return `404`; responses are `private, no-store` and band-only; logs contain no learning text, event payloads or authorization headers. Worker roles are limited to the granted tables. |
| Deviations and follow-ups | No approved deviation. Follow-ups: composite `memory_decisions` history index, `disable_existing_loggers=False` in migration logging, real T09 producer wiring, and T13/T15 additive extensions. All are recorded in `docs/learning/T11_Study_Note.md` and are outside the T11 merge boundary. |

### T24 review evidence

T24 is in **Review**, not Done. Route A is complete on
`task/T24-physics-content`: all eight envelopes use `expert_review`, record an
explicit self-review by Malshani Perera (Physics Teacher, qualification reference
`PostGraduate`) and are approved for import batch `T24-PHYS-PILOT-2026-11`. The
reviewer is also the author. Independence is not claimed, and the qualification
reference is self-declared and underspecified.

The conversion changed review and publication metadata only; prompts, options,
explanations, derivations, source references and concept/objective mappings were
preserved. `content/physics/pilot/REVIEW_RECORD.md` records the declaration,
per-item decisions and reviewed/sealed hashes. The real envelopes were imported
through `QuestionImportRepository` into a disposable PostgreSQL database; all
eight rows carry the same non-null author and reviewer principal and an approved
version. T24 remains Review until the Route A changes are committed, the branch is
merged and the merged content is reviewed as part of `develop`. Full evidence is
in `docs/evidence/T24_Content_Evidence.md`.

## 7 Current next action

T01-T09, T11-T12, T17 and T20 are merged and Done. T10, T21 and T24 are in
Review; T13 is In Progress. T18 and T19 are Ready. T14, T15, T22 and T23 remain
Blocked until T13 is Done; later tasks remain blocked until all listed
dependencies are Done.

T21's implementation and automated evidence are recorded in its study note and
privacy evidence. Before marking it Done, complete a real T20 backend/worker
exercise and Android manual accessibility/device record. The current PR merge
also requires final CI artifact uploads to succeed; this run hit the GitHub
Actions artifact storage quota. T27 remains Blocked until T21 is Done.

T24's next action is user commit, push, pull request and merge of the Route A
changes. Do not mark T24 Done until that merge occurs. The qualified-review record
is a self-review, and the qualification reference still lacks degree,
institution, year and subject-specialisation evidence.

T20 completed through pull request #38, merged into `develop` at `a243e79`. All required CI checks passed. Its successors were recalculated: T21 is Ready because T07 and T20 are Done; T23 and T25 remain Blocked by their other incomplete dependencies.

