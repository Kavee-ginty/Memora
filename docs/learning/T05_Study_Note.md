# Memora T05 study note

This note explains the shared API contract and generated-client pipeline implemented
in T05. It is a guide to the code, not a replacement for the specifications.

## The big picture

T05 turns the API contract into a generated, reviewed artifact instead of a set of
hand-written mobile DTOs:

```text
FastAPI models + operation registry
        ↓
custom OpenAPI builder and guards
        ↓
contracts/openapi/memora-v1.json          (reviewed)
        ↓
pinned openapi-generator 7.26.0
        ↓
contracts/dart/memora_api_client/         (generated)
        ↓
mobile repositories → Riverpod state → screens
```

The important consequence is that a backend schema change cannot silently diverge
from the mobile client. Regeneration is deterministic, and CI runs a drift check.

T05 was merged to `develop` in PR #11. The definition of done at the end records
the completed repository and review evidence.

## 1. Pydantic is the source of truth

The backend defines shared request, response and error shapes in
`backend/src/memora/api/v1/schemas/`. FastAPI converts those models into OpenAPI, so
the reviewed artifact and the Dart client are both derived from one definition.

`common.py` contains the primitives reused by later resources:

- `UtcDatetime` — aware UTC datetime, serialized to JSON with `Z` and seconds
  precision.
- `CalendarDate`, `Version` (`>= 1`) and `Cursor` (1–512 characters).
- `PageMeta` — required nullable `next_cursor` and required `has_more`, with a
  validator that keeps the two consistent.
- `Page[T]` — `PageMeta` plus `items`.
- `PageParams` — nullable cursor, limit default 20, range 1–100.
- `AsyncOperation` — resource ID, status, status URL, required nullable retry
  delay and UTC update time.

```python
def _serialize_utc_datetime(value: datetime) -> str:
    return value.astimezone(UTC).isoformat(timespec="seconds").replace("+00:00", "Z")

UtcDatetime = Annotated[
    AwareDatetime,
    PlainSerializer(_serialize_utc_datetime, return_type=str, when_used="json"),
]
```

The custom serializer matters because Dart and Python otherwise produce different
date strings. The contract is explicit: UTC, `Z`, seconds — not a local time and
not microseconds.

`PageMeta` demonstrates validation at the model boundary rather than trusting every
caller:

```python
@model_validator(mode="after")
def _validate_cursor(self) -> PageMeta:
    if self.has_more != (self.next_cursor is not None):
        raise ValueError("has_more must be true exactly when next_cursor is present")
    return self
```

Read: `backend/src/memora/api/v1/schemas/common.py` and
`backend/tests/test_api_contract_models.py`.

## 2. The shared error envelope

