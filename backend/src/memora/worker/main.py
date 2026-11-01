"""Durable worker entry point.

Runs the outbox-driven worker loop: polls background jobs (memory events,
privacy export/deletion) and invokes the ingestion worker once per cycle.
Reconciles expired leases and unprocessed producer evidence periodically.
"""

from __future__ import annotations

import logging
import os
import time
from collections.abc import Callable
from datetime import UTC, datetime
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import Engine, text

from memora.core.config import get_settings
from memora.db.runtime import database_engine
from memora.modules.privacy.repository import PrivacyRepository
from memora.worker.ingestion import build_worker
from memora.worker.memory import (
    JOB_TYPE_MEMORY_PROCESS_EVENT,
    OUTCOME_DEAD_LETTERED,
    OUTCOME_IDLE,
    OUTCOME_LEASE_LOST,
    OUTCOME_RETRY_WAIT,
    OUTCOME_SUCCEEDED,
    POLL_SECONDS,
    RECONCILE_SECONDS,
    WORKER_ROLE,
    NonRetryableJobError,
    claim_job,
    complete_job,
    enqueue_outbox_backlog,
    fail_job,
    recover_expired_leases,
)
from memora.worker.memory import (
    handle_job as handle_memory_job,
)

logger = logging.getLogger(__name__)

ALL_JOB_TYPES: tuple[str, ...] = (
    JOB_TYPE_MEMORY_PROCESS_EVENT,
    "privacy.export",
    "privacy.deletion",
)


def _fail_and_sync(
    engine: Engine,
    *,
    job: dict[str, Any],
    lease_owner: str,
    error_code: str,
    retryable: bool,
    now: datetime,
) -> str | None:
    with engine.begin() as connection:
        connection.execute(text(f"SET LOCAL ROLE {WORKER_ROLE}"))
        status = fail_job(
            connection,
            job_id=job["id"],
            lease_owner=lease_owner,
            error_code=error_code,
            retryable=retryable,
            now=now,
        )
        if status == "dead_lettered":
            job_type = job.get("job_type")
            payload = job.get("payload") or {}
            if job_type in ("privacy.export", "privacy.deletion") and "request_id" in payload:
                request_id = UUID(str(payload["request_id"]))
                user_id = UUID(str(payload["user_id"])) if "user_id" in payload else None
                if user_id is not None:
                    connection.execute(text("SET LOCAL ROLE memora_api"))
                    connection.execute(
                        text("SELECT set_config('memora.user_id', :user_id, true)"),
                        {"user_id": str(user_id)},
                    )
                connection.execute(
                    text(
                        """
                        UPDATE privacy_requests
                        SET status = 'failed', failure_code = :error_code,
                            updated_at = :now, row_version = row_version + 1
                        WHERE id = :request_id
                          AND status IN ('requested', 'verifying', 'processing')
                        """
                    ),
                    {"request_id": request_id, "error_code": error_code, "now": now},
                )
                if job_type == "privacy.deletion" and user_id is not None:
                    connection.execute(
                        text(
                            """
                            UPDATE users
                            SET status = 'active', updated_at = :now, row_version = row_version + 1
                            WHERE id = :user_id AND status = 'deletion_pending'
                            """
                        ),
                        {"user_id": user_id, "now": now},
                    )
    return status


