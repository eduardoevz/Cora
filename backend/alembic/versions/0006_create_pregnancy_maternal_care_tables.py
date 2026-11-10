"""create pregnancy maternal care tables

Revision ID: 0006
Revises: 0005
Create Date: 2026-11-10 13:45:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "0006"
down_revision: str | None = "0005"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # Use JSONB for postgres, JSON for fallback
    json_type = sa.JSON().with_variant(postgresql.JSONB(), "postgresql")

    # 1. pregnancy_episodes
    op.create_table(
        "pregnancy_episodes",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("clinical_edd", sa.Date(), nullable=False),
        sa.Column("last_menstrual_period", sa.Date(), nullable=True),
        sa.Column("ultrasound_edd", sa.Date(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column(
            "started_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "recalibration_history",
            json_type,
            nullable=False,
            server_default="[]",
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index(
        "ix_pregnancy_episodes_user_id_active",
        "pregnancy_episodes",
        ["user_id", "is_active"],
    )

    # 2. maternal_vitals_logs
    op.create_table(
        "maternal_vitals_logs",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "pregnancy_episode_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("pregnancy_episodes.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "measured_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column("gestational_weeks", sa.Integer(), nullable=False),
        sa.Column("systolic_mmhg", sa.Integer(), nullable=True),
        sa.Column("diastolic_mmhg", sa.Integer(), nullable=True),
        sa.Column("glucose_mg_dl", sa.Numeric(precision=5, scale=1), nullable=True),
        sa.Column("glucose_timing", sa.String(length=32), nullable=True),
        sa.Column("weight_kg", sa.Numeric(precision=5, scale=2), nullable=True),
        sa.Column("symptoms", json_type, nullable=False, server_default="[]"),
        sa.Column("alerts", json_type, nullable=False, server_default="[]"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index(
        "ix_maternal_vitals_episode_measured",
        "maternal_vitals_logs",
        ["pregnancy_episode_id", "measured_at"],
    )

    # 3. contraction_sessions
    op.create_table(
        "contraction_sessions",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "pregnancy_episode_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("pregnancy_episodes.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("gestational_weeks", sa.Integer(), nullable=False),
        sa.Column("pattern", sa.String(length=32), nullable=False),
        sa.Column("total_contractions", sa.Integer(), nullable=False),
        sa.Column(
            "avg_interval_seconds",
            sa.Numeric(precision=6, scale=1),
            nullable=True,
        ),
        sa.Column(
            "avg_duration_seconds",
            sa.Numeric(precision=6, scale=1),
            nullable=True,
        ),
        sa.Column("events", json_type, nullable=False, server_default="[]"),
        sa.Column("alert", json_type, nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index(
        "ix_contraction_sessions_episode_started",
        "contraction_sessions",
        ["pregnancy_episode_id", "started_at"],
    )

    # 4. kick_sessions
    op.create_table(
        "kick_sessions",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "pregnancy_episode_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("pregnancy_episodes.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("duration_minutes", sa.Integer(), nullable=False),
        sa.Column("gestational_weeks", sa.Integer(), nullable=False),
        sa.Column("kicks_count", sa.Integer(), nullable=False),
        sa.Column("target_reached", sa.Boolean(), nullable=False),
        sa.Column("target_reached_at_minutes", sa.Integer(), nullable=True),
        sa.Column("is_reassuring", sa.Boolean(), nullable=False),
        sa.Column("alert", json_type, nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index(
        "ix_kick_sessions_episode_started",
        "kick_sessions",
        ["pregnancy_episode_id", "started_at"],
    )

    # 5. birth_plans
    op.create_table(
        "birth_plans",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "pregnancy_episode_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("pregnancy_episodes.id", ondelete="CASCADE"),
            nullable=False,
            unique=True,
        ),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "companion_preferences",
            json_type,
            nullable=False,
            server_default="[]",
        ),
        sa.Column("pain_management", json_type, nullable=False, server_default="[]"),
        sa.Column(
            "delivery_environment",
            json_type,
            nullable=False,
            server_default="[]",
        ),
        sa.Column(
            "immediate_postpartum",
            json_type,
            nullable=False,
            server_default="[]",
        ),
        sa.Column("special_requests", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    # 6. prenatal_appointments
    op.create_table(
        "prenatal_appointments",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "pregnancy_episode_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("pregnancy_episodes.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("scheduled_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("doctor_or_clinic", sa.String(length=255), nullable=False),
        sa.Column("gestational_week", sa.Integer(), nullable=False),
        sa.Column("topics_to_discuss", json_type, nullable=False, server_default="[]"),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "is_completed",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index(
        "ix_prenatal_appointments_episode_scheduled",
        "prenatal_appointments",
        ["pregnancy_episode_id", "scheduled_at"],
    )


def downgrade() -> None:
    op.drop_table("prenatal_appointments")
    op.drop_table("birth_plans")
    op.drop_table("kick_sessions")
    op.drop_table("contraction_sessions")
    op.drop_table("maternal_vitals_logs")
    op.drop_table("pregnancy_episodes")
