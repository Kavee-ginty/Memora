# Memora App Flow and Screen State Specification

**Document 5 of 6**  
**Status:** Canonical implementation specification  
**Version:** 1.0  
**Prepared:** 22 October 2026  
**Audience:** Mobile, backend, design, QA, accessibility and AI coding agents  
**Applies to:** Student-first Sri Lankan GCE Advanced Level Physics MVP  
**Related documents:** `./Memora_PRD.md`, `./Memora_TRD.md`, `./Memora_UI_UX_Design_Specification.md` and `./Memora_Backend_Schema_and_Data_Model.md`

## 1 Purpose and authority

This document defines every student-facing route, guard, transition, async state, interruption rule and recovery path required for the Memora MVP. It is the implementation authority for how a student moves through the Flutter application and how each screen reacts to server, connectivity and local-persistence state.

The PRD governs product scope and outcomes. The TRD governs architecture and service boundaries. The UI/UX specification governs visual behavior, copy and accessibility. The backend schema governs durable state. This document binds those decisions into executable mobile flows without changing them.

### 1.1 Required implementation outcome

An implementation is conformant only when the same durable state always resolves to the same safe route and visible screen state; repeated operations do not duplicate evidence or rewards; ordinary interruption does not discard recoverable work; and every failure offers a truthful next action.

### 1.2 Non-goals

This document does not define exact component dimensions, database migrations, complete API schemas, animation assets, model prompts, educator tools or post-MVP social features.

## 2 Flow principles

### FLOW-001 Server authority is never simulated

The client may optimistically preserve input and show pending operations, but it does not invent mission membership, grading, due dates, XP, streak status, reef health, consent status or deletion completion.

### FLOW-002 One durable operation has one client operation identifier

Upload finalization, answer submission, mission completion, reports, preference changes and privacy requests use an idempotency key or stable client operation ID. Retrying reuses the identifier until a terminal response is known.

### FLOW-003 Navigation follows confirmed state

Routes that require authentication, consent, committed content or an active mission are guarded. A guard redirects to a recovery screen while retaining an encoded safe return location. The client never exposes another user's identifier through a route.

### FLOW-004 Interruption is expected

Form values, text learning drafts, concept edits, the downloaded active mission and pending answer envelopes survive ordinary app backgrounding or process recreation when safe. Destructive exits require confirmation.

### FLOW-005 Loading never hides indefinitely

Page skeletons are used for initial reads and inline progress for mutations. After 10 seconds, the interface states what is still happening and offers a safe leave, retry or continue-later action.

### FLOW-006 Error recovery preserves context

Recoverable failures keep accepted input, selection and scroll context. Error copy identifies the failed action, not the student. Raw server messages and internal codes are not primary copy.

### FLOW-007 Accessibility state is part of route state

Every transition moves focus intentionally, announces meaningful async outcomes, respects reduced motion and retains a logical reading order at 200 percent text scale.

### FLOW-008 Bounded missions remain bounded

No result or repair path silently adds an endless sequence. A repair item belongs to the planned policy boundary, and mission completion uses the server's authoritative completion response.

## 3 Navigation architecture

### 3.1 Root destinations

| Destination | Route | Purpose | Active label |
| --- | --- | --- | --- |
| Home | `/home` | Today's mission and next useful action | Home |
| Learning | `/learning` | Subject learning path and material entry | Learning |
| Progress | `/progress` | Continuous seabed and reef detail | Progress |
| Profile | `/profile` | Identity, preferences, privacy and support | Profile |

The bottom navigation is visible only on root destinations and their non-immersive child views. It is hidden during onboarding, authentication, material verification steps, active missions, answer feedback, explanations, mission results and destructive account workflows.

### 3.2 Route classes

| Class | Behavior | Examples |
| --- | --- | --- |
| Public | No session required | splash, onboarding, sign in, account recovery |
| Authenticated root | Valid session and bootstrap required | Home, Learning, Progress, Profile |
| Authenticated detail | Valid session; back returns to stable parent | material, statistics, settings |
| Transactional | Guarded by durable workflow identifier | extraction verification, mission, privacy request |
| Modal | Restores underlying route after dismissal | subject picker, reef detail, report question |

### 3.3 Canonical route inventory

