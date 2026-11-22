from datetime import date

from app.modules.clinical_tracking.application.ports.cycle_repository_port import (
    ICycleRepository,
)
from app.modules.clinical_tracking.domain.exceptions import ClinicalTrackingError
from app.modules.clinical_tracking.domain.services import (
    CycleCalendarProjectionService,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    CalendarMonthProjection,
    PatientCycleContext,
)


class GetCycleCalendarUseCase:
    """Projects a monthly menstrual calendar calibrated to history and life stage."""

    def __init__(
        self,
        repository: ICycleRepository,
        projection_service: CycleCalendarProjectionService | None = None,
    ) -> None:
        self._repository = repository
        self._projection_service = (
            projection_service or CycleCalendarProjectionService()
        )

    async def execute(
        self,
        user_id: str,
        year: int,
        month: int,
        context: PatientCycleContext,
        reference_date: date,
    ) -> CalendarMonthProjection:
        if not (1 <= month <= 12) or not (2000 <= year <= 2100):
            raise ClinicalTrackingError(
                code="invalid_calendar_month",
                title="Mes de Calendario Inválido",
                detail=("El año debe estar entre 2000 y 2100 y el mes entre 1 y 12."),
                status_code=400,
            )

        cycles = await self._repository.list_cycles(user_id, limit=24)
        symptoms = await self._repository.list_symptom_logs(user_id)

        return self._projection_service.project_month(
            year=year,
            month=month,
            cycles=cycles,
            symptom_logs=symptoms,
            context=context,
            today=reference_date,
        )
