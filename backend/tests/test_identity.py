from __future__ import annotations

import base64
from datetime import UTC, datetime, timedelta
from types import SimpleNamespace
from uuid import UUID, uuid4

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa
from fastapi.testclient import TestClient
from pydantic import SecretStr, ValidationError

from memora.api.errors import ApiError
from memora.api.security import (
    AuthContext,
    AuthenticatedRequest,
    SupabaseTokenValidator,
    require_recent_authentication,
)
from memora.api.v1.schemas.identity import (
    ConsentAcceptanceRequest,
    DeviceRegistrationRequest,
    ProfilePreferencesUpdateRequest,
    ProfileUpdateRequest,
)
from memora.core.config import Settings
from memora.main import create_app
from memora.modules.identity.service import (
    DeviceTokenProtector,
    IdentityService,
    SupabaseAuthClient,
)

ISSUER = "https://test-project.supabase.co/auth/v1"
SESSION_ID = UUID("10000000-0000-0000-0000-000000000001")
SUBJECT = "20000000-0000-0000-0000-000000000001"
REQUEST_HEADERS = {
    "X-Client-Version": "1.0.0",
    "X-Platform": "android",
}


class StaticJwks:
    def __init__(self, key: object) -> None:
        self.key = key

    def get_signing_key_from_jwt(self, _: str) -> SimpleNamespace:
        return SimpleNamespace(key=self.key)


@pytest.fixture(scope="module")
def signing_key() -> rsa.RSAPrivateKey:
    return rsa.generate_private_key(public_exponent=65537, key_size=2048)


def make_token(
    signing_key: rsa.RSAPrivateKey,
    *,
    expires_at: datetime | None = None,
    issued_at: datetime | None = None,
    audience: str = "authenticated",
    authenticated_at: datetime | None = None,
) -> str:
    now = datetime.now(UTC)
    return jwt.encode(
        {
            "iss": ISSUER,
            "aud": audience,
            "exp": expires_at or now + timedelta(minutes=5),
            "iat": issued_at or now,
            "sub": SUBJECT,
            "role": "authenticated",
            "session_id": str(SESSION_ID),
            "is_anonymous": False,
            "amr": [
                {
                    "method": "oauth",
                    "timestamp": int((authenticated_at or now).timestamp()),
                }
            ],
        },
        signing_key,
        algorithm="RS256",
        headers={"kid": "test-key"},
    )


def validator(signing_key: rsa.RSAPrivateKey) -> SupabaseTokenValidator:
    result = SupabaseTokenValidator(ISSUER, "https://unused.example/jwks.json")
    result.jwks = StaticJwks(signing_key.public_key())  # type: ignore[assignment]
    return result


def test_supabase_token_validation_uses_signature_issuer_audience_and_claims(
    signing_key: rsa.RSAPrivateKey,
) -> None:
    context = validator(signing_key).validate(make_token(signing_key))

    assert context.issuer == ISSUER
    assert context.subject == SUBJECT
    assert context.session_id == SESSION_ID
    assert context.role == "authenticated"
    assert context.authenticated_at is not None


def test_expired_token_fails_with_safe_code(signing_key: rsa.RSAPrivateKey) -> None:
    token = make_token(signing_key, expires_at=datetime.now(UTC) - timedelta(seconds=1))

    with pytest.raises(ApiError) as captured:
        validator(signing_key).validate(token)

    assert captured.value.status_code == 401
    assert captured.value.code == "token_expired"
    assert token not in repr(captured.value)


def test_token_validation_allows_bounded_issuer_clock_skew(
    signing_key: rsa.RSAPrivateKey,
) -> None:
    token = make_token(
        signing_key,
        issued_at=datetime.now(UTC) + timedelta(seconds=5),
    )

    assert validator(signing_key).validate(token).subject == SUBJECT


