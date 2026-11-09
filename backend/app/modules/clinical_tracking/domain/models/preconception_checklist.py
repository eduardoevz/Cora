from dataclasses import dataclass, field
from datetime import UTC, datetime


@dataclass(frozen=True)
class PreconceptionChecklist:
    """Checklist of evidence-based clinical recommendations for healthy conception."""

    user_id: str
    taking_folic_acid: bool = False
    folic_acid_dose_mcg: int | None = 400
    medical_checkup_done: bool = False
    rubella_immunity_checked: bool = False
    dental_checkup_done: bool = False
    toxic_habits_stopped: bool = False
    partner_evaluation_planned: bool = False
    active_seeking_months: int = 0
    updated_at: datetime = field(default_factory=lambda: datetime.now(UTC))

    @property
    def is_folic_acid_adequate(self) -> bool:
        """WHO / ACOG recommendation: >= 400 mcg daily before conception."""
        if not self.taking_folic_acid:
            return False
        return self.folic_acid_dose_mcg is None or self.folic_acid_dose_mcg >= 400

    @property
    def completion_percentage(self) -> int:
        """Calculates percentage of core recommendations completed."""
        items = [
            self.is_folic_acid_adequate,
            self.medical_checkup_done,
            self.rubella_immunity_checked,
            self.dental_checkup_done,
            self.toxic_habits_stopped,
            self.partner_evaluation_planned,
        ]
        completed = sum(1 for item in items if item)
        return int(round((completed / len(items)) * 100))
