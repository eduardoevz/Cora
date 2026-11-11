"""SQLAlchemy 2.0 ORM models for partner sharing invitations and links."""

from datetime import UTC, datetime
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import JSON, Boolean, DateTime, ForeignKey, Index, String, Uuid
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.modules.partner_sharing.domain.entities import (
    PartnerInvitation,
    PartnerLink,
    PartnerLinkStatus,
    SharingScopeMask,
)

JSONVariant = JSON().with_variant(JSONB(), "postgresql")


class PartnerInvitationORM(Base):
    """ORM representation of a 24-hour single-use partner invitation code."""

    __tablename__ = "partner_invitations"

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid4
    )
    owner_user_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    invitation_code_hash: Mapped[str] = mapped_column(
        String(64), unique=True, nullable=False, index=True
    )
    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    is_redeemed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    redeemed_by_user_id: Mapped[UUID | None] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("user_profiles.id", ondelete="SET NULL"),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )

    def to_domain(self) -> PartnerInvitation:
        created = self.created_at
        if created.tzinfo is None:
            created = created.replace(tzinfo=UTC)
        expires = self.expires_at
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=UTC)
        return PartnerInvitation(
            id=self.id,
            owner_user_id=self.owner_user_id,
            invitation_code_hash=self.invitation_code_hash,
            expires_at=expires,
            is_redeemed=self.is_redeemed,
            redeemed_by_user_id=self.redeemed_by_user_id,
            created_at=created,
        )


class PartnerLinkORM(Base):
    """ORM representation of a bidirectional partner sharing connection."""

    __tablename__ = "partner_links"

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid4
    )
    owner_user_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    partner_user_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    status: Mapped[str] = mapped_column(
        String(30), nullable=False, default="ACTIVE", index=True
    )
    permissions: Mapped[dict[str, Any]] = mapped_column(
        JSONVariant, nullable=False, default=dict
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )

    __table_args__ = (
        Index(
            "ix_partner_links_owner_partner",
            "owner_user_id",
            "partner_user_id",
            unique=True,
        ),
    )

    def to_domain(self) -> PartnerLink:
        created = self.created_at
        if created.tzinfo is None:
            created = created.replace(tzinfo=UTC)
        updated = self.updated_at
        if updated.tzinfo is None:
            updated = updated.replace(tzinfo=UTC)
        return PartnerLink(
            id=self.id,
            owner_user_id=self.owner_user_id,
            partner_user_id=self.partner_user_id,
            status=PartnerLinkStatus(self.status),
            scope=SharingScopeMask.from_dict(self.permissions),
            created_at=created,
            updated_at=updated,
        )
