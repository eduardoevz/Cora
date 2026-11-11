import uuid
from typing import Any, Protocol

from app.modules.maternal_care.domain.models.pregnancy_episode import (
    BirthPlanPreference,
    PregnancyEpisode,
    PrenatalAppointment,
)


class IPregnancyRepository(Protocol):
    """Port for persistence of pregnancy episodes, vitals, timers, and birth plans."""

    async def get_active_episode(
        self, user_id: uuid.UUID
    ) -> PregnancyEpisode | None: ...

    async def create_episode(self, episode: PregnancyEpisode) -> PregnancyEpisode: ...

    async def update_episode(self, episode: PregnancyEpisode) -> PregnancyEpisode: ...

    async def save_vitals_log(self, vitals_data: dict[str, Any]) -> dict[str, Any]: ...

    async def get_vitals_history(
        self, pregnancy_episode_id: uuid.UUID, limit: int = 50
    ) -> list[dict[str, Any]]: ...

    async def save_contraction_session(
        self, session_data: dict[str, Any]
    ) -> dict[str, Any]: ...

    async def get_latest_contraction_sessions(
        self, pregnancy_episode_id: uuid.UUID, limit: int = 10
    ) -> list[dict[str, Any]]: ...

    async def save_kick_session(
        self, session_data: dict[str, Any]
    ) -> dict[str, Any]: ...

    async def get_latest_kick_sessions(
        self, pregnancy_episode_id: uuid.UUID, limit: int = 10
    ) -> list[dict[str, Any]]: ...

    async def get_birth_plan(
        self, pregnancy_episode_id: uuid.UUID
    ) -> BirthPlanPreference | None: ...

    async def save_birth_plan(
        self,
        pregnancy_episode_id: uuid.UUID,
        user_id: uuid.UUID,
        birth_plan: BirthPlanPreference,
    ) -> BirthPlanPreference: ...

    async def list_appointments(
        self, pregnancy_episode_id: uuid.UUID
    ) -> list[PrenatalAppointment]: ...

    async def create_appointment(
        self, appointment: PrenatalAppointment, user_id: uuid.UUID
    ) -> PrenatalAppointment: ...

    async def toggle_appointment_completion(
        self,
        appointment_id: uuid.UUID,
        is_completed: bool,
        user_id: uuid.UUID | None = None,
    ) -> PrenatalAppointment | None: ...
