from collections.abc import Sequence
from dataclasses import dataclass, field
from datetime import UTC, datetime
from enum import StrEnum

from app.core.errors import DomainError
from app.modules.identity.domain.exceptions.identity_exceptions import (
    InvalidBirthYearError,
    InvalidOnboardingGoalsError,
)


class CycleRegularity(StrEnum):
    """Self-reported menstrual cycle regularity established during onboarding."""

    REGULAR = "regular"
    IRREGULAR = "irregular"
    UNSURE = "unsure"
    NOT_APPLICABLE = "not_applicable"


class PrimaryIntent(StrEnum):
    """User primary wellness and health priorities in Cora."""

    CYCLE_AND_SYMPTOMS = "cycle_and_symptoms"
    FAMILY_PLANNING = "family_planning"
    PREGNANCY_TRACKING = "pregnancy_tracking"
    HORMONAL_AND_CLIMACTERIC = "hormonal_and_climacteric"
    PREVENTIVE_HEALTH = "preventive_health"
    GENERAL_WELLNESS = "general_wellness"


class HormonalMethod(StrEnum):
    """Hormonal or contraceptive treatments currently active."""

    NONE = "none"
    COMBINED_ORAL_PILL = "combined_oral_pill"
    PROGESTIN_ONLY_PILL = "progestin_only_pill"
    HORMONAL_IUD = "hormonal_iud"
    COPPER_IUD = "copper_iud"
    SUBDERMAL_IMPLANT = "subdermal_implant"
    TRANSDERMAL_PATCH = "transdermal_patch"
    INJECTABLE = "injectable"
    HORMONE_REPLACEMENT_THERAPY = "hormone_replacement_therapy"
    OTHER = "other"


class DiagnosedCondition(StrEnum):
    """Pre-existing clinical conditions that calibrate cycle and health algorithms."""

    PCOS = "pcos"
    ENDOMETRIOSIS = "endometriosis"
    THYROID_DISORDER = "thyroid_disorder"
    INSULIN_RESISTANCE_OR_DIABETES = "insulin_resistance_or_diabetes"
    NONE = "none"


@dataclass(frozen=True)
class OnboardingContext:
    """Immutable calibration context established during user onboarding."""

    birth_year: int
    primary_intents: Sequence[PrimaryIntent]
    hormonal_method: HormonalMethod | None = None
    diagnosed_conditions: Sequence[DiagnosedCondition] = field(default_factory=tuple)
    clinical_context_completed: bool = False
    cycle_regularity: CycleRegularity = CycleRegularity.UNSURE
    typical_cycle_length_days: int | None = None
    typical_bleeding_duration_days: int | None = None

    def __post_init__(self) -> None:
        current_year = datetime.now(UTC).year
        min_year = current_year - 110
        max_year = current_year - 9

        if not (min_year <= self.birth_year <= max_year):
            raise InvalidBirthYearError(
                f"El año de nacimiento debe estar entre {min_year} y {max_year}."
            )

        if self.typical_cycle_length_days is not None and not (
            15 <= self.typical_cycle_length_days <= 90
        ):
            raise DomainError(
                code="invalid_cycle_length",
                title="Duración del Ciclo Inválida",
                detail="La duración habitual del ciclo debe estar entre 15 y 90 días.",
                status_code=400,
            )

        if self.typical_bleeding_duration_days is not None and not (
            1 <= self.typical_bleeding_duration_days <= 15
        ):
            raise DomainError(
                code="invalid_bleeding_duration",
                title="Duración de Sangrado Inválida",
                detail=(
                    "La duración habitual del sangrado debe estar entre 1 y 15 días."
                ),
                status_code=400,
            )

        # Deduplicate while preserving order
        deduped_intents = tuple(dict.fromkeys(self.primary_intents))
        if not (1 <= len(deduped_intents) <= 3):
            raise InvalidOnboardingGoalsError(
                "Debes seleccionar entre 1 y 3 intenciones "
                f"(recibidas: {len(deduped_intents)})."
            )

        # Ensure tuple immutability for Sequence fields
        object.__setattr__(self, "primary_intents", deduped_intents)

        deduped_conditions = tuple(dict.fromkeys(self.diagnosed_conditions))
        object.__setattr__(self, "diagnosed_conditions", deduped_conditions)
