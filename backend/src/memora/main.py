from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI

from memora.api.health import router as health_router
from memora.api.openapi import custom_openapi
from memora.api.v1.router import router as v1_router
from memora.core.config import get_settings


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    get_settings()
    yield


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="Memora API",
        version="0.1.0",
        docs_url="/docs" if settings.docs_enabled else None,
        redoc_url=None,
        lifespan=lifespan,
    )
    app.include_router(health_router)
    app.include_router(v1_router)

    def openapi_schema() -> dict[str, Any]:
        return custom_openapi(app)

    app.openapi = openapi_schema  # type: ignore[method-assign]
    return app


app = create_app()
