import logging

from memora.core.config import get_settings
from memora.worker.ingestion import build_worker


def main() -> None:
    settings = get_settings()
    logging.basicConfig(level=settings.log_level)
    worker = build_worker(settings)
    worker.run_forever()


if __name__ == "__main__":
    main()
