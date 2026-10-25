from functools import lru_cache
from typing import Literal, Self

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import make_url

Environment = Literal["local", "development", "staging", "production"]

LOCAL_DATABASE_URL = "postgresql+psycopg://memora:change-for-local-only@127.0.0.1:5432/memora"
LOCAL_DATABASE_HOSTS = frozenset(
    {"localhost", "127.0.0.1", "::1", "postgres", "host.docker.internal"}
)


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=("../.env", ".env"),
        env_prefix="MEMORA_",
        extra="ignore",
    )

    environment: Environment = "local"
    log_level: str = "INFO"
    database_url: str | None = Field(default=None, repr=False)

    @model_validator(mode="after")
    def validate_environment_boundaries(self) -> Self:
        database_url = (self.database_url or "").strip()
        if not database_url:
            if self.environment != "local":
                raise ValueError(
                    "MEMORA_DATABASE_URL is required when MEMORA_ENVIRONMENT is not local"
                )
            database_url = LOCAL_DATABASE_URL

        try:
            parsed = make_url(database_url)
        except Exception as exc:
            raise ValueError("MEMORA_DATABASE_URL must be a valid PostgreSQL URL") from exc

        if parsed.drivername != "postgresql+psycopg":
            raise ValueError(
                "MEMORA_DATABASE_URL must use the psycopg driver (postgresql+psycopg://)"
            )

        if self.environment in {"staging", "production"}:
            if not parsed.host or parsed.host in LOCAL_DATABASE_HOSTS:
                raise ValueError(
                    "MEMORA_DATABASE_URL must use a managed, non-local host "
                    "in staging and production"
                )
            if not parsed.database:
                raise ValueError(
                    "MEMORA_DATABASE_URL must include a database name in staging and production"
                )

        self.database_url = database_url
        return self

    @property
    def docs_enabled(self) -> bool:
        return self.environment in {"local", "development"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
