from enum import StrEnum


class LifeStage(StrEnum):
    """Canonical 7 biological life stages of women in Cora."""

    ADOLESCENCE = "adolescence"
    REGULAR_ADULT = "regular_adult"
    CONCEPTION_SEARCH = "conception_search"
    PREGNANCY = "pregnancy"
    POSTPARTUM = "postpartum"
    PERIMENOPAUSE = "perimenopause"
    SENIOR_VITALITY = "senior_vitality"


class TransitionReason(StrEnum):
    """Rationale for transitioning between biological life stages."""

    NATURAL_PROGRESSION = "natural_progression"
    CONCEPTION_CONFIRMED = "conception_confirmed"
    CHILDBIRTH = "childbirth"
    PREGNANCY_LOSS = "pregnancy_loss"
    USER_MANUAL_SELECTION = "user_manual_selection"
