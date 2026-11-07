from dataclasses import dataclass, field
from datetime import UTC, date, datetime
from uuid import uuid4

from app.modules.clinical_tracking.domain.value_objects.wellness_metrics import (
    EnergyLevel,
    ExerciseMinutes,
    HydrationMl,
    MoodTag,
    SleepHours,
    SleepQuality,
)


@dataclass(frozen=True)
class DailyWellnessLog:
    """Holistic daily wellness and lifestyle tracking aggregate."""

    id: str
    user_id: str
    log_date: date
    sleep_hours: SleepHours | None = None
    sleep_quality: SleepQuality | None = None
    energy_level: EnergyLevel | None = None
    hydration_ml: HydrationMl | None = None
    exercise_minutes: ExerciseMinutes | None = None
    mood_tags: list[MoodTag] = field(default_factory=list)
    notes: str | None = None
    created_at: datetime = field(default_factory=lambda: datetime.now(UTC))
    updated_at: datetime = field(default_factory=lambda: datetime.now(UTC))

    @classmethod
    def create(
        cls,
        user_id: str,
        log_date: date,
        sleep_hours: SleepHours | None = None,
        sleep_quality: SleepQuality | None = None,
        energy_level: EnergyLevel | None = None,
        hydration_ml: HydrationMl | None = None,
        exercise_minutes: ExerciseMinutes | None = None,
        mood_tags: list[MoodTag] | None = None,
        notes: str | None = None,
        log_id: str | None = None,
    ) -> "DailyWellnessLog":
        now = datetime.now(UTC)
        return cls(
            id=log_id or str(uuid4()),
            user_id=user_id,
            log_date=log_date,
            sleep_hours=sleep_hours,
            sleep_quality=sleep_quality,
            energy_level=energy_level,
            hydration_ml=hydration_ml,
            exercise_minutes=exercise_minutes,
            mood_tags=list(mood_tags) if mood_tags is not None else [],
            notes=notes,
            created_at=now,
            updated_at=now,
        )

    def merge_patch(
        self,
        sleep_hours: SleepHours | None = None,
        sleep_quality: SleepQuality | None = None,
        energy_level: EnergyLevel | None = None,
        hydration_ml: HydrationMl | None = None,
        exercise_minutes: ExerciseMinutes | None = None,
        mood_tags: list[MoodTag] | None = None,
        notes: str | None = None,
    ) -> "DailyWellnessLog":
        """Merge incoming non-null fields while preserving existing data."""
        return DailyWellnessLog(
            id=self.id,
            user_id=self.user_id,
            log_date=self.log_date,
            sleep_hours=sleep_hours if sleep_hours is not None else self.sleep_hours,
            sleep_quality=(
                sleep_quality if sleep_quality is not None else self.sleep_quality
            ),
            energy_level=(
                energy_level if energy_level is not None else self.energy_level
            ),
            hydration_ml=(
                hydration_ml if hydration_ml is not None else self.hydration_ml
            ),
            exercise_minutes=(
                exercise_minutes
                if exercise_minutes is not None
                else self.exercise_minutes
            ),
            mood_tags=list(mood_tags) if mood_tags is not None else self.mood_tags,
            notes=notes if notes is not None else self.notes,
            created_at=self.created_at,
            updated_at=datetime.now(UTC),
        )
