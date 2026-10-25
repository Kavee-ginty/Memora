# Continuous integration

The T02 quality baseline is defined in `.github/workflows/ci.yml`. It runs on every pull request, on pushes to `main` and `develop`, and can be started manually. The workflow has `contents: read` permission and does not consume repository or environment secrets.

## Jobs

| Job | Checks | Output |
| --- | --- | --- |
| `Backend format, lint and tests` | Ruff formatting, Ruff lint and backend unit tests. Database-dependent migration tests are excluded here and run in the migration job. | None |
| `Flutter format, analyze and tests` | Dart formatting, Flutter analysis and widget tests | None |
| `Compose configuration` | Resolves the local Compose definition without starting services | None |
| `Migration checks` | Applies T04 migrations to a fresh pgvector database and runs T04 migration tests when that tooling is present; fails clearly if tests exist without the Alembic configuration | None |
| `OpenAPI and Dart client` | Calls the T05 contract workflow: backend contract tests, OpenAPI and Dart client drift, generated-client analysis and client tests | None |
| `Dependency and secret scans` | Hash-locked Python audit, git-history secret scan and repository vulnerability/secret scan | None |
| `Flutter debug APK` | Builds the Android debug APK | `memora-debug-apk` |
| `Backend container build` | Builds and scans the backend image, then creates a CycloneDX SBOM | `memora-backend-image` |
| `CI gate` | Aggregates every T02 job and fails if any required job did not succeed | None |

Configure branch protection to require the `CI gate` check. Do not require the individual T02 jobs separately; the gate reports their results. The gate calls the T05 contract workflow, so contract drift blocks every pull request. Do not require the standalone path-filtered `OpenAPI and Dart client` check separately; it does not report on pull requests that do not touch contract paths.

`CI gate` uses `if: always()` and requires every listed job result to be exactly `success`. A failed, cancelled or skipped required job makes the gate fail. If the entire workflow run is cancelled before the gate starts, GitHub cannot report a gate result; branch protection must treat the missing required check as not passing.

## Ownership boundaries

### T04 migration checks

The `Migration checks` job starts a PostgreSQL 16 service with pgvector. It detects T04-owned files at runtime:

- `backend/alembic.ini` and `backend/migrations/env.py`;
- `backend/tests/test_migrations.py`.

When the Alembic files are present, it applies migrations with `python -m alembic -c alembic.ini upgrade head`. When the migration test file is present, it runs `python -m pytest tests/test_migrations.py` with `MEMORA_TEST_DATABASE_URL` pointing at the same disposable service, so the database-backed migration, seed, downgrade and RLS tests cannot silently skip. The database and credentials are synthetic and exist only for that job. The backend unit-test job excludes `test_migrations.py` when present so the database-dependent test runs once, against pgvector.

If the migration test file is present but `backend/alembic.ini` or `backend/migrations/env.py` is missing, the job fails with an explicit error. It does not run the tests against a database whose schema was never provisioned, and it does not imply that migrations ran. A partial T04 integration must add the Alembic configuration or update this workflow with a documented alternative.

When both the Alembic files and the test file are absent, the job emits a notice and passes. This keeps the fresh-clone baseline green without creating placeholder migrations or claiming that T04 has run. T04 owns the migration environment, schema and tests. If T04 chooses different entry points, that change must update this job with T04 review.

### T05 OpenAPI drift

T05 owns `tools/contracts/generate_contracts.py`, generated OpenAPI, generated Dart clients and their contract workflow. This branch now contains that tooling and `.github/workflows/contracts.yml` after the `develop` merge.

T02's `CI gate` calls the T05 workflow through `workflow_call` as the `OpenAPI and Dart client` job. It does not duplicate the generator, so there is still one source of truth. The called workflow runs the backend contract tests, `python tools/contracts/generate_contracts.py --check`, generated-client analysis and client contract tests.

The standalone `pull_request` and `push` triggers keep their path filters for T05's own runs. Those filters do not apply to a reusable-workflow call, so the gate runs the contract checks on every pull request, including pull requests that do not touch contract paths. The standalone path-filtered check is not a reliable required check; require only `CI gate` in branch protection.

T05 integration checklist:

