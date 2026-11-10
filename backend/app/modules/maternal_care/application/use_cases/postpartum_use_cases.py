import uuid
from typing import Any
from uuid import UUID

from app.modules.maternal_care.application.dtos.postpartum_dtos import (
    AddMilkStashDTO,
    EvaluateEpdsScreeningDTO,
    LogLactationSessionDTO,
    RecordPostpartumRecoveryDTO,
)
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
    EpdsQuestionnaireInput,
    EpdsScreeningService,
)
from app.modules.maternal_care.domain.services.postpartum_recovery_evaluator import (
    PostpartumRecoveryEvaluationInput,
    PostpartumRecoveryEvaluator,
)
from app.modules.maternal_care.domain.value_objects.postpartum_observations import (
    CesareanWoundStatus,
    LochiaFlow,
    LochiaStage,
    PelvicFloorSymptom,
    PerinealWoundStatus,
)


class RecordPostpartumRecoveryUseCase:
    def __init__(self, repository: IPostpartumRepository) -> None:
        self._repo = repository

    async def execute(
        self, user_id: UUID, dto: RecordPostpartumRecoveryDTO
    ) -> dict[str, Any]:
        pelvic_symptoms = [PelvicFloorSymptom(s) for s in dto.pelvic_floor_symptoms]
        if not pelvic_symptoms:
            pelvic_symptoms = [PelvicFloorSymptom.NORMAL]

        obs = PostpartumRecoveryEvaluationInput(
            days_postpartum=dto.days_postpartum,
            lochia_stage=LochiaStage(dto.lochia_stage),
            lochia_flow=LochiaFlow(dto.lochia_flow),
            foul_odor=dto.foul_odor,
            maternal_temperature_c=dto.maternal_temperature_c,
            perineal_wound_status=(
                PerinealWoundStatus(dto.perineal_wound_status)
                if dto.perineal_wound_status
                else None
            ),
            cesarean_wound_status=(
                CesareanWoundStatus(dto.cesarean_wound_status)
                if dto.cesarean_wound_status
                else None
            ),
            pelvic_floor_symptoms=pelvic_symptoms,
        )

        alerts = PostpartumRecoveryEvaluator.evaluate(obs)
        log_id = await self._repo.save_recovery_log(
            user_id=user_id,
            obs=obs,
            alerts=alerts,
            notes=dto.notes,
        )

        return {
            "id": str(log_id),
            "user_id": str(user_id),
            "days_postpartum": obs.days_postpartum,
            "lochia_stage": obs.lochia_stage.value,
            "lochia_flow": obs.lochia_flow.value,
            "foul_odor": obs.foul_odor,
            "maternal_temperature_c": obs.maternal_temperature_c,
            "perineal_wound_status": (
                obs.perineal_wound_status.value if obs.perineal_wound_status else None
            ),
            "cesarean_wound_status": (
                obs.cesarean_wound_status.value if obs.cesarean_wound_status else None
            ),
            "pelvic_floor_symptoms": [s.value for s in obs.pelvic_floor_symptoms],
            "notes": dto.notes,
            "alerts": [
                {
                    "severity": a.severity.value,
                    "category": a.category,
                    "title": a.title,
                    "message": a.message,
                    "action_recommended": a.action_recommended,
                }
                for a in alerts
            ],
        }


class GetRecentPostpartumRecoveryLogsUseCase:
    def __init__(self, repository: IPostpartumRepository) -> None:
        self._repo = repository

    async def execute(self, user_id: UUID, limit: int = 20) -> list[dict[str, Any]]:
        return await self._repo.get_recent_recovery_logs(user_id=user_id, limit=limit)


class LogLactationSessionUseCase:
    def __init__(self, repository: IPostpartumRepository) -> None:
        self._repo = repository

    async def execute(
        self, user_id: UUID, dto: LogLactationSessionDTO
    ) -> dict[str, Any]:
        session_id = str(uuid.uuid4())
        session = LactationSession(
            id=session_id,
            user_id=str(user_id),
            started_at=dto.started_at,
            ended_at=dto.ended_at,
            left_duration_seconds=dto.left_duration_seconds,
            right_duration_seconds=dto.right_duration_seconds,
            last_offered_breast=OfferedBreast(dto.last_offered_breast),
            bottle_volume_ml=dto.bottle_volume_ml,
            feeding_type=FeedingType(dto.feeding_type),
            notes=dto.notes,
        )

        await self._repo.save_lactation_session(session)

        return {
            "id": session.id,
            "user_id": session.user_id,
            "started_at": session.started_at.isoformat(),
            "ended_at": session.ended_at.isoformat(),
            "left_duration_seconds": session.left_duration_seconds,
            "right_duration_seconds": session.right_duration_seconds,
            "total_duration_seconds": session.total_duration_seconds,
            "last_offered_breast": session.last_offered_breast.value,
            "suggested_next_breast": session.suggested_next_breast.value,
            "bottle_volume_ml": session.bottle_volume_ml,
            "feeding_type": session.feeding_type.value,
            "notes": session.notes,
        }


