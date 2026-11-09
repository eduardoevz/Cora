from datetime import UTC, date, datetime
from decimal import Decimal

from app.modules.clinical_tracking.application.dtos.fertility_dtos import (
    FertilityChartEntryDTO,
    FertilityCycleChartDTO,
    LogFertilityDailyDTO,
    PreconceptionChecklistDTO,
    UpdatePreconceptionChecklistDTO,
)
from app.modules.clinical_tracking.application.ports.cycle_repository_port import (
    ICycleRepository,
)
from app.modules.clinical_tracking.application.ports.fertility_repository_port import (
    IFertilityRepository,
)
from app.modules.clinical_tracking.domain.models.menstrual_cycle import (
    MenstrualCycle,
)
from app.modules.clinical_tracking.domain.models.preconception_checklist import (
    PreconceptionChecklist,
)
from app.modules.clinical_tracking.domain.services.symptothermal_fertility_service import (  # noqa: E501
    SymptothermalFertilityService,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    PatientCycleContext,
)
from app.modules.clinical_tracking.domain.value_objects.fertility_biomarkers import (
    BasalBodyTemperature,
    CervicalMucusType,
    DailyFertilityLog,
    IntercourseType,
    LhStripResult,
)


class LogFertilityDailyBiomarkersUseCase:
    """Use case recording daily basal temperature, LH, mucus, and intercourse."""

    def __init__(self, repository: IFertilityRepository) -> None:
        self._repository = repository

    async def execute(
        self, user_id: str, dto: LogFertilityDailyDTO
    ) -> DailyFertilityLog:
        bbt: BasalBodyTemperature | None = None
        if dto.bbt_celsius is not None:
            bbt = BasalBodyTemperature(
                celsius=dto.bbt_celsius,
                is_disturbed=dto.is_disturbed,
                disturbance_reason=dto.disturbance_reason,
                measured_at_time=dto.measured_at_time,
            )

        mucus = CervicalMucusType(dto.cervical_mucus) if dto.cervical_mucus else None
        lh = LhStripResult(dto.lh_result) if dto.lh_result else None
        intercourse = (
            IntercourseType(dto.intercourse_type)
            if dto.intercourse_type
            else IntercourseType.NONE
        )

        domain_log = DailyFertilityLog(
            log_date=dto.log_date,
            bbt=bbt,
            cervical_mucus=mucus,
            lh_result=lh,
            intercourse_had=dto.intercourse_had,
            intercourse_type=intercourse,
            notes=dto.notes,
        )

        return await self._repository.upsert_daily_fertility_log(
            user_id=user_id, log=domain_log
        )


class GetFertilityCycleChartUseCase:
    """Use case retrieving biphasic temperature curve and fertility assessment."""

    def __init__(
        self,
        fertility_repo: IFertilityRepository,
        cycle_repo: ICycleRepository,
        fertility_service: SymptothermalFertilityService | None = None,
    ) -> None:
        self._fertility_repo = fertility_repo
        self._cycle_repo = cycle_repo
        self._fertility_service = fertility_service or SymptothermalFertilityService()

    async def execute(
        self,
        user_id: str,
        patient_context: PatientCycleContext,
        cycle_id: str | None = None,
        reference_date: date | None = None,
    ) -> FertilityCycleChartDTO:
        ref_date = reference_date or date.today()

        cycle: MenstrualCycle | None = None
        if cycle_id:
            cycle = await self._cycle_repo.get_cycle_by_id(cycle_id)
        else:
            cycle = await self._cycle_repo.get_current_cycle(user_id)

        if cycle is None:
            # Fallback when no cycle is yet recorded: virtual cycle starting 1st
            cycle = MenstrualCycle.create(
                user_id=user_id,
                start_date=date(ref_date.year, ref_date.month, 1),
                is_current=True,
            )

        cycle_end = cycle.end_date or (cycle.start_date + date.resolution * 45)
        logs = await self._fertility_repo.list_fertility_logs_between(
            user_id=user_id,
            start_date=cycle.start_date,
            end_date=cycle_end,
        )

        checklist = await self._fertility_repo.get_preconception_checklist(user_id)
        seeking_months = checklist.active_seeking_months if checklist else 0

        assessment = self._fertility_service.evaluate_cycle_fertility(
            current_cycle=cycle,
            daily_logs=logs,
            patient_context=patient_context,
            reference_date=ref_date,
            active_seeking_months=seeking_months,
        )

        coverline_c = assessment.coverline_celsius
        coverline_f = (
            round((coverline_c * Decimal("9") / Decimal("5")) + Decimal("32"), 2)
            if coverline_c is not None
            else None
        )

        entries_dto: list[FertilityChartEntryDTO] = []
        for entry in logs:
            c_day = (entry.log_date - cycle.start_date).days + 1
            entries_dto.append(
                FertilityChartEntryDTO(
                    log_date=entry.log_date,
                    cycle_day=c_day,
                    bbt_celsius=entry.bbt.celsius if entry.bbt else None,
                    bbt_fahrenheit=entry.bbt.to_fahrenheit() if entry.bbt else None,
                    is_disturbed=entry.bbt.is_disturbed if entry.bbt else False,
                    disturbance_reason=entry.bbt.disturbance_reason
                    if entry.bbt
                    else None,
                    cervical_mucus=(
                        entry.cervical_mucus.value if entry.cervical_mucus else None
                    ),
                    lh_result=(entry.lh_result.value if entry.lh_result else None),
                    intercourse_had=entry.intercourse_had,
                    intercourse_type=(
                        entry.intercourse_type.value
                        if entry.intercourse_type
                        else "none"
                    ),
                )
            )

        curr_cycle_day = (ref_date - cycle.start_date).days + 1

        return FertilityCycleChartDTO(
            cycle_id=cycle.id,
            cycle_start_date=cycle.start_date,
            cycle_day=curr_cycle_day,
            status=assessment.status.value,
            coverline_celsius=coverline_c,
            coverline_fahrenheit=coverline_f,
            ovulation_confirmed_date=assessment.ovulation_confirmed_date,
            fertile_window_start=assessment.fertile_window_start,
            fertile_window_end=assessment.fertile_window_end,
            is_biphasic_shift_detected=assessment.is_biphasic_shift_detected,
            evaluation_notes_es=assessment.evaluation_notes_es,
            active_seeking_guidance_es=assessment.active_seeking_guidance_es,
            daily_entries=entries_dto,
        )


