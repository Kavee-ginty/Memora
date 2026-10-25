from unittest.mock import MagicMock
from uuid import uuid4

from memora.db import seed


def test_seed_uses_existing_physics_subject_identity(monkeypatch) -> None:
    existing_subject_id = uuid4()
    connection = MagicMock()
    connection.scalar.return_value = existing_subject_id
    transaction = MagicMock()
    transaction.__enter__.return_value = connection
    engine = MagicMock()
    engine.begin.return_value = transaction
    monkeypatch.setattr(seed, "create_engine", lambda _url, **_kwargs: engine)

    seed.seed_database("postgresql+psycopg://unused")

    curriculum_values = connection.execute.call_args_list[1].args[1]
    assert curriculum_values["subject_id"] == existing_subject_id
