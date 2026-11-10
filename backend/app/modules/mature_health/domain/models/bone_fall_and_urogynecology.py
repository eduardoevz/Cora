"""Domain entities for DXA results, fall risk, and pelvic floor logs."""

from dataclasses import dataclass, field
from datetime import date
from uuid import UUID, uuid4

from app.modules.mature_health.domain.exceptions import (
    InvalidBoneDensityReadingError,
    InvalidFallAssessmentError,
    InvalidPelvicLogError,
)
from app.modules.mature_health.domain.value_objects import (
    AnatomicalSite,
    IncontinenceType,
)


@dataclass
class DexaBoneResult:
    """Bone mineral density DXA scan measurement."""

    scan_date: date
    anatomical_site: AnatomicalSite
    t_score: float
    z_score: float | None = None
    bmd_g_cm2: float | None = None
    previous_fragility_fracture: bool = False
    notes: str | None = None
    id: UUID = field(default_factory=uuid4)
    user_id: UUID | None = None

    def __post_init__(self) -> None:
        if not (-10.0 <= self.t_score <= 10.0):
            raise InvalidBoneDensityReadingError(
                f"T-score {self.t_score} out of physiological range [-10.0, 10.0]"
            )
        if self.z_score is not None and not (-10.0 <= self.z_score <= 10.0):
            raise InvalidBoneDensityReadingError(
                f"Z-score {self.z_score} out of physiological range [-10.0, 10.0]"
            )
        if self.bmd_g_cm2 is not None and self.bmd_g_cm2 < 0:
            raise InvalidBoneDensityReadingError("BMD cannot be negative")


@dataclass
class FallRiskAssessment:
    """Senior functional mobility and fall risk assessment."""

    assessment_date: date
    falls_past_year: int
    has_gait_unsteadiness: bool = False
    uses_walking_aid: bool = False
    timed_up_and_go_seconds: float | None = None
    environmental_hazards_identified: list[str] = field(default_factory=list)
    notes: str | None = None
    id: UUID = field(default_factory=uuid4)
    user_id: UUID | None = None

    def __post_init__(self) -> None:
        if self.falls_past_year < 0:
            raise InvalidFallAssessmentError(
                f"falls_past_year cannot be negative, got {self.falls_past_year}"
            )
        if (
            self.timed_up_and_go_seconds is not None
            and self.timed_up_and_go_seconds < 0
        ):
            raise InvalidFallAssessmentError(
                "timed_up_and_go_seconds cannot be negative"
            )


@dataclass
class ContinenceAndPelvicLog:
    """Pelvic floor and urogynecological symptom diary."""

    log_date: date
    incontinence_type: IncontinenceType = IncontinenceType.NONE
    daily_pad_count: int = 0
    has_pelvic_heaviness: bool = False
    vaginal_dryness_level: int = 0
    has_dyspareunia: bool = False
    notes: str | None = None
    id: UUID = field(default_factory=uuid4)
    user_id: UUID | None = None

    def __post_init__(self) -> None:
        if self.daily_pad_count < 0:
            raise InvalidPelvicLogError("daily_pad_count cannot be negative")
        if not (0 <= self.vaginal_dryness_level <= 3):
            raise InvalidPelvicLogError(
                f"vaginal_dryness_level must be between 0 and 3, "
                f"got {self.vaginal_dryness_level}"
            )
