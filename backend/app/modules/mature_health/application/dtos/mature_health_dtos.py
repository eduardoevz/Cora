"""Application DTOs for mature health use cases."""

from dataclasses import dataclass, field
from datetime import date, datetime
from uuid import UUID

from app.modules.mature_health.domain.value_objects import (
    AnatomicalSite,
    BoneDensityClassification,
    CardiometabolicAssessment,
    FallRiskResult,
    FractureRiskAlert,
    HotFlashSeverity,
    HotFlashType,
    IncontinenceType,
    MenopauseClinicalAlert,
    PelvicFloorGuidance,
    Straw10Stage,
)


@dataclass(frozen=True)
class RecordHotFlashInput:
    """Input for recording a vasomotor symptom episode."""

    occurred_at: datetime
    severity: HotFlashSeverity
    flash_type: HotFlashType
    duration_minutes: int
    triggers: list[str] = field(default_factory=list)
    sleep_disruption_level: int = 0
    associated_with_hrt: bool = False
    notes: str | None = None


@dataclass(frozen=True)
class RecordCardiometabolicInput:
    """Input for recording a lipid and blood pressure panel."""

    measurement_date: date
    systolic_bp: int | None = None
    diastolic_bp: int | None = None
    total_cholesterol_mg_dl: float | None = None
    ldl_cholesterol_mg_dl: float | None = None
    hdl_cholesterol_mg_dl: float | None = None
    triglycerides_mg_dl: float | None = None
    fasting_glucose_mg_dl: float | None = None
    notes: str | None = None


@dataclass(frozen=True)
class RecordBleedingObservationInput:
    """Input for recording vaginal bleeding during transition or postmenopause."""

    observation_date: date
    days_of_prior_amenorrhea: int
    flow_intensity: str = "LIGHT"
    has_cramping: bool = False
    notes: str | None = None


@dataclass(frozen=True)
class RecordDexaInput:
    """Input for registering a DXA bone density scan."""

    scan_date: date
    anatomical_site: AnatomicalSite
    t_score: float
    z_score: float | None = None
    bmd_g_cm2: float | None = None
    previous_fragility_fracture: bool = False
    notes: str | None = None


@dataclass(frozen=True)
class RecordFallAssessmentInput:
    """Input for senior fall risk assessment."""

    assessment_date: date
    falls_past_year: int
    has_gait_unsteadiness: bool = False
    uses_walking_aid: bool = False
    timed_up_and_go_seconds: float | None = None
    environmental_hazards_identified: list[str] = field(default_factory=list)
    notes: str | None = None


@dataclass(frozen=True)
class RecordPelvicLogInput:
    """Input for urogynecology and continence symptom log."""

    log_date: date
    incontinence_type: IncontinenceType = IncontinenceType.NONE
    daily_pad_count: int = 0
    has_pelvic_heaviness: bool = False
    vaginal_dryness_level: int = 0
    has_dyspareunia: bool = False
    notes: str | None = None


@dataclass(frozen=True)
class SaveSupportContactInput:
    """Input for configuring primary trusted family/support contact."""

    contact_name: str
    relationship: str
    phone_number: str
    notes: str | None = None
    is_primary: bool = True


@dataclass(frozen=True)
class BleedingSafetyEvaluationOutput:
    """Output for bleeding safety evaluation."""

    observation_id: UUID
    is_alert_triggered: bool
    alert: MenopauseClinicalAlert | None


@dataclass(frozen=True)
class DexaEvaluationOutput:
    """Output containing DXA record and classification."""

    scan_id: UUID
    classification: BoneDensityClassification


@dataclass(frozen=True)
class FallRiskEvaluationOutput:
    """Output containing fall risk record and composite result."""

    assessment_id: UUID
    result: FallRiskResult


@dataclass(frozen=True)
class PelvicLogOutput:
    """Output containing pelvic log and clinical guidance."""

    log_id: UUID
    guidance: PelvicFloorGuidance


@dataclass(frozen=True)
class MenopauseHubSummaryOutput:
    """Aggregated summary for Menopause and Perimenopause dashboard."""

    straw10_stage: Straw10Stage
    hot_flashes_count_last_30_days: int
    latest_cardiometabolic_assessment: CardiometabolicAssessment | None
    active_alerts: list[MenopauseClinicalAlert]


@dataclass(frozen=True)
class SeniorVitalityHubSummaryOutput:
    """Aggregated summary for Senior Vitality dashboard."""

    latest_bone_classification: BoneDensityClassification | None
    latest_fall_risk: FallRiskResult | None
    fracture_alert: FractureRiskAlert | None
    latest_pelvic_guidance: PelvicFloorGuidance | None
    trusted_contact_name: str | None
    trusted_contact_phone: str | None
