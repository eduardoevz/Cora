from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_async_session
from app.core.errors import EntityNotFoundError
from app.core.security import CurrentUserDep
from app.modules.clinical_tracking.application.dtos.fertility_dtos import (
    LogFertilityDailyDTO,
    UpdatePreconceptionChecklistDTO,
)
from app.modules.clinical_tracking.application.ports.cycle_repository_port import (
    ICycleRepository,
)
from app.modules.clinical_tracking.application.ports.fertility_repository_port import (
    IFertilityRepository,
)
from app.modules.clinical_tracking.application.use_cases.fertility_tracking_use_cases import (  # noqa: E501
    GetFertilityCycleChartUseCase,
    GetPreconceptionChecklistUseCase,
    LogFertilityDailyBiomarkersUseCase,
    UpdatePreconceptionChecklistUseCase,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    PatientCycleContext,
)
from app.modules.clinical_tracking.infrastructure.adapters.postgres_cycle_repository import (  # noqa: E501
    PostgresCycleRepository,
)
from app.modules.clinical_tracking.infrastructure.adapters.postgres_fertility_repository import (  # noqa: E501
    PostgresFertilityRepository,
)
from app.modules.clinical_tracking.infrastructure.entrypoints.fertility_schemas import (
    DailyFertilityLogRequest,
    DailyFertilityLogResponse,
    FertilityCycleChartResponse,
    PreconceptionChecklistResponse,
    UpdatePreconceptionChecklistRequest,
)
from app.modules.identity.domain.models.user_profile import UserProfile
from app.modules.identity.infrastructure.adapters.postgres_user_profile_repository import (  # noqa: E501
    PostgresUserProfileRepository,
)

router = APIRouter(prefix="/fertility", tags=["Fertility & Conception"])


