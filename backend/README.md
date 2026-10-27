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