1. Confirm the merged generator and Dart client are the reviewed artifacts.
2. Confirm the reusable workflow passes on a hosted runner and that the gate reports it.
3. Require `CI gate`, not the standalone path-filtered check, in branch protection.

## Dependency and secret scanning

- **Python dependencies:** `pip-audit 2.10.1` audits both `backend/requirements.lock` and `backend/requirements-dev.lock` with `--require-hashes --strict`. A known vulnerability fails the job.
- **Secret history:** Gitleaks `v8.30.1` scans the full available git history with `--all`, redacts findings, exits with code 1 when a leak is found and fails the job. The container image is pinned by digest.
- **Repository scan:** Trivy `0.76.1` scans repository dependencies, including `backend/requirements.lock` and `mobile/pubspec.lock`, plus configuration and secrets for high or critical findings. Only fixable vulnerabilities block; unfixed findings are excluded because no upstream fix exists. Trivy is pinned by digest.
- **Image scan:** Trivy scans the built backend image. A high/critical report is uploaded, then fixable high/critical findings fail the job. Unfixed base-image findings remain visible in that report.

No scan uses a repository secret, and generated reports are CI artifacts rather than committed files.

## Build artifacts

- `memora-debug-apk` contains `app-debug.apk` from the pinned Flutter 3.47.5 toolchain.
- `memora-backend-image` contains the unsigned backend image tar, a CycloneDX SBOM and a Trivy vulnerability report.
- Artifacts are retained for seven days.
- No job pushes an image, signs an artifact, publishes a package or deploys an environment. Signing and release publication belong to release tasks.

Artifacts produced by a pull request, especially from a fork, are untrusted input. Do not install or deploy them without reviewing the source change.

## Tool versions

| Tool | Version | Pinning |
| --- | --- | --- |
| Python | 3.12 | `actions/setup-python` |
| Flutter / Dart | 3.47.5 / 3.13.4 | `subosito/flutter-action` and `mobile/pubspec.lock` |
| Java | 21 | `actions/setup-java` |
| PostgreSQL | 16 with pgvector | `pgvector/pgvector:pg16` service |
| pip-audit | 2.10.1 | Exact version in the workflow |
| Gitleaks | v8.30.1 | Image tag and digest |
| Trivy | 0.76.1 | Image tag and digest |

Dependency and tool upgrades belong in their owning task. Update the relevant lockfile and this document in the same change. A container digest must be updated deliberately; do not replace it with an unpinned tag.

## Fork and secret safety

- The workflow runs on `pull_request`, not `pull_request_target`.
- Permissions are limited to `contents: read`.
- Checkout credentials are not persisted in the workspace.
- No job reads a repository or environment secret.
- No registry login or push credential is available.
- The Compose job reads only the synthetic values in `.env.example`; it never reads a developer `.env`.
- Gitleaks mounts the checkout read-only and receives only `safe.directory` configuration.
- Docker pulls public scanner images by digest. Pull-request code can still execute in the runner, so artifacts from untrusted pull requests must not be trusted.

## Environment boundaries

CI is verification only. It does not define staging or production infrastructure and does not deploy. The environment matrix, configuration sources and enforced staging/production boundaries are documented in [`environments.md`](environments.md).

- Local development uses the untracked `.env` copied from `.env.example` and the Compose services; data is synthetic.
- Development uses platform configuration and secret management with synthetic or explicitly approved de-identified data.
- Staging uses platform configuration and synthetic data, rejects loopback database hosts and disables API documentation.
- Production uses approved data, platform secret management and the same non-local safeguards as staging.

CI never receives staging or production credentials and never starts a deployment.

## Local checks

From the repository root:

```powershell
.\.venv\Scripts\python.exe -m ruff format --check backend
.\.venv\Scripts\python.exe -m ruff check backend
.\.venv\Scripts\python.exe -m pytest backend\tests --ignore=backend\tests\test_migrations.py

Push-Location mobile
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
Pop-Location

docker compose --env-file .env.example -f infra/compose.yaml config --quiet
```

Backend unit tests do not require a live database. Migration tests are skipped unless `MEMORA_TEST_DATABASE_URL` is set. The Compose check validates configuration only; it does not create containers, volumes or network services.

