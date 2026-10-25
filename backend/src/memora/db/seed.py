"""Idempotent foundational database seeds for local and deployed environments."""

from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url

from memora.core.config import get_settings

DEFAULT_CONNECT_TIMEOUT_SECONDS = 10
PHYSICS_SUBJECT_ID = "10000000-0000-0000-0000-000000000001"
PHYSICS_CURRICULUM_ID = "20000000-0000-0000-0000-000000000001"

SUBJECT_SEED_SQL = text(
    """
    INSERT INTO subjects(id, code, name, status)
    VALUES (:subject_id, 'physics', 'Physics', 'approved')
    ON CONFLICT (code) DO NOTHING
    """
)
SUBJECT_ID_SQL = text("SELECT id FROM subjects WHERE code = 'physics'")
CURRICULUM_SEED_SQL = text(
    """
    INSERT INTO curriculum_versions(
        id, subject_id, authority, edition_code, language_medium, valid_from, status
    ) VALUES (
        :curriculum_id, :subject_id, 'National Institute of Education, Sri Lanka',
        'GCE-AL-PHYSICS-2017', 'en', DATE '2017-01-01', 'approved'
    ) ON CONFLICT (subject_id, edition_code, language_medium) DO NOTHING
    """
)


def seed_database(database_url: str | None = None) -> None:
    resolved_url = database_url or get_settings().database_url
    connect_args: dict[str, int] = {}
    if make_url(resolved_url).get_backend_name() == "postgresql":
        connect_args["connect_timeout"] = DEFAULT_CONNECT_TIMEOUT_SECONDS
    engine = create_engine(resolved_url, connect_args=connect_args)
    with engine.begin() as connection:
        values = {"subject_id": PHYSICS_SUBJECT_ID, "curriculum_id": PHYSICS_CURRICULUM_ID}
        connection.execute(SUBJECT_SEED_SQL, values)
        values["subject_id"] = connection.scalar(SUBJECT_ID_SQL)
        if values["subject_id"] is None:
            raise RuntimeError("Physics subject seed could not be resolved")
        connection.execute(CURRICULUM_SEED_SQL, values)
    engine.dispose()


if __name__ == "__main__":
    seed_database()
