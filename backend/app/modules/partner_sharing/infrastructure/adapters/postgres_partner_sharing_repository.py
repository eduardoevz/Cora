"""PostgreSQL/SQLAlchemy implementation of IPartnerSharingRepository."""

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.partner_sharing.domain.entities import (
    PartnerInvitation,
    PartnerLink,
)
from app.modules.partner_sharing.infrastructure.orm.models import (
    PartnerInvitationORM,
    PartnerLinkORM,
)


class PostgresPartnerSharingRepository:
    """SQLAlchemy adapter for partner_invitations and partner_links."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def create_invitation(
        self, invitation: PartnerInvitation
    ) -> PartnerInvitation:
        row = PartnerInvitationORM(
            id=invitation.id,
            owner_user_id=invitation.owner_user_id,
            invitation_code_hash=invitation.invitation_code_hash,
            expires_at=invitation.expires_at,
            is_redeemed=invitation.is_redeemed,
            redeemed_by_user_id=invitation.redeemed_by_user_id,
            created_at=invitation.created_at,
        )
        self._session.add(row)
        await self._session.commit()
        await self._session.refresh(row)
        return row.to_domain()

    async def find_invitation_by_hash(self, code_hash: str) -> PartnerInvitation | None:
        stmt = select(PartnerInvitationORM).where(
            PartnerInvitationORM.invitation_code_hash == code_hash
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return row.to_domain() if row else None

    async def mark_invitation_redeemed(
        self, invitation_id: UUID, redeemed_by: UUID
    ) -> None:
        stmt = select(PartnerInvitationORM).where(
            PartnerInvitationORM.id == invitation_id
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        if row is not None:
            row.is_redeemed = True
            row.redeemed_by_user_id = redeemed_by
            await self._session.commit()

    async def create_or_update_link(self, link: PartnerLink) -> PartnerLink:
        stmt = select(PartnerLinkORM).where(
            PartnerLinkORM.owner_user_id == link.owner_user_id,
            PartnerLinkORM.partner_user_id == link.partner_user_id,
        )
        existing = (await self._session.execute(stmt)).scalar_one_or_none()
        now = datetime.now(UTC)

        if existing is None:
            row = PartnerLinkORM(
                id=link.id,
                owner_user_id=link.owner_user_id,
                partner_user_id=link.partner_user_id,
                status=link.status.value,
                permissions=link.scope.to_dict(),
                created_at=link.created_at,
                updated_at=now,
            )
            self._session.add(row)
        else:
            existing.status = link.status.value
            existing.permissions = link.scope.to_dict()
            existing.updated_at = now
            row = existing

        await self._session.commit()
        await self._session.refresh(row)
        return row.to_domain()

    async def get_link_by_id(self, link_id: UUID) -> PartnerLink | None:
        stmt = select(PartnerLinkORM).where(PartnerLinkORM.id == link_id)
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return row.to_domain() if row else None

    async def get_link_by_owner_and_partner(
        self, owner_user_id: UUID, partner_user_id: UUID
    ) -> PartnerLink | None:
        stmt = select(PartnerLinkORM).where(
            PartnerLinkORM.owner_user_id == owner_user_id,
            PartnerLinkORM.partner_user_id == partner_user_id,
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return row.to_domain() if row else None

    async def list_links_as_owner(self, owner_user_id: UUID) -> list[PartnerLink]:
        stmt = (
            select(PartnerLinkORM)
            .where(PartnerLinkORM.owner_user_id == owner_user_id)
            .order_by(PartnerLinkORM.created_at.desc())
        )
        rows = (await self._session.execute(stmt)).scalars().all()
        return [r.to_domain() for r in rows]

    async def list_links_as_partner(self, partner_user_id: UUID) -> list[PartnerLink]:
        stmt = (
            select(PartnerLinkORM)
            .where(PartnerLinkORM.partner_user_id == partner_user_id)
            .order_by(PartnerLinkORM.created_at.desc())
        )
        rows = (await self._session.execute(stmt)).scalars().all()
        return [r.to_domain() for r in rows]
