from __future__ import annotations

from datetime import UTC, date, datetime
from typing import Annotated
from uuid import UUID

from pydantic import AwareDatetime, BaseModel, Field, PlainSerializer, model_validator


def _serialize_utc_datetime(value: datetime) -> str:
    return value.astimezone(UTC).isoformat(timespec="seconds").replace("+00:00", "Z")


UtcDatetime = Annotated[
    AwareDatetime,
    PlainSerializer(_serialize_utc_datetime, return_type=str, when_used="json"),
]
CalendarDate = date
Version = Annotated[int, Field(ge=1)]
Cursor = Annotated[str, Field(min_length=1, max_length=512)]
AsyncOperationStatus = Annotated[str, Field(min_length=1, max_length=64)]


class PageMeta(BaseModel):
    next_cursor: Cursor | None
    has_more: bool

    @model_validator(mode="after")
    def _validate_cursor(self) -> PageMeta:
        if self.has_more != (self.next_cursor is not None):
            raise ValueError("has_more must be true exactly when next_cursor is present")
        return self


class Page[T](PageMeta):
    items: list[T]


class PageParams(BaseModel):
    cursor: Cursor | None = None
    limit: Annotated[int, Field(ge=1, le=100)] = 20


class AsyncOperation(BaseModel):
    resource_id: UUID
    status: AsyncOperationStatus
    status_url: Annotated[str, Field(min_length=1, max_length=2048, pattern=r"^/")]
    retry_after_seconds: Annotated[int, Field(ge=0)] | None
    updated_at: UtcDatetime