| Route name | Path | Guard | Stable parent |
| --- | --- | --- | --- |
| splash | `/` | none | none |
| onboarding | `/onboarding/:step` | signed-out | sign in |
| signIn | `/auth/sign-in` | signed-out | onboarding or Home |
| createAccount | `/auth/create-account` | signed-out | onboarding or Home |
| recoverAccount | `/auth/recover` | signed-out | sign in |
| home | `/home` | authenticated | root |
| learning | `/learning` | authenticated | root |
| learningPath | `/learning/:subjectId` | subject ownership | Learning |
| addMaterial | `/learning/:subjectId/material/new` | online consent | Learning path |
| materialStatus | `/learning/updates/:updateId` | update ownership | Learning path |
| verifyConcepts | `/learning/updates/:updateId/verify` | verification required | Material status |
| pathPreview | `/learning/updates/:updateId/preview` | verified candidate set | Verify concepts |
| missionPreview | `/missions/:missionId/preview` | mission ownership | Home or deep link |
| mission | `/missions/:missionId/item/:itemId` | active mission | Mission preview |
| missionFeedback | `/missions/:missionId/item/:itemId/feedback` | recorded attempt | Mission |
| explanation | `/missions/:missionId/item/:itemId/explanation` | feedback available | Feedback |
| missionResults | `/missions/:missionId/results` | completed mission | Home |
| progress | `/progress` | authenticated | root |
| reefDetail | `/progress/reef/:subjectId` | subject ownership | Progress |
| statistics | `/progress/statistics` | authenticated | Progress |
| profile | `/profile` | authenticated | root |
| notifications | `/profile/notifications` | authenticated | Profile |
| accessibility | `/profile/accessibility` | authenticated | Profile |
| privacy | `/profile/privacy` | recent auth for mutations | Profile |
| reportQuestion | `/questions/:questionVersionId/report` | authenticated | Feedback or explanation |

Opaque IDs may appear in internal routes, but the router must validate ownership through server responses and must not infer access from identifier presence.

## 4 Bootstrap and global app state

### 4.1 Bootstrap order

1. Initialize local preferences, accessibility settings and pending-operation metadata.
2. Restore the provider session from secure storage.
3. If a session exists, request the session bootstrap payload.
4. Reconcile consent, account status, active mission, pending operations and notification deep link.
5. Resolve the destination using the priority table below.

| Priority | Condition | Destination |
| --- | --- | --- |
| 1 | Account deletion completed or session revoked | Sign in with completion message |
| 2 | Account suspended or required recovery | Blocking account recovery state |
| 3 | Required consent renewal affects requested action | Consent review, then safe return route |
| 4 | Valid active mission and the student chose resume | Current mission item |
| 5 | Valid authenticated deep link | Validated deep-link destination |
| 6 | Authenticated | Home |
| 7 | Onboarding incomplete | Onboarding step 1 |
| 8 | Signed out | Sign in |

The splash has no artificial delay and no percentage. An initialization failure offers retry; if safe cached preferences exist, accessibility settings still apply to the recovery screen.

### 4.2 Global state dimensions

| Dimension | Values |
| --- | --- |
| Data phase | initial, loading, ready, empty, stale, failure |
| Connectivity | online, offline, reconnecting |
| Mutation | idle, submitting, pendingSync, succeeded, failed |
| Session | unknown, signedOut, active, refreshRequired, blocked |
| Freshness | current, cached, expired |

Content already on screen remains visible during a refresh. A refresh indicator must not replace usable data with a blank loading page.

## 5 Guards and back behavior

### 5.1 Guard order

Guards run in this order: session, account status, recent authentication, consent, resource ownership, workflow state and active-mission interruption. A failed guard returns a typed reason and safe redirect rather than throwing a blank route.

### 5.2 Back and exit rules

| Context | Back behavior |
| --- | --- |
| Root destination | System back exits or backgrounds according to platform convention |
| Detail screen | Return to stable parent and retain its tab and scroll position |
| Onboarding | Previous step; step 1 returns to sign-in choice |
| Form with unsaved changes | Confirm discard, keep editing by default |
| Upload in progress | Explain whether background continuation is supported before leaving |
| Extraction processing | Leaving is safe; status remains accessible from Learning |
| Active mission | Pause/exit confirmation; preserve downloaded mission and answered progress |
| Feedback or explanation | Return only within the current mission sequence |
| Account deletion confirmation | Cancel returns to Privacy without changing state |

App links must never create a navigation stack that cycles between a detail and itself. After authentication, a valid return location is consumed once and cleared.

## 6 Session and account flows

### 6.1 First use

