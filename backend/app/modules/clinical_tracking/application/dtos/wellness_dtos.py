from dataclasses import dataclass


@dataclass(frozen=True)
class UpsertWellnessDTO:
    """Input DTO for recording or updating daily wellness metrics."""

    sleep_hours: float | None = None
    sleep_quality: int | None = None
    energy_level: int | None = None
    hydration_ml: int | None = None
    exercise_minutes: int | None = None
    mood_tags: list[str] | None = None
    notes: str | None = None


@dataclass(frozen=True)
class WellnessLogDTO:
    """Output DTO representing a consolidated daily wellness log."""

    id: str
    user_id: str
    log_date: str
    sleep_hours: float | None
    sleep_quality: int | None
    energy_level: int | None
    hydration_ml: int | None
    exercise_minutes: int | None
    mood_tags: list[str]
    notes: str | None
    created_at: str
    updated_at: str
