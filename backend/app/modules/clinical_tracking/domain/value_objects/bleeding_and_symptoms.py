from dataclasses import dataclass
from datetime import date
from enum import StrEnum

from app.modules.clinical_tracking.domain.exceptions import (
    ClinicalTrackingError,
    InvalidWellnessMetricError,
)
from app.modules.identity.domain.value_objects.life_stage import LifeStage
from app.modules.identity.domain.value_objects.onboarding_context import (
    CycleRegularity,
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


class CalendarDayMarker(StrEnum):
    """Visual/clinical marker assigned to a day on the menstrual calendar."""

    RECORDED_PERIOD = "recorded_period"
    PREDICTED_PERIOD = "predicted_period"
    FERTILE_WINDOW = "fertile_window"
    PREDICTED_OVULATION = "predicted_ovulation"
    SPOTTING = "spotting"
    NONE = "none"


class FertilityProbability(StrEnum):
    """Qualitative orientation of conception probability on a given calendar day."""

    NONE = "none"
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class CalendarDisplayMode(StrEnum):
    """Stage-adapted presentation mode for the monthly menstrual calendar."""

    STANDARD_CYCLE = "standard_cycle"
    ADOLESCENCE_FLEXIBLE = "adolescence_flexible"
    CONCEPTION_FERTILITY = "conception_fertility"
    HORMONALLY_MANAGED = "hormonally_managed"
    PREGNANCY_GESTATIONAL = "pregnancy_gestational"
    POSTPARTUM_RECOVERY = "postpartum_recovery"
    PERIMENOPAUSE_STRAW10 = "perimenopause_straw10"
    SENIOR_PREVENTIVE = "senior_preventive"


@dataclass(frozen=True)
class InitialPeriodRange:
    """Validated date range [start_date..end_date] for an initial historical period."""

    start_date: date
    end_date: date

    def __post_init__(self) -> None:
        if self.end_date < self.start_date:
            raise ClinicalTrackingError(
                code="invalid_period_range",
                title="Rango de Periodo Inválido",
                detail="La fecha de fin del periodo no puede ser anterior al inicio.",
                status_code=400,
            )
        if self.bleeding_duration_days > 15:
            raise ClinicalTrackingError(
                code="invalid_bleeding_duration",
                title="Duración de Sangrado Inválida",
                detail=(
                    "Cada periodo inicial debe tener una duración máxima de 15 días."
                ),
                status_code=400,
            )

    @property
    def bleeding_duration_days(self) -> int:
        return (self.end_date - self.start_date).days + 1


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
    cycle_regularity: CycleRegularity = CycleRegularity.UNSURE
    typical_cycle_length_days: int | None = None
    typical_bleeding_duration_days: int | None = None

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


@dataclass(frozen=True)
class CalendarDayProjection:
    """Single day projection inside the monthly menstrual calendar."""

    date: date
    day_in_cycle: int | None
    phase: CyclePhase | None
    day_marker: CalendarDayMarker
    fertility_probability: FertilityProbability
    has_logged_symptoms: bool
    bleeding_flow: BleedingFlow
    pelvic_pain: int | None
    daily_summary_es: str
    phase_education_es: str


@dataclass(frozen=True)
class CalendarMonthProjection:
    """Full monthly projection adapted to life stage and cycle history."""

    year: int
    month: int
    display_mode: CalendarDisplayMode
    estimated_cycle_length_days: int
    estimated_bleeding_duration_days: int
    is_hormonally_managed: bool
    has_extended_uncertainty: bool
    current_cycle_day: int | None
    current_phase: CyclePhase | None
    predicted_next_period: date | None
    ovulation_date: date | None
    fertile_window_start: date | None
    fertile_window_end: date | None
    days: tuple[CalendarDayProjection, ...]
