"""Create the MVP PostgreSQL schema.

Revision ID: 20261023_0001
Revises: None
"""

from pathlib import Path

from alembic import op

revision = "20261023_0001"
down_revision = None
branch_labels = None
depends_on = None


def _run_script(name: str) -> None:
    sql = Path(__file__).with_name(name).read_text(encoding="utf-8")
    op.get_bind().connection.driver_connection.execute(sql, prepare=False)


def upgrade() -> None:
    _run_script("20261023_0001_mvp_schema.up.sql")


def downgrade() -> None:
    _run_script("20261023_0001_mvp_schema.down.sql")
