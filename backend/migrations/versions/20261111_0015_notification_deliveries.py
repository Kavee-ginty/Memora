"""Add the append-only notification delivery ledger.

Revision ID: 20261111_0015
Revises: 20261101_0014
"""

from pathlib import Path

from alembic import op

revision = "20261111_0015"
down_revision = "20261101_0014"
branch_labels = None
depends_on = None


def _run_script(name: str) -> None:
    sql = Path(__file__).with_name(name).read_text(encoding="utf-8")
    op.get_bind().connection.driver_connection.execute(sql, prepare=False)


def upgrade() -> None:
    _run_script("20261111_0015_notification_deliveries.up.sql")


def downgrade() -> None:
    _run_script("20261111_0015_notification_deliveries.down.sql")
