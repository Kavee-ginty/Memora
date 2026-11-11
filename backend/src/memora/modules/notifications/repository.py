"""Persistence for notification preferences reads and delivery results.

Preference and device rows stay owned by the identity domain (Schema §6.4-
6.5); this module reads them through narrow, owner-scoped SELECTs that run as
``memora_api`` with ``memora.user_id`` set (the caller's transaction sets the
context, matching the worker convention in ``memora.worker``). Delivery rows
are appended only through the SECURITY DEFINER functions of migration
``20261111_0015`` — the ledger is append-only and never read by clients.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime
from uuid import UUID

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from sqlalchemy import Connection, text

from memora.modules.notifications.constants import REMINDER_CATEGORIES

# Ciphertext format written by the identity device protector (T06): a one-byte
# format version, a 12-byte AES-GCM nonce, then the ciphertext bound to the
# owner's ``oidc_issuer\0oidc_subject`` as AAD.
_TOKEN_FORMAT_VERSION = 1
_TOKEN_NONCE_BYTES = 12

# The worker's advisory-lock domain, distinct from the memory engine's.
_DELIVERY_LOCK_DOMAIN = 77


@dataclass(frozen=True)
class NotificationPreferences:
    """The persisted notification preference row (Schema §6.5 + migration 0010)."""

    notifications_enabled: bool
    mission_enabled: bool
    reward_enabled: bool
    quiet_start_local: str | None
    quiet_end_local: str | None
    preferred_window_start_local: str | None
    preferred_window_end_local: str | None
    timezone: str
    lock_screen_detail: str
    max_daily_reminders: int


@dataclass(frozen=True)
class PushDevice:
    """One registered device eligible for a send."""

    device_id: UUID
    token_ciphertext: bytes
    oidc_issuer: str
    oidc_subject: str


@dataclass(frozen=True)
class RecordedDelivery:
    """Outcome of one recorded ledger row."""

    delivery_id: UUID | None
    replayed: bool


def load_preferences(connection: Connection, user_id: UUID) -> NotificationPreferences | None:
    """Read the user's notification preferences, or ``None`` when unset."""

    row = (
        connection.execute(
            text(
                """
                SELECT notifications_enabled, mission_enabled, reward_enabled,
                       quiet_start_local, quiet_end_local,
                       preferred_window_start_local, preferred_window_end_local,
                       timezone, lock_screen_detail, max_daily_reminders
                FROM notification_preferences
                WHERE user_id = :user_id
                """
            ),
            {"user_id": user_id},
        )
        .mappings()
        .first()
    )
    if row is None:
        return None
    return NotificationPreferences(
        notifications_enabled=bool(row["notifications_enabled"]),
        mission_enabled=bool(row["mission_enabled"]),
        reward_enabled=bool(row["reward_enabled"]),
        quiet_start_local=_time_text(row["quiet_start_local"]),
        quiet_end_local=_time_text(row["quiet_end_local"]),
        preferred_window_start_local=_time_text(row["preferred_window_start_local"]),
        preferred_window_end_local=_time_text(row["preferred_window_end_local"]),
        timezone=str(row["timezone"]),
        lock_screen_detail=str(row["lock_screen_detail"]),
        max_daily_reminders=int(row["max_daily_reminders"]),
    )


def load_sendable_devices(connection: Connection, user_id: UUID) -> list[PushDevice]:
    """Registered, non-revoked devices that still hold a push token."""

    rows = connection.execute(
        text(
            """
            SELECT d.id AS device_id, d.push_token_ciphertext,
                   u.oidc_issuer, u.oidc_subject
            FROM device_registrations d
            JOIN users u ON u.id = d.user_id
            WHERE d.user_id = :user_id
              AND d.revoked_at IS NULL
              AND d.push_token_ciphertext IS NOT NULL
            ORDER BY d.last_seen_at DESC, d.id
            """
        ),
        {"user_id": user_id},
    ).mappings()
    return [
        PushDevice(
            device_id=UUID(str(row["device_id"])),
            token_ciphertext=bytes(row["push_token_ciphertext"]),
            oidc_issuer=str(row["oidc_issuer"]),
            oidc_subject=str(row["oidc_subject"]),
        )
        for row in rows
    ]


def delivery_exists(connection: Connection, user_id: UUID, dedupe_key: str) -> bool:
    """Whether any ledger row already exists for this trigger dedupe key."""

    return bool(
        connection.scalar(
            text("SELECT memora_notifications_delivery_exists(:user_id, :dedupe_key)"),
            {"user_id": user_id, "dedupe_key": dedupe_key},
        )
    )


