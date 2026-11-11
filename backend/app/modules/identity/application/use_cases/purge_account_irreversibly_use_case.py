"""Use case for cascading, irreversible account purge across DB and R2."""

from sqlalchemy import delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.identity.domain.models.user_profile import UserProfile
from app.modules.identity.infrastructure.orm.identity_models import (
    UserProfileModel,
)
from app.modules.medical_records.application.ports.file_storage_port import (
    IFileStorage,
)

REQUIRED_CONFIRMATION_PHRASE = "ELIMINAR MI CUENTA CORA"


class PurgeAccountIrreversiblyUseCase:
    """Permanently purges all clinical records and attachments without soft-deletes."""

    def __init__(self, file_storage: IFileStorage | None = None) -> None:
        self._file_storage = file_storage

    async def execute(
        self,
        profile: UserProfile,
        confirm_phrase: str,
        session: AsyncSession,
    ) -> None:
        if confirm_phrase.strip() != REQUIRED_CONFIRMATION_PHRASE:
            msg = (
                "Frase de confirmación inválida. "
                f"Debes escribir exactamente '{REQUIRED_CONFIRMATION_PHRASE}'."
            )
            raise ValueError(msg)

        user_id = profile.id

        # 1. Clean Cloudflare R2 object prefix if storage adapter available
        if self._file_storage is not None:
            await self._file_storage.delete_user_prefix(user_id)

        # 2. Delete UserProfile in PostgreSQL (cascades to all 9 modules)
        stmt = delete(UserProfileModel).where(UserProfileModel.id == user_id)
        await session.execute(stmt)
        await session.commit()
