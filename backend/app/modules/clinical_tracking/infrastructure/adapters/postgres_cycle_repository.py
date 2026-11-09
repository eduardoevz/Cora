import uuid
from datetime import UTC, date, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.clinical_tracking.application.ports.cycle_repository_port import (
    ICycleRepository,
)
from app.modules.clinical_tracking.domain.models.menstrual_cycle import (
    CycleSymptomLog,
    MenstrualCycle,
)
from app.modules.clinical_tracking.infrastructure.orm.cycle_orm import (
    CycleSymptomLogModel,
    MenstrualCycleModel,
)


class PostgresCycleRepository(ICycleRepository):
    """PostgreSQL adapter implementing ICycleRepository via SQLAlchemy 2.0."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def save_cycle(self, cycle: MenstrualCycle) -> MenstrualCycle:
        cycle_uuid = uuid.UUID(cycle.id)
        stmt = select(MenstrualCycleModel).where(MenstrualCycleModel.id == cycle_uuid)
        res = await self._session.execute(stmt)
        existing = res.scalar_one_or_none()

        if existing is None:
            model = MenstrualCycleModel.from_domain(cycle)
            self._session.add(model)
        else:
            existing.start_date = cycle.start_date
            existing.end_date = cycle.end_date
            existing.cycle_length_days = cycle.cycle_length_days
            existing.bleeding_duration_days = cycle.bleeding_duration_days
            existing.is_current = cycle.is_current
            existing.updated_at = datetime.now(UTC)

        await self._session.commit()
        return cycle

    async def get_cycle_by_id(self, cycle_id: str) -> MenstrualCycle | None:
        cycle_uuid = uuid.UUID(cycle_id)
        stmt = select(MenstrualCycleModel).where(MenstrualCycleModel.id == cycle_uuid)
        res = await self._session.execute(stmt)
        model = res.scalar_one_or_none()
        return model.to_domain() if model else None

    async def get_current_cycle(self, user_id: str) -> MenstrualCycle | None:
        user_uuid = uuid.UUID(user_id)
        stmt = (
            select(MenstrualCycleModel)
            .where(
                MenstrualCycleModel.user_id == user_uuid,
                MenstrualCycleModel.is_current.is_(True),
            )
            .order_by(MenstrualCycleModel.start_date.desc())
            .limit(1)
        )
        res = await self._session.execute(stmt)
        model = res.scalar_one_or_none()
        return model.to_domain() if model else None

    async def list_cycles(self, user_id: str, limit: int = 12) -> list[MenstrualCycle]:
        user_uuid = uuid.UUID(user_id)
        stmt = (
            select(MenstrualCycleModel)
            .where(MenstrualCycleModel.user_id == user_uuid)
            .order_by(MenstrualCycleModel.start_date.desc())
            .limit(limit)
        )
        res = await self._session.execute(stmt)
        models = res.scalars().all()
        return [m.to_domain() for m in models]

    async def save_symptom_log(self, log: CycleSymptomLog) -> CycleSymptomLog:
        user_uuid = uuid.UUID(log.user_id)
        stmt = select(CycleSymptomLogModel).where(
            CycleSymptomLogModel.user_id == user_uuid,
            CycleSymptomLogModel.log_date == log.log_date,
        )
        res = await self._session.execute(stmt)
        existing = res.scalar_one_or_none()

        if existing is None:
            model = CycleSymptomLogModel.from_domain(log)
            self._session.add(model)
        else:
            existing.cycle_id = uuid.UUID(log.cycle_id) if log.cycle_id else None
            existing.bleeding_flow = log.bleeding_flow.value
            existing.pelvic_pain = log.pelvic_pain
            existing.dysmenorrhea = log.dysmenorrhea
            existing.dyspareunia = log.dyspareunia
            existing.acne_severity = log.acne_severity
            existing.hirsutism = log.hirsutism
            existing.fatigue_level = log.fatigue_level
            existing.gi_symptoms = log.gi_symptoms
            existing.notes = log.notes
            existing.updated_at = datetime.now(UTC)

        await self._session.commit()
        return log

    async def get_symptom_log_by_date(
        self, user_id: str, log_date: date
    ) -> CycleSymptomLog | None:
        user_uuid = uuid.UUID(user_id)
        stmt = select(CycleSymptomLogModel).where(
            CycleSymptomLogModel.user_id == user_uuid,
            CycleSymptomLogModel.log_date == log_date,
        )
        res = await self._session.execute(stmt)
        model = res.scalar_one_or_none()
        return model.to_domain() if model else None

    async def list_symptom_logs(
        self,
        user_id: str,
        start_date: date | None = None,
        end_date: date | None = None,
    ) -> list[CycleSymptomLog]:
        user_uuid = uuid.UUID(user_id)
        stmt = select(CycleSymptomLogModel).where(
            CycleSymptomLogModel.user_id == user_uuid
        )
        if start_date is not None:
            stmt = stmt.where(CycleSymptomLogModel.log_date >= start_date)
        if end_date is not None:
            stmt = stmt.where(CycleSymptomLogModel.log_date <= end_date)

        stmt = stmt.order_by(CycleSymptomLogModel.log_date.asc())
        res = await self._session.execute(stmt)
        models = res.scalars().all()
        return [m.to_domain() for m in models]
