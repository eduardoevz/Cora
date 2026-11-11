from dataclasses import dataclass
from datetime import date, datetime
from uuid import UUID

from app.modules.identity.domain.value_objects.life_stage import LifeStage


@dataclass(frozen=True)
class CycleReportSummary:
    total_cycles_logged: int
    average_length_days: float
    min_length_days: int
    max_length_days: int
    variability_days: int
    is_regular: bool
    atypical_alerts_detected: list[str]
    last_period_date: date | None = None


@dataclass(frozen=True)
class TreatmentAdherenceItem:
    medication_name: str
    dosage: str
    frequency: str
    adherence_percentage: float
    status: str


@dataclass(frozen=True)
class VitalsReportSummary:
    latest_blood_pressure: str
    mean_systolic: int | None
    mean_diastolic: int | None
    fasting_glucose_mg_dl: float | None
    bmi: float | None
    weight_kg: float | None


@dataclass(frozen=True)
class DoctorReportData:
    user_id: UUID
    patient_name: str
    patient_age: int
    life_stage: LifeStage
    generated_at: datetime
    reporting_window_months: int
    cycle_summary: CycleReportSummary | None
    treatment_summary: list[TreatmentAdherenceItem]
    vitals_summary: VitalsReportSummary | None
    stage_specific_notes: list[str]
    specialist_notes: str | None
