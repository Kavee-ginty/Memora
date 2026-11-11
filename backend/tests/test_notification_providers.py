"""Provider adapter contract tests (T19 Commit 2).

Every provider satisfies the same one-method protocol with bounded results.
The FCM adapter is exercised against a fake transport: token exchange and
caching, retryable vs permanent failure classification, 401 refresh-and-retry,
transport timeouts, and constructor validation that never leaks credential
material. The logging provider must never emit parameters or push tokens.
"""

from __future__ import annotations

import json
import logging
from datetime import UTC, datetime
from types import SimpleNamespace

import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

from memora.modules.notifications.constants import (
    CATEGORY_DUE_MEMORIES,
    REMINDER_INTENT_TTL,
)
from memora.modules.notifications.payload import build_payload
from memora.modules.notifications.providers import (
    FcmNotificationProvider,
    FcmTransportError,
    FcmTransportResponse,
    LoggingNotificationProvider,
    build_provider,
)

NOW = datetime.now(UTC)


def _generated_rsa_key_pem() -> str:
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    return key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    ).decode()


def payload(**overrides):  # noqa: ANN001, ANN202 - test helper with defaults
    defaults = dict(
        category=CATEGORY_DUE_MEMORIES,
        resource_id="018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80",
        expires_at=NOW + REMINDER_INTENT_TTL,
        notification_id="a1b2c3d4e5f60718293a4b5c6d7e8f90",
        detail="subject",
        params={"subject_name": "Physics"},
    )
    defaults.update(overrides)
    return build_payload(**defaults)


SERVICE_ACCOUNT_JSON = json.dumps(
    {
        "client_email": "push@test-project.iam.gserviceaccount.com",
        "private_key": _generated_rsa_key_pem(),
        "project_id": "test-project",
    }
)

PUSH_TOKEN = "fcm-token-018f3c2a"


class FakeTransport:
    def __init__(self, responses):  # noqa: ANN001
        self.responses = list(responses)
        self.calls: list[dict] = []

    def post(self, url, *, headers, body, timeout):  # noqa: ANN001, ANN202
        self.calls.append({"url": url, "headers": dict(headers), "body": body, "timeout": timeout})
        item = self.responses.pop(0)
        if isinstance(item, Exception):
            raise item
        status, payload = item
        return FcmTransportResponse(status=status, body=json.dumps(payload).encode())

    @property
    def token_calls(self) -> int:
        return sum(1 for call in self.calls if "oauth2.googleapis.com" in call["url"])

    @property
    def send_calls(self) -> int:
        return sum(1 for call in self.calls if "fcm.googleapis.com" in call["url"])


def token_ok() -> tuple[int, dict]:
    return 200, {"access_token": "ya29.test-token", "expires_in": 3600}


def fcm_provider(responses) -> tuple[FcmNotificationProvider, FakeTransport]:
    transport = FakeTransport(responses)
    provider = FcmNotificationProvider(
        service_account_json=SERVICE_ACCOUNT_JSON, transport=transport
    )
    return provider, transport


def test_logging_provider_reports_sent_without_leaking_content(caplog) -> None:
    with caplog.at_level(logging.INFO, logger="memora.modules.notifications.providers"):
        result = LoggingNotificationProvider().send(payload(), PUSH_TOKEN)
    assert result.sent is True
    assert result.reason_code == "logged"
    joined = caplog.text
    assert "category=due_memories" in joined
    assert "Physics" not in joined  # payload parameter never logged
    assert PUSH_TOKEN not in joined  # push token never logged


def test_fcm_success_returns_provider_message_id() -> None:
    provider, transport = fcm_provider(
        [token_ok(), (200, {"name": "projects/test-project/messages/1234"})]
    )
    result = provider.send(payload(), PUSH_TOKEN)
    assert result.sent is True
    assert result.provider_message_id == "projects/test-project/messages/1234"
    assert transport.token_calls == 1

    send_call = transport.calls[1]
    assert send_call["headers"]["Authorization"] == "Bearer ya29.test-token"
    body = json.loads(send_call["body"])
    assert body["message"]["token"] == PUSH_TOKEN
    assert body["message"]["data"]["category"] == "due_memories"
    assert body["message"]["data"]["param.subject_name"] == "Physics"


