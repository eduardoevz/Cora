from collections.abc import Sequence
from dataclasses import dataclass, field
from datetime import datetime

from app.modules.identity.domain.value_objects.life_stage import (
    LifeStage,
    TransitionReason,
)
from app.modules.identity.domain.value_objects.onboarding_context import (
    DiagnosedCondition,
    HormonalMethod,
    PrimaryIntent,
)


@dataclass(frozen=True)
class CompleteOnboardingCommand:
    """Command payload for completing the 3-layer onboarding flow."""

    first_name: str
    last_name: str
    current_life_stage: LifeStage
    birth_year: int
    primary_intents: Sequence[PrimaryIntent]
    hormonal_method: HormonalMethod | None = None
    diagnosed_conditions: Sequence[DiagnosedCondition] = field(default_factory=tuple)
    clinical_context_completed: bool = False


@dataclass(frozen=True)
class SwitchLifeStageCommand:
    """Command payload for transitioning between biological life stages."""

    target_stage: LifeStage
    reason: TransitionReason
    notes: str | None = None
    occurred_at: datetime | None = None


@dataclass(frozen=True)
class UpdateModulePreferencesCommand:
    """Command payload for updating active secondary modules preferences."""

    enabled_modules: Sequence[str]
