from functools import lru_cache
from typing import Literal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=("../.env", ".env"),
        env_prefix="MEMORA_",
        extra="ignore",
    )

    environment: Literal["local", "development", "staging", "production"] = "local"
    log_level: str = "INFO"
    database_url: str = Field(
        default="postgresql+psycopg://memora:memora@localhost:5432/memora",
        repr=False,
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