def test_token_validation_rejects_excessive_issuer_clock_skew(
    signing_key: rsa.RSAPrivateKey,
) -> None:
    token = make_token(
        signing_key,
        issued_at=datetime.now(UTC) + timedelta(minutes=1),
    )

    with pytest.raises(ApiError, match="token_invalid") as captured:
        validator(signing_key).validate(token)

    assert captured.value.status_code == 401
    assert token not in repr(captured.value)


def test_wrong_audience_fails_safely(signing_key: rsa.RSAPrivateKey) -> None:
    with pytest.raises(ApiError, match="token_invalid") as captured:
        validator(signing_key).validate(make_token(signing_key, audience="anon"))

    assert captured.value.status_code == 401


def test_recent_authentication_accepts_ten_minutes_and_rejects_stale() -> None:
    now = datetime.now(UTC)
    settings = Settings(_env_file=None, recent_auth_window_seconds=600)
    fresh = authenticated_request(authenticated_at=now - timedelta(minutes=10))
    stale = authenticated_request(authenticated_at=now - timedelta(minutes=11))

    require_recent_authentication(fresh, settings, now=now)
    with pytest.raises(ApiError, match="recent_authentication_required"):
        require_recent_authentication(stale, settings, now=now)


def test_supabase_revocation_maps_supported_scopes(monkeypatch: pytest.MonkeyPatch) -> None:
    urls: list[str] = []

    class Response:
        status = 204

        def __enter__(self) -> Response:
            return self

        def __exit__(self, *_: object) -> None:
            return None

    def urlopen(request: object, *, timeout: int) -> Response:
        assert timeout == 10
        urls.append(request.full_url)  # type: ignore[attr-defined]
        assert request.get_header("Authorization") == "Bearer access-token"  # type: ignore[attr-defined]
        assert request.get_header("Apikey") == "publishable-key"  # type: ignore[attr-defined]
        return Response()

    monkeypatch.setattr("memora.modules.identity.service.urllib.request.urlopen", urlopen)
    client = SupabaseAuthClient("https://test-project.supabase.co", "publishable-key")

    for scope in ("current", "other_sessions", "all"):
        client.revoke("access-token", scope)

    assert [url.rsplit("=", 1)[-1] for url in urls] == ["local", "others", "global"]


def test_authenticated_request_repr_redacts_access_token() -> None:
    request = authenticated_request(authenticated_at=datetime.now(UTC))

    assert "secret-access-token" not in repr(request)


def test_missing_token_returns_shared_error_envelope() -> None:
    response = TestClient(create_app()).get("/v1/session/bootstrap", headers=REQUEST_HEADERS)

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "token_missing"
    assert response.headers["cache-control"] == "private, no-store"
    UUID(response.headers["x-correlation-id"])
    UUID(response.headers["x-request-id"])


class BootstrapRepository:
    def bootstrap(self, auth: AuthContext, **_: object) -> dict[str, object]:
        assert auth.subject == SUBJECT
        subject_id = UUID("30000000-0000-0000-0000-000000000001")
        curriculum_id = UUID("40000000-0000-0000-0000-000000000001")
        return {
            "user_id": UUID("50000000-0000-0000-0000-000000000001"),
            "account": {
                "status": "active",
                "display_name": "Student",
                "onboarding_completed_at": None,
                "active_subject_id": subject_id,
                "curriculum_version_id": curriculum_id,
            },
            "consents": [
                {
                    "consent_type": "terms",
                    "policy_version": "terms-v1",
                    "decision": "granted",
                    "decided_at": datetime.now(UTC),
                }
            ],
            "subjects": [
                {
                    "id": subject_id,
                    "code": "physics",
                    "name": "Physics",
                    "curriculum_version_id": curriculum_id,
                    "curriculum_edition_code": "GCE-AL-PHYSICS-2017",
                }
            ],
            "active_mission": None,
            "pending_learning_updates": [],
            "pending_privacy_requests": [],
        }


