# Shared development deployment

This environment deploys only the Memora API from the
`codex/shared-development-deployment` branch. It does not deploy `develop`, staging or
production. It uses the existing Supabase development project for PostgreSQL, pgvector and
Auth. Only synthetic or explicitly approved de-identified data is permitted.

## Runtime layout

- The API runs as `memora-backend:<commit-sha>` and binds to `127.0.0.1:8001` on the VPS.
- Caddy is the only public container and terminates HTTPS on ports 80 and 443.
- The deployment lives in `/home/kaveesha/Memora` under the Compose project
  `memora-development`.
- Runtime configuration lives outside the checkout at
  `/home/kaveesha/.config/memora/development.env` with mode `600`.
- The development Supabase database remains managed and is not hosted on the VPS.

The current worker entry point is a placeholder and is intentionally not deployed. Add a
worker only when its owning feature task registers a durable consumer.

## Required GitHub environment secrets

Create a GitHub environment named `development` and configure:

| Secret | Purpose |
| --- | --- |
| `DEV_VPS_HOST` | VPS hostname or IP address |
| `DEV_VPS_USER` | Restricted deployment user |
| `DEV_VPS_SSH_PRIVATE_KEY` | Private key dedicated to this deployment |
| `DEV_VPS_KNOWN_HOSTS` | Pinned SSH host-key entry produced by an independently verified scan |

Set the non-secret `MEMORA_DEV_DOMAIN` environment variable to the development API hostname.
The deployment workflow validates it and synchronizes only that setting into the protected VPS
environment file before deployment.

The workflow never stores application or database credentials in GitHub. Those values remain
in the VPS environment file.

## VPS bootstrap

The owner must approve the VPS for Memora before bootstrap. Create the configuration directory
and copy the real development settings through an authenticated SSH session:

```bash
install -d -m 700 /home/kaveesha/.config/memora
install -m 600 /dev/stdin /home/kaveesha/.config/memora/development.env
```

The file must contain every application setting in
`infra/development/development.env.example`, including `MEMORA_DEV_DOMAIN`. Never copy the file
into the repository or a deployment image.

Point the development domain to the VPS before the first workflow run. Caddy obtains and renews
the certificate automatically after ports 80 and 443 reach the server.

## Deployment and rollback

A push to `codex/shared-development-deployment` verifies the backend, validates deployment
configuration, builds the immutable image, applies migrations and deploys it. The workflow
records the active commit in `/home/kaveesha/Memora/current-image`.

To roll back, rerun the workflow for a previously verified commit while its image is still
present on the VPS. Database migrations must remain backward compatible; destructive migration
rollback is not automated.

## Verification

```bash
docker compose --project-name memora-development \
  --env-file /home/kaveesha/.config/memora/development.env \
  -f /home/kaveesha/Memora/compose.yaml ps
curl --fail https://DEV_DOMAIN/health/live
curl --fail https://DEV_DOMAIN/health/ready
```

The mobile application uses `https://DEV_DOMAIN` as `MEMORA_API_BASE_URL`. Supabase OAuth keeps
the existing `com.kaveeginty.memora://login-callback` mobile redirect.
