# Memora T02 study note

Simple English notes for a beginner. This is a learning guide, not a replacement
for the specifications.

## 1. What T02 was about

T02 answered one question:

> Can a new developer clone the repository, start the local services, and trust
> that every change passes the same checks before it is merged?

**Simple analogy:** T02 is the airport before a flight.

- **CI** is the security checkpoint. Every passenger (change) is checked.
- **CI gate** is the boarding gate. It opens only when every checkpoint passed.
- **Docker Compose** is the practice kitchen on your laptop. It starts the same
  ingredients the real system needs.
- **`.env`** is your private keychain. It stays on your machine.
- **Migrations** are the careful moving of furniture in a shared house. Do it on
  a practice house first, never on the real one.

T02 was not a feature for students. It was the safety net that lets later
features be built without guessing.

## 2. The big picture

When you push code or open a pull request:

```text
Developer
   |
   | push / pull request
   v
GitHub Actions
   |-- backend: format, lint, unit tests
   |-- Flutter: format, analyze, tests
   |-- Compose: validate local service file
   |-- migrations: empty database -> head -> tests
   |-- contracts: OpenAPI and Dart client drift
   |-- security: dependency, secret and vulnerability scans
   |-- builds: Flutter APK and backend container image
   v
CI gate  ---> all passed? ---> merge is allowed
```

On your laptop:

```text
.env  ->  docker compose  ->  PostgreSQL + pgvector
                              API
                              worker (optional profile)
```

## 3. Key concepts I learned

### 3.1 CI is code, not a person

CI (Continuous Integration) is a YAML file that tells GitHub what to run. The
file is split into **jobs**. A job has **steps**. Steps run commands.

```yaml
jobs:
  backend:
    steps:
      - run: python -m ruff check backend
      - run: python -m pytest backend/tests
```

A later job can wait for earlier jobs with `needs`. That is how `ci-gate` knows
whether everything passed.

**Why one gate?** The contract workflow only runs when API-related files change.
On a documentation-only pull request it is **skipped**. If branch protection
requires that skipped check, the pull request can wait forever. So the project
requires one always-running check: `CI gate`.

### 3.2 The jobs in the pipeline

| Job | What it protects |
| --- | --- |
| Backend | Python formatting, linting and unit tests |
| Flutter | Dart formatting, analysis and widget tests |
| Compose | The local `compose.yaml` is valid |
| Migrations | A fresh database can upgrade to the latest schema |
| Contracts | OpenAPI and generated Dart client match the backend |
| Security | Known vulnerable packages, leaked secrets, high-risk findings |
| Flutter build | The Android debug APK still builds |
| Container | The backend Docker image builds and can be scanned |
| CI gate | Fails if any required job did not succeed |

The backend job skips database migration tests. Those run in the separate
migration job because they need a real PostgreSQL service.

### 3.3 Docker Compose is a local practice kitchen

Docker Compose starts several services from one file:

- `postgres` uses the `pgvector/pgvector:pg16` image.
- `api` builds the FastAPI backend.
- `worker` is optional and starts only with the `worker` profile.

Useful ideas:

- A **healthcheck** asks "are you alive?" before other services depend on it.
- `depends_on: condition: service_healthy` makes the API wait for PostgreSQL.
- `--wait` makes Compose wait until healthchecks pass.
- `down` stops containers but keeps the database volume.
- `down --volumes` deletes the local database too.

**Important Windows detail:** use `127.0.0.1` from the host, not `localhost`.
`localhost` may try IPv6 first, fail, and only then try IPv4. That makes every
database connection slower. Inside the Compose network, use the service name
`postgres` instead.

### 3.4 Environment boundaries

The same application image runs in every environment. Only configuration changes.

| Environment | Data | Configuration |
| --- | --- | --- |
| Local | Synthetic only | Untracked `.env` |
| Development | Synthetic or approved de-identified data | Platform secret manager |
| Staging | Synthetic, production-shaped data | Platform secret manager |
| Production | Approved real data | Platform secret manager |

Rules I learned:

- `.env` is ignored by Git and must never be committed.
- `.env.example` is committed and contains fake placeholders only.
- A non-local environment must provide `MEMORA_DATABASE_URL`.
- Staging and production reject local database hosts such as `localhost`,
  `127.0.0.1`, `postgres` or `host.docker.internal`.
- Staging and production disable `/docs`.
- The app fails fast at startup instead of silently using a dangerous default.

**Analogy:** your home key, school key and bank key look similar, but they must
not open each other's doors. The environment name selects the correct key.

### 3.5 Migration safety

Alembic applies database migrations in order.

Two safety ideas matter:

1. **Bound the wait.** A connection attempt should not hang forever. T02 added a
   10-second connect timeout, configurable with
   `MEMORA_DB_CONNECT_TIMEOUT_SECONDS`.
2. **Use a disposable database.** Migration tests downgrade to base, which
   deletes schema objects. The test fixture refuses any database whose name does
   not end in `_test` or `_ci`. This prevents a copy-paste mistake from wiping
   the development database.

**Analogy:** a crash-test car is destroyed on purpose. You never crash-test the
car you drive to work.

