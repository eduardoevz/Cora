"""create wellness and treatments tables

Revision ID: 0003
Revises: 0002
Create Date: 2026-11-07 14:00:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

from alembic import op

revision: str = "0003"
down_revision: str | None = "0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    json_col = sa.JSON().with_variant(JSONB, "postgresql")

    # 1. daily_wellness_logs
    op.create_table(
        "daily_wellness_logs",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("log_date", sa.Date(), nullable=False),
        sa.Column("sleep_hours", sa.Float(), nullable=True),
        sa.Column("sleep_quality", sa.Integer(), nullable=True),
        sa.Column("energy_level", sa.Integer(), nullable=True),
        sa.Column("hydration_ml", sa.Integer(), nullable=True),
        sa.Column("exercise_minutes", sa.Integer(), nullable=True),
        sa.Column("mood_tags", json_col, nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint(
            "user_id", "log_date", name="uq_daily_wellness_logs_user_date"
        ),
    )
    op.create_index(
        "ix_daily_wellness_logs_user_id",
        "daily_wellness_logs",
        ["user_id"],
        unique=False,
    )
    op.create_index(
        "ix_daily_wellness_logs_log_date",
        "daily_wellness_logs",
        ["log_date"],
        unique=False,
    )

    # 2. treatment_regimens
    op.create_table(
        "treatment_regimens",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("category", sa.String(length=50), nullable=False),
        sa.Column("dosage", sa.String(length=100), nullable=False),
        sa.Column("schedule_type", sa.String(length=50), nullable=False),
        sa.Column("scheduled_time", sa.String(length=10), nullable=False),
        sa.Column("active_days", sa.Integer(), nullable=True),
        sa.Column("break_days", sa.Integer(), nullable=True),
        sa.Column("interval_days", sa.Integer(), nullable=True),
        sa.Column("replacement_date", sa.Date(), nullable=True),
        sa.Column("instructions", sa.Text(), nullable=True),
        sa.Column("start_date", sa.Date(), nullable=False),
        sa.Column("end_date", sa.Date(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, default=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(
        "ix_treatment_regimens_user_id",
        "treatment_regimens",
        ["user_id"],
        unique=False,
    )

    # 3. dose_intake_logs
    op.create_table(
        "dose_intake_logs",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "regimen_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("treatment_regimens.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("scheduled_for", sa.DateTime(timezone=True), nullable=False),
        sa.Column("taken_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("client_mutation_id", sa.Uuid(as_uuid=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(
        "ix_dose_intake_logs_regimen_id",
        "dose_intake_logs",
        ["regimen_id"],
        unique=False,
    )
    op.create_index(
        "ix_dose_intake_logs_scheduled_for",
        "dose_intake_logs",
        ["scheduled_for"],
        unique=False,
    )
    op.create_index(
        "ix_dose_intake_logs_client_mutation_id",
        "dose_intake_logs",
        ["client_mutation_id"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_dose_intake_logs_client_mutation_id",
        table_name="dose_intake_logs",
    )
    op.drop_index("ix_dose_intake_logs_scheduled_for", table_name="dose_intake_logs")
    op.drop_index("ix_dose_intake_logs_regimen_id", table_name="dose_intake_logs")
    op.drop_table("dose_intake_logs")

    op.drop_index("ix_treatment_regimens_user_id", table_name="treatment_regimens")
    op.drop_table("treatment_regimens")

    op.drop_index(
        "ix_daily_wellness_logs_log_date",
        table_name="daily_wellness_logs",
    )
    op.drop_index("ix_daily_wellness_logs_user_id", table_name="daily_wellness_logs")
    op.drop_table("daily_wellness_logs")
