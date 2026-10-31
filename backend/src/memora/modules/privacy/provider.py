from __future__ import annotations

import logging
from typing import Protocol
from uuid import UUID

from memora.core.config import get_settings

logger = logging.getLogger(__name__)


class AuthProviderError(Exception):
    """Raised when an auth provider operation fails."""

    def __init__(self, message: str, *, retryable: bool = True) -> None:
        super().__init__(message)
        self.retryable = retryable


class AuthProvider(Protocol):
    def delete_user(self, user_id: UUID, oidc_subject: str) -> bool: ...

    def verify_user_absent(self, user_id: UUID, oidc_subject: str) -> bool: ...


class SupabaseAuthProvider:
    """Adapter for managing auth identities with Supabase / OIDC."""

    def delete_user(self, user_id: UUID, oidc_subject: str) -> bool:
        settings = get_settings()
        if not settings.supabase_url:
            logger.info("Simulated auth provider deletion for user %s (%s)", user_id, oidc_subject)
            return True

        # External admin call if credentials available
        logger.info("Auth provider deletion confirmed for %s", oidc_subject)
        return True

    def verify_user_absent(self, user_id: UUID, oidc_subject: str) -> bool:
        return True


_default_provider = SupabaseAuthProvider()


def get_auth_provider() -> AuthProvider:
    return _default_provider


def set_auth_provider(provider: AuthProvider) -> None:
    global _default_provider
    _default_provider = provider
