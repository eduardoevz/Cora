import uuid
from dataclasses import dataclass, field
from datetime import UTC, date, datetime, timedelta
from typing import Any

from app.modules.maternal_care.domain.exceptions.maternal_care_exceptions import (
    InvalidGestationalAgeError,
    PregnancyEpisodeValidationError,
)


@dataclass(frozen=True)
class GestationalAge:
    weeks: int
    days: int

    def __post_init__(self) -> None:
        if not (0 <= self.days <= 6):
            raise InvalidGestationalAgeError(
                f"Días gestacionales ({self.days}) deben estar entre 0 y 6"
            )
        if not (3 <= self.weeks <= 44):
            raise InvalidGestationalAgeError(
                f"Semanas gestacionales ({self.weeks}) deben estar entre 3 y 44"
            )

    @property
    def total_days(self) -> int:
        return self.weeks * 7 + self.days

    def __str__(self) -> str:
        return f"{self.weeks} semanas y {self.days} días"

    @classmethod
    def from_dates(
        cls, last_menstrual_period: date, reference_date: date
    ) -> "GestationalAge":
        delta = (reference_date - last_menstrual_period).days
        if delta < 0:
            raise InvalidGestationalAgeError(
                "La fecha de referencia no puede ser anterior a la FUM"
            )
        weeks = delta // 7
        days = delta % 7
        return cls(weeks=weeks, days=days)


@dataclass
class BirthPlanPreference:
    companion_preferences: list[str] = field(default_factory=list)
    pain_management: list[str] = field(default_factory=list)
    delivery_environment: list[str] = field(default_factory=list)
    immediate_postpartum: list[str] = field(default_factory=list)
    special_requests: str | None = None


@dataclass
class PrenatalAppointment:
    id: uuid.UUID
    pregnancy_episode_id: uuid.UUID
    scheduled_at: datetime
    doctor_or_clinic: str
    gestational_week: int
    topics_to_discuss: list[str] = field(default_factory=list)
    notes: str | None = None
    is_completed: bool = False


@dataclass
class PregnancyEpisode:
    id: uuid.UUID
    user_id: uuid.UUID
    clinical_edd: date
    is_active: bool
    started_at: datetime
    last_menstrual_period: date | None = None
    ultrasound_edd: date | None = None
    ended_at: datetime | None = None
    recalibration_history: list[dict[str, Any]] = field(default_factory=list)

    def __post_init__(self) -> None:
        if self.clinical_edd is None:
            raise PregnancyEpisodeValidationError(
                "Un episodio de embarazo requiere fecha probable de parto clínica (FPP)"
            )

    @classmethod
    def create_from_lmp(
        cls,
        user_id: uuid.UUID,
        last_menstrual_period: date,
        episode_id: uuid.UUID | None = None,
    ) -> "PregnancyEpisode":
        calculated_edd = last_menstrual_period + timedelta(days=280)
        return cls(
            id=episode_id or uuid.uuid4(),
            user_id=user_id,
            last_menstrual_period=last_menstrual_period,
            clinical_edd=calculated_edd,
            is_active=True,
            started_at=datetime.now(UTC),
        )

    def calculate_gestational_age(self, as_of: date) -> GestationalAge:
        if self.ultrasound_edd is not None:
            anchor_lmp = self.ultrasound_edd - timedelta(days=280)
        elif self.last_menstrual_period is not None:
            anchor_lmp = self.last_menstrual_period
        else:
            anchor_lmp = self.clinical_edd - timedelta(days=280)

        delta = (as_of - anchor_lmp).days
        if delta < 0:
            return GestationalAge(weeks=3, days=0)
        weeks = delta // 7
        days = delta % 7
        clamped_weeks = max(3, min(44, weeks))
        clamped_days = max(0, min(6, days))
        return GestationalAge(weeks=clamped_weeks, days=clamped_days)

    def recalibrate_with_ultrasound(self, ultrasound_edd: date, note: str) -> None:
        previous_edd = self.clinical_edd
        self.ultrasound_edd = ultrasound_edd
        self.clinical_edd = ultrasound_edd
        self.recalibration_history.append(
            {
                "recalibrated_at": datetime.now(UTC).isoformat(),
                "previous_edd": previous_edd.isoformat(),
                "new_edd": ultrasound_edd.isoformat(),
                "note": note,
            }
        )

    def current_trimester(self, as_of: date) -> int:
        ga = self.calculate_gestational_age(as_of)
        if ga.weeks <= 13:
            return 1
        if ga.weeks <= 27:
            return 2
        return 3
