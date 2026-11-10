import uuid
from datetime import UTC, datetime
from decimal import Decimal
from typing import Any
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.maternal_care.application.ports.postpartum_repository_port import (
    IPostpartumRepository,
)
from app.modules.maternal_care.domain.models.lactation_and_milk_stash import (
    FeedingType,
    LactationSession,
    MilkStashEntry,
    OfferedBreast,
    StorageLocation,
)
from app.modules.maternal_care.domain.services.epds_screening_service import (
    EpdsAssessmentResult,
    EpdsQuestionnaireInput,
)
from app.modules.maternal_care.domain.services.postpartum_recovery_evaluator import (
    PostpartumRecoveryEvaluationInput,
)
from app.modules.maternal_care.domain.value_objects.postpartum_observations import (
    PostpartumClinicalAlert,
)
from app.modules.maternal_care.infrastructure.orm.postpartum_orm import (
    EpdsScreeningModel,
    LactationSessionModel,
    MilkStashEntryModel,
    PostpartumRecoveryLogModel,
)


class PostgresPostpartumRepository(IPostpartumRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def save_recovery_log(
        self,
        user_id: UUID,
        obs: PostpartumRecoveryEvaluationInput,
        alerts: list[PostpartumClinicalAlert],
        notes: str | None = None,
    ) -> UUID:
        log_id = uuid.uuid4()
        alerts_data: list[dict[str, Any]] = [
            {
                "severity": a.severity.value,
                "category": a.category,
                "title": a.title,
                "message": a.message,
                "action_recommended": a.action_recommended,
            }
            for a in alerts
        ]
        symptoms_data: list[str] = [s.value for s in obs.pelvic_floor_symptoms]

        temp_decimal = (
            Decimal(str(obs.maternal_temperature_c))
            if obs.maternal_temperature_c is not None
            else None
        )

        model = PostpartumRecoveryLogModel(
            id=log_id,
            user_id=user_id,
            logged_at=datetime.now(UTC),
            days_postpartum=obs.days_postpartum,
            lochia_stage=obs.lochia_stage.value,
            lochia_flow=obs.lochia_flow.value,
            foul_odor=obs.foul_odor,
            maternal_temperature_c=temp_decimal,
            perineal_wound_status=(
                obs.perineal_wound_status.value if obs.perineal_wound_status else None
            ),
            cesarean_wound_status=(
                obs.cesarean_wound_status.value if obs.cesarean_wound_status else None
            ),
            pelvic_floor_symptoms=symptoms_data,
            notes=notes,
            alerts=alerts_data,
        )
        self._session.add(model)
        await self._session.commit()
        return log_id

    async def get_recent_recovery_logs(
        self, user_id: UUID, limit: int = 20
    ) -> list[dict[str, object]]:
        stmt = (
            select(PostpartumRecoveryLogModel)
            .where(PostpartumRecoveryLogModel.user_id == user_id)
            .order_by(PostpartumRecoveryLogModel.logged_at.desc())
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        models = result.scalars().all()

        return [
            {
                "id": str(m.id),
                "user_id": str(m.user_id),
                "logged_at": m.logged_at.isoformat(),
                "days_postpartum": m.days_postpartum,
                "lochia_stage": m.lochia_stage,
                "lochia_flow": m.lochia_flow,
                "foul_odor": m.foul_odor,
                "maternal_temperature_c": (
                    float(m.maternal_temperature_c)
                    if m.maternal_temperature_c is not None
                    else None
                ),
                "perineal_wound_status": m.perineal_wound_status,
                "cesarean_wound_status": m.cesarean_wound_status,
                "pelvic_floor_symptoms": m.pelvic_floor_symptoms,
                "notes": m.notes,
                "alerts": m.alerts,
            }
            for m in models
        ]

    async def save_lactation_session(self, session: LactationSession) -> None:
        session_uuid = UUID(session.id)
        user_uuid = UUID(session.user_id)
        bottle_vol = (
            Decimal(str(session.bottle_volume_ml))
            if session.bottle_volume_ml is not None
            else None
        )

        model = LactationSessionModel(
            id=session_uuid,
            user_id=user_uuid,
            started_at=session.started_at,
            ended_at=session.ended_at,
            left_duration_seconds=session.left_duration_seconds,
            right_duration_seconds=session.right_duration_seconds,
            last_offered_breast=session.last_offered_breast.value,
            bottle_volume_ml=bottle_vol,
            feeding_type=session.feeding_type.value,
            notes=session.notes,
        )
        self._session.add(model)
        await self._session.commit()

    async def get_recent_lactation_sessions(
        self, user_id: UUID, limit: int = 20
    ) -> list[LactationSession]:
        stmt = (
            select(LactationSessionModel)
            .where(LactationSessionModel.user_id == user_id)
            .order_by(LactationSessionModel.started_at.desc())
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        models = result.scalars().all()

        return [
            LactationSession(
                id=str(m.id),
                user_id=str(m.user_id),
                started_at=m.started_at,
                ended_at=m.ended_at,
                left_duration_seconds=m.left_duration_seconds,
                right_duration_seconds=m.right_duration_seconds,
                last_offered_breast=OfferedBreast(m.last_offered_breast),
                bottle_volume_ml=(
                    float(m.bottle_volume_ml)
                    if m.bottle_volume_ml is not None
                    else None
                ),
                feeding_type=FeedingType(m.feeding_type),
                notes=m.notes,
            )
            for m in models
        ]

    async def save_milk_stash_entry(self, entry: MilkStashEntry) -> None:
        entry_uuid = UUID(entry.id)
        user_uuid = UUID(entry.user_id)

        model = MilkStashEntryModel(
            id=entry_uuid,
            user_id=user_uuid,
            pumped_at=entry.pumped_at,
            volume_ml=Decimal(str(entry.volume_ml)),
            storage_location=entry.storage_location.value,
            expires_at=entry.expires_at,
            is_consumed=entry.is_consumed,
            consumed_at=entry.consumed_at,
            notes=entry.notes,
        )
        self._session.add(model)
        await self._session.commit()

    async def get_active_milk_stash(self, user_id: UUID) -> list[MilkStashEntry]:
        stmt = (
            select(MilkStashEntryModel)
            .where(
                MilkStashEntryModel.user_id == user_id,
                MilkStashEntryModel.is_consumed.is_(False),
            )
            .order_by(MilkStashEntryModel.expires_at.asc())
        )
        result = await self._session.execute(stmt)
        models = result.scalars().all()

        return [
            MilkStashEntry(
                id=str(m.id),
                user_id=str(m.user_id),
                pumped_at=m.pumped_at,
                volume_ml=float(m.volume_ml),
                storage_location=StorageLocation(m.storage_location),
                expires_at=m.expires_at,
                is_consumed=m.is_consumed,
                consumed_at=m.consumed_at,
                notes=m.notes,
            )
            for m in models
        ]

    async def mark_milk_stash_consumed(
        self, stash_id: UUID, user_id: UUID
    ) -> MilkStashEntry | None:
        stmt = select(MilkStashEntryModel).where(
            MilkStashEntryModel.id == stash_id,
            MilkStashEntryModel.user_id == user_id,
        )
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        if model is None:
            return None

        model.is_consumed = True
        model.consumed_at = datetime.now(UTC)
        await self._session.commit()

        return MilkStashEntry(
            id=str(model.id),
            user_id=str(model.user_id),
            pumped_at=model.pumped_at,
            volume_ml=float(model.volume_ml),
            storage_location=StorageLocation(model.storage_location),
            expires_at=model.expires_at,
            is_consumed=model.is_consumed,
            consumed_at=model.consumed_at,
            notes=model.notes,
        )

    async def save_epds_screening(
        self,
        user_id: UUID,
        days_postpartum: int,
        responses: EpdsQuestionnaireInput,
        assessment: EpdsAssessmentResult,
    ) -> UUID:
        screening_id = uuid.uuid4()
        responses_dict = {
            "item_1": responses.item_1,
            "item_2": responses.item_2,
            "item_3": responses.item_3,
            "item_4": responses.item_4,
            "item_5": responses.item_5,
            "item_6": responses.item_6,
            "item_7": responses.item_7,
            "item_8": responses.item_8,
            "item_9": responses.item_9,
            "item_10": responses.item_10,
        }

        model = EpdsScreeningModel(
            id=screening_id,
            user_id=user_id,
            screened_at=datetime.now(UTC),
            days_postpartum=days_postpartum,
            responses=responses_dict,
            total_score=assessment.total_score,
            item_10_score=assessment.item_10_score,
            self_harm_risk=assessment.self_harm_risk,
            severity=assessment.severity.value,
            clinical_summary=assessment.message,
            action_recommended=assessment.action_recommended,
        )
        self._session.add(model)
        await self._session.commit()
        return screening_id

    async def get_latest_epds_screening(
        self, user_id: UUID
    ) -> dict[str, object] | None:
        stmt = (
            select(EpdsScreeningModel)
            .where(EpdsScreeningModel.user_id == user_id)
            .order_by(EpdsScreeningModel.screened_at.desc())
            .limit(1)
        )
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        if model is None:
            return None

        return {
            "id": str(model.id),
            "user_id": str(model.user_id),
            "screened_at": model.screened_at.isoformat(),
            "days_postpartum": model.days_postpartum,
            "responses": model.responses,
            "total_score": model.total_score,
            "item_10_score": model.item_10_score,
            "self_harm_risk": model.self_harm_risk,
            "severity": model.severity,
            "clinical_summary": model.clinical_summary,
            "action_recommended": model.action_recommended,
        }
