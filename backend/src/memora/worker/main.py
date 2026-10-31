"""Durable worker entry point.

Runs the outbox-driven worker loop: poll background jobs (memory events,
privacy export/deletion), reconcile expired leases and unprocessed producer
evidence periodically.
"""

from __future__ import annotations

import logging
from typing import Any
from uuid import UUID

from sqlalchemy import Engine, text

from memora.core.config import get_settings
from memora.db.runtime import database_engine
from memora.modules.privacy.repository import PrivacyRepository
from memora.worker.memory import run_worker

logger = logging.getLogger(__name__)


def process_one_job(engine: Engine) -> bool:
    """Leases and processes one eligible background job.

    Returns True if a job was found and processed, False otherwise.
    """
    repository = PrivacyRepository(engine)
    with engine.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_worker"))
        row = (
            connection.execute(
                text(
                    """
                SELECT id, job_type, resource_id, payload
                FROM background_jobs
                WHERE status IN ('queued', 'retry_wait')
                  AND job_type IN ('privacy.export', 'privacy.deletion')
                  AND available_at <= now()
                ORDER BY available_at ASC
                FOR UPDATE SKIP LOCKED
                LIMIT 1
                """
                )
            )
            .mappings()
            .one_or_none()
        )

        if row is None:
            return False

        job_id = row["id"]
        job_type = row["job_type"]
        payload: dict[str, Any] = row["payload"]

        # Mark leased
        connection.execute(
            text(
                """
                UPDATE background_jobs
                SET status = 'leased', lease_owner = 'memora_worker',
                    lease_expires_at = now() + interval '5 minutes',
                    attempt_count = attempt_count + 1,
                    updated_at = now(), row_version = row_version + 1
                WHERE id = :id
                """
            ),
            {"id": job_id},
        )

    # Process outside the lease transaction
    try:
        if job_type == "privacy.export":
            request_id = UUID(str(payload["request_id"]))
            user_id = UUID(str(payload["user_id"]))
            repository.execute_export_job(request_id, user_id)
        elif job_type == "privacy.deletion":
            request_id = UUID(str(payload["request_id"]))
            user_id = UUID(str(payload["user_id"]))
            repository.execute_deletion_job(request_id, user_id)
        else:
            logger.warning("Unrecognized job type %s", job_type)
            with engine.begin() as connection:
                connection.execute(text("SET LOCAL ROLE memora_worker"))
                connection.execute(
                    text(
                        """
                        UPDATE background_jobs
                        SET status = 'failed', last_error_code = 'unknown_job_type',
                            updated_at = now(), row_version = row_version + 1
                        WHERE id = :id
                        """
                    ),
                    {"id": job_id},
                )
            return True

        with engine.begin() as connection:
            connection.execute(text("SET LOCAL ROLE memora_worker"))
            connection.execute(
                text(
                    """
                    UPDATE background_jobs
                    SET status = 'succeeded', completed_at = now(),
                        updated_at = now(), row_version = row_version + 1
                    WHERE id = :id
                    """
                ),
                {"id": job_id},
            )
    except Exception as exc:
        logger.exception("Error processing background job %s: %s", job_id, exc)
        with engine.begin() as connection:
            connection.execute(text("SET LOCAL ROLE memora_worker"))
            connection.execute(
                text(
                    """
                    UPDATE background_jobs
                    SET status = 'failed', last_error_code = 'execution_failed',
                        updated_at = now(), row_version = row_version + 1
                    WHERE id = :id
                    """
                ),
                {"id": job_id},
            )

    return True


def run_worker_once(engine: Engine, limit: int = 100) -> int:
    """Processes up to `limit` available jobs and returns the count processed."""
    processed = 0
    for _ in range(limit):
        if not process_one_job(engine):
            break
        processed += 1
    return processed


def build_worker_engine() -> Engine:
    settings = get_settings()
    database_url = settings.database_url
    if not database_url:
        raise RuntimeError("MEMORA_DATABASE_URL is required for the worker")
    return database_engine(database_url)


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )
    run_worker(build_worker_engine())


if __name__ == "__main__":
    main()
