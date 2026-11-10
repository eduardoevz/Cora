"""Repository protocol for mature health data persistence."""

from typing import Protocol
from uuid import UUID

from app.modules.mature_health.domain.models.bone_fall_and_urogynecology import (
    ContinenceAndPelvicLog,
    DexaBoneResult,
    FallRiskAssessment,
)
from app.modules.mature_health.domain.models.trusted_support_contact import (
    TrustedSupportContact,
)
from app.modules.mature_health.domain.models.vasomotor_and_metabolic_logs import (
    CardiometabolicPanel,
    HotFlashEpisode,
    VaginalBleedingObservation,
)


class IMatureHealthRepository(Protocol):
    """Port for persisting mature health records."""

    async def save_hot_flash_episode(
        self, episode: HotFlashEpisode
    ) -> HotFlashEpisode: ...

    async def list_hot_flash_episodes(
        self, user_id: UUID, limit: int = 50
    ) -> list[HotFlashEpisode]: ...

    async def save_cardiometabolic_panel(
        self,
        panel: CardiometabolicPanel,
        risk_level: str,
        flagged_params: list[str],
    ) -> CardiometabolicPanel: ...

    async def get_latest_cardiometabolic_panel(
        self, user_id: UUID
    ) -> tuple[CardiometabolicPanel, str, list[str]] | None: ...

    async def save_bleeding_observation(
        self, obs: VaginalBleedingObservation, is_alert_triggered: bool
    ) -> VaginalBleedingObservation: ...

    async def list_bleeding_observations(
        self, user_id: UUID, limit: int = 50
    ) -> list[VaginalBleedingObservation]: ...

    async def save_dexa_bone_result(
        self, dexa: DexaBoneResult, category: str
    ) -> DexaBoneResult: ...

    async def get_latest_dexa_bone_result(
        self, user_id: UUID
    ) -> tuple[DexaBoneResult, str] | None: ...

    async def save_fall_risk_assessment(
        self, assessment: FallRiskAssessment, risk_level: str, score: int
    ) -> FallRiskAssessment: ...

    async def get_latest_fall_risk_assessment(
        self, user_id: UUID
    ) -> tuple[FallRiskAssessment, str, int] | None: ...

    async def save_pelvic_log(
        self, log: ContinenceAndPelvicLog
    ) -> ContinenceAndPelvicLog: ...

    async def list_pelvic_logs(
        self, user_id: UUID, limit: int = 50
    ) -> list[ContinenceAndPelvicLog]: ...

    async def save_support_contact(
        self, contact: TrustedSupportContact
    ) -> TrustedSupportContact: ...

    async def get_support_contact(
        self, user_id: UUID
    ) -> TrustedSupportContact | None: ...
