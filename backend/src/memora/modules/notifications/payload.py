"""Push payload construction for the closed API §16.2 contract.

A push payload contains only a notification category, an opaque resource
identifier, a route intent, an expiry, a localization key with safe
parameters and a per-send notification id. The builder is the single place
that assembles payloads, and it rejects everything outside the allowlists in
:mod:`memora.modules.notifications.constants` — note text, answers,
misconception details and tokens cannot be expressed, so they cannot leak
into a push (PRD 031, Task Table T19 acceptance gate).
"""

from __future__ import annotations

import re
from collections.abc import Mapping
from dataclasses import dataclass, field
from datetime import UTC, datetime
from typing import Final, Literal

from memora.modules.notifications.constants import (
    COUNT_MAX,
    PARAM_COUNT,
    PARAM_SUBJECT_NAME,
    PAYLOAD_SCHEMA_VERSION,
    SAFE_PARAM_NAMES,
    SUBJECT_NAME_MAX_LENGTH,
    NotificationCategorySpec,
    category_spec,
)

LockScreenDetail = Literal["minimal", "subject", "detailed"]

LOCK_SCREEN_DETAILS: Final[tuple[str, ...]] = ("minimal", "subject", "detailed")

# Opaque identifier shape shared by notification ids and resource ids. Callers
# pass server-issued UUIDs; the shape stays deliberately narrow so no readable
# content can hide inside an identifier.
_OPAQUE_ID_PATTERN: Final = re.compile(r"\A[0-9a-zA-Z_-]{8,64}\Z")

_SUBJECT_NAME_FORBIDDEN: Final = re.compile(r"[\x00-\x1f\x7f]")

# Resource types push may reference. The value names the aggregate the client
# must revalidate through the API before navigating (API §16.3).
RESOURCE_MISSION: Final = "mission"
RESOURCE_LEARNING_UPDATE: Final = "learning_update"
RESOURCE_REWARD_GRANT: Final = "reward_grant"
RESOURCE_PRIVACY_REQUEST: Final = "privacy_request"

CATEGORY_RESOURCE_TYPES: Final[dict[str, tuple[str, ...]]] = {
    "mission_ready": (RESOURCE_MISSION,),
    "due_memories": (RESOURCE_MISSION,),
    "verification_required": (RESOURCE_LEARNING_UPDATE,),
    "learning_path_ready": (RESOURCE_LEARNING_UPDATE,),
    "reward_ready": (RESOURCE_REWARD_GRANT,),
    "privacy_export_ready": (RESOURCE_PRIVACY_REQUEST,),
}

_PARAM_DATA_PREFIX: Final = "param."

_DATA_KEYS: Final[tuple[str, ...]] = (
    "schema_version",
    "notification_id",
    "category",
    "route_intent",
    "resource_type",
    "resource_id",
    "expires_at",
    "loc_key",
)


class PayloadError(ValueError):
    """Raised when a payload would violate the closed push contract."""


@dataclass(frozen=True)
class NotificationPayload:
    """One outbound push payload under the closed API §16.2 contract."""

    schema_version: str
    notification_id: str
    category: str
    route_intent: str
    resource_type: str
    resource_id: str
    expires_at: datetime
    loc_key: str
    params: Mapping[str, str | int] = field(default_factory=dict)

    def spec(self) -> NotificationCategorySpec:
        return category_spec(self.category)


def _validate_opaque_id(value: str, label: str) -> str:
    if not isinstance(value, str) or not _OPAQUE_ID_PATTERN.match(value):
        raise PayloadError(f"{label} must be 8-64 characters of [0-9a-zA-Z_-]")
    return value


def _validate_subject_name(value: str) -> str:
    if not isinstance(value, str):
        raise PayloadError("subject_name parameter must be a string")
    stripped = value.strip()
    if not stripped or len(stripped) > SUBJECT_NAME_MAX_LENGTH:
        raise PayloadError(f"subject_name parameter must be 1-{SUBJECT_NAME_MAX_LENGTH} characters")
    if _SUBJECT_NAME_FORBIDDEN.search(stripped):
        raise PayloadError("subject_name parameter must not contain control characters")
    return stripped


