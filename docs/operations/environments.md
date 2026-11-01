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
- Host tools (Alembic, seed) read `MEMORA_DATABASE_URL` from the process environment
  first, then fall back to the repository `.env` (override with `MEMORA_ENV_FILE`).
  Compose builds the API and worker database URL from `POSTGRES_*` and the service
  host `postgres`, so the loopback URL in `.env` is for host commands only.
- Development, staging and production receive configuration from the platform's environment or secret manager. The deployment image contains no repository `.env` file.
- `MEMORA_DATABASE_URL` contains credentials and is treated as a secret. It is excluded from configuration representations and must not be logged.
- The API database login must be permitted to `SET ROLE memora_api`; migrations use the owning migration login separately. Runtime identity transactions explicitly select the restricted role before setting the authenticated user RLS context.
- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` and `POSTGRES_PORT` configure the local Compose database only. Deployed environments use managed database credentials and do not use these local variables.
- `MEMORA_API_PORT` is a local host-port mapping only.

## Application variables

| Variable | Required | Rule |
| --- | --- | --- |
| `MEMORA_ENVIRONMENT` | Yes in deployed environments | One of `local`, `development`, `staging` or `production` |
| `MEMORA_DATABASE_URL` | Yes outside local | PostgreSQL SQLAlchemy URL with the required scheme `postgresql+psycopg://` |
| `MEMORA_LOG_LEVEL` | No | Logging threshold; defaults to `INFO` |
| `MEMORA_SUPABASE_URL` | Yes in staging and production | HTTPS Supabase project URL; the backend derives the OIDC issuer and JWKS URL |
| `MEMORA_SUPABASE_PUBLISHABLE_KEY` | Yes in staging and production | Publishable Auth key used only for provider logout |
| `MEMORA_SUPABASE_SERVICE_ROLE_KEY` | Yes in staging and production | Secret-manager value used server-side only for verified Auth Admin deletion; never expose it to mobile clients or SQL scripts |
| `MEMORA_RECENT_AUTH_WINDOW_SECONDS` | No | Recent interactive authentication window; defaults to 600 seconds |
| `MEMORA_DEVICE_ENCRYPTION_KEY` | Yes in staging and production | Secret-manager value containing a base64-encoded 32-byte AES-256-GCM key |
| `MEMORA_DEVICE_FINGERPRINT_KEY` | Yes in staging and production | Independent secret-manager value containing a base64-encoded 32-byte HMAC key |
| `MEMORA_CONSENT_*_VERSION` | Yes in staging and production | Approved current policy versions; `unapproved-*` placeholders are rejected |
| `MEMORA_INGESTION_ENCRYPTION_KEY` | No (defaults to deterministic local fallback) | Base64-encoded 32-byte AES-256-GCM key for manual text encryption |
| `MEMORA_EXTRACTION_PROVIDER` | No | One of `deterministic` or `openrouter`; defaults to `deterministic` |
| `MEMORA_OPENROUTER_API_KEY` | When provider is `openrouter` | Secret-manager token for LLM candidate extraction |
| `MEMORA_OPENROUTER_MODEL` | No | Model identifier on OpenRouter; e.g. `google/gemini-2.5-flash` |
| `MEMORA_OBJECT_STORAGE_PROVIDER` | Yes in staging and production | One of `memory` or `s3`; deployed environments require `s3` |
| `MEMORA_OBJECT_STORAGE_BUCKET` | When provider is `s3` | S3 bucket name for temporary source uploads |
| `MEMORA_OBJECT_STORAGE_ENDPOINT` | No | Custom S3 endpoint URL for MinIO, Cloudflare R2, etc. |
| `MEMORA_OBJECT_STORAGE_REGION` | No | S3 region; defaults to `us-east-1` |
| `MEMORA_OBJECT_STORAGE_ACCESS_KEY` | When provider is `s3` | S3 access key ID for presigning and verification |
| `MEMORA_OBJECT_STORAGE_SECRET_KEY` | When provider is `s3` | S3 secret access key for presigning and verification |
| `MEMORA_UPLOAD_MAX_FILES` | No | File upload count bound per update; defaults to 5 |
| `MEMORA_UPLOAD_MAX_BYTES` | No | Max upload byte size; defaults to 26,214,400 (25 MiB) |
| `MEMORA_UPLOAD_GRANT_TTL_SECONDS` | No | Presigned PUT grant validity duration; defaults to 900 seconds |
| `MEMORA_INGESTION_EXPIRY_HOURS` | No | Inactive draft/uploading update TTL; defaults to 72 hours |
| `MEMORA_VERIFICATION_EXPIRY_HOURS` | No | Verification candidate decision window; defaults to 72 hours |

Local development falls back to a loopback PostgreSQL URL when `MEMORA_DATABASE_URL` is omitted. That fallback is not a deployed-environment default.

## Enforced boundaries

The application refuses to start when:

- a non-local environment omits `MEMORA_DATABASE_URL`;
- the database URL is malformed or does not use the required `postgresql+psycopg://` scheme;
- staging or production uses a loopback or local service host such as `localhost`, `127.0.0.1`, `postgres` or `host.docker.internal`;
- staging or production omits the database name.
- staging or production omits Supabase, device-key or consent-policy configuration;
- a deployed device key is malformed or does not decode to exactly 32 bytes;
- a deployed consent version still uses an `unapproved-*` placeholder.

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