### 3.6 Contract drift and security scans

The OpenAPI file and generated Dart client are committed artifacts. If the
backend changes but the artifacts are not regenerated, CI fails. This is called
**drift**.

Security checks:

- `pip-audit` looks for known vulnerable Python packages.
- Gitleaks scans git history for secrets.
- Trivy scans dependencies, configuration and container images.

Tools are pinned to exact versions or image digests so the result is repeatable.
CI uses `contents: read` and no repository secrets. That makes fork pull requests
safer.

### 3.7 Health checks

There are two different questions:

- `GET /health/live` -> "Is the API process running?"
- `GET /health/ready` -> "Can the API reach the database?"

Readiness returns `503` when the database is unavailable. Compose uses that
endpoint so it does not report the API as ready too early.

## 4. The bug that taught the biggest lesson

The migration command once felt like it was hanging.

What was happening:

1. The URL used `localhost`.
2. Windows resolved it to IPv6 `::1` and IPv4 `127.0.0.1`.
3. Compose published PostgreSQL on IPv4 only.
4. Each connection waited for the IPv6 attempt to fail first.
5. There was no connect timeout, so the delay was repeated for every connection.

The fix was simple: use `127.0.0.1` and add a bounded connect timeout.

**Lesson:** a slow system and a broken system can look the same. Always bound
network waits, and measure before guessing.

## 5. What changed in the repository

- `.github/workflows/ci.yml` — the full quality pipeline and `CI gate`.
- `.github/workflows/contracts.yml` — callable from CI with `workflow_call`.
- `infra/compose.yaml` — PostgreSQL, API, optional worker and healthchecks.
- `.env.example` — safe local placeholders and environment notes.
- `backend/src/memora/core/config.py` — environment validation and safe local
  defaults.
- `backend/migrations/env.py` — bounded connection timeout.
- `backend/tests/test_migrations.py` — disposable database guard and timeout.
- `backend/src/memora/api/health.py` — live and ready endpoints.
- `docs/operations/ci.md` and `docs/operations/environments.md` — the written
  rules.

Later tasks extended the same config validator with identity and consent
settings. The T02 pattern stayed the same: validate early, fail clearly, never
commit secrets.

## 6. Common mistakes and fixes

| Mistake | Fix |
| --- | --- |
| A required CI check stays "Expected" forever | Require only the always-running `CI gate` |
| Compose cannot connect from the host | Use `127.0.0.1`, not `localhost` |
| Compose cannot resolve the database from the API | Use the service name `postgres` |
| Migration tests refuse the database | The name must end in `_test` or `_ci` |
| Migration tests are skipped | Set `MEMORA_TEST_DATABASE_URL` |
| Contract check fails before comparing files | `.env` has an invalid database URL |
| A secret was committed | Rotate it, remove it from history, let Gitleaks verify |
| `docker compose config` did not start anything | It only validates the file |

## 7. Commands cheat sheet

```powershell
# First local setup
Copy-Item .env.example .env
docker compose --env-file .env -f infra/compose.yaml up -d --build --wait

# Health
docker compose --env-file .env -f infra/compose.yaml ps
Invoke-RestMethod http://127.0.0.1:8000/health/live
Invoke-RestMethod http://127.0.0.1:8000/health/ready

# Logs and shutdown
docker compose --env-file .env -f infra/compose.yaml logs --follow
docker compose --env-file .env -f infra/compose.yaml down

# Full local database reset (destructive)
docker compose --env-file .env -f infra/compose.yaml down --volumes
docker compose --env-file .env -f infra/compose.yaml up -d --build --wait

# Backend checks
.\.venv\Scripts\python.exe -m ruff format --check backend
.\.venv\Scripts\python.exe -m ruff check backend
.\.venv\Scripts\python.exe -m pytest backend\tests --ignore=backend\tests\test_migrations.py

# Compose validation
docker compose --env-file .env.example -f infra/compose.yaml config --quiet
```

## 8. Quick self-check

1. **Why does the project require one `CI gate` instead of every job?**
   Because path-filtered workflows can be skipped, and a required skipped check
   can leave a pull request waiting forever.

2. **Why use `127.0.0.1` instead of `localhost` on Windows?**
   `localhost` may try IPv6 first. Compose publishes IPv4 only, so the failed
   IPv6 attempt adds delay.

3. **Why must the migration test database end in `_test` or `_ci`?**
   The tests downgrade to base. The suffix guard prevents deleting a real
   database by accident.

4. **What is the difference between `/health/live` and `/health/ready`?**
   Live means the process is running. Ready means the process can reach the
   database.

5. **Why is `.env.example` safe to commit but `.env` is not?**
   `.env.example` has fake placeholders. `.env` has real credentials and is
   ignored by Git.

## 9. Specification map

- TRD 2 — non-functional requirements and quality gates.
- TRD 16 — security and privacy.
- TRD 18 — environments and configuration.
- TRD 19 — testing and CI.
- Task table T02 acceptance gate.

The main lesson: **make the safe path the easy path.** A new developer should
not need to remember every rule. The scripts, Compose file, config validator and
CI gate should enforce the rules automatically.
