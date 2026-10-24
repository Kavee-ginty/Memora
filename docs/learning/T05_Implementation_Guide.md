# Memora T05 implementation guide

## 1. Task and boundary

**Task:** T05 — OpenAPI models and generated client pipeline.

**Acceptance gate:** OpenAPI includes common errors, auth, idempotency and examples; the Dart client compiles; regenerated output is deterministic; CI rejects undocumented API changes.

**In scope**

- Shared Pydantic primitives, errors, request headers and bearer scheme.
- Stable operation IDs for the planned `/v1` surface.
- OpenAPI metadata, components, examples and guards.
- Canonical OpenAPI artifact.
- Pinned generator tooling.
- Generated Dart client and serialization tests.
- Separate contract CI workflow.

**Out of scope**

- Business `/v1` endpoints or endpoint stubs.
- Token validation, request context or authorization dependencies.
- Per-resource schemas owned by T06, T08, T09, T12, T17 and T20.
- Full provider/consumer and authorization suite (T25).
- T02's general CI.

**Repository state**

- T01 and T04 are Done.
- T02 and T05 are Ready. Coordinate before touching CI.
- T08 stays Blocked until T05 is merged and marked Done.
- Integration branch is `develop`; `main` is behind and lacks T04.
- `CONTRIBUTING.md` says to branch from `main`. For T05, branch from `develop` and note the documentation mismatch as a follow-up.
- Current backend resolves FastAPI 0.161.1 and Pydantic 2.14.1.
- Mobile pins Dart 3.13.0 and Flutter 3.47.5.

## 2. Locked decisions

| Decision | Value |
| --- | --- |
| Branch | `task/T05-openapi-pipeline` |
| Base and PR target | `develop` |
| Scope | Shared foundation plus operation inventory; no endpoint stubs |
| OpenAPI artifact | `contracts/openapi/memora-v1.json` |
| Generated client | `contracts/dart/memora_api_client/` |
| Dart contract tests | `contracts/dart/memora_api_client_contract_tests/` |
| Generator | `openapi-generator-cli` 7.26.0, `dart-dio` |
| Serialization | `built_value` with `useOptional: true` |
| OpenAPI version | 3.1.0 |
| CI | Separate `.github/workflows/contracts.yml` |
| New Python dependencies | None |

The artifact contains only the current health operations plus shared components. Endpoint tasks add paths later without changing the shared client surface.

## 3. Files to create

```text
backend/src/memora/api/
  openapi.py
  operation_ids.py
  security.py
  export_openapi.py
  v1/__init__.py
  v1/router.py
  v1/schemas/__init__.py
  v1/schemas/common.py
  v1/schemas/errors.py
  v1/schemas/headers.py
backend/src/memora/main.py                  # modify
backend/tests/
  test_api_contract_models.py
  test_openapi_contract.py
  test_openapi_artifact.py
contracts/openapi/
  README.md
  operation-inventory.md
  memora-v1.json
contracts/dart/
  README.md
  memora_api_client/                        # generated, committed
  memora_api_client_contract_tests/
tools/contracts/
  generate_contracts.py
  openapi-generator.json
  dart-dio-config.yaml
  templates/pubspec.mustache
  README.md
.github/workflows/contracts.yml
```

## 4. Pre-flight

Create the branch after claiming T05 on the task table:

```powershell
git switch develop
git pull --ff-only
git switch -c task/T05-openapi-pipeline
```

Set T05 Owner and status **In Progress** on the task branch. Do not commit the claim directly to `develop` or `main`.

