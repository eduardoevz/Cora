from datetime import date, datetime, time
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class DailyFertilityLogRequest(BaseModel):
    """Payload for logging or updating daily fertility observations."""

    model_config = ConfigDict(extra="forbid")

    bbt_celsius: Decimal | None = Field(
        default=None,
        ge=Decimal("35.00"),
        le=Decimal("42.00"),
        description="Temperatura basal en grados Celsius (35.00 - 42.00)",
    )
    is_disturbed: bool = Field(
        default=False,
        description="Indica si la medición fue perturbada (fiebre, insomnio, alcohol)",
    )
    disturbance_reason: str | None = Field(
        default=None,
        max_length=128,
        description="Motivo clínico o conductual de perturbación",
    )
    measured_at_time: time | None = Field(
        default=None,
        description="Hora matutina de la toma de temperatura",
    )
    cervical_mucus: str | None = Field(
        default=None,
        description="dry | sticky | creamy | watery | egg_white",
    )
    lh_result: str | None = Field(
        default=None,
        description="negative | high | peak",
    )
    intercourse_had: bool = Field(
        default=False,
        description="Indica si hubo actividad sexual o inseminación",
    )
    intercourse_type: str = Field(
        default="none",
        description="none | unprotected | protected | insemination",
    )
    notes: str | None = Field(
        default=None,
        max_length=500,
        description="Notas clínicas u observaciones",
    )


class DailyFertilityLogResponse(BaseModel):
    """Daily fertility log response representation."""

    model_config = ConfigDict(from_attributes=True)

    log_date: date
    bbt_celsius: Decimal | None
    bbt_fahrenheit: Decimal | None
    is_disturbed: bool
    disturbance_reason: str | None
    measured_at_time: time | None
    cervical_mucus: str | None
    lh_result: str | None
    intercourse_had: bool
    intercourse_type: str
    notes: str | None


class FertilityChartEntryResponse(BaseModel):
    """Single point in the cycle fertility chart."""

    model_config = ConfigDict(from_attributes=True)

    log_date: date
    cycle_day: int
    bbt_celsius: Decimal | None
    bbt_fahrenheit: Decimal | None
    is_disturbed: bool
    disturbance_reason: str | None
    cervical_mucus: str | None
    lh_result: str | None
    intercourse_had: bool
    intercourse_type: str


class FertilityCycleChartResponse(BaseModel):
    """Biphasic temperature chart, coverline, and symptothermal evaluation."""

    model_config = ConfigDict(from_attributes=True)

    cycle_id: str | None
    cycle_start_date: date | None
    cycle_day: int | None
    status: str
    coverline_celsius: Decimal | None
    coverline_fahrenheit: Decimal | None
    ovulation_confirmed_date: date | None
    fertile_window_start: date | None
    fertile_window_end: date | None
    is_biphasic_shift_detected: bool
    evaluation_notes_es: str
    active_seeking_guidance_es: str | None
    daily_entries: list[FertilityChartEntryResponse]


class PreconceptionChecklistResponse(BaseModel):
    """Preconception clinical recommendations checklist and adherence score."""

    model_config = ConfigDict(from_attributes=True)

    user_id: str
    taking_folic_acid: bool
    folic_acid_dose_mcg: int | None
    is_folic_acid_adequate: bool
    medical_checkup_done: bool
    rubella_immunity_checked: bool
    dental_checkup_done: bool
    toxic_habits_stopped: bool
    partner_evaluation_planned: bool
    active_seeking_months: int
    completion_percentage: int
    updated_at: datetime


class UpdatePreconceptionChecklistRequest(BaseModel):
    """Partial update payload for preconception checklist."""

    model_config = ConfigDict(extra="forbid")

    taking_folic_acid: bool | None = None
    folic_acid_dose_mcg: int | None = Field(default=None, ge=100, le=5000)
    medical_checkup_done: bool | None = None
    rubella_immunity_checked: bool | None = None
    dental_checkup_done: bool | None = None
    toxic_habits_stopped: bool | None = None
    partner_evaluation_planned: bool | None = None
    active_seeking_months: int | None = Field(default=None, ge=0, le=120)
