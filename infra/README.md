# Infrastructure

The Compose file supplies the minimum local PostgreSQL/pgvector and API environment. `T02` owns CI and complete local environment behavior. Production infrastructure is not defined by this baseline.

```powershell
Copy-Item .env.example .env
docker compose --env-file .env -f infra/compose.yaml up --build
```
