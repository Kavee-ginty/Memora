# Memora

Memora is a student-first spaced-repetition mobile application for Sri Lankan GCE Advanced Level Physics. The MVP uses a Flutter client, FastAPI modular monolith and worker, PostgreSQL with pgvector, temporary object storage and a durable queue.

## Repository layout

```text
mobile/             Flutter application
backend/            FastAPI API, worker, migrations and backend tests
contracts/          Generated OpenAPI and shared schema artifacts
content/            Reviewed curriculum and pilot-content sources
infra/              Local and deployment infrastructure definitions
tests/e2e/          Cross-feature black-box tests
tools/docs/         Documentation and diagram builders
docs/               Six specifications, UI references and project plans
```

## Start here

1. Read `AGENTS.md`.
2. Follow `SETUP.md` to install and verify the development tools.
3. Open `docs/project-management/Memora_Development_Task_Table.md`.
4. Claim only a Ready task and use its listed branch.
5. Read the relevant specification sections before coding.

The six Markdown specifications are the implementation authorities. The CPM plan controls task precedence; it does not replace the specifications.

## Backend quick start

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --require-hashes -r requirements-dev.lock
python -m pip install --no-deps -e .
uvicorn memora.main:app --reload
```

## Local services

```powershell
docker compose --env-file .env -f infra/compose.yaml up --build
```

Copy `.env.example` to `.env` first. Never commit `.env`.

## Mobile

Flutter is not bundled in this repository. Use Flutter 3.47.5, then run:

```powershell
cd mobile
flutter pub get
flutter test
flutter run
```

## Current CPM state

`T01` is merged and defines this baseline. `T02`, `T03`, `T04` and `T05` are Ready to be claimed in parallel.
