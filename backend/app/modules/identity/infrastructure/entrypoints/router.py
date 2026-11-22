from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_async_session
from app.core.security import CurrentUserDep
from app.modules.clinical_tracking.application.use_cases.seed_initial_periods_use_case import (  # noqa: E501
    SeedInitialPeriodsUseCase,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    InitialPeriodRange,
)
from app.modules.clinical_tracking.infrastructure.adapters.postgres_cycle_repository import (  # noqa: E501
    PostgresCycleRepository,
)
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
from app.modules.identity.domain.value_objects.life_stage import LifeStage
from app.modules.identity.domain.value_objects.onboarding_context import (
    CycleRegularity,
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
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> UserProfileResponse:
    ordered_ranges: list[InitialPeriodRange] = []
    if request.initial_periods:
        raw_ranges = [
            InitialPeriodRange(start_date=p.start_date, end_date=p.end_date)
            for p in request.initial_periods
        ]
        ordered_ranges = SeedInitialPeriodsUseCase.validate_periods(raw_ranges)

    non_menstrual_stages = {
        LifeStage.PREGNANCY,
        LifeStage.POSTPARTUM,
        LifeStage.SENIOR_VITALITY,
    }
    regularity = request.cycle_regularity
    if (
        request.current_life_stage in non_menstrual_stages
        and regularity == CycleRegularity.UNSURE
        and not ordered_ranges
    ):
        regularity = CycleRegularity.NOT_APPLICABLE

    cycle_length_days = request.typical_cycle_length_days
    if cycle_length_days is None and len(ordered_ranges) == 2:
        cycle_length_days = (
            ordered_ranges[1].start_date - ordered_ranges[0].start_date
        ).days

    bleeding_duration_days = request.typical_bleeding_duration_days
    if bleeding_duration_days is None and ordered_ranges:
        bleeding_duration_days = round(
            sum(r.bleeding_duration_days for r in ordered_ranges) / len(ordered_ranges)
        )

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
        cycle_regularity=regularity,
        typical_cycle_length_days=cycle_length_days,
        typical_bleeding_duration_days=bleeding_duration_days,
    )
    profile = await use_case.execute(user=current_user, command=command)

    if ordered_ranges:
        seed_use_case = SeedInitialPeriodsUseCase(PostgresCycleRepository(session))
        await seed_use_case.execute(user_id=str(profile.id), periods=ordered_ranges)

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
