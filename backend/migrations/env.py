import os
from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool
from sqlalchemy.engine import make_url

from memora.db.env_file import database_url_from_env_file

DEFAULT_CONNECT_TIMEOUT_SECONDS = 10

config = context.config
if config.config_file_name:
    fileConfig(config.config_file_name)

database_url = os.getenv("MEMORA_DATABASE_URL") or database_url_from_env_file()
if not database_url:
    raise RuntimeError("MEMORA_DATABASE_URL is required to run database migrations")
config.set_main_option("sqlalchemy.url", database_url.replace("%", "%%"))


def migration_connect_args() -> dict[str, int]:
    """Bound how long Alembic waits for an unreachable PostgreSQL server."""
    if make_url(database_url).get_backend_name() != "postgresql":
        return {}

    raw_timeout = os.getenv(
        "MEMORA_DB_CONNECT_TIMEOUT_SECONDS", str(DEFAULT_CONNECT_TIMEOUT_SECONDS)
    )
    try:
        timeout = int(raw_timeout)
    except ValueError as exc:
        raise RuntimeError("MEMORA_DB_CONNECT_TIMEOUT_SECONDS must be an integer") from exc
    if timeout <= 0:
        raise RuntimeError("MEMORA_DB_CONNECT_TIMEOUT_SECONDS must be greater than zero")
    return {"connect_timeout": timeout}


def run_migrations_offline() -> None:
    context.configure(
        url=config.get_main_option("sqlalchemy.url"),
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
        connect_args=migration_connect_args(),
    )
    with connectable.connect() as connection:
        context.configure(connection=connection)
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
