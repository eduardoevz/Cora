import re
from dataclasses import dataclass
from datetime import date
from enum import StrEnum

from app.modules.treatments.domain.exceptions.treatment_exceptions import (
    InvalidScheduleConfigurationError,
)

_TIME_REGEX = re.compile(r"^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$")


class TreatmentCategory(StrEnum):
    """Clinical categories of medications and treatments."""

    CONTRACEPTIVE_ORAL_COMBINED = "contraceptive_oral_combined"
    CONTRACEPTIVE_PROGESTIN_ONLY = "contraceptive_progestin_only"
    PATCH = "patch"
    INJECTABLE = "injectable"
    LARC_IUD_IMPLANT = "larc_iud_implant"
    HRT = "hrt"
    SUPPLEMENT = "supplement"
    CHRONIC_MEDICATION = "chronic_medication"


class ScheduleType(StrEnum):
    """Posology intake schedule patterns."""

    DAILY_FIXED = "daily_fixed"
    CYCLIC_ACTIVE_BREAK = "cyclic_active_break"
    INTERVAL_DAYS = "interval_days"
    LONG_ACTING_REPLACEMENT = "long_acting_replacement"


@dataclass(frozen=True)
class DosageSchedule:
    """Posology configuration for scheduled administration of treatments."""

    schedule_type: ScheduleType
    scheduled_time: str
    active_days: int | None = None
    break_days: int | None = None
    interval_days: int | None = None
    replacement_date: date | None = None

    def __post_init__(self) -> None:
        if not _TIME_REGEX.match(self.scheduled_time):
            raise InvalidScheduleConfigurationError(
                f"Hora de toma inválida: '{self.scheduled_time}'. "
                "Debe tener formato HH:MM."
            )

        if self.schedule_type == ScheduleType.CYCLIC_ACTIVE_BREAK:
            if (
                self.active_days is None
                or self.break_days is None
                or self.active_days <= 0
                or self.break_days <= 0
            ):
                raise InvalidScheduleConfigurationError(
                    "Los esquemas cíclicos requieren días activos y de descanso > 0."
                )

        elif self.schedule_type == ScheduleType.LONG_ACTING_REPLACEMENT:
            if self.replacement_date is None:
                raise InvalidScheduleConfigurationError(
                    "Tratamientos LARC requieren fecha de reemplazo programada."
                )

        elif self.schedule_type == ScheduleType.INTERVAL_DAYS:
            if self.interval_days is None or self.interval_days <= 0:
                raise InvalidScheduleConfigurationError(
                    "Tratamientos por intervalo requieren especificar intervalo > 0."
                )