Splash routes a new signed-out student through three onboarding steps. Skip routes to the authentication choice. Create account is primary on step 3; existing account routes to sign in. Successful authentication bootstraps the Physics subject and routes to Home. If no learning path exists, Home presents Add learning material.

### 6.2 Sign in

| State | Visible behavior | Allowed action |
| --- | --- | --- |
| Ready | Empty persistent-label fields | Submit or use Google |
| Invalid input | Inline fields plus focusable summary | Correct and resubmit |
| Submitting | Values retained; submit disabled | Cancel only if provider allows |
| Invalid credentials | Safe message; password retained only while screen remains | Retry or recover account |
| Network failure | Values retained | Retry with same operation context |
| Success | Brief accessible confirmation | Bootstrap then Home or return route |

Token refresh happens outside screens. One refresh attempt may replay safe reads. A mutation is replayed only under its idempotency contract. Refresh failure clears sensitive session material and routes to sign in with a session-expired message.

### 6.3 Sign out and session revocation

Sign out warns if an unsynced answer or draft exists. Confirming revokes the current session when online, clears secure credentials and private cached payloads, then routes to sign in. If revocation cannot reach the server, local sign-out still completes and the server revocation is queued only if the security design permits it.

## 7 Home flow and states

| Condition | Hero state | Primary action |
| --- | --- | --- |
| No learning path | Setup | Add learning material |
| Mission planned | Ready | Start Daily Mission |
| Mission started or paused | In progress | Continue Daily Mission |
| Mission completed today | Complete | View today's results |
| No due memories | Cared for | Quick practice, when supplied by server |
| Data refresh failed with cache | Stale | Continue from safe cached state or retry |

Starting a mission opens its preview unless the student is resuming a started mission. Home does not compute due counts, rewards or reef health. Pull-to-refresh preserves the current card until replacement succeeds.

## 8 Learning path flow and states

Learning opens the selected subject path. The MVP has one Physics reef, but the route supports future subjects without changing the four root destinations.

| Node state | Action |
| --- | --- |
| completed | Open summary; optional server-provided practice |
| current | Start or continue the associated mission |
| available | Open preview, then start |
| locked | Explain prerequisite; never navigate into a question |
| needsReview | Open due mission preview |

The readable and focus order is top-to-bottom regardless of decorative curves. A missing path shows Add learning material. A cached path may be shown offline with a stale label, but status is not recomputed locally.

## 9 Learning material ingestion flow

### 9.1 Entry and draft

The student selects Physics, then chooses pasted text or a supported temporary PDF/image. Manual text may persist as a protected local draft. Upload bytes are not kept in a long-lived application cache.

### 9.2 State machine

| Durable update state | Screen state | Student actions |
| --- | --- | --- |
| draft | Editable source | Save draft, upload or paste, discard |
| uploading | Byte progress | Leave if background-safe; cancel |
| processing | Extraction progress | Leave and return later |
| verification_required | Concept checks ready | Verify concepts |
| committed | Learning path ready | Preview or start first mission |
| failed | Safe failure reason | Retry eligible step or replace source |
| expired | Temporary material unavailable | Start a new update |
| deleted | Source removed; retained result stated | Open committed path if available |

### 9.3 Upload transition rules

1. Create the learning update with declared metadata and client operation ID.
2. Receive a short-lived signed grant.
3. Upload directly to temporary object storage.
4. Finalize once with the same operation identity.
5. Observe server status until verification, commit, terminal failure or expiry.

Unsupported type, excessive size, encryption or failed local quality checks block before upload where detectable. A server rejection replaces local assumptions. Retrying an expired grant requests a new grant but retains the update identity when allowed.

### 9.4 Verify concepts

Verification displays accepted candidates and marks uncertain items Check this. Edits remain local until submitted. The student may edit a title, reject irrelevant material or merge an obvious duplicate. Preview is disabled only when no valid concept remains, with a reason.

Submitting decisions uses one operation ID and locks only affected controls. A conflict caused by expired or committed candidates refreshes the update and explains the result. Successful commit routes to Learning path preview. Upload deletion status remains separate from retained knowledge.

### 9.5 Learning path preview

Preview shows subject, source, concept count, first concepts and estimated first mission duration. Edit concepts returns to verification. Add to my learning path performs the authoritative commit if needed. Success presents Start first mission and awards no XP.

## 10 Mission lifecycle

### 10.1 Preview and start

Mission preview shows type, subject, item count, estimated duration, due reason and connectivity limitation. Start calls the server and pins question versions. A repeated start returns the same active mission.

