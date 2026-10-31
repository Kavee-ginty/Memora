import base64
import binascii
from functools import lru_cache
from ipaddress import ip_address
from typing import Literal, Self
from urllib.parse import urlparse

from pydantic import Field, SecretStr, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import make_url

Environment = Literal["local", "development", "staging", "production"]

LOCAL_DATABASE_URL = "postgresql+psycopg://memora:change-for-local-only@127.0.0.1:5432/memora"
LOCAL_DATABASE_HOSTS = frozenset(
    {"localhost", "127.0.0.1", "::1", "postgres", "host.docker.internal"}
)


def is_local_database_host(host: str) -> bool:
    normalized = host.rstrip(".").lower()
    if normalized in LOCAL_DATABASE_HOSTS:
        return True
    try:
        address = ip_address(normalized)
    except ValueError:
        return False
    mapped = getattr(address, "ipv4_mapped", None)
    return address.is_loopback or address.is_unspecified or bool(mapped and mapped.is_loopback)


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=("../.env", ".env"),
        env_prefix="MEMORA_",
        extra="ignore",
    )

    environment: Environment = "local"
    log_level: str = "INFO"
    database_url: str | None = Field(default=None, repr=False)
    supabase_url: str | None = None
    supabase_publishable_key: SecretStr | None = Field(default=None, repr=False)
    supabase_service_role_key: SecretStr | None = Field(default=None, repr=False)
    recent_auth_window_seconds: int = Field(default=600, ge=60, le=3600)
    default_timezone: str = "Asia/Colombo"
    default_locale: str = "en-LK"
    device_encryption_key: SecretStr | None = Field(default=None, repr=False)
    device_fingerprint_key: SecretStr | None = Field(default=None, repr=False)
    consent_terms_version: str | None = None
    consent_privacy_version: str | None = None
    consent_material_processing_version: str | None = None
    consent_model_processing_version: str | None = None
    consent_notifications_version: str | None = None

    ingestion_encryption_key: SecretStr | None = Field(default=None, repr=False)
    extraction_provider: Literal["deterministic", "openrouter"] = "deterministic"
    openrouter_api_key: SecretStr | None = Field(default=None, repr=False)
    openrouter_model: str | None = None
    openrouter_timeout_seconds: int = Field(default=60, ge=5, le=300)
    upload_max_files: int = Field(default=5, ge=1, le=20)
    upload_max_bytes: int = Field(default=25 * 1024 * 1024, ge=1024)
    upload_grant_ttl_seconds: int = Field(default=900, ge=60, le=86400)
    ingestion_expiry_hours: int = Field(default=72, ge=1, le=720)
    verification_expiry_hours: int = Field(default=72, ge=1, le=720)
    object_storage_provider: Literal["memory", "s3"] = "memory"
    object_storage_endpoint: str | None = None
    object_storage_region: str = "us-east-1"
    object_storage_bucket: str | None = None
    object_storage_access_key: SecretStr | None = Field(default=None, repr=False)
    object_storage_secret_key: SecretStr | None = Field(default=None, repr=False)

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
            if not parsed.host or is_local_database_host(parsed.host):
                raise ValueError(
                    "MEMORA_DATABASE_URL must use a managed, non-local host "
                    "in staging and production"
                )
            if not parsed.database:
                raise ValueError(
                    "MEMORA_DATABASE_URL must include a database name in staging and production"
                )

        self.database_url = database_url

        if self.supabase_url is not None:
            self.supabase_url = self.supabase_url.strip().rstrip("/")
            if self.supabase_url:
                parsed_supabase = urlparse(self.supabase_url)
                if parsed_supabase.scheme != "https" or not parsed_supabase.netloc:
                    raise ValueError("MEMORA_SUPABASE_URL must be an HTTPS URL")

        if self.environment in {"staging", "production"}:
            required = {
                "MEMORA_SUPABASE_URL": self.supabase_url,
                "MEMORA_SUPABASE_PUBLISHABLE_KEY": self.supabase_publishable_key,
                "MEMORA_DEVICE_ENCRYPTION_KEY": self.device_encryption_key,
                "MEMORA_DEVICE_FINGERPRINT_KEY": self.device_fingerprint_key,
                "MEMORA_CONSENT_TERMS_VERSION": self.consent_terms_version,
                "MEMORA_CONSENT_PRIVACY_VERSION": self.consent_privacy_version,
                "MEMORA_CONSENT_MATERIAL_PROCESSING_VERSION": (
                    self.consent_material_processing_version
                ),
                "MEMORA_CONSENT_MODEL_PROCESSING_VERSION": (self.consent_model_processing_version),
                "MEMORA_CONSENT_NOTIFICATIONS_VERSION": self.consent_notifications_version,
            }
            missing = [
                name
                for name, value in required.items()
                if value is None
                or (isinstance(value, SecretStr) and not value.get_secret_value().strip())
                or (isinstance(value, str) and not value.strip())
            ]
            if missing:
                raise ValueError(f"Missing required identity settings: {', '.join(missing)}")
            for name, value in (
                ("MEMORA_DEVICE_ENCRYPTION_KEY", self.device_encryption_key),
                ("MEMORA_DEVICE_FINGERPRINT_KEY", self.device_fingerprint_key),
            ):
                try:
                    decoded = base64.b64decode(value.get_secret_value(), validate=True)  # type: ignore[union-attr]
                except (binascii.Error, ValueError) as exc:
                    raise ValueError(f"{name} must be valid base64") from exc
                if len(decoded) != 32:
                    raise ValueError(f"{name} must decode to exactly 32 bytes")
            unapproved = [
                name
                for name, version in (
                    ("MEMORA_CONSENT_TERMS_VERSION", self.consent_terms_version),
                    ("MEMORA_CONSENT_PRIVACY_VERSION", self.consent_privacy_version),
                    (
                        "MEMORA_CONSENT_MATERIAL_PROCESSING_VERSION",
                        self.consent_material_processing_version,
                    ),
                    (
                        "MEMORA_CONSENT_MODEL_PROCESSING_VERSION",
                        self.consent_model_processing_version,
                    ),
                    (
                        "MEMORA_CONSENT_NOTIFICATIONS_VERSION",
                        self.consent_notifications_version,
                    ),
                )
                if version and version.startswith("unapproved-")
            ]
            if unapproved:
                raise ValueError(f"Unapproved consent policy versions: {', '.join(unapproved)}")
        return self

    @property
    def docs_enabled(self) -> bool:
        return self.environment in {"local", "development"}

    @property
    def oidc_issuer(self) -> str | None:
        return f"{self.supabase_url}/auth/v1" if self.supabase_url else None

    @property
    def oidc_jwks_url(self) -> str | None:
        return f"{self.oidc_issuer}/.well-known/jwks.json" if self.oidc_issuer else None

    @property
    def consent_policy_versions(self) -> dict[str, str]:
        values = {
            "terms": self.consent_terms_version,
            "privacy": self.consent_privacy_version,
            "material_processing": self.consent_material_processing_version,
            "model_processing": self.consent_model_processing_version,
            "notifications": self.consent_notifications_version,
        }
        return {name: version for name, version in values.items() if version is not None}


@lru_cache
def get_settings() -> Settings:
    return Settings()