Every API failure uses one shape, defined in `errors.py`:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Check the highlighted fields and try again.",
    "request_id": "01J0000000000000000000000",
    "field_errors": [
      {
        "field": "preferred_time",
        "code": "invalid_time",
        "message": "Enter a valid local time."
      }
    ],
    "retryable": false,
    "retry_after_seconds": null,
    "action": "correct_input"
  }
}
```

The example is attached to the Pydantic model with `json_schema_extra`, so it
travels into the OpenAPI artifact and becomes the fixture used by the Dart
serialization test.

`ERROR_CODES` and `ERROR_ACTIONS` are documented tuples, not validation enums. They
record the vocabulary without making every new code a breaking schema change. A
client still reads `code` and `action` as strings and decides how to behave.

Unknown fields are ignored by Pydantic by default. That is deliberate tolerance for
additive provider metadata; the server does not fail because a client sent a newer
field.

Read: `backend/src/memora/api/v1/schemas/errors.py` and
`backend/tests/test_api_contract_models.py`.

## 3. Headers, bearer auth and idempotency

`headers.py` defines two reusable models:

- `RequestHeaders` — required `X-Correlation-ID` UUID, required
  `X-Client-Version` (1–50), required `X-Platform` (`android`/`ios`) and optional
  `Accept-Language` (max 35).
- `IdempotencyHeaders` — required `Idempotency-Key` (16–255).

Both use field aliases with `populate_by_name=True`, so Python code can use
`correlation_id` while the wire contract uses `X-Correlation-ID`.

FastAPI treats a model passed through `Depends()` as query parameters. For headers,
the route must use the annotated form:

```python
headers: Annotated[RequestHeaders, Header()]
```

`security.py` installs the bearer scheme:

```python
bearer_auth = HTTPBearer(
    scheme_name="bearerAuth",
    description="Short-lived OIDC-issued access token.",
    auto_error=False,
)
```

`auto_error=False` is intentional. `bearer_auth(auto_error=False)` is solely the
credential and schema primitive for OpenAPI declaration and header extraction.
T06 owns token validation and must provide the enforcing request-context
dependency that validates OIDC access tokens and returns the shared
`token_missing` / `token_invalid` / `token_expired` `ErrorEnvelope` (401)
instead of FastAPI's default 403.

Idempotency is enforced by the contract guard, not by every route remembering it:

- `POST`, `PUT`, `PATCH` and `DELETE` must reference `Idempotency-Key`, unless the
  operation is assigned body-based idempotency via required `client_operation_id`
  (`submitAttempt`) or is listed as naturally idempotent (`deleteDevice`).

## 4. Stable operation IDs and the inventory

`operation_ids.py` is a `StrEnum` of 52 permanent IDs, for example:

```python
class OperationId(StrEnum):
    BOOTSTRAP_SESSION = "bootstrapSession"
    SUBMIT_ATTEMPT = "submitAttempt"
    GET_TODAY_MISSION = "getTodayMission"