### 10.2 Mission state machine

| Mission status | Allowed transition | Visible destination |
| --- | --- | --- |
| planned | start, expire | Preview |
| started | answer, skip, pause, complete | Current item |
| paused | resume, abandon if policy permits | Preview or current item |
| completed | view results | Results |
| expired | request current mission | Home explanation |
| abandoned | request next safe action | Home |

The client follows the server current item and completed count. It does not skip ahead by changing a route ID.

### 10.3 Active item states

| State | Controls | Transition |
| --- | --- | --- |
| Presenting | Response controls enabled | Select or enter response |
| Draft answer | Check answer enabled when valid | Submit |
| Submitting | Response stable; controls locked | Await grading or pending sync |
| Pending sync | Response stored locally and marked unsynced | Retry same operation ID |
| Recalled | Feedback panel | Next memory or explanation |
| Partial or uncertain | Qualified feedback | Confirm, appeal, repair or continue as supplied |
| Weak memory | Repair explanation | Try repair question |
| Skipped | No correctness claim | Next server-provided item |
| Blocking failure | Response preserved | Retry, return Home or support path |

Selecting an option does not submit. Numeric and short answers validate shape locally but server grading is authoritative. Correctness is never inferred from client-held options.

### 10.4 Answer submission

Each answer envelope contains mission/item identifiers, question version, response payload, client operation ID and client timestamp. The first submit disables duplicate taps. A timeout moves to pending sync without pretending to grade. Retry uses the same operation ID. If the server confirms an existing attempt, the client uses its grading result.

When offline, only an already downloaded mission can continue. Responses may queue, but server-dependent feedback remains pending. The client must not reveal an answer key from cached data.

### 10.5 Feedback repair and completion

Recalled feedback announces Memory protected and keeps the prompt and response stable. Weak feedback announces Weak memory found and provides one bounded repair action when supplied. Explanation returns to feedback. Report question preserves mission progress and confirms submission visibly.

After the final handled item, complete is called idempotently. Only its response may show memories protected or repaired, XP, streak and reef change. While pending, show Finalizing your mission and allow leaving. Results actions are See my reef and Back to Home. Reopening results never reapplies XP.

## 11 Progress and reef flow

Progress opens the continuous seabed with the server projection. The MVP uses exactly `new`, `thriving`, `healthy`, `needs_care` and `dormant`. An unknown value renders a neutral unavailable state and is logged; the client does not guess a replacement.

Selecting a reef opens its detail sheet. Start review mission routes through preview. Open learning path routes to the subject. Statistics is secondary. A projection refresh after mission completion may animate once; repeated loads do not replay reward celebrations.

Offline Progress may show a labeled cached projection and last-synced time. It cannot claim queued answers already changed the reef.

## 12 Profile settings and privacy flows

### 12.1 Preferences and notifications

Profile edits use local draft state and field validation. Settings apply optimistically only when safe; failed persistence restores the confirmed value. Local accessibility settings apply immediately and sync later when allowed.

The app explains notification value before the system prompt. Denial never blocks use. Preferred time, quiet hours, categories and preview detail remain editable. Device-token registration failure is recoverable.

### 12.2 Export and deletion

Export requires recent authentication. Submit creates one privacy request and routes to status. Queued or processing states may be left safely. Ready provides the approved retrieval action and expiry. Failure avoids duplicate simultaneous exports.

Deletion requires recent authentication, a clear description and explicit confirmation. The app never claims completion until the server confirms deletion and proof state. Cancellation appears only when policy and server status permit it.

## 13 Notifications and deep links

### 13.1 Supported deep links

| Notification intent | Valid destination | Fallback |
| --- | --- | --- |
| Daily Mission ready | Mission preview | Home mission card |
| Due memories | Mission preview | Home |
| Extraction needs verification | Verify concepts | Material status |
| Learning path ready | Path preview | Learning |
| Reward ready | Reef detail or inventory surface | Progress |
| Privacy export ready | Privacy request status | Privacy |

A notification never opens directly into a timed or submitted question. Bootstrap validates session, ownership and current workflow status. Invalid, expired or completed links resolve to the stable parent with a brief explanation.

### 13.2 Foreground behavior

When the app is foregrounded, a non-blocking notice may update the relevant provider. It does not interrupt an active response. Tapping consumes the pending intent once; dismissing leaves underlying state unchanged.

## 14 Offline retry and reconciliation

### 14.1 Allowed offline work

