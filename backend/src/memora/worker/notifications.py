"""Notification trigger consumers and the durable push-send job.

Trigger flow (Flow §13.1, D6): producer transactions append outbox events of
the six trigger types; this worker's reconcile pass enqueues one
``notification.send`` job per unseen trigger event (dedupe key per event id,
so reconciliation never resurrects a dead-lettered job). The job handler
validates the documented trigger envelope, resolves the payload resource,
builds the closed-contract push payload and dispatches through
:func:`memora.modules.notifications.service.dispatch`, which owns quiet
hours, caps, consume-once and per-device delivery recording.

Job payloads and logs carry identifiers and bounded safe parameters only —
never learning text, answers, tokens or provider credentials (API §19).
"""

from __future__ import annotations

import base64
import logging
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Any
from uuid import UUID, uuid4
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from sqlalchemy import Connection, Engine, text

from memora.core.config import get_settings
from memora.modules.notifications.constants import (
    CATEGORY_DUE_MEMORIES,
    CATEGORY_LEARNING_PATH_READY,
    CATEGORY_MISSION_READY,
    CATEGORY_PRIVACY_EXPORT_READY,
    CATEGORY_REWARD_READY,
    CATEGORY_VERIFICATION_REQUIRED,
    category_spec,
)
from memora.modules.notifications.payload import NotificationPayload, build_payload
from memora.modules.notifications.providers import (
    NotificationProvider,
    ProviderResult,
    build_provider,
)
from memora.modules.notifications.repository import (
    expire_stale_sending as _expire_stale_sending,
)
from memora.modules.notifications.repository import load_preferences
from memora.modules.notifications.service import (
    SKIP_RESOURCE_UNAVAILABLE,
    DeliveryOutcome,
    DispatchPlan,
    complete_dispatch,
    plan_dispatch,
    record_skip_once,
)
from memora.worker.memory import (
    ENVELOPE_SCHEMA_VERSION,
    MAX_JOB_ATTEMPTS,
    WORKER_ROLE,
    NonRetryableJobError,
)

logger = logging.getLogger(__name__)

JOB_TYPE_NOTIFICATION_SEND = "notification.send"

# In-flight sends unresolved for longer than this are crashed workers; the
# outcome is unknown and resolves to a bounded failure (T22 spirit: unknown
# outcomes never duplicate).
STALE_SENDING_AFTER = timedelta(minutes=15)

# Outbox event types that may trigger a push. ``reward.granted`` is reserved
# for T15; consumers accept the documented envelope and tests exercise it
# with synthetic rows until that producer exists (D6).
EVENT_MISSION_READY = "mission.ready"
EVENT_REWARD_GRANTED = "reward.granted"
EVENT_VERIFICATION_REQUIRED = "ingestion.verification_required"
EVENT_LEARNING_PATH_READY = "ingestion.learning_path_committed"
EVENT_PRIVACY_EXPORT_READY = "privacy.export_ready"
EVENT_SCHEDULE_CHANGED = "memory.schedule_changed"

TRIGGER_EVENT_TYPES: tuple[str, ...] = (
    EVENT_SCHEDULE_CHANGED,
    EVENT_MISSION_READY,
    EVENT_REWARD_GRANTED,
    EVENT_VERIFICATION_REQUIRED,
    EVENT_LEARNING_PATH_READY,
    EVENT_PRIVACY_EXPORT_READY,
)

TRIGGER_EVENT_CATEGORIES: dict[str, str] = {
    EVENT_SCHEDULE_CHANGED: CATEGORY_DUE_MEMORIES,
    EVENT_MISSION_READY: CATEGORY_MISSION_READY,
    EVENT_REWARD_GRANTED: CATEGORY_REWARD_READY,
    EVENT_VERIFICATION_REQUIRED: CATEGORY_VERIFICATION_REQUIRED,
    EVENT_LEARNING_PATH_READY: CATEGORY_LEARNING_PATH_READY,
    EVENT_PRIVACY_EXPORT_READY: CATEGORY_PRIVACY_EXPORT_READY,
}

