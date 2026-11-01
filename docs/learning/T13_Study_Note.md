# T13 mission backend

T13 implements deterministic daily mission planning and the full server-side mission
lifecycle on `task/T13-mission-backend`. The task is implemented but is not marked
Done until review and merge. T14 owns the mobile mission experience. T15 owns XP,
streak and reef projections.

## Policy boundary

- A plan contains no more than six questions and no more than seven estimated
  minutes. Selection stops at the first limit and never adds filler.
- Ranking is deterministic and versioned. It combines T11 due-selection signals,
  prerequisite weakness, confidence, overdue severity, comeback state and T12 source
  precedence. Stored input and priority snapshots make a plan auditable.
- Only approved, non-disputed expert or AI question versions are eligible. Teacher
  content stays disabled until its provenance policy exists.
- Short-answer grading remains available in T12 but short-answer questions are not
  selected automatically in the initial mission policy.
- One repair question may be appended after a confidently weak or misconception
  result. A mission can never exceed seven total items.

## Transaction and recovery model

Every private lookup derives the learner from the validated request context and runs
with the database RLS context set. Lifecycle mutations lock the mission row, and
idempotency records bind each key to a request hash. Replaying the same logical action
converges; changing the payload for an existing key is rejected.

Question versions are pinned in mission items and the public item payload is produced
by T12's redacting snapshot model. Attempt persistence, deterministic grading, item
state, repair insertion and `mission.attempt_graded` outbox publication share one
transaction. Pause and resume preserve the current item. Skip advances without
creating grading evidence. Completion is allowed only after every item is answered or
skipped, stores a stable summary, and publishes exactly one `mission.completed` event.

## T13/T15 staged result contract

T13 completion results contain stable learning and completion facts and explicitly
report engagement processing as pending. The `mission.completed` outbox event is the
handoff to T15, which will add authoritative XP, streak and reef results. T13 does not
derive or grant game state.

## Shared surfaces

Migration `20261101_0014` adds completion-summary and attempt-request-hash constraints
plus mission lookup indexes. The OpenAPI artifact and generated Dart client include
the nine mission operations and typed answer payloads. Generated client files are
regenerated from FastAPI and are never hand edited.

## Verification

Focused coverage includes deterministic ranking, workload limits, owner isolation,
hidden answer keys, pinned versions, concurrent start/answer/completion convergence,
changed-request rejection, repair insertion, pause/resume, skip, lock-timeout recovery,
atomic rollback on outbox dependency failure, producer-event replay, migration
upgrade/downgrade, OpenAPI drift and generated Dart compilation/tests.

## Specification traceability

- PRD requirements 013-022: planning, trust, workload, lifecycle and recovery.
- TRD sections 9 and 12-13: modular backend, deterministic rules, transactions,
  idempotency and outbox reliability.
- UI/UX sections 8.2 and 9.12-9.16: mission states and truthful completion boundary.
- Backend Schema sections 11 and 13-16: missions, attempts, question versions, memory
  evidence and outbox persistence.
- App Flow sections 10, 14 and 20: start/resume/pause/skip/completion and recovery.
- API contract section 13: mission routes, safe payloads and mutation semantics.

## Known follow-up

T15 must consume `mission.completed` idempotently and extend the completion result with
engagement projections. Enabling short-answer mission selection requires the approved
model evaluator and quality gate; T12's deterministic short-answer interface remains
available for that future policy.
