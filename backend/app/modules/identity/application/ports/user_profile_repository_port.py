from typing import Protocol
from uuid import UUID

from app.modules.identity.domain.models.user_profile import UserProfile


class IUserProfileRepository(Protocol):
    """Port for persistence and retrieval of UserProfile aggregates."""

    async def get_by_id(self, user_id: UUID) -> UserProfile | None:
        """Find profile by internal UUID."""
        ...

    async def get_by_firebase_uid(self, firebase_uid: str) -> UserProfile | None:
        """Find profile by external Firebase UID."""
        ...

    async def save(self, profile: UserProfile) -> None:
        """Persist or update profile with all longitudinal transitions."""
        ...
