from dataclasses import dataclass
from datetime import date, datetime
from uuid import UUID

from app.modules.medical_records.domain.value_objects.record_metadata import (
    AttachmentSpec,
    ExamType,
    ScreeningUrgency,
    SpecialtyType,
    VaccineType,
)


@dataclass
class MedicalExamRecord:
    id: UUID
    user_id: UUID
    exam_type: ExamType
    title: str
    performed_at: date
    clinic_or_lab: str | None
    notes: str | None
    attachment: AttachmentSpec | None
    created_at: datetime
    updated_at: datetime


@dataclass
class VaccinationEntry:
    id: UUID
    user_id: UUID
    vaccine_type: VaccineType
    dose_number: int
    administered_at: date
    lot_number: str | None
    administrator_clinic: str | None
    notes: str | None
    created_at: datetime


@dataclass
class SpecialistContact:
    id: UUID
    user_id: UUID
    full_name: str
    specialty: SpecialtyType
    clinic_name: str | None
    phone_number: str | None
    email: str | None
    notes: str | None
    is_favorite: bool
    created_at: datetime


@dataclass(frozen=True)
class PreventiveScreeningItem:
    screening_code: str
    title: str
    description: str
    recommended_age_range: str
    frequency_guideline: str
    urgency: ScreeningUrgency
    last_performed_at: date | None = None
    due_date: date | None = None
