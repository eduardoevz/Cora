from dataclasses import replace
from datetime import UTC, date, datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_async_session
from app.core.errors import EntityNotFoundError
from app.core.security import CurrentUserDep
from app.modules.clinical_tracking.application.dtos.cycle_dtos import (
    CycleOverviewDTO,
    LogSymptomDTO,
)
from app.modules.clinical_tracking.application.ports.cycle_repository_port import (
    ICycleRepository,
)
from app.modules.clinical_tracking.application.use_cases.get_cycle_calendar_use_case import (  # noqa: E501
    GetCycleCalendarUseCase,
)
from app.modules.clinical_tracking.application.use_cases.get_cycle_overview_use_case import (  # noqa: E501
    GetCycleOverviewUseCase,
)
from app.modules.clinical_tracking.application.use_cases.log_bleeding_and_symptoms_use_case import (  # noqa: E501
    LogBleedingAndSymptomsUseCase,
)
from app.modules.clinical_tracking.application.use_cases.seed_initial_periods_use_case import (  # noqa: E501
    SeedInitialPeriodsUseCase,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    InitialPeriodRange,
    PatientCycleContext,
)
from app.modules.clinical_tracking.infrastructure.adapters.postgres_cycle_repository import (  # noqa: E501
    PostgresCycleRepository,
)
from app.modules.clinical_tracking.infrastructure.entrypoints.cycle_schemas import (
    CalendarDayProjectionResponse,
    CalendarMonthProjectionResponse,
    ClinicalPatternAlertResponse,
    CycleOverviewResponse,
    CycleStatusResponse,
    CycleSymptomLogResponse,
    LogBleedingAndSymptomsRequest,
    MenstrualCycleResponse,
    SeedInitialPeriodsRequest,
)
from app.modules.identity.domain.models.user_profile import UserProfile
from app.modules.identity.domain.value_objects.onboarding_context import (
    DiagnosedCondition,
    HormonalMethod,
)
from app.modules.identity.infrastructure.adapters.postgres_user_profile_repository import (  # noqa: E501
    PostgresUserProfileRepository,
)

router = APIRouter(prefix="/cycles", tags=["Menstrual Cycles & Symptoms"])


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


