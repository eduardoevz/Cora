from dataclasses import dataclass, field
from datetime import UTC, date, datetime
from uuid import uuid4

from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    BleedingFlow,
    PelvicPainScore,
)


@dataclass(frozen=True)
class MenstrualCycle:
    """Longitudinal menstrual cycle aggregate spanning from Day 1 of bleeding.

    Ends the day before the next bleeding starts.
    """

    id: str
    user_id: str
    start_date: date
    end_date: date | None = None
    cycle_length_days: int | None = None
    bleeding_duration_days: int | None = None
    is_current: bool = True
    created_at: datetime = field(default_factory=lambda: datetime.now(UTC))
    updated_at: datetime = field(default_factory=lambda: datetime.now(UTC))

    @classmethod
    def create(
        cls,
        user_id: str,
        start_date: date,
        end_date: date | None = None,
        cycle_length_days: int | None = None,
        bleeding_duration_days: int | None = None,
        is_current: bool = True,
        cycle_id: str | None = None,
    ) -> "MenstrualCycle":
        now = datetime.now(UTC)
        if end_date is not None and cycle_length_days is None:
            cycle_length_days = (end_date - start_date).days + 1

        return cls(
            id=cycle_id or str(uuid4()),
            user_id=user_id,
            start_date=start_date,
            end_date=end_date,
            cycle_length_days=cycle_length_days,
            bleeding_duration_days=bleeding_duration_days,
            is_current=is_current,
            created_at=now,
            updated_at=now,
        )

    def close(self, end_date: date) -> "MenstrualCycle":
        """Closes the cycle when a subsequent cycle begins."""
        now = datetime.now(UTC)
        length = (end_date - self.start_date).days + 1
        return MenstrualCycle(
            id=self.id,
            user_id=self.user_id,
            start_date=self.start_date,
            end_date=end_date,
            cycle_length_days=length,
            bleeding_duration_days=self.bleeding_duration_days,
            is_current=False,
            created_at=self.created_at,
            updated_at=now,
        )


@dataclass(frozen=True)
class CycleSymptomLog:
    """Daily somatic and gynecological symptom entry associated with a cycle."""

    id: str
    user_id: str
    log_date: date
    cycle_id: str | None = None
    bleeding_flow: BleedingFlow = BleedingFlow.NONE
    pelvic_pain: int | None = None
    dysmenorrhea: int | None = None
    dyspareunia: bool | None = None
    acne_severity: int | None = None
    hirsutism: bool | None = None
    fatigue_level: int | None = None
    gi_symptoms: list[str] = field(default_factory=list)
    notes: str | None = None
    created_at: datetime = field(default_factory=lambda: datetime.now(UTC))
    updated_at: datetime = field(default_factory=lambda: datetime.now(UTC))

    def __post_init__(self) -> None:
        if self.pelvic_pain is not None:
            PelvicPainScore(self.pelvic_pain)
        if self.dysmenorrhea is not None:
            PelvicPainScore(self.dysmenorrhea)

    @classmethod
    def create(
        cls,
        user_id: str,
        log_date: date,
        cycle_id: str | None = None,
        bleeding_flow: BleedingFlow = BleedingFlow.NONE,
        pelvic_pain: int | None = None,
        dysmenorrhea: int | None = None,
        dyspareunia: bool | None = None,
        acne_severity: int | None = None,
        hirsutism: bool | None = None,
        fatigue_level: int | None = None,
        gi_symptoms: list[str] | None = None,
        notes: str | None = None,
        log_id: str | None = None,
    ) -> "CycleSymptomLog":
        now = datetime.now(UTC)
        return cls(
            id=log_id or str(uuid4()),
            user_id=user_id,
            log_date=log_date,
            cycle_id=cycle_id,
            bleeding_flow=bleeding_flow,
            pelvic_pain=pelvic_pain,
            dysmenorrhea=dysmenorrhea,
            dyspareunia=dyspareunia,
            acne_severity=acne_severity,
            hirsutism=hirsutism,
            fatigue_level=fatigue_level,
            gi_symptoms=gi_symptoms or [],
            notes=notes,
            created_at=now,
            updated_at=now,
        )
