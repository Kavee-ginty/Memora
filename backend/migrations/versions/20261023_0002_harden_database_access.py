"""Harden database roles and row isolation.

Revision ID: 20261023_0002
Revises: 20261023_0001
"""

from pathlib import Path

from alembic import op

revision = "20261023_0002"
down_revision = "20261023_0001"
branch_labels = None
depends_on = None


def _run_script(name: str) -> None:
    sql = Path(__file__).with_name(name).read_text(encoding="utf-8")
    op.get_bind().connection.driver_connection.execute(sql, prepare=False)


def upgrade() -> None:
    _run_script("20261023_0002_harden_database_access.up.sql")


def downgrade() -> None:
    _run_script("20261023_0002_harden_database_access.down.sql")
