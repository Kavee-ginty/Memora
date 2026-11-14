"""Durable consumer for T13 mission completion engagement consequences."""

from __future__ import annotations

from datetime import datetime
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, Engine, text

from memora.modules.engagement.constants import ENGAGEMENT_JOB_TYPE, MISSION_COMPLETED_EVENT
from memora.modules.engagement.repository import EngagementRepository
from memora.worker.memory import NonRetryableJobError


def enqueue_engagement_backlog(connection: Connection, *, now: datetime) -> int:
    rows = connection.execute(
        text(
            """
            INSERT INTO background_jobs(
              job_type,owner_user_id,resource_type,resource_id,dedupe_key,status,
              attempt_count,max_attempts,available_at,payload
            )
            SELECT :job_type,NULL,'outbox_event',e.id,
              'engagement:outbox:' || e.id::text,'queued',0,8,:now,
              jsonb_build_object('schema_version','1','outbox_event_id',e.id)
            FROM outbox_events e
            WHERE e.event_type=:event_type
              AND NOT EXISTS (SELECT 1 FROM background_jobs j
                WHERE j.dedupe_key='engagement:outbox:' || e.id::text)
            ON CONFLICT (dedupe_key) DO NOTHING
            RETURNING id
            """
        ),
        {"job_type": ENGAGEMENT_JOB_TYPE, "event_type": MISSION_COMPLETED_EVENT, "now": now},
    ).fetchall()
    return len(rows)


def handle_engagement_job(engine: Engine, job: dict[str, Any], *, now: datetime) -> None:
    payload = job.get("payload")
    try:
        event_id = UUID(str(payload["outbox_event_id"]))
    except (KeyError, TypeError, ValueError) as exc:
        raise NonRetryableJobError("invalid_event_payload") from exc
    with engine.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_worker"))
        event = (
            connection.execute(
                text(
                    """
                SELECT aggregate_type,event_type,payload,correlation_id
                FROM outbox_events WHERE id=:id
                """
                ),
                {"id": event_id},
            )
            .mappings()
            .first()
        )
    if event is None:
        raise NonRetryableJobError("source_event_missing")
    if event["aggregate_type"] != "mission" or event["event_type"] != MISSION_COMPLETED_EVENT:
        raise NonRetryableJobError("invalid_event_type")
    with engine.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_worker"))
        pending_memory = connection.scalar(
            text(
                """
                SELECT count(*) FROM outbox_events attempt_event
                JOIN attempts a ON a.id=attempt_event.aggregate_id
                JOIN mission_items mi ON mi.id=a.mission_item_id
                LEFT JOIN background_jobs j
                  ON j.dedupe_key='memory:outbox:' || attempt_event.id::text
                WHERE mi.mission_id=:mission_id
                  AND attempt_event.event_type='mission.attempt_graded'
                  AND (j.id IS NULL OR j.status <> 'succeeded')
                """
            ),
            {"mission_id": event["payload"]["mission_id"]},
        )
    if pending_memory:
        raise RuntimeError("memory_dependency_pending")
    try:
        EngagementRepository(engine).process_mission_completed(
            outbox_event_id=event_id,
            payload=dict(event["payload"]),
            correlation_id=UUID(str(event["correlation_id"])),
            now=now,
        )
    except ValueError as exc:
        raise NonRetryableJobError(str(exc)) from exc
