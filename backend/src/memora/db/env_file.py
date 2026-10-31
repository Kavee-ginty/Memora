"""Small local-only ``.env`` reader for host tools that run before app settings.

Alembic needs ``MEMORA_DATABASE_URL`` before importing the application settings.
This helper keeps the developer convenience of one repository ``.env`` file without
adding a runtime dependency or changing the deployed-environment contract: explicit
process environment values always win, and a missing file is not an error.
"""

from __future__ import annotations

import os
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parents[3]
REPOSITORY_ROOT = BACKEND_ROOT.parent
DEFAULT_ENV_FILE = REPOSITORY_ROOT / ".env"
ENV_FILE_OVERRIDE = "MEMORA_ENV_FILE"


def read_dotenv(path: Path) -> dict[str, str]:
    """Read simple KEY=VALUE lines, ignoring comments, blanks and optional quotes."""
    values: dict[str, str] = {}
    if not path.is_file():
        return values

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        if line.startswith("export "):
            line = line.removeprefix("export ").lstrip()
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
            value = value[1:-1]
        if key:
            values[key] = value
    return values


def database_url_from_env_file(env_file: str | None = None) -> str | None:
    """Return a local database URL, preferring the explicit override path."""
    path = Path(env_file) if env_file else Path(os.getenv(ENV_FILE_OVERRIDE, DEFAULT_ENV_FILE))
    value = read_dotenv(path).get("MEMORA_DATABASE_URL", "").strip()
    return value or None
