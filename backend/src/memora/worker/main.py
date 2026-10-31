"""Durable ingestion and memory worker entry point.

The memory loop owns polling and invokes the ingestion worker once per cycle.
Each worker claims only its own job types from the shared durable queue.
"""

import logging

from memora.core.config import get_settings
from memora.worker.ingestion import build_worker
from memora.worker.memory import run_worker


def main() -> None:
    settings = get_settings()
    logging.basicConfig(
        level=settings.log_level,
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )
    ingestion_worker = build_worker(settings)
    run_worker(ingestion_worker.engine, cycle_callback=ingestion_worker.run_once)


if __name__ == "__main__":
    main()
