"""FastAPI router for Partner Sharing (/api/v1/partner-sharing)."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_async_session
from app.core.errors import EntityNotFoundError
from app.core.security import CurrentUserDep
from app.modules.identity.domain.models.user_profile import UserProfile
from app.modules.identity.infrastructure.adapters import (
    postgres_user_profile_repository,
)
from app.modules.partner_sharing.application.use_cases import (
    partner_sharing_use_cases as partner_uc,
)
from app.modules.partner_sharing.domain.entities import PartnerLinkStatus
from app.modules.partner_sharing.domain.services.partner_projection_builder import (
    PartnerProjectionBuilder,
    RawPartnerSourceData,
)
from app.modules.partner_sharing.infrastructure.adapters import (
    postgres_partner_sharing_repository as partner_repo_adapter,
)
from app.modules.partner_sharing.infrastructure.entrypoints.schemas import (
    CreateInvitationResponse,
    PartnerLinkResponse,
    PartnerProjectedViewResponse,
    RedeemInvitationRequest,
    UpdatePermissionsRequest,
)

PostgresPartnerSharingRepository = partner_repo_adapter.PostgresPartnerSharingRepository
CreatePartnerInvitationUseCase = partner_uc.CreatePartnerInvitationUseCase
RedeemPartnerInvitationUseCase = partner_uc.RedeemPartnerInvitationUseCase
UpdatePartnerPermissionsUseCase = partner_uc.UpdatePartnerPermissionsUseCase
RevokePartnerLinkUseCase = partner_uc.RevokePartnerLinkUseCase
router = APIRouter(prefix="/partner-sharing", tags=["Partner Sharing"])


async def get_current_user_profile(
    current_user: CurrentUserDep,
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> UserProfile:
    repo = postgres_user_profile_repository.PostgresUserProfileRepository(session)
    profile = await repo.get_by_firebase_uid(current_user.firebase_uid)
    if profile is None:
        raise EntityNotFoundError("UserProfile", current_user.firebase_uid)
    return profile


@router.post(
    "/invitations",
    response_model=CreateInvitationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Generar código de invitación temporal para la pareja (24h)",
)
async def create_partner_invitation(
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> CreateInvitationResponse:
    repo = PostgresPartnerSharingRepository(session)
    use_case = CreatePartnerInvitationUseCase(repo)
    raw_code, inv = await use_case.execute(owner_user_id=profile.id)
    return CreateInvitationResponse.from_domain(raw_code, inv)


@router.post(
    "/invitations/redeem",
    response_model=PartnerLinkResponse,
    status_code=status.HTTP_200_OK,
    summary="Canjear código de invitación recibido de la pareja",
)
async def redeem_partner_invitation(
    payload: RedeemInvitationRequest,
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> PartnerLinkResponse:
    repo = PostgresPartnerSharingRepository(session)
    use_case = RedeemPartnerInvitationUseCase(repo)
    try:
        link = await use_case.execute(
            partner_user_id=profile.id, raw_code=payload.invitation_code
        )
        return PartnerLinkResponse.from_domain(link)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)
        ) from exc


@router.get(
    "/links",
    response_model=list[PartnerLinkResponse],
    summary="Listar vínculos de pareja compartidos por la usuaria",
)
async def list_my_partner_links(
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> list[PartnerLinkResponse]:
    repo = PostgresPartnerSharingRepository(session)
    links = await repo.list_links_as_owner(profile.id)
    return [PartnerLinkResponse.from_domain(link) for link in links]


@router.patch(
    "/links/{link_id}/permissions",
    response_model=PartnerLinkResponse,
    summary="Modificar permisos de visualización compartida",
)
async def update_partner_permissions(
    link_id: UUID,
    payload: UpdatePermissionsRequest,
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> PartnerLinkResponse:
    repo = PostgresPartnerSharingRepository(session)
    use_case = UpdatePartnerPermissionsUseCase(repo)
    scope = payload.permissions.to_domain() if payload.permissions else None
    status_enum = PartnerLinkStatus(payload.status) if payload.status else None
    try:
        updated = await use_case.execute(
            owner_user_id=profile.id,
            link_id=link_id,
            scope=scope,
            status=status_enum,
        )
        return PartnerLinkResponse.from_domain(updated)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)
        ) from exc


@router.delete(
    "/links/{link_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Revocar vínculo de pareja de forma inmediata",
)
async def revoke_partner_link(
    link_id: UUID,
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> Response:
    repo = PostgresPartnerSharingRepository(session)
    use_case = RevokePartnerLinkUseCase(repo)
    try:
        await use_case.execute(owner_user_id=profile.id, link_id=link_id)
        return Response(status_code=status.HTTP_204_NO_CONTENT)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)
        ) from exc


@router.get(
    "/shared-with-me",
    response_model=PartnerProjectedViewResponse,
    summary="Ver información compartida por la pareja (Modo Acompañante)",
)
async def get_shared_partner_view(
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> PartnerProjectedViewResponse:
    repo = PostgresPartnerSharingRepository(session)
    links = await repo.list_links_as_partner(profile.id)
    active_links = [link for link in links if link.status == PartnerLinkStatus.ACTIVE]
    if not active_links:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No tienes ningún vínculo activo de pareja.",
        )

    active_link = active_links[0]
    owner_repo = postgres_user_profile_repository.PostgresUserProfileRepository(session)
    owner_profile = await owner_repo.get_by_id(active_link.owner_user_id)
    if owner_profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Perfil de la titular no encontrado.",
        )

    # In production, query respective modules; provide clean projected raw source
    source = RawPartnerSourceData(
        owner_first_name=owner_profile.first_name,
        current_life_stage=owner_profile.current_life_stage.value,
        fertility_window_summary="Ventana fértil estimada próxima semana.",
        pregnancy_week=20,
        fetal_milestone="El bebé tiene el tamaño de un mango.",
        recent_mood_summary="Bienestar general y energía moderada.",
        support_tips=[
            "Pregúntale cómo se siente hoy y ayúdala con las tareas del hogar."
        ],
    )
    use_case = GetSharedPartnerViewUseCase(repo, PartnerProjectionBuilder())
    try:
        proj = await use_case.execute(profile.id, source)
        return PartnerProjectedViewResponse.from_domain(proj)
    except PermissionError as exc:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail=str(exc)
        ) from exc
