# T11 memory engine v1

This note explains the deterministic review scheduler implemented for T11: the
pure FSRS-style engine, the expert policy layer wrapped around it, the atomic
persistence contract, the outbox-driven worker consumer, the due-selection
inputs T13 consumes and the two owner-scoped read endpoints. It is a guide to
the code and its invariants, not a replacement for the specifications.

T11 targets `task/T11-memory-engine` and depends on T08 (curriculum graph),
which is Done. T09 (ingestion) is not merged on this branch, so exposure
evidence arrives through the documented producer envelope and is exercised with
synthetic outbox rows. The task table still lists T11 as Ready: nothing is Done
until the branch is reviewed and merged.

## 1. Contract surface

T11 owns two of the operations in the reviewed inventory:

| Operation | Method and path | Success |
| --- | --- | --- |
| `listConceptProgress` | `GET /v1/subjects/{subject_id}/concept-progress` | `200` |
| `getConceptHistory` | `GET /v1/concepts/{concept_id}/history` | `200` |

Both are read-only, bearer-authenticated, `private, no-store` and owner-scoped
through the standard identity path. Neither returns a raw engine value: the
client receives bands, stable identifiers, counters and allowlisted codes.
`listConceptProgress` is shared with T15, which extends the read model later
without a breaking change.

Everything else in T11 is library, worker or migration work with no HTTP
surface. Mission assembly (T13), XP/reef projections (T15) and mobile rendering
(T14/T16) stay outside this boundary.

## 2. The engine is a pure, versioned library

`modules/memory/engine/` has no database access, no clock reads and no
randomness. Every function takes explicit inputs plus an `EngineConfig` and
returns clamped values, so the same state, event, `now` and configuration
reproduce the identical decision bit for bit.

### Identity

Two versions travel together and are stamped on every decision row and every
calibration fixture:

- `ENGINE_VERSION = "fsrs-mvp-1.0.0"` — the quantitative model and its weights.
- `POLICY_VERSION = "policy-mvp-1.0.0"` — the expert rules layered on top.

`STATE_SNAPSHOT_SCHEMA_VERSION = "memora.memory_state/1"` versions the jsonb
envelope written to `memory_decisions.previous_state` and `result_state`.
`SELECTION_INPUT_VERSION = "memory-selection-inputs/1"` versions the contract
T13 consumes. The persistence layer passes the producing engine's version into
`to_snapshot()`, so a runtime configuration bump never relabels an older
snapshot: `result_state` carries the new version and `previous_state` keeps the
version of the engine that actually wrote it.

Every number the engine uses lives in the frozen `EngineConfig`. `validate()`
runs at import time, so a nonsensical weight table fails at startup rather than
producing an unverifiable schedule.

### The state

`LearnerConceptState` is an immutable dataclass that maps onto the Schema §10.1
columns:

```text
difficulty          1.0 – 10.0
stability_days      0.1 – 3650
last_retrievability 0 – 1   (computed at the last decision)
evidence_confidence 0 – 1   (blended, not a calibrated probability)
first_exposed_at    temporal anchor
last_reviewed_at    nullable until the first scored review
next_review_at      the schedule the engine produced
exposure_count / eligible_review_count / lapse_count
```

Snapshots serialise to a versioned jsonb object. Nothing reads a stored
snapshot without parsing it back through the same shape, so a historical row
cannot silently become a different structure.

### The formulas, in plain language

**Forgetting curve.** Recall probability decays as

```text
R(t) = (1 + (19/81) · t / S) ^ (-0.5)
```

clamped to `[0, 1]`. With those constants `R(t = S) = 0.9`, exactly the desired
retention, so *the scheduled interval in days is the post-review stability*.
That single identity is why scheduling never needs a separate conversion step.

**Grade mapping.** A normalised score in `[0, 1]` becomes a continuous
FSRS-style grade `G = 1 + 3·score` on `[1, 4]`. A score of `0.5` or more counts
as recall; below that it is a lapse.

**First exposure.** A concept seen for the first time starts with
`S = 0.5` days, `D = 5`, and a schedule produced by the first-review policy.
No scored review has happened, so there is no curve position to sit on.

**First scored review.** With no prior state the rating seeds stability
directly, as the FSRS family does:

```text
D0 = 5 - (G - 3)                 clamped to [1, 10]
S0 = exp(G - 3)                  clamped to [0.1, 3650]
```

A strong first attempt starts far out; a weak one starts near in.

