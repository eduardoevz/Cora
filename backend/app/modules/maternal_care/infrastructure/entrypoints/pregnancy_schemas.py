import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class CreatePregnancyEpisodeRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    last_menstrual_period: date | None = Field(
        default=None,
        description="Fecha de la última menstruación (FUM) en formato YYYY-MM-DD",
    )
    ultrasound_edd: date | None = Field(
        default=None,
        description="Fecha probable de parto estimada por ecografía de 1er trimestre",
    )
    clinical_edd: date | None = Field(
        default=None,
        description="Fecha probable de parto clínica manual",
    )


class PregnancyEpisodeResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    clinical_edd: date
    last_menstrual_period: date | None = None
    ultrasound_edd: date | None = None
    is_active: bool
    started_at: datetime
    ended_at: datetime | None = None
    recalibration_history: list[dict[str, Any]] = Field(default_factory=list)


class FetalMilestoneResponse(BaseModel):
    week: int
    fruit_comparison: str
    approximate_length_cm: float
    approximate_weight_grams: float
    anatomical_highlights: str
    clinical_recommendations: str
    suggested_tests: list[str] = Field(default_factory=list)


class MaternalSymptomItem(BaseModel):
    model_config = ConfigDict(extra="forbid")

    symptom_type: str = Field(
        ...,
        description=(
            "persistent_severe_headache | scotomas_visual_blur | epigastric_ruq_pain | "
            "sudden_facial_hand_edema | nausea_vomiting | decreased_fetal_movement | "
            "vaginal_bleeding | amniotic_fluid_leak | pelvic_pressure"
        ),
    )
    notes: str | None = Field(default=None, max_length=255)


class MaternalAlertItem(BaseModel):
    severity: str
    category: str
    title: str
    message: str
    action_recommended: str


class MaternalVitalsResponse(BaseModel):
    id: uuid.UUID
    pregnancy_episode_id: uuid.UUID
    user_id: uuid.UUID
    measured_at: datetime
    gestational_weeks: int
    systolic_mmhg: int | None = None
    diastolic_mmhg: int | None = None
    glucose_mg_dl: Decimal | None = None
    glucose_timing: str | None = None
    weight_kg: Decimal | None = None
    symptoms: list[dict[str, Any]] = Field(default_factory=list)
    alerts: list[MaternalAlertItem] = Field(default_factory=list)
    created_at: datetime


class PregnancySummaryResponse(BaseModel):
    episode_id: uuid.UUID
    user_id: uuid.UUID
    clinical_edd: date
    last_menstrual_period: date | None = None
    ultrasound_edd: date | None = None
    gestational_weeks: int
    gestational_days: int
    gestational_age_formatted: str
    trimester: int
    days_to_edd: int
    milestone: FetalMilestoneResponse
    recent_vitals: list[dict[str, Any]] = Field(default_factory=list)


class LogMaternalVitalsRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    systolic_mmhg: int | None = Field(
        default=None, ge=60, le=260, description="Presión arterial sistólica en mmHg"
    )
    diastolic_mmhg: int | None = Field(
        default=None, ge=30, le=160, description="Presión arterial diastólica en mmHg"
    )
    glucose_mg_dl: Decimal | None = Field(
        default=None,
        ge=Decimal("30.0"),
        le=Decimal("600.0"),
        description="Glucosa capilar en mg/dL",
    )
    glucose_timing: str | None = Field(
        default=None,
        description="fasting | postprandial_1h | postprandial_2h | random",
    )
    weight_kg: Decimal | None = Field(
        default=None,
        ge=Decimal("30.0"),
        le=Decimal("250.0"),
        description="Peso materno en kg",
    )
    symptoms: list[MaternalSymptomItem] = Field(
        default_factory=list, description="Lista de síntomas percibidos"
    )
    measured_at: datetime | None = Field(
        default=None, description="Fecha y hora de la medición"
    )


class ContractionEventItem(BaseModel):
    model_config = ConfigDict(extra="forbid")

    started_at: str = Field(
        ..., description="Timestamp ISO-8601 del inicio de la contracción"
    )
    duration_seconds: int = Field(..., ge=5, le=300, description="Duración en segundos")
    intensity: str = Field(default="moderate", description="mild | moderate | strong")


class LogContractionSessionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    events: list[ContractionEventItem] = Field(..., min_length=1)
    ended_at: datetime | None = Field(default=None)


class ContractionSessionResponse(BaseModel):
    id: uuid.UUID
    pregnancy_episode_id: uuid.UUID
    started_at: datetime
    ended_at: datetime | None = None
    gestational_weeks: int
    pattern: str
    total_contractions: int
    avg_interval_seconds: Decimal | None = None
    avg_duration_seconds: Decimal | None = None
    events: list[dict[str, Any]] = Field(default_factory=list)
    alert: MaternalAlertItem | None = None
    assessment: dict[str, Any] | None = None
    created_at: datetime


class LogKickSessionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    kicks_count: int = Field(
        ..., ge=0, le=100, description="Número de patadas contadas"
    )
    duration_minutes: int = Field(
        ..., ge=1, le=240, description="Duración de la sesión en minutos"
    )
    target_reached_at_minutes: int | None = Field(
        default=None, description="Minuto en que se alcanzaron 10 movimientos"
    )
    started_at: datetime | None = Field(default=None)


class KickSessionResponse(BaseModel):
    id: uuid.UUID
    pregnancy_episode_id: uuid.UUID
    started_at: datetime
    duration_minutes: int
    gestational_weeks: int
    kicks_count: int
    target_reached: bool
    target_reached_at_minutes: int | None = None
    is_reassuring: bool
    alert: MaternalAlertItem | None = None
    created_at: datetime


class BirthPlanRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    companion_preferences: list[str] = Field(default_factory=list)
    pain_management: list[str] = Field(default_factory=list)
    delivery_environment: list[str] = Field(default_factory=list)
    immediate_postpartum: list[str] = Field(default_factory=list)
    special_requests: str | None = Field(default=None, max_length=1000)


class BirthPlanResponse(BaseModel):
    companion_preferences: list[str] = Field(default_factory=list)
    pain_management: list[str] = Field(default_factory=list)
    delivery_environment: list[str] = Field(default_factory=list)
    immediate_postpartum: list[str] = Field(default_factory=list)
    special_requests: str | None = None


class CreatePrenatalAppointmentRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    scheduled_at: datetime = Field(...)
    doctor_or_clinic: str = Field(..., max_length=255)
    gestational_week: int = Field(..., ge=4, le=42)
    topics_to_discuss: list[str] = Field(default_factory=list)
    notes: str | None = Field(default=None, max_length=1000)


class ToggleAppointmentRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    is_completed: bool = Field(...)


class PrenatalAppointmentResponse(BaseModel):
    id: uuid.UUID
    pregnancy_episode_id: uuid.UUID
    scheduled_at: datetime
    doctor_or_clinic: str
    gestational_week: int
    topics_to_discuss: list[str] = Field(default_factory=list)
    notes: str | None = None
    is_completed: bool
