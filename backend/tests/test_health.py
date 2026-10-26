from uuid import UUID

import pytest
from httpx import ASGITransport, AsyncClient

from memora.main import app


async def get(path: str):
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as client:
        return await client.get(path)


@pytest.mark.asyncio
async def test_live() -> None:
    response = await get("/health/live")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


@pytest.mark.asyncio
async def test_ready_when_database_is_available(monkeypatch) -> None:
    monkeypatch.setattr("memora.api.health.database_is_ready", lambda: True)

    response = await get("/health/ready")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


@pytest.mark.asyncio
async def test_not_ready_when_database_is_unavailable(monkeypatch) -> None:
    monkeypatch.setattr("memora.api.health.database_is_ready", lambda: False)

    response = await get("/health/ready")

    assert response.status_code == 503
    error = response.json()["error"]
    UUID(error.pop("request_id"))
    assert error == {
        "code": "temporarily_unavailable",
        "message": "The service is not ready.",
        "field_errors": [],
        "retryable": True,
        "retry_after_seconds": 5,
        "action": "retry",
    }
