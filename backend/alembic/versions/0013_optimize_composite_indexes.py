"""optimize composite longitudinal indexes across clinical modules

Revision ID: 0013
Revises: 0012
Create Date: 2026-11-10 23:00:00.000000

"""

from collections.abc import Sequence

from alembic import op

revision: str = "0013"
down_revision: str | None = "0012"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_index(
        "ix_treatment_regimens_user_active",
        "treatment_regimens",
        ["user_id", "is_active"],
        if_not_exists=True,
    )
    op.create_index(
        "ix_dose_intake_logs_regimen_scheduled",
        "dose_intake_logs",
        ["regimen_id", "scheduled_for"],
        if_not_exists=True,
    )
    op.create_index(
        "ix_maternal_vitals_user_measured",
        "maternal_vitals_logs",
        ["user_id", "measured_at"],
        if_not_exists=True,
    )
    op.create_index(
        "ix_postpartum_recovery_user_logged",
        "postpartum_recovery_logs",
        ["user_id", "logged_at"],
        if_not_exists=True,
    )
    op.create_index(
        "ix_epds_screenings_user_screened",
        "epds_screenings",
        ["user_id", "screened_at"],
        if_not_exists=True,
    )
    op.create_index(
        "ix_hot_flash_episodes_user_occurred",
        "hot_flash_episodes",
        ["user_id", "occurred_at"],
        if_not_exists=True,
    )
    op.create_index(
        "ix_assistant_conversations_user_updated",
        "assistant_conversations",
        ["user_id", "updated_at"],
        if_not_exists=True,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_assistant_conversations_user_updated",
        table_name="assistant_conversations",
        if_exists=True,
    )
    op.drop_index(
        "ix_hot_flash_episodes_user_occurred",
        table_name="hot_flash_episodes",
        if_exists=True,
    )
    op.drop_index(
        "ix_epds_screenings_user_screened",
        table_name="epds_screenings",
        if_exists=True,
    )
    op.drop_index(
        "ix_postpartum_recovery_user_logged",
        table_name="postpartum_recovery_logs",
        if_exists=True,
    )
    op.drop_index(
        "ix_maternal_vitals_user_measured",
        table_name="maternal_vitals_logs",
        if_exists=True,
    )
    op.drop_index(
        "ix_dose_intake_logs_regimen_scheduled",
        table_name="dose_intake_logs",
        if_exists=True,
    )
    op.drop_index(
        "ix_treatment_regimens_user_active",
        table_name="treatment_regimens",
        if_exists=True,
    )
