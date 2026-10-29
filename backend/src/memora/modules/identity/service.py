from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import re
import urllib.error
import urllib.request
from datetime import UTC, datetime
from typing import Annotated
from uuid import UUID
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from fastapi import Depends

from memora.api.errors import ApiError
from memora.api.security import AuthenticatedRequest, require_recent_authentication
from memora.api.v1.schemas.identity import (
    CapabilityFlags,
    ConsentAcceptanceRequest,
    ConsentAcceptanceResponse,
    ConsentResponse,
    ConsentStatus,
    DeviceRegistrationRequest,
    DeviceRegistrationResponse,
    ProfilePreferencesResponse,
    ProfilePreferencesUpdateRequest,
    ProfileResponse,
    ProfileSummary,
    ProfileUpdateRequest,
    SessionBootstrapResponse,
    SessionRevokeRequest,
)
from memora.core.config import Settings, get_settings
from memora.db.runtime import database_engine
from memora.modules.identity.repository import IdentityRepository

_REQUIRED_ACCOUNT_CONSENTS = frozenset({"terms", "privacy"})
_REQUIRED_INGESTION_CONSENTS = frozenset(
    {"terms", "privacy", "material_processing", "model_processing"}
)
_LOCALE_PATTERN = re.compile(r"^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$")


class DeviceTokenProtector:
    def __init__(self, encryption_key: bytes, fingerprint_key: bytes) -> None:
        if len(encryption_key) != 32 or len(fingerprint_key) != 32:
            raise ValueError("Device keys must decode to exactly 32 bytes")
        self._cipher = AESGCM(encryption_key)
        self._fingerprint_key = fingerprint_key

    def protect(self, token: str, *, owner: bytes) -> tuple[bytes, str]:
        raw = token.encode("utf-8")
        nonce = os.urandom(12)
        ciphertext = b"\x01" + nonce + self._cipher.encrypt(nonce, raw, owner)
        fingerprint = hmac.new(self._fingerprint_key, raw, hashlib.sha256).hexdigest()
        return ciphertext, fingerprint


