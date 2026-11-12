"""Send-time enforcement and dispatch for push notifications.

One dispatch is one transactional decision (TRD §16.2): take the per-trigger
advisory lock, honour the closed enforcement order, then send to every
eligible device and append exactly one ledger row per attempt outcome. The
enforcement order (PRD 031-032, D5):

1. expired intent,
2. notification preferences missing or disabled,
3. per-category choice (mission / reward),
4. reminder frequency cap per user-local day,
5. quiet hours in the user's timezone with the preferred-window exception,
6. consume-once: the trigger dedupe key has already produced a delivery,
7. per-device send with bounded provider results.

Notification denial never raises into callers: every blocked dispatch
resolves to a recorded skip with a closed reason code (T17 gate carried
forward). Logs carry category, resource identifiers and counts only — never
payload parameters or push tokens (API §19).
"""

from __future__ import annotations

import logging
from collections.abc import Mapping
from dataclasses import dataclass
from datetime import datetime, time
from uuid import UUID
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from sqlalchemy import Connection

from memora.modules.notifications.constants import (
    CATEGORY_DUE_MEMORIES,
    CATEGORY_MISSION_READY,
    CATEGORY_REWARD_READY,
    REMINDER_CATEGORIES,
    category_spec,
)
from memora.modules.notifications.payload import NotificationPayload, is_expired
from memora.modules.notifications.providers import (
    PROVIDER_OUTCOME_SENT,
    ProviderResult,
)
from memora.modules.notifications.repository import (
    complete_send_outcome,
    decrypt_push_token,
    delivery_exists,
    load_preferences,
    load_sendable_devices,
    record_delivery,
    reminders_sent_on,
    take_delivery_lock,
)

logger = logging.getLogger(__name__)

# Closed skip-reason set; mirrors the ``notification_deliveries.skip_reason``
# CHECK added by migration 20261111_0015.
SKIP_ALREADY_DELIVERED = "already_delivered"
SKIP_CATEGORY_DISABLED = "category_disabled"
SKIP_EXPIRED = "expired"
SKIP_NO_DEVICES = "no_devices"
SKIP_NOTIFICATIONS_DISABLED = "notifications_disabled"
SKIP_QUIET_HOURS = "quiet_hours"
SKIP_REMINDER_CAP = "reminder_cap_reached"
SKIP_RESOURCE_UNAVAILABLE = "resource_unavailable"
SKIP_TOKEN_UNREADABLE = "token_unreadable"


def record_skip_once(
    connection: Connection,
    *,
    user_id: UUID,
    notification_id: str,
    category: str,
    resource_type: str,
    resource_id: str,
    dedupe_key: str,
    reason: str,
    now: datetime,
) -> bool:
    """Record a pre-dispatch skip exactly once per trigger dedupe key.

    Used when a trigger must be consumed without producing a payload — for
    example a due-memories reminder when the user has no open mission today.
    Returns ``True`` when this call recorded the skip, ``False`` when another
    dispatch already consumed the trigger.
    """

    take_delivery_lock(connection, dedupe_key)
    if delivery_exists(connection, user_id, dedupe_key):
        return False
    record_delivery(
        connection,
        user_id=user_id,
        notification_id=notification_id,
        category=category,
        resource_type=resource_type,
        resource_id=resource_id,
        dedupe_key=dedupe_key,
        device_id=None,
        status="skipped",
        skip_reason=reason,
        provider_code=None,
        provider_message_id=None,
        created_at=now,
    )
    return True


@dataclass(frozen=True)
class DeliveryOutcome:
    """Result of dispatching one payload to one user."""

    notification_id: str
    category: str
    delivered: int = 0
    failed: int = 0
    replayed: bool = False
    skip_reason: str | None = None


def _in_window(local: time, start: time, end: time) -> bool:
    """Whether ``local`` falls in [start, end), tolerating windows past midnight."""

    if start <= end:
        return start <= local < end
    return local >= start or local < end


def quiet_hours_block(
    now_utc: datetime,
    *,
    timezone_name: str,
    quiet_start: str | None,
    quiet_end: str | None,
    preferred_start: str | None,
    preferred_end: str | None,
) -> bool:
    """Whether quiet hours block a send at ``now_utc`` (PRD 032).

    Quiet hours follow the recipient's IANA timezone. A configured preferred
    window is the user's explicit exception: inside it, quiet hours never
    block. Invalid timezones degrade to "notifications not configured".
    """

    if quiet_start is None or quiet_end is None:
        return False
    try:
        local_now = now_utc.astimezone(ZoneInfo(timezone_name)).time()
    except (ZoneInfoNotFoundError, ValueError):
        return True

    start = time.fromisoformat(quiet_start)
    end = time.fromisoformat(quiet_end)
    if not _in_window(local_now, start, end):
        return False
    if preferred_start is None or preferred_end is None:
        return True
    return not _in_window(
        local_now, time.fromisoformat(preferred_start), time.fromisoformat(preferred_end)
    )


