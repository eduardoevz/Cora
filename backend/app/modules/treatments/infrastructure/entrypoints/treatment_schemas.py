from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.modules.treatments.domain.models.treatment_regimen import (
    DoseIntakeLog,
    TreatmentRegimen,
)
from app.modules.treatments.domain.services.adherence_and_missed_dose_service import (
    AdherenceSummary,
    IntakeAssessment,
    LarcAlert,
)


class CreateTreatmentRegimenRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    category: str = Field(
        ...,
        description=(
            "contraceptive_oral_combined, contraceptive_progestin_only, patch, "
            "injectable, larc_iud_implant, hrt, supplement, chronic_medication"
        ),
    )
    dosage: str = Field(..., min_length=1, max_length=100)
    schedule_type: str = Field(
        ...,
        description=(
            "daily_fixed, cyclic_active_break, interval_days, long_acting_replacement"
        ),
    )
    scheduled_time: str = Field(..., pattern=r"^\d{2}:\d{2}$")
    start_date: date
    end_date: date | None = None
    active_days: int | None = None
    break_days: int | None = None
    interval_days: int | None = None
    replacement_date: date | None = None
    instructions: str | None = None


class TreatmentRegimenResponse(BaseModel):
    id: UUID
    user_id: UUID
    name: str
    category: str
    dosage: str
    schedule_type: str
    scheduled_time: str
    active_days: int | None = None
    break_days: int | None = None
    interval_days: int | None = None
    replacement_date: date | None = None
    instructions: str | None = None
    start_date: date
    end_date: date | None = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    @classmethod
    def from_domain(cls, domain: TreatmentRegimen) -> "TreatmentRegimenResponse":
        return cls(
            id=UUID(domain.id),
            user_id=UUID(domain.user_id),
            name=domain.name,
            category=domain.category.value,
            dosage=domain.dosage,
            schedule_type=domain.schedule.schedule_type.value,
            scheduled_time=domain.schedule.scheduled_time,
            active_days=domain.schedule.active_days,
            break_days=domain.schedule.break_days,
            interval_days=domain.schedule.interval_days,
            replacement_date=domain.schedule.replacement_date,
            instructions=domain.instructions,
            start_date=domain.start_date,
            end_date=domain.end_date,
            is_active=domain.is_active,
            created_at=domain.created_at,
            updated_at=domain.updated_at,
        )


class LogDoseIntakeRequest(BaseModel):
    regimen_id: UUID
    scheduled_for: datetime
    taken_at: datetime | None = None
    status: str = "taken"
    notes: str | None = None
    client_mutation_id: UUID | None = None


class IntakeAssessmentResponse(BaseModel):
    status: str
    delay_hours: float
    is_critical_missed_dose: bool
    requires_backup_contraception: bool
    guidance_message: str | None = None

    @classmethod
    def from_domain(cls, domain: IntakeAssessment) -> "IntakeAssessmentResponse":
        return cls(
            status=domain.status.value,
            delay_hours=domain.delay_hours,
            is_critical_missed_dose=domain.is_critical_missed_dose,
            requires_backup_contraception=domain.requires_backup_contraception,
            guidance_message=domain.guidance_message,
        )


class DoseIntakeLogResponse(BaseModel):
    id: UUID
    regimen_id: UUID
    scheduled_for: datetime
    taken_at: datetime | None = None
    status: str
    notes: str | None = None
    client_mutation_id: UUID | None = None
    assessment: IntakeAssessmentResponse
    created_at: datetime

    @classmethod
    def from_domain(
        cls, domain: DoseIntakeLog, assessment: IntakeAssessment
    ) -> "DoseIntakeLogResponse":
        return cls(
            id=UUID(domain.id),
            regimen_id=UUID(domain.regimen_id),
            scheduled_for=domain.scheduled_for,
            taken_at=domain.taken_at,
            status=domain.status.value,
            notes=domain.notes,
            client_mutation_id=UUID(domain.client_mutation_id)
            if domain.client_mutation_id
            else None,
            assessment=IntakeAssessmentResponse.from_domain(assessment),
            created_at=domain.created_at,
        )


class AdherenceSummaryResponse(BaseModel):
    regimen_id: UUID
    scheduled_doses: int
    taken_doses: int
    delayed_doses: int
    missed_doses: int
    adherence_percentage: float

    @classmethod
    def from_domain(cls, domain: AdherenceSummary) -> "AdherenceSummaryResponse":
        return cls(
            regimen_id=UUID(domain.regimen_id),
            scheduled_doses=domain.scheduled_doses,
            taken_doses=domain.taken_doses,
            delayed_doses=domain.delayed_doses,
            missed_doses=domain.missed_doses,
            adherence_percentage=domain.adherence_percentage,
        )


class LarcAlertResponse(BaseModel):
    alert_level: str
    days_remaining: int
    message: str

    @classmethod
    def from_domain(cls, domain: LarcAlert) -> "LarcAlertResponse":
        return cls(
            alert_level=domain.alert_level.value,
            days_remaining=domain.days_remaining,
            message=domain.message,
        )
