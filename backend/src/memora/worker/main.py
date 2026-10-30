"""Durable worker entry point (T11 memory consumer).

Runs the outbox-driven memory worker loop: poll ``memory.process_event``
jobs, reconcile expired leases and unprocessed producer evidence
periodically. Ingestion job consumers are introduced by their owning task
(T09) on this same entry point.
"""

import logging

from sqlalchemy import Engine

from memora.core.config import get_settings
from memora.db.runtime import database_engine
from memora.worker.memory import run_worker


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