def category_blocked(preferences, category: str) -> bool:  # noqa: ANN001 - prefs dataclass
    """Whether the user's category choice blocks this category."""

    if category in (CATEGORY_MISSION_READY, CATEGORY_DUE_MEMORIES):
        return not preferences.mission_enabled
    if category == CATEGORY_REWARD_READY:
        return not preferences.reward_enabled
    return False


@dataclass(frozen=True)
class PlannedSend:
    """One device resolved for delivery, with its decrypted push token."""

    device_id: UUID
    push_token: str


@dataclass(frozen=True)
class DispatchPlan:
    """The transactional plan for one payload (two-phase send).

    ``plan_dispatch`` records every decision — skips and per-device
    in-flight rows — inside the caller's transaction. The provider call then
    happens strictly outside any database transaction (Schema 14.2), and
    ``complete_dispatch`` persists the outcomes in a short transaction.
    """

    user_id: UUID
    payload: NotificationPayload
    dedupe_key: str
    devices: tuple[PlannedSend, ...] = ()
    replayed: bool = False
    skip_reason: str | None = None

    @property
    def is_send(self) -> bool:
        return not self.replayed and self.skip_reason is None and bool(self.devices)


def _cap_lock_key(user_id: UUID) -> str:
    """Shared per-user lock for reminder dispatches (PRD 032).

    ``mission_ready`` and ``due_memories`` reminders use different dedupe
    keys; serializing their plan phase on one per-user lock keeps the daily
    cap correct when different reminder categories are processed
    concurrently.
    """

    return f"notifications:reminder-cap:{user_id}"


def plan_dispatch(
    connection: Connection,
    *,
    user_id: UUID,
    payload: NotificationPayload,
    dedupe_key: str,
    now: datetime,
    token_encryption_key: bytes,
) -> DispatchPlan:
    """Enforce preferences and record the dispatch plan transactionally."""

    category_spec(payload.category)  # unknown categories fail fast

    def skipped(reason: str) -> DispatchPlan:
        logger.info(
            "notification.skip category=%s resource_type=%s resource_id=%s "
            "notification_id=%s reason=%s",
            payload.category,
            payload.resource_type,
            payload.resource_id,
            payload.notification_id,
            reason,
        )
        record_delivery(
            connection,
            user_id=user_id,
            notification_id=payload.notification_id,
            category=payload.category,
            resource_type=payload.resource_type,
            resource_id=payload.resource_id,
            dedupe_key=dedupe_key,
            device_id=None,
            status="skipped",
            skip_reason=reason,
            provider_code=None,
            provider_message_id=None,
            created_at=now,
        )
        return DispatchPlan(
            user_id=user_id,
            payload=payload,
            dedupe_key=dedupe_key,
            skip_reason=reason,
        )

    # Reminder categories serialize on one shared per-user lock so the daily
    # cap holds across concurrently planned categories; workflow signals
    # lock per trigger dedupe key.
    lock_key = _cap_lock_key(user_id) if payload.category in REMINDER_CATEGORIES else dedupe_key
    take_delivery_lock(connection, lock_key)

    if delivery_exists(connection, user_id, dedupe_key):
        logger.info(
            "notification.replayed category=%s notification_id=%s",
            payload.category,
            payload.notification_id,
        )
        return DispatchPlan(
            user_id=user_id,
            payload=payload,
            dedupe_key=dedupe_key,
            replayed=True,
        )

    if is_expired(payload, now):
        return skipped(SKIP_EXPIRED)

    preferences = load_preferences(connection, user_id)
    if preferences is None or not preferences.notifications_enabled:
        return skipped(SKIP_NOTIFICATIONS_DISABLED)

    if category_blocked(preferences, payload.category):
        return skipped(SKIP_CATEGORY_DISABLED)

    if payload.category in REMINDER_CATEGORIES:
        try:
            local_day = now.astimezone(ZoneInfo(preferences.timezone)).date()
        except (ZoneInfoNotFoundError, ValueError):
            return skipped(SKIP_NOTIFICATIONS_DISABLED)
        # In-flight sends count toward the cap: a concurrent reminder of the
        # other category is already recorded as 'sending'.
        sent_today = reminders_sent_on(connection, user_id, preferences.timezone, local_day)
        if sent_today >= preferences.max_daily_reminders:
            return skipped(SKIP_REMINDER_CAP)

    if quiet_hours_block(
        now,
        timezone_name=preferences.timezone,
        quiet_start=preferences.quiet_start_local,
        quiet_end=preferences.quiet_end_local,
        preferred_start=preferences.preferred_window_start_local,
        preferred_end=preferences.preferred_window_end_local,
    ):
        return skipped(SKIP_QUIET_HOURS)

    devices = load_sendable_devices(connection, user_id)
    if not devices:
        return skipped(SKIP_NO_DEVICES)

    planned: list[PlannedSend] = []
    for device in devices:
        try:
            token = decrypt_push_token(
                device.token_ciphertext,
                issuer=device.oidc_issuer,
                subject=device.oidc_subject,
                key=token_encryption_key,
            )
        except ValueError:
            record_delivery(
                connection,
                user_id=user_id,
                notification_id=payload.notification_id,
                category=payload.category,
                resource_type=payload.resource_type,
                resource_id=payload.resource_id,
                dedupe_key=dedupe_key,
                device_id=device.device_id,
                status="failed",
                skip_reason=None,
                provider_code=SKIP_TOKEN_UNREADABLE,
                provider_message_id=None,
                created_at=now,
            )
            continue
        # Record the in-flight row inside this transaction: it holds the
        # (user, notification, device) send index, so worker retries and
        # duplicate triggers cannot double-send while the external call is
        # in progress or after a crash (the stale-sending reconciler resolves
        # unknown outcomes).
        record_delivery(
            connection,
            user_id=user_id,
            notification_id=payload.notification_id,
            category=payload.category,
            resource_type=payload.resource_type,
            resource_id=payload.resource_id,
            dedupe_key=dedupe_key,
            device_id=device.device_id,
            status="sending",
            skip_reason=None,
            provider_code=None,
            provider_message_id=None,
            created_at=now,
        )
        planned.append(PlannedSend(device_id=device.device_id, push_token=token))

    return DispatchPlan(
        user_id=user_id,
        payload=payload,
        dedupe_key=dedupe_key,
        devices=tuple(planned),
    )