# Envelope field carrying the opaque resource id for each workflow trigger.
# The due-memories reminder resolves its resource from the user's open
# mission instead (see ``_resolve_due_memories_resource``).
TRIGGER_RESOURCE_FIELDS: dict[str, str] = {
    EVENT_MISSION_READY: "mission_id",
    EVENT_REWARD_GRANTED: "grant_id",
    EVENT_VERIFICATION_REQUIRED: "update_id",
    EVENT_LEARNING_PATH_READY: "update_id",
    EVENT_PRIVACY_EXPORT_READY: "request_id",
}

_NOTIFICATIONS_DEDUPE_PREFIX = "notifications:outbox:"

CODE_UNKNOWN_TRIGGER = "unknown_trigger_event"
CODE_OUTBOX_EVENT_MISSING = "outbox_event_missing"
CODE_INVALID_EVENT_PAYLOAD = "invalid_trigger_envelope"


@dataclass(frozen=True)
class NotificationDispatcher:
    """Configured provider plus the device-token encryption key."""

    provider: NotificationProvider
    token_encryption_key: bytes


_DISPATCHER: NotificationDispatcher | None = None


def build_dispatcher(settings=None) -> NotificationDispatcher:  # noqa: ANN001 - Settings cycle
    """Build the dispatcher from settings; fail fast on unusable configuration."""

    resolved = settings or get_settings()
    secret = resolved.device_encryption_key
    if secret is None or not secret.get_secret_value().strip():
        raise ValueError(
            "MEMORA_DEVICE_ENCRYPTION_KEY is required to decrypt registered device push tokens"
        )
    key = base64.b64decode(secret.get_secret_value(), validate=True)
    if len(key) != 32:
        raise ValueError("MEMORA_DEVICE_ENCRYPTION_KEY must decode to exactly 32 bytes")
    return NotificationDispatcher(provider=build_provider(resolved), token_encryption_key=key)


def get_dispatcher() -> NotificationDispatcher:
    """Process-wide dispatcher, built once from settings on first use."""

    global _DISPATCHER
    if _DISPATCHER is None:
        _DISPATCHER = build_dispatcher()
    return _DISPATCHER


def set_dispatcher(dispatcher: NotificationDispatcher | None) -> None:
    """Override the process dispatcher (tests inject fakes here)."""

    global _DISPATCHER
    _DISPATCHER = dispatcher


_BACKLOG_ENQUEUE_QUERY = text(
    """
    INSERT INTO background_jobs(
        job_type, owner_user_id, resource_type, resource_id, dedupe_key,
        status, attempt_count, max_attempts, available_at, payload
    )
    SELECT
        :job_type,
        NULL,
        'outbox_event',
        e.id,
        :prefix || e.id::text,
        'queued',
        0,
        :max_attempts,
        :now,
        jsonb_build_object(
            'schema_version', CAST(:schema_version AS text),
            'outbox_event_id', e.id
        )
    FROM outbox_events e
    WHERE e.event_type = ANY(CAST(:source_event_types AS text[]))
      AND NOT EXISTS (
          SELECT 1 FROM background_jobs j
          WHERE j.dedupe_key = :prefix || e.id::text
      )
    ON CONFLICT (dedupe_key) DO NOTHING
    RETURNING id
    """
)


def enqueue_notification_backlog(
    connection: Connection,
    *,
    now: datetime,
    job_type: str = JOB_TYPE_NOTIFICATION_SEND,
    source_event_types: tuple[str, ...] = TRIGGER_EVENT_TYPES,
    max_attempts: int = MAX_JOB_ATTEMPTS,
    schema_version: str = ENVELOPE_SCHEMA_VERSION,
) -> int:
    """Enqueue one send job per unseen trigger event (reconcile pass).

    An event whose job already exists is left alone in every state, so a
    dead-lettered poison payload is never resurrected by reconciliation.
    """

    rows = connection.execute(
        _BACKLOG_ENQUEUE_QUERY,
        {
            "job_type": job_type,
            "now": now,
            "max_attempts": max_attempts,
            "schema_version": schema_version,
            "source_event_types": list(source_event_types),
            "prefix": _NOTIFICATIONS_DEDUPE_PREFIX,
        },
    ).fetchall()
    return len(rows)


