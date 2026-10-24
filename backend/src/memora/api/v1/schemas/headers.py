from __future__ import annotations

from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class RequestHeaders(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    correlation_id: Annotated[UUID, Field(alias="X-Correlation-ID")]
    client_version: Annotated[
        str,
        Field(alias="X-Client-Version", min_length=1, max_length=50),
    ]
    platform: Annotated[Literal["android", "ios"], Field(alias="X-Platform")]
    accept_language: Annotated[
        str | None,
        Field(alias="Accept-Language", max_length=35),
    ] = None


class IdempotencyHeaders(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    idempotency_key: Annotated[
        str,
        Field(alias="Idempotency-Key", min_length=16, max_length=255),
    ]