class SupabaseAuthClient:
    def __init__(self, url: str, publishable_key: str) -> None:
        self.url = url.rstrip("/")
        self.publishable_key = publishable_key

    def revoke(self, access_token: str, scope: str) -> None:
        provider_scope = {
            "current": "local",
            "other_sessions": "others",
            "all": "global",
        }[scope]
        request = urllib.request.Request(
            f"{self.url}/auth/v1/logout?scope={provider_scope}",
            method="POST",
            headers={
                "apikey": self.publishable_key,
                "Authorization": f"Bearer {access_token}",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=10) as response:
                if response.status not in {200, 204}:
                    raise ApiError(
                        503,
                        "temporarily_unavailable",
                        "Session revocation is temporarily unavailable.",
                        "retry",
                        retryable=True,
                    )
        except urllib.error.HTTPError as exc:
            if exc.code in {401, 404}:
                return
            raise ApiError(
                503,
                "temporarily_unavailable",
                "Session revocation is temporarily unavailable.",
                "retry",
                retryable=True,
            ) from exc
        except urllib.error.URLError as exc:
            raise ApiError(
                503,
                "temporarily_unavailable",
                "Session revocation is temporarily unavailable.",
                "retry",
                retryable=True,
            ) from exc


class IdentityService:
    def __init__(self, repository: IdentityRepository, settings: Settings) -> None:
        self.repository = repository
        self.settings = settings

    def bootstrap(self, request: AuthenticatedRequest) -> SessionBootstrapResponse:
        data = self.repository.bootstrap(
            request.context,
            default_timezone=self.settings.default_timezone,
            default_locale=self.settings.default_locale,
        )
        consent_status = self._consent_status(data["consents"])
        granted = {
            item.policy_id.value
            for item in consent_status
            if item.is_current and item.decision == "granted"
        }
        active = data["account"]["status"] == "active"
        return SessionBootstrapResponse(
            profile_summary=ProfileSummary(
                user_id=data["user_id"],
                display_name=data["account"]["display_name"],
                onboarding_completed=data["account"]["onboarding_completed_at"] is not None,
                active_subject_id=data["account"]["active_subject_id"],
                curriculum_version_id=data["account"]["curriculum_version_id"],
            ),
            account_status=data["account"]["status"],
            consent_status=consent_status,
            subjects=data["subjects"],
            active_mission=data["active_mission"],
            pending_learning_updates=data["pending_learning_updates"],
            pending_privacy_requests=data["pending_privacy_requests"],
            server_time=datetime.now(UTC),
            capability_flags=CapabilityFlags(
                can_add_learning_material=active and _REQUIRED_INGESTION_CONSENTS.issubset(granted),
                can_start_mission=active and _REQUIRED_ACCOUNT_CONSENTS.issubset(granted),
            ),
        )

    def consent(self, request: AuthenticatedRequest) -> ConsentResponse:
        return ConsentResponse(
            policies=self._consent_status(self.repository.consent_records(request.context))
        )

    def profile(self, request: AuthenticatedRequest) -> ProfileResponse:
        return ProfileResponse.model_validate(self.repository.profile(request.context))

    def update_profile(
        self,
        request: AuthenticatedRequest,
        body: ProfileUpdateRequest,
        *,
        idempotency_key: str,
    ) -> ProfileResponse:
        values = body.model_dump(exclude_unset=True, exclude={"version"})
        if "timezone" in values:
            self._validate_timezone(values["timezone"])
        if "locale" in values and not _LOCALE_PATTERN.fullmatch(values["locale"]):
            raise ApiError(
                422,
                "validation_failed",
                "Enter a valid locale.",
                "correct_input",
            )
        return ProfileResponse.model_validate(
            self.repository.update_profile(
                request.context,
                version=body.version,
                idempotency_key=idempotency_key,
                values=values,
            )
        )

    def preferences(self, request: AuthenticatedRequest) -> ProfilePreferencesResponse:
        return ProfilePreferencesResponse.model_validate(
            self.repository.preferences(request.context, default_reminders=1)
        )

    def update_preferences(
        self,
        request: AuthenticatedRequest,
        body: ProfilePreferencesUpdateRequest,
        *,
        idempotency_key: str,
    ) -> ProfilePreferencesResponse:
        values = body.model_dump(mode="json", exclude_unset=True, exclude={"version"})
        if "timezone" in values:
            self._validate_timezone(values["timezone"])
        return ProfilePreferencesResponse.model_validate(
            self.repository.update_preferences(
                request.context,
                version=body.version,
                idempotency_key=idempotency_key,
                values=values,
                default_reminders=1,
            )
        )

    def accept_consent(
        self,
        request: AuthenticatedRequest,
        body: ConsentAcceptanceRequest,
        *,
        idempotency_key: str,
        locale: str | None,
    ) -> ConsentAcceptanceResponse:
        current_version = self.settings.consent_policy_versions.get(body.policy_id.value)
        if current_version is None or body.policy_version != current_version:
            raise ApiError(
                409,
                "version_conflict",
                "The consent policy has changed. Review the current version.",
                "refresh_state",
            )
        if body.policy_id.value not in body.accepted_scopes:
            raise ApiError(
                422,
                "validation_failed",
                "Accept the required policy scope to continue.",
                "correct_input",
            )
        result = self.repository.accept_consent(
            request.context,
            idempotency_key=idempotency_key,
            policy_id=body.policy_id.value,
            policy_version=body.policy_version,
            accepted_scopes=body.accepted_scopes,
            locale=locale,
        )
        return ConsentAcceptanceResponse.model_validate(result)

    def register_device(
        self,
        request: AuthenticatedRequest,
        body: DeviceRegistrationRequest,
        *,
        idempotency_key: str,
    ) -> tuple[DeviceRegistrationResponse, bool]:
        self._validate_timezone(body.timezone)
        protector = self._protector()
        ciphertext, fingerprint = protector.protect(
            body.push_token.get_secret_value(),
            owner=f"{request.context.issuer}\0{request.context.subject}".encode(),
        )
        body_hash = hashlib.sha256(
            json.dumps(
                {
                    "installation_id": str(body.installation_id),
                    "platform": body.platform,
                    "token_fingerprint": fingerprint,
                    "locale": body.locale,
                    "timezone": body.timezone,
                    "app_version": body.app_version,
                },
                sort_keys=True,
                separators=(",", ":"),
            ).encode("utf-8")
        ).hexdigest()
        result, created = self.repository.register_device(
            request.context,
            idempotency_key=idempotency_key,
            body_hash=body_hash,
            installation_id=body.installation_id,
            platform=body.platform,
            ciphertext=ciphertext,
            fingerprint=fingerprint,
            locale=body.locale,
            timezone=body.timezone,
            app_version=body.app_version,
        )
        return DeviceRegistrationResponse.model_validate(result), created

    def delete_device(self, request: AuthenticatedRequest, device_id: UUID) -> None:
        self.repository.delete_device(request.context, device_id)

    def revoke(
        self,
        request: AuthenticatedRequest,
        body: SessionRevokeRequest,
        *,
        idempotency_key: str,
        request_id: UUID,
        correlation_id: UUID,
    ) -> None:
        require_recent_authentication(request, self.settings)
        if self.repository.claim_revocation(
            request.context,
            idempotency_key=idempotency_key,
            scope=body.scope.value,
        ):
            return
        self._provider().revoke(request.access_token.get_secret_value(), body.scope.value)
        self.repository.complete_revocation(
            request.context,
            idempotency_key=idempotency_key,
            scope=body.scope.value,
            request_id=request_id,
            correlation_id=correlation_id,
        )

    def _consent_status(self, records: list[dict[str, object]]) -> list[ConsentStatus]:
        latest = {str(record["consent_type"]): record for record in records}
        return [
            ConsentStatus(
                policy_id=policy_id,
                policy_version=version,
                required=policy_id in _REQUIRED_ACCOUNT_CONSENTS,
                decision=record["decision"] if record else None,
                decided_at=record["decided_at"] if record else None,
                is_current=bool(
                    record
                    and record["policy_version"] == version
                    and record["decision"] == "granted"
                ),
            )
            for policy_id, version in self.settings.consent_policy_versions.items()
            for record in [latest.get(policy_id)]
        ]

    def _provider(self) -> SupabaseAuthClient:
        if self.settings.supabase_url is None or self.settings.supabase_publishable_key is None:
            raise ApiError(
                503,
                "temporarily_unavailable",
                "Session revocation is temporarily unavailable.",
                "retry",
                retryable=True,
            )
        return SupabaseAuthClient(
            self.settings.supabase_url,
            self.settings.supabase_publishable_key.get_secret_value(),
        )

    def _protector(self) -> DeviceTokenProtector:
        if (
            self.settings.device_encryption_key is None
            or self.settings.device_fingerprint_key is None
        ):
            raise ApiError(
                503,
                "temporarily_unavailable",
                "Device registration is temporarily unavailable.",
                "retry",
                retryable=True,
            )
        try:
            encryption_key = base64.b64decode(
                self.settings.device_encryption_key.get_secret_value(), validate=True
            )
            fingerprint_key = base64.b64decode(
                self.settings.device_fingerprint_key.get_secret_value(), validate=True
            )
            return DeviceTokenProtector(encryption_key, fingerprint_key)
        except (ValueError, TypeError) as exc:
            raise ApiError(
                503,
                "temporarily_unavailable",
                "Device registration is temporarily unavailable.",
                "retry",
                retryable=True,
            ) from exc

    @staticmethod
    def _validate_timezone(value: str) -> None:
        try:
            ZoneInfo(value)
        except ZoneInfoNotFoundError as exc:
            raise ApiError(
                422,
                "validation_failed",
                "Enter a valid timezone.",
                "correct_input",
            ) from exc


def get_identity_service(
    settings: Annotated[Settings, Depends(get_settings)],
) -> IdentityService:
    return IdentityService(
        IdentityRepository(database_engine(settings.database_url)),
        settings,
    )
