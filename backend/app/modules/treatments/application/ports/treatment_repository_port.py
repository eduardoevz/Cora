from datetime import datetime
from typing import Protocol

from app.modules.treatments.domain.models.treatment_regimen import (
    DoseIntakeLog,
    TreatmentRegimen,
)


class ITreatmentRepository(Protocol):
    """Port for treatments and dose intakes persistence."""

    async def save_regimen(self, regimen: TreatmentRegimen) -> TreatmentRegimen:
        """Persist or update a treatment regimen."""
        ...

    async def get_regimens(
        self, user_id: str, is_active: bool | None = None
    ) -> list[TreatmentRegimen]:
        """List treatment regimens for a user."""
        ...

    async def get_regimen_by_id(self, regimen_id: str) -> TreatmentRegimen | None:
        """Retrieve regimen by unique ID."""
        ...

    async def log_intake(self, intake: DoseIntakeLog) -> DoseIntakeLog:
        """Record or update an individual dose intake."""
        ...

    async def get_intakes(
        self, regimen_id: str, start_dt: datetime, end_dt: datetime
    ) -> list[DoseIntakeLog]:
        """List dose intakes for a regimen in a datetime range."""
        ...
