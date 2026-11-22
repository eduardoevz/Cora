"""add menstrual baseline columns to user_profiles

Revision ID: 0014
Revises: 0013
Create Date: 2026-11-21 22:42:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0014"
down_revision: str | None = "0013"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "user_profiles",
        sa.Column(
            "cycle_regularity",
            sa.String(length=30),
            nullable=False,
            server_default="unsure",
        ),
    )
    op.add_column(
        "user_profiles",
        sa.Column("typical_cycle_length_days", sa.Integer(), nullable=True),
    )
    op.add_column(
        "user_profiles",
        sa.Column("typical_bleeding_duration_days", sa.Integer(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("user_profiles", "typical_bleeding_duration_days")
    op.drop_column("user_profiles", "typical_cycle_length_days")
    op.drop_column("user_profiles", "cycle_regularity")
