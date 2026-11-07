from app.core.errors import ConflictError, DomainError, EntityNotFoundError


class InvalidOnboardingGoalsError(DomainError):
    """Raised when primary intents count is outside the valid range (1..3)."""

    def __init__(
        self, message: str = "Debes seleccionar entre 1 y 3 intenciones principales."
    ) -> None:
        super().__init__(
            code="invalid_onboarding_goals",
            title="Intenciones Principales Inválidas",
            detail=message,
            status_code=400,
        )


class InvalidBirthYearError(DomainError):
    """Raised when birth year is outside realistic range."""

    def __init__(
        self,
        message: str = (
            "El año de nacimiento ingresado no es válido para la calibración clínica."
        ),
    ) -> None:
        super().__init__(
            code="invalid_birth_year",
            title="Año de Nacimiento Inválido",
            detail=message,
            status_code=400,
        )


class InvalidLifeStageTransitionError(DomainError):
    """Raised when an incoherent transition between life stages is requested."""

    def __init__(
        self,
        message: str = "La transición solicitada entre etapas de vida no es válida.",
    ) -> None:
        super().__init__(
            code="invalid_life_stage_transition",
            title="Transición de Etapa Inválida",
            detail=message,
            status_code=400,
        )


class UserProfileNotFoundError(EntityNotFoundError):
    """Raised when a user profile is not found."""

    def __init__(self, identifier: str) -> None:
        super().__init__(
            entity="UserProfile",
            identifier=identifier,
        )


class UserProfileAlreadyExistsError(ConflictError):
    """Raised when attempting to create a profile that already exists."""

    def __init__(self, firebase_uid: str) -> None:
        super().__init__(
            entity="UserProfile",
            detail=(
                "Ya existe un perfil para la usuaria con identificador "
                f"'{firebase_uid}'."
            ),
        )