T04 migration checks run against the local pgvector service. Create a disposable database whose name ends in `_test` or `_ci`; these tests downgrade to base, so never reuse the development database URL. The `createdb` command reports "already exists" on later runs, which is safe to ignore:

```powershell
docker compose --env-file .env -f infra/compose.yaml exec -T postgres createdb -U memora memora_migration_test

$dbPassword = docker compose --env-file .env -f infra/compose.yaml exec -T postgres printenv POSTGRES_PASSWORD
$encoded = [uri]::EscapeDataString($dbPassword.Trim())
$env:MEMORA_DATABASE_URL = "postgresql+psycopg://memora:$encoded@127.0.0.1:5432/memora_migration_test"
$env:MEMORA_TEST_DATABASE_URL = $env:MEMORA_DATABASE_URL

Push-Location backend
..\.venv\Scripts\python.exe -m alembic -c alembic.ini upgrade head
..\.venv\Scripts\python.exe -m pytest tests/test_migrations.py
Pop-Location
```

Use `127.0.0.1`, not `localhost` or the Compose service name `postgres`: only `127.0.0.1` is published to the Windows host, and `postgres` resolves only inside the Compose network. Alembic bounds each connection attempt with `MEMORA_DB_CONNECT_TIMEOUT_SECONDS` (default 10 seconds). The migration fixture refuses a database name that does not end in `_test` or `_ci`, so a copy-paste mistake cannot downgrade the development database.

The contract check imports the FastAPI application, so `Settings` reads the untracked `.env`. If that file contains an invalid or non-`postgresql+psycopg://` database URL, the check stops before comparing artifacts. Export a valid URL for the command, or fix `.env`, before rerunning it.

Verify contract artifacts without writing generated files:

```powershell
.\.venv\Scripts\python.exe tools\contracts\generate_contracts.py --check
```

Run the security checks locally with the same pinned tools:

```powershell
.\.venv\Scripts\python.exe -m pip install pip-audit==2.10.1
.\.venv\Scripts\python.exe -m pip_audit -r backend\requirements.lock --require-hashes --strict --progress-spinner off
.\.venv\Scripts\python.exe -m pip_audit -r backend\requirements-dev.lock --require-hashes --strict --progress-spinner off

docker run --rm -e GIT_CONFIG_COUNT=1 -e GIT_CONFIG_KEY_0=safe.directory -e GIT_CONFIG_VALUE_0=/repo -v "${PWD}:/repo:ro" ghcr.io/gitleaks/gitleaks:v8.30.1@sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f git --redact --no-banner --verbose --exit-code 1 --log-opts=--all /repo

docker run --rm -v "${PWD}:/repo:ro" aquasec/trivy:0.76.1@sha256:790fd66d1697395d8693d1acaa1ea702406a20f109b6fc7bac8db623eca6c06c fs --scanners vuln,secret --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 --no-progress --skip-dirs .git --skip-dirs .venv --skip-dirs mobile/build --skip-dirs mobile/.dart_tool /repo
```

Build and inspect the backend image locally without publishing it:

```powershell
docker build --pull -t memora-backend:ci backend
$artifactDir = Join-Path $env:TEMP 'memora-ci'
New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null
docker save memora-backend:ci -o "$artifactDir\backend-image.tar"
docker run --rm -v "${artifactDir}:/work" aquasec/trivy:0.76.1@sha256:790fd66d1697395d8693d1acaa1ea702406a20f109b6fc7bac8db623eca6c06c image --input /work/backend-image.tar --scanners vuln --format cyclonedx --output /work/backend-image.cdx.json --no-progress
```

## Verification limits

- Hosted GitHub Actions execution is confirmed only after the branch is pushed and the workflow runs.
- T04 migration checks stay skipped only while both the Alembic files and the migration test file are absent. A partial integration that adds tests without the Alembic configuration fails closed.
- OpenAPI drift is T05-owned and runs inside `CI gate` through the reusable T05 workflow. Hosted execution is still unconfirmed until the branch is pushed. Do not require the standalone path-filtered `OpenAPI and Dart client` check directly.
- Local migration tests are validated on Windows against the Compose database through `127.0.0.1`. Hosted CI runs the same tests on Linux against a service container.
- Branch protection is configured in GitHub settings, not in this repository.
- Builds are unsigned and unpushed; deployment and release signing are outside T02.
