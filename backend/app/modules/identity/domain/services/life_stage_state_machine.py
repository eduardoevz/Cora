from datetime import UTC, datetime

from app.modules.identity.domain.exceptions.identity_exceptions import (
    InvalidLifeStageTransitionError,
)
from app.modules.identity.domain.models.user_profile import (
    LifeStageTransition,
    UserProfile,
)
from app.modules.identity.domain.value_objects.life_stage import (
    LifeStage,
    TransitionReason,
)


class LifeStageStateMachine:
    """Orchestrates biological stage transitions and modular defaults."""

    _DEFAULT_MODULES_BY_STAGE: dict[LifeStage, list[str]] = {
        LifeStage.ADOLESCENCE: [
            "my_first_period",
            "body_changes_guide",
            "privacy_pin",
            "symptom_logger",
        ],
        LifeStage.REGULAR_ADULT: [
            "cycle_tracking",
            "hormonal_phases",
            "wellness",
            "symptom_logger",
        ],
        LifeStage.CONCEPTION_SEARCH: [
            "fertile_window",
            "symptothermal_tracking",
            "preconception_habits",
            "cycle_tracking",
        ],
        LifeStage.PREGNANCY: [
            "fetal_development",
            "maternal_vitals",
            "birth_plan",
            "symptom_logger",
        ],
        LifeStage.POSTPARTUM: [
            "postpartum_recovery",
            "lactation_tracker",
            "maternal_mental_health",
            "symptom_logger",
        ],
        LifeStage.PERIMENOPAUSE: [
            "hormonal_transition",
            "hot_flashes",
            "metabolic_health",
            "symptom_logger",
        ],
        LifeStage.SENIOR_VITALITY: [
            "bone_muscle_health",
            "urogynecology",
            "high_legibility_theme",
            "emergency_contact",
            "symptom_logger",
        ],
    }

    _INVALID_TRANSITIONS: set[tuple[LifeStage, LifeStage]] = {
        (LifeStage.SENIOR_VITALITY, LifeStage.ADOLESCENCE),
        (LifeStage.PERIMENOPAUSE, LifeStage.ADOLESCENCE),
        (LifeStage.POSTPARTUM, LifeStage.ADOLESCENCE),
        (LifeStage.PREGNANCY, LifeStage.ADOLESCENCE),
    }

    @classmethod
    def get_default_modules_for_stage(cls, stage: LifeStage) -> list[str]:
        """Return canonical active modules configured for a given life stage."""
        return list(
            cls._DEFAULT_MODULES_BY_STAGE.get(stage, ["wellness", "symptom_logger"])
        )

    @classmethod
    def validate_transition(
        cls,
        from_stage: LifeStage,
        to_stage: LifeStage,
        reason: TransitionReason,
    ) -> None:
        """Validate whether a transition between two life stages is coherent."""
        if from_stage == to_stage:
            raise InvalidLifeStageTransitionError(
                f"La usuaria ya se encuentra activa en la etapa '{from_stage}'."
            )

        if (from_stage, to_stage) in cls._INVALID_TRANSITIONS:
            raise InvalidLifeStageTransitionError(
                f"No es posible transicionar desde '{from_stage}' hacia '{to_stage}'."
            )

    @classmethod
    def transition(
        cls,
        profile: UserProfile,
        target_stage: LifeStage,
        reason: TransitionReason,
        occurred_at: datetime | None = None,
        notes: str | None = None,
    ) -> LifeStageTransition:
        """Execute and record an immutable biological transition for a user profile."""
        current_stage = profile.current_life_stage
        cls.validate_transition(current_stage, target_stage, reason)

        transition = LifeStageTransition(
            from_stage=current_stage,
            to_stage=target_stage,
            reason=reason,
            occurred_at=occurred_at or datetime.now(UTC),
            notes=notes,
        )

        suggested_modules = cls.get_default_modules_for_stage(target_stage)

        # Sensitive clinical adaptation for pregnancy loss:
        # Immediately deactivate all fetal reminder modules
        if reason == TransitionReason.PREGNANCY_LOSS:
            suggested_modules = [
                m
                for m in suggested_modules
                if m not in {"fetal_development", "birth_plan"}
            ]
            if "cycle_tracking" not in suggested_modules:
                suggested_modules.append("cycle_tracking")

        profile.record_transition(transition, suggested_modules)
        return transition
