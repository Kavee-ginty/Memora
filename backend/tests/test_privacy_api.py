from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID, uuid4

import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr

from memora.api.errors import ApiError
from memora.api.security import AuthContext, AuthenticatedRequest, get_authenticated_request
from memora.api.v1.schemas.privacy import (
    DeletionProofSummary,
    PrivacyDeletionCancelRequest,
    PrivacyDeletionRequest,
    PrivacyDeletionResponse,
    PrivacyExportRequest,
    PrivacyExportResponse,
)
from memora.core.config import Settings
from memora.main import create_app
from memora.modules.privacy.constants import LEGAL_RETENTION_EXCEPTIONS
from memora.modules.privacy.service import PrivacyService, get_privacy_service

REQUEST_HEADERS = {
    "X-Correlation-ID": "80000000-0000-0000-0000-000000000001",
    "X-Client-Version": "1.0.0",
    "X-Platform": "android",
}
IDEMPOTENCY_HEADERS = {
    **REQUEST_HEADERS,
    "Idempotency-Key": "test-idempotency-key-privacy",
}


def make_authenticated_request(
    *,
    user_id: str = "90000000-0000-0000-0000-000000000001",
    authenticated_at: datetime | None = None,
) -> AuthenticatedRequest:
    now = datetime.now(UTC)
    return AuthenticatedRequest(
        context=AuthContext(
            issuer="https://test-project.supabase.co/auth/v1",
            subject=user_id,
            session_id=uuid4(),
            role="authenticated",
            authenticated_at=authenticated_at if authenticated_at is not None else now,
            expires_at=now + timedelta(minutes=5),
        ),
        access_token=SecretStr("synthetic-token"),
    )


class FakePrivacyService:
    def __init__(self) -> None:
        self.export_id = uuid4()
        self.deletion_id = uuid4()
        self.deletion_status = "requested"
        self.valid_token = "valid-test-token"
        self.export_zip_content = b"PK\x03\x04test-zip-content"

    def get_export_download_archive(self, request_id: UUID, token: str) -> bytes:
        if not token:
            raise ApiError(401, "authentication_required", "Token required.")
        if token != self.valid_token:
            raise ApiError(403, "forbidden", "Invalid token.")
        if request_id != self.export_id:
            raise ApiError(404, "not_found", "Archive not found.")
        return self.export_zip_content

    def create_export(
        self,
        auth: AuthenticatedRequest,
        body: PrivacyExportRequest,
        *,
        idempotency_key: str,
        correlation_id: UUID | None = None,
    ) -> PrivacyExportResponse:
        return PrivacyExportResponse(
            id=self.export_id,
            request_type="export",
            status="requested",
            requested_at=datetime.now(UTC),
        )

    def get_export(
        self,
        auth: AuthenticatedRequest,
        request_id: UUID,
    ) -> PrivacyExportResponse:
        if request_id != self.export_id:
            raise ApiError(404, "not_found", "Export request not found.")
        return PrivacyExportResponse(
            id=self.export_id,
            request_type="export",
            status="completed",
            requested_at=datetime.now(UTC) - timedelta(minutes=2),
            completed_at=datetime.now(UTC) - timedelta(minutes=1),
            download_url="https://storage.memora.internal/v1/privacy/exports/test/download",
            download_expires_at=datetime.now(UTC) + timedelta(hours=24),
        )

    def create_deletion(
        self,
        auth: AuthenticatedRequest,
        body: PrivacyDeletionRequest,
        *,
        idempotency_key: str,
        correlation_id: UUID | None = None,
    ) -> PrivacyDeletionResponse:
        if not body.confirmed:
            raise ApiError(
                400,
                "confirmation_required",
                "Account deletion requires explicit confirmation.",
            )
        return PrivacyDeletionResponse(
            id=self.deletion_id,
            request_type="delete",
            status="requested",
            requested_at=datetime.now(UTC),
            proofs=[],
            retention_exceptions=[],
        )

    def get_deletion(
        self,
        auth: AuthenticatedRequest,
        request_id: UUID,
    ) -> PrivacyDeletionResponse:
        if request_id != self.deletion_id:
            raise ApiError(404, "not_found", "Deletion request not found.")
        proofs = []
        if self.deletion_status == "completed":
            proofs = [
                DeletionProofSummary(
                    id=uuid4(),
                    scope="database_learner_state",
                    provider="postgres",
                    target_fingerprint="abc",
                    result="deleted",
                    verified_at=datetime.now(UTC),
                )
            ]
        exceptions = LEGAL_RETENTION_EXCEPTIONS if self.deletion_status == "completed" else []
        return PrivacyDeletionResponse(
            id=self.deletion_id,
            request_type="delete",
            status=self.deletion_status,  # type: ignore[arg-type]
            requested_at=datetime.now(UTC) - timedelta(minutes=5),
            completed_at=datetime.now(UTC) if self.deletion_status == "completed" else None,
            proofs=proofs,
            retention_exceptions=exceptions,
        )

    def cancel_deletion(
        self,
        auth: AuthenticatedRequest,
        request_id: UUID,
        body: PrivacyDeletionCancelRequest,
        *,
        idempotency_key: str,
        correlation_id: UUID | None = None,
    ) -> PrivacyDeletionResponse:
        if request_id != self.deletion_id:
            raise ApiError(404, "not_found", "Deletion request not found.")
        if self.deletion_status not in {"requested", "verifying"}:
            raise ApiError(
                409,
                "deletion_cancellation_disallowed",
                f"Deletion request in '{self.deletion_status}' status cannot be cancelled.",
            )
        self.deletion_status = "cancelled"
        return PrivacyDeletionResponse(
            id=self.deletion_id,
            request_type="delete",
            status="cancelled",
            requested_at=datetime.now(UTC) - timedelta(minutes=5),
            proofs=[],
            retention_exceptions=[],
        )


