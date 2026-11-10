"""Pydantic v2 schemas for mature health REST API."""

import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field


class HotFlashRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    occurred_at: datetime = Field(
        ..., description="Timestamp de cuando ocurrió el episodio de sofoco"
    )
    severity: int = Field(
        ..., ge=1, le=4, description="Intensidad de 1 (leve) a 4 (muy severo)"
    )
    flash_type: str = Field(
        ...,
        pattern="^(DAYTIME|NIGHT_SWEATS)$",
        description="DAYTIME o NIGHT_SWEATS",
    )
    duration_minutes: int = Field(
        ..., ge=0, le=1440, description="Duración estimada en minutos"
    )
    triggers: list[str] = Field(
        default_factory=list,
        description="Factores desencadenantes identificados",
    )
    sleep_disruption_level: int = Field(
        default=0, ge=0, le=3, description="Impacto en el sueño (0 a 3)"
    )
    associated_with_hrt: bool = Field(
        default=False,
        description="Si la usuaria está bajo esquema activo de TRH",
    )
    notes: str | None = Field(default=None, max_length=500)


class HotFlashResponse(BaseModel):
    id: uuid.UUID
    occurred_at: datetime
    severity: int
    flash_type: str
    duration_minutes: int
    triggers: list[str]
    sleep_disruption_level: int
    associated_with_hrt: bool
    notes: str | None


class CardiometabolicRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    measurement_date: date = Field(
        ..., description="Fecha de toma de la muestra o medición"
    )
    systolic_bp: int | None = Field(
        default=None, ge=50, le=280, description="Presión sistólica en mmHg"
    )
    diastolic_bp: int | None = Field(
        default=None, ge=30, le=180, description="Presión diastólica en mmHg"
    )
    total_cholesterol_mg_dl: float | None = Field(
        default=None, ge=50.0, le=800.0, description="Colesterol total en mg/dL"
    )
    ldl_cholesterol_mg_dl: float | None = Field(
        default=None, ge=10.0, le=500.0, description="Colesterol LDL en mg/dL"
    )
    hdl_cholesterol_mg_dl: float | None = Field(
        default=None, ge=10.0, le=200.0, description="Colesterol HDL en mg/dL"
    )
    triglycerides_mg_dl: float | None = Field(
        default=None, ge=20.0, le=2000.0, description="Triglicéridos en mg/dL"
    )
    fasting_glucose_mg_dl: float | None = Field(
        default=None, ge=30.0, le=600.0, description="Glucosa en ayuno en mg/dL"
    )
    notes: str | None = Field(default=None, max_length=500)


class CardiometabolicResponse(BaseModel):
    id: uuid.UUID
    measurement_date: date
    systolic_bp: int | None
    diastolic_bp: int | None
    total_cholesterol_mg_dl: float | None
    ldl_cholesterol_mg_dl: float | None
    hdl_cholesterol_mg_dl: float | None
    triglycerides_mg_dl: float | None
    fasting_glucose_mg_dl: float | None
    risk_level: str
    flagged_parameters: list[str]
    notes: str | None


class VaginalBleedingRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    observation_date: date = Field(..., description="Fecha del sangrado")
    days_of_prior_amenorrhea: int = Field(
        ..., ge=0, description="Días previos transcurridos sin menstruación"
    )
    flow_intensity: str = Field(default="LIGHT", description="LIGHT | MEDIUM | HEAVY")
    has_cramping: bool = Field(
        default=False, description="Presencia de cólico o dolor pélvico"
    )
    notes: str | None = Field(default=None, max_length=500)


class VaginalBleedingResponse(BaseModel):
    observation_id: uuid.UUID
    is_alert_triggered: bool
    alert_code: str | None
    alert_severity: str | None
    alert_guidance: str | None


class DexaScanRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    scan_date: date = Field(..., description="Fecha del estudio DXA")
    anatomical_site: str = Field(
        ...,
        pattern="^(LUMBAR_SPINE|FEMORAL_NECK|TOTAL_HIP|DISTAL_RADIUS)$",
        description="Sitio anatómico explorado",
    )
    t_score: float = Field(
        ..., ge=-10.0, le=10.0, description="T-score del informe DXA"
    )
    z_score: float | None = Field(default=None, ge=-10.0, le=10.0)
    bmd_g_cm2: float | None = Field(
        default=None, ge=0.0, description="Densidad mineral en g/cm2"
    )
    previous_fragility_fracture: bool = Field(
        default=False,
        description="Antecedente de fractura por fragilidad previa",
    )
    notes: str | None = Field(default=None, max_length=500)


class DexaScanResponse(BaseModel):
    scan_id: uuid.UUID
    category: str
    t_score: float
    anatomical_site: str
    clinical_summary: str


class FallAssessmentRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    assessment_date: date = Field(..., description="Fecha de evaluación")
    falls_past_year: int = Field(
        ..., ge=0, description="Número de caídas en los últimos 12 meses"
    )
    has_gait_unsteadiness: bool = Field(
        default=False, description="Inestabilidad o balanceo al caminar"
    )
    uses_walking_aid: bool = Field(
        default=False, description="Uso de bastón, andador o apoyo"
    )
    timed_up_and_go_seconds: float | None = Field(
        default=None, ge=0.0, description="Segundos en prueba TUG"
    )
    environmental_hazards_identified: list[str] = Field(
        default_factory=list, description="Riesgos identificados en casa"
    )
    notes: str | None = Field(default=None, max_length=500)


class FallAssessmentResponse(BaseModel):
    assessment_id: uuid.UUID
    risk_level: str
    composite_score: int
    preventive_actions: list[str]


class PelvicLogRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    log_date: date = Field(..., description="Fecha de registro")
    incontinence_type: str = Field(
        ...,
        pattern="^(NONE|STRESS|URGE|MIXED|OVERFLOW)$",
        description="Tipo de incontinencia urinaria reportada",
    )
    daily_pad_count: int = Field(
        default=0, ge=0, description="Protectores o toallas utilizadas por día"
    )
    has_pelvic_heaviness: bool = Field(
        default=False, description="Sensación de peso pélvico o prolapso"
    )
    vaginal_dryness_level: int = Field(
        default=0, ge=0, le=3, description="Sequedad vaginal de 0 a 3"
    )
    has_dyspareunia: bool = Field(
        default=False, description="Molestia o dolor en relaciones sexuales"
    )
    notes: str | None = Field(default=None, max_length=500)


class PelvicLogResponse(BaseModel):
    log_id: uuid.UUID
    requires_urogynecology_consult: bool
    supportive_tips: list[str]


class SupportContactRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    contact_name: str = Field(..., min_length=1, max_length=128)
    relationship: str = Field(..., min_length=1, max_length=64)
    phone_number: str = Field(..., min_length=3, max_length=32)
    notes: str | None = Field(default=None, max_length=500)
    is_primary: bool = Field(default=True)


class SupportContactResponse(BaseModel):
    id: uuid.UUID
    contact_name: str
    relationship: str
    phone_number: str
    notes: str | None
    is_primary: bool


class MenopauseSummaryResponse(BaseModel):
    straw10_stage: str
    hot_flashes_count_last_30_days: int
    latest_cardiometabolic_risk_level: str | None
    active_alerts_count: int


class SeniorVitalitySummaryResponse(BaseModel):
    latest_bone_category: str | None
    latest_fall_risk_level: str | None
    has_fracture_alert: bool
    requires_urogynecology_consult: bool
    trusted_contact_name: str | None
    trusted_contact_phone: str | None
