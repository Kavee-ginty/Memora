from dataclasses import dataclass, field
from datetime import UTC, datetime
from functools import lru_cache
from typing import Annotated, Any
from uuid import UUID

import jwt
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import PyJWKClient
from pydantic import SecretStr

from memora.api.errors import ApiError
from memora.core.config import Settings, get_settings

# OpenAPI credential and security-schema primitive.
# auto_error=False ensures FastAPI does not intercept unauthenticated requests with
# its default 403. T06 must provide the enforcing request-context dependency that
# validates OIDC access tokens and emits safe, shared 401 ErrorEnvelope responses.
bearer_auth = HTTPBearer(
    scheme_name="bearerAuth",
    description="Short-lived OIDC-issued access token.",
    auto_error=False,
)

_INTERACTIVE_AUTH_METHODS = frozenset({"oauth", "password", "otp", "totp", "magiclink", "sso/saml"})


@dataclass(frozen=True, slots=True)
class AuthContext:
    issuer: str
    subject: str
    session_id: UUID
    role: str
    authenticated_at: datetime | None
    expires_at: datetime


@dataclass(frozen=True, slots=True)
class AuthenticatedRequest:
    context: AuthContext
    access_token: SecretStr = field(repr=False)


class SupabaseTokenValidator:
    def __init__(self, issuer: str, jwks_url: str) -> None:
        self.issuer = issuer
        self.jwks = PyJWKClient(jwks_url, cache_keys=True, lifespan=600)

    def validate(self, token: str) -> AuthContext:
        try:
            signing_key = self.jwks.get_signing_key_from_jwt(token)
            claims: dict[str, Any] = jwt.decode(
                token,
                signing_key.key,
                algorithms=["RS256", "ES256", "EdDSA"],
                audience="authenticated",
                issuer=self.issuer,
                options={"require": ["iss", "aud", "exp", "iat", "sub", "role", "session_id"]},
            )
        except jwt.ExpiredSignatureError as exc:
            raise ApiError(
                401,
                "token_expired",
                "Your session has expired. Sign in again.",
                "reauthenticate",
            ) from exc
        except jwt.PyJWTError as exc:
            raise ApiError(
                401,
                "token_invalid",
                "Your session could not be verified. Sign in again.",
                "reauthenticate",
            ) from exc

        if claims.get("role") != "authenticated" or claims.get("is_anonymous") is True:
            raise ApiError(
                401,
                "token_invalid",
                "Your session could not be verified. Sign in again.",
                "reauthenticate",
            )

        try:
            session_id = UUID(str(claims["session_id"]))
            expires_at = datetime.fromtimestamp(int(claims["exp"]), UTC)
        except (TypeError, ValueError) as exc:
            raise ApiError(
                401,
                "token_invalid",
                "Your session could not be verified. Sign in again.",
                "reauthenticate",
            ) from exc

        authenticated_at = _interactive_auth_time(claims.get("amr"))
        return AuthContext(
            issuer=self.issuer,
            subject=str(claims["sub"]),
            session_id=session_id,
            role="authenticated",
            authenticated_at=authenticated_at,
            expires_at=expires_at,
        )


def _interactive_auth_time(value: Any) -> datetime | None:
    if not isinstance(value, list):
        return None
    timestamps = [
        entry.get("timestamp")
        for entry in value
        if isinstance(entry, dict)
        and entry.get("method") in _INTERACTIVE_AUTH_METHODS
        and isinstance(entry.get("timestamp"), int)
    ]
    return datetime.fromtimestamp(max(timestamps), UTC) if timestamps else None


@lru_cache(maxsize=4)
def _validator(issuer: str, jwks_url: str) -> SupabaseTokenValidator:
    return SupabaseTokenValidator(issuer, jwks_url)


def get_authenticated_request(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_auth)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> AuthenticatedRequest:
    if credentials is None:
        raise ApiError(
            401,
            "token_missing",
            "Sign in to continue.",
            "reauthenticate",
        )
    if credentials.scheme.lower() != "bearer":
        raise ApiError(
            401,
            "token_invalid",
            "Your session could not be verified. Sign in again.",
            "reauthenticate",
        )
    if settings.oidc_issuer is None or settings.oidc_jwks_url is None:
        raise ApiError(
            503,
            "temporarily_unavailable",
            "Sign-in verification is temporarily unavailable.",
            "retry",
            retryable=True,
            retry_after_seconds=30,
        )
    context = _validator(settings.oidc_issuer, settings.oidc_jwks_url).validate(
        credentials.credentials
    )
    return AuthenticatedRequest(context=context, access_token=SecretStr(credentials.credentials))


def require_recent_authentication(
    request: AuthenticatedRequest,
    settings: Settings,
    *,
    now: datetime | None = None,
) -> None:
    authenticated_at = request.context.authenticated_at
    current = now or datetime.now(UTC)
    if (
        authenticated_at is None
        or authenticated_at > current
        or (current - authenticated_at).total_seconds() > settings.recent_auth_window_seconds
    ):
        raise ApiError(
            403,
            "recent_authentication_required",
            "Sign in again to continue.",
            "reauthenticate",
        )
