from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.modules.clinical_tracking.domain.models.daily_wellness_log import (
    DailyWellnessLog,
)


class UpsertDailyWellnessRequest(BaseModel):
    """Payload for partial or full daily wellness logging."""

    sleep_hours: float | None = Field(default=None, ge=0.0, le=24.0)
    sleep_quality: int | None = Field(default=None, ge=1, le=5)
    energy_level: int | None = Field(default=None, ge=1, le=5)
    hydration_ml: int | None = Field(default=None, ge=0, le=10000)
    exercise_minutes: int | None = Field(default=None, ge=0, le=1440)
    mood_tags: list[str] | None = None
    notes: str | None = None


class DailyWellnessLogResponse(BaseModel):
    """API representation of consolidated daily wellness."""

    id: UUID
    user_id: UUID
    log_date: date
    sleep_hours: float | None = None
    sleep_quality: int | None = None
    energy_level: int | None = None
    hydration_ml: int | None = None
    exercise_minutes: int | None = None
    mood_tags: list[str] = Field(default_factory=list)
    notes: str | None = None
    created_at: datetime
    updated_at: datetime

    @classmethod
    def from_domain(cls, domain: DailyWellnessLog) -> "DailyWellnessLogResponse":
        return cls(
            id=UUID(domain.id),
            user_id=UUID(domain.user_id),
            log_date=domain.log_date,
            sleep_hours=domain.sleep_hours.value if domain.sleep_hours else None,
            sleep_quality=domain.sleep_quality.value if domain.sleep_quality else None,
            energy_level=domain.energy_level.value if domain.energy_level else None,
            hydration_ml=domain.hydration_ml.value if domain.hydration_ml else None,
            exercise_minutes=domain.exercise_minutes.value
            if domain.exercise_minutes
            else None,
            mood_tags=[m.value for m in domain.mood_tags],
            notes=domain.notes,
            created_at=domain.created_at,
            updated_at=domain.updated_at,
        )
