from collections.abc import Sequence
from datetime import date, timedelta

from app.modules.clinical_tracking.application.ports.cycle_repository_port import (
    ICycleRepository,
)
from app.modules.clinical_tracking.domain.exceptions import ClinicalTrackingError
from app.modules.clinical_tracking.domain.models.menstrual_cycle import (
    CycleSymptomLog,
    MenstrualCycle,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    BleedingFlow,
    InitialPeriodRange,
)


class SeedInitialPeriodsUseCase:
    """Seeds historical initial menstrual periods and daily bleeding logs."""

    def __init__(self, repository: ICycleRepository) -> None:
        self._repository = repository

    @staticmethod
    def validate_periods(
        periods: Sequence[InitialPeriodRange],
        reference_date: date | None = None,
    ) -> list[InitialPeriodRange]:
        """Validate 1 or 2 non-overlapping initial periods without future dates."""
        if not (1 <= len(periods) <= 2):
            raise ClinicalTrackingError(
                code="invalid_initial_periods_count",
                title="Cantidad de Periodos Inválida",
                detail="Debes registrar entre 1 y 2 periodos iniciales.",
                status_code=400,
            )

        today = reference_date or date.today()
        for period in periods:
            if period.start_date > today or period.end_date > today:
                raise ClinicalTrackingError(
                    code="future_period_date",
                    title="Fecha Futura No Permitida",
                    detail=(
                        "Los periodos históricos iniciales no pueden incluir fechas "
                        "posteriores al día de hoy."
                    ),
                    status_code=400,
                )

        ordered = sorted(periods, key=lambda item: item.start_date)
        if len(ordered) == 2:
            p1, p2 = ordered[0], ordered[1]
            if p1.start_date >= p2.start_date or p1.end_date >= p2.start_date:
                raise ClinicalTrackingError(
                    code="overlapping_initial_periods",
                    title="Periodos Solapados o Inválidos",
                    detail=(
                        "El periodo anterior debe finalizar antes de que inicie el "
                        "último periodo."
                    ),
                    status_code=400,
                )
            cycle_length = (p2.start_date - p1.start_date).days
            if not (15 <= cycle_length <= 90):
                raise ClinicalTrackingError(
                    code="invalid_cycle_length",
                    title="Duración del Ciclo Inválida",
                    detail=(
                        "La distancia entre el inicio de ambos periodos iniciales debe "
                        "estar entre 15 y 90 días."
                    ),
                    status_code=400,
                )

        return ordered

    async def execute(
        self,
        user_id: str,
        periods: Sequence[InitialPeriodRange],
        reference_date: date | None = None,
    ) -> list[MenstrualCycle]:
        ordered = self.validate_periods(periods, reference_date=reference_date)

        existing_current = await self._repository.get_current_cycle(user_id)
        if existing_current is not None:
            if existing_current.start_date < ordered[0].start_date:
                closed = existing_current.close(
                    ordered[0].start_date - timedelta(days=1)
                )
                await self._repository.save_cycle(closed)
            else:
                deactivated = MenstrualCycle(
                    id=existing_current.id,
                    user_id=existing_current.user_id,
                    start_date=existing_current.start_date,
                    end_date=existing_current.end_date,
                    cycle_length_days=existing_current.cycle_length_days,
                    bleeding_duration_days=existing_current.bleeding_duration_days,
                    is_current=False,
                    created_at=existing_current.created_at,
                    updated_at=existing_current.updated_at,
                )
                await self._repository.save_cycle(deactivated)

        created_cycles: list[MenstrualCycle] = []
        if len(ordered) == 2:
            p1, p2 = ordered[0], ordered[1]
            cycle_1 = MenstrualCycle.create(
                user_id=user_id,
                start_date=p1.start_date,
                end_date=p2.start_date - timedelta(days=1),
                cycle_length_days=(p2.start_date - p1.start_date).days,
                bleeding_duration_days=p1.bleeding_duration_days,
                is_current=False,
            )
            cycle_2 = MenstrualCycle.create(
                user_id=user_id,
                start_date=p2.start_date,
                end_date=None,
                cycle_length_days=None,
                bleeding_duration_days=p2.bleeding_duration_days,
                is_current=True,
            )
            created_cycles.extend([cycle_1, cycle_2])
            cycle_periods = [(cycle_1, p1), (cycle_2, p2)]
        else:
            p1 = ordered[0]
            cycle_1 = MenstrualCycle.create(
                user_id=user_id,
                start_date=p1.start_date,
                end_date=None,
                cycle_length_days=None,
                bleeding_duration_days=p1.bleeding_duration_days,
                is_current=True,
            )
            created_cycles.append(cycle_1)
            cycle_periods = [(cycle_1, p1)]

        for cycle, period in cycle_periods:
            await self._repository.save_cycle(cycle)
            for offset in range(period.bleeding_duration_days):
                bleeding_date = period.start_date + timedelta(days=offset)
                log = CycleSymptomLog.create(
                    user_id=user_id,
                    log_date=bleeding_date,
                    cycle_id=cycle.id,
                    bleeding_flow=BleedingFlow.MEDIUM,
                )
                await self._repository.save_symptom_log(log)

        return created_cycles
