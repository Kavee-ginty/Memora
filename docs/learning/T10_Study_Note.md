# T10 Learning Ingestion Mobile

## Contract

T10 implements the student-facing ingestion experience on top of the twelve T09
operations: Add learning material, material status (upload progress/status),
Verify concepts and Learning-path preview, with their canonical routes, guards,
data/application layers and evidence tests.

- `addMaterial` (`/learning/:subjectId/material/new`) — subject, source picking
  (PDF/document, camera, gallery, pasted text), per-source states, protected
  manual-text draft, **Extract concepts**.
- `materialStatus` (`/learning/updates/:updateId`) — all eight durable update
  states, byte/extraction progress, retry, expiry, deletion status rendered
  separately from knowledge status.
- `verifyConcepts` (`/learning/updates/:updateId/verify`) — confidence-grouped
  candidates, **Check this** markers, local accept/edit/reject/merge, one
  idempotent decision batch, **Preview learning path**.
- `pathPreview` (`/learning/updates/:updateId/preview`) — subject, source,
  concept count, estimated first-mission duration, first concepts, idempotent
  **Add to my learning path**, ready state with **Start first mission**.

Boundaries: mission execution stays T13/T14 (`first_mission` is `null`, so
**Start first mission** renders disabled with an explanation); XP/reef stay
T15/T16 (nothing in ingestion awards XP); real offline sync stays T22; the full
Learning-path screen (UI/UX 9.8) is outside the task — T10 only adds the
**Add material** secondary action to the existing Learning detail placeholder.

## Architecture and Layering

The feature follows the established T07 consent/auth patterns exactly:

- `domain/` — immutable models and enums with `fromWireName` snake_case parsers
  and an `unknown` fallback, so additive server values can never crash a screen
  (FLOW-001). Built-value `EnumClass.name` returns the wire name, making the
  DTO→domain mapping a direct `DomainEnum.fromWireName(dto.x.name)`.
- `data/` — `IngestionRepository` (abstract + generated-client impl + mock in
  one file), `PresignedUploadClient`, `IngestionDraftStore`, `SourcePicker`,
  `ingestion_error_mapper.dart` (allowlisted copy; server `message` never
  rendered). Screens and controllers never touch transport types.
- `application/` — `StateNotifier` + `StateNotifierProvider` controllers
  (autoDispose families by subject/update id), providers overridden in
  `main.dart` (mock default, real when configured).
- New dependencies, each with a concrete task need: `crypto` (streaming SHA-256
  required by grant/finalize), `file_picker` (PDF/document selection),
  `image_picker` (camera + gallery per the source screens). Picked files are
  treated as untrusted data and held in memory only.

## State Machine and Screen Mapping

Screen states map 1:1 to the Flow §9.2 table. Terminal states (`committed`,
`deleted`, `expired`) never move backward; retry affordances are hidden on all
of them. `source_deletion_status` and per-upload deletion state render as a
separate card — a deleted source with committed knowledge still opens the
committed path. `uploading`/`processing` poll with capped backoff (2 s → 10 s);
after 10 s the UIX-019 plain-language status appears, after 10 minutes the
leave-and-return banner recommends navigating away (processing continues
server-side). Leaving and re-entering the status route always re-reads
authoritative state; no local status invention.

## Uploads

Raw bytes never pass through the API service. The presigned PUT uses a
dedicated `Dio` instance with no interceptors — only `grant.required_headers`
verbatim (asserted by test). Byte size and SHA-256 are computed before the
grant request; empty, oversized (> 25 MB) and unsupported files are blocked
before any network call. A server rejection always replaces local assumptions.
Storage 401/403/409 maps to a re-grant failure (not a generic error), 413 to
payload_too_large, 415 to unsupported_media_type.

## Durable Identity and Protected Drafts

One durable operation has one client identifier (FLOW-002, D4). Keys are
generated once per logical operation and persisted in the encrypted,
account-scoped `IngestionDraftStore` until a confirmed terminal outcome:

- create: `create` / `create_operation` (the create `client_operation_id`)
- grant/finalize per file: `grant:<updateId>:<sha>`, `finalize:<updateId>:<sha>`,
  `finalize_operation:<updateId>:<sha>` — scoped per update and file
- decisions: `verification_decisions:<updateId>:<sha256 of sorted batch>`
- commit: `commit:<updateId>`; retry/delete/draft keys follow the same pattern

Manual text persists as a protected local draft (secure storage,
`memora_ingestion_draft:<accountId>`), restored only for the same subject and
never across accounts; `clearAccount` runs on discard, successful commit and
sign-out. A `idempotency_key_reused` failure now clears the stale identity so
the student can restart the step with the draft preserved.

## Verification and Commit

Decisions stay local until submit; one batch per submission with one durable
key (a changed batch gets a new identity, a retry reuses the stored one);
only affected controls lock. `version_conflict`/`invalid_state` refresh the
update, keep safe edits (title-unchanged, still-open, valid merge targets) and
explain the result. Commit is idempotent and replay-safe; success clears the
draft, decision record and commit key. The ready state explains that the first
mission is not available yet while `first_mission` is `null`.

