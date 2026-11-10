from typing import Protocol
from uuid import UUID

from app.modules.maternal_care.domain.models.lactation_and_milk_stash import (
    LactationSession,
    MilkStashEntry,
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


class IPostpartumRepository(Protocol):
    async def save_recovery_log(
        self,
        user_id: UUID,
        obs: PostpartumRecoveryEvaluationInput,
        alerts: list[PostpartumClinicalAlert],
        notes: str | None = None,
    ) -> UUID: ...

    async def get_recent_recovery_logs(
        self, user_id: UUID, limit: int = 20
    ) -> list[dict[str, object]]: ...

    async def save_lactation_session(self, session: LactationSession) -> None: ...

    async def get_recent_lactation_sessions(
        self, user_id: UUID, limit: int = 20
    ) -> list[LactationSession]: ...

    async def save_milk_stash_entry(self, entry: MilkStashEntry) -> None: ...

    async def get_active_milk_stash(self, user_id: UUID) -> list[MilkStashEntry]: ...

    async def mark_milk_stash_consumed(
        self, stash_id: UUID, user_id: UUID
    ) -> MilkStashEntry | None: ...

    async def save_epds_screening(
        self,
        user_id: UUID,
        days_postpartum: int,
        responses: EpdsQuestionnaireInput,
        assessment: EpdsAssessmentResult,
    ) -> UUID: ...

    async def get_latest_epds_screening(
        self, user_id: UUID
    ) -> dict[str, object] | None: ...
