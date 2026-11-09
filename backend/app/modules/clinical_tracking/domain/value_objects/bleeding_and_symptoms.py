from dataclasses import dataclass
from datetime import date
from enum import StrEnum

from app.modules.clinical_tracking.domain.exceptions import (
    InvalidWellnessMetricError,
)
from app.modules.identity.domain.value_objects.life_stage import LifeStage
from app.modules.identity.domain.value_objects.onboarding_context import (
    DiagnosedCondition,
    HormonalMethod,
)


class BleedingFlow(StrEnum):
    """Menstrual flow intensity classification."""

    NONE = "none"
    SPOTTING = "spotting"
    LIGHT = "light"
    MEDIUM = "medium"
    HEAVY = "heavy"

    @property
    def is_menstrual_bleeding(self) -> bool:
        """Determines if flow is active menstrual bleeding instead of spotting."""
        return self in (
            BleedingFlow.LIGHT,
            BleedingFlow.MEDIUM,
            BleedingFlow.HEAVY,
        )


class CyclePhase(StrEnum):
    """Physiological phase of the menstrual cycle."""

    MENSTRUAL = "menstrual"
    FOLLICULAR = "follicular"
    OVULATORY = "ovulatory"
    LUTEAL = "luteal"
    HORMONALLY_MANAGED = "hormonally_managed"


@dataclass(frozen=True)
class PelvicPainScore:
    """Pain intensity score on 0-10 numeric scale."""

    value: int

    def __post_init__(self) -> None:
        if not (0 <= self.value <= 10):
            raise InvalidWellnessMetricError(
                metric_name="Dolor pélvico",
                value=self.value,
                valid_range="0 a 10",
            )


@dataclass(frozen=True)
class PatientCycleContext:
    """Reproductive context to calibrate cycle calculations and avoid false alarms."""

    life_stage: LifeStage
    hormonal_method: HormonalMethod
    diagnosed_conditions: list[DiagnosedCondition]
    birth_year: int
    menarche_year: int | None = None

    @property
    def is_hormonally_suppressed(self) -> bool:
        """Indicates if active contraceptive method suppresses spontaneous ovulation."""
        return self.hormonal_method in (
            HormonalMethod.COMBINED_ORAL_PILL,
            HormonalMethod.PROGESTIN_ONLY_PILL,
            HormonalMethod.HORMONAL_IUD,
            HormonalMethod.SUBDERMAL_IMPLANT,
            HormonalMethod.TRANSDERMAL_PATCH,
            HormonalMethod.INJECTABLE,
            HormonalMethod.HORMONE_REPLACEMENT_THERAPY,
        )

    @property
    def has_pcos(self) -> bool:
        return DiagnosedCondition.PCOS in self.diagnosed_conditions

    @property
    def has_endometriosis(self) -> bool:
        return DiagnosedCondition.ENDOMETRIOSIS in self.diagnosed_conditions

    @property
    def years_since_menarche(self) -> int | None:
        if self.menarche_year is None:
            return None
        return max(0, date.today().year - self.menarche_year)


@dataclass(frozen=True)
class CycleStatusSnapshot:
    """Current evaluated status of a user's cycle for a reference date."""

    current_cycle_id: str | None
    day_in_cycle: int | None
    current_phase: CyclePhase
    predicted_next_period: date | None
    fertile_window_start: date | None
    fertile_window_end: date | None
    ovulation_date: date | None
    is_hormonally_managed: bool
    has_extended_uncertainty: bool
    phase_description_es: str
    daily_tip_es: str
