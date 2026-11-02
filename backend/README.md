# Memora backend

The backend is a FastAPI modular monolith with a separate worker entry point. The foundation contains application configuration, health endpoints, database migrations and the shared API contract surface. Domain modules and `/v1` resources are added by their owning CPM tasks.

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --require-hashes -r requirements-dev.lock
python -m pip install --no-deps -e .
pytest
uvicorn memora.main:app --reload
```

Create or update the local database and apply foundational seeds:

Alembic reads `MEMORA_DATABASE_URL` from the process environment first. When that
variable is absent it falls back to the repository `.env` file (override the path with
`MEMORA_ENV_FILE`). Deployed jobs must still set the variable explicitly. Host commands
must use the loopback host `127.0.0.1`; the Compose service name `postgres` resolves only
inside the Compose network.

```powershell
alembic upgrade head
python -m memora.db.seed
```

The `.env` value is the synthetic `POSTGRES_PASSWORD` from your untracked `.env`.

Alembic waits at most 10 seconds for a database connection; set
`MEMORA_DB_CONNECT_TIMEOUT_SECONDS` to change that bound. The seed command uses the same
10-second default.

### Migration tests

The migration tests drop and recreate every table, so they only accept a disposable
database whose name ends in `_test` or `_ci`. Never point `MEMORA_TEST_DATABASE_URL` at
the development database or a deployed database.

Create the isolated database once. The command reports "already exists" on later runs,
which is safe to ignore:

```powershell
docker compose --env-file .env -f infra/compose.yaml exec -T postgres createdb -U memora memora_migration_test
```

Then run the tests with a loopback URL built from the local container password. These
commands do not print the password:

```powershell
$dbPassword = docker compose --env-file .env -f infra/compose.yaml exec -T postgres printenv POSTGRES_PASSWORD
$encoded = [uri]::EscapeDataString($dbPassword.Trim())
$env:MEMORA_TEST_DATABASE_URL = "postgresql+psycopg://memora:$encoded@127.0.0.1:5432/memora_migration_test"
.\.venv\Scripts\python.exe -m pytest backend\tests\test_migrations.py -vv
```

`localhost` also works, but Windows resolves it to both `::1` and `127.0.0.1`. Compose
publishes PostgreSQL on `127.0.0.1` only, so each connection first waits for the IPv6
attempt to fail. Use `127.0.0.1` for fast, predictable local runs.

Runtime and development dependencies are locked with hashes. After an intentional change to `pyproject.toml`, regenerate both files with Python 3.12:

```powershell
python -m pip install pip-tools==7.5.2
python -m piptools compile --strip-extras --generate-hashes --output-file requirements.lock pyproject.toml
python -m piptools compile --strip-extras --generate-hashes --extra dev --output-file requirements-dev.lock pyproject.toml
```

## API contracts

The FastAPI application is the source of the reviewed OpenAPI artifact at
`../contracts/openapi/memora-v1.json`. Do not edit that artifact or the generated
Dart client by hand.

From the repository root, with this environment active:

```powershell
python -m pytest backend\tests\test_api_contract_models.py backend\tests\test_openapi_contract.py backend\tests\test_openapi_artifact.py
python tools\contracts\generate_contracts.py --write
python tools\contracts\generate_contracts.py --check
```

`--write` exports and validates the artifact, regenerates the Dart client and
rebuilds it. `--check` fails on artifact or client drift; CI also runs it.

When adding a `/v1` route:

- Use `operation_id=OperationId.NAME` from `memora/api/operation_ids.py`.
- Add a non-empty `tags=` value from the shared tag list.
- Attach `dependencies=[Depends(bearer_auth)]`. `bearer_auth(auto_error=False)` is solely the credential/schema primitive; T06 must provide the enforcing request-context dependency and safe 401 `ErrorEnvelope` responses.
- Merge success responses with `COMMON_ERROR_RESPONSES`.
- For mutations, accept `Annotated[IdempotencyHeaders, Header()]` unless the
  operation uses `client_operation_id` or is naturally idempotent.
- Regenerate the OpenAPI artifact and Dart client in the same change.

## Identity and session configuration

T06 uses Supabase Auth with Google OAuth. The API validates asymmetric Supabase
access tokens locally from the project JWKS endpoint. It accepts only audience
`authenticated`, role `authenticated`, a non-anonymous subject and the required
issuer, expiry, issued-at and session claims.

Copy the identity variable names from `../.env.example`. Local `.env` values stay
untracked. Staging and production obtain the Supabase publishable key, independent
device encryption/fingerprint keys and approved consent policy versions from the
platform secret manager. The backend does not read or need a Supabase secret or
service-role key.

Supabase logout revokes refresh material; an already issued access token remains
valid until its short expiry. Keep the provider access-token lifetime short. Session
revocation requires interactive authentication within the configured ten-minute
window and records a safe audit event without the token.

## Learning ingestion and background workers

T09 provides the learning ingestion pipeline, extraction worker and temporary upload
reconciler. Ingestion endpoints live under `/v1/learning-updates`:

- Lifecycle: create, list, read, edit and discard learning updates.
- Source uploads: generate single-use presigned PUT upload grants, validate uploaded
  content bounds and SHA-256 digests, and finalize uploads for processing.
- Extraction & candidates: worker executes text/document extraction (deterministic or
  OpenRouter LLM), storing candidate concepts, questions and facts with confidence bands.
- Verification: inspect candidates, accept/edit/reject/merge decisions, and preview the
  learning path impact.
- Knowledge commit & deletion: atomic commit transaction into retained knowledge tables,
  outbox event creation, and background raw file deletion with cryptographic deletion proofs.

### Background worker runners

Ingestion and deletion jobs run asynchronously through the worker entry points:

```powershell
# Run extraction and source deletion background worker
python -m memora.worker.ingestion

