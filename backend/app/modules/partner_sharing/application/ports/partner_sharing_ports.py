"""Application ports for the Partner Sharing module."""

from typing import Protocol
from uuid import UUID

from app.modules.partner_sharing.domain.entities import (
    PartnerInvitation,
    PartnerLink,
)


class IPartnerSharingRepository(Protocol):
    """Port for persisting and retrieving partner invitations and links."""

    async def create_invitation(
        self, invitation: PartnerInvitation
    ) -> PartnerInvitation: ...

    async def find_invitation_by_hash(
        self, code_hash: str
    ) -> PartnerInvitation | None: ...

    async def mark_invitation_redeemed(
        self, invitation_id: UUID, redeemed_by: UUID
    ) -> None: ...

    async def create_or_update_link(self, link: PartnerLink) -> PartnerLink: ...

    async def get_link_by_id(self, link_id: UUID) -> PartnerLink | None: ...

    async def get_link_by_owner_and_partner(
        self, owner_user_id: UUID, partner_user_id: UUID
    ) -> PartnerLink | None: ...

    async def list_links_as_owner(self, owner_user_id: UUID) -> list[PartnerLink]: ...

    async def list_links_as_partner(
        self, partner_user_id: UUID
    ) -> list[PartnerLink]: ...