def reminders_sent_on(connection: Connection, user_id: UUID, timezone: str, local_day: date) -> int:
    """Delivered reminder pushes counted on the user's local calendar day."""

    return int(
        connection.scalar(
            text("SELECT memora_notifications_reminders_sent(:user_id, :tz, :local_day)"),
            {"user_id": user_id, "tz": timezone, "local_day": local_day},
        )
    )


def record_delivery(
    connection: Connection,
    *,
    user_id: UUID,
    notification_id: str,
    category: str,
    resource_type: str,
    resource_id: str,
    dedupe_key: str,
    device_id: UUID | None,
    status: str,
    skip_reason: str | None,
    provider_code: str | None,
    provider_message_id: str | None,
    created_at: datetime,
) -> RecordedDelivery:
    """Append one delivery outcome; replayed when the row already existed.

    ``created_at`` is the caller's logical send time so cap accounting stays
    deterministic under the worker clock (defaults stay wall-clock in SQL for
    any caller that omits it via raw SQL only).
    """

    delivery_id = connection.scalar(
        text(
            """
            SELECT memora_notifications_record_delivery(
                :user_id, :notification_id, :category, :resource_type,
                :resource_id, :dedupe_key, :device_id, :status, :skip_reason,
                :provider_code, :provider_message_id, :created_at
            )
            """
        ),
        {
            "user_id": user_id,
            "notification_id": notification_id,
            "category": category,
            "resource_type": resource_type,
            "resource_id": resource_id,
            "dedupe_key": dedupe_key,
            "device_id": device_id,
            "status": status,
            "skip_reason": skip_reason,
            "provider_code": provider_code,
            "created_at": created_at,
            "provider_message_id": provider_message_id,
        },
    )
    if delivery_id is None:
        # The unique send index already holds this (user, notification,
        # device) outcome: a concurrent worker recorded it first.
        existing = connection.execute(
            text(
                """
                SELECT id FROM notification_deliveries
                WHERE user_id = :user_id AND notification_id = :notification_id
                  AND device_id IS NOT DISTINCT FROM :device_id
                """
            ),
            {"user_id": user_id, "notification_id": notification_id, "device_id": device_id},
        ).scalar()
        return RecordedDelivery(delivery_id=existing, replayed=True)
    return RecordedDelivery(delivery_id=UUID(str(delivery_id)), replayed=False)


def take_delivery_lock(connection: Connection, dedupe_key: str) -> None:
    """Serialize consume-once decisions for one trigger dedupe key.

    Called inside the sending transaction so two workers that receive the
    same trigger cannot both pass the existence check.
    """

    connection.execute(
        text("SELECT pg_advisory_xact_lock(hashtextextended(:domain || ':' || :key, 0))"),
        {"domain": _DELIVERY_LOCK_DOMAIN, "key": dedupe_key},
    )


def decrypt_push_token(ciphertext: bytes, *, issuer: str, subject: str, key: bytes) -> str:
    """Decrypt a device push token written by the identity protector (T06).

    Raises ``ValueError`` for unknown formats or failed authentication so the
    caller records a ``token_unreadable`` outcome instead of crashing.
    """

    if not ciphertext or ciphertext[0] != _TOKEN_FORMAT_VERSION:
        raise ValueError("unsupported push token ciphertext format version")
    if len(ciphertext) < 1 + _TOKEN_NONCE_BYTES + 16:
        raise ValueError("push token ciphertext is too short")
    nonce = ciphertext[1 : 1 + _TOKEN_NONCE_BYTES]
    encrypted = ciphertext[1 + _TOKEN_NONCE_BYTES :]
    associated = f"{issuer}\0{subject}".encode()
    try:
        raw = AESGCM(key).decrypt(nonce, encrypted, associated)
    except Exception as exc:  # noqa: BLE001 - AESGCM raises InvalidTag
        raise ValueError("push token ciphertext failed authentication") from exc
    return raw.decode("utf-8")


def _time_text(value) -> str | None:  # noqa: ANN001 - datetime.time or None from driver
    return value.isoformat() if value is not None else None


__all__ = [
    "REMINDER_CATEGORIES",
    "NotificationPreferences",
    "PushDevice",
    "RecordedDelivery",
    "decrypt_push_token",
    "delivery_exists",
    "load_preferences",
    "load_sendable_devices",
    "record_delivery",
    "reminders_sent_on",
    "take_delivery_lock",
]