**Successful recall.** Stability grows multiplicatively:

```text
S' = S · (1 + 3 · exp(0.8·(G-3)) · S^(-0.2) · (exp(0.5·(1-R)) - 1))
```

The growth factor shrinks as stability grows (`S^(-0.2)`) and grows with how far
down the curve the recall happened (`1 - R`): remembering something you had
nearly forgotten buys more interval than remembering something fresh.

**Lapse.** Stability collapses by a power law:

```text
S' = D^(-0.2) · (exp(0.3·ln(1+S)) - 1) · exp(0.3·(1-R))
```

Difficult concepts collapse harder, and a lapse on a well-rested concept costs
more than one on an already-shaky concept.

**Difficulty.** Each grade moves difficulty and then pulls it back toward the
initial value, so a single outlier cannot permanently mark a concept hard:

```text
D' = D - (G - 3)
D'' = 0.2·5 + 0.8·D'             clamped to [1, 10]
```

**Evidence confidence.** `c' = 0.7·c + 0.3·c_event`, clamped to `[0, 1]`. It is
a blend of how much evidence exists, never a probability claim.

Every transition is clamped to the schema bounds before it leaves the engine.
The engine also raises on out-of-contract input rather than guessing: a score
outside `[0, 1]`, an unknown event type, a naive datetime, or an exposure
carrying a score.

### One event, one decision

`decide(state, event, now)` is the only place a due date is produced. It
handles three shapes:

- no prior state → bootstrap (exposure) or first scored review;
- exposure on an existing state → record evidence, keep the existing schedule,
  blend confidence, increment the exposure counter;
- scored event on an existing state → the review transition above.

`invalidation` is metadata about a prior event. `apply_event` appends it and
returns no decision, `decide()` rejects it explicitly as a contract error, and
the corrective state change arrives as a later `manual_review` event, so
history is never rewritten. Out-of-order evidence (an `observed_at` earlier
than the state anchor) still produces a decision but is tagged
`out_of_order_evidence`.

## 3. The policy layer

`engine/policy.py` wraps the core transition with the educational constraints
the quantitative model must not know about. It is pure and it validates every
reason code and template key it emits against the closed allowlists.

| Bound | Rule | Reason code |
| --- | --- | --- |
| First review | First retrieval lands in 16–48 h. Below the floor it is raised to 16 h. Above the ceiling it is pulled back to 48 h unless the first attempt scored `≥ 0.8`, which justifies a later start. | `first_review_bounded`, `evidence_justified_schedule` |
| Confidence damping | Below `confidence_floor = 0.35` the stability and difficulty deltas are scaled by `confidence / 0.35`. At or above the floor the influence is full. | `low_confidence_damped` |
| Comeback | An absence longer than 7 days still uses real elapsed time for retrievability, but the next review is capped at `now + 3 days`. Prior state is never erased. | `comeback_elapsed` |
| Weak prerequisite | A lapse on a concept whose prerequisite is currently below 0.5 retrievability caps the next review at `now + 7 days`. | `weak_prerequisite_recover` |
| Interval cap | No schedule exceeds 180 days, so overdue work cannot compound into a backlog. | `interval_bounded` |

Damping is a scale on the *delta*, not on the result: the damped state is
`anchor + (result - anchor)·scale`. When the influence is full the damped and
undamped paths are identical, which is why the tests can assert that a
high-confidence event is untouched.

The governing explanation key follows a fixed precedence — weak prerequisite,
comeback, low confidence, then the core outcome key — so one decision never
presents two competing explanations.

### Shared rules, one implementation

Two rules are used by both the decision path and the read path, and both live in
exactly one place:

- `policy.is_comeback_elapsed(anchor, at)` — the comeback threshold.
- `prerequisites.is_weak_prerequisite_state(stability, anchor, now)` — the
  retrievability floor.

The flag a learner sees and the flag the planner ranks on therefore cannot
drift apart.

## 4. Persistence and duplicate convergence

One memory update is one database transaction: read the current snapshot under
a per-pair advisory lock, decide in Python, append-or-confirm the evidence
event, write the decision with both state snapshots, upsert the snapshot and
publish exactly one outbox event.

Migration `20261029_0006` provides three SECURITY DEFINER functions because
migration 0004 removed worker DML on user tables:

