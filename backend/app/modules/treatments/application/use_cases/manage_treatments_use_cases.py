from datetime import UTC, date, datetime, time

from app.modules.treatments.application.dtos.treatment_dtos import (
    CreateTreatmentRegimenDTO,
    LogDoseIntakeDTO,
)
from app.modules.treatments.application.ports.treatment_repository_port import (
    ITreatmentRepository,
)
from app.modules.treatments.domain.exceptions.treatment_exceptions import (
    TreatmentRegimenNotFoundError,
)
from app.modules.treatments.domain.models.treatment_regimen import (
    DoseIntakeLog,
    TreatmentRegimen,
)
from app.modules.treatments.domain.services.adherence_and_missed_dose_service import (
    AdherenceAndMissedDoseService,
    AdherenceSummary,
    IntakeAssessment,
)
from app.modules.treatments.domain.value_objects.dosage_schedule import (
    DosageSchedule,
    ScheduleType,
    TreatmentCategory,
)


class CreateTreatmentRegimenUseCase:
    """Use case to configure and persist a new treatment regimen."""

    def __init__(self, repository: ITreatmentRepository) -> None:
        self._repository = repository

    async def execute(
        self, user_id: str, dto: CreateTreatmentRegimenDTO
    ) -> TreatmentRegimen:
        category = TreatmentCategory(dto.category)
        schedule_type = ScheduleType(dto.schedule_type)
        start_date = date.fromisoformat(dto.start_date)
        end_date = date.fromisoformat(dto.end_date) if dto.end_date else None
        replacement_date = (
            date.fromisoformat(dto.replacement_date) if dto.replacement_date else None
        )

        schedule = DosageSchedule(
            schedule_type=schedule_type,
            scheduled_time=dto.scheduled_time,
            active_days=dto.active_days,
            break_days=dto.break_days,
            interval_days=dto.interval_days,
            replacement_date=replacement_date,
        )

        regimen = TreatmentRegimen.create(
            user_id=user_id,
            name=dto.name,
            category=category,
            dosage=dto.dosage,
            schedule=schedule,
            start_date=start_date,
            end_date=end_date,
            instructions=dto.instructions,
            reminder_enabled=dto.reminder_enabled,
            discreet_notification=dto.discreet_notification,
        )

        return await self._repository.save_regimen(regimen)


class LogDoseIntakeUseCase:
    """Use case to record an individual medication intake event."""

    def __init__(
        self,
        repository: ITreatmentRepository,
        service: AdherenceAndMissedDoseService | None = None,
    ) -> None:
        self._repository = repository
        self._service = service or AdherenceAndMissedDoseService()

    async def execute(
        self,
        user_id: str,
        regimen_id: str,
        dto: LogDoseIntakeDTO,
        intake_id: str | None = None,
    ) -> tuple[DoseIntakeLog, IntakeAssessment]:
        regimen = await self._repository.get_regimen_by_id(regimen_id)
        if regimen is None or regimen.user_id != user_id:
            raise TreatmentRegimenNotFoundError(regimen_id=regimen_id)

        scheduled_for = datetime.fromisoformat(dto.scheduled_for)
        taken_at = datetime.fromisoformat(dto.taken_at) if dto.taken_at else None

        assessment = self._service.evaluate_intake(
            regimen=regimen,
            scheduled_for=scheduled_for,
            taken_at=taken_at,
        )

        intake = DoseIntakeLog.create(
            intake_id=intake_id,
            regimen_id=regimen_id,
            user_id=user_id,
            scheduled_for=scheduled_for,
            taken_at=taken_at,
            status=assessment.status,
            notes=dto.notes,
            client_mutation_id=dto.client_mutation_id,
        )

        saved = await self._repository.log_intake(intake)
        return saved, assessment


class GetTreatmentAdherenceUseCase:
    """Use case to compute compliance summary for a regimen over a date range."""

    def __init__(
        self,
        repository: ITreatmentRepository,
        service: AdherenceAndMissedDoseService | None = None,
    ) -> None:
        self._repository = repository
        self._service = service or AdherenceAndMissedDoseService()

    async def execute(
        self, user_id: str, regimen_id: str, start_date: date, end_date: date
    ) -> AdherenceSummary:
        regimen = await self._repository.get_regimen_by_id(regimen_id)
        if regimen is None or regimen.user_id != user_id:
            raise TreatmentRegimenNotFoundError()

        start_dt = datetime.combine(start_date, time.min, tzinfo=UTC)
        end_dt = datetime.combine(end_date, time.max, tzinfo=UTC)

        intakes = await self._repository.get_intakes(regimen_id, start_dt, end_dt)
        return self._service.calculate_adherence_summary(regimen, intakes)
