"""create medical records tables

Revision ID: 0009
Revises: 0008
Create Date: 2026-11-10 20:30:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0009"
down_revision: str | None = "0008"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # 1. medical_exam_records
    op.create_table(
        "medical_exam_records",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column("exam_type", sa.String(50), nullable=False, index=True),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("performed_at", sa.Date(), nullable=False, index=True),
        sa.Column("clinic_or_lab", sa.String(200), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("attachment_file_name", sa.String(255), nullable=True),
        sa.Column("attachment_mime_type", sa.String(100), nullable=True),
        sa.Column("attachment_size_bytes", sa.Integer(), nullable=True),
        sa.Column("attachment_storage_key", sa.String(500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(
        "ix_medical_exam_records_user_performed",
        "medical_exam_records",
        ["user_id", "performed_at"],
    )

    # 2. vaccination_entries
    op.create_table(
        "vaccination_entries",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column("vaccine_type", sa.String(50), nullable=False, index=True),
        sa.Column("dose_number", sa.Integer(), nullable=False),
        sa.Column("administered_at", sa.Date(), nullable=False, index=True),
        sa.Column("lot_number", sa.String(100), nullable=True),
        sa.Column("administrator_clinic", sa.String(200), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(
        "ix_vaccination_entries_user_administered",
        "vaccination_entries",
        ["user_id", "administered_at"],
    )

    # 3. specialist_contacts
    op.create_table(
        "specialist_contacts",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column("full_name", sa.String(150), nullable=False),
        sa.Column("specialty", sa.String(50), nullable=False, index=True),
        sa.Column("clinic_name", sa.String(200), nullable=True),
        sa.Column("phone_number", sa.String(50), nullable=True),
        sa.Column("email", sa.String(150), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("is_favorite", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(
        "ix_specialist_contacts_user_favorite",
        "specialist_contacts",
        ["user_id", "is_favorite"],
    )


def downgrade() -> None:
    op.drop_index("ix_specialist_contacts_user_favorite", table_name="specialist_contacts")
    op.drop_table("specialist_contacts")
    op.drop_index("ix_vaccination_entries_user_administered", table_name="vaccination_entries")
    op.drop_table("vaccination_entries")
    op.drop_index("ix_medical_exam_records_user_performed", table_name="medical_exam_records")
    op.drop_table("medical_exam_records")
