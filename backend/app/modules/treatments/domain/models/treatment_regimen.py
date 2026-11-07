from dataclasses import dataclass, field
from datetime import UTC, date, datetime
from enum import StrEnum
from uuid import uuid4

from app.modules.treatments.domain.value_objects.dosage_schedule import (
    DosageSchedule,
    TreatmentCategory,
)


class IntakeStatus(StrEnum):
    """Clinical status of a scheduled treatment dose."""

    TAKEN = "taken"
    MISSED = "missed"
    SKIPPED = "skipped"
    DELAYED = "delayed"


@dataclass(frozen=True)
class TreatmentRegimen:
    """Therapeutic medication or supplementation regimen aggregate."""

    id: str
    user_id: str
    name: str
    category: TreatmentCategory
    dosage: str
    schedule: DosageSchedule
    start_date: date
    end_date: date | None = None
    instructions: str | None = None
    reminder_enabled: bool = True
    discreet_notification: bool = True
    is_active: bool = True
    created_at: datetime = field(default_factory=lambda: datetime.now(UTC))
    updated_at: datetime = field(default_factory=lambda: datetime.now(UTC))

    @classmethod
    def create(
        cls,
        user_id: str,
        name: str,
        category: TreatmentCategory,
        dosage: str,
        schedule: DosageSchedule,
        start_date: date,
        end_date: date | None = None,
        instructions: str | None = None,
        reminder_enabled: bool = True,
        discreet_notification: bool = True,
        regimen_id: str | None = None,
    ) -> "TreatmentRegimen":
        now = datetime.now(UTC)
        return cls(
            id=regimen_id or str(uuid4()),
            user_id=user_id,
            name=name,
            category=category,
            dosage=dosage,
            schedule=schedule,
            start_date=start_date,
            end_date=end_date,
            instructions=instructions,
            reminder_enabled=reminder_enabled,
            discreet_notification=discreet_notification,
            is_active=True,
            created_at=now,
            updated_at=now,
        )


@dataclass(frozen=True)
class DoseIntakeLog:
    """Historical intake event of a scheduled medication dose."""

    id: str
    regimen_id: str
    scheduled_for: datetime
    taken_at: datetime | None = None
    status: IntakeStatus = IntakeStatus.TAKEN
    notes: str | None = None
    client_mutation_id: str | None = None
    user_id: str | None = None
    created_at: datetime = field(default_factory=lambda: datetime.now(UTC))

    @classmethod
    def create(
        cls,
        regimen_id: str,
        user_id: str | None = None,
        scheduled_for: datetime | None = None,
        taken_at: datetime | None = None,
        status: IntakeStatus = IntakeStatus.TAKEN,
        notes: str | None = None,
        client_mutation_id: str | None = None,
        intake_id: str | None = None,
    ) -> "DoseIntakeLog":
        if scheduled_for is None:
            scheduled_for = datetime.now(UTC)
        return cls(
            id=intake_id or str(uuid4()),
            regimen_id=regimen_id,
            user_id=user_id,
            scheduled_for=scheduled_for,
            taken_at=taken_at,
            status=status,
            notes=notes,
            client_mutation_id=client_mutation_id,
            created_at=datetime.now(UTC),
        )
