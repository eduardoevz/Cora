from datetime import date

from app.modules.clinical_tracking.application.dtos.cycle_dtos import (
    CycleOverviewDTO,
)
from app.modules.clinical_tracking.application.ports.cycle_repository_port import (
    ICycleRepository,
)
from app.modules.clinical_tracking.domain.services import (
    CyclePhaseAndPredictionService,
    FigoAtypicalPatternDetector,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    PatientCycleContext,
)


class GetCycleOverviewUseCase:
    """Aggregates cycle status, phase predictions, and FIGO pattern alerts."""

    def __init__(
        self,
        repository: ICycleRepository,
        prediction_service: CyclePhaseAndPredictionService | None = None,
        figo_detector: FigoAtypicalPatternDetector | None = None,
    ) -> None:
        self._repository = repository
        self._prediction_service = (
            prediction_service or CyclePhaseAndPredictionService()
        )
        self._figo_detector = figo_detector or FigoAtypicalPatternDetector()

    async def execute(
        self,
        user_id: str,
        context: PatientCycleContext,
        reference_date: date,
    ) -> CycleOverviewDTO:
        cycles = await self._repository.list_cycles(user_id, limit=12)
        current_cycle = await self._repository.get_current_cycle(user_id)
        symptoms = await self._repository.list_symptom_logs(user_id)

        status = self._prediction_service.compute_status(
            cycles=cycles,
            context=context,
            reference_date=reference_date,
        )

        alerts = self._figo_detector.evaluate(
            cycles=cycles,
            symptoms=symptoms,
            context=context,
        )

        return CycleOverviewDTO(
            current_cycle=current_cycle,
            status=status,
            alerts=alerts,
            recent_cycles=cycles,
        )