Install and baseline:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install --require-hashes -r backend\requirements-dev.lock
python -m pip install --no-deps -e backend
python -m pytest backend\tests
python -m ruff format --check backend
python -m ruff check backend
```

If the baseline fails, stop and record it. Do not fix unrelated code in T05.

Install Java 17+ and Dart 3.12+. Prefer Dart 3.13.0 in CI to match mobile.

Download and verify the generator:

```powershell
$cache = "tools\.cache\openapi-generator"
New-Item -ItemType Directory -Force -Path $cache | Out-Null
$jar = Join-Path $cache "openapi-generator-cli-7.26.0.jar"
Invoke-WebRequest `
  -Uri "https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/7.26.0/openapi-generator-cli-7.26.0.jar" `
  -OutFile $jar
Get-FileHash -Algorithm SHA256 -LiteralPath $jar
```

Expected SHA-256:

```text
1760050094997b9cc790cc1350be095f15da8c08a996b184d3eadc4ccda5e35e
```

## 5. Implementation order

Each commit must leave the repository working.

One coding agent implements the parts in order. The agent must not run `git add`, `git commit`, `git merge`, `git rebase`, `git push`, `gh pr create`, or edit the task table. After each commit-sized part, the agent stops and reports:

```text
Commit: 1/11
Message: feat(T05): add shared API primitives and error envelope
Status: Done
Files changed:
- path
Commands run:
- command -> result
Blocked: none
Ready for: human commit
```

The human commits each part with the supplied message, then tells the agent to continue.

### Commit 1 — Shared primitives and errors

```text
feat(T05): add shared API primitives and error envelope
```

Create `common.py`, `errors.py`, package `__init__.py` files, and `test_api_contract_models.py`.

`common.py` must define:

- `UtcDatetime`: aware datetime, serialized as ISO 8601 UTC with `Z` and seconds precision.
- `CalendarDate`, `Version` (`>=1`), `Cursor` (1–512 characters).
- `PageMeta`: required nullable `next_cursor`, required `has_more`; reject `has_more` when it disagrees with `next_cursor`.
- `Page[T]`: `PageMeta` plus `items`.
- `PageParams`: nullable `cursor`, `limit` default 20, range 1–100.
- `AsyncOperation`: `resource_id`, `status`, `status_url`, required nullable `retry_after_seconds`, `updated_at`.

`errors.py` must define:

- `FieldError`: `field` (1–200), `code` (1–64), `message` (1–500).
- `ErrorDetail`: `code`, `message`, `request_id`, `field_errors`, `retryable`, required nullable `retry_after_seconds`, required nullable `action`.
- `ErrorEnvelope`: `error: ErrorDetail`; attach a schema example with `json_schema_extra`.
- `ERROR_CODES` and `ERROR_ACTIONS` as documented tuples, not validation enums.

Keep nullable response fields required. Do not use `datetime.utcnow()`.

Run:

```powershell
python -m pytest backend\tests\test_api_contract_models.py
python -m ruff format backend\src\memora\api\v1 backend\tests\test_api_contract_models.py
python -m ruff check backend\src\memora\api\v1 backend\tests\test_api_contract_models.py
```

### Commit 2 — Headers and bearer security

```text
feat(T05): add shared request headers and bearer security
```

`headers.py`:

- `RequestHeaders`: required `X-Correlation-ID` UUID, required `X-Client-Version` (1–50), required `X-Platform` (`android`/`ios`), optional `Accept-Language` (max 35).
- `IdempotencyHeaders`: required `Idempotency-Key` (16–255).
- Use aliases and `populate_by_name=True`.

Use a model in a route as:

```python
headers: Annotated[RequestHeaders, Header()]
```

Do not use `Depends()` on the model; FastAPI treats those fields as query parameters.

`security.py`:

```python
bearer_auth = HTTPBearer(
    scheme_name="bearerAuth",
    description="Short-lived OIDC-issued access token.",
    auto_error=False,
)
```

Attach it to future routes with `dependencies=[Depends(bearer_auth)]`. FastAPI route decorators do not accept a `security=` keyword argument. `auto_error=False` lets T06 return the shared `token_missing` envelope.

Run the model tests and Ruff checks for the changed files.

### Commit 3 — Operation IDs and inventory

```text
feat(T05): register stable operation IDs for the v1 surface
```

Create `operation_ids.py` with a `StrEnum` and `OPERATION_IDS = frozenset(item.value for item in OperationId)`.

Rules:

- lowerCamelCase.
- `/v1` IDs start with a verb.
- Existing `healthLive` and `healthReady` are grandfathered.
- Every FastAPI route passes `operation_id=` explicitly.
- Published IDs are permanent.

Copy the table from Appendix A into `contracts/openapi/operation-inventory.md`.

Add `test_openapi_contract.py` with a uniqueness/camelCase/registry test.

Run:

```powershell
python -m pytest backend\tests\test_openapi_contract.py
python -m ruff format backend\src\memora\api\operation_ids.py backend\tests\test_openapi_contract.py
python -m ruff check backend\src\memora\api\operation_ids.py backend\tests\test_openapi_contract.py
```

### Commit 4 — OpenAPI builder and guards

```text
feat(T05): add OpenAPI contract metadata and guards
```

`openapi.py` must:

- Build with `get_openapi(..., openapi_version="3.1.0", routes=app.routes)`.
- Inject `bearerAuth`, common parameters, common response headers, and shared schemas.
- Include tags for health, session, profile, curriculum, learning updates, verification, missions, progress, rewards, reports and privacy.
- Include `COMMON_ERROR_RESPONSES` for 400, 401, 403, 404, 409, 413, 415, 422, 429 and 503, each using `ErrorEnvelope`.
- Cache the schema on `app.openapi_schema`.
- Validate before returning.

Guard rules:

- Only `/v1` and `/health/*` paths are allowed.
- Every operation ID is registered and unique.
- Every operation has tags and responses.
- Every `/v1` operation has `security: [{"bearerAuth": []}]`.
- Every mutation references `Idempotency-Key` unless it uses `client_operation_id` or is naturally idempotent. Accept either a component `$ref` or an inline parameter named `Idempotency-Key`.
- Every 4xx/5xx response references `#/components/schemas/ErrorEnvelope`.

Create an empty `v1/router.py` with `APIRouter(prefix="/v1")`.

Modify `main.py` to include the v1 router and install the custom builder:

```python
def openapi_schema() -> dict[str, Any]:
    return custom_openapi(app)

app.openapi = openapi_schema  # type: ignore[method-assign]
```

Future route requirements:

- `operation_id=OperationId.NAME`
- non-empty `tags`
- `dependencies=[Depends(bearer_auth)]`
- `responses=COMMON_ERROR_RESPONSES` merged with success responses
- `Annotated[IdempotencyHeaders, Header()]` for mutations that use a key

FastAPI adds a default 422 `HTTPValidationError` when a route has parameters or a body. Passing `responses=COMMON_ERROR_RESPONSES` overrides it with `ErrorEnvelope`.

Add tests for:

- Shared components and `ErrorEnvelope` example.
- Health operation IDs.
- Unregistered ID and duplicate ID rejection.
- Undocumented path rejection.
- Missing bearer rejection.
- Non-envelope 4xx rejection.
- Missing idempotency rejection.
- Positive `/v1` operation with `Depends(bearer_auth)`, `IdempotencyHeaders` and `COMMON_ERROR_RESPONSES`.

Run:

```powershell
python -m pytest backend\tests\test_openapi_contract.py
python -m ruff format backend\src\memora\api backend\src\memora\main.py backend\tests\test_openapi_contract.py
python -m ruff check backend\src\memora\api backend\src\memora\main.py backend\tests\test_openapi_contract.py
```

### Commit 5 — Reviewed OpenAPI artifact

```text
feat(T05): publish reviewed OpenAPI artifact
```

Create `export_openapi.py` with:

- `canonical_document(app=None)` returning sorted keys, two-space indent, UTF-8, LF and one trailing newline.
- `write_document(path)`.
- `document_is_current(path)` rejecting missing files, CRLF and stale content.
- `--output` and `--check` CLI flags.

Generate and test:

```powershell
python -m memora.api.export_openapi --output contracts\openapi\memora-v1.json
python -m memora.api.export_openapi --check --output contracts\openapi\memora-v1.json
python -m pytest backend\tests\test_openapi_artifact.py
```

Add artifact tests for current content, no `localhost`/`127.0.0.1`, no CRLF and deterministic output.

Update `contracts/openapi/README.md`: the artifact is generated by T05 and must be regenerated with the command above.

The artifact must contain health paths and shared components only. It must not contain `servers` or environment URLs.

### Commit 6 — Pinned generator and tooling

```text
chore(T05): pin OpenAPI generator and add contract scripts
```

`tools/contracts/openapi-generator.json`:

```json
{
  "version": "7.26.0",
  "url": "https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/7.26.0/openapi-generator-cli-7.26.0.jar",
  "sha256": "1760050094997b9cc790cc1350be095f15da8c08a996b184d3eadc4ccda5e35e"
}
```

`tools/contracts/dart-dio-config.yaml`:

```yaml
additionalProperties:
  pubName: memora_api_client
  pubVersion: 0.1.0
  pubDescription: Generated Dart client for the Memora /v1 API. Do not edit by hand.
  pubRepository: https://github.com/Kavee-ginty/Memora
  pubHomepage: https://github.com/Kavee-ginty/Memora
  pubAuthor: Memora
  pubAuthorEmail: ""
  pubPublishTo: none
  pubLibrary: memora_api_client.api
  serializationLibrary: built_value
  enumUnknownDefaultCase: true
  useOptional: true
  disallowAdditionalPropertiesIfNotPresent: false
  dateLibrary: core
  sourceFolder: src
```

`tools/contracts/templates/pubspec.mustache` is a one-file override. The generator resolves it from the template-directory root. Copy the generator's dart-dio pubspec template and add only:

```text
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  ...
  json_annotation: '^4.9.0'
```

The override is required because generator 7.26.0 with `useOptional: true` generates `optional.dart` importing `json_annotation` without declaring it. Consumers otherwise fail with `Couldn't resolve the package 'json_annotation'`.

`generate_contracts.py` must:

1. Download the pinned JAR into `tools/.cache/openapi-generator/` and verify SHA-256.
2. Run `python -m memora.api.export_openapi` with the backend `src` on `PYTHONPATH`.
3. Run `java -jar <jar> validate -i contracts/openapi/memora-v1.json`.
4. `--write`: regenerate `contracts/dart/memora_api_client/`, run `dart pub get`, `build_runner` and `dart format lib`.
5. `--check`: regenerate into `tools/.cache/contract-check/`, copy the committed `pubspec.lock`, run `dart pub get --enforce-lockfile` and `build_runner`, then compare every file.
6. Fail on stale, missing or unexpected files.

Add to `.gitignore`:

```text
tools/.cache/
```

Do not run `--write` until Commit 7.

### Commit 7 — Generate and commit the Dart client

```text
chore(T05): generate Dart API client
```

```powershell
python tools\contracts\generate_contracts.py --write
```

Confirm:

- `json_annotation` is under `dependencies`.
- SDK floor is Dart 3.
- `error_envelope.dart`, `error_detail.dart`, `field_error.dart`, `page_meta.dart`, `async_operation.dart` and the health response model exist.
- `serializers.dart` lists the shared models.

Check:

```powershell
Push-Location contracts\dart\memora_api_client
dart pub get
dart run build_runner build
dart analyze --no-fatal-warnings
Pop-Location
```

Two warnings are expected: an unused `built_value/json_object.dart` import and a raw `Map` in `optional.dart`. Use `--no-fatal-warnings`; never edit generated files.

Commit the client. The generated `.gitignore` ignores `pubspec.lock`; force-add it:

```powershell
git add contracts\dart\memora_api_client
git add -f contracts\dart\memora_api_client\pubspec.lock
```

Update `contracts/dart/README.md`: generated from the reviewed artifact, never hand-edited, regenerate with the script, lock file intentionally committed, consumers set `basePathOverride`, repositories wrap the client.

### Commit 8 — Dart serialization tests

```text
test(T05): verify generated Dart serialization contracts
```

Create `contracts/dart/memora_api_client_contract_tests/` with:

- `pubspec.yaml` depending on the client via `path: ../memora_api_client` and `test`.
- Committed `pubspec.lock`.
- `test/serialization_test.dart`.

Test:

- Documented `ErrorEnvelope` example.
- Unknown additive fields inside the envelope and inside `error`.
- `PageMeta` with null and non-null cursor.
- `AsyncOperation` UTC timestamp round-trip.
- `Optional` absent versus present null.

Run:

```powershell
Push-Location contracts\dart\memora_api_client_contract_tests
dart pub get
dart format .
dart analyze --no-fatal-warnings
dart test
Pop-Location
```

Use synthetic identifiers and copy only.

### Commit 9 — Contract CI

```text
ci(T05): block OpenAPI and client drift
```

Create `.github/workflows/contracts.yml` for pull requests and pushes to `develop`/`main`, triggered by backend API, contract, tooling and workflow changes.

Steps:

1. Checkout.
2. Python 3.12 with pip cache keyed on `backend/requirements-dev.lock`.
3. Install the dev lock and editable backend.
4. Java 21 (Temurin).
5. Dart 3.13.0.
6. Cache `tools/.cache/openapi-generator`.
7. Run the three backend contract test files.
8. Run `python tools/contracts/generate_contracts.py --check`.
9. In `contracts/dart/memora_api_client`: `dart pub get --enforce-lockfile`, then `dart analyze --no-fatal-warnings`.
10. In `contracts/dart/memora_api_client_contract_tests`: `dart pub get --enforce-lockfile`, then `dart analyze --no-fatal-warnings`, then `dart test`.

Resolve dependencies before analyzing. `dart analyze` does not run `pub get` automatically.

This workflow is separate from T02's. Do not edit T02's workflow.

### Commit 10 — Documentation

```text
docs(T05): document the contract pipeline
```

Update `contracts/README.md`, `contracts/openapi/README.md`, `contracts/dart/README.md`, `backend/README.md` and `tools/README.md`.

Document:

- Artifact is the reviewed source of truth.
- Generated files are never hand-edited.
- Schema changes require regeneration in the same PR.
- Breaking changes require a new major path.
- Operation IDs are permanent.
- Optional additive response fields are allowed; removals and renames are breaking.
- Generator cache is ignored; client lock file is committed.
- Template override exists for the `useOptional` dependency bug.

### Commit 11 — Review status

```text
docs(T05): mark OpenAPI pipeline ready for review
```

The human sets T05 to **Review** and keeps the owner. Leave T08 Blocked until T05 is merged and Done. Do not edit the task table or make this commit.

## 6. Verification

```powershell
python -m pytest backend\tests\test_api_contract_models.py backend\tests\test_openapi_contract.py backend\tests\test_openapi_artifact.py
python -m ruff format --check backend
python -m ruff check backend
python tools\contracts\generate_contracts.py --check
Push-Location contracts\dart\memora_api_client
dart pub get --enforce-lockfile
dart analyze --no-fatal-warnings
Pop-Location
Push-Location contracts\dart\memora_api_client_contract_tests
dart pub get --enforce-lockfile
dart analyze --no-fatal-warnings
dart test
Pop-Location
```

Expected: backend tests pass, Ruff passes, drift check passes, generated client has only the two known analyzer warnings, Dart tests pass.

## 7. Gotchas

- **`json_annotation` missing:** the template override was not applied or is in the wrong location. It must be `tools/contracts/templates/pubspec.mustache`.
- **FastAPI 422 uses `HTTPValidationError`:** pass `responses=COMMON_ERROR_RESPONSES` on routes with parameters or bodies.
- **Bearer security missing:** attach `Depends(bearer_auth)`; do not pass `security=` to the decorator.
- **Idempotency guard false negative:** accept both component `$ref` and inline `Idempotency-Key`.
- **`dart analyze` fails in CI:** run `dart pub get --enforce-lockfile` first.
- **CRLF artifact:** `export_openapi` writes LF and the check rejects CRLF.
- **`pubspec.lock` missing:** force-add it; the generated `.gitignore` ignores it.
- **Generator "Unused model" warnings:** expected because shared models are not referenced by health paths; the validator exits successfully.
- **OpenAPI 3.1.0 rejection:** do not silently downgrade; change the constant and artifact together.

## 8. PR handoff

Title:

```text
T05: OpenAPI models and generated client pipeline
```

Include:

- Task ID and branch.
- Scope: shared contract foundation; no business endpoints.
- Files changed.
- Verification commands and results.
- Specification sections: API 1–7 and 20–22; TRD 6.
- Risks: generator template override; `develop`/`main` documentation mismatch; T02 CI coordination.
- Confirmation: no secrets, tokens, real learning text or production data.

## Appendix A — Operation inventory

Copy this table to `contracts/openapi/operation-inventory.md`.

| Domain | Method | Path | Operation ID | Auth | Idempotency | Owner |
| --- | --- | --- | --- | --- | --- | --- |
| Health | GET | `/health/live` | `healthLive` | Public | Read | T01 |
| Health | GET | `/health/ready` | `healthReady` | Public | Read | T02 |
| Session | GET | `/v1/session/bootstrap` | `bootstrapSession` | Bearer | Read | T06 |
| Session | POST | `/v1/session/revoke` | `revokeSession` | Bearer | Header | T06 |
| Session | POST | `/v1/devices` | `registerDevice` | Bearer | Header | T06 |
| Session | DELETE | `/v1/devices/{device_id}` | `deleteDevice` | Bearer | Natural | T06 |
| Profile | GET | `/v1/profile` | `getProfile` | Bearer | Read | T17 |
| Profile | PATCH | `/v1/profile` | `updateProfile` | Bearer | Version + header | T17 |
| Profile | GET | `/v1/profile/preferences` | `getProfilePreferences` | Bearer | Read | T17 |
| Profile | PATCH | `/v1/profile/preferences` | `updateProfilePreferences` | Bearer | Version + header | T17 |
| Consent | GET | `/v1/consent` | `getConsent` | Bearer | Read | T06 |
| Consent | POST | `/v1/consent/acceptances` | `acceptConsent` | Bearer | Header | T06 |
| Home | GET | `/v1/home` | `getHome` | Bearer | Read | T13/T15 |
| Curriculum | GET | `/v1/subjects` | `listSubjects` | Bearer | Read | T08 |
| Curriculum | GET | `/v1/subjects/{subject_id}` | `getSubject` | Bearer | Read | T08 |
| Curriculum | GET | `/v1/subjects/{subject_id}/learning-path` | `getLearningPath` | Bearer | Read | T08 |
| Curriculum | GET | `/v1/subjects/{subject_id}/concept-progress` | `listConceptProgress` | Bearer | Read | T11/T15 |
| Curriculum | GET | `/v1/concepts/{concept_id}/history` | `getConceptHistory` | Bearer | Read | T11 |
| Learning | POST | `/v1/learning-updates` | `createLearningUpdate` | Bearer | Header | T09 |
| Learning | GET | `/v1/learning-updates` | `listLearningUpdates` | Bearer | Read | T09 |
| Learning | GET | `/v1/learning-updates/{update_id}` | `getLearningUpdate` | Bearer | Read | T09 |
| Learning | PATCH | `/v1/learning-updates/{update_id}` | `updateLearningUpdate` | Bearer | Version + header | T09 |
| Learning | DELETE | `/v1/learning-updates/{update_id}` | `deleteLearningUpdate` | Bearer | Header | T09 |
| Learning | POST | `/v1/learning-updates/{update_id}/uploads` | `createUploadGrant` | Bearer | Header | T09 |
| Learning | POST | `/v1/learning-updates/{update_id}/uploads/{upload_id}/finalize` | `finalizeUpload` | Bearer | Header | T09 |
| Learning | POST | `/v1/learning-updates/{update_id}/retry` | `retryLearningUpdate` | Bearer | Header | T09 |
| Verification | GET | `/v1/learning-updates/{update_id}/candidates` | `listExtractionCandidates` | Bearer | Read | T09 |
| Verification | POST | `/v1/learning-updates/{update_id}/verification-decisions` | `submitVerificationDecisions` | Bearer | Version + header | T09 |
| Verification | GET | `/v1/learning-updates/{update_id}/preview` | `previewLearningPath` | Bearer | Read | T09 |
| Verification | POST | `/v1/learning-updates/{update_id}/commit` | `commitLearningUpdate` | Bearer | Header | T09 |
| Missions | GET | `/v1/missions/today` | `getTodayMission` | Bearer | Read | T13 |
| Missions | GET | `/v1/missions/{mission_id}` | `getMission` | Bearer | Read | T13 |
| Missions | POST | `/v1/missions/{mission_id}/start` | `startMission` | Bearer | Header | T13 |
| Missions | GET | `/v1/missions/{mission_id}/items/{item_id}` | `getMissionItem` | Bearer | Read | T13 |
| Missions | POST | `/v1/missions/{mission_id}/items/{item_id}/attempts` | `submitAttempt` | Bearer | `client_operation_id` | T13 |
| Missions | POST | `/v1/missions/{mission_id}/items/{item_id}/skip` | `skipMissionItem` | Bearer | Header | T13 |
| Missions | POST | `/v1/missions/{mission_id}/pause` | `pauseMission` | Bearer | Header | T13 |
| Missions | POST | `/v1/missions/{mission_id}/complete` | `completeMission` | Bearer | Header | T13 |
| Missions | GET | `/v1/missions/{mission_id}/results` | `getMissionResults` | Bearer | Read | T13 |
| Progress | GET | `/v1/seabed` | `getSeabed` | Bearer | Read | T15 |
| Progress | GET | `/v1/seabed/reefs/{subject_id}` | `getReef` | Bearer | Read | T15 |
| Progress | GET | `/v1/progress/statistics` | `getProgressStatistics` | Bearer | Read | T15 |
| Rewards | GET | `/v1/rewards` | `listRewards` | Bearer | Read | T15 |
| Rewards | PATCH | `/v1/rewards/{reward_grant_id}` | `updateRewardPlacement` | Bearer | Version + header | T15 |
| Reports | POST | `/v1/questions/{question_version_id}/reports` | `createQuestionReport` | Bearer | Header | T12 |
| Reports | GET | `/v1/question-reports` | `listQuestionReports` | Bearer | Read | T12 |
| Reports | GET | `/v1/question-reports/{report_id}` | `getQuestionReport` | Bearer | Read | T12 |
| Privacy | POST | `/v1/privacy/exports` | `createPrivacyExport` | Bearer + recent auth | Header | T20 |
| Privacy | GET | `/v1/privacy/exports/{request_id}` | `getPrivacyExport` | Bearer | Read | T20 |
| Privacy | POST | `/v1/privacy/deletions` | `createPrivacyDeletion` | Bearer + recent auth | Header | T20 |
| Privacy | GET | `/v1/privacy/deletions/{request_id}` | `getPrivacyDeletion` | Bearer | Read | T20 |
| Privacy | POST | `/v1/privacy/deletions/{request_id}/cancel` | `cancelPrivacyDeletion` | Bearer | Header | T20 |
