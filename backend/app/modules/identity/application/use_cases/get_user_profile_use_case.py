from app.core.security import AuthenticatedUser
from app.modules.identity.application.ports.user_profile_repository_port import (
    IUserProfileRepository,
)
from app.modules.identity.domain.exceptions.identity_exceptions import (
    UserProfileNotFoundError,
)
from app.modules.identity.domain.models.user_profile import UserProfile


class GetUserProfileUseCase:
    """Retrieves the profile of the currently authenticated user."""

    def __init__(self, repository: IUserProfileRepository) -> None:
        self._repository = repository

    async def execute(self, user: AuthenticatedUser) -> UserProfile:
        profile = await self._repository.get_by_firebase_uid(user.firebase_uid)
        if profile is None:
            raise UserProfileNotFoundError(user.firebase_uid)
        return profile
