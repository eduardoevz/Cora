"""create menstrual cycles and symptoms tables

Revision ID: 0004
Revises: 0003
Create Date: 2026-11-09 05:00:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

from alembic import op

revision: str = "0004"
down_revision: str | None = "0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    json_col = sa.JSON().with_variant(JSONB, "postgresql")

    # 1. menstrual_cycles
    op.create_table(
        "menstrual_cycles",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("start_date", sa.Date(), nullable=False),
        sa.Column("end_date", sa.Date(), nullable=True),
        sa.Column("cycle_length_days", sa.Integer(), nullable=True),
        sa.Column("bleeding_duration_days", sa.Integer(), nullable=True),
        sa.Column("is_current", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint(
            "user_id", "start_date", name="uq_menstrual_cycles_user_start_date"
        ),
    )
    op.create_index(
        "ix_menstrual_cycles_user_id",
        "menstrual_cycles",
        ["user_id"],
        unique=False,
    )
    op.create_index(
        "ix_menstrual_cycles_start_date",
        "menstrual_cycles",
        ["start_date"],
        unique=False,
    )

    # 2. cycle_symptom_logs
    op.create_table(
        "cycle_symptom_logs",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "cycle_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("menstrual_cycles.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("log_date", sa.Date(), nullable=False),
        sa.Column(
            "bleeding_flow",
            sa.String(length=32),
            nullable=False,
            server_default="none",
        ),
        sa.Column("pelvic_pain", sa.SmallInteger(), nullable=True),
        sa.Column("dysmenorrhea", sa.SmallInteger(), nullable=True),
        sa.Column("dyspareunia", sa.Boolean(), nullable=True),
        sa.Column("acne_severity", sa.SmallInteger(), nullable=True),
        sa.Column("hirsutism", sa.Boolean(), nullable=True),
        sa.Column("fatigue_level", sa.SmallInteger(), nullable=True),
        sa.Column("gi_symptoms", json_col, nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint(
            "user_id", "log_date", name="uq_cycle_symptom_logs_user_date"
        ),
    )
    op.create_index(
        "ix_cycle_symptom_logs_user_id",
        "cycle_symptom_logs",
        ["user_id"],
        unique=False,
    )
    op.create_index(
        "ix_cycle_symptom_logs_cycle_id",
        "cycle_symptom_logs",
        ["cycle_id"],
        unique=False,
    )
    op.create_index(
        "ix_cycle_symptom_logs_log_date",
        "cycle_symptom_logs",
        ["log_date"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_cycle_symptom_logs_log_date", table_name="cycle_symptom_logs")
    op.drop_index("ix_cycle_symptom_logs_cycle_id", table_name="cycle_symptom_logs")
    op.drop_index("ix_cycle_symptom_logs_user_id", table_name="cycle_symptom_logs")
    op.drop_table("cycle_symptom_logs")

    op.drop_index("ix_menstrual_cycles_start_date", table_name="menstrual_cycles")
    op.drop_index("ix_menstrual_cycles_user_id", table_name="menstrual_cycles")
    op.drop_table("menstrual_cycles")
