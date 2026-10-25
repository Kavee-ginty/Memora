# Environment configuration boundaries

Memora uses the same application image in every environment and selects behavior only through server-side configuration. The environment name is part of that configuration: a deployed service must set `MEMORA_ENVIRONMENT` explicitly. An omitted value falls back to `local` and is only acceptable on a developer workstation.

This document defines the T02 boundary. Deployment manifests, cloud resources and release credentials belong to later release tasks.

## Environment matrix

| Environment | Purpose | Configuration source | Data rule | API docs |
| --- | --- | --- | --- | --- |
| Local | Developer feedback and unit tests | Untracked `.env` copied from `.env.example`; Compose | Synthetic fixtures only | Enabled |
| Development | Shared integration and agent experiments | Platform environment and secret manager | Synthetic or explicitly approved de-identified samples | Enabled |
| Staging | Production-like release, load and security verification | Platform environment and secret manager | Synthetic datasets matching production shape | Disabled |
| Production | Pilot and live students | Platform environment and secret manager | Approved data, monitoring and retention policy | Disabled |

The data rules follow TRD 18.2. Production data must never be copied into local, development or staging environments.

## Configuration sources

- `.env` is local-only, ignored by Git and must never be committed.
- `.env.example` is committed and contains synthetic local placeholders only.
- Development, staging and production receive configuration from the platform's environment or secret manager. The deployment image contains no repository `.env` file.
- `MEMORA_DATABASE_URL` contains credentials and is treated as a secret. It is excluded from configuration representations and must not be logged.
- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` and `POSTGRES_PORT` configure the local Compose database only. Deployed environments use managed database credentials and do not use these local variables.
- `MEMORA_API_PORT` is a local host-port mapping only.

## Application variables

| Variable | Required | Rule |
| --- | --- | --- |
| `MEMORA_ENVIRONMENT` | Yes in deployed environments | One of `local`, `development`, `staging` or `production` |
| `MEMORA_DATABASE_URL` | Yes outside local | PostgreSQL SQLAlchemy URL with the required scheme `postgresql+psycopg://` |
| `MEMORA_LOG_LEVEL` | No | Logging threshold; defaults to `INFO` |

Local development falls back to a loopback PostgreSQL URL when `MEMORA_DATABASE_URL` is omitted. That fallback is not a deployed-environment default.

## Enforced boundaries

The application refuses to start when:

- a non-local environment omits `MEMORA_DATABASE_URL`;
- the database URL is malformed or does not use the required `postgresql+psycopg://` scheme;
- staging or production uses a loopback or local service host such as `localhost`, `127.0.0.1`, `postgres` or `host.docker.internal`;
- staging or production omits the database name.

Staging and production always disable `/docs`. Local and development keep the OpenAPI UI for developer use. These checks are covered by `backend/tests/test_config.py`.

## Local workflow

From the repository root:

```powershell
Copy-Item .env.example .env
docker compose --env-file .env -f infra/compose.yaml up -d --build --wait
```

See `../../infra/README.md` for health checks, the optional worker profile, reset and teardown commands. Compose is a local development definition only; it must not be used to describe staging or production infrastructure.

## Future environment work

This boundary does not create cloud accounts, deployment workflows or production secrets. Staging deployment, migration rehearsal, signed artifacts and production approval remain release-task responsibilities.
