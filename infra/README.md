# Local infrastructure

`compose.yaml` defines the local development environment only. It is not a staging or production deployment definition. Environment rules are in `../docs/operations/environments.md`.

## Prerequisites

- Docker Desktop with Compose v2 or later.
- Ports `5432` and `8000` available unless you override them in `.env`.

## First start

From the repository root:

```powershell
Copy-Item .env.example .env
docker compose --env-file .env -f infra/compose.yaml up -d --build --wait
```

`--wait` blocks until the PostgreSQL and API health checks pass. The first start also runs `postgres/init/00-extensions.sql`, which enables pgvector on a fresh local database.

Local endpoints:

- API: `http://127.0.0.1:8000`
- API documentation: `http://127.0.0.1:8000/docs`
- PostgreSQL: `127.0.0.1:5432`

The API and worker containers reach PostgreSQL through the Compose service name `postgres`; Compose builds their `MEMORA_DATABASE_URL` from `POSTGRES_*`. The `MEMORA_DATABASE_URL` in `.env` is only for host commands such as Alembic, seed and tests, so it uses `127.0.0.1`. If you run `uvicorn` on the host instead, the same loopback URL applies.

Host commands must use `127.0.0.1`, not `localhost`. Windows resolves `localhost` to both `::1` and `127.0.0.1`, but Compose publishes PostgreSQL on `127.0.0.1` only, so every connection first waits for the IPv6 attempt to fail. The Compose service name `postgres` also resolves only inside the Compose network. See `../backend/README.md` for migration-test setup and the disposable `memora_migration_test` database.

## Health and verification

```powershell
docker compose --env-file .env -f infra/compose.yaml ps
Invoke-RestMethod http://127.0.0.1:8000/health/live
Invoke-RestMethod http://127.0.0.1:8000/health/ready
docker compose --env-file .env -f infra/compose.yaml exec -T postgres psql -U memora -d memora -c "SELECT extversion FROM pg_extension WHERE extname = 'vector';"
```

Adjust the database user and name if you changed `POSTGRES_USER` or `POSTGRES_DB`. The vector query must return an installed `vector` extension version.

## Optional worker profile

The worker is a placeholder until feature tasks register durable job consumers. It is excluded from the default profile and exits after logging that no jobs are registered. It is not a long-running service yet.

```powershell
docker compose --env-file .env -f infra/compose.yaml --profile worker run --rm --no-deps worker
```

## Logs

```powershell
docker compose --env-file .env -f infra/compose.yaml logs --follow
```

Add a service name, such as `api` or `postgres`, to limit the output.

## Stop without deleting data

```powershell
docker compose --env-file .env -f infra/compose.yaml down
```

## Reset the local database

This deletes the local PostgreSQL volume and recreates it on the next start. Use it only for synthetic local data.

```powershell
docker compose --env-file .env -f infra/compose.yaml down --volumes
docker compose --env-file .env -f infra/compose.yaml up -d --build --wait
```

## Port overrides

Edit `.env` or set shell variables before Compose runs:

```powershell
$env:MEMORA_API_PORT = "8080"
$env:POSTGRES_PORT = "15432"
docker compose --env-file .env -f infra/compose.yaml up -d --build --wait
```

The API container still uses PostgreSQL on the internal port `5432`; only the host mapping changes.

## Safety rules

- Never commit `.env` or real credentials.
- Never use this Compose definition for staging or production.
- Use synthetic fixtures only; do not load production or student data locally.
- Do not add application tables through Compose initialization. Schema migrations belong to T04.
