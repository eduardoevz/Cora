from datetime import UTC, datetime, timedelta

from app.modules.clinical_tracking.application.dtos.cycle_dtos import (
    LogSymptomDTO,
)
from app.modules.clinical_tracking.application.ports.cycle_repository_port import (
    ICycleRepository,
)
from app.modules.clinical_tracking.domain.models.menstrual_cycle import (
    CycleSymptomLog,
    MenstrualCycle,
)


class LogBleedingAndSymptomsUseCase:
    """Orchestrates recording daily somatic/bleeding symptoms and cycle delimitation."""

    def __init__(self, repository: ICycleRepository) -> None:
        self._repository = repository

    async def execute(self, user_id: str, dto: LogSymptomDTO) -> CycleSymptomLog:
        current_cycle = await self._repository.get_current_cycle(user_id)
        is_menstrual = dto.bleeding_flow.is_menstrual_bleeding

        if is_menstrual:
            if current_cycle is None:
                new_cycle = MenstrualCycle.create(
                    user_id=user_id,
                    start_date=dto.log_date,
                    bleeding_duration_days=None,
                    is_current=True,
                )
                current_cycle = await self._repository.save_cycle(new_cycle)
            else:
                delta_days = (dto.log_date - current_cycle.start_date).days
                if delta_days > 14:
                    # New cycle starts; close the previous cycle
                    closing_end = dto.log_date - timedelta(days=1)
                    closed_cycle = current_cycle.close(closing_end)
                    await self._repository.save_cycle(closed_cycle)

                    new_cycle = MenstrualCycle.create(
                        user_id=user_id,
                        start_date=dto.log_date,
                        bleeding_duration_days=None,
                        is_current=True,
                    )
                    current_cycle = await self._repository.save_cycle(new_cycle)
                elif delta_days >= 0:
                    # Bleeding belongs to ongoing cycle; extend duration if needed
                    days_from_start = delta_days + 1
                    current_duration = current_cycle.bleeding_duration_days or 5
                    if days_from_start > current_duration:
                        updated_cycle = MenstrualCycle(
                            id=current_cycle.id,
                            user_id=current_cycle.user_id,
                            start_date=current_cycle.start_date,
                            end_date=current_cycle.end_date,
                            cycle_length_days=current_cycle.cycle_length_days,
                            bleeding_duration_days=days_from_start,
                            is_current=current_cycle.is_current,
                            created_at=current_cycle.created_at,
                            updated_at=datetime.now(UTC),
                        )
                        current_cycle = await self._repository.save_cycle(updated_cycle)

        # Retrieve or create daily symptom log
        existing_log = await self._repository.get_symptom_log_by_date(
            user_id, dto.log_date
        )

        cycle_id = current_cycle.id if current_cycle else None

        if existing_log is not None:
            updated_log = CycleSymptomLog(
                id=existing_log.id,
                user_id=user_id,
                log_date=dto.log_date,
                cycle_id=cycle_id or existing_log.cycle_id,
                bleeding_flow=dto.bleeding_flow,
                pelvic_pain=(
                    dto.pelvic_pain
                    if dto.pelvic_pain is not None
                    else existing_log.pelvic_pain
                ),
                dysmenorrhea=(
                    dto.dysmenorrhea
                    if dto.dysmenorrhea is not None
                    else existing_log.dysmenorrhea
                ),
                dyspareunia=(
                    dto.dyspareunia
                    if dto.dyspareunia is not None
                    else existing_log.dyspareunia
                ),
                acne_severity=(
                    dto.acne_severity
                    if dto.acne_severity is not None
                    else existing_log.acne_severity
                ),
                hirsutism=(
                    dto.hirsutism
                    if dto.hirsutism is not None
                    else existing_log.hirsutism
                ),
                fatigue_level=(
                    dto.fatigue_level
                    if dto.fatigue_level is not None
                    else existing_log.fatigue_level
                ),
                gi_symptoms=dto.gi_symptoms or existing_log.gi_symptoms,
                notes=dto.notes if dto.notes is not None else existing_log.notes,
                created_at=existing_log.created_at,
                updated_at=datetime.now(UTC),
            )
            return await self._repository.save_symptom_log(updated_log)

        new_log = CycleSymptomLog.create(
            user_id=user_id,
            log_date=dto.log_date,
            cycle_id=cycle_id,
            bleeding_flow=dto.bleeding_flow,
            pelvic_pain=dto.pelvic_pain,
            dysmenorrhea=dto.dysmenorrhea,
            dyspareunia=dto.dyspareunia,
            acne_severity=dto.acne_severity,
            hirsutism=dto.hirsutism,
            fatigue_level=dto.fatigue_level,
            gi_symptoms=dto.gi_symptoms,
            notes=dto.notes,
        )
        return await self._repository.save_symptom_log(new_log)