# Run temporary source upload and expired update reconciler
python -m memora.worker.reconciler
```

### Ingestion configuration

Ingestion configuration keys in `.env` or the platform environment:

- `MEMORA_INGESTION_ENCRYPTION_KEY`: Base64-encoded 32-byte AES-256-GCM key for manual text encryption.
- `MEMORA_EXTRACTION_PROVIDER`: `deterministic` (default) or `openrouter`.
- `MEMORA_OPENROUTER_API_KEY`: API key for OpenRouter model extraction.
- `MEMORA_OPENROUTER_MODEL`: Model identifier for LLM extraction.
- `MEMORA_OBJECT_STORAGE_PROVIDER`: `memory` (test/local default) or `s3`.
- `MEMORA_OBJECT_STORAGE_BUCKET`: Target S3 bucket name for temporary source uploads.
- `MEMORA_OBJECT_STORAGE_ENDPOINT`: S3 endpoint URL (when using MinIO, Cloudflare R2, etc.).
- `MEMORA_OBJECT_STORAGE_REGION`: AWS region (defaults to `us-east-1`).
- `MEMORA_OBJECT_STORAGE_ACCESS_KEY` & `MEMORA_OBJECT_STORAGE_SECRET_KEY`: S3 SigV4 credentials.
- `MEMORA_UPLOAD_MAX_FILES`: Maximum files declared per update (defaults to 5, max 20).
- `MEMORA_UPLOAD_MAX_BYTES`: Maximum byte size per upload (defaults to 25 MiB).
- `MEMORA_UPLOAD_GRANT_TTL_SECONDS`: Presigned PUT grant validity window (defaults to 900s).
- `MEMORA_INGESTION_EXPIRY_HOURS`: TTL before uncommitted updates expire (defaults to 72h).

Privacy deletion additionally requires `MEMORA_SUPABASE_SERVICE_ROLE_KEY` for the
server-only Supabase Auth Admin API. Staging and production require the `s3`
storage provider so export archives and deletion verification are shared by the
API and durable worker. Secrets belong in the runtime secret manager, not the
Supabase SQL editor.

## Memory engine

T11 schedules reviews per learner-concept pair. The engine is deterministic code
with no AI provider: a due date is produced only by
`modules/memory/engine/decide.py`, never by a model. Same inputs plus the same
engine and policy versions reproduce the identical decision.

### Module map

```text
modules/memory/engine/config.py    frozen weights, bounds and the two versions
modules/memory/engine/state.py     immutable LearnerConceptState + jsonb snapshots
modules/memory/engine/fsrs.py      forgetting curve, difficulty/stability transitions
modules/memory/engine/decide.py    pure decide(state, event, now) -> Decision
modules/memory/engine/policy.py    first review, confidence damping, comeback, caps
modules/memory/prerequisites.py    read-only weak-prerequisite signal from the graph
modules/memory/repository.py       SECURITY DEFINER calls; event + decision + outbox
modules/memory/selection.py        due-selection inputs for T13 (no ranking)
modules/memory/service.py          owner-scoped reads for the two read endpoints
modules/memory/explanations.py     reason codes and template keys -> safe copy
modules/memory/constants.py        closed allowlists: event types, codes, keys, bands
worker/memory.py                   outbox -> memory job handler, retries, reconcile
worker/main.py                     worker entry point (runs the memory loop)
api/v1/memory.py                   concept-progress and history routes
```

### Versions

Every decision row and calibration fixture stamps its configuration identity:

- `ENGINE_VERSION = fsrs-mvp-1.0.0` — the quantitative model and its weights.
- `POLICY_VERSION = policy-mvp-1.0.0` — the expert rules layered on top.
- `STATE_SNAPSHOT_SCHEMA_VERSION = memora.memory_state/1` — the
  `previous_state` / `result_state` jsonb envelope.
- `SELECTION_INPUT_VERSION = memory-selection-inputs/1` — the due-selection
  contract T13 consumes.

Change a weight or a rule and bump the matching version. Never mutate a stored
snapshot: a version bump changes future decisions and leaves past rows readable.

### Worker job type

`memory.process_event` carries one `outbox_event_id` and nothing else. The worker
reads the producer event, maps it to per-concept evidence and applies each concept
in one transaction. Two producer envelopes are reserved:

| Event type | Aggregate | Evidence |
| --- | --- | --- |
| `learning_update.committed` | `learning_update` | one `exposure` per committed concept |
| `mission.attempt_graded` | `attempt` | one scored event per mapped concept |

Unknown event types succeed as a skip. A known envelope with a malformed payload
dead-letters immediately with `invalid_event_payload` and never blocks the queue.
Retryable failures back off `15/60/180/600/1800` seconds across five attempts, then
dead-letter. A reconcile pass re-enqueues producer events that have no job and
recovers expired leases, so a restarted worker loses nothing; dead-lettered
payloads stay quarantined until an operator fixes them.

The job lifecycle runs as `memora_worker`. The evidence transaction runs as
`memora_api` with `memora.user_id` set for the envelope's learner, so the
prerequisite lookup is RLS-scoped. Memory writes go through the SECURITY DEFINER
functions added by migration `20261031_0010`.

### Read endpoints

`GET /v1/subjects/{subject_id}/concept-progress` and
`GET /v1/concepts/{concept_id}/history` are owner-scoped and `no-store`. They
return bands, stable identifiers, counts and allowlisted codes — never raw
retrievability, stability, forgetting risk, candidate scores or `event_payload`.
The `due_reason` and explanation `template_key` values are the copy contract for
T14; the server supplies a plain-language fallback message. Cursors are bound to
the endpoint and filter that produced them, so a cursor cannot be replayed against
another route or another concept.

### Tests

From the repository root, with the backend environment active:

```powershell
$env:MEMORA_TEST_DATABASE_URL = 'postgresql+psycopg://memora:<local-password>@127.0.0.1:5432/memora_migration_test'
backend\.venv\Scripts\python.exe -m pytest backend\tests\test_memory_engine.py backend\tests\test_memory_policy.py backend\tests\test_memory_persistence.py backend\tests\test_memory_selection.py backend\tests\test_memory_simulation.py backend\tests\test_memory_worker.py backend\tests\test_memory_endpoints.py
```

The database-backed cases in `test_memory_persistence`, `test_memory_selection`,
`test_memory_worker` and `test_memory_endpoints` skip without
`MEMORA_TEST_DATABASE_URL`; the pure engine, policy and simulation suites run
everywhere. `test_memory_simulation.py` replays the versioned calibration fixture
in `backend/tests/fixtures/memory` across a simulated calendar for the four
acceptance scenarios (new, overdue, weak prerequisite, comeback).

## Study missions

T13 assembles and runs owner-scoped daily missions under `/v1/missions`. Planning
consumes T11 due-selection inputs and T12 approved question versions. It selects at
most six planned questions and stops before the estimate would exceed seven minutes;
it never pads a short mission. Short-answer questions are excluded from automatic
selection for the initial release.

Start, attempt, skip, pause and completion mutations are idempotent and serialize on
the mission row. A mission pins immutable question versions, never exposes answer
keys before submission, and can insert at most one high-confidence repair question.
The repair counts toward a hard total of seven items. Grading and the corresponding
`mission.attempt_graded` outbox event commit atomically. Completion stores a stable
learning summary and emits one `mission.completed` event; T15 consumes that boundary
to add authoritative XP, streak and reef results.

Run the focused mission checks against a disposable database:

```powershell
$env:MEMORA_TEST_DATABASE_URL = 'postgresql+psycopg://memora:<local-password>@127.0.0.1:5432/memora_migration_test'
backend\.venv\Scripts\python.exe -m pytest backend\tests\test_mission_ranking.py backend\tests\test_missions_integration.py
```
