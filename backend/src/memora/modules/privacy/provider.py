from __future__ import annotations

import logging
import urllib.error
import urllib.request
from typing import Protocol
from uuid import UUID

from memora.core.config import Settings, get_settings

logger = logging.getLogger(__name__)


class AuthProviderError(Exception):
    """Raised when an auth provider operation fails."""

    def __init__(self, message: str, *, retryable: bool = True) -> None:
        super().__init__(message)
        self.retryable = retryable


class AuthProvider(Protocol):
    def delete_user(self, user_id: UUID, oidc_subject: str) -> bool: ...

    def verify_user_absent(self, user_id: UUID, oidc_subject: str) -> bool: ...


class MemoryAuthProvider:
    """In-memory auth provider for unit tests and local verification."""

    def __init__(self, initial_users: set[str] | None = None) -> None:
        self._users: set[str] = set(initial_users) if initial_users else set()

    def register_user(self, oidc_subject: str) -> None:
        self._users.add(oidc_subject)

    def delete_user(self, user_id: UUID, oidc_subject: str) -> bool:
        self._users.discard(oidc_subject)
        return True

    def verify_user_absent(self, user_id: UUID, oidc_subject: str) -> bool:
        return oidc_subject not in self._users


class SupabaseAuthProvider:
    """Adapter for managing auth identities with Supabase / OIDC Admin API."""

    def __init__(self, settings: Settings | None = None) -> None:
        self._settings = settings or get_settings()

    def _get_admin_headers(self) -> dict[str, str] | None:
        if not self._settings.supabase_url:
            return None
        service_key = (
            self._settings.supabase_service_role_key.get_secret_value()
            if self._settings.supabase_service_role_key
            else None
        )
        if not service_key:
            return None
        return {
            "apikey": service_key,
            "Authorization": f"Bearer {service_key}",
            "Content-Type": "application/json",
        }

    def delete_user(self, user_id: UUID, oidc_subject: str) -> bool:
        headers = self._get_admin_headers()
        if not headers or not self._settings.supabase_url:
            logger.info("Simulated auth provider deletion for user %s (%s)", user_id, oidc_subject)
            return True

        url = f"{self._settings.supabase_url}/auth/v1/admin/users/{oidc_subject}"
        request = urllib.request.Request(url, method="DELETE", headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=10) as response:
                if response.status in {200, 204}:
                    return True
                raise AuthProviderError(f"Unexpected deletion response status: {response.status}")
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                return True
            raise AuthProviderError(
                f"Auth provider deletion failed with HTTP {exc.code}", retryable=True
            ) from exc
        except (urllib.error.URLError, TimeoutError) as exc:
            raise AuthProviderError(
                "Auth provider temporarily unavailable", retryable=True
            ) from exc

    def verify_user_absent(self, user_id: UUID, oidc_subject: str) -> bool:
        headers = self._get_admin_headers()
        if not headers or not self._settings.supabase_url:
            return True

        url = f"{self._settings.supabase_url}/auth/v1/admin/users/{oidc_subject}"
        request = urllib.request.Request(url, method="GET", headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=10) as response:
                return response.status != 200
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                return True
            raise AuthProviderError(
                f"Auth provider query failed with HTTP {exc.code}", retryable=True
            ) from exc
        except (urllib.error.URLError, TimeoutError) as exc:
            raise AuthProviderError(
                "Auth provider temporarily unavailable", retryable=True
            ) from exc


_default_provider: AuthProvider = SupabaseAuthProvider()


def get_auth_provider() -> AuthProvider:
    return _default_provider


def set_auth_provider(provider: AuthProvider) -> None:
    global _default_provider
    _default_provider = provider
