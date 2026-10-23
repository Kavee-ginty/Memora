# Memora T01 and T04 study note

This note explains the main ideas implemented in T01 and T04. It is a guide to the code, not a replacement for the project specifications.

## The big picture

Memora is a Flutter mobile app backed by a FastAPI modular monolith, a separate worker, and PostgreSQL with pgvector.

- **T01 — Architecture baseline and repository scaffold:** created the places where later work belongs and proved that the smallest mobile and backend applications run.
- **T04 — PostgreSQL migrations and seed framework:** created the MVP database structure and made important privacy and consistency rules enforceable by PostgreSQL.

T01 is **Done**. T04 is currently **Review**, so its database design should not yet be described as merged or production-ready.

## T01: architecture baseline

### 1. Repository structure and separation of responsibility

The repository is organized by responsibility:

```text
mobile/       Flutter application
backend/      FastAPI API, worker, migrations, and backend tests
contracts/    Future shared OpenAPI and JSON contracts
infra/        Local infrastructure definitions
content/      Reviewed academic content
docs/         Product, technical, UI, data, and flow specifications
tools/        Documentation and development utilities
tests/e2e/    Cross-system tests
```

This is a **monorepo**: related applications and contracts live in one repository. The folders still have clear ownership, which reduces accidental coupling.

### 2. Flutter, Riverpod, and go_router

Flutter provides the cross-platform mobile UI. The root widget uses `MaterialApp.router`, while `go_router` owns navigation. Riverpod's `ProviderScope` is installed at the application boundary so later features can add immutable state providers without changing startup.

```dart
void main() {
  runApp(const ProviderScope(child: MemoraApp()));
}

return MaterialApp.router(
  theme: MemoraTheme.light(),
  routerConfig: appRouter,
);
```

At T01 this is intentionally only a shell. Authentication guards, feature state, full design tokens, and real screens belong to later tasks.

Read: `mobile/lib/main.dart`, `mobile/lib/src/app.dart`, and `mobile/lib/src/routing/app_router.dart`.

### 3. FastAPI and Pydantic

FastAPI exposes the HTTP application. `create_app()` is an **application factory**: configuration and routers are assembled in one place, which makes startup and testing predictable. Pydantic validates both settings and response shapes.

```python
def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="Memora API",
        docs_url="/docs" if settings.environment != "production" else None,
    )
    app.include_router(health_router)
    return app
```

The live health endpoint answers whether the process is running. The ready endpoint is still a T01 placeholder; T02 will add dependency checks.

Read: `backend/src/memora/main.py` and `backend/src/memora/api/health.py`.

### 4. Configuration with pydantic-settings

`Settings` reads `MEMORA_` environment variables and validates allowed environments. `database_url` has `repr=False`, reducing the chance that credentials appear in debug output. `@lru_cache` creates one settings object per process.

```python
class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="MEMORA_", extra="ignore")
    environment: Literal["local", "development", "staging", "production"] = "local"

@lru_cache
def get_settings() -> Settings:
    return Settings()
```

The `.env.example` documents variable names only. Real credentials must remain outside Git.

Read: `backend/src/memora/core/config.py` and `backend/tests/test_config.py`.

### 5. Docker Compose and pgvector

`infra/compose.yaml` describes reproducible local services. PostgreSQL uses the pgvector image because Memora will store embeddings alongside relational data. The API waits for the database health check and both ports bind to localhost.

```yaml
postgres:
  image: pgvector/pgvector:pg16
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
```

Compose is a local development convenience; it is not the production deployment design.

### 6. Tests and quality tools

Pytest checks the backend behavior, while Flutter's widget test checks that the application shell renders. Ruff handles Python linting and formatting rules. Lock files make dependency installation repeatable.

```python
response = await client.get("/health/live")
assert response.status_code == 200
assert response.json() == {"status": "ok"}
```

The useful lesson is that a scaffold still needs executable proof. A folder layout alone does not prove that the application starts.

## T04: PostgreSQL schema and data safety

### 1. PostgreSQL as the authoritative data store

T04 represents identity, curriculum, ingestion, questions, memory, missions, engagement, reliability, and privacy in 48 related tables. UUID primary keys, foreign keys, UTC-aware `timestamptz` values, status checks, and unique constraints preserve meaning at the database boundary.

For example, a learning update cannot use an unknown input type or status, and the same user's client operation cannot create duplicates:

```sql
CREATE TABLE learning_updates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  input_type text NOT NULL CHECK (input_type IN ('manual_text','pdf','image','mixed')),
  status text NOT NULL CHECK (status IN
    ('draft','uploading','processing','verification_required','committed','failed','expired','deleted')),
  client_operation_id uuid NOT NULL,
  UNIQUE(user_id, client_operation_id)
);
```

Application validation gives friendly errors; database constraints remain the final protection when multiple code paths write concurrently.

### 2. Alembic migrations

Alembic applies ordered, versioned database changes. Each Python revision records its parent and executes a reviewed forward or reverse SQL file.

```python
revision = "20261023_0003"
down_revision = "20261023_0002"

def upgrade() -> None:
    _run_script("20261023_0003_worker_state_transitions.up.sql")
```

The production recovery strategy is **roll forward** with a new corrective migration. The destructive downgrade exists only for empty/local migration testing.

Read: `backend/migrations/versions/` and `backend/migrations/README.md`.

### 3. Row-level security and least privilege

PostgreSQL Row-Level Security (RLS) adds database-side tenant isolation. The API sets the authenticated user's ID in the transaction, and policies allow private rows only when their owner matches it. Separate `memora_api` and `memora_worker` roles receive only the operations they need.

```sql
CREATE POLICY idempotency_records_worker_service ON idempotency_records
FOR ALL TO memora_worker
USING (user_id IS NULL)
WITH CHECK (user_id IS NULL);
```

This policy lets the worker manage service-owned idempotency rows, not a student's rows. RLS is defense in depth; the API must still derive ownership from the validated session and authorize every request.

### 4. Idempotency, outbox events, and worker state

Mobile networks retry requests. `idempotency_records` stores a stable operation key so repeating the same mutation converges on one result. `outbox_events` records domain events in the same database transaction as business changes so a worker can publish them reliably later.

The event evidence is immutable, but the worker may change delivery fields such as `publication_status` and `published_at`. The third migration added a trigger that permits those narrow state transitions while rejecting payload changes and deletes.

This is the important distinction:

- **Business evidence** stays unchanged.
- **Processing state** may move through explicitly allowed transitions.

### 5. Seed data

The seed command inserts the approved Physics subject and curriculum identity. `ON CONFLICT DO NOTHING` makes the operation idempotent, so running it twice does not create duplicates.

```sql
INSERT INTO subjects(id, code, name, status)
VALUES (:subject_id, 'physics', 'Physics', 'approved')
ON CONFLICT (code) DO NOTHING;
```

Seeds contain shared reference data, never real users, production content, or secrets. T08 owns the detailed Physics knowledge graph.

Read: `backend/src/memora/db/seed.py`.

### 6. Database integration tests

The migration tests verify more than table creation. They exercise upgrade/downgrade/upgrade, repeatable seeds, cross-user isolation, invalid statuses, append-only evidence, role grants, graph-cycle rejection, worker transitions, and service-owned idempotency.

```python
connection.execute(text("SET LOCAL ROLE memora_api"))
connection.execute(
    text("SELECT set_config('memora.user_id', :user_id, true)"),
    {"user_id": user_two},
)
assert connection.scalar(text("SELECT count(*) FROM learning_updates")) == 0
```

This negative test is valuable because security is demonstrated by proving what another user **cannot** read or write.

Read: `backend/tests/test_migrations.py`.

## How the two tasks fit together

T01 established the process and runtime boundaries. T04 filled one shared boundary—the database—with durable contracts. Later feature tasks should reuse these foundations rather than bypass them:

1. Flutter sends typed API requests; it does not access PostgreSQL.
2. FastAPI validates identity and business intent.
3. PostgreSQL enforces relationships, ownership, valid states, and deduplication.
4. The worker handles durable background transitions with a restricted role.
5. Tests prove both successful behavior and forbidden behavior.

## Quick self-check

You understand these tasks if you can answer:

1. Why are `mobile`, `backend`, `contracts`, and `infra` separate folders in one repository?
2. What is the difference between `/health/live` and `/health/ready`?
3. Why should secrets come from environment variables instead of source code?
4. What problem does an Alembic revision solve?
5. Why are API authorization and PostgreSQL RLS both needed?
6. How do a unique operation key and `ON CONFLICT` make retries safer?
7. Why may an outbox event's publication status change while its payload cannot?

## Specification map

- T01: TRD sections 3, 5, and 18; repository workflow documents.
- T04: Backend Schema sections 3–18 and 21; TRD sections 7 and 14–16.
- Supporting product rules: PRD sections 4, 5, and 11; API sections 2, 4, 7, and 19; App Flow principles and mobile state ownership.