def test_routes_require_authentication() -> None:
    app = create_app()
    client = TestClient(app)

    res = client.post("/v1/privacy/exports", json={"format": "json"}, headers=IDEMPOTENCY_HEADERS)
    assert res.status_code == 401

    res = client.get(f"/v1/privacy/exports/{uuid4()}", headers=REQUEST_HEADERS)
    assert res.status_code == 401

    del_body = {"confirmed": True}
    res = client.post("/v1/privacy/deletions", json=del_body, headers=IDEMPOTENCY_HEADERS)
    assert res.status_code == 401

    res = client.get(f"/v1/privacy/deletions/{uuid4()}", headers=REQUEST_HEADERS)
    assert res.status_code == 401

    cancel_url = f"/v1/privacy/deletions/{uuid4()}/cancel"
    res = client.post(cancel_url, json={}, headers=IDEMPOTENCY_HEADERS)
    assert res.status_code == 401


def test_mutations_require_idempotency_header() -> None:
    app = create_app()
    app.dependency_overrides[get_authenticated_request] = make_authenticated_request
    app.dependency_overrides[get_privacy_service] = FakePrivacyService
    client = TestClient(app)

    # Missing Idempotency-Key
    res = client.post("/v1/privacy/exports", json={"format": "json"}, headers=REQUEST_HEADERS)
    assert res.status_code == 422

    res = client.post("/v1/privacy/deletions", json={"confirmed": True}, headers=REQUEST_HEADERS)
    assert res.status_code == 422

    res = client.post(f"/v1/privacy/deletions/{uuid4()}/cancel", json={}, headers=REQUEST_HEADERS)
    assert res.status_code == 422


def test_export_lifecycle_endpoints() -> None:
    app = create_app()
    fake = FakePrivacyService()
    app.dependency_overrides[get_authenticated_request] = make_authenticated_request
    app.dependency_overrides[get_privacy_service] = lambda: fake
    client = TestClient(app)

    # Create export -> 202 Accepted
    create_res = client.post(
        "/v1/privacy/exports",
        json={"format": "json"},
        headers=IDEMPOTENCY_HEADERS,
    )
    assert create_res.status_code == 202
    created_data = create_res.json()
    assert created_data["status"] == "requested"
    assert created_data["request_type"] == "export"
    assert created_data["id"] == str(fake.export_id)

    # Get export status -> 200 OK
    get_res = client.get(f"/v1/privacy/exports/{fake.export_id}", headers=REQUEST_HEADERS)
    assert get_res.status_code == 200
    get_data = get_res.json()
    assert get_data["status"] == "completed"
    assert get_data["download_url"] is not None

    # Get unknown export -> 404
    missing_res = client.get(f"/v1/privacy/exports/{uuid4()}", headers=REQUEST_HEADERS)
    assert missing_res.status_code == 404