def test_bootstrap_returns_contracted_bounded_summary() -> None:
    settings = Settings(
        _env_file=None,
        consent_terms_version="terms-v1",
        consent_privacy_version="privacy-v1",
    )
    service = IdentityService(BootstrapRepository(), settings)  # type: ignore[arg-type]

    result = service.bootstrap(authenticated_request(authenticated_at=datetime.now(UTC)))

    assert result.account_status == "active"
    assert result.profile_summary.display_name == "Student"
    assert [subject.code for subject in result.subjects] == ["physics"]
    assert [policy.policy_id for policy in result.consent_status] == ["terms", "privacy"]
    assert result.pending_learning_updates == []
    assert result.capability_flags.can_start_mission is False
    assert "question" not in result.model_dump_json()
    assert "learning_content" not in result.model_dump_json()


def test_device_token_encryption_is_random_and_fingerprint_is_stable() -> None:
    protector = DeviceTokenProtector(b"a" * 32, b"b" * 32)
    owner = b"synthetic-owner"

    first_ciphertext, first_fingerprint = protector.protect("push-token-secret", owner=owner)
    second_ciphertext, second_fingerprint = protector.protect("push-token-secret", owner=owner)

    assert first_ciphertext != second_ciphertext
    assert first_fingerprint == second_fingerprint
    assert b"push-token-secret" not in first_ciphertext


class ConsentRepository:
    def __init__(self) -> None:
        self.accepted: dict[str, object] | None = None

    def consent_records(self, _: AuthContext) -> list[dict[str, object]]:
        return []

    def accept_consent(self, _: AuthContext, **values: object) -> dict[str, object]:
        self.accepted = values
        return {
            "id": uuid4(),
            "policy_id": values["policy_id"],
            "policy_version": values["policy_version"],
            "decision": "granted",
            "accepted_scopes": values["accepted_scopes"],
            "decided_at": datetime.now(UTC),
        }


def test_consent_acceptance_requires_current_server_policy_version() -> None:
    repository = ConsentRepository()
    settings = Settings(_env_file=None, consent_privacy_version="privacy-v2")
    service = IdentityService(repository, settings)  # type: ignore[arg-type]
    request = authenticated_request(authenticated_at=datetime.now(UTC))

    with pytest.raises(ApiError, match="version_conflict"):
        service.accept_consent(
            request,
            ConsentAcceptanceRequest(
                policy_id="privacy",
                policy_version="privacy-v1",
                accepted_scopes=["privacy"],
            ),
            idempotency_key="00000000-0000-0000-0000-000000000001",
            locale="en-LK",
        )

    accepted = service.accept_consent(
        request,
        ConsentAcceptanceRequest(
            policy_id="privacy",
            policy_version="privacy-v2",
            accepted_scopes=["privacy"],
        ),
        idempotency_key="00000000-0000-0000-0000-000000000002",
        locale="en-LK",
    )
    assert accepted.policy_version == "privacy-v2"
    assert repository.accepted is not None


def test_device_keys_are_exactly_32_bytes() -> None:
    invalid = base64.b64encode(b"short").decode()
    settings = Settings(
        _env_file=None,
        device_encryption_key=invalid,
        device_fingerprint_key=invalid,
    )
    service = IdentityService(ConsentRepository(), settings)  # type: ignore[arg-type]

    with pytest.raises(ApiError, match="temporarily_unavailable"):
        service._protector()


