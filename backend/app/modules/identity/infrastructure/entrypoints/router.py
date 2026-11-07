from typing import Annotated

from fastapi import APIRouter, Depends, status
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
from app.modules.identity.application.use_cases.complete_onboarding_use_case import (
    CompleteOnboardingUseCase,
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
    SwitchLifeStageRequest,
    UpdateModulePreferencesRequest,
    UserProfileResponse,
)

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