def test_fcm_caches_access_token_across_sends() -> None:
    provider, transport = fcm_provider(
        [
            token_ok(),
            (200, {"name": "projects/test-project/messages/1"}),
            (200, {"name": "projects/test-project/messages/2"}),
        ]
    )
    provider.send(payload(), PUSH_TOKEN)
    provider.send(payload(), PUSH_TOKEN)
    assert transport.token_calls == 1
    assert transport.send_calls == 2


def test_fcm_refreshes_token_once_on_401_and_retries() -> None:
    provider, transport = fcm_provider(
        [
            token_ok(),
            (401, {"error": {"status": "UNAUTHENTICATED"}}),
            token_ok(),
            (200, {"name": "projects/test-project/messages/after-refresh"}),
        ]
    )
    result = provider.send(payload(), PUSH_TOKEN)
    assert result.sent is True
    assert transport.token_calls == 2
    assert transport.send_calls == 2
    assert transport.calls[3]["headers"]["Authorization"] == "Bearer ya29.test-token"


def test_fcm_rate_limit_is_retryable() -> None:
    provider, _ = fcm_provider([token_ok(), (429, {"error": {"status": "RESOURCE_EXHAUSTED"}})])
    result = provider.send(payload(), PUSH_TOKEN)
    assert result.outcome == "retryable_failure"
    assert result.reason_code == "provider_rate_limited"


def test_fcm_server_error_is_retryable() -> None:
    provider, _ = fcm_provider([token_ok(), (503, {"error": {"status": "UNAVAILABLE"}})])
    result = provider.send(payload(), PUSH_TOKEN)
    assert result.outcome == "retryable_failure"
    assert result.reason_code == "provider_server_error"


def test_fcm_bad_request_is_permanent() -> None:
    provider, _ = fcm_provider([token_ok(), (400, {"error": {"status": "INVALID_ARGUMENT"}})])
    result = provider.send(payload(), PUSH_TOKEN)
    assert result.outcome == "permanent_failure"
    assert result.reason_code == "invalid_token"


def test_fcm_unregistered_token_is_permanent() -> None:
    provider, _ = fcm_provider([token_ok(), (404, {"error": {"status": "NOT_FOUND"}})])
    result = provider.send(payload(), PUSH_TOKEN)
    assert result.outcome == "permanent_failure"
    assert result.reason_code == "invalid_token"


def test_fcm_transport_timeout_is_retryable() -> None:
    provider, _ = fcm_provider([token_ok(), FcmTransportError("ReadTimeout")])
    result = provider.send(payload(), PUSH_TOKEN)
    assert result.outcome == "retryable_failure"
    assert result.reason_code == "provider_timeout"


def test_fcm_unreadable_token_exchange_is_retryable() -> None:
    transport = FakeTransport([(200, {"unexpected": True})])
    provider = FcmNotificationProvider(
        service_account_json=SERVICE_ACCOUNT_JSON, transport=transport
    )
    result = provider.send(payload(), PUSH_TOKEN)
    assert result.outcome == "retryable_failure"
    assert result.reason_code == "provider_timeout"


def test_fcm_constructor_rejects_unusable_credentials_without_leaking() -> None:
    with pytest.raises(ValueError, match="service-account key JSON"):
        FcmNotificationProvider(service_account_json="not json")
    with pytest.raises(ValueError, match="project_id"):
        FcmNotificationProvider(
            service_account_json=json.dumps({"client_email": "a@b.c", "private_key": "k"})
        )
    with pytest.raises(ValueError, match="valid PEM RSA key"):
        FcmNotificationProvider(
            service_account_json=json.dumps(
                {"client_email": "a@b.c", "private_key": "not-a-real-key", "project_id": "p"}
            )
        )


def test_build_provider_allowlist() -> None:
    logging_provider = build_provider(SimpleNamespace(notification_provider="logging"))
    assert isinstance(logging_provider, LoggingNotificationProvider)

    with pytest.raises(ValueError, match="MEMORA_FCM_PROJECT_ID"):
        build_provider(
            SimpleNamespace(
                notification_provider="fcm", fcm_project_id=None, fcm_service_account_json=None
            )
        )

    fcm = build_provider(
        SimpleNamespace(
            notification_provider="fcm",
            fcm_project_id="test-project",
            fcm_service_account_json=SimpleNamespace(get_secret_value=lambda: SERVICE_ACCOUNT_JSON),
        )
    )
    assert isinstance(fcm, FcmNotificationProvider)
