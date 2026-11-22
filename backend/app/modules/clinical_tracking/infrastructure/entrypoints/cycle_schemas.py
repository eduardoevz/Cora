from datetime import date, datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field

from app.modules.clinical_tracking.domain.services import (
    AlertSeverity,
    FigoAlertType,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    BleedingFlow,
    CalendarDayMarker,
    CalendarDisplayMode,
    CyclePhase,
    FertilityProbability,
)
from app.modules.identity.domain.value_objects.onboarding_context import (
    CycleRegularity,
)


class LogBleedingAndSymptomsRequest(BaseModel):
    """Payload to log bleeding flow and associated somatic symptoms."""

    model_config = ConfigDict(extra="forbid")

    log_date: date = Field(..., description="Date of the symptom record")
    bleeding_flow: BleedingFlow = Field(
        default=BleedingFlow.NONE,
        description="Flow intensity: none, spotting, light, medium, heavy",
    )
    pelvic_pain: int | None = Field(
        None, ge=0, le=10, description="Pelvic pain score on 0-10 scale"
    )
    dysmenorrhea: int | None = Field(
        None, ge=0, le=10, description="Menstrual cramps score on 0-10 scale"
    )
    dyspareunia: bool | None = Field(
        None, description="Pain during intercourse if applicable"
    )
    acne_severity: int | None = Field(
        None, ge=0, le=10, description="Acne breakout severity 0-10"
    )
    hirsutism: bool | None = Field(
        None, description="Presence of excess hair or androgenic signs"
    )
    fatigue_level: int | None = Field(
        None, ge=0, le=10, description="Fatigue level 0-10"
    )
    gi_symptoms: list[str] = Field(
        default_factory=list,
        description="Gastrointestinal symptoms (e.g. bloating, nausea)",
    )
    notes: str | None = Field(
        None, max_length=500, description="Optional brief clinical note"
    )


class CycleSymptomLogResponse(BaseModel):
    """Response model for a recorded cycle symptom log."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    cycle_id: str | None = None
    log_date: date
    bleeding_flow: BleedingFlow
    pelvic_pain: int | None = None
    dysmenorrhea: int | None = None
    dyspareunia: bool | None = None
    acne_severity: int | None = None
    hirsutism: bool | None = None
    fatigue_level: int | None = None
    gi_symptoms: list[str] = Field(default_factory=list)
    notes: str | None = None
    created_at: datetime
    updated_at: datetime


class MenstrualCycleResponse(BaseModel):
    """Response model for a menstrual cycle aggregate."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    start_date: date
    end_date: date | None = None
    cycle_length_days: int | None = None
    bleeding_duration_days: int | None = None
    is_current: bool
    created_at: datetime
    updated_at: datetime


class CycleStatusResponse(BaseModel):
    """Detailed biological cycle status, 4-phase calculation, and predictions."""

    current_cycle_id: str | None = None
    day_in_cycle: int | None = None
    current_phase: CyclePhase
    predicted_next_period: date | None = None
    fertile_window_start: date | None = None
    fertile_window_end: date | None = None
    ovulation_date: date | None = None
    is_hormonally_managed: bool
    has_extended_uncertainty: bool
    phase_description_es: str
    daily_tip_es: str


class ClinicalPatternAlertResponse(BaseModel):
    """Preventative FIGO alert or clinical finding."""

    alert_type: FigoAlertType
    severity: AlertSeverity
    title_es: str
    description_es: str
    recommendation_es: str
    evidence: dict[str, Any] = Field(default_factory=dict)


class CycleOverviewResponse(BaseModel):
    """Comprehensive cycle overview with status, FIGO alerts, and history."""

    current_cycle: MenstrualCycleResponse | None = None
    status: CycleStatusResponse
    alerts: list[ClinicalPatternAlertResponse]
    recent_cycles: list[MenstrualCycleResponse]


class InitialPeriodInput(BaseModel):
    """Start and end date range for an initial historical menstrual period."""

    model_config = ConfigDict(extra="forbid")

    start_date: date = Field(..., description="First day of bleeding")
    end_date: date = Field(..., description="Last day of bleeding")


class SeedInitialPeriodsRequest(BaseModel):
    """Payload to seed up to 2 historical initial periods and baseline metrics."""

    model_config = ConfigDict(extra="forbid")

    periods: list[InitialPeriodInput] = Field(
        ...,
        min_length=1,
        max_length=2,
        description="Up to 2 historical periods (start and end dates)",
    )
    cycle_regularity: CycleRegularity | None = Field(
        default=None,
        description="Optional self-reported cycle regularity update",
    )
    typical_cycle_length_days: int | None = Field(
        default=None,
        ge=15,
        le=90,
        description="Optional typical cycle length override in days (15-90)",
    )
    typical_bleeding_duration_days: int | None = Field(
        default=None,
        ge=1,
        le=15,
        description="Optional typical bleeding duration override in days (1-15)",
    )


class CalendarDayProjectionResponse(BaseModel):
    """Single day projection inside the monthly menstrual calendar."""

    date: date
    day_in_cycle: int | None = None
    phase: CyclePhase | None = None
    day_marker: CalendarDayMarker
    fertility_probability: FertilityProbability
    has_logged_symptoms: bool
    bleeding_flow: BleedingFlow
    pelvic_pain: int | None = None
    daily_summary_es: str
    phase_education_es: str


class CalendarMonthProjectionResponse(BaseModel):
    """Full monthly projection adapted to life stage and cycle history."""

    year: int
    month: int
    display_mode: CalendarDisplayMode
    estimated_cycle_length_days: int
    estimated_bleeding_duration_days: int
    is_hormonally_managed: bool
    has_extended_uncertainty: bool
    current_cycle_day: int | None = None
    current_phase: CyclePhase | None = None
    predicted_next_period: date | None = None
    ovulation_date: date | None = None
    fertile_window_start: date | None = None
    fertile_window_end: date | None = None
    days: list[CalendarDayProjectionResponse]
