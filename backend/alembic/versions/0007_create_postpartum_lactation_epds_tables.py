"""create postpartum lactation epds tables

Revision ID: 0007
Revises: 0006
Create Date: 2026-11-10 14:30:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "0007"
down_revision: str | None = "0006"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    json_type = sa.JSON().with_variant(postgresql.JSONB(), "postgresql")

    # 1. postpartum_recovery_logs
    op.create_table(
        "postpartum_recovery_logs",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column(
            "logged_at",
            sa.DateTime(timezone=True),
            nullable=False,
            index=True,
        ),
        sa.Column("days_postpartum", sa.Integer(), nullable=False),
        sa.Column("lochia_stage", sa.String(32), nullable=False),
        sa.Column("lochia_flow", sa.String(64), nullable=False),
        sa.Column(
            "foul_odor",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column("maternal_temperature_c", sa.Numeric(4, 2), nullable=True),
        sa.Column("perineal_wound_status", sa.String(64), nullable=True),
        sa.Column("cesarean_wound_status", sa.String(64), nullable=True),
        sa.Column(
            "pelvic_floor_symptoms",
            json_type,
            nullable=False,
            server_default=sa.text("'[]'"),
        ),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "alerts",
            json_type,
            nullable=False,
            server_default=sa.text("'[]'"),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    # 2. lactation_sessions
    op.create_table(
        "lactation_sessions",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column(
            "started_at",
            sa.DateTime(timezone=True),
            nullable=False,
            index=True,
        ),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "left_duration_seconds",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("0"),
        ),
        sa.Column(
            "right_duration_seconds",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("0"),
        ),
        sa.Column("last_offered_breast", sa.String(16), nullable=False),
        sa.Column("bottle_volume_ml", sa.Numeric(6, 1), nullable=True),
        sa.Column("feeding_type", sa.String(32), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    # 3. milk_stash_entries
    op.create_table(
        "milk_stash_entries",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column(
            "pumped_at",
            sa.DateTime(timezone=True),
            nullable=False,
            index=True,
        ),
        sa.Column("volume_ml", sa.Numeric(6, 1), nullable=False),
        sa.Column("storage_location", sa.String(32), nullable=False),
        sa.Column(
            "expires_at",
            sa.DateTime(timezone=True),
            nullable=False,
            index=True,
        ),
        sa.Column(
            "is_consumed",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
            index=True,
        ),
        sa.Column("consumed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    # 4. epds_screenings
    op.create_table(
        "epds_screenings",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column(
            "screened_at",
            sa.DateTime(timezone=True),
            nullable=False,
            index=True,
        ),
        sa.Column("days_postpartum", sa.Integer(), nullable=False),
        sa.Column("responses", json_type, nullable=False),
        sa.Column("total_score", sa.Integer(), nullable=False),
        sa.Column("item_10_score", sa.Integer(), nullable=False),
        sa.Column(
            "self_harm_risk",
            sa.Boolean(),
            nullable=False,
            index=True,
        ),
        sa.Column("severity", sa.String(32), nullable=False),
        sa.Column("clinical_summary", sa.Text(), nullable=False),
        sa.Column("action_recommended", sa.Text(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )


def downgrade() -> None:
    op.drop_table("epds_screenings")
    op.drop_table("milk_stash_entries")
    op.drop_table("lactation_sessions")
    op.drop_table("postpartum_recovery_logs")