def test_deletion_lifecycle_endpoints() -> None:
    app = create_app()
    fake = FakePrivacyService()
    app.dependency_overrides[get_authenticated_request] = make_authenticated_request
    app.dependency_overrides[get_privacy_service] = lambda: fake
    client = TestClient(app)

    # Unconfirmed deletion -> 400
    bad_res = client.post(
        "/v1/privacy/deletions",
        json={"confirmed": False},
        headers=IDEMPOTENCY_HEADERS,
    )
    assert bad_res.status_code == 400

    # Create deletion -> 202 Accepted
    create_res = client.post(
        "/v1/privacy/deletions",
        json={"confirmed": True},
        headers=IDEMPOTENCY_HEADERS,
    )
    assert create_res.status_code == 202
    created_data = create_res.json()
    assert created_data["status"] == "requested"
    assert created_data["request_type"] == "delete"

    # Get deletion status -> 200 OK
    get_res = client.get(f"/v1/privacy/deletions/{fake.deletion_id}", headers=REQUEST_HEADERS)
    assert get_res.status_code == 200
    assert get_res.json()["status"] == "requested"

    # Cancel deletion -> 200 OK
    cancel_res = client.post(
        f"/v1/privacy/deletions/{fake.deletion_id}/cancel",
        json={"reason": "changed mind"},
        headers=IDEMPOTENCY_HEADERS,
    )
    assert cancel_res.status_code == 200
    assert cancel_res.json()["status"] == "cancelled"

    # Cancel when already completed/processing -> 409 Conflict
    fake.deletion_status = "processing"
    disallowed_res = client.post(
        f"/v1/privacy/deletions/{fake.deletion_id}/cancel",
        json={"reason": "changed mind"},
        headers=IDEMPOTENCY_HEADERS,
    )
    assert disallowed_res.status_code == 409


def test_recent_authentication_enforcement() -> None:
    class MockRepo:
        def create_export_request(self, *args: Any, **kwargs: Any) -> dict[str, Any]:
            now = datetime.now(UTC)
            return {
                "id": uuid4(),
                "request_type": "export",
                "status": "requested",
                "requested_at": now,
            }

        def create_deletion_request(self, *args: Any, **kwargs: Any) -> dict[str, Any]:
            now = datetime.now(UTC)
            return {
                "id": uuid4(),
                "request_type": "delete",
                "status": "requested",
                "requested_at": now,
            }

    settings = Settings(recent_auth_window_seconds=600)  # 10 minute window
    service = PrivacyService(MockRepo(), settings)  # type: ignore[arg-type]

    # Stale auth: 15 minutes ago
    stale_auth = make_authenticated_request(
        authenticated_at=datetime.now(UTC) - timedelta(minutes=15)
    )
    with pytest.raises(ApiError) as exc_export:
        service.create_export(stale_auth, PrivacyExportRequest(), idempotency_key="test-key-1")
    assert exc_export.value.status_code == 403
    assert exc_export.value.code == "recent_authentication_required"

    with pytest.raises(ApiError) as exc_del:
        body = PrivacyDeletionRequest(confirmed=True)
        service.create_deletion(stale_auth, body, idempotency_key="test-key-2")
    assert exc_del.value.status_code == 403
    assert exc_del.value.code == "recent_authentication_required"

    # Missing auth time
    no_auth_time = AuthenticatedRequest(
        context=AuthContext(
            issuer="https://test.supabase.co/auth/v1",
            subject="sub1",
            session_id=uuid4(),
            role="authenticated",
            authenticated_at=None,
            expires_at=datetime.now(UTC) + timedelta(minutes=5),
        ),
        access_token=SecretStr("token"),
    )
    with pytest.raises(ApiError) as exc_missing:
        service.create_export(no_auth_time, PrivacyExportRequest(), idempotency_key="test-key-3")
    assert exc_missing.value.status_code == 403

    # Fresh auth: 2 minutes ago -> passes recent auth
    fresh_auth = make_authenticated_request(
        authenticated_at=datetime.now(UTC) - timedelta(minutes=2)
    )
    res = service.create_export(fresh_auth, PrivacyExportRequest(), idempotency_key="test-key-4")
    assert res.status == "requested"


def test_export_download_token_authorization() -> None:
    app = create_app()
    fake_service = FakePrivacyService()
    app.dependency_overrides[get_privacy_service] = lambda: fake_service
    client = TestClient(app)

    # 1. Missing token -> 401
    res = client.get(f"/v1/privacy/exports/{fake_service.export_id}/download")
    assert res.status_code == 401
    assert res.json()["error"]["code"] == "authentication_required"

    # 2. Invalid token -> 403
    res = client.get(f"/v1/privacy/exports/{fake_service.export_id}/download?token=bad-token")
    assert res.status_code == 403
    assert res.json()["error"]["code"] == "forbidden"

    # 3. Valid token -> 200 application/zip
    res = client.get(
        f"/v1/privacy/exports/{fake_service.export_id}/download?token={fake_service.valid_token}"
    )
    assert res.status_code == 200
    assert res.headers["content-type"] == "application/zip"
    assert res.content == fake_service.export_zip_content
