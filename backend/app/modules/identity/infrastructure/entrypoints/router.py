from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_async_session
from app.core.security import CurrentUserDep
from app.modules.identity.application.dtos.identity_dtos import (
    CompleteOnboardingCommand,
    SwitchLifeStageCommand,
    UpdateModulePreferencesCommand,
)
from app.modules.identity.application.ports.user_profile_repository_port import (
    IUserProfileRepository,
)
from app.modules.identity.application.use_cases import (
    purge_account_irreversibly_use_case as purge_uc,
)
from app.modules.identity.application.use_cases.complete_onboarding_use_case import (
    CompleteOnboardingUseCase,
)
from app.modules.identity.application.use_cases.export_all_user_data_use_case import (
    ExportAllUserDataUseCase,
)
from app.modules.identity.application.use_cases.get_user_profile_use_case import (
    GetUserProfileUseCase,
)
from app.modules.identity.application.use_cases.switch_life_stage_use_case import (
    SwitchLifeStageUseCase,
)
from app.modules.identity.application.use_cases.update_module_preferences_use_case import (  # noqa: E501
    UpdateModulePreferencesUseCase,
)
from app.modules.identity.infrastructure.adapters.postgres_user_profile_repository import (  # noqa: E501
    PostgresUserProfileRepository,
)
from app.modules.identity.infrastructure.entrypoints.schemas import (
    OnboardingRequest,
    PurgeAccountRequest,
    SwitchLifeStageRequest,
    UpdateModulePreferencesRequest,
    UserProfileResponse,
)
from app.modules.medical_records.infrastructure.adapters import (
    cloudflare_r2_storage_adapter as r2_adapter,
)

PurgeAccountIrreversiblyUseCase = purge_uc.PurgeAccountIrreversiblyUseCase
CloudflareR2StorageAdapter = r2_adapter.CloudflareR2StorageAdapter

router = APIRouter(prefix="/identity", tags=["Identity"])


def get_user_profile_repository(
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> IUserProfileRepository:
    return PostgresUserProfileRepository(session)


@router.get(
    "/me",
    response_model=UserProfileResponse,
    summary="Get Current User Profile",
    description=(
        "Returns the calibrated profile, active life stage, and modules "
        "for the authenticated user."
    ),
)
async def get_me(
    current_user: CurrentUserDep,
    repository: Annotated[IUserProfileRepository, Depends(get_user_profile_repository)],
) -> UserProfileResponse:
    use_case = GetUserProfileUseCase(repository=repository)
    profile = await use_case.execute(user=current_user)
    return UserProfileResponse.from_domain(profile)


@router.put(
    "/onboarding",
    response_model=UserProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Complete 3-Layer Onboarding",
    description=(
        "Creates or initialises the user profile with 3-layer progressive "
        "context calibration."
    ),
)
async def complete_onboarding(
    current_user: CurrentUserDep,
    request: OnboardingRequest,
    repository: Annotated[IUserProfileRepository, Depends(get_user_profile_repository)],
) -> UserProfileResponse:
    use_case = CompleteOnboardingUseCase(repository=repository)
    command = CompleteOnboardingCommand(
        first_name=request.first_name,
        last_name=request.last_name,
        current_life_stage=request.current_life_stage,
        birth_year=request.birth_year,
        primary_intents=request.primary_intents,
        hormonal_method=request.hormonal_method,
        diagnosed_conditions=request.diagnosed_conditions,
        clinical_context_completed=request.clinical_context_completed,
    )
    profile = await use_case.execute(user=current_user, command=command)
    return UserProfileResponse.from_domain(profile)


@router.post(
    "/life-stage/transitions",
    response_model=UserProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Transition to a New Biological Life Stage",
    description=(
        "Switches the user's active life stage, recording an immutable "
        "longitudinal transition record."
    ),
)
async def switch_life_stage(
    current_user: CurrentUserDep,
    request: SwitchLifeStageRequest,
    repository: Annotated[IUserProfileRepository, Depends(get_user_profile_repository)],
) -> UserProfileResponse:
    use_case = SwitchLifeStageUseCase(repository=repository)
    command = SwitchLifeStageCommand(
        target_stage=request.target_stage,
        reason=request.reason,
        notes=request.notes,
    )
    profile = await use_case.execute(user=current_user, command=command)
    return UserProfileResponse.from_domain(profile)


@router.patch(
    "/module-preferences",
    response_model=UserProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Update Modular Preferences",
    description=(
        "Adjusts visible and enabled secondary modules for the active profile "
        "(Modularidad a la Carta)."
    ),
)
async def update_module_preferences(
    current_user: CurrentUserDep,
    request: UpdateModulePreferencesRequest,
    repository: Annotated[IUserProfileRepository, Depends(get_user_profile_repository)],
) -> UserProfileResponse:
    use_case = UpdateModulePreferencesUseCase(repository=repository)
    command = UpdateModulePreferencesCommand(
        enabled_modules=request.enabled_modules,
    )
    profile = await use_case.execute(user=current_user, command=command)
    return UserProfileResponse.from_domain(profile)


@router.post(
    "/me/data-export",
    status_code=status.HTTP_200_OK,
    summary="Exportar totalidad de datos personales y de salud (ZIP)",
    responses={
        200: {
            "content": {"application/zip": {}},
            "description": "Archivo ZIP comprimido con los JSONs estructurados.",
        }
    },
)
async def export_my_data(
    current_user: CurrentUserDep,
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> Response:
    profile_repo = PostgresUserProfileRepository(session)
    profile = await profile_repo.get_by_firebase_uid(current_user.firebase_uid)
    if profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Perfil de usuaria no encontrado.",
        )

    use_case = ExportAllUserDataUseCase()
    zip_bytes = await use_case.execute(profile=profile, session=session)
    filename = f"cora_data_export_{profile.id}.zip"
    return Response(
        content=zip_bytes,
        media_type="application/zip",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.delete(
    "/me",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Purga irreversible y eliminación permanente de cuenta (GDPR)",
)
async def purge_my_account(
    payload: PurgeAccountRequest,
    current_user: CurrentUserDep,
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> Response:
    profile_repo = PostgresUserProfileRepository(session)
    profile = await profile_repo.get_by_firebase_uid(current_user.firebase_uid)
    if profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Perfil de usuaria no encontrado.",
        )

    r2_storage = CloudflareR2StorageAdapter()
    use_case = PurgeAccountIrreversiblyUseCase(file_storage=r2_storage)
    try:
        await use_case.execute(
            profile=profile,
            confirm_phrase=payload.confirm_phrase,
            session=session,
        )
        return Response(status_code=status.HTTP_204_NO_CONTENT)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
