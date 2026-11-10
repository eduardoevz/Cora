from app.core.errors import DomainError


class MaternalCareDomainError(DomainError):
    """Base domain error for maternal_care module."""


class InvalidBloodPressureError(MaternalCareDomainError):
    """Raised when blood pressure readings violate physiological ranges."""

    def __init__(self, detail: str) -> None:
        super().__init__(
            code="invalid_blood_pressure",
            title="Presión Arterial Inválida",
            detail=detail,
            status_code=400,
        )


class InvalidGlucoseValueError(MaternalCareDomainError):
    """Raised when capillary glucose values fall outside limits."""

    def __init__(self, detail: str) -> None:
        super().__init__(
            code="invalid_glucose_value",
            title="Valor de Glucosa Inválido",
            detail=detail,
            status_code=400,
        )


class InvalidGestationalAgeError(MaternalCareDomainError):
    """Raised when gestational weeks/days are invalid."""

    def __init__(self, detail: str) -> None:
        super().__init__(
            code="invalid_gestational_age",
            title="Edad Gestacional Inválida",
            detail=detail,
            status_code=400,
        )


class PregnancyEpisodeValidationError(MaternalCareDomainError):
    """Raised when pregnancy episode invariant checks fail."""

    def __init__(self, detail: str) -> None:
        super().__init__(
            code="pregnancy_episode_validation_error",
            title="Error de Validación de Episodio de Embarazo",
            detail=detail,
            status_code=400,
        )
