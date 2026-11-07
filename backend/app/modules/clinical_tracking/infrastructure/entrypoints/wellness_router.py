from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_async_session
from app.core.errors import EntityNotFoundError
from app.core.security import CurrentUserDep
from app.modules.clinical_tracking.application.dtos.wellness_dtos import (
    UpsertWellnessDTO,
)
from app.modules.clinical_tracking.application.ports.wellness_repository_port import (
    IWellnessRepository,
)
from app.modules.clinical_tracking.application.use_cases.upsert_daily_wellness_use_case import (  # noqa: E501
    UpsertDailyWellnessUseCase,
)
from app.modules.clinical_tracking.infrastructure.adapters.postgres_wellness_repository import (  # noqa: E501
    PostgresWellnessRepository,
)
from app.modules.clinical_tracking.infrastructure.entrypoints.wellness_schemas import (
    DailyWellnessLogResponse,
    UpsertDailyWellnessRequest,
)
from app.modules.identity.domain.models.user_profile import UserProfile
from app.modules.identity.infrastructure.adapters.postgres_user_profile_repository import (  # noqa: E501
    PostgresUserProfileRepository,
)

router = APIRouter(prefix="/wellness", tags=["Wellness & Habits"])


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


def get_wellness_repository(
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> IWellnessRepository:
    return PostgresWellnessRepository(session)


@router.put(
    "/logs/{log_date}",
    response_model=DailyWellnessLogResponse,
    status_code=status.HTTP_200_OK,
    summary="Upsert Daily Wellness Check-in",
    description=(
        "Records or partially merges daily wellness metrics "
        "(sleep, energy, hydration, exercise, mood) without erasing previous fields."
    ),
)
async def upsert_daily_wellness(
    log_date: date,
    request: UpsertDailyWellnessRequest,
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[IWellnessRepository, Depends(get_wellness_repository)],
) -> DailyWellnessLogResponse:
    use_case = UpsertDailyWellnessUseCase(repository)
    dto = UpsertWellnessDTO(
        sleep_hours=request.sleep_hours,
        sleep_quality=request.sleep_quality,
        energy_level=request.energy_level,
        hydration_ml=request.hydration_ml,
        exercise_minutes=request.exercise_minutes,
        mood_tags=request.mood_tags,
        notes=request.notes,
    )
    domain_log = await use_case.execute(
        user_id=str(user_profile.id),
        log_date=log_date,
        dto=dto,
    )
    return DailyWellnessLogResponse.from_domain(domain_log)


@router.get(
    "/logs/{log_date}",
    response_model=DailyWellnessLogResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Daily Wellness Log for a Date",
    description="Retrieves consolidated daily wellness log for the specified date.",
)
async def get_daily_wellness_by_date(
    log_date: date,
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[IWellnessRepository, Depends(get_wellness_repository)],
) -> DailyWellnessLogResponse:
    log = await repository.get_by_date(user_id=str(user_profile.id), log_date=log_date)
    if log is None:
        raise EntityNotFoundError(entity="DailyWellnessLog", identifier=str(log_date))
    return DailyWellnessLogResponse.from_domain(log)


@router.get(
    "/logs",
    response_model=list[DailyWellnessLogResponse],
    status_code=status.HTTP_200_OK,
    summary="Get Daily Wellness History",
    description="Retrieves a list of wellness logs for a given date range.",
)
async def get_wellness_history(
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[IWellnessRepository, Depends(get_wellness_repository)],
    start_date: Annotated[date, Query(description="Start date (YYYY-MM-DD)")],
    end_date: Annotated[date, Query(description="End date (YYYY-MM-DD)")],
) -> list[DailyWellnessLogResponse]:
    logs = await repository.get_history(
        user_id=str(user_profile.id),
        start_date=start_date,
        end_date=end_date,
    )
    return [DailyWellnessLogResponse.from_domain(log) for log in logs]
