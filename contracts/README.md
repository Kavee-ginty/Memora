# Contracts

This directory holds the reviewed API contract artifacts. They are generated; do
not hand-edit them.

- `openapi/memora-v1.json` — reviewed OpenAPI 3.1 artifact generated from the
  FastAPI application.
- `openapi/operation-inventory.md` — stable operation IDs, auth and idempotency
  rules, and owning tasks.
- `dart/memora_api_client/` — Dart client generated from the artifact.
- `dart/memora_api_client_contract_tests/` — serialization contract tests for the
  generated client.

## Rules

- The OpenAPI artifact is the reviewed source of truth for the mobile client and
  contract tests.
- Generated files are never hand-edited. A schema change regenerates the artifact
  and the Dart client in the same pull request.
- Published operation IDs are permanent. Add new IDs to
  `backend/src/memora/api/operation_ids.py` and `openapi/operation-inventory.md`
  together.
- Optional additive response fields are allowed. Removing or renaming a field is
  breaking and requires a new major API path.
- The artifact stays canonical: sorted keys, two-space indent, UTF-8, LF and one
  trailing newline. It contains no `servers` or environment-specific URLs.
- The OpenAPI generator is pinned by version and SHA-256 in
  `tools/contracts/openapi-generator.json`. Its cache under
  `tools/.cache/openapi-generator/` is ignored.
- The generated client's `pubspec.lock` is intentionally committed so the drift
  check and CI install an exact dependency graph. Force-add it after regenerating:

  ```powershell
  git add -f contracts/dart/memora_api_client/pubspec.lock
  ```

- `tools/contracts/templates/pubspec.mustache` is the only template override.
  Generator 7.26.0 with `useOptional: true` emits `optional.dart` importing
  `json_annotation` without declaring it; the override adds the dependency.

Regenerate and verify from the repository root:

```powershell
python tools/contracts/generate_contracts.py --write
python tools/contracts/generate_contracts.py --check
```

CI runs the drift check in `.github/workflows/contracts.yml`. See
`openapi/README.md` and `dart/README.md` for the individual pipelines.
