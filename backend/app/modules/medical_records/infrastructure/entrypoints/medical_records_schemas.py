from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.modules.medical_records.domain.value_objects.record_metadata import (
    ExamType,
    ScreeningUrgency,
    SpecialtyType,
    VaccineType,
)


class AttachmentSpecSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    file_name: str
    mime_type: str
    size_bytes: int
    storage_key: str


class MedicalExamRequest(BaseModel):
    exam_type: ExamType
    title: str = Field(..., min_length=2, max_length=200)
    performed_at: date
    clinic_or_lab: str | None = Field(None, max_length=200)
    notes: str | None = None


class MedicalExamResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    exam_type: ExamType
    title: str
    performed_at: date
    clinic_or_lab: str | None = None
    notes: str | None = None
    attachment: AttachmentSpecSchema | None = None
    created_at: datetime
    updated_at: datetime


class RequestUploadUrlRequest(BaseModel):
    file_name: str = Field(..., min_length=1, max_length=255)
    mime_type: str = Field(..., min_length=3, max_length=100)
    size_bytes: int = Field(..., gt=0, le=15 * 1024 * 1024)


class PresignedUploadUrlResponseSchema(BaseModel):
    upload_url: str
    storage_key: str
    expires_in_seconds: int
    required_headers: dict[str, str] = Field(default_factory=dict)


class PresignedDownloadUrlResponseSchema(BaseModel):
    download_url: str
    expires_in_seconds: int = 900


class PreventiveScreeningItemSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    screening_code: str
    title: str
    description: str
    recommended_age_range: str
    frequency_guideline: str
    urgency: ScreeningUrgency
    last_performed_at: date | None = None
    due_date: date | None = None


class PreventiveCalendarResponse(BaseModel):
    screenings: list[PreventiveScreeningItemSchema]


class VaccinationEntryRequest(BaseModel):
    vaccine_type: VaccineType
    dose_number: int = Field(..., ge=1, le=10)
    administered_at: date
    lot_number: str | None = Field(None, max_length=100)
    administrator_clinic: str | None = Field(None, max_length=200)
    notes: str | None = None


class VaccinationEntryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    vaccine_type: VaccineType
    dose_number: int
    administered_at: date
    lot_number: str | None = None
    administrator_clinic: str | None = None
    notes: str | None = None
    created_at: datetime


class SpecialistContactRequest(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=150)
    specialty: SpecialtyType
    clinic_name: str | None = Field(None, max_length=200)
    phone_number: str | None = Field(None, max_length=50)
    email: str | None = Field(None, max_length=150)
    notes: str | None = None
    is_favorite: bool = False


class SpecialistContactResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    full_name: str
    specialty: SpecialtyType
    clinic_name: str | None = None
    phone_number: str | None = None
    email: str | None = None
    notes: str | None = None
    is_favorite: bool = False
    created_at: datetime


class DoctorReportPdfRequest(BaseModel):
    reporting_window_months: int = Field(6, ge=1, le=24)
    specialist_notes: str | None = Field(None, max_length=1000)
