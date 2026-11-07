import uuid
from datetime import UTC, date, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.clinical_tracking.application.ports.wellness_repository_port import (
    IWellnessRepository,
)
from app.modules.clinical_tracking.domain.models.daily_wellness_log import (
    DailyWellnessLog,
)
from app.modules.clinical_tracking.infrastructure.orm.wellness_orm import (
    DailyWellnessLogModel,
)


class PostgresWellnessRepository(IWellnessRepository):
    """PostgreSQL adapter implementing IWellnessRepository over SQLAlchemy 2.0."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def upsert(self, log: DailyWellnessLog) -> DailyWellnessLog:
        user_uuid = uuid.UUID(log.user_id)
        stmt = select(DailyWellnessLogModel).where(
            DailyWellnessLogModel.user_id == user_uuid,
            DailyWellnessLogModel.log_date == log.log_date,
        )
        res = await self._session.execute(stmt)
        existing = res.scalar_one_or_none()

        if existing is None:
            model = DailyWellnessLogModel.from_domain(log)
            self._session.add(model)
        else:
            existing.sleep_hours = (
                log.sleep_hours.value if log.sleep_hours is not None else None
            )
            existing.sleep_quality = (
                log.sleep_quality.value if log.sleep_quality is not None else None
            )
            existing.energy_level = (
                log.energy_level.value if log.energy_level is not None else None
            )
            existing.hydration_ml = (
                log.hydration_ml.value if log.hydration_ml is not None else None
            )
            existing.exercise_minutes = (
                log.exercise_minutes.value if log.exercise_minutes is not None else None
            )
            existing.mood_tags = [m.value for m in log.mood_tags]
            existing.notes = log.notes
            existing.updated_at = datetime.now(UTC)

        await self._session.commit()
        return log

    async def get_by_date(
        self, user_id: str, log_date: date
    ) -> DailyWellnessLog | None:
        user_uuid = uuid.UUID(user_id)
        stmt = select(DailyWellnessLogModel).where(
            DailyWellnessLogModel.user_id == user_uuid,
            DailyWellnessLogModel.log_date == log_date,
        )
        res = await self._session.execute(stmt)
        model = res.scalar_one_or_none()
        return model.to_domain() if model else None

    async def get_history(
        self, user_id: str, start_date: date, end_date: date
    ) -> list[DailyWellnessLog]:
        user_uuid = uuid.UUID(user_id)
        stmt = (
            select(DailyWellnessLogModel)
            .where(
                DailyWellnessLogModel.user_id == user_uuid,
                DailyWellnessLogModel.log_date >= start_date,
                DailyWellnessLogModel.log_date <= end_date,
            )
            .order_by(DailyWellnessLogModel.log_date.asc())
        )
        res = await self._session.execute(stmt)
        models = res.scalars().all()
        return [m.to_domain() for m in models]
