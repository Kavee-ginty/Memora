"""Add T13 mission lifecycle guarantees.

Revision ID: 20261101_0014
Revises: 20261101_0013
"""

from pathlib import Path

from alembic import op

revision = "20261101_0014"
down_revision = "20261101_0013"
branch_labels = None
depends_on = None


def _run_script(name: str) -> None:
    sql = Path(__file__).with_name(name).read_text(encoding="utf-8")
    op.get_bind().connection.driver_connection.execute(sql, prepare=False)


def upgrade() -> None:
    _run_script("20261101_0014_mission_backend.up.sql")


def downgrade() -> None:
    _run_script("20261101_0014_mission_backend.down.sql")
