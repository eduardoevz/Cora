from abc import ABC, abstractmethod
from datetime import date

from app.modules.clinical_tracking.domain.models.preconception_checklist import (
    PreconceptionChecklist,
)
from app.modules.clinical_tracking.domain.value_objects.fertility_biomarkers import (
    DailyFertilityLog,
)


class IFertilityRepository(ABC):
    """Port for fertility biomarker logs and preconception checklist persistence."""

    @abstractmethod
    async def upsert_daily_fertility_log(
        self, user_id: str, log: DailyFertilityLog
    ) -> DailyFertilityLog:
        """Saves or updates daily fertility observation for a user and date."""

    @abstractmethod
    async def get_daily_fertility_log(
        self, user_id: str, log_date: date
    ) -> DailyFertilityLog | None:
        """Retrieves fertility observation for a specific date if recorded."""

    @abstractmethod
    async def list_fertility_logs_between(
        self, user_id: str, start_date: date, end_date: date
    ) -> list[DailyFertilityLog]:
        """Lists daily fertility observations in date ascending order."""

    @abstractmethod
    async def get_preconception_checklist(
        self, user_id: str
    ) -> PreconceptionChecklist | None:
        """Retrieves preconception checklist for a user."""

    @abstractmethod
    async def upsert_preconception_checklist(
        self, checklist: PreconceptionChecklist
    ) -> PreconceptionChecklist:
        """Saves or updates preconception checklist."""
