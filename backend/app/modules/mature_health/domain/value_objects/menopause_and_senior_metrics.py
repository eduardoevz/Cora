"""Value objects and clinical metric types for mature health domain."""

from dataclasses import dataclass
from enum import IntEnum, StrEnum


class Straw10Stage(StrEnum):
    """Stages of Reproductive Aging Workshop + 10 (STRAW+10)."""

    LATE_REPRODUCTIVE = "LATE_REPRODUCTIVE"
    EARLY_TRANSITION = "EARLY_TRANSITION"
    LATE_TRANSITION = "LATE_TRANSITION"
    POSTMENOPAUSE = "POSTMENOPAUSE"


class MenopauseClinicalAlertSeverity(StrEnum):
    """Severity levels for menopause clinical alerts."""

    INFO = "INFO"
    WARNING = "WARNING"
    URGENT_EMERGENCY = "URGENT_EMERGENCY"


class HotFlashSeverity(IntEnum):
    """Intensity score for hot flash episodes (1 to 4)."""

    MILD = 1
    MODERATE = 2
    SEVERE = 3
    VERY_SEVERE = 4


class HotFlashType(StrEnum):
    """Time-of-day characterization for vasomotor episodes."""

    DAYTIME = "DAYTIME"
    NIGHT_SWEATS = "NIGHT_SWEATS"


class CardiometabolicRiskLevel(StrEnum):
    """Cardiometabolic risk stratification."""

    OPTIMAL = "OPTIMAL"
    BORDERLINE = "BORDERLINE"
    ELEVATED_RISK = "ELEVATED_RISK"


class AnatomicalSite(StrEnum):
    """Anatomical site scanned during DXA bone densitometry."""

    LUMBAR_SPINE = "LUMBAR_SPINE"
    FEMORAL_NECK = "FEMORAL_NECK"
    TOTAL_HIP = "TOTAL_HIP"
    DISTAL_RADIUS = "DISTAL_RADIUS"


class BoneDensityCategory(StrEnum):
    """WHO T-score diagnostic criteria for bone mineral density."""

    NORMAL = "NORMAL"
    OSTEOPENIA = "OSTEOPENIA"
    OSTEOPOROSIS = "OSTEOPOROSIS"
    SEVERE_OSTEOPOROSIS = "SEVERE_OSTEOPOROSIS"


class FallRiskLevel(StrEnum):
    """Stratified fall risk assessment for senior health."""

    LOW = "LOW"
    MODERATE = "MODERATE"
    HIGH = "HIGH"


class IncontinenceType(StrEnum):
    """Urogynecology urinary incontinence classification."""

    NONE = "NONE"
    STRESS = "STRESS"
    URGE = "URGE"
    MIXED = "MIXED"
    OVERFLOW = "OVERFLOW"


@dataclass(frozen=True)
class MenopauseClinicalAlert:
    """Clinical alert generated for perimenopause and postmenopause safety."""

    code: str
    severity: MenopauseClinicalAlertSeverity
    title: str
    clinical_guidance: str
    requires_immediate_clinical_evaluation: bool


@dataclass(frozen=True)
class CardiometabolicAssessment:
    """Result of lipid, blood pressure, and glycemic profile evaluation."""

    risk_level: CardiometabolicRiskLevel
    flagged_parameters: tuple[str, ...]
    recommendations: tuple[str, ...]


@dataclass(frozen=True)
class BoneDensityClassification:
    """WHO classification of DXA bone densitometry scan."""

    category: BoneDensityCategory
    t_score: float
    anatomical_site: AnatomicalSite
    clinical_summary: str


@dataclass(frozen=True)
class FallRiskResult:
    """Assessment of functional fall risk for senior vitality."""

    risk_level: FallRiskLevel
    score: int
    preventive_actions: tuple[str, ...]


@dataclass(frozen=True)
class FractureRiskAlert:
    """Alert when high fall risk coincides with low bone mineral density."""

    code: str
    priority: str
    recommendations: str


@dataclass(frozen=True)
class PelvicFloorGuidance:
    """Supportive and preventative clinical guidance for pelvic floor health."""

    requires_urogynecology_consult: bool
    supportive_tips: tuple[str, ...]
