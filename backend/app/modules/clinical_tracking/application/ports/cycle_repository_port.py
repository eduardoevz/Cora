from abc import ABC, abstractmethod
from datetime import date

from app.modules.clinical_tracking.domain.models.menstrual_cycle import (
    CycleSymptomLog,
    MenstrualCycle,
)


class ICycleRepository(ABC):
    """Port defining persistence operations for menstrual cycles and symptoms."""

    @abstractmethod
    async def save_cycle(self, cycle: MenstrualCycle) -> MenstrualCycle:
        """Saves or updates a menstrual cycle."""
        pass

    @abstractmethod
    async def get_cycle_by_id(self, cycle_id: str) -> MenstrualCycle | None:
        """Retrieves a single cycle by its identifier."""
        pass

    @abstractmethod
    async def get_current_cycle(self, user_id: str) -> MenstrualCycle | None:
        """Retrieves the active ongoing menstrual cycle for a user."""
        pass

    @abstractmethod
    async def list_cycles(self, user_id: str, limit: int = 12) -> list[MenstrualCycle]:
        """Lists past and current cycles ordered by start_date descending."""
        pass

    @abstractmethod
    async def save_symptom_log(self, log: CycleSymptomLog) -> CycleSymptomLog:
        """Upserts a daily symptom and bleeding log."""
        pass

    @abstractmethod
    async def get_symptom_log_by_date(
        self, user_id: str, log_date: date
    ) -> CycleSymptomLog | None:
        """Retrieves the symptom log for a given date."""
        pass

    @abstractmethod
    async def list_symptom_logs(
        self,
        user_id: str,
        start_date: date | None = None,
        end_date: date | None = None,
    ) -> list[CycleSymptomLog]:
        """Lists symptom logs for a user, optionally filtered by date range."""
        pass
