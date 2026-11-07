"""create identity tables

Revision ID: 0002
Revises: 0001
Create Date: 2026-11-07 13:30:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

from alembic import op

revision: str = "0002"
down_revision: str | None = "0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    json_col = sa.JSON().with_variant(JSONB, "postgresql")

    op.create_table(
        "user_profiles",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column("firebase_uid", sa.String(length=128), nullable=False),
        sa.Column("first_name", sa.String(length=100), nullable=False),
        sa.Column("last_name", sa.String(length=100), nullable=False),
        sa.Column("current_life_stage", sa.String(length=50), nullable=False),
        sa.Column("birth_year", sa.Integer(), nullable=False),
        sa.Column("primary_intents", json_col, nullable=False),
        sa.Column("hormonal_method", sa.String(length=50), nullable=True),
        sa.Column("diagnosed_conditions", json_col, nullable=False),
        sa.Column(
            "clinical_context_completed", sa.Boolean(), nullable=False, default=False
        ),
        sa.Column("onboarding_completed", sa.Boolean(), nullable=False, default=True),
        sa.Column("enabled_modules", json_col, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(
        "ix_user_profiles_firebase_uid",
        "user_profiles",
        ["firebase_uid"],
        unique=True,
    )

    op.create_table(
        "life_stage_transitions",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_profile_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("from_stage", sa.String(length=50), nullable=False),
        sa.Column("to_stage", sa.String(length=50), nullable=False),
        sa.Column("reason", sa.String(length=50), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(
        "ix_life_stage_transitions_user_profile_id",
        "life_stage_transitions",
        ["user_profile_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_life_stage_transitions_user_profile_id",
        table_name="life_stage_transitions",
    )
    op.drop_table("life_stage_transitions")
    op.drop_index(
        "ix_user_profiles_firebase_uid",
        table_name="user_profiles",
    )
    op.drop_table("user_profiles")
