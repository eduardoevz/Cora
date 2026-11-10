"""Domain entities for vasomotor episodes, bleeding, and metabolic panels."""

from dataclasses import dataclass, field
from datetime import date, datetime
from uuid import UUID, uuid4

from app.modules.mature_health.domain.exceptions import (
    InvalidCardiometabolicReadingError,
    InvalidHotFlashEpisodeError,
)
from app.modules.mature_health.domain.value_objects import (
    HotFlashSeverity,
    HotFlashType,
)


@dataclass
class HotFlashEpisode:
    """Record of a vasomotor symptom (hot flash or night sweat)."""

    occurred_at: datetime
    severity: HotFlashSeverity
    flash_type: HotFlashType
    duration_minutes: int
    triggers: list[str] = field(default_factory=list)
    sleep_disruption_level: int = 0
    associated_with_hrt: bool = False
    notes: str | None = None
    id: UUID = field(default_factory=uuid4)
    user_id: UUID | None = None

    def __post_init__(self) -> None:
        if not isinstance(self.severity, HotFlashSeverity) and self.severity not in (
            1,
            2,
            3,
            4,
        ):
            raise InvalidHotFlashEpisodeError(
                f"Severity must be between 1 and 4, got {self.severity}"
            )
        try:
            self.severity = HotFlashSeverity(self.severity)
        except ValueError as err:
            raise InvalidHotFlashEpisodeError(str(err)) from err

        if not (0 <= self.sleep_disruption_level <= 3):
            raise InvalidHotFlashEpisodeError(
                "sleep_disruption_level must be between 0 (none) and 3 (severe)"
            )
        if self.duration_minutes < 0:
            raise InvalidHotFlashEpisodeError("duration_minutes cannot be negative")


@dataclass
class VaginalBleedingObservation:
    """Clinical observation of vaginal bleeding during or after transition."""

    observation_date: date
    days_of_prior_amenorrhea: int
    flow_intensity: str = "LIGHT"
    has_cramping: bool = False
    notes: str | None = None
    id: UUID = field(default_factory=uuid4)
    user_id: UUID | None = None

    def __post_init__(self) -> None:
        if self.days_of_prior_amenorrhea < 0:
            raise ValueError("days_of_prior_amenorrhea cannot be negative")


@dataclass
class CardiometabolicPanel:
    """Lipid, blood pressure, and metabolic profile measurements."""

    measurement_date: date
    systolic_bp: int | None = None
    diastolic_bp: int | None = None
    total_cholesterol_mg_dl: float | None = None
    ldl_cholesterol_mg_dl: float | None = None
    hdl_cholesterol_mg_dl: float | None = None
    triglycerides_mg_dl: float | None = None
    fasting_glucose_mg_dl: float | None = None
    notes: str | None = None
    id: UUID = field(default_factory=uuid4)
    user_id: UUID | None = None

    def __post_init__(self) -> None:
        for field_name, val in [
            ("systolic_bp", self.systolic_bp),
            ("diastolic_bp", self.diastolic_bp),
            ("total_cholesterol_mg_dl", self.total_cholesterol_mg_dl),
            ("ldl_cholesterol_mg_dl", self.ldl_cholesterol_mg_dl),
            ("hdl_cholesterol_mg_dl", self.hdl_cholesterol_mg_dl),
            ("triglycerides_mg_dl", self.triglycerides_mg_dl),
            ("fasting_glucose_mg_dl", self.fasting_glucose_mg_dl),
        ]:
            if val is not None and val < 0:
                raise InvalidCardiometabolicReadingError(
                    f"{field_name} cannot be negative, got {val}"
                )
        if (
            self.systolic_bp is not None
            and self.diastolic_bp is not None
            and self.systolic_bp <= self.diastolic_bp
        ):
            raise InvalidCardiometabolicReadingError(
                f"systolic_bp ({self.systolic_bp}) must exceed "
                f"diastolic_bp ({self.diastolic_bp})"
            )