| Function | Responsibility |
| --- | --- |
| `memora_memory_context(user, concept)` | Takes `pg_advisory_xact_lock` on the `user:concept` pair and returns the snapshot without identity columns. |
| `memora_memory_record_event(...)` | Inserts the event with `ON CONFLICT DO NOTHING` on `(event_type, source_type, source_id, concept_id)` and reports `replayed`. Raises if the same identity resolves to a different owner. |
| `memora_memory_apply_decision(...)` | Replays an existing `(trigger_event_id, concept_id, engine_version)` decision, or inserts the decision, upserts the snapshot with `row_version + 1` and writes one `memory.schedule_changed` outbox row. |

The same migration adds:

- `ix_memory_events_delivery` on `(source_type, source_id)` for delivery dedupe
  lookups;
- a CHECK constraint restricting `reason_codes` to the twelve allowlisted codes
  and a non-empty array;
- a CHECK constraint restricting `explanation_template_key` to the eight
  published keys.

Both the API role and the worker role may execute the three functions; `PUBLIC`
is revoked. The API role can therefore record an event inside T13's grading
transaction and use the identical code path, which is what decision D9
reserves.

Duplicate delivery converges because the identities, not the call sites, decide:

- the same event delivered twice appends once and reports `replayed`;
- the same trigger event decided twice returns the stored decision without a
  second outbox row;
- a concurrent pair of transactions that both pass the existence check collide
  on the unique constraint and the loser re-reads the winner's decision.

`previous_state` is `None` in Python only for the bootstrap decision; the
database stores an explicit
`{"schema_version": "memora.memory_state.bootstrap"}` envelope so the column
stays a non-null object.

### Prerequisite signals

`prerequisites.py` reads the graph through `CurriculumService.get_prerequisites`
so edge semantics (`prerequisite_of`, approved, valid window, bounded depth and
result limit) have one implementation. It then checks the learner's own state
for each prerequisite and flags those below the retrievability floor.

The lookup is read-only by construction: prerequisite weakness changes reason
codes and selection inputs, never another concept's state. A prerequisite the
learner has never touched is a curriculum-coverage matter, not weak memory, and
is not flagged.

## 5. The worker consumer

`worker/memory.py` runs the outbox-driven loop and `worker/main.py` is the
entry point.

### Job shape

Job type `memory.process_event` carries one `outbox_event_id` and nothing else.
The payload is `{"schema_version": "1", "outbox_event_id": "..."}`. Evidence is
read from the producer event, not from the job, so the job cannot be used to
inject facts.

### Producer envelopes (decision D9)

| Event type | Aggregate | Required payload |
| --- | --- | --- |
| `learning_update.committed` | `learning_update` | `user_id`, `learning_update_id`, `committed_concepts[]` with `concept_id`, `concept_version_id`, `confidence` |
| `mission.attempt_graded` | `attempt` | `user_id`, `attempt_id`, `concept_grades[]` with `concept_id`, `concept_version_id`, `score`, `confidence`, optional `memory_event_type`, `is_eligible`, `ineligibility_reason` |

`memory_event_type` may be `attempt`, `repair`, `regrade` or `manual_review`.
Numbers must be JSON numbers inside `[0, 1]`; booleans and numeric strings are
rejected. An envelope spanning more than one `user_id` is rejected. The
producer event's `created_at` is the evidence `observed_at`.

Both envelopes are a shared contract with T09 and T13, which are not merged on
this branch. T11 implements the consumer against the documented shape and
exercises it with synthetic outbox rows; the naming needs reviewer
acknowledgement before T13 starts emitting it.

### Failure handling

- **Unknown event type** — the job succeeds with zero concept updates. It is not
  a retry and not a dead letter.
- **Known envelope, malformed payload** — `invalid_event_payload`, dead-lettered
  immediately. A poison payload must not consume the retry budget or block the
  queue.
- **Missing source event** — `source_event_missing`, dead-lettered.
- **Anything else** — `processing_failed`, retryable, backing off
  `15 / 60 / 180 / 600 / 1800` seconds across five attempts, then dead-lettered.

`attempt_count` is incremented at claim time, so a worker that crashes mid-job
still consumes an attempt. Leases last 120 seconds; the reconcile pass returns
expired leases to the queue and dead-letters those that exhausted their
attempts.

Reconciliation also enqueues one job per memory-relevant producer event that has
no job, keyed by `dedupe_key = 'memory:outbox:<id>'` with
`ON CONFLICT DO NOTHING`. Because the existence check ignores job status, a
dead-lettered payload is never resurrected by reconciliation; it stays
quarantined until an operator fixes it.

### Roles

