"""Allow the evidence-recorded explanation for stale memory evidence.

Revision ID: 20261030_0008
Revises: 20261029_0007
"""

from pathlib import Path

from alembic import op

revision = "20261030_0008"
down_revision = "20261029_0007"
branch_labels = None
depends_on = None


def _run_script(name: str) -> None:
    sql = Path(__file__).with_name(name).read_text(encoding="utf-8")
    op.get_bind().connection.driver_connection.execute(sql, prepare=False)


def upgrade() -> None:
    _run_script("20261030_0008_evidence_recorded_template.up.sql")


def downgrade() -> None:
    _run_script("20261030_0008_evidence_recorded_template.down.sql")
