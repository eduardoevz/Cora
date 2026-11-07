import uuid
from datetime import UTC, datetime

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.treatments.application.ports.treatment_repository_port import (
    ITreatmentRepository,
)
from app.modules.treatments.domain.models.treatment_regimen import (
    DoseIntakeLog,
    TreatmentRegimen,
)
from app.modules.treatments.infrastructure.orm.treatment_orm import (
    DoseIntakeLogModel,
    TreatmentRegimenModel,
)


class PostgresTreatmentRepository(ITreatmentRepository):
    """PostgreSQL adapter implementing ITreatmentRepository over SQLAlchemy 2.0."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def save_regimen(self, regimen: TreatmentRegimen) -> TreatmentRegimen:
        regimen_uuid = uuid.UUID(regimen.id)
        stmt = select(TreatmentRegimenModel).where(
            TreatmentRegimenModel.id == regimen_uuid
        )
        res = await self._session.execute(stmt)
        existing = res.scalar_one_or_none()

        if existing is None:
            model = TreatmentRegimenModel.from_domain(regimen)
            self._session.add(model)
        else:
            existing.name = regimen.name
            existing.category = regimen.category.value
            existing.dosage = regimen.dosage
            existing.schedule_type = regimen.schedule.schedule_type.value
            existing.scheduled_time = regimen.schedule.scheduled_time
            existing.active_days = regimen.schedule.active_days
            existing.break_days = regimen.schedule.break_days
            existing.interval_days = regimen.schedule.interval_days
            existing.replacement_date = regimen.schedule.replacement_date
            existing.instructions = regimen.instructions
            existing.start_date = regimen.start_date
            existing.end_date = regimen.end_date
            existing.is_active = regimen.is_active
            existing.updated_at = datetime.now(UTC)

        await self._session.commit()
        return regimen

    async def get_regimens(
        self, user_id: str, is_active: bool | None = None
    ) -> list[TreatmentRegimen]:
        user_uuid = uuid.UUID(user_id)
        conditions = [TreatmentRegimenModel.user_id == user_uuid]
        if is_active is not None:
            conditions.append(TreatmentRegimenModel.is_active == is_active)

        stmt = (
            select(TreatmentRegimenModel)
            .where(and_(*conditions))
            .order_by(TreatmentRegimenModel.created_at.desc())
        )
        res = await self._session.execute(stmt)
        models = res.scalars().all()
        return [m.to_domain() for m in models]

    async def get_regimen_by_id(self, regimen_id: str) -> TreatmentRegimen | None:
        try:
            regimen_uuid = uuid.UUID(regimen_id)
        except ValueError:
            return None

        stmt = select(TreatmentRegimenModel).where(
            TreatmentRegimenModel.id == regimen_uuid
        )
        res = await self._session.execute(stmt)
        model = res.scalar_one_or_none()
        return model.to_domain() if model else None

    async def log_intake(self, intake: DoseIntakeLog) -> DoseIntakeLog:
        if intake.client_mutation_id:
            mutation_uuid = uuid.UUID(intake.client_mutation_id)
            stmt = select(DoseIntakeLogModel).where(
                DoseIntakeLogModel.client_mutation_id == mutation_uuid
            )
            res = await self._session.execute(stmt)
            existing = res.scalar_one_or_none()
            if existing is not None:
                return existing.to_domain()

        model = DoseIntakeLogModel.from_domain(intake)
        self._session.add(model)
        await self._session.commit()
        return intake

    async def get_intakes(
        self, regimen_id: str, start_dt: datetime, end_dt: datetime
    ) -> list[DoseIntakeLog]:
        regimen_uuid = uuid.UUID(regimen_id)
        stmt = (
            select(DoseIntakeLogModel)
            .where(
                and_(
                    DoseIntakeLogModel.regimen_id == regimen_uuid,
                    DoseIntakeLogModel.scheduled_for >= start_dt,
                    DoseIntakeLogModel.scheduled_for <= end_dt,
                )
            )
            .order_by(DoseIntakeLogModel.scheduled_for.asc())
        )
        res = await self._session.execute(stmt)
        models = res.scalars().all()
        return [m.to_domain() for m in models]
