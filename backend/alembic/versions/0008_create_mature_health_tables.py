"""create mature health tables

Revision ID: 0008
Revises: 0007
Create Date: 2026-11-10 16:00:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "0008"
down_revision: str | None = "0007"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    json_type = sa.JSON().with_variant(postgresql.JSONB(), "postgresql")

    # 1. hot_flash_episodes
    op.create_table(
        "hot_flash_episodes",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column(
            "occurred_at",
            sa.DateTime(timezone=True),
            nullable=False,
            index=True,
        ),
        sa.Column("severity", sa.Integer(), nullable=False),
        sa.Column("flash_type", sa.String(32), nullable=False),
        sa.Column("duration_minutes", sa.Integer(), nullable=False),
        sa.Column(
            "triggers",
            json_type,
            nullable=False,
            server_default=sa.text("'[]'::jsonb"),
        ),
        sa.Column(
            "sleep_disruption_level",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("0"),
        ),
        sa.Column(
            "associated_with_hrt",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    # 2. cardiometabolic_panels
    op.create_table(
        "cardiometabolic_panels",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column("measurement_date", sa.Date(), nullable=False, index=True),
        sa.Column("systolic_bp", sa.Integer(), nullable=True),
        sa.Column("diastolic_bp", sa.Integer(), nullable=True),
        sa.Column("total_cholesterol_mg_dl", sa.Float(), nullable=True),
        sa.Column("ldl_cholesterol_mg_dl", sa.Float(), nullable=True),
        sa.Column("hdl_cholesterol_mg_dl", sa.Float(), nullable=True),
        sa.Column("triglycerides_mg_dl", sa.Float(), nullable=True),
        sa.Column("fasting_glucose_mg_dl", sa.Float(), nullable=True),
        sa.Column(
            "risk_level",
            sa.String(32),
            nullable=False,
            server_default="OPTIMAL",
        ),
        sa.Column(
            "flagged_parameters",
            json_type,
            nullable=False,
            server_default=sa.text("'[]'::jsonb"),
        ),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    # 3. vaginal_bleeding_observations
    op.create_table(
        "vaginal_bleeding_observations",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column("observation_date", sa.Date(), nullable=False, index=True),
        sa.Column("days_of_prior_amenorrhea", sa.Integer(), nullable=False),
        sa.Column(
            "flow_intensity",
            sa.String(32),
            nullable=False,
            server_default="LIGHT",
        ),
        sa.Column(
            "has_cramping",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column(
            "is_postmenopausal_alert_triggered",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    # 4. dexa_bone_results
    op.create_table(
        "dexa_bone_results",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column("scan_date", sa.Date(), nullable=False, index=True),
        sa.Column("anatomical_site", sa.String(32), nullable=False),
        sa.Column("t_score", sa.Float(), nullable=False),
        sa.Column("z_score", sa.Float(), nullable=True),
        sa.Column("bmd_g_cm2", sa.Float(), nullable=True),
        sa.Column(
            "previous_fragility_fracture",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column("category", sa.String(32), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    # 5. fall_risk_assessments
    op.create_table(
        "fall_risk_assessments",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column("assessment_date", sa.Date(), nullable=False, index=True),
        sa.Column("falls_past_year", sa.Integer(), nullable=False),
        sa.Column(
            "has_gait_unsteadiness",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column(
            "uses_walking_aid",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column("timed_up_and_go_seconds", sa.Float(), nullable=True),
        sa.Column("risk_level", sa.String(32), nullable=False),
        sa.Column(
            "composite_score",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("0"),
        ),
        sa.Column(
            "environmental_hazards",
            json_type,
            nullable=False,
            server_default=sa.text("'[]'::jsonb"),
        ),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    # 6. continence_and_pelvic_logs
    op.create_table(
        "continence_and_pelvic_logs",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column("log_date", sa.Date(), nullable=False, index=True),
        sa.Column("incontinence_type", sa.String(32), nullable=False),
        sa.Column(
            "daily_pad_count",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("0"),
        ),
        sa.Column(
            "has_pelvic_heaviness",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column(
            "vaginal_dryness_level",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("0"),
        ),
        sa.Column(
            "has_dyspareunia",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    # 7. trusted_support_contacts
    op.create_table(
        "trusted_support_contacts",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column("contact_name", sa.String(128), nullable=False),
        sa.Column("relationship", sa.String(64), nullable=False),
        sa.Column("phone_number", sa.String(32), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "is_primary",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )


def downgrade() -> None:
    op.drop_table("trusted_support_contacts")
    op.drop_table("continence_and_pelvic_logs")
    op.drop_table("fall_risk_assessments")
    op.drop_table("dexa_bone_results")
    op.drop_table("vaginal_bleeding_observations")
    op.drop_table("cardiometabolic_panels")
    op.drop_table("hot_flash_episodes")
