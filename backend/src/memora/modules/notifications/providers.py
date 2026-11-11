"""Push provider adapters behind one narrow protocol (TRD §3.3, §5.1).

Providers are selected by server configuration allowlist
(``MEMORA_NOTIFICATION_PROVIDER``). The default ``logging`` provider records
the dispatch without external calls so local, CI and degraded environments
keep operating safely (TRD §16.2). The ``fcm`` adapter speaks the FCM HTTP v1
API: it signs the service-account assertion with the already-present
``PyJWT[crypto]`` dependency and exchanges it for an access token. Credentials
arrive via environment only and are never logged; provider errors are reduced
to bounded, safe reason codes before they leave this module.
"""

from __future__ import annotations

import json
import logging
import threading
import time
from dataclasses import dataclass
from typing import Final, Literal, Protocol

import jwt

from memora.modules.notifications.payload import (
    NotificationPayload,
    payload_to_data,
)

logger = logging.getLogger(__name__)

PROVIDER_OUTCOME_SENT: Final = "sent"
PROVIDER_OUTCOME_RETRYABLE: Final = "retryable_failure"
PROVIDER_OUTCOME_PERMANENT: Final = "permanent_failure"

# Safe reason codes only — no provider response bodies or credentials.
REASON_SENT: Final = "sent"
REASON_LOGGED: Final = "logged"
REASON_TIMEOUT: Final = "provider_timeout"
REASON_RATE_LIMITED: Final = "provider_rate_limited"
REASON_SERVER_ERROR: Final = "provider_server_error"
REASON_INVALID_TOKEN: Final = "invalid_token"
REASON_REJECTED: Final = "provider_rejected"

_OAUTH_TOKEN_URL: Final = "https://oauth2.googleapis.com/token"
_FCM_SEND_URL_TEMPLATE: Final = "https://fcm.googleapis.com/v1/projects/{project}/messages:send"
_FCM_SCOPE: Final = "https://www.googleapis.com/auth/firebase.messaging"

_CONNECT_TIMEOUT_SECONDS: Final = 5.0
_READ_TIMEOUT_SECONDS: Final = 10.0
_TOKEN_EXPIRY_MARGIN_SECONDS: Final = 60.0


@dataclass(frozen=True)
class ProviderResult:
    """Bounded provider outcome; never carries response bodies."""

    outcome: Literal["sent", "retryable_failure", "permanent_failure"]
    reason_code: str
    provider_message_id: str | None = None

    @property
    def sent(self) -> bool:
        return self.outcome == PROVIDER_OUTCOME_SENT


class NotificationProvider(Protocol):
    """One method, bounded result: every provider must satisfy this."""

    def send(
        self, payload: NotificationPayload, push_token: str
    ) -> ProviderResult: ...  # pragma: no cover - protocol


class LoggingNotificationProvider:
    """Default provider: records the dispatch without external calls.

    Only category, resource type/id and the per-send notification id are
    logged — never payload parameters, never push tokens (API §19).
    """

    def send(self, payload: NotificationPayload, push_token: str) -> ProviderResult:
        logger.info(
            "notification.dispatch provider=logging category=%s resource_type=%s "
            "resource_id=%s notification_id=%s",
            payload.category,
            payload.resource_type,
            payload.resource_id,
            payload.notification_id,
        )
        return ProviderResult(outcome=PROVIDER_OUTCOME_SENT, reason_code=REASON_LOGGED)


class FcmTransportError(Exception):
    """Transport-level failure raised by :class:`FcmTransport` implementors."""


@dataclass(frozen=True)
class FcmTransportResponse:
    status: int
    body: bytes


class FcmTransport(Protocol):
    """Narrow HTTP surface so tests can inject a fake transport."""

    def post(
        self,
        url: str,
        *,
        headers: dict[str, str],
        body: bytes,
        timeout: tuple[float, float],
    ) -> FcmTransportResponse: ...  # pragma: no cover - protocol