| Capability | Offline behavior |
| --- | --- |
| Read cached Home, Learning or Progress | Allowed with stale and last-synced labels |
| Edit manual text draft | Allowed locally |
| Start upload or extraction | Disabled with connection reason |
| Continue downloaded active mission | Allowed within cached mission boundary |
| Submit answer | Queue envelope; grading pending |
| Change local accessibility setting | Apply locally; sync later |
| Complete mission | Pending until server confirmation |
| Export or delete account | Disabled with connection reason |

### 14.2 Reconciliation order

On reconnection: refresh session, submit pending answers in mission order, resolve results, request authoritative mission state, complete if eligible, then refresh Home and Progress. A failed operation stops only dependants. An unrecoverable conflict is surfaced with a support-safe request ID.

Pending records are removed only after authoritative acknowledgement. Sign-out and account deletion clear them according to security policy; private response content must not become available to another account on the device.

## 15 Standard async and error behavior

| Condition | Required UI behavior |
| --- | --- |
| Initial read | Skeleton matching content geometry |
| Background refresh | Keep data; show subtle refresh state |
| Slow operation over 10 seconds | Plain-language status plus safe leave or retry |
| Empty result | Explain what is absent and provide next action |
| Validation error | Inline error and summary when multiple |
| Recoverable server error | Preserve context and operation identity |
| Rate limit | Show retry timing without repeated automatic calls |
| Unauthorized | Refresh once, then sign-in recovery |
| Forbidden or not owned | Stable parent; no resource details leaked |
| Not found or expired | Stable parent with workflow-specific explanation |
| Conflict | Refresh authoritative state and explain changed outcome |
| Maintenance | Read cached safe data; disable affected mutations |

Error telemetry may record safe code, route class and request ID. It excludes note text, answers, tokens, source excerpts and sensitive profile values.

## 16 Persistence and restoration contract

| Item | Persist locally | Restore rule | Clear rule |
| --- | --- | --- | --- |
| Onboarding completion | Yes | Skip completed onboarding | Account reset or explicit replay |
| Sign-in password | No durable storage | Current process only | Leave or background per security policy |
| Manual learning draft | Protected | Restore to same subject | Submit, discard, sign-out or expiry |
| Upload file path | Temporary only | While platform grant remains valid | Completion, cancellation or cleanup |
| Concept edits | Until submission | Restore update and candidate version | Commit, discard or expiry |
| Active mission payload | Bounded protected cache | Validate before resume | Completion, expiry or sign-out |
| Pending answer envelope | Yes | Retry same operation ID | Authoritative acknowledgement |
| Root tab and scroll | Non-sensitive only | Restore after detail dismissal | Cache expiry |
| Accessibility settings | Yes | Apply before first rendered screen | User reset |

Schema versions accompany local records. An incompatible record is quarantined or safely discarded with explanation; it is never interpreted using the wrong shape.

## 17 Accessibility transition contract

- Each route exposes one primary heading and a descriptive page name.
- After navigation, focus moves to the heading or first error summary.
- After answer submission, feedback is announced without unexpectedly moving focus from the response.
- Opening a sheet or dialog traps focus; closing restores focus to its trigger.
- Progress indicators expose current, total and status text.
- Offline, pending-sync and stale states are announced once and remain visible in text.
- Reduced motion replaces route movement and reef growth with fades or immediate changes.
- A state change never depends on color, icon or Mora alone.

## 18 Mobile state ownership

Riverpod providers use immutable state and are scoped by stable resource identifiers.

| Provider responsibility | Owns | Must not own |
| --- | --- | --- |
| Session | bootstrap, refresh, account status | Feature form drafts |
| Router guard | route eligibility and return location | Server authorization decisions |
| Home | mission and reef summaries | Mission grading |
| Learning path | path projection and selected subject | Extraction mutation state |
| Learning update | draft, upload and processing status | Shared root navigation |
| Mission | payload, item state, pending envelopes | XP or reef calculation |
| Progress | seabed projection and reef detail | Memory-engine computation |
| Preferences | confirmed settings and local-safe overrides | Provider tokens |
| Pending operations | operation IDs and dependency order | Raw upload bytes |

Providers expose typed phases and safe errors. Screens render state and dispatch intents; they do not call repositories directly. Repository DTOs are mapped into domain state before presentation.

## 19 Analytics and observability

Allowed events include route viewed, onboarding completed, material method selected, upload stage changed, verification completed, mission started, answer acknowledged, repair offered, mission completed, report submitted and settings changed. Properties use opaque IDs or safe categories.

