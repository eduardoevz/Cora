from dataclasses import dataclass
from datetime import date, time
from decimal import ROUND_HALF_UP, Decimal
from enum import StrEnum

from app.modules.clinical_tracking.domain.exceptions.clinical_tracking_exceptions import (  # noqa: E501
    InvalidBasalTemperatureError,
)

MIN_PHYSIOLOGICAL_BBT = Decimal("35.00")
MAX_PHYSIOLOGICAL_BBT = Decimal("42.00")
FEVER_THRESHOLD_BBT = Decimal("38.00")


class CervicalMucusType(StrEnum):
    """Cervical fluid consistency classification according to symptothermal method."""

    DRY = "dry"
    STICKY = "sticky"
    CREAMY = "creamy"
    WATERY = "watery"
    EGG_WHITE = "egg_white"

    @property
    def is_fertile(self) -> bool:
        """Watery and egg-white textures indicate high estrogen and fertile window."""
        return self in (CervicalMucusType.WATERY, CervicalMucusType.EGG_WHITE)

    @property
    def fertility_score(self) -> int:
        scores = {
            CervicalMucusType.DRY: 0,
            CervicalMucusType.STICKY: 1,
            CervicalMucusType.CREAMY: 2,
            CervicalMucusType.WATERY: 3,
            CervicalMucusType.EGG_WHITE: 4,
        }
        return scores[self]


class LhStripResult(StrEnum):
    """Urinary luteinizing hormone (LH) test strip classification."""

    NEGATIVE = "negative"
    HIGH = "high"
    PEAK = "peak"

    @property
    def is_positive(self) -> bool:
        return self in (LhStripResult.HIGH, LhStripResult.PEAK)


class IntercourseType(StrEnum):
    """Coitus/insemination tracking for conception timing."""

    NONE = "none"
    UNPROTECTED = "unprotected"
    PROTECTED = "protected"
    INSEMINATION = "insemination"


class FertilityStatus(StrEnum):
    """Daily fertility status derived deterministically from symptothermal signs."""

    LOW = "low"
    HIGH = "high"
    PEAK_FERTILITY = "peak_fertility"
    OVULATION_CONFIRMED = "ovulation_confirmed"


@dataclass(frozen=True)
class BasalBodyTemperature:
    """Resting body temperature measured upon waking before activity.

    Enforces strict physiological range (35.00 °C – 42.00 °C) and marks disturbances
    (fever >= 38.00 °C, insomnia, alcohol) to prevent false luteal phase confirmations.
    """

    celsius: Decimal
    is_disturbed: bool = False
    disturbance_reason: str | None = None
    measured_at_time: time | None = None

    def __post_init__(self) -> None:
        celsius_val = Decimal(str(self.celsius)).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )
        if celsius_val < MIN_PHYSIOLOGICAL_BBT or celsius_val > MAX_PHYSIOLOGICAL_BBT:
            raise InvalidBasalTemperatureError(celsius_val)

        object.__setattr__(self, "celsius", celsius_val)

        if celsius_val >= FEVER_THRESHOLD_BBT:
            object.__setattr__(self, "is_disturbed", True)
            if not self.disturbance_reason:
                object.__setattr__(self, "disturbance_reason", "Fiebre (>= 38.00 °C)")

    @property
    def is_fever(self) -> bool:
        return self.celsius >= FEVER_THRESHOLD_BBT

    def to_fahrenheit(self) -> Decimal:
        """Converts canonical Celsius to Fahrenheit rounded to 2 decimal places."""
        f_val = (self.celsius * Decimal("9") / Decimal("5")) + Decimal("32")
        return f_val.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

    @classmethod
    def from_fahrenheit(
        cls,
        fahrenheit: Decimal,
        is_disturbed: bool = False,
        disturbance_reason: str | None = None,
        measured_at_time: time | None = None,
    ) -> "BasalBodyTemperature":
        """Factory creating canonical Celsius instance from a Fahrenheit reading."""
        c_val = (fahrenheit - Decimal("32")) * Decimal("5") / Decimal("9")
        c_rounded = c_val.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        return cls(
            celsius=c_rounded,
            is_disturbed=is_disturbed,
            disturbance_reason=disturbance_reason,
            measured_at_time=measured_at_time,
        )


@dataclass(frozen=True)
class DailyFertilityLog:
    """Aggregate observation for a specific date in conception search."""

    log_date: date
    bbt: BasalBodyTemperature | None = None
    cervical_mucus: CervicalMucusType | None = None
    lh_result: LhStripResult | None = None
    intercourse_had: bool = False
    intercourse_type: IntercourseType = IntercourseType.NONE
    notes: str | None = None


@dataclass(frozen=True)
class FertilityWindowAssessment:
    """Deterministic clinical evaluation of cycle fertility window."""

    status: FertilityStatus
    coverline_celsius: Decimal | None = None
    ovulation_confirmed_date: date | None = None
    fertile_window_start: date | None = None
    fertile_window_end: date | None = None
    is_biphasic_shift_detected: bool = False
    evaluation_notes_es: str = ""
    active_seeking_guidance_es: str | None = None
