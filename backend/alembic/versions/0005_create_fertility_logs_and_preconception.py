"""create fertility logs and preconception checklist tables

Revision ID: 0005
Revises: 0004
Create Date: 2026-11-09 07:30:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0005"
down_revision: str | None = "0004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # 1. daily_fertility_logs
    op.create_table(
        "daily_fertility_logs",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("log_date", sa.Date(), nullable=False),
        sa.Column("bbt_celsius", sa.Numeric(precision=4, scale=2), nullable=True),
        sa.Column(
            "is_disturbed", sa.Boolean(), nullable=False, server_default=sa.false()
        ),
        sa.Column("disturbance_reason", sa.String(length=128), nullable=True),
        sa.Column("measured_at_time", sa.Time(), nullable=True),
        sa.Column("cervical_mucus", sa.String(length=32), nullable=True),
        sa.Column("lh_result", sa.String(length=32), nullable=True),
        sa.Column(
            "intercourse_had", sa.Boolean(), nullable=False, server_default=sa.false()
        ),
        sa.Column(
            "intercourse_type",
            sa.String(length=32),
            nullable=False,
            server_default="none",
        ),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint(
            "user_id", "log_date", name="uq_daily_fertility_logs_user_date"
        ),
    )
    op.create_index(
        "ix_daily_fertility_logs_user_id",
        "daily_fertility_logs",
        ["user_id"],
        unique=False,
    )
    op.create_index(
        "ix_daily_fertility_logs_log_date",
        "daily_fertility_logs",
        ["log_date"],
        unique=False,
    )

    # 2. preconception_checklists
    op.create_table(
        "preconception_checklists",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
            unique=True,
        ),
        sa.Column(
            "taking_folic_acid",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
        sa.Column(
            "folic_acid_dose_mcg",
            sa.Integer(),
            nullable=True,
            server_default=sa.text("400"),
        ),
        sa.Column(
            "medical_checkup_done",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
        sa.Column(
            "rubella_immunity_checked",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
        sa.Column(
            "dental_checkup_done",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
        sa.Column(
            "toxic_habits_stopped",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
        sa.Column(
            "partner_evaluation_planned",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
        sa.Column(
            "active_seeking_months",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("0"),
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(
        "ix_preconception_checklists_user_id",
        "preconception_checklists",
        ["user_id"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_preconception_checklists_user_id",
        table_name="preconception_checklists",
    )
    op.drop_table("preconception_checklists")

    op.drop_index(
        "ix_daily_fertility_logs_log_date",
        table_name="daily_fertility_logs",
    )
    op.drop_index(
        "ix_daily_fertility_logs_user_id",
        table_name="daily_fertility_logs",
    )
    op.drop_table("daily_fertility_logs")
