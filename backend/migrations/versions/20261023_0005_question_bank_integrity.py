"""Protect question-bank history and historical-read authorization.

Revision ID: 20261023_0005
Revises: 20261023_0004
"""

from pathlib import Path

from alembic import op

revision = "20261023_0005"
down_revision = "20261023_0004"
branch_labels = None
depends_on = None


def _run_script(name: str) -> None:
    sql = Path(__file__).with_name(name).read_text(encoding="utf-8")
    op.get_bind().connection.driver_connection.execute(sql, prepare=False)


def upgrade() -> None:
    _run_script("20261023_0005_question_bank_integrity.up.sql")


def downgrade() -> None:
    _run_script("20261023_0005_question_bank_integrity.down.sql")