class ProfileRepository:
    def __init__(self) -> None:
        self.profile_values: dict[str, object] | None = None
        self.preference_values: dict[str, object] | None = None

    def profile(self, _: AuthContext) -> dict[str, object]:
        return self._profile()

    def update_profile(self, _: AuthContext, **values: object) -> dict[str, object]:
        self.profile_values = values
        return {**self._profile(), "display_name": values["values"]["display_name"], "version": 2}  # type: ignore[index]

    def preferences(self, _auth: AuthContext, **_values: object) -> dict[str, object]:
        return self._preferences()

    def update_preferences(self, _: AuthContext, **values: object) -> dict[str, object]:
        self.preference_values = values
        return {**self._preferences(), **values["values"], "version": 2}  # type: ignore[arg-type]

    @staticmethod
    def _profile() -> dict[str, object]:
        return {
            "user_id": uuid4(),
            "display_name": "Student",
            "locale": "en-LK",
            "timezone": "Asia/Colombo",
            "active_subject_id": None,
            "curriculum_version_id": None,
            "version": 1,
        }

    @staticmethod
    def _preferences() -> dict[str, object]:
        return {
            "notifications_enabled": False,
            "mission_enabled": True,
            "reward_enabled": True,
            "streak_enabled": True,
            "quiet_start_local": None,
            "quiet_end_local": None,
            "preferred_window_start_local": None,
            "preferred_window_end_local": None,
            "timezone": "Asia/Colombo",
            "lock_screen_detail": "minimal",
            "max_daily_reminders": 1,
            "accessibility": {"schema_version": "1"},
            "version": 1,
        }


def test_profile_update_normalizes_name_and_validates_timezone() -> None:
    repository = ProfileRepository()
    service = IdentityService(repository, Settings(_env_file=None))  # type: ignore[arg-type]
    request = authenticated_request(authenticated_at=datetime.now(UTC))

    result = service.update_profile(
        request,
        ProfileUpdateRequest(version=1, display_name="  Ada   Student  "),
        idempotency_key="profile-update-key",
    )

    assert result.display_name == "Ada Student"
    assert repository.profile_values is not None
    with pytest.raises(ApiError, match="validation_failed"):
        service.update_profile(
            request,
            ProfileUpdateRequest(version=1, timezone="Not/A_Zone"),
            idempotency_key="profile-timezone-key",
        )


def test_preference_models_reject_partial_pairs_unknown_keys_and_cap() -> None:
    invalid_values = (
        {"version": 1, "quiet_start_local": "22:00:00"},
        {"version": 1, "preferred_window_end_local": "18:00:00"},
        {"version": 1, "max_daily_reminders": 4},
        {"version": 1, "unknown_setting": True},
        {"version": 1, "accessibility": {"schema_version": "1", "unknown": True}},
    )
    for values in invalid_values:
        with pytest.raises(ValidationError):
            ProfilePreferencesUpdateRequest.model_validate(values)


def test_device_registration_rejects_invalid_locale_before_protecting_token() -> None:
    service = IdentityService(ProfileRepository(), Settings(_env_file=None))
    with pytest.raises(ApiError, match="validation_failed"):
        service.register_device(
            authenticated_request(authenticated_at=datetime.now(UTC)),
            DeviceRegistrationRequest(
                installation_id=uuid4(),
                platform="android",
                push_token="synthetic-device-token",
                locale="!!!!!!!!",
                timezone="Asia/Colombo",
                app_version="1.0.0",
            ),
            idempotency_key="invalid-device-locale",
        )


def test_notification_denial_and_accessibility_settings_are_supported() -> None:
    repository = ProfileRepository()
    service = IdentityService(repository, Settings(_env_file=None))  # type: ignore[arg-type]

    result = service.update_preferences(
        authenticated_request(authenticated_at=datetime.now(UTC)),
        ProfilePreferencesUpdateRequest(
            version=1,
            notifications_enabled=False,
            mission_enabled=False,
            accessibility={"reduced_motion": True, "timer_visible": True},
        ),
        idempotency_key="preference-update-key",
    )

    assert result.notifications_enabled is False
    assert result.mission_enabled is False
    assert result.accessibility.reduced_motion is True
    assert result.accessibility.timer_visible is True


def authenticated_request(*, authenticated_at: datetime | None) -> AuthenticatedRequest:
    return AuthenticatedRequest(
        context=AuthContext(
            issuer=ISSUER,
            subject=SUBJECT,
            session_id=SESSION_ID,
            role="authenticated",
            authenticated_at=authenticated_at,
            expires_at=datetime.now(UTC) + timedelta(minutes=5),
        ),
        access_token=SecretStr("secret-access-token"),
    )
