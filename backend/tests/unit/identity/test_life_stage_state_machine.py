from datetime import UTC, datetime
from uuid import uuid4

import pytest

from app.modules.identity.domain.exceptions.identity_exceptions import (
    InvalidLifeStageTransitionError,
)
from app.modules.identity.domain.models.user_profile import (
    UserProfile,
)
from app.modules.identity.domain.services.life_stage_state_machine import (
    LifeStageStateMachine,
)
from app.modules.identity.domain.value_objects.life_stage import (
    LifeStage,
    TransitionReason,
)
from app.modules.identity.domain.value_objects.onboarding_context import (
    OnboardingContext,
    PrimaryIntent,
)


def _build_test_profile(
    stage: LifeStage = LifeStage.REGULAR_ADULT,
    birth_year: int = 1996,
) -> UserProfile:
    context = OnboardingContext(
        birth_year=birth_year,
        primary_intents=[PrimaryIntent.CYCLE_AND_SYMPTOMS],
    )
    return UserProfile(
        id=uuid4(),
        firebase_uid="firebase-user-123",
        first_name="Camila",
        last_name="Torres",
        current_life_stage=stage,
        onboarding_context=context,
        onboarding_completed=True,
    )


def test_state_machine_computes_default_modules_for_each_stage() -> None:
    for stage in LifeStage:
        modules = LifeStageStateMachine.get_default_modules_for_stage(stage)
        assert len(modules) >= 2, f"Stage {stage} should have default modules"


def test_state_machine_transition_conception_to_pregnancy() -> None:
    profile = _build_test_profile(stage=LifeStage.CONCEPTION_SEARCH)
    transition_time = datetime.now(UTC)

    transition = LifeStageStateMachine.transition(
        profile=profile,
        target_stage=LifeStage.PREGNANCY,
        reason=TransitionReason.CONCEPTION_CONFIRMED,
        occurred_at=transition_time,
        notes="Prueba de embarazo positiva en sangre.",
    )

    assert profile.current_life_stage == LifeStage.PREGNANCY
    assert len(profile.transition_history) == 1
    assert profile.transition_history[0] == transition
    assert transition.from_stage == LifeStage.CONCEPTION_SEARCH
    assert transition.to_stage == LifeStage.PREGNANCY
    assert transition.reason == TransitionReason.CONCEPTION_CONFIRMED
    assert "fetal_development" in profile.enabled_modules


def test_sensitive_transition_pregnancy_loss_to_regular_adult() -> None:
    profile = _build_test_profile(stage=LifeStage.PREGNANCY)
    transition_time = datetime.now(UTC)

    transition = LifeStageStateMachine.transition(
        profile=profile,
        target_stage=LifeStage.REGULAR_ADULT,
        reason=TransitionReason.PREGNANCY_LOSS,
        occurred_at=transition_time,
        notes="Acompañamiento prioritario y desactivación de avisos gestacionales.",
    )

    assert profile.current_life_stage == LifeStage.REGULAR_ADULT
    assert transition.reason == TransitionReason.PREGNANCY_LOSS
    # Must immediately deactivate fetal reminders to prevent emotional distress
    assert "fetal_development" not in profile.enabled_modules
    assert "cycle_tracking" in profile.enabled_modules


def test_transition_pregnancy_to_postpartum_childbirth() -> None:
    profile = _build_test_profile(stage=LifeStage.PREGNANCY)
    transition_time = datetime.now(UTC)

    transition = LifeStageStateMachine.transition(
        profile=profile,
        target_stage=LifeStage.POSTPARTUM,
        reason=TransitionReason.CHILDBIRTH,
        occurred_at=transition_time,
    )

    assert profile.current_life_stage == LifeStage.POSTPARTUM
    assert transition.from_stage == LifeStage.PREGNANCY
    assert "postpartum_recovery" in profile.enabled_modules
    assert "lactation_tracker" in profile.enabled_modules


def test_state_machine_rejects_incoherent_transition() -> None:
    profile = _build_test_profile(stage=LifeStage.SENIOR_VITALITY)

    with pytest.raises(InvalidLifeStageTransitionError) as exc_info:
        LifeStageStateMachine.transition(
            profile=profile,
            target_stage=LifeStage.ADOLESCENCE,
            reason=TransitionReason.NATURAL_PROGRESSION,
        )
    assert exc_info.value.code == "invalid_life_stage_transition"
    assert profile.current_life_stage == LifeStage.SENIOR_VITALITY
    assert len(profile.transition_history) == 0


def test_transitions_preserve_immutable_longitudinal_history() -> None:
    profile = _build_test_profile(stage=LifeStage.CONCEPTION_SEARCH)

    t1 = LifeStageStateMachine.transition(
        profile=profile,
        target_stage=LifeStage.PREGNANCY,
        reason=TransitionReason.CONCEPTION_CONFIRMED,
        occurred_at=datetime(2025, 3, 1, tzinfo=UTC),
    )
    t2 = LifeStageStateMachine.transition(
        profile=profile,
        target_stage=LifeStage.POSTPARTUM,
        reason=TransitionReason.CHILDBIRTH,
        occurred_at=datetime(2025, 11, 20, tzinfo=UTC),
    )

    assert len(profile.transition_history) == 2
    assert profile.transition_history[0].id == t1.id
    assert profile.transition_history[1].id == t2.id
    assert profile.current_life_stage == LifeStage.POSTPARTUM