def process_next_job(
    engine: Engine,
    *,
    now: datetime,
    lease_owner: str,
    job_types: tuple[str, ...] = ALL_JOB_TYPES,
) -> str:
    """Claims and executes the next available background job."""
    with engine.begin() as connection:
        connection.execute(text(f"SET LOCAL ROLE {WORKER_ROLE}"))
        job = claim_job(connection, job_types=job_types, now=now, lease_owner=lease_owner)
    if job is None:
        return OUTCOME_IDLE

    job_id = job["id"]
    job_type = job["job_type"]
    payload = job.get("payload") or {}

    try:
        if job_type == JOB_TYPE_MEMORY_PROCESS_EVENT:
            handle_memory_job(engine, job, now=now)
        elif job_type == "privacy.export":
            request_id = UUID(str(payload["request_id"]))
            user_id = UUID(str(payload["user_id"]))
            PrivacyRepository(engine).execute_export_job(request_id, user_id)
        elif job_type == "privacy.deletion":
            request_id = UUID(str(payload["request_id"]))
            user_id = UUID(str(payload["user_id"]))
            PrivacyRepository(engine).execute_deletion_job(request_id, user_id)
        else:
            raise NonRetryableJobError("unknown_job_type")

    except NonRetryableJobError as exc:
        logger.warning("Job dead-lettered non-retryable: job_id=%s code=%s", job_id, exc.code)
        status = _fail_and_sync(
            engine,
            job=job,
            lease_owner=lease_owner,
            error_code=exc.code,
            retryable=False,
            now=now,
        )
        return OUTCOME_DEAD_LETTERED if status == "dead_lettered" else OUTCOME_LEASE_LOST

    except Exception as exc:
        logger.exception("Job processing failed: job_id=%s error=%s", job_id, exc)
        status = _fail_and_sync(
            engine,
            job=job,
            lease_owner=lease_owner,
            error_code="execution_failed",
            retryable=True,
            now=now,
        )
        if status is None:
            return OUTCOME_LEASE_LOST
        return OUTCOME_RETRY_WAIT if status == "retry_wait" else OUTCOME_DEAD_LETTERED

    with engine.begin() as connection:
        connection.execute(text(f"SET LOCAL ROLE {WORKER_ROLE}"))
        completed = complete_job(connection, job_id=job_id, lease_owner=lease_owner)
    if not completed:
        logger.info("Job lease lost during completion: job_id=%s", job_id)
        return OUTCOME_LEASE_LOST

    logger.info("Job succeeded: job_id=%s type=%s", job_id, job_type)
    return OUTCOME_SUCCEEDED


def process_one_job(engine: Engine) -> bool:
    """Leases and processes one eligible background job.

    Returns True if a job was found and processed, False otherwise.
    """
    owner = f"worker-once:{os.getpid()}:{uuid4().hex[:8]}"
    outcome = process_next_job(engine, now=datetime.now(UTC), lease_owner=owner)
    return outcome not in (OUTCOME_IDLE, OUTCOME_LEASE_LOST)


def run_worker_once(engine: Engine, limit: int = 100) -> int:
    """Processes up to `limit` available jobs and returns the count processed."""
    processed = 0
    for _ in range(limit):
        if not process_one_job(engine):
            break
        processed += 1
    return processed


def run_worker(
    engine: Engine,
    *,
    poll_seconds: float = POLL_SECONDS,
    reconcile_seconds: float = RECONCILE_SECONDS,
    lease_owner: str | None = None,
    stop_after_cycles: int | None = None,
    cycle_callback: Callable[[], bool] | None = None,
) -> None:
    """Poll for background jobs forever; reconcile leases and backlog periodically."""
    owner = lease_owner or f"memora-worker:{os.getpid()}:{uuid4().hex[:8]}"
    logger.info("Durable worker started: owner=%s", owner)
    last_reconcile = 0.0
    cycles = 0
    while True:
        now = datetime.now(UTC)
        if time.monotonic() - last_reconcile >= reconcile_seconds:
            with engine.begin() as connection:
                connection.execute(text(f"SET LOCAL ROLE {WORKER_ROLE}"))
                recovered = recover_expired_leases(connection, now=now)
                enqueued = enqueue_outbox_backlog(connection, now=now)
                from memora.modules.privacy.repository import (
                    reconcile_expired_export_archives,
                    reconcile_privacy_deletions,
                )

                privacy_reconciled = reconcile_privacy_deletions(connection, now=now)
                exports_expired = reconcile_expired_export_archives(connection, now=now)
            if recovered or enqueued or privacy_reconciled or exports_expired:
                logger.info(
                    "Worker reconcile: recovered=%s enqueued=%s privacy_reconciled=%s "
                    "exports_expired=%s",
                    recovered,
                    enqueued,
                    privacy_reconciled,
                    exports_expired,
                )
            last_reconcile = time.monotonic()

        outcome = process_next_job(engine, now=datetime.now(UTC), lease_owner=owner)
        callback_worked = cycle_callback() if cycle_callback is not None else False
        if outcome == OUTCOME_IDLE and not callback_worked:
            time.sleep(poll_seconds)
        cycles += 1
        if stop_after_cycles is not None and cycles >= stop_after_cycles:
            return


def build_worker_engine() -> Engine:
    settings = get_settings()
    database_url = settings.database_url
    if not database_url:
        raise RuntimeError("MEMORA_DATABASE_URL is required for the worker")
    return database_engine(database_url)


def main() -> None:
    settings = get_settings()
    logging.basicConfig(
        level=settings.log_level,
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )
    ingestion_worker = build_worker(settings)
    run_worker(
        ingestion_worker.engine,
        cycle_callback=ingestion_worker.run_once,
    )


if __name__ == "__main__":
    main()
