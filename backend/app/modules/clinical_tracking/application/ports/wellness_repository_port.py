from datetime import date
from typing import Protocol

from app.modules.clinical_tracking.domain.models.daily_wellness_log import (
    DailyWellnessLog,
)


class IWellnessRepository(Protocol):
    """Port for daily wellness logs persistence."""

    async def upsert(self, log: DailyWellnessLog) -> DailyWellnessLog:
        """Persist or update a daily wellness log."""
        ...

    async def get_by_date(
        self, user_id: str, log_date: date
    ) -> DailyWellnessLog | None:
        """Retrieve daily wellness record for a specific user and date."""
        ...

    async def get_history(
        self, user_id: str, start_date: date, end_date: date
    ) -> list[DailyWellnessLog]:
        """Retrieve historical logs for a date range."""
        ...