def _load_trigger_event(
    connection: Connection, outbox_event_id: UUID
) -> tuple[str, dict[str, Any]]:
    row = (
        connection.execute(
            text(
                """
                SELECT event_type, payload
                FROM outbox_events
                WHERE id = :event_id
                """
            ),
            {"event_id": outbox_event_id},
        )
        .mappings()
        .first()
    )
    if row is None:
        raise NonRetryableJobError(CODE_OUTBOX_EVENT_MISSING)
    payload = row["payload"]
    if not isinstance(payload, dict):
        raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD)
    return str(row["event_type"]), payload


def _parse_user_id(envelope: dict[str, Any]) -> UUID:
    try:
        return UUID(str(envelope["user_id"]))
    except (KeyError, TypeError, ValueError) as exc:
        raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD) from exc


def _parse_resource_id(envelope: dict[str, Any], field: str) -> str:
    value = envelope.get(field)
    if value is None:
        raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD)
    return str(value)


def _resolve_due_memories_resource(
    connection: Connection, user_id: UUID, timezone_name: str, now: datetime
) -> str | None:
    """Today's open mission id for the recipient, if one exists."""

    if not timezone_name:
        return None
    try:
        local_day = now.astimezone(ZoneInfo(timezone_name)).date()
    except (ZoneInfoNotFoundError, ValueError):
        return None
    resource = connection.scalar(
        text(
            """
            SELECT id
            FROM missions
            WHERE user_id = :user_id
              AND mission_date = :local_day
              AND status IN ('planned', 'started', 'paused')
            ORDER BY sequence_no
            LIMIT 1
            """
        ),
        {"user_id": user_id, "local_day": local_day},
    )
    return str(resource) if resource is not None else None


def _local_day_text(now: datetime, timezone_name: str) -> str | None:
    if not timezone_name:
        return None
    try:
        return now.astimezone(ZoneInfo(timezone_name)).date().isoformat()
    except (ZoneInfoNotFoundError, ValueError):
        return None


def build_trigger_dedupe_key(
    *,
    category: str,
    user_id: UUID,
    resource_id: str,
    local_day: str | None = None,
) -> str:
    """Stable consume-once key per logical trigger.

    Reminders dedupe per user-local calendar day (one daily-mission or
    due-memories push per day); workflow signals dedupe per resource so a
    retried or duplicated event never pushes twice for the same update.
    """

    if local_day is not None:
        return f"{category}:{user_id}:{local_day}"
    return f"{category}:{user_id}:{resource_id}"


def _build_trigger_payload(
    *,
    category: str,
    resource_id: str,
    now: datetime,
    lock_screen_detail: str,
    envelope: dict[str, Any],
) -> NotificationPayload:
    """Build the outbound payload from envelope-safe facts only."""

    safe_params: dict[str, str | int] = {}
    subject_name = envelope.get("subject_name")
    if isinstance(subject_name, str) and subject_name.strip():
        safe_params["subject_name"] = subject_name
    count = envelope.get("count")
    if isinstance(count, int) and not isinstance(count, bool):
        safe_params["count"] = count

    spec = category_spec(category)
    return build_payload(
        category=category,
        resource_id=resource_id,
        expires_at=now + spec.intent_ttl,
        notification_id=uuid4().hex,
        detail=lock_screen_detail,  # type: ignore[arg-type] - DB CHECK constrains values
        params=safe_params,
    )