async def get_current_user_profile(
    current_user: CurrentUserDep,
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> UserProfile:
    repo = PostgresUserProfileRepository(session)
    profile = await repo.get_by_firebase_uid(current_user.firebase_uid)
    if profile is None:
        raise EntityNotFoundError(
            entity="UserProfile", identifier=current_user.firebase_uid
        )
    return profile


def get_fertility_repository(
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> IFertilityRepository:
    return PostgresFertilityRepository(session)


def get_cycle_repository(
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> ICycleRepository:
    return PostgresCycleRepository(session)


def _build_patient_context(profile: UserProfile) -> PatientCycleContext:
    from app.modules.identity.domain.value_objects.onboarding_context import (
        DiagnosedCondition,
        HormonalMethod,
    )

    ob_ctx = profile.onboarding_context
    return PatientCycleContext(
        life_stage=profile.current_life_stage,
        hormonal_method=ob_ctx.hormonal_method or HormonalMethod.NONE,
        diagnosed_conditions=(
            list(ob_ctx.diagnosed_conditions)
            if ob_ctx.diagnosed_conditions
            else [DiagnosedCondition.NONE]
        ),
        birth_year=ob_ctx.birth_year,
    )


@router.put(
    "/logs/{log_date}",
    response_model=DailyFertilityLogResponse,
    status_code=status.HTTP_200_OK,
    summary="Log or Update Daily Fertility Biomarkers",
    description=(
        "Records basal body temperature, cervical mucus texture, "
        "urinary LH strip test results, and intercourse/insemination."
    ),
)
async def log_daily_fertility(
    log_date: date,
    request: DailyFertilityLogRequest,
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[IFertilityRepository, Depends(get_fertility_repository)],
) -> DailyFertilityLogResponse:
    use_case = LogFertilityDailyBiomarkersUseCase(repository)
    dto = LogFertilityDailyDTO(
        log_date=log_date,
        bbt_celsius=request.bbt_celsius,
        is_disturbed=request.is_disturbed,
        disturbance_reason=request.disturbance_reason,
        measured_at_time=request.measured_at_time,
        cervical_mucus=request.cervical_mucus,
        lh_result=request.lh_result,
        intercourse_had=request.intercourse_had,
        intercourse_type=request.intercourse_type,
        notes=request.notes,
    )
    result = await use_case.execute(user_id=str(user_profile.id), dto=dto)

    bbt_c = result.bbt.celsius if result.bbt else None
    bbt_f = result.bbt.to_fahrenheit() if result.bbt else None
    is_disturbed = result.bbt.is_disturbed if result.bbt else False
    dist_reason = result.bbt.disturbance_reason if result.bbt else None
    m_time = result.bbt.measured_at_time if result.bbt else None

    return DailyFertilityLogResponse(
        log_date=result.log_date,
        bbt_celsius=bbt_c,
        bbt_fahrenheit=bbt_f,
        is_disturbed=is_disturbed,
        disturbance_reason=dist_reason,
        measured_at_time=m_time,
        cervical_mucus=(result.cervical_mucus.value if result.cervical_mucus else None),
        lh_result=result.lh_result.value if result.lh_result else None,
        intercourse_had=result.intercourse_had,
        intercourse_type=result.intercourse_type.value,
        notes=result.notes,
    )


@router.get(
    "/chart",
    response_model=FertilityCycleChartResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Fertility Cycle Chart and Symptothermal Analysis",
    description=(
        "Retrieves biphasic temperature curve, symptothermal coverline, "
        "ovulation confirmation status, and fertile window prediction."
    ),
)
async def get_fertility_chart(
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    fertility_repo: Annotated[IFertilityRepository, Depends(get_fertility_repository)],
    cycle_repo: Annotated[ICycleRepository, Depends(get_cycle_repository)],
    cycle_id: Annotated[
        str | None,
        Query(description="Cycle ID; defaults to current active cycle"),
    ] = None,
    reference_date: Annotated[
        date | None,
        Query(description="Reference evaluation date; defaults to today"),
    ] = None,
) -> FertilityCycleChartResponse:
    use_case = GetFertilityCycleChartUseCase(
        fertility_repo=fertility_repo, cycle_repo=cycle_repo
    )
    context = _build_patient_context(user_profile)
    result = await use_case.execute(
        user_id=str(user_profile.id),
        patient_context=context,
        cycle_id=cycle_id,
        reference_date=reference_date,
    )
    return FertilityCycleChartResponse.model_validate(result)


@router.get(
    "/preconception-checklist",
    response_model=PreconceptionChecklistResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Preconception Health Recommendations Checklist",
    description=(
        "Retrieves user's preconception checklist, folic acid adherence, "
        "and clinical completion percentage."
    ),
)
async def get_preconception_checklist(
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[IFertilityRepository, Depends(get_fertility_repository)],
) -> PreconceptionChecklistResponse:
    use_case = GetPreconceptionChecklistUseCase(repository)
    result = await use_case.execute(user_id=str(user_profile.id))
    return PreconceptionChecklistResponse.model_validate(result)


@router.patch(
    "/preconception-checklist",
    response_model=PreconceptionChecklistResponse,
    status_code=status.HTTP_200_OK,
    summary="Update Preconception Health Checklist",
    description="Updates adherence to preconception clinical recommendations.",
)
async def update_preconception_checklist(
    request: UpdatePreconceptionChecklistRequest,
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[IFertilityRepository, Depends(get_fertility_repository)],
) -> PreconceptionChecklistResponse:
    use_case = UpdatePreconceptionChecklistUseCase(repository)
    dto = UpdatePreconceptionChecklistDTO(
        taking_folic_acid=request.taking_folic_acid,
        folic_acid_dose_mcg=request.folic_acid_dose_mcg,
        medical_checkup_done=request.medical_checkup_done,
        rubella_immunity_checked=request.rubella_immunity_checked,
        dental_checkup_done=request.dental_checkup_done,
        toxic_habits_stopped=request.toxic_habits_stopped,
        partner_evaluation_planned=request.partner_evaluation_planned,
        active_seeking_months=request.active_seeking_months,
    )
    result = await use_case.execute(user_id=str(user_profile.id), dto=dto)
    return PreconceptionChecklistResponse.model_validate(result)
