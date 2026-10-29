"""Finalize profile and notification preference constraints.

Revision ID: 20261029_0006
Revises: 20261023_0005
"""

from pathlib import Path

from alembic import op

revision = "20261029_0006"
down_revision = "20261023_0005"
branch_labels = None
depends_on = None


def _run_script(name: str) -> None:
    sql = Path(__file__).with_name(name).read_text(encoding="utf-8")
    op.get_bind().connection.driver_connection.execute(sql, prepare=False)


def upgrade() -> None:
    _run_script("20261029_0006_profile_preferences.up.sql")


def downgrade() -> None:
    _run_script("20261029_0006_profile_preferences.down.sql")
