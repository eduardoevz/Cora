from dataclasses import dataclass, field
from datetime import datetime


@dataclass(frozen=True)
class RecordPostpartumRecoveryDTO:
    days_postpartum: int
    lochia_stage: str
    lochia_flow: str
    foul_odor: bool = False
    maternal_temperature_c: float | None = None
    perineal_wound_status: str | None = None
    cesarean_wound_status: str | None = None
    pelvic_floor_symptoms: list[str] = field(default_factory=list)
    notes: str | None = None


@dataclass(frozen=True)
class LogLactationSessionDTO:
    started_at: datetime
    ended_at: datetime
    left_duration_seconds: int = 0
    right_duration_seconds: int = 0
    last_offered_breast: str = "none"
    bottle_volume_ml: float | None = None
    feeding_type: str = "breast_only"
    notes: str | None = None


@dataclass(frozen=True)
class AddMilkStashDTO:
    pumped_at: datetime
    volume_ml: float
    storage_location: str = "refrigerator"
    notes: str | None = None


@dataclass(frozen=True)
class EvaluateEpdsScreeningDTO:
    days_postpartum: int
    responses: dict[str, int]