class GetPreconceptionChecklistUseCase:
    """Use case retrieving preconception health checklist."""

    def __init__(self, repository: IFertilityRepository) -> None:
        self._repository = repository

    async def execute(self, user_id: str) -> PreconceptionChecklistDTO:
        checklist = await self._repository.get_preconception_checklist(user_id)
        if checklist is None:
            checklist = PreconceptionChecklist(user_id=user_id)

        return PreconceptionChecklistDTO(
            user_id=checklist.user_id,
            taking_folic_acid=checklist.taking_folic_acid,
            folic_acid_dose_mcg=checklist.folic_acid_dose_mcg,
            is_folic_acid_adequate=checklist.is_folic_acid_adequate,
            medical_checkup_done=checklist.medical_checkup_done,
            rubella_immunity_checked=checklist.rubella_immunity_checked,
            dental_checkup_done=checklist.dental_checkup_done,
            toxic_habits_stopped=checklist.toxic_habits_stopped,
            partner_evaluation_planned=checklist.partner_evaluation_planned,
            active_seeking_months=checklist.active_seeking_months,
            completion_percentage=checklist.completion_percentage,
            updated_at=checklist.updated_at,
        )


class UpdatePreconceptionChecklistUseCase:
    """Use case updating preconception recommendations adherence."""

    def __init__(self, repository: IFertilityRepository) -> None:
        self._repository = repository

    async def execute(
        self, user_id: str, dto: UpdatePreconceptionChecklistDTO
    ) -> PreconceptionChecklistDTO:
        existing = await self._repository.get_preconception_checklist(user_id)
        if existing is None:
            existing = PreconceptionChecklist(user_id=user_id)

        taking_folic = (
            dto.taking_folic_acid
            if dto.taking_folic_acid is not None
            else existing.taking_folic_acid
        )
        folic_dose = (
            dto.folic_acid_dose_mcg
            if dto.folic_acid_dose_mcg is not None
            else existing.folic_acid_dose_mcg
        )
        medical = (
            dto.medical_checkup_done
            if dto.medical_checkup_done is not None
            else existing.medical_checkup_done
        )
        rubella = (
            dto.rubella_immunity_checked
            if dto.rubella_immunity_checked is not None
            else existing.rubella_immunity_checked
        )
        dental = (
            dto.dental_checkup_done
            if dto.dental_checkup_done is not None
            else existing.dental_checkup_done
        )
        toxic = (
            dto.toxic_habits_stopped
            if dto.toxic_habits_stopped is not None
            else existing.toxic_habits_stopped
        )
        partner = (
            dto.partner_evaluation_planned
            if dto.partner_evaluation_planned is not None
            else existing.partner_evaluation_planned
        )
        seeking_m = (
            dto.active_seeking_months
            if dto.active_seeking_months is not None
            else existing.active_seeking_months
        )

        updated = PreconceptionChecklist(
            user_id=user_id,
            taking_folic_acid=taking_folic,
            folic_acid_dose_mcg=folic_dose,
            medical_checkup_done=medical,
            rubella_immunity_checked=rubella,
            dental_checkup_done=dental,
            toxic_habits_stopped=toxic,
            partner_evaluation_planned=partner,
            active_seeking_months=seeking_m,
            updated_at=datetime.now(UTC),
        )

        saved = await self._repository.upsert_preconception_checklist(updated)

        return PreconceptionChecklistDTO(
            user_id=saved.user_id,
            taking_folic_acid=saved.taking_folic_acid,
            folic_acid_dose_mcg=saved.folic_acid_dose_mcg,
            is_folic_acid_adequate=saved.is_folic_acid_adequate,
            medical_checkup_done=saved.medical_checkup_done,
            rubella_immunity_checked=saved.rubella_immunity_checked,
            dental_checkup_done=saved.dental_checkup_done,
            toxic_habits_stopped=saved.toxic_habits_stopped,
            partner_evaluation_planned=saved.partner_evaluation_planned,
            active_seeking_months=saved.active_seeking_months,
            completion_percentage=saved.completion_percentage,
            updated_at=saved.updated_at,
        )
