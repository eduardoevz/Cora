from dataclasses import dataclass, field
from datetime import date

from app.modules.clinical_tracking.domain.models.menstrual_cycle import (
    MenstrualCycle,
)
from app.modules.clinical_tracking.domain.services import (
    ClinicalPatternAlert,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    BleedingFlow,
    CycleStatusSnapshot,
)


@dataclass(frozen=True)
class LogSymptomDTO:
    """Input payload for logging daily bleeding and cycle symptoms."""

    log_date: date
    bleeding_flow: BleedingFlow = BleedingFlow.NONE
    pelvic_pain: int | None = None
    dysmenorrhea: int | None = None
    dyspareunia: bool | None = None
    acne_severity: int | None = None
    hirsutism: bool | None = None
    fatigue_level: int | None = None
    gi_symptoms: list[str] = field(default_factory=list)
    notes: str | None = None


@dataclass(frozen=True)
class CycleOverviewDTO:
    """Aggregated clinical cycle overview, predictions, and FIGO alerts."""

    current_cycle: MenstrualCycle | None
    status: CycleStatusSnapshot
    alerts: list[ClinicalPatternAlert]
    recent_cycles: list[MenstrualCycle]
