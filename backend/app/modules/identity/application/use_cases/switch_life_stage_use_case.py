from app.core.security import AuthenticatedUser
from app.modules.identity.application.dtos.identity_dtos import SwitchLifeStageCommand
from app.modules.identity.application.ports.user_profile_repository_port import (
    IUserProfileRepository,
)
from app.modules.identity.domain.exceptions.identity_exceptions import (
    UserProfileNotFoundError,
)
from app.modules.identity.domain.models.user_profile import UserProfile
from app.modules.identity.domain.services.life_stage_state_machine import (
    LifeStageStateMachine,
)


class SwitchLifeStageUseCase:
    """Orchestrates life stage transitions and updates user preferences."""

    def __init__(self, repository: IUserProfileRepository) -> None:
        self._repository = repository

    async def execute(
        self,
        user: AuthenticatedUser,
        command: SwitchLifeStageCommand,
    ) -> UserProfile:
        profile = await self._repository.get_by_firebase_uid(user.firebase_uid)
        if profile is None:
            raise UserProfileNotFoundError(user.firebase_uid)

        LifeStageStateMachine.transition(
            profile=profile,
            target_stage=command.target_stage,
            reason=command.reason,
            occurred_at=command.occurred_at,
            notes=command.notes,
        )

        await self._repository.save(profile)
        return profile