The job lifecycle runs as `memora_worker`, which can read `outbox_events` and
read/update `background_jobs`. The evidence transaction runs as `memora_api`
with `memora.user_id` set for the envelope's learner, so the prerequisite lookup
is RLS-scoped and the memory writes still go through the SECURITY DEFINER
functions. The worker connection must be able to assume both roles.

All concepts of one producer event are applied in a single transaction: either
the whole envelope lands or none of it does.

### Ineligible evidence

Evidence flagged `is_eligible: false` is appended for the audit trail with its
`ineligibility_reason` but drives no decision and no schedule change. T13 calls
`attempt_evidence_eligibility()` before emitting; T11 only honours the flag.

## 6. Due-selection inputs for T13

`selection.py` answers one question: which of this learner's concepts in this
subject are due or nearly due, and what signals does a planner need to rank
them? It deliberately performs no ranking, no diversity selection and no
workload cap — those belong to T13.

Each candidate carries:

```text
concept_id, concept_version_id, stable_code, title
next_review_at, last_reviewed_at, urgency, overdue_days
retrievability, retrievability_band, forgetting_risk
evidence_confidence, recent_error_severity, recent_error_count
lapse_count, exposure_count, eligible_review_count
is_new_concept, is_comeback, prerequisite_impact
weak_prerequisite_concept_ids, coverage_objective_ids
selection_reason
```

Urgency bands are `overdue` (before `as_of`), `due` (within one day) and
`near_due` (inside the requested horizon).

The governing reason follows a fixed precedence, and only the five codes T11
can justify from memory state, graph signals and recent evidence are emitted:

1. `weak_prerequisite_failure` — recent errors **and** a weak prerequisite.
2. `high_error_rate_repair` — recent errors above the severity floor.
3. `forgetting_curve_overdue` — the review is past due.
4. `new_concept_introduction` — the concept has no scored review yet.
5. `daily_retention_protect` — everything else inside the horizon.

`misconception_detected` and `streak_preservation` are reserved for T13/T15.
The vocabulary is the shared mission reason list from `curriculum/constants.py`,
not a second private enum.

### Bounds

| Bound | Value |
| --- | --- |
| Page size | default 20, maximum 50 |
| Horizon | default 3 days, maximum 30 |
| Recent-error window / sample | 14 days / 5 events |
| Recent-error severity floor | mean `1 - score ≥ 0.4` |
| Coverage objectives per candidate | 10 |
| Weak-prerequisite rows per page | 500 |

Weak prerequisites are resolved with one bounded set query per page rather than
one query per candidate. Nothing outside the horizon leaves the backend, so
there is no hidden candidate pool for a client to mine.

### Cursors

Cursors are opaque keyset positions `(next_review_at, concept_id)` encoded as
URL-safe base64. They are bound to a scope string, for example
`memory.due-selection/1/<subject>/<horizon>`, and a mismatch is rejected. A
cursor therefore cannot be replayed against another endpoint, another subject
or a materially different horizon.

## 7. The two read endpoints

`api/v1/memory.py` and `modules/memory/service.py` project persisted state into
client-safe models. The projection is a whitelist: each item is built field by
field from the selection candidate or the stored row, FastAPI serialises only
the declared response model, and the closed `Literal` types mean an unknown
band, reason code or template key fails validation instead of reaching a client.

### `GET /v1/subjects/{subject_id}/concept-progress`

Returns one bounded page of due and near-due concepts in next-review order for
the requested horizon (default 3 days, maximum 30). Each item carries stable
IDs, `title`, `state_band`, `confidence_band`, `review_window`,
`next_review_at`, `last_reviewed_at`, the three counters, the new/comeback flags
and a non-null `due_reason`.

`due_reason` is a small object, not prose composed in the route:

```json
{
  "reason_code": "forgetting_curve_overdue",
  "template_key": "memory.due_reason.overdue",
  "message": "This review is overdue. A short review now brings it back on track."
}
```

`template_key` is the copy contract for T14. `message` is the server-authored
accessible fallback, derived only from the allowlisted code — no interpolation
of stored evidence, no free text, no model output.

The endpoint reuses `selection.list_due_candidates` rather than duplicating the
query, so the numbers a learner sees and the inputs T13 ranks are the same
query result.

### `GET /v1/concepts/{concept_id}/history`

Returns the concept's current band, next review, a bounded evidence summary and
one page of scheduling decisions, newest first.