Unsent decisions persist per account+update (`memora_ingestion_decisions:
<accountId>`, UIX-033) because the controller is autoDispose. The persisted
copy is strictly a mirror: on a conflict reload the reconcile verdict is
authoritative and the store can never resurrect a dropped decision. A conflict
reload also fetches further candidate pages until every preserved decision's
candidate is present, so decisions beyond the first page survive.

## Navigation and Guards

New routes use the canonical Flow §3.3 names. Guards: addMaterial requires
session + consent + connectivity ("online consent"); materialStatus validates
ownership via the server (404 → not-found, indistinguishable from missing);
verifyConcepts requires `verification_required` (else redirect to status);
pathPreview requires a previewable update. Bottom navigation is visible on
addMaterial/materialStatus and hidden on verifyConcepts/pathPreview ("material
verification steps"). Recorded deviation: the existing `learningDetail` route
name is kept instead of the canonical `learningPath` to avoid T07 churn.

## Accessibility and Evidence

Every screen has one primary heading, semantic labels for progress/bands/states
(confidence bands are text + icon, never color alone), 48 px targets, and works
at 320 px and 200% text. Reduced motion is honored via the shared route page
builder. Golden evidence follows the T07 pattern; the UI/UX §13 Material state
matrix (empty/loading/success/recoverable/blocking + offline and
deletion-pending) is covered per screen.

## Bug Hunt Findings (Commit 10)

1. **Upload identities were scoped per file only** (`grant:<sha>`): attaching
   the same file to a second update replayed the same key with a different
   body → permanent `idempotency_key_reused`. Fixed by updateId scoping plus
   stale-key clearing on the reused-key failure.
2. **Create-collision deadlock**: a process death between create and restore
   plus a later text edit made the durable create key collide with a changed
   body forever. Fixed: the collision clears the create identity and keeps the
   draft; the abandoned server row expires via the T09 reconciler.
3. **Verification edits died with the controller** (autoDispose), violating
   UIX-033. Fixed with persisted decision drafts (above). Implementation note:
   the first draft of the fix resurrected a reconcile-dropped stale edit from
   the store; the existing "keeps only safe edits" test caught it, and the
   mirror-only rule is now locked by tests.
4. **Conflict reload dropped page-2 decisions.** Fixed by fetching further
   pages until preserved decisions are found (bounded at 20 pages).

Accepted behaviors, recorded deliberately: polling stays manual after a
transient mid-poll failure (banner retry) pending T22; a stale
`candidate_version` after an optimistic outcome converges through the 409
path; `listUpdates` is repository-complete but unused (no updates list screen
in T10).

## Verification Evidence

Environment: Flutter 3.47.9 / Dart 3.13.7 locally (CI pins 3.47.5; the project
requires ≥ 3.47.5). Contract checks ran with the backend virtualenv Python.

- `flutter analyze` (mobile) — No issues found (baseline unchanged).
- `flutter test` (mobile) — 474 passed: 467 from Commits 1-9 plus 7
  bug-hunt regressions in `mobile/test/ingestion/review_findings_test.dart`
  (one per finding, covering key scoping, reused-key recovery, create-collision
  recovery, decision persistence/restore/clearing and the page-2 conflict
  reload).
- `backend/.venv/Scripts/python.exe tools/contracts/generate_contracts.py
  --check` — exit 0; no OpenAPI or generated-client drift (T10 changed no API
  surface; the generated client was never hand-edited).
- Accessibility/state evidence: per-screen 320 px and 200% text tests,
  semantics tests, reduced-motion tests and golden captures for nine states.

## Known Limitations and Follow-ups

- `first_mission` is `null` until T13 wires mission creation into commit; the
  ready-state CTA stays disabled with an explanation.
- Connectivity is derived from failed requests (no connectivity plugin) —
  needs reviewer acknowledgement (guide decision D12); full offline
  reconciliation is T22.
- Home first-use **Add learning material** entry (UI/UX 8.1 step 5) waits for
  the Home authoritative read model.
- `learningDetail` → `learningPath` rename is a candidate cleanup.
- No in-app list of past updates in T10; reaching `materialStatus` for a
  restored flow relies on the submitted receipt or a future deep link (T19).

## References

- `docs/learning/T10_Implementation_Guide.md` — task boundary, decisions
  D1-D15, commit plan, bug-hunt checklist (local, git-ignored).
- `docs/learning/T07` context — auth/session, guard order and design-system
  patterns reused here; `docs/learning/T09_Study_Note.md` — backend contract.
- `docs/specifications/Memora_UI_UX_Design_Specification.md` §6-7, §8.3,
  §9.8-9.11, §11-13; `docs/screens/Material.png`, `docs/screens/Material-1.png`.
- `docs/specifications/Memora_App_Flow_and_Screen_State_Specification.md`
  §3.1-3.3, §9.
- `docs/specifications/Memora_API_and_Integration_Contract.md` §3-7, §11-12.
- `docs/specifications/Memora_PRD.md` §5-10; `Memora_TRD.md` §6.3.
