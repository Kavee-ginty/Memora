import logging


def main() -> None:
    """Worker placeholder; queue consumers are introduced by their owning tasks."""
    logging.basicConfig(level=logging.INFO)
    logging.getLogger(__name__).info("No worker jobs are registered in the T01 baseline.")


if __name__ == "__main__":
    main()
