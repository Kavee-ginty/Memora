# Memora backend

The backend is a FastAPI modular monolith with a separate worker entry point. This baseline intentionally contains only application configuration and health endpoints. Domain modules, migrations and `/v1` resources belong to later CPM tasks.

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --require-hashes -r requirements-dev.lock
python -m pip install --no-deps -e .
pytest
uvicorn memora.main:app --reload
```

Create or update the local database and apply foundational seeds:

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
