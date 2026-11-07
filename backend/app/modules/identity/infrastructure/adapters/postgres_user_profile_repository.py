from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.identity.application.ports.user_profile_repository_port import (
    IUserProfileRepository,
)
from app.modules.identity.domain.models.user_profile import UserProfile
from app.modules.identity.infrastructure.orm.identity_models import (
    LifeStageTransitionModel,
    UserProfileModel,
)


class PostgresUserProfileRepository(IUserProfileRepository):
    """PostgreSQL adapter implementing IUserProfileRepository over SQLAlchemy 2.0."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_id(self, user_id: UUID) -> UserProfile | None:
        stmt = (
            select(UserProfileModel)
            .where(UserProfileModel.id == user_id)
            .options(selectinload(UserProfileModel.transitions))
        )
        res = await self._session.execute(stmt)
        model = res.scalar_one_or_none()
        return model.to_domain() if model else None

    async def get_by_firebase_uid(self, firebase_uid: str) -> UserProfile | None:
        stmt = (
            select(UserProfileModel)
            .where(UserProfileModel.firebase_uid == firebase_uid)
            .options(selectinload(UserProfileModel.transitions))
        )
        res = await self._session.execute(stmt)
        model = res.scalar_one_or_none()
        return model.to_domain() if model else None

    async def save(self, profile: UserProfile) -> None:
        stmt = (
            select(UserProfileModel)
            .where(UserProfileModel.id == profile.id)
            .options(selectinload(UserProfileModel.transitions))
        )
        res = await self._session.execute(stmt)
        existing = res.scalar_one_or_none()

        if existing is None:
            new_model = UserProfileModel.from_domain(profile)
            self._session.add(new_model)
        else:
            existing.first_name = profile.first_name
            existing.last_name = profile.last_name
            existing.current_life_stage = profile.current_life_stage.value
            existing.birth_year = profile.onboarding_context.birth_year
            existing.primary_intents = [
                i.value for i in profile.onboarding_context.primary_intents
            ]
            existing.hormonal_method = (
                profile.onboarding_context.hormonal_method.value
                if profile.onboarding_context.hormonal_method
                else None
            )
            existing.diagnosed_conditions = [
                c.value for c in profile.onboarding_context.diagnosed_conditions
            ]
            existing.clinical_context_completed = (
                profile.onboarding_context.clinical_context_completed
            )
            existing.onboarding_completed = profile.onboarding_completed
            existing.enabled_modules = list(profile.enabled_modules)
            existing.updated_at = profile.updated_at

            # Synchronize transitions
            existing_ids = {t.id for t in existing.transitions}
            for t in profile.transition_history:
                if t.id not in existing_ids:
                    existing.transitions.append(
                        LifeStageTransitionModel.from_domain(t, profile.id)
                    )

        await self._session.commit()
