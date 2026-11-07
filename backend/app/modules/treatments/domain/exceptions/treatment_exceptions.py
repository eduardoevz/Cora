from app.core.errors import DomainError, EntityNotFoundError


class TreatmentError(DomainError):
    """Base exception for treatment domain errors."""


class TreatmentRegimenNotFoundError(EntityNotFoundError):
    """Raised when a treatment regimen does not exist for the user."""

    def __init__(self, regimen_id: str = "unknown") -> None:
        super().__init__(
            entity="TreatmentRegimen",
            identifier=regimen_id,
        )


class InvalidScheduleConfigurationError(TreatmentError):
    """Raised when schedule parameters are inconsistent or missing."""

    def __init__(self, detail: str) -> None:
        super().__init__(
            code="invalid_schedule_configuration",
            title="Configuración de Pauta Horaria Inválida",
            detail=detail,
            status_code=400,
        )