Do not collect raw answers, learning text, source excerpts, passwords, tokens, full notification content or unnecessary accessibility values. Route timing distinguishes network latency from reading or answering time. Duplicate client events use a stable event ID when they affect metrics.

## 20 Acceptance scenarios

### 20.1 Required end to end scenario

1. A new student completes or skips onboarding and creates an account.
2. Home presents Add learning material.
3. The student uploads a supported Physics source and leaves during processing.
4. A deep link returns to uncertain-concept verification.
5. The student edits one concept, rejects one item and commits the learning path.
6. The first mission starts, an answer times out and is retried without duplicate evidence.
7. One weak memory receives a bounded repair question.
8. Mission completion applies XP once and updates the Physics reef projection.
9. The student opens the reef, reports a questionable explanation and returns Home.
10. After process recreation, the app restores confirmed state and no stale pending operation remains.

### 20.2 Mandatory test matrix

Every applicable screen is tested for initial, ready, empty, loading, stale, offline, pending mutation, success, recoverable failure, blocking failure and restored state. Tests include 320 px width, 200 percent text scale, screen reader, keyboard or switch access, reduced motion, process recreation and duplicate delivery.

### 20.3 Critical automated tests

- Router guards reject signed-out, wrong-owner, expired and invalid-state routes.
- A consumed deep link is not replayed after later navigation.
- Duplicate answer, completion and report taps create one server operation.
- Mission resume uses server current-item state after reconciliation.
- Pending offline answers submit in order and cannot cross accounts.
- Unsaved forms and concept edits warn before discard.
- Cached projections are labeled stale and exclude unconfirmed work.
- Focus moves correctly for errors, feedback, dialogs and route changes.
- Permanent rewards are never presented as removed by reef-state changes.

## 21 Requirement traceability

| Flow area | Product requirements | Technical contract | UI contract | Data contract |
| --- | --- | --- | --- | --- |
| Session and onboarding | PRD 001-004 | TRD 5, 6, 14 | UIX 001, 008-010 | users, consent records, devices |
| Ingestion | PRD 005-010 | TRD 6.3, 11 | UIX 019-023, screens 9.9-9.11 | updates, uploads, candidates |
| Missions | PRD 011-022 | TRD 9, 12, 13 | UIX 024-025, screens 9.12-9.16 | missions, attempts, grading |
| Progress | PRD 023-030 | TRD 13 | UIX 026, screens 9.17-9.19 | XP, streaks, reef projections |
| Notifications | PRD 031-032 | TRD 5, 6 | screen 9.21 | devices and preferences |
| Privacy | PRD 033-035 | TRD 14-16 | Profile and state matrix | privacy requests and proofs |

## 22 Implementation order

1. Define typed routes, resource parameters and guard results.
2. Implement bootstrap, return-location handling and the root shell.
3. Define reusable async, connectivity, mutation and safe-error types.
4. Implement versioned local persistence and account-scoped clearing.
5. Build Home and Learning reads before ingestion mutations.
6. Implement learning-update draft, upload, processing, verification and commit.
7. Implement mission preview, item, pending answer, feedback, repair and completion.
8. Implement Progress, reef detail and statistics.
9. Implement Profile, notification, accessibility and privacy workflows.
10. Add deep links, reconciliation, analytics and the acceptance matrix.

## 23 Definition of done

Document 5 is implemented when:

- Every route has a typed definition, guard, stable parent and invalid-state fallback.
- Every mutation has an idempotency or client-operation strategy.
- Screen states and transitions are represented in immutable application state.
- Process recreation preserves only approved state and never crosses accounts.
- Offline behavior matches the capability matrix.
- Deep links validate authentication, ownership and workflow state.
- Accessibility focus, announcements, text scaling and reduced motion pass QA.
- Analytics contain no prohibited learning or identity content.
- The required end-to-end scenario passes against production-shaped APIs.
- Deviations are documented against a `FLOW-` rule and approved.

## 24 Open decisions inherited from earlier documents

- Exact syllabus edition, language medium and examination-year applicability.
- Final identity provider, age range and consent renewal policy.
- Supported upload formats, size limits and multi-source policy.
- Mission workload cap, repair allowance and practice availability.
- Notification provider, preview-detail default and frequency caps.
- Retention periods for drafts, pending operations, cached missions and exports.
- Final route URI scheme and associated-domain configuration.

