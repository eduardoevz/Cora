from app.core.errors import DomainError


class InvalidAttachmentError(DomainError):
    def __init__(self, detail: str) -> None:
        super().__init__(
            code="INVALID_ATTACHMENT",
            title="Adjunto Médico Inválido",
            detail=detail,
            status_code=400,
        )


class MedicalRecordNotFoundError(DomainError):
    def __init__(self, record_id: str) -> None:
        super().__init__(
            code="MEDICAL_RECORD_NOT_FOUND",
            title="Estudio Médico No Encontrado",
            detail=f"No se encontró el estudio médico solicitado: {record_id}",
            status_code=404,
        )


class SpecialistNotFoundError(DomainError):
    def __init__(self, specialist_id: str) -> None:
        super().__init__(
            code="SPECIALIST_NOT_FOUND",
            title="Especialista No Encontrado",
            detail=f"No se encontró el especialista solicitado: {specialist_id}",
            status_code=404,
        )


class VaccinationRecordNotFoundError(DomainError):
    def __init__(self, vax_id: str) -> None:
        super().__init__(
            code="VACCINATION_NOT_FOUND",
            title="Registro de Vacunación No Encontrado",
            detail=f"No se encontró el registro de vacunación: {vax_id}",
            status_code=404,
        )
