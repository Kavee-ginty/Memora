# Database migrations

T04 owns the Alembic environment and the MVP schema defined in the backend data-model specification.

From `backend/`:

```powershell
alembic upgrade head
python -m memora.db.seed
alembic current
```

The initial migration enables `pgcrypto` and `vector`, creates the complete empty-database schema, applies constraints, indexes, RLS and immutable-row triggers, and inserts only approved foundational seed data. The seed command is idempotent and is the extension point for later task-owned reviewed content.

Migration tests downgrade to base. Set `MEMORA_TEST_DATABASE_URL` only to a disposable database whose name ends in `_test` or `_ci`; the test fixture rejects any other name. Never reuse `MEMORA_DATABASE_URL` from `.env`, because that URL can point at a shared or deployed database. Run the host commands with `127.0.0.1`; the Compose hostname `postgres` resolves only inside the Compose network.

Alembic waits at most 10 seconds for a database connection by default. Set `MEMORA_DB_CONNECT_TIMEOUT_SECONDS` to a positive integer to change that bound.

The access-hardening migrations remove blanket service-role grants. Student API access is owner-scoped for private rows and read-only for approved shared academic content. Indirect private records such as grading results and deletion proofs inherit ownership through their required parent relationships. The worker can access only operational outbox, job and service-idempotency rows; later worker features must add narrowly scoped policies or security-definer functions.

Session bootstrap resolves an internal user ID through a security-definer function that accepts only the validated OIDC issuer and subject. Grading evidence remains immutable while an authoritative result may be demoted before its replacement is appended in the same transaction. The outbox enforces publication-status and timestamp agreement on both insert and update.

Product values that remain open are intentionally not guessed in T04. T09 owns upload limits, T11 owns initial memory and policy versions, T13 owns the mission item cap, T15 owns reward definitions and XP thresholds, and T17 owns the reminder cap. Each task must add its approved value through a reviewed forward migration when the corresponding contract is finalized.

T17 finalizes notification frequency at a maximum of three reminders per user-local day,
with one reminder per day as the default. A student may set the value to zero or disable
notifications and individual categories without blocking normal application use.

## Recovery

The production recovery path is roll-forward: correct the migration in a new reviewed revision and run `alembic upgrade head`. Do not downgrade a database containing user data. The initial downgrade drops the complete `public` schema and exists only for empty/local migration testing where data loss is explicitly acceptable.

After restoring a backup, keep API traffic disabled until retention/deletion reconciliation and rebuildable projections have run. Those operational reconcilers belong to their later feature tasks.

No vector ANN index is created yet. The specification requires representative recall and latency measurements before choosing HNSW or IVFFlat; exact scans are correct for the initial empty/pilot-sized schema.