def _validate_count(value: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise PayloadError("count parameter must be an integer")
    if not 0 <= value <= COUNT_MAX:
        raise PayloadError(f"count parameter must be between 0 and {COUNT_MAX}")
    return value


def _validate_params(
    params: Mapping[str, str | int] | None,
) -> dict[str, str | int]:
    if params is None:
        return {}
    unknown = sorted(set(params) - set(SAFE_PARAM_NAMES))
    if unknown:
        raise PayloadError(f"payload parameters outside the safe allowlist: {unknown}")
    validated: dict[str, str | int] = {}
    if PARAM_SUBJECT_NAME in params:
        validated[PARAM_SUBJECT_NAME] = _validate_subject_name(params[PARAM_SUBJECT_NAME])  # type: ignore[arg-type]
    if PARAM_COUNT in params:
        validated[PARAM_COUNT] = _validate_count(params[PARAM_COUNT])  # type: ignore[arg-type]
    return validated


def _apply_detail_band(
    params: dict[str, str | int], detail: LockScreenDetail
) -> dict[str, str | int]:
    """Filter safe parameters down to the user's lock-screen detail band."""

    if detail == "minimal":
        return {}
    if detail == "subject":
        return {name: value for name, value in params.items() if name == PARAM_SUBJECT_NAME}
    return dict(params)


def build_payload(
    *,
    category: str,
    resource_id: str,
    expires_at: datetime,
    notification_id: str,
    resource_type: str | None = None,
    detail: LockScreenDetail = "minimal",
    params: Mapping[str, str | int] | None = None,
) -> NotificationPayload:
    """Build and validate one outbound payload.

    ``detail`` is the recipient's persisted ``lock_screen_detail`` preference
    (Schema §6.5); parameters outside the band are dropped here so downstream
    code cannot leak them by accident.
    """

    spec = category_spec(category)  # KeyError for unknown categories.

    if resource_type is None:
        resource_type = CATEGORY_RESOURCE_TYPES[category][0]
    allowed_types = CATEGORY_RESOURCE_TYPES[category]
    if resource_type not in allowed_types:
        raise PayloadError(
            f"resource_type {resource_type!r} is not valid for category {category!r}"
        )

    if expires_at.tzinfo is None or expires_at.tzinfo.utcoffset(expires_at) is None:
        raise PayloadError("expires_at must be timezone-aware")

    if detail not in LOCK_SCREEN_DETAILS:
        raise PayloadError(f"lock_screen_detail must be one of {LOCK_SCREEN_DETAILS}")

    return NotificationPayload(
        schema_version=PAYLOAD_SCHEMA_VERSION,
        notification_id=_validate_opaque_id(notification_id, "notification_id"),
        category=category,
        route_intent=spec.route_intent,
        resource_type=resource_type,
        resource_id=_validate_opaque_id(resource_id, "resource_id"),
        expires_at=expires_at,
        loc_key=spec.loc_key,
        params=_apply_detail_band(_validate_params(params), detail),
    )


def payload_to_data(payload: NotificationPayload) -> dict[str, str]:
    """Flatten a payload into the string map pushed to the device.

    Provider data payloads are flat ``str -> str`` maps; parameters travel
    under a ``param.`` prefix so unknown future top-level keys can be ignored
    by clients.
    """

    data = {
        "schema_version": payload.schema_version,
        "notification_id": payload.notification_id,
        "category": payload.category,
        "route_intent": payload.route_intent,
        "resource_type": payload.resource_type,
        "resource_id": payload.resource_id,
        "expires_at": payload.expires_at.astimezone(UTC).isoformat().replace("+00:00", "Z"),
        "loc_key": payload.loc_key,
    }
    for name, value in payload.params.items():
        data[f"{_PARAM_DATA_PREFIX}{name}"] = str(value)
    return data


def payload_from_data(data: Mapping[str, str]) -> NotificationPayload:
    """Rebuild a payload from its flattened wire form.

    Malformed or unknown-version data raises :class:`PayloadError`; callers
    treat that as an invalid intent and fall back safely instead of crashing.
    """

    missing = [key for key in _DATA_KEYS if key not in data]
    if missing:
        raise PayloadError(f"payload data missing keys: {missing}")
    if data["schema_version"] != PAYLOAD_SCHEMA_VERSION:
        raise PayloadError(f"unsupported payload schema_version: {data['schema_version']!r}")

    try:
        expires_at = datetime.fromisoformat(data["expires_at"].replace("Z", "+00:00"))
    except ValueError as exc:
        raise PayloadError("expires_at is not an ISO 8601 timestamp") from exc

    params: dict[str, str | int] = {}
    for key, value in data.items():
        if not key.startswith(_PARAM_DATA_PREFIX):
            continue
        name = key[len(_PARAM_DATA_PREFIX) :]
        if name not in SAFE_PARAM_NAMES:
            raise PayloadError(f"payload parameter outside the safe allowlist: {name}")
        params[name] = int(value) if name == PARAM_COUNT else value

    spec = category_spec(data["category"])
    if data["route_intent"] != spec.route_intent:
        raise PayloadError("route_intent does not match the category registry")
    if data["loc_key"] != spec.loc_key:
        raise PayloadError("loc_key does not match the category registry")
    if data["resource_type"] not in CATEGORY_RESOURCE_TYPES[data["category"]]:
        raise PayloadError(
            f"resource_type {data['resource_type']!r} is not valid for "
            f"category {data['category']!r}"
        )

    return NotificationPayload(
        schema_version=data["schema_version"],
        notification_id=_validate_opaque_id(data["notification_id"], "notification_id"),
        category=data["category"],
        route_intent=spec.route_intent,
        resource_type=data["resource_type"],
        resource_id=_validate_opaque_id(data["resource_id"], "resource_id"),
        expires_at=expires_at,
        loc_key=spec.loc_key,
        params=params,
    )


def is_expired(payload: NotificationPayload, now: datetime) -> bool:
    """Whether the intent is expired at ``now`` (send time and tap time)."""

    if now.tzinfo is None or now.tzinfo.utcoffset(now) is None:
        raise PayloadError("now must be timezone-aware")
    return now >= payload.expires_at