class GetRecentLactationSessionsUseCase:
    def __init__(self, repository: IPostpartumRepository) -> None:
        self._repo = repository

    async def execute(self, user_id: UUID, limit: int = 20) -> list[dict[str, Any]]:
        sessions = await self._repo.get_recent_lactation_sessions(
            user_id=user_id, limit=limit
        )
        return [
            {
                "id": s.id,
                "user_id": s.user_id,
                "started_at": s.started_at.isoformat(),
                "ended_at": s.ended_at.isoformat(),
                "left_duration_seconds": s.left_duration_seconds,
                "right_duration_seconds": s.right_duration_seconds,
                "total_duration_seconds": s.total_duration_seconds,
                "last_offered_breast": s.last_offered_breast.value,
                "suggested_next_breast": s.suggested_next_breast.value,
                "bottle_volume_ml": s.bottle_volume_ml,
                "feeding_type": s.feeding_type.value,
                "notes": s.notes,
            }
            for s in sessions
        ]


class AddMilkStashUseCase:
    def __init__(self, repository: IPostpartumRepository) -> None:
        self._repo = repository

    async def execute(self, user_id: UUID, dto: AddMilkStashDTO) -> dict[str, Any]:
        entry = MilkStashEntry.create(
            user_id=str(user_id),
            pumped_at=dto.pumped_at,
            volume_ml=dto.volume_ml,
            storage_location=StorageLocation(dto.storage_location),
            notes=dto.notes,
        )
        await self._repo.save_milk_stash_entry(entry)

        return {
            "id": entry.id,
            "user_id": entry.user_id,
            "pumped_at": entry.pumped_at.isoformat(),
            "volume_ml": entry.volume_ml,
            "storage_location": entry.storage_location.value,
            "expires_at": entry.expires_at.isoformat(),
            "is_consumed": entry.is_consumed,
            "consumed_at": (
                entry.consumed_at.isoformat() if entry.consumed_at else None
            ),
            "notes": entry.notes,
        }


class GetActiveMilkStashUseCase:
    def __init__(self, repository: IPostpartumRepository) -> None:
        self._repo = repository

    async def execute(self, user_id: UUID) -> list[dict[str, Any]]:
        entries = await self._repo.get_active_milk_stash(user_id=user_id)
        return [
            {
                "id": e.id,
                "user_id": e.user_id,
                "pumped_at": e.pumped_at.isoformat(),
                "volume_ml": e.volume_ml,
                "storage_location": e.storage_location.value,
                "expires_at": e.expires_at.isoformat(),
                "is_consumed": e.is_consumed,
                "consumed_at": (e.consumed_at.isoformat() if e.consumed_at else None),
                "notes": e.notes,
            }
            for e in entries
        ]


class ConsumeMilkStashUseCase:
    def __init__(self, repository: IPostpartumRepository) -> None:
        self._repo = repository

    async def execute(self, stash_id: UUID, user_id: UUID) -> dict[str, Any] | None:
        entry = await self._repo.mark_milk_stash_consumed(
            stash_id=stash_id, user_id=user_id
        )
        if entry is None:
            return None
        return {
            "id": entry.id,
            "user_id": entry.user_id,
            "pumped_at": entry.pumped_at.isoformat(),
            "volume_ml": entry.volume_ml,
            "storage_location": entry.storage_location.value,
            "expires_at": entry.expires_at.isoformat(),
            "is_consumed": entry.is_consumed,
            "consumed_at": (
                entry.consumed_at.isoformat() if entry.consumed_at else None
            ),
            "notes": entry.notes,
        }


class EvaluateEpdsScreeningUseCase:
    def __init__(self, repository: IPostpartumRepository) -> None:
        self._repo = repository

    async def execute(
        self, user_id: UUID, dto: EvaluateEpdsScreeningDTO
    ) -> dict[str, Any]:
        inputs = EpdsQuestionnaireInput(
            item_1=dto.responses.get("item_1", 0),
            item_2=dto.responses.get("item_2", 0),
            item_3=dto.responses.get("item_3", 0),
            item_4=dto.responses.get("item_4", 0),
            item_5=dto.responses.get("item_5", 0),
            item_6=dto.responses.get("item_6", 0),
            item_7=dto.responses.get("item_7", 0),
            item_8=dto.responses.get("item_8", 0),
            item_9=dto.responses.get("item_9", 0),
            item_10=dto.responses.get("item_10", 0),
        )

        assessment = EpdsScreeningService.evaluate(inputs)
        screening_id = await self._repo.save_epds_screening(
            user_id=user_id,
            days_postpartum=dto.days_postpartum,
            responses=inputs,
            assessment=assessment,
        )

        return {
            "id": str(screening_id),
            "user_id": str(user_id),
            "days_postpartum": dto.days_postpartum,
            "responses": dto.responses,
            "total_score": assessment.total_score,
            "item_10_score": assessment.item_10_score,
            "self_harm_risk": assessment.self_harm_risk,
            "severity": assessment.severity.value,
            "clinical_summary": assessment.message,
            "action_recommended": assessment.action_recommended,
        }


class GetLatestEpdsScreeningUseCase:
    def __init__(self, repository: IPostpartumRepository) -> None:
        self._repo = repository

    async def execute(self, user_id: UUID) -> dict[str, Any] | None:
        return await self._repo.get_latest_epds_screening(user_id=user_id)
