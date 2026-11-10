from dataclasses import dataclass, field
from datetime import date, datetime
from decimal import Decimal
from typing import Any


@dataclass(frozen=True)
class CreatePregnancyEpisodeDTO:
    last_menstrual_period: date | None = None
    ultrasound_edd: date | None = None
    clinical_edd: date | None = None


@dataclass(frozen=True)
class LogMaternalVitalsDTO:
    systolic_mmhg: int | None = None
    diastolic_mmhg: int | None = None
    glucose_mg_dl: Decimal | None = None
    glucose_timing: str | None = None
    weight_kg: Decimal | None = None
    symptoms: list[dict[str, Any]] = field(default_factory=list)
    measured_at: datetime | None = None


@dataclass(frozen=True)
class LogContractionSessionDTO:
    events: list[dict[str, Any]]
    ended_at: datetime | None = None


@dataclass(frozen=True)
class LogKickSessionDTO:
    kicks_count: int
    duration_minutes: int
    target_reached_at_minutes: int | None = None
    started_at: datetime | None = None


@dataclass(frozen=True)
class SaveBirthPlanDTO:
    companion_preferences: list[str] = field(default_factory=list)
    pain_management: list[str] = field(default_factory=list)
    delivery_environment: list[str] = field(default_factory=list)
    immediate_postpartum: list[str] = field(default_factory=list)
    special_requests: str | None = None


@dataclass(frozen=True)
class CreatePrenatalAppointmentDTO:
    scheduled_at: datetime
    doctor_or_clinic: str
    gestational_week: int
    topics_to_discuss: list[str] = field(default_factory=list)
    notes: str | None = None


@dataclass(frozen=True)
class ToggleAppointmentDTO:
    is_completed: bool
