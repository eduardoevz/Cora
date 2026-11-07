from dataclasses import dataclass


@dataclass(frozen=True)
class CreateTreatmentRegimenDTO:
    """Input DTO for creating a new treatment or medication regimen."""

    name: str
    category: str
    dosage: str
    schedule_type: str
    scheduled_time: str
    start_date: str
    end_date: str | None = None
    active_days: int | None = None
    break_days: int | None = None
    interval_days: int | None = None
    replacement_date: str | None = None
    instructions: str | None = None
    reminder_enabled: bool = True
    discreet_notification: bool = True


@dataclass(frozen=True)
class LogDoseIntakeDTO:
    """Input DTO for recording an individual dose intake event."""

    scheduled_for: str
    taken_at: str | None = None
    status: str = "taken"
    notes: str | None = None
    client_mutation_id: str | None = None


@dataclass(frozen=True)
class TreatmentRegimenDTO:
    """Output DTO representing a configured treatment regimen."""

    id: str
    user_id: str
    name: str
    category: str
    dosage: str
    schedule_type: str
    scheduled_time: str
    start_date: str
    end_date: str | None
    active_days: int | None
    break_days: int | None
    interval_days: int | None
    replacement_date: str | None
    reminder_enabled: bool
    discreet_notification: bool
    is_active: bool
    created_at: str
    updated_at: str


@dataclass(frozen=True)
class DoseIntakeDTO:
    """Output DTO representing a logged intake event."""

    id: str
    regimen_id: str
    user_id: str
    scheduled_for: str
    taken_at: str | None
    status: str
    notes: str | None
    created_at: str


@dataclass(frozen=True)
class AdherenceSummaryDTO:
    """Output DTO summarizing treatment adherence performance."""

    regimen_id: str
    scheduled_doses: int
    taken_doses: int
    missed_doses: int
    delayed_doses: int
    adherence_percentage: float
