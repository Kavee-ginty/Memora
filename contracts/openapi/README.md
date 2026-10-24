# OpenAPI

`memora-v1.json` is the reviewed OpenAPI 3.1 artifact for the Memora API. FastAPI
generates it from the typed Pydantic models and registered operations; it is the
source of truth for the generated Dart client and the contract tests. Do not edit
it by hand.

The artifact currently contains the health operations and shared components
(errors, pagination, headers, async operations and bearer security). `/v1`
resource paths are added by their owning tasks without changing the shared client
surface.

## Regenerate

From the repository root, with the backend environment installed:

```powershell
python tools/contracts/generate_contracts.py --write
```

That command verifies the pinned generator, exports and validates the artifact,
then regenerates the Dart client. To write only the artifact:

```powershell
$env:PYTHONPATH = "backend\src"
python -m memora.api.export_openapi --output contracts\openapi\memora-v1.json
```

## Check for drift

```powershell
python tools/contracts/generate_contracts.py --check
```

or artifact-only:

```powershell
$env:PYTHONPATH = "backend\src"
python -m memora.api.export_openapi --check --output contracts\openapi\memora-v1.json
```

CI (`.github/workflows/contracts.yml`) runs both the contract tests and the drift
check; an undocumented operation or an unregenerated artifact fails the build.

## Change rules

- Schema changes regenerate the OpenAPI artifact and the Dart client in the same
  pull request.
- Published operation IDs are permanent. Record a new ID in
  `operation-inventory.md` and `backend/src/memora/api/operation_ids.py` together.
- Optional additive response fields are allowed. Removing or renaming a field is
  breaking and requires a new major API path.
- Every operation declares tags and responses. `/v1` operations use bearer auth,
  every 4xx/5xx response uses the shared `ErrorEnvelope`, and mutations declare
  either `Idempotency-Key` or `client_operation_id` unless naturally idempotent.
- The artifact stays canonical: sorted keys, two-space indent, UTF-8, LF and one
  trailing newline. It must not contain `servers` or environment-specific URLs.
