import uuid
from datetime import UTC, date, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.clinical_tracking.application.ports.fertility_repository_port import (
    IFertilityRepository,
)
from app.modules.clinical_tracking.domain.models.preconception_checklist import (
    PreconceptionChecklist,
)
from app.modules.clinical_tracking.domain.value_objects.fertility_biomarkers import (
    DailyFertilityLog,
)
from app.modules.clinical_tracking.infrastructure.orm.fertility_orm import (
    DailyFertilityLogModel,
    PreconceptionChecklistModel,
)


class PostgresFertilityRepository(IFertilityRepository):
    """PostgreSQL adapter implementing IFertilityRepository via SQLAlchemy 2.0 Async."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def upsert_daily_fertility_log(
        self, user_id: str, log: DailyFertilityLog
    ) -> DailyFertilityLog:
        user_uuid = uuid.UUID(user_id)
        stmt = select(DailyFertilityLogModel).where(
            DailyFertilityLogModel.user_id == user_uuid,
            DailyFertilityLogModel.log_date == log.log_date,
        )
        res = await self._session.execute(stmt)
        existing = res.scalar_one_or_none()

        now = datetime.now(UTC)
        bbt_celsius = log.bbt.celsius if log.bbt else None
        is_disturbed = log.bbt.is_disturbed if log.bbt else False
        disturbance_reason = log.bbt.disturbance_reason if log.bbt else None
        measured_time = log.bbt.measured_at_time if log.bbt else None
        mucus = log.cervical_mucus.value if log.cervical_mucus else None
        lh = log.lh_result.value if log.lh_result else None
        intercourse_type = (
            log.intercourse_type.value if log.intercourse_type else "none"
        )

        if existing is None:
            model = DailyFertilityLogModel(
                user_id=user_uuid,
                log_date=log.log_date,
                bbt_celsius=bbt_celsius,
                is_disturbed=is_disturbed,
                disturbance_reason=disturbance_reason,
                measured_at_time=measured_time,
                cervical_mucus=mucus,
                lh_result=lh,
                intercourse_had=log.intercourse_had,
                intercourse_type=intercourse_type,
                notes=log.notes,
                created_at=now,
                updated_at=now,
            )
            self._session.add(model)
        else:
            existing.bbt_celsius = bbt_celsius
            existing.is_disturbed = is_disturbed
            existing.disturbance_reason = disturbance_reason
            existing.measured_at_time = measured_time
            existing.cervical_mucus = mucus
            existing.lh_result = lh
            existing.intercourse_had = log.intercourse_had
            existing.intercourse_type = intercourse_type
            existing.notes = log.notes
            existing.updated_at = now

        await self._session.commit()
        return log

    async def get_daily_fertility_log(
        self, user_id: str, log_date: date
    ) -> DailyFertilityLog | None:
        user_uuid = uuid.UUID(user_id)
        stmt = select(DailyFertilityLogModel).where(
            DailyFertilityLogModel.user_id == user_uuid,
            DailyFertilityLogModel.log_date == log_date,
        )
        res = await self._session.execute(stmt)
        model = res.scalar_one_or_none()
        return model.to_domain() if model else None

    async def list_fertility_logs_between(
        self, user_id: str, start_date: date, end_date: date
    ) -> list[DailyFertilityLog]:
        user_uuid = uuid.UUID(user_id)
        stmt = (
            select(DailyFertilityLogModel)
            .where(
                DailyFertilityLogModel.user_id == user_uuid,
                DailyFertilityLogModel.log_date >= start_date,
                DailyFertilityLogModel.log_date <= end_date,
            )
            .order_by(DailyFertilityLogModel.log_date.asc())
        )
        res = await self._session.execute(stmt)
        models = res.scalars().all()
        return [m.to_domain() for m in models]

    async def get_preconception_checklist(
        self, user_id: str
    ) -> PreconceptionChecklist | None:
        user_uuid = uuid.UUID(user_id)
        stmt = select(PreconceptionChecklistModel).where(
            PreconceptionChecklistModel.user_id == user_uuid
        )
        res = await self._session.execute(stmt)
        model = res.scalar_one_or_none()
        return model.to_domain() if model else None

    async def upsert_preconception_checklist(
        self, checklist: PreconceptionChecklist
    ) -> PreconceptionChecklist:
        user_uuid = uuid.UUID(checklist.user_id)
        stmt = select(PreconceptionChecklistModel).where(
            PreconceptionChecklistModel.user_id == user_uuid
        )
        res = await self._session.execute(stmt)
        existing = res.scalar_one_or_none()

        now = datetime.now(UTC)
        if existing is None:
            model = PreconceptionChecklistModel(
                user_id=user_uuid,
                taking_folic_acid=checklist.taking_folic_acid,
                folic_acid_dose_mcg=checklist.folic_acid_dose_mcg,
                medical_checkup_done=checklist.medical_checkup_done,
                rubella_immunity_checked=checklist.rubella_immunity_checked,
                dental_checkup_done=checklist.dental_checkup_done,
                toxic_habits_stopped=checklist.toxic_habits_stopped,
                partner_evaluation_planned=checklist.partner_evaluation_planned,
                active_seeking_months=checklist.active_seeking_months,
                created_at=now,
                updated_at=now,
            )
            self._session.add(model)
        else:
            existing.taking_folic_acid = checklist.taking_folic_acid
            existing.folic_acid_dose_mcg = checklist.folic_acid_dose_mcg
            existing.medical_checkup_done = checklist.medical_checkup_done
            existing.rubella_immunity_checked = checklist.rubella_immunity_checked
            existing.dental_checkup_done = checklist.dental_checkup_done
            existing.toxic_habits_stopped = checklist.toxic_habits_stopped
            existing.partner_evaluation_planned = checklist.partner_evaluation_planned
            existing.active_seeking_months = checklist.active_seeking_months
            existing.updated_at = now

        await self._session.commit()
        return checklist
