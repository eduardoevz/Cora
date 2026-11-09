from dataclasses import dataclass
from datetime import date, datetime, time
from decimal import Decimal


@dataclass(frozen=True)
class LogFertilityDailyDTO:
    log_date: date
    bbt_celsius: Decimal | None = None
    is_disturbed: bool = False
    disturbance_reason: str | None = None
    measured_at_time: time | None = None
    cervical_mucus: str | None = None
    lh_result: str | None = None
    intercourse_had: bool = False
    intercourse_type: str = "none"
    notes: str | None = None


@dataclass(frozen=True)
class FertilityChartEntryDTO:
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


@dataclass(frozen=True)
class FertilityCycleChartDTO:
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
    daily_entries: list[FertilityChartEntryDTO]


@dataclass(frozen=True)
class PreconceptionChecklistDTO:
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


@dataclass(frozen=True)
class UpdatePreconceptionChecklistDTO:
    taking_folic_acid: bool | None = None
    folic_acid_dose_mcg: int | None = None
    medical_checkup_done: bool | None = None
    rubella_immunity_checked: bool | None = None
    dental_checkup_done: bool | None = None
    toxic_habits_stopped: bool | None = None
    partner_evaluation_planned: bool | None = None
    active_seeking_months: int | None = None
