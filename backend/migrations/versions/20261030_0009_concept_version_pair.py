"""Pin a learner-concept state's active version to its own concept.

Revision ID: 20261030_0009
Revises: 20261030_0008
"""

from pathlib import Path

from alembic import op

revision = "20261030_0009"
down_revision = "20261030_0008"
branch_labels = None
depends_on = None


def _run_script(name: str) -> None:
    sql = Path(__file__).with_name(name).read_text(encoding="utf-8")
    op.get_bind().connection.driver_connection.execute(sql, prepare=False)


def upgrade() -> None:
    _run_script("20261030_0009_concept_version_pair.up.sql")


def downgrade() -> None:
    _run_script("20261030_0009_concept_version_pair.down.sql")
