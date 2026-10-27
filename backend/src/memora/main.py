from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any
from uuid import UUID, uuid4

from fastapi import FastAPI, Request

from memora.api.errors import install_error_handlers
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
    install_error_handlers(app)

    @app.middleware("http")
    async def request_context(request: Request, call_next: Any) -> Any:
        try:
            correlation_id = UUID(request.headers.get("X-Correlation-ID", ""))
        except ValueError:
            correlation_id = uuid4()
        request_id = uuid4()
        request.state.correlation_id = correlation_id
        request.state.request_id = request_id

        headers = [
            (name, value)
            for name, value in request.scope["headers"]
            if name.lower() != b"x-correlation-id"
        ]
        headers.append((b"x-correlation-id", str(correlation_id).encode("ascii")))
        request.scope["headers"] = headers

        response = await call_next(request)
        response.headers["X-Correlation-ID"] = str(correlation_id)
        response.headers["X-Request-ID"] = str(request_id)
        if request.url.path.startswith("/v1/"):
            response.headers["Cache-Control"] = "private, no-store"
        return response

    def openapi_schema() -> dict[str, Any]:
        return custom_openapi(app)

    app.openapi = openapi_schema  # type: ignore[method-assign]
    return app


app = create_app()
