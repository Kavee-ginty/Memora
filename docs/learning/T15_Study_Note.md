# T15 progress, XP, streak and reef backend

T15 implements the authoritative engagement module on
`task/T15-progress-backend`. It consumes T13's `mission.completed` outbox event,
waits for its attempt-memory jobs, applies engagement consequences once, and
updates the stable mission result. T16 owns mobile presentation. T19 consumes
the `reward.granted` envelope and validates its deep link through the reward
inventory read model.

## Approved decisions

### XP policy `xp-v1`

- Protected memory: 6 XP.
- Repaired memory: 6 XP.
- Mission completion with at least one protected or repaired memory: 10 XP.
- Comeback completion: 6 additional XP.
- Normal cap: 46 XP; comeback cap: 52 XP.
- An all-skipped or unresolved mission earns zero.
- One `mission.completed` outbox event can create one earn ledger row. Repairs
  are already represented by the authoritative repaired count and never create
  a second item award.

Equal protected/repair values avoid penalising a learner who needed repair and
avoid making an incorrect first answer more valuable. There are no boosts,
leaderboards, upload awards or app-open awards. The existing approved reward
thresholds remain 100, 300, 500 and 1,000 XP.

### Streak policy `streak-v1`

The persisted mission date and mission timezone decide the streak day. An
active mission keeps its anchor across a preference change. A two-date gap may
insert the immediately preceding day as `grace_used` only when the rolling
seven-date window contains no earlier grace. Longer gaps produce
`comeback_completed`. Rows are append-only and duplicate completion is harmless.

### Reef policy `reef-v1`

The five canonical conditions are `new`, `thriving`, `healthy`, `needs_care`
and `dormant`. PRD 026 was corrected to match the previously consistent schema,
API, flow and UI contracts.

```text
health = 0.50 * retrievability
       + 0.25 * (1 - due_ratio)
       + 0.15 * (1 - prerequisite_risk)
       + 0.10 * recent_evidence
```

- No eligible scored retrieval evidence: `new`, neutral score 0.5.
- No eligible activity for 30 complete days: `dormant`.
- Score at least 0.80, due ratio at most 0.10 and prerequisite risk at most
  0.25: `thriving`.
- Score at least 0.60 and due ratio at most 0.35: `healthy`.
- Otherwise: `needs_care`.

The source watermark, projected time and policy version make rebuild comparison
explicit. One answer influences only its concept and bounded recent aggregate;
it cannot directly set the subject state.

### Permanent ownership and mutable placement

`reward_grants` remains append-only. The separate `reward_placements` table
contains owner-scoped optimistic-concurrency state. Grant creation emits only
schema version, server-derived owner and opaque grant ID. T19 may use
`GET /v1/rewards?grant_id=...` to confirm ownership and whether the reward is
still unplaced before navigation. Placement never affects learning priority.

## Processing and recovery

The durable job key is `engagement:outbox:<event-id>`. The consumer serializes
consequences per learner, uses ledger/grant uniqueness for concurrency safety,
and updates the mission summary only after XP, streak, rewards and reef commit.
It defers while related memory jobs are incomplete. Replaying a succeeded or
unknown-outcome job returns the persisted logical result.

## API boundary

T15 implements `getHome`, `getSeabed`, `getReef`, `getProgressStatistics`,
`listRewards` and `updateRewardPlacement`. Reads derive ownership from the
validated session. Statistics are bounded to 93 days and use the requested
validated IANA timezone. Reward mutation requires both optimistic version and
idempotency key.

## Specification traceability

- PRD 023-030.
- TRD sections 3, 4, 6 and 13.
- UI/UX sections 9.7, 9.16-9.19 and 10.
- Backend Schema sections 12, 14, 16, 18 and 21.
- App Flow sections 10.5, 11 and 14.
- API sections 10, 13.5 and 14.

## Task boundaries

T15 does not render the seabed or statistics, deliver push notifications,
invent offline projections, or alter memory schedules. Those remain T16, T19,
T22 and the memory module respectively.

## Audit and acceptance evidence

The final audit added database-backed coverage for one-event/one-ledger-entry
processing, replay-stable completion results, permanent reward grants,
wrong-owner reward reads and placement, deterministic projection rebuilds,
authoritative Home/statistics reads, learner-local Home dates and late-effective
XP corrections. It also verifies the T15 columns, placement RLS, role grants and
balance index through the migration contract.

Audit fixes made before handoff:

- Completion streaks use the schema value `mission_completed`, matching the
  persisted streak contract.
- Home selects only the learner's current local-day mission and evaluates streak
  freshness in the learner's timezone.
- Current XP balance follows append order, while statistics continue to group by
  the effective `earned_at` date.
- Engagement replay returns the same JSON-normalized result as the first run.
- The historical privacy downgrade removes target-only proof rows that its older
  exclusive-source schema cannot represent, allowing a complete downgrade and
  re-upgrade on the disposable database.
- The generated-client analyzer baseline includes the three T15 API groups, and
  `opentelemetry-api` is locked to the vulnerability-fixed `1.45.2` release.

Verified on 2026-11-14 with backend Ruff format/lint, the complete PostgreSQL
backend suite including downgrade/re-upgrade, OpenAPI/client drift generation,
generated Dart tests, generated-client contract analysis/tests, full Flutter
format/analyze/tests, Compose configuration and production/development Python
dependency audits.
