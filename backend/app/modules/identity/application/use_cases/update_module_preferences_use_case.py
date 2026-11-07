from app.core.security import AuthenticatedUser
from app.modules.identity.application.dtos.identity_dtos import (
    UpdateModulePreferencesCommand,
)
from app.modules.identity.application.ports.user_profile_repository_port import (
    IUserProfileRepository,
)
from app.modules.identity.domain.exceptions.identity_exceptions import (
    UserProfileNotFoundError,
)
from app.modules.identity.domain.models.user_profile import UserProfile


class UpdateModulePreferencesUseCase:
    """Updates active secondary modules preferences for the authenticated user."""

    def __init__(self, repository: IUserProfileRepository) -> None:
        self._repository = repository

    async def execute(
        self,
        user: AuthenticatedUser,
        command: UpdateModulePreferencesCommand,
    ) -> UserProfile:
        profile = await self._repository.get_by_firebase_uid(user.firebase_uid)
        if profile is None:
            raise UserProfileNotFoundError(user.firebase_uid)

        profile.update_module_preferences(list(command.enabled_modules))
        await self._repository.save(profile)
        return profile
