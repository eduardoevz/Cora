from datetime import UTC, datetime

import pytest

from app.modules.identity.domain.exceptions.identity_exceptions import (
    InvalidBirthYearError,
    InvalidOnboardingGoalsError,
)
from app.modules.identity.domain.value_objects.onboarding_context import (
    DiagnosedCondition,
    HormonalMethod,
    OnboardingContext,
    PrimaryIntent,
)


def test_valid_onboarding_context_with_clinical_data() -> None:
    context = OnboardingContext(
        birth_year=1998,
        primary_intents=[
            PrimaryIntent.CYCLE_AND_SYMPTOMS,
            PrimaryIntent.GENERAL_WELLNESS,
        ],
        hormonal_method=HormonalMethod.COMBINED_ORAL_PILL,
        diagnosed_conditions=[DiagnosedCondition.PCOS],
        clinical_context_completed=True,
    )

    assert context.birth_year == 1998
    assert len(context.primary_intents) == 2
    assert context.hormonal_method == HormonalMethod.COMBINED_ORAL_PILL
    assert DiagnosedCondition.PCOS in context.diagnosed_conditions
    assert context.clinical_context_completed is True


def test_onboarding_context_omitting_layer_three_responder_despues() -> None:
    context = OnboardingContext(
        birth_year=2002,
        primary_intents=[PrimaryIntent.CYCLE_AND_SYMPTOMS],
        hormonal_method=None,
        diagnosed_conditions=[],
        clinical_context_completed=False,
    )

    assert context.clinical_context_completed is False
    assert context.hormonal_method is None
    assert context.diagnosed_conditions == ()


@pytest.mark.parametrize("empty_intents", [[], ()])
def test_onboarding_context_rejects_empty_intents(
    empty_intents: list[PrimaryIntent],
) -> None:
    with pytest.raises(InvalidOnboardingGoalsError) as exc_info:
        OnboardingContext(
            birth_year=1995,
            primary_intents=empty_intents,
        )
    assert exc_info.value.code == "invalid_onboarding_goals"
    assert "entre 1 y 3" in exc_info.value.detail


def test_onboarding_context_rejects_more_than_three_intents() -> None:
    with pytest.raises(InvalidOnboardingGoalsError) as exc_info:
        OnboardingContext(
            birth_year=1995,
            primary_intents=[
                PrimaryIntent.CYCLE_AND_SYMPTOMS,
                PrimaryIntent.FAMILY_PLANNING,
                PrimaryIntent.PREVENTIVE_HEALTH,
                PrimaryIntent.GENERAL_WELLNESS,
            ],
        )
    assert exc_info.value.code == "invalid_onboarding_goals"


def test_onboarding_context_deduplicates_intents() -> None:
    context = OnboardingContext(
        birth_year=1990,
        primary_intents=[
            PrimaryIntent.CYCLE_AND_SYMPTOMS,
            PrimaryIntent.CYCLE_AND_SYMPTOMS,
            PrimaryIntent.GENERAL_WELLNESS,
        ],
    )
    assert len(context.primary_intents) == 2


@pytest.mark.parametrize(
    "invalid_year",
    [
        1890,
        1910,
        datetime.now(UTC).year + 1,
        datetime.now(UTC).year - 5,  # Too young (< 9 years)
    ],
)
def test_onboarding_context_rejects_unrealistic_birth_year(invalid_year: int) -> None:
    with pytest.raises(InvalidBirthYearError) as exc_info:
        OnboardingContext(
            birth_year=invalid_year,
            primary_intents=[PrimaryIntent.GENERAL_WELLNESS],
        )
    assert exc_info.value.code == "invalid_birth_year"
