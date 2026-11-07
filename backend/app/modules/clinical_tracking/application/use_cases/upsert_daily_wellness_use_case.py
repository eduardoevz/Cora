from datetime import date

from app.modules.clinical_tracking.application.dtos.wellness_dtos import (
    UpsertWellnessDTO,
)
from app.modules.clinical_tracking.application.ports.wellness_repository_port import (
    IWellnessRepository,
)
from app.modules.clinical_tracking.domain.models.daily_wellness_log import (
    DailyWellnessLog,
)
from app.modules.clinical_tracking.domain.value_objects.wellness_metrics import (
    EnergyLevel,
    ExerciseMinutes,
    HydrationMl,
    MoodTag,
    SleepHours,
    SleepQuality,
)


class UpsertDailyWellnessUseCase:
    """Use case to record or merge partial daily wellness metrics."""

    def __init__(self, repository: IWellnessRepository) -> None:
        self._repository = repository

    async def execute(
        self, user_id: str, log_date: date, dto: UpsertWellnessDTO
    ) -> DailyWellnessLog:
        # Convert primitive values to domain value objects (validating ranges)
        sleep_hours = (
            SleepHours(dto.sleep_hours) if dto.sleep_hours is not None else None
        )
        sleep_quality = (
            SleepQuality(dto.sleep_quality) if dto.sleep_quality is not None else None
        )
        energy_level = (
            EnergyLevel(dto.energy_level) if dto.energy_level is not None else None
        )
        hydration_ml = (
            HydrationMl(dto.hydration_ml) if dto.hydration_ml is not None else None
        )
        exercise_minutes = (
            ExerciseMinutes(dto.exercise_minutes)
            if dto.exercise_minutes is not None
            else None
        )
        mood_tags = (
            [MoodTag(tag) for tag in dto.mood_tags]
            if dto.mood_tags is not None
            else None
        )

        existing_log = await self._repository.get_by_date(user_id, log_date)

        if existing_log is not None:
            updated_log = existing_log.merge_patch(
                sleep_hours=sleep_hours,
                sleep_quality=sleep_quality,
                energy_level=energy_level,
                hydration_ml=hydration_ml,
                exercise_minutes=exercise_minutes,
                mood_tags=mood_tags,
                notes=dto.notes,
            )
        else:
            updated_log = DailyWellnessLog.create(
                user_id=user_id,
                log_date=log_date,
                sleep_hours=sleep_hours,
                sleep_quality=sleep_quality,
                energy_level=energy_level,
                hydration_ml=hydration_ml,
                exercise_minutes=exercise_minutes,
                mood_tags=mood_tags,
                notes=dto.notes,
            )

        return await self._repository.upsert(updated_log)
