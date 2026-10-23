import pytest
from httpx import ASGITransport, AsyncClient

from memora.main import app


@pytest.mark.asyncio
@pytest.mark.parametrize("path", ["/health/live", "/health/ready"])
async def test_health(path: str) -> None:
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as client:
        response = await client.get(path)

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