```

`OPERATION_IDS` is the frozen set used by the guard. Rules:

- lowerCamelCase.
- `/v1` IDs begin with a verb.
- `healthLive` and `healthReady` are grandfathered.
- Published IDs are permanent; renaming one breaks generated method names, traces
  and documentation.

`contracts/openapi/operation-inventory.md` is the human-readable registry. The
backend test parses its table and asserts it matches `OperationId`, so the code and
the document cannot drift.

## 5. Building and guarding the OpenAPI document

`openapi.py` builds the document with OpenAPI 3.1 and then adds the shared
components that FastAPI cannot infer from the health routes alone:

- `bearerAuth` security scheme.
- `IdempotencyKey` and `IfNoneMatch` parameters.
- `X-Correlation-ID` and `X-Request-ID` response headers.
- Shared schemas: `ErrorEnvelope`, `ErrorDetail`, `FieldError`, `PageMeta`,
  `PageParams`, `AsyncOperation`, `RequestHeaders`, `IdempotencyHeaders`.
- The 11 domain tags used by later resources.

The builder validates before returning. A route fails generation when it:

- uses a path outside `/v1` or `/health/*`;
- uses an operation ID that is unregistered or duplicated;
- has no tags or responses;
- is a `/v1` operation without `bearerAuth`;
- is a mutation without idempotency evidence;
- declares a 4xx/5xx response that is not `ErrorEnvelope`.

```python
if path == "/v1" or path.startswith("/v1/"):
    _require(
        operation.get("security") == [{"bearerAuth": []}],
        f"{operation_id} must use bearerAuth",
    )

if method in MUTATION_METHODS:
    _require(
        operation_id in NATURALLY_IDEMPOTENT_OPERATION_IDS
        or operation_id in CLIENT_OPERATION_ID_OPERATION_IDS
        or _has_client_operation_id(schema, operation)
        or _has_idempotency_key(schema, operation),
        f"{operation_id} must reference the Idempotency-Key parameter",
    )
```

The guard tests exercise each rejection plus two positive cases: a header-model
mutation and a `client_operation_id` body. `COMMON_ERROR_RESPONSES` covers 400, 401,
403, 404, 409, 413, 415, 422, 429 and 503.

The current artifact has only `/health/live` and `/health/ready`. The shared error,
auth and idempotency components are prepared for the first real `/v1` resource; they
are not yet exercised by a live private path.

Read: `backend/src/memora/api/openapi.py`,
`backend/src/memora/api/operation_ids.py` and
`backend/tests/test_openapi_contract.py`.

## 6. The reviewed OpenAPI artifact

`export_openapi.py` writes a canonical document:

- sorted keys;
- two-space indent;
- UTF-8 with LF endings;
- exactly one trailing newline;
- no `servers` block or environment URLs.

`--check` compares the committed artifact with a fresh export and rejects missing,
stale or CRLF content. This is what makes the artifact reviewable: a pull request
shows the exact schema change instead of an environment-specific dump.

The artifact is committed, not generated at runtime. The mobile client and CI both
consume the reviewed file.

Read: `backend/src/memora/api/export_openapi.py` and
`backend/tests/test_openapi_artifact.py`.

## 7. The pinned generator and deterministic client

The generator is pinned by version and checksum in
`tools/contracts/openapi-generator.json`:

```json
{
  "version": "7.26.0",
  "sha256": "1760050094997b9cc790cc1350be095f15da8c08a996b184d3eadc4ccda5e35e"
}
```

`tools/contracts/generate_contracts.py` has two modes:

- `--write` — verify the JAR, export and validate the artifact, regenerate
  `contracts/dart/memora_api_client/`, run `dart pub get`, `build_runner` and
  `dart format lib`.
- `--check` — export in check mode, regenerate into
  `tools/.cache/contract-check/`, copy the committed `pubspec.lock`, install with
  `dart pub get --enforce-lockfile`, rebuild, format and compare every file.

The JAR is cached in `tools/.cache/openapi-generator/` and ignored by Git. A cache
miss downloads it from Maven Central and verifies the SHA-256 before use.

`tools/contracts/templates/pubspec.mustache` is the only template override.
Generator 7.26.0 with `useOptional: true` emits `optional.dart` importing
`json_annotation` without declaring it; the override adds the dependency.

Read: `tools/contracts/generate_contracts.py`,
`tools/contracts/dart-dio-config.yaml` and `contracts/dart/README.md`.

## 8. Inside the generated Dart client

The client uses `built_value` models with custom primitive serializers. Each
serializer emits a flat list of key/value pairs; `StandardJsonPlugin` turns that
into a JSON object. The exported `standardSerializers` is the entry point used by
the tests and by `HealthApi`.

`useOptional: true` distinguishes three states for genuinely optional fields:

```dart
final absent = HealthResponse();
final presentNull = HealthResponse(
  (b) => b.status = const Optional.present(null),
);
final present = HealthResponse(
  (b) => b.status = const Optional.present('ok'),
);
```

Serialized results:

```text
absent       → {}
presentNull  → {"status": null}
present      → {"status": "ok"}
```

Required fields stay plain Dart types. Required nullable fields, such as
`ErrorDetail.action`, are `String?` and are always emitted with a value or `null`.
For API-valid examples, use `AsyncOperation`:

```dart
final operation = standardSerializers.deserializeWith(
  AsyncOperation.serializer,
  <String, dynamic>{
    'resource_id': '00000000-0000-4000-8000-000000000001',
    'retry_after_seconds': null,
    'status': 'processing',
    'status_url': '/v1/learning-updates/00000000-0000-4000-8000-000000000001',
    'updated_at': '2026-01-02T03:04:05Z',
  },
);
```

The Dart model reports `updatedAt.isUtc == true` and serializes the same instant
with a `Z` suffix.

`enumUnknownDefaultCase: true` produces an `unknownDefaultOpenApi` member for
component enums such as `RequestHeadersXPlatformEnum`, so a future platform value
does not crash an older client.

The client is configured with `MemoraApiClient(basePathOverride: ...)`. Feature
repositories wrap the generated API/DTOs; screens and Riverpod providers must not
construct URLs or parse raw error JSON.

Read: `contracts/dart/memora_api_client/lib/src/serializers.dart`,
`lib/src/api.dart` and `lib/src/optional.dart`.

## 9. Tests and CI

Backend contract coverage (49 tests):

- 24 model tests — UTC formatting, bounds, page consistency, headers, aliases,
  error envelope example, unknown-field tolerance.
- 17 OpenAPI guard tests — registry/inventory match, shared components, operation
  IDs, negative guards, positive idempotency forms.
- 8 artifact tests — canonical output, no environment URLs, CRLF rejection,
  deterministic writes, CLI check behavior.

Dart coverage:

- 28 generated placeholder tests — they compile the client but contain empty
  bodies; do not count them as behavioral coverage.
- 8 contract tests in `contracts/dart/memora_api_client_contract_tests/` — the
  documented error example, unknown additive fields, pagination cursors, UTC
  timestamp round-trip and `Optional` absent/null/value.

```powershell
python -m pytest backend\tests\test_api_contract_models.py backend\tests\test_openapi_contract.py backend\tests\test_openapi_artifact.py
python tools\contracts\generate_contracts.py --check

Push-Location contracts\dart\memora_api_client
dart pub get --enforce-lockfile
dart analyze --no-fatal-warnings
Pop-Location

Push-Location contracts\dart\memora_api_client_contract_tests
dart pub get --enforce-lockfile
dart test
Pop-Location
```

Three analyzer warnings in the generated client are expected: unused
`built_value/json_object.dart` and `error_envelope.dart` imports in the health
API, plus a raw `Map` in `optional.dart`. The error-envelope import is emitted
for the documented readiness `503` response but is not referenced by the
generated success-return method.
CI no longer merely tolerates them: the contract workflow captures the analyzer
output and fails if the warning set changes, so a new warning cannot be merged
silently.

`.github/workflows/contracts.yml` runs the three backend test files, the drift
check, the generated-client analysis with the warning baseline and the client
contract tests in strict mode (`--fatal-infos`). It triggers on
pull requests and on pushes to `develop`/`main` for backend, contract, contract
tooling and workflow changes.

## 10. Trade-offs and generator constraints

### Health status uses a named one-value enum

The original model used `status: Literal["ok"]`. Generator 7.26.0 with
`useOptional: true` emits `Optional<HealthResponseStatusEnum?>` but does not
define the enum class, so the client does not compile.

The model now declares an explicit `HealthStatus(StrEnum)` with a single `OK`
member. FastAPI emits a named `HealthStatus` schema (`enum: ["ok"]`) and the
generator produces a Dart `HealthStatus` enum with its
`unknownDefaultOpenApi` fallback, so the client compiles and forward-compatible
deserialization keeps working. The inline `const` marker is still absent because
the schema lives on the named enum; restoring it needs a generator template
override or upgrade, but every response still validates against exactly one
value.

### Unknown response fields are tolerated and ignored

The generated custom serializers collect unknown keys in `unhandled` and ignore
them. Per approved API §21 policy, clients must tolerate and ignore unknown
additive response fields without treating them as authoritative or re-emitting
them; this ensures backward compatibility with newer API versions without requiring
client-side round-trip field preservation.

### No live `/v1` path yet

The shared error, auth and idempotency components are ready, but the artifact only
contains health paths. T06 and later tasks add real operations. Cross-user
authorization, replay and pagination behavior belong to T25 once those resources
exist.

### Version drift between local and CI

The client was generated and formatted with Dart 3.12.1 and Java 17 locally; CI
pins Dart 3.13.0 and Java 21. The first PR run must confirm formatter and analyzer
parity.

### Generated tests are placeholders

Every generated `test/*.dart` file is an empty scaffold. The real consumer
guarantees live in the separate contract-test package.

## 11. How T05 fits with later tasks

- **T06** adds session, consent and device routes using `OperationId`, bearer auth,
  `RequestHeaders`, `IdempotencyHeaders` and `COMMON_ERROR_RESPONSES`.
- **T07** consumes generated DTOs through repositories; it must not create its own
  API models.
- **T08** is Ready now that T04 and T05 are Done.
- **T12 and T25** add resource schemas and the full provider/consumer,
  cross-user and idempotency suite.

The rule for later work is simple: edit the Pydantic/model layer, regenerate the
artifact and client in the same change, and let the guard tests catch missing auth
or idempotency.

## Appendix A — operation inventory

Appendix A is already committed as `contracts/openapi/operation-inventory.md`. It
contains 52 operations and matches the implementation guide row for row; the
backend test fails if the table and `OperationId` registry diverge.

| Domain | Operations |
| --- | ---: |
| Health | 2 |
| Session | 4 |
| Profile | 4 |
| Consent | 2 |
| Home | 1 |
| Curriculum | 5 |
| Learning | 8 |
| Verification | 4 |
| Missions | 9 |
| Progress | 3 |
| Rewards | 2 |
| Reports | 3 |
| Privacy | 5 |
| **Total** | **52** |

Keep the canonical copy in `contracts/openapi/`; duplicating the table in another
document would create a second source of truth.

## Definition of Done for T05

T05 is Done only when code, tests, generated artifacts and documentation are
merged, not when the branch merely compiles.

### Contract surface

- [x] Shared primitives, error envelope and schema example.
- [x] Request headers, idempotency header and bearer scheme.
- [x] 52 stable operation IDs and matching operation inventory.
- [x] OpenAPI builder with shared components and contract guards.
- [x] Canonical reviewed artifact with drift detection.
- [x] Pinned generator, deterministic generation script and template override.
- [x] Generated Dart client with serializers and a documented lock-file policy.
- [x] Dart serialization contract tests.
- [x] Separate contract CI workflow.
- [x] Contract, client and CI documentation.

### Verification

- [x] Backend contract tests pass (63).
- [x] Dart contract tests pass (10).
- [x] Generated client analyzes with only the two expected warnings.
- [x] `generate_contracts.py --check` passes locally.
- [x] Ruff format and lint pass on changed backend files.
- [x] CI workflow passes on GitHub.
- [x] Generated client `pubspec.lock` is tracked in Git.
- [x] A fresh GitHub Actions checkout runs `--check` before the explicit client
  `dart pub get` step.

### Review and completion

- [x] Pull request uses the repository template.
- [x] No secrets, tokens, real learning text or production data are present.
- [x] T05 was reviewed with an owner.
- [x] Merge approval is recorded in PR #11.
- [x] T05 is merged to `develop`.
- [x] The task table marks T05 Done and unblocks T08.

T05 satisfies its task-level definition of done.

## Useful testing follow-ups

- Replace or remove the 28 generated placeholder tests once real API resources
  exist.
- Add consumer tests for every future success and error example; today only the
  shared error example is covered.
- T25 adds cross-user authorization, idempotency replay, pagination and
  provider/consumer contract tests against live resources.
- T28 owns load, security and failure testing; they are outside T05.

## Quick self-check

1. Why is the OpenAPI artifact committed instead of generated at build time?
2. What prevents a `/v1` mutation from shipping without idempotency?
3. Why does `bearer_auth` use `auto_error=False`?
4. Why are `ERROR_CODES` tuples instead of a validation enum?
5. What is the difference between `Optional.absent()` and
   `Optional.present(null)` in the generated client?
6. Why does `submitAttempt` enforce `client_operation_id` in the body while other mutations require `Idempotency-Key`?
7. What does `generate_contracts.py --check` compare, and why does it need the
   committed `pubspec.lock`?
8. Why does the health status use a named `HealthStatus` enum, and what still
   differs from `Literal["ok"]` in the artifact?

## Specification map

- API and Integration Contract: sections 1–7 and 20–22.
- TRD: section 6 (API design).
- Task table: T05 acceptance gate; T08 depends on T05 being Done.
- Supporting context: API section 6 (error contract), section 7 (idempotency),
  section 19 (security), and TRD sections 19–20 for verification and traceability.
