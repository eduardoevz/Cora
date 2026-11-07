from dataclasses import dataclass, field
from datetime import UTC, datetime
from uuid import UUID, uuid4

from app.modules.identity.domain.value_objects.life_stage import (
    LifeStage,
    TransitionReason,
)
from app.modules.identity.domain.value_objects.onboarding_context import (
    OnboardingContext,
)


@dataclass
class LifeStageTransition:
    """Historical record of a biological life stage transition."""

    from_stage: LifeStage
    to_stage: LifeStage
    reason: TransitionReason
    occurred_at: datetime = field(default_factory=lambda: datetime.now(UTC))
    notes: str | None = None
    id: UUID = field(default_factory=uuid4)


@dataclass
class UserProfile:
    """User aggregate root for identity and biological context in Cora."""

    id: UUID
    firebase_uid: str
    first_name: str
    last_name: str
    current_life_stage: LifeStage
    onboarding_context: OnboardingContext
    onboarding_completed: bool = True
    enabled_modules: list[str] = field(default_factory=list)
    transition_history: list[LifeStageTransition] = field(default_factory=list)
    created_at: datetime = field(default_factory=lambda: datetime.now(UTC))
    updated_at: datetime = field(default_factory=lambda: datetime.now(UTC))

    def update_module_preferences(self, new_modules: list[str]) -> None:
        """Update visible and active secondary modules preferences."""
        self.enabled_modules = list(dict.fromkeys(new_modules))
        self.updated_at = datetime.now(UTC)

    def record_transition(
        self,
        transition: LifeStageTransition,
        suggested_modules: list[str],
    ) -> None:
        """Apply a validated stage transition and update enabled modules."""
        self.current_life_stage = transition.to_stage
        self.transition_history.append(transition)
        self.enabled_modules = list(dict.fromkeys(suggested_modules))
        self.updated_at = datetime.now(UTC)