The evidence summary contains lifetime counts, so
`total_events == sum(counts_by_type.values())` always holds, plus
`recent_events` for the 90-day window, `last_observed_at` and a confidence band.
Per-type counts are deliberately not windowed: keeping every count additive
makes the payload verifiable by a client without a second request.

Each explanation carries the decision ID and time, the trigger event type, the
scheduled next review, the allowlisted reason codes, the template key, the
fallback message and both version stamps.

The queries select no `event_payload`, no `previous_state`, no `result_state`
and no stability or difficulty value, so a leak would require editing the
whitelist. Tests assert that those strings never appear in a serialised
response.

### Ownership and errors

Both routes resolve the caller through `memora_resolve_user_id`, set
`memora.user_id` for RLS and query with the resolved owner. An unknown subject,
an unknown concept and another learner's concept all return the same
`404 resource_not_found`, so a random identifier cannot confirm that a resource
exists. A malformed or wrongly scoped cursor returns `400 invalid_cursor`. Both
errors use the shared envelope with a `request_id`.

`main.py` already sets `Cache-Control: private, no-store` for every `/v1/`
response, so the endpoints inherit it; the tests assert the header on both
routes rather than trusting the middleware by inspection.

## 8. Decisions and why

| # | Decision | Why |
| --- | --- | --- |
| D1 | The engine is a pure library with explicit inputs, no clock, no DB, no randomness. | The acceptance gate is reproducibility; a hidden clock read or query would break it silently. |
| D2 | Engine identity is the pair `fsrs-mvp-1.0.0` / `policy-mvp-1.0.0`, stamped on every decision and fixture. | Weights are versioned configuration (TRD §9.4); a historical decision must remain explainable against the exact rules that produced it. |
| D3 | FSRS-style math is implemented in-repo with clamped, bounded updates and conservative defaults. | A package would import unverifiable behaviour; the acceptance gate requires every bound to be testable. |
| D4 | An event's influence scales with its confidence and is damped below the floor. | Sparse or uncertain evidence must not produce a dramatic schedule jump (TRD §9.5). |
| D5 | Overdue and comeback are bounded: elapsed time drives retrievability, but the next review never compounds backlog. | A 90-day absence must produce a manageable plan, not 90 days of work (PRD 015). |
| D6 | One event, one decision, enforced by two unique constraints; replay returns the stored decision. | Duplicate delivery is normal in an outbox system and must converge instead of double-counting (Schema §10.2-10.3). |
| D7 | Event, decision, snapshot and outbox event commit in one transaction, with no provider call open. | Schema §14.2; a partial write would leave the schedule and its evidence inconsistent. |
| D8 | The worker never writes user tables directly; three SECURITY DEFINER functions carry the writes. | Migration 0004 removed worker DML; this keeps the privilege boundary intact while still allowing T13 to share the code path. |
| D9 | The two producer envelopes are defined here and implemented against synthetic outbox rows. | T09/T13 are not merged; the contract is documented and reviewer acknowledgement is requested before T13 emits it. |
| D10 | Reason codes and template keys are closed allowlists in code and CHECK constraints in the database. | A decision must be explainable from its codes alone; an invented code would have no copy and no meaning. |
| D11 | Every write is scoped to exactly one `(user_id, concept_id)`; prerequisite signals are read-only. | Per-pair independence is the core product promise (PRD 011). |
| D12 | The endpoints return bands, counts and allowlisted codes only, with scope-bound cursors. | Clients must not receive hidden candidate scores or payload internals (TRD §9.4, API §3-7). |
| D13 | No learning text, answers, tokens or authorization headers are logged; job payloads carry IDs. | API §19, AGENTS §7; a worker log is a much wider audience than a request. |

Two sub-decisions are worth recording because they were not in the original
plan:

- **Selection reasons reuse the mission vocabulary.** Commit 5 imports the
  shared `REASON_CODES` rather than defining a second private enum, and exposes
  only the five codes T11 can justify. Two vocabularies for the same concept
  would drift.
- **Shared rules moved out of the policy body.** `is_comeback_elapsed()` and
  `is_weak_prerequisite_state()` were extracted so the decision path and the
  read path call one function instead of two copies of the same comparison.

## 9. Verification

Run from the repository root with the backend virtual environment active.

