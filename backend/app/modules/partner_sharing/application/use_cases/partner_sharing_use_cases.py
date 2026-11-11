"""Application use cases for Partner Sharing."""

import secrets
import string
from datetime import UTC, datetime, timedelta
from uuid import UUID

from app.modules.partner_sharing.application.ports.partner_sharing_ports import (
    IPartnerSharingRepository,
)
from app.modules.partner_sharing.domain.entities import (
    PartnerInvitation,
    PartnerLink,
    PartnerLinkStatus,
    PartnerProjectedView,
    SharingScopeMask,
)
from app.modules.partner_sharing.domain.services.partner_projection_builder import (
    PartnerProjectionBuilder,
    RawPartnerSourceData,
)


class CreatePartnerInvitationUseCase:
    """Generates a high-entropy, 24-hour single-use invitation code."""

    def __init__(self, repository: IPartnerSharingRepository) -> None:
        self._repository = repository

    async def execute(self, owner_user_id: UUID) -> tuple[str, PartnerInvitation]:
        # Generate alfanumeric code (e.g., CORA-7X9P)
        random_suffix = "".join(
            secrets.choice(string.ascii_uppercase + string.digits) for _ in range(6)
        )
        raw_code = f"CORA-{random_suffix}"
        code_hash = PartnerInvitation.hash_code(raw_code)

        now = datetime.now(UTC)
        invitation = PartnerInvitation(
            owner_user_id=owner_user_id,
            invitation_code_hash=code_hash,
            expires_at=now + timedelta(hours=24),
            created_at=now,
        )
        saved = await self._repository.create_invitation(invitation)
        return raw_code, saved


class RedeemPartnerInvitationUseCase:
    """Validates and redeems invitation, rejecting self-linking or expired codes."""

    def __init__(self, repository: IPartnerSharingRepository) -> None:
        self._repository = repository

    async def execute(self, partner_user_id: UUID, raw_code: str) -> PartnerLink:
        code_hash = PartnerInvitation.hash_code(raw_code)
        invitation = await self._repository.find_invitation_by_hash(code_hash)
        if invitation is None:
            raise ValueError("Código de invitación inválido.")

        if invitation.is_expired():
            raise ValueError("El código de invitación ha expirado (límite 24 horas).")

        if invitation.is_redeemed:
            raise ValueError("Este código de invitación ya ha sido canjeado.")

        if invitation.owner_user_id == partner_user_id:
            raise ValueError("No puedes vincularte contigo misma con tu propio código.")

        # Mark redeemed
        await self._repository.mark_invitation_redeemed(
            invitation.id, redeemed_by=partner_user_id
        )

        # Create or reactivate link with minimum privilege (all False)
        link = PartnerLink(
            owner_user_id=invitation.owner_user_id,
            partner_user_id=partner_user_id,
            status=PartnerLinkStatus.ACTIVE,
            scope=SharingScopeMask(),
        )
        return await self._repository.create_or_update_link(link)


class UpdatePartnerPermissionsUseCase:
    """Updates sharing scope mask or pauses/resumes link."""

    def __init__(self, repository: IPartnerSharingRepository) -> None:
        self._repository = repository

    async def execute(
        self,
        owner_user_id: UUID,
        link_id: UUID,
        scope: SharingScopeMask | None = None,
        status: PartnerLinkStatus | None = None,
    ) -> PartnerLink:
        link = await self._repository.get_link_by_id(link_id)
        if link is None or link.owner_user_id != owner_user_id:
            raise ValueError("Vínculo de pareja no encontrado.")

        new_scope = scope if scope is not None else link.scope
        new_status = status if status is not None else link.status

        updated_link = PartnerLink(
            id=link.id,
            owner_user_id=link.owner_user_id,
            partner_user_id=link.partner_user_id,
            status=new_status,
            scope=new_scope,
            created_at=link.created_at,
        )
        return await self._repository.create_or_update_link(updated_link)


class RevokePartnerLinkUseCase:
    """Revokes partner link immediately, preventing any subsequent access."""

    def __init__(self, repository: IPartnerSharingRepository) -> None:
        self._repository = repository

    async def execute(self, owner_user_id: UUID, link_id: UUID) -> PartnerLink:
        link = await self._repository.get_link_by_id(link_id)
        if link is None or link.owner_user_id != owner_user_id:
            raise ValueError("Vínculo de pareja no encontrado.")

        revoked_link = PartnerLink(
            id=link.id,
            owner_user_id=link.owner_user_id,
            partner_user_id=link.partner_user_id,
            status=PartnerLinkStatus.REVOKED,
            scope=link.scope,
            created_at=link.created_at,
        )
        return await self._repository.create_or_update_link(revoked_link)


class GetSharedPartnerViewUseCase:
    """Projects authorized clinical view for partner user."""

    def __init__(
        self,
        repository: IPartnerSharingRepository,
        projection_builder: PartnerProjectionBuilder,
    ) -> None:
        self._repository = repository
        self._projection_builder = projection_builder

    async def execute(
        self, partner_user_id: UUID, source_data_provider: RawPartnerSourceData
    ) -> PartnerProjectedView:
        links = await self._repository.list_links_as_partner(partner_user_id)
        active_links = [
            link for link in links if link.status == PartnerLinkStatus.ACTIVE
        ]
        if not active_links:
            raise PermissionError("No tienes ningún vínculo activo de pareja.")

        active_link = active_links[0]
        return self._projection_builder.build_projection(
            link=active_link, source=source_data_provider
        )
