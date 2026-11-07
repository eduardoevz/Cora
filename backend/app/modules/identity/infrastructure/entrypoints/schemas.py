from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.modules.identity.domain.models.user_profile import (
    LifeStageTransition,
    UserProfile,
)
from app.modules.identity.domain.value_objects.life_stage import (
    LifeStage,
    TransitionReason,
)
from app.modules.identity.domain.value_objects.onboarding_context import (
    DiagnosedCondition,
    HormonalMethod,
    PrimaryIntent,
)


class OnboardingRequest(BaseModel):
    """Payload to complete the 3-layer progressive onboarding."""

    first_name: str = Field(..., min_length=1, max_length=100, examples=["Camila"])
    last_name: str = Field(..., min_length=1, max_length=100, examples=["Torres"])
    current_life_stage: LifeStage = Field(
        ...,
        description="Active biological life stage chosen in Layer 1.",
        examples=[LifeStage.REGULAR_ADULT],
    )
    birth_year: int = Field(
        ...,
        description="Birth year to calibrate age and clinical prevention timelines.",
        examples=[1996],
    )
    primary_intents: list[PrimaryIntent] = Field(
        ...,
        description="1 to 3 primary priorities selected in Layer 2.",
        examples=[[PrimaryIntent.CYCLE_AND_SYMPTOMS, PrimaryIntent.GENERAL_WELLNESS]],
    )
    hormonal_method: HormonalMethod | None = Field(
        default=None,
        description="Contraceptive or hormonal method active in Layer 3.",
    )
    diagnosed_conditions: list[DiagnosedCondition] = Field(
        default_factory=list,
        description="Diagnosed conditions in Layer 3 (PCOS, endometriosis, etc.).",
    )
    clinical_context_completed: bool = Field(
        default=False,
        description="Whether Layer 3 was completed or deferred ('Responder después').",
    )


class SwitchLifeStageRequest(BaseModel):
    """Payload to transition between biological life stages."""

    target_stage: LifeStage = Field(
        ...,
        description="Target biological life stage.",
        examples=[LifeStage.PREGNANCY],
    )
    reason: TransitionReason = Field(
        ...,
        description="Clinical or user rationale for transition.",
        examples=[TransitionReason.CONCEPTION_CONFIRMED],
    )
    notes: str | None = Field(
        default=None,
        max_length=500,
        description="Optional clinical or user notes on transition.",
    )


class UpdateModulePreferencesRequest(BaseModel):
    """Payload to update modularity preferences (Modularidad a la Carta)."""

    enabled_modules: list[str] = Field(
        ...,
        min_length=1,
        description="List of enabled secondary modules.",
        examples=[["cycle_tracking", "symptom_logger"]],
    )


class LifeStageTransitionResponse(BaseModel):
    """Historical transition item."""

    id: UUID
    from_stage: LifeStage
    to_stage: LifeStage
    reason: TransitionReason
    notes: str | None = None
    occurred_at: datetime

    @classmethod
    def from_domain(cls, t: LifeStageTransition) -> "LifeStageTransitionResponse":
        return cls(
            id=t.id,
            from_stage=t.from_stage,
            to_stage=t.to_stage,
            reason=t.reason,
            notes=t.notes,
            occurred_at=t.occurred_at,
        )


class OnboardingContextResponse(BaseModel):
    """Context summary returned with profile."""

    birth_year: int
    primary_intents: list[PrimaryIntent]
    hormonal_method: HormonalMethod | None
    diagnosed_conditions: list[DiagnosedCondition]
    clinical_context_completed: bool


class UserProfileResponse(BaseModel):
    """Public representation of user profile and active biological stage."""

    id: UUID
    firebase_uid: str
    first_name: str
    last_name: str
    current_life_stage: LifeStage
    onboarding_completed: bool
    onboarding_context: OnboardingContextResponse
    enabled_modules: list[str]
    transition_history: list[LifeStageTransitionResponse]
    created_at: datetime
    updated_at: datetime

    @classmethod
    def from_domain(cls, profile: UserProfile) -> "UserProfileResponse":
        context_res = OnboardingContextResponse(
            birth_year=profile.onboarding_context.birth_year,
            primary_intents=list(profile.onboarding_context.primary_intents),
            hormonal_method=profile.onboarding_context.hormonal_method,
            diagnosed_conditions=list(profile.onboarding_context.diagnosed_conditions),
            clinical_context_completed=profile.onboarding_context.clinical_context_completed,
        )
        transitions_res = [
            LifeStageTransitionResponse.from_domain(t)
            for t in profile.transition_history
        ]
        return cls(
            id=profile.id,
            firebase_uid=profile.firebase_uid,
            first_name=profile.first_name,
            last_name=profile.last_name,
            current_life_stage=profile.current_life_stage,
            onboarding_completed=profile.onboarding_completed,
            onboarding_context=context_res,
            enabled_modules=list(profile.enabled_modules),
            transition_history=transitions_res,
            created_at=profile.created_at,
            updated_at=profile.updated_at,
        )
