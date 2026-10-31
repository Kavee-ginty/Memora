"""Enforce single active privacy request per user and request type.

Revision ID: 20261031_0011
Revises: 20261031_0010
"""

from pathlib import Path

from alembic import op

revision = "20261031_0011"
down_revision = "20261031_0010"
branch_labels = None
depends_on = None


def _run_script(name: str) -> None:
    sql = Path(__file__).with_name(name).read_text(encoding="utf-8")
    op.get_bind().connection.driver_connection.execute(sql, prepare=False)


def upgrade() -> None:
    _run_script("20261031_0011_privacy_active_request_unique.up.sql")


def downgrade() -> None:
    _run_script("20261031_0011_privacy_active_request_unique.down.sql")