def handle_notification_job(
    engine: Engine,
    job: dict[str, Any],
    *,
    now: datetime,
    dispatcher: NotificationDispatcher | None = None,
) -> None:
    """Execute one ``notification.send`` job end to end.

    One transaction: load the trigger event, resolve the recipient context,
    build the payload and dispatch (lock, enforce, send, record).
    """

    resolved = dispatcher or get_dispatcher()
    payload = job.get("payload") or {}
    if not isinstance(payload, dict) or payload.get("schema_version") != ENVELOPE_SCHEMA_VERSION:
        raise NonRetryableJobError("invalid_job_payload")
    try:
        outbox_event_id = UUID(str(payload["outbox_event_id"]))
    except (KeyError, TypeError, ValueError) as exc:
        raise NonRetryableJobError("invalid_job_payload") from exc

    with engine.begin() as connection:
        connection.execute(text(f"SET LOCAL ROLE {WORKER_ROLE}"))
        event_type, envelope = _load_trigger_event(connection, outbox_event_id)

        category = TRIGGER_EVENT_CATEGORIES.get(event_type)
        if category is None:
            raise NonRetryableJobError(CODE_UNKNOWN_TRIGGER)
        if envelope.get("schema_version") != ENVELOPE_SCHEMA_VERSION:
            raise NonRetryableJobError(CODE_INVALID_EVENT_PAYLOAD)
        user_id = _parse_user_id(envelope)

        # Recipient-scoped reads and writes run as the API role with the
        # owner context set, matching the worker convention.
        connection.execute(text("SET LOCAL ROLE memora_api"))
        connection.execute(
            text("SELECT set_config('memora.user_id', :user_id, true)"),
            {"user_id": str(user_id)},
        )
        preferences = load_preferences(connection, user_id)
        timezone_name = preferences.timezone if preferences is not None else ""

        if event_type == EVENT_SCHEDULE_CHANGED:
            mission_id = _resolve_due_memories_resource(connection, user_id, timezone_name, now)
            if preferences is None or mission_id is None:
                record_skip_once(
                    connection,
                    user_id=user_id,
                    notification_id=uuid4().hex,
                    category=category,
                    resource_type="memory_state",
                    resource_id=str(envelope.get("concept_id", "unresolved"))[:64],
                    dedupe_key=build_trigger_dedupe_key(
                        category=category,
                        user_id=user_id,
                        resource_id="",
                        local_day=_local_day_text(now, timezone_name),
                    ),
                    reason=SKIP_RESOURCE_UNAVAILABLE,
                    now=now,
                )
                logger.info(
                    "notification.trigger_skipped category=%s reason=%s event_type=%s",
                    category,
                    SKIP_RESOURCE_UNAVAILABLE,
                    event_type,
                )
                return
            resource_id = mission_id
            lock_screen_detail = preferences.lock_screen_detail
            dedupe_key = build_trigger_dedupe_key(
                category=category,
                user_id=user_id,
                resource_id=resource_id,
                local_day=_local_day_text(now, timezone_name),
            )
        else:
            resource_id = _parse_resource_id(envelope, TRIGGER_RESOURCE_FIELDS[event_type])
            lock_screen_detail = (
                preferences.lock_screen_detail if preferences is not None else "minimal"
            )
            dedupe_key = build_trigger_dedupe_key(
                category=category, user_id=user_id, resource_id=resource_id
            )

        payload_out = _build_trigger_payload(
            category=category,
            resource_id=resource_id,
            now=now,
            lock_screen_detail=lock_screen_detail,
            envelope=envelope,
        )
        return plan_dispatch(
            connection,
            user_id=user_id,
            payload=payload_out,
            dedupe_key=dedupe_key,
            now=now,
            token_encryption_key=resolved.token_encryption_key,
        )


def _send_plan_outside_transaction(
    engine: Engine,
    plan: DispatchPlan,
    resolved: NotificationDispatcher,
    now: datetime,
) -> DeliveryOutcome:
    """External provider calls outside any database transaction.

    The plan transaction already recorded every in-flight row (the send
    index keeps consume-once and crash safety); this phase performs only the
    network calls, and a short second transaction persists the outcomes.
    """

    if not plan.is_send:
        return DeliveryOutcome(
            notification_id=plan.payload.notification_id,
            category=plan.payload.category,
            replayed=plan.replayed,
            skip_reason=plan.skip_reason,
        )

    results: dict[UUID, ProviderResult] = {}
    for send in plan.devices:
        results[send.device_id] = resolved.provider.send(plan.payload, send.push_token)

    with engine.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_api"))
        connection.execute(
            text("SELECT set_config('memora.user_id', :user_id, true)"),
            {"user_id": str(plan.user_id)},
        )
        return complete_dispatch(
            connection,
            plan=plan,
            results=results,
            now=now,
        )


def reconcile_stale_sending(connection: Connection, *, now: datetime) -> int:
    """Resolve crashed in-flight sends (worker reconcile pass)."""

    return _expire_stale_sending(
        connection,
        now=now,
        stale_after=STALE_SENDING_AFTER,
    )