def get_cycle_repository(
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> ICycleRepository:
    return PostgresCycleRepository(session)


@router.post(
    "/symptoms",
    response_model=CycleSymptomLogResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Log Bleeding and Cycle Symptoms",
    description=(
        "Records daily menstrual bleeding, somatic symptoms "
        "(pelvic pain, dysmenorrhea), and automatically manages "
        "cycle transitions according to clinical guidelines."
    ),
)
async def log_bleeding_and_symptoms(
    request: LogBleedingAndSymptomsRequest,
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[ICycleRepository, Depends(get_cycle_repository)],
) -> CycleSymptomLogResponse:
    use_case = LogBleedingAndSymptomsUseCase(repository)
    dto = LogSymptomDTO(
        log_date=request.log_date,
        bleeding_flow=request.bleeding_flow,
        pelvic_pain=request.pelvic_pain,
        dysmenorrhea=request.dysmenorrhea,
        dyspareunia=request.dyspareunia,
        acne_severity=request.acne_severity,
        hirsutism=request.hirsutism,
        fatigue_level=request.fatigue_level,
        gi_symptoms=request.gi_symptoms,
        notes=request.notes,
    )
    result = await use_case.execute(user_id=str(user_profile.id), dto=dto)
    return CycleSymptomLogResponse.model_validate(result)


def _build_patient_cycle_context(user_profile: UserProfile) -> PatientCycleContext:
    ob_ctx = user_profile.onboarding_context
    return PatientCycleContext(
        life_stage=user_profile.current_life_stage,
        hormonal_method=ob_ctx.hormonal_method or HormonalMethod.NONE,
        diagnosed_conditions=(
            list(ob_ctx.diagnosed_conditions)
            if ob_ctx.diagnosed_conditions
            else [DiagnosedCondition.NONE]
        ),
        birth_year=ob_ctx.birth_year,
        cycle_regularity=ob_ctx.cycle_regularity,
        typical_cycle_length_days=ob_ctx.typical_cycle_length_days,
        typical_bleeding_duration_days=ob_ctx.typical_bleeding_duration_days,
    )


@router.get(
    "/overview",
    response_model=CycleOverviewResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Cycle Overview, Phase Prediction, and FIGO Alerts",
    description=(
        "Retrieves active cycle status, 4-phase biological prediction, "
        "and preventative FIGO alerts adapted to life stage and conditions."
    ),
)
async def get_cycle_overview(
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[ICycleRepository, Depends(get_cycle_repository)],
    reference_date: Annotated[
        date | None,
        Query(description="Reference date for cycle calculation; defaults to today"),
    ] = None,
) -> CycleOverviewResponse:
    calc_date = reference_date or date.today()
    context = _build_patient_cycle_context(user_profile)

    use_case = GetCycleOverviewUseCase(repository)
    overview: CycleOverviewDTO = await use_case.execute(
        user_id=str(user_profile.id),
        context=context,
        reference_date=calc_date,
    )

    current_resp = (
        MenstrualCycleResponse.model_validate(overview.current_cycle)
        if overview.current_cycle
        else None
    )

    return CycleOverviewResponse(
        current_cycle=current_resp,
        status=CycleStatusResponse(
            current_cycle_id=overview.status.current_cycle_id,
            day_in_cycle=overview.status.day_in_cycle,
            current_phase=overview.status.current_phase,
            predicted_next_period=overview.status.predicted_next_period,
            fertile_window_start=overview.status.fertile_window_start,
            fertile_window_end=overview.status.fertile_window_end,
            ovulation_date=overview.status.ovulation_date,
            is_hormonally_managed=overview.status.is_hormonally_managed,
            has_extended_uncertainty=overview.status.has_extended_uncertainty,
            phase_description_es=overview.status.phase_description_es,
            daily_tip_es=overview.status.daily_tip_es,
        ),
        alerts=[
            ClinicalPatternAlertResponse(
                alert_type=a.alert_type,
                severity=a.severity,
                title_es=a.title_es,
                description_es=a.description_es,
                recommendation_es=a.recommendation_es,
                evidence=a.evidence,
            )
            for a in overview.alerts
        ],
        recent_cycles=[
            MenstrualCycleResponse.model_validate(c) for c in overview.recent_cycles
        ],
    )


@router.post(
    "/initial-periods",
    response_model=list[MenstrualCycleResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Seed Initial Historical Periods & Baseline",
    description=(
        "Seeds up to 2 historical initial periods with daily bleeding logs and "
        "updates the user's baseline regularity and typical cycle duration."
    ),
)
async def seed_initial_periods(
    request: SeedInitialPeriodsRequest,
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[ICycleRepository, Depends(get_cycle_repository)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> list[MenstrualCycleResponse]:
    ranges = [
        InitialPeriodRange(start_date=item.start_date, end_date=item.end_date)
        for item in request.periods
    ]
    use_case = SeedInitialPeriodsUseCase(repository)
    created_cycles = await use_case.execute(
        user_id=str(user_profile.id),
        periods=ranges,
    )

    ordered = sorted(ranges, key=lambda item: item.start_date)
    inferred_cycle_len = (
        (ordered[1].start_date - ordered[0].start_date).days
        if len(ordered) == 2
        else None
    )
    inferred_bleed_len = round(
        sum(item.bleeding_duration_days for item in ordered) / len(ordered)
    )

    new_regularity = (
        request.cycle_regularity or user_profile.onboarding_context.cycle_regularity
    )
    new_cycle_len = (
        request.typical_cycle_length_days
        if request.typical_cycle_length_days is not None
        else (
            inferred_cycle_len
            or user_profile.onboarding_context.typical_cycle_length_days
        )
    )
    new_bleed_len = (
        request.typical_bleeding_duration_days
        if request.typical_bleeding_duration_days is not None
        else (
            inferred_bleed_len
            or user_profile.onboarding_context.typical_bleeding_duration_days
        )
    )
    user_profile.onboarding_context = replace(
        user_profile.onboarding_context,
        cycle_regularity=new_regularity,
        typical_cycle_length_days=new_cycle_len,
        typical_bleeding_duration_days=new_bleed_len,
    )
    user_profile.updated_at = datetime.now(UTC)
    await PostgresUserProfileRepository(session).save(user_profile)

    return [MenstrualCycleResponse.model_validate(c) for c in created_cycles]


@router.get(
    "/calendar",
    response_model=CalendarMonthProjectionResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Projected Monthly Menstrual Calendar",
    description=(
        "Projects each day of a target calendar month with recorded periods, "
        "predicted periods, fertile window, estimated ovulation, symptoms, "
        "and life-stage-adapted educational guidance."
    ),
)
async def get_cycle_calendar(
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[ICycleRepository, Depends(get_cycle_repository)],
    year: Annotated[int, Query(ge=2000, le=2100, description="Calendar year")],
    month: Annotated[int, Query(ge=1, le=12, description="Calendar month (1-12)")],
    reference_date: Annotated[
        date | None,
        Query(description="Reference date for 'today' status; defaults to today"),
    ] = None,
) -> CalendarMonthProjectionResponse:
    calc_date = reference_date or date.today()
    context = _build_patient_cycle_context(user_profile)
    use_case = GetCycleCalendarUseCase(repository)
    projection = await use_case.execute(
        user_id=str(user_profile.id),
        year=year,
        month=month,
        context=context,
        reference_date=calc_date,
    )
    return CalendarMonthProjectionResponse(
        year=projection.year,
        month=projection.month,
        display_mode=projection.display_mode,
        estimated_cycle_length_days=projection.estimated_cycle_length_days,
        estimated_bleeding_duration_days=projection.estimated_bleeding_duration_days,
        is_hormonally_managed=projection.is_hormonally_managed,
        has_extended_uncertainty=projection.has_extended_uncertainty,
        current_cycle_day=projection.current_cycle_day,
        current_phase=projection.current_phase,
        predicted_next_period=projection.predicted_next_period,
        ovulation_date=projection.ovulation_date,
        fertile_window_start=projection.fertile_window_start,
        fertile_window_end=projection.fertile_window_end,
        days=[
            CalendarDayProjectionResponse(
                date=day.date,
                day_in_cycle=day.day_in_cycle,
                phase=day.phase,
                day_marker=day.day_marker,
                fertility_probability=day.fertility_probability,
                has_logged_symptoms=day.has_logged_symptoms,
                bleeding_flow=day.bleeding_flow,
                pelvic_pain=day.pelvic_pain,
                daily_summary_es=day.daily_summary_es,
                phase_education_es=day.phase_education_es,
            )
            for day in projection.days
        ],
    )


@router.get(
    "/history",
    response_model=list[MenstrualCycleResponse],
    status_code=status.HTTP_200_OK,
    summary="List Menstrual Cycle History",
    description="Retrieves chronological history of past and current menstrual cycles.",
)
async def list_cycle_history(
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[ICycleRepository, Depends(get_cycle_repository)],
    limit: Annotated[int, Query(ge=1, le=50, description="Max cycles to return")] = 12,
) -> list[MenstrualCycleResponse]:
    cycles = await repository.list_cycles(user_id=str(user_profile.id), limit=limit)
    return [MenstrualCycleResponse.model_validate(c) for c in cycles]