class UrllibFcmTransport:
    """Standard-library transport; no extra runtime dependency."""

    def post(
        self,
        url: str,
        *,
        headers: dict[str, str],
        body: bytes,
        timeout: tuple[float, float],
    ) -> FcmTransportResponse:
        import urllib.error
        import urllib.request

        request = urllib.request.Request(url, data=body, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(request, timeout=timeout[0] + timeout[1]) as response:
                return FcmTransportResponse(status=response.status, body=response.read())
        except urllib.error.HTTPError as exc:
            return FcmTransportResponse(status=exc.code, body=exc.read())
        except (urllib.error.URLError, TimeoutError, OSError) as exc:
            raise FcmTransportError(str(exc.__class__.__name__)) from exc


class FcmNotificationProvider:
    """FCM HTTP v1 adapter with a cached service-account OAuth token.

    ``service_account_json`` is the raw key JSON from the environment. It is
    parsed once; the material itself is never logged and never included in
    error messages.
    """

    def __init__(
        self,
        *,
        service_account_json: str,
        transport: FcmTransport | None = None,
    ) -> None:
        try:
            parsed = json.loads(service_account_json)
            self._client_email = parsed["client_email"]
            self._private_key = parsed["private_key"]
            project_id = parsed.get("project_id")
        except (ValueError, KeyError, TypeError) as exc:
            raise ValueError(
                "MEMORA_FCM_SERVICE_ACCOUNT_JSON must be a service-account key "
                "JSON with client_email, private_key and project_id"
            ) from exc
        if not project_id or not isinstance(project_id, str):
            raise ValueError("service account JSON is missing project_id")

        # Fail fast on an unusable signing key so configuration errors surface
        # at startup instead of mid-flight as unclassified exceptions.
        try:
            jwt.encode(
                {"iss": self._client_email, "aud": "validation", "exp": 1},
                self._private_key,
                algorithm="RS256",
            )
        except jwt.PyJWTError as exc:
            raise ValueError("service account private_key is not a valid PEM RSA key") from exc

        self._project_id = project_id
        self._transport = transport if transport is not None else UrllibFcmTransport()
        self._token_lock = threading.Lock()
        self._cached_token: str | None = None
        self._token_fetched_at: float = 0.0
        self._token_lifetime: float = 0.0

    def _fetch_access_token(self) -> str:
        now = int(time.time())
        assertion = jwt.encode(
            {
                "iss": self._client_email,
                "scope": _FCM_SCOPE,
                "aud": _OAUTH_TOKEN_URL,
                "iat": now,
                "exp": now + 3600,
            },
            self._private_key,
            algorithm="RS256",
        )
        form = (
            "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer"
            f"&assertion={assertion}"
        ).encode("ascii")
        response = self._transport.post(
            _OAUTH_TOKEN_URL,
            headers={
                "Content-Type": "application/x-www-form-urlencoded",
                "Content-Length": str(len(form)),
            },
            body=form,
            timeout=(_CONNECT_TIMEOUT_SECONDS, _READ_TIMEOUT_SECONDS),
        )
        if response.status != 200:
            raise FcmTransportError(f"token exchange failed with status {response.status}")
        try:
            payload = json.loads(response.body)
            token = payload["access_token"]
            lifetime = float(payload.get("expires_in", 3600))
        except (ValueError, KeyError, TypeError) as exc:
            raise FcmTransportError("token exchange returned an unreadable body") from exc
        self._cached_token = token
        self._token_fetched_at = time.monotonic()
        self._token_lifetime = lifetime
        return token

    def _access_token(self) -> str:
        with self._token_lock:
            age = time.monotonic() - self._token_fetched_at
            if (
                self._cached_token is not None
                and age < self._token_lifetime - _TOKEN_EXPIRY_MARGIN_SECONDS
            ):
                return self._cached_token
            return self._fetch_access_token()

    def _drop_cached_token(self) -> None:
        with self._token_lock:
            self._cached_token = None
            self._token_fetched_at = 0.0
            self._token_lifetime = 0.0

    def _send_once(self, payload: NotificationPayload, push_token: str) -> FcmTransportResponse:
        token = self._access_token()
        body = json.dumps(
            {"message": {"token": push_token, "data": payload_to_data(payload)}}
        ).encode("utf-8")
        return self._transport.post(
            _FCM_SEND_URL_TEMPLATE.format(project=self._project_id),
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json; charset=UTF-8",
                "Content-Length": str(len(body)),
            },
            body=body,
            timeout=(_CONNECT_TIMEOUT_SECONDS, _READ_TIMEOUT_SECONDS),
        )

    def send(self, payload: NotificationPayload, push_token: str) -> ProviderResult:
        try:
            response = self._send_once(payload, push_token)
            if response.status == 401:
                # Cached token rejected: refresh once and retry.
                self._drop_cached_token()
                response = self._send_once(payload, push_token)
        except FcmTransportError:
            return ProviderResult(outcome=PROVIDER_OUTCOME_RETRYABLE, reason_code=REASON_TIMEOUT)
        except jwt.PyJWTError:
            # Signing hiccups are transient from this adapter's perspective;
            # the key itself was validated at construction time.
            return ProviderResult(
                outcome=PROVIDER_OUTCOME_RETRYABLE, reason_code=REASON_SERVER_ERROR
            )

        return _classify_fcm_response(response)


def _classify_fcm_response(response: FcmTransportResponse) -> ProviderResult:
    status = response.status
    try:
        body = json.loads(response.body) if response.body else {}
    except ValueError:
        body = {}
    error_status = str(body.get("error", {}).get("status", ""))

    if 200 <= status < 300:
        name = body.get("name")
        return ProviderResult(
            outcome=PROVIDER_OUTCOME_SENT,
            reason_code=REASON_SENT,
            provider_message_id=name if isinstance(name, str) else None,
        )

    if status == 401:
        return ProviderResult(outcome=PROVIDER_OUTCOME_RETRYABLE, reason_code=REASON_SERVER_ERROR)
    if status == 404 or error_status in {"NOT_FOUND", "UNREGISTERED", "INVALID_ARGUMENT"}:
        return ProviderResult(outcome=PROVIDER_OUTCOME_PERMANENT, reason_code=REASON_INVALID_TOKEN)
    if status == 429:
        return ProviderResult(outcome=PROVIDER_OUTCOME_RETRYABLE, reason_code=REASON_RATE_LIMITED)
    if 500 <= status <= 599:
        return ProviderResult(outcome=PROVIDER_OUTCOME_RETRYABLE, reason_code=REASON_SERVER_ERROR)
    return ProviderResult(outcome=PROVIDER_OUTCOME_PERMANENT, reason_code=REASON_REJECTED)


def build_provider(settings) -> NotificationProvider:  # noqa: ANN001 - Settings type cycle
    """Create the configured provider; fail fast on unusable configuration."""

    selection = settings.notification_provider
    if selection == "logging":
        return LoggingNotificationProvider()
    if selection == "fcm":
        secret = settings.fcm_service_account_json
        service_account_json = secret.get_secret_value() if secret else ""
        if not settings.fcm_project_id or not service_account_json.strip():
            raise ValueError(
                "MEMORA_NOTIFICATION_PROVIDER=fcm requires MEMORA_FCM_PROJECT_ID "
                "and MEMORA_FCM_SERVICE_ACCOUNT_JSON"
            )
        return FcmNotificationProvider(service_account_json=service_account_json)
    raise ValueError(f"unknown notification provider: {selection!r}")