def complete_dispatch(
    connection: Connection,
    *,
    plan: DispatchPlan,
    results: Mapping[UUID, ProviderResult],
    now: datetime,
) -> DeliveryOutcome:
    """Persist per-device provider outcomes for an in-flight plan.

    Rows whose result is missing stay ``sending`` and are resolved to a
    bounded failed outcome by the stale-sending reconciler.
    """

    delivered = 0
    failed = 0
    for send in plan.devices:
        result = results.get(send.device_id)
        if result is None:
            continue
        if result.outcome == PROVIDER_OUTCOME_SENT:
            status = "sent"
            provider_code = None
            provider_message_id = result.provider_message_id
            delivered += 1
        else:
            # Terminal outcome for this trigger: the send index already holds
            # the row, so worker retries and duplicate triggers cannot
            # double-send. The provider adapter performs its own bounded
            # transport retries before classifying; later natural triggers
            # attempt again, and the client reads truth from the status
            # endpoint regardless (API 16.3).
            status = "failed"
            provider_code = result.reason_code
            provider_message_id = None
            failed += 1
        complete_send_outcome(
            connection,
            user_id=plan.user_id,
            notification_id=plan.payload.notification_id,
            device_id=send.device_id,
            status=status,
            provider_code=provider_code,
            provider_message_id=provider_message_id,
        )

    logger.info(
        "notification.dispatch category=%s resource_type=%s resource_id=%s "
        "notification_id=%s delivered=%d failed=%d",
        plan.payload.category,
        plan.payload.resource_type,
        plan.payload.resource_id,
        plan.payload.notification_id,
        delivered,
        failed,
    )
    return DeliveryOutcome(
        notification_id=plan.payload.notification_id,
        category=plan.payload.category,
        delivered=delivered,
        failed=failed,
    )


__all__ = [
    "DeliveryOutcome",
    "DispatchPlan",
    "PlannedSend",
    "SKIP_ALREADY_DELIVERED",
    "SKIP_CATEGORY_DISABLED",
    "SKIP_EXPIRED",
    "SKIP_NO_DEVICES",
    "SKIP_NOTIFICATIONS_DISABLED",
    "SKIP_QUIET_HOURS",
    "SKIP_REMINDER_CAP",
    "SKIP_RESOURCE_UNAVAILABLE",
    "SKIP_TOKEN_UNREADABLE",
    "category_blocked",
    "complete_dispatch",
    "plan_dispatch",
    "quiet_hours_block",
    "record_skip_once",
]
