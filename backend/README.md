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

Set `MEMORA_DATABASE_URL` in the process environment first; Alembic has no committed
credential fallback.

```powershell
alembic upgrade head
python -m memora.db.seed
```

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