```powershell
backend\.venv\Scripts\python.exe -m ruff format --check backend
backend\.venv\Scripts\python.exe -m ruff check backend

# disposable database, name must end in _test or _ci
$env:MEMORA_TEST_DATABASE_URL = 'postgresql+psycopg://memora:<local-password>@127.0.0.1:5432/memora_migration_test'
backend\.venv\Scripts\python.exe -m pytest backend\tests

backend\.venv\Scripts\python.exe tools\contracts\generate_contracts.py --check

cd contracts\dart\memora_api_client
dart test
```

Results recorded for this branch:

- Ruff lint and format checks pass across `backend` (91 files formatted).
- Full backend suite with `MEMORA_TEST_DATABASE_URL` configured: **432 passed**,
  one existing Starlette/httpx deprecation warning. Of those, **182** are the
  T11 suites below.
- `generate_contracts.py --check` exits `0` after export, generation, formatting
  and comparison.
- Generated Dart client tests: **171 passed**, including the six new model
  suites and `CurriculumApi`.

| Suite | Covers |
| --- | --- |
| `test_memory_engine.py` | determinism, clamps, monotonic sanity, snapshot round-trips, seeded 200-event fuzz, invalid inputs, invalidation as metadata |
| `test_memory_policy.py` | first-review window, confidence damping, comeback, weak prerequisite, interval cap |
| `test_memory_persistence.py` | append-only evidence, sequential and concurrent duplicate delivery, per-concept and per-learner isolation, transaction atomicity, invalidation without a decision, engine-version bumps, outbox key uniqueness, `SET LOCAL` isolation, worker grant negative, RLS |
| `test_memory_selection.py` | due inputs, urgency bands, reason precedence, caps, cursor scoping, limit boundaries, prerequisite write isolation |
| `test_memory_simulation.py` | versioned calibration fixture and 30-day calendar for the four gate scenarios |
| `test_memory_worker.py` | envelope mapping, retry/backoff, dead-lettering, lease recovery, log safety |
| `test_memory_endpoints.py` | explanation copy, service mapping, bounds, `no-store`, owner-negative matrix, pagination, OpenAPI security and envelopes |

The four acceptance scenarios are covered by
`backend/tests/fixtures/memory/calibration_v1.json` (`memory-calibration/1`),
which records the engine and policy versions it was calibrated against. The
simulation replays each scenario across a 30-day calendar and asserts the
schedule stays inside the expert bounds at every step.

## 10. Boundaries and follow-ups

- **T13** owns mission assembly. T11 supplies typed selection inputs and
  `selection_reason`; it never produces a mission, a ranking or a workload cap.
- **T13** must emit `mission.attempt_graded` (or call
  `MemoryRepository.record_event` inside its grading transaction) and must
  honour `is_eligible` / `ineligibility_reason` from
  `attempt_evidence_eligibility()`. The envelope names need reviewer
  acknowledgement first.
- **T15** extends `concept-progress` additively with reef, XP and streak fields.
  Nothing in T11 reserves those field names.
- **T14** renders the `template_key` values. The server-side `message` is a
  fallback, not the primary copy source.
- **T09** is unmerged; `learning_update.committed` is exercised only through
  synthetic outbox rows. Wiring the real producer is T09's job.
- `memory_decisions` has no `(user_id, concept_id, decided_at)` index. History
  reads are bounded per concept but scan the concept's decision rows. A
  follow-up migration should add the composite index once history volume is
  real; it was not added here because T11's migration is already scoped to the
  worker-access contract.
- `migrations/env.py` calls `fileConfig(..., disable_existing_loggers=True)`,
  which disables `memora.worker.memory` for the rest of a process after the
  first migration runs. The worker log-safety test re-enables it, but the
  cleaner fix is `disable_existing_loggers=False` in a shared-config change.
- `tools/docs/*.py` carries pre-existing lint debt (import sorting, one unused
  import, one `PIE810`). It is outside the T11 boundary and untouched.
- T11 must not be marked Done until the branch is reviewed, merged and the task
  table records the code, tests, migration, generated artifacts and this note.

## Specification map

- PRD 011-016 (per-pair state, first retrieval near the next day,
  prioritisation inputs, comeback, visible why).
- TRD 3.2-3.3, 4, 9 (module boundaries, AI authority, memory architecture and
  the versioned expert policy).
- Backend Schema 2, 3, 10, 13, 14.1-14.2 (state columns and bounds, reason-code
  allowlists, outbox and job contracts, the memory transaction boundary).
- API and Integration Contract 3-7 and 10, plus the `listConceptProgress`
  (T11/T15) and `getConceptHistory` (T11) inventory rows.
- Task table T11 scope and acceptance gate.
