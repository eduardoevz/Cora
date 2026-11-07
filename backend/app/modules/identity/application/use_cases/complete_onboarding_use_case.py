from uuid import uuid4

from app.core.security import AuthenticatedUser
from app.modules.identity.application.dtos.identity_dtos import (
    CompleteOnboardingCommand,
)
from app.modules.identity.application.ports.user_profile_repository_port import (
    IUserProfileRepository,
)
from app.modules.identity.domain.exceptions.identity_exceptions import (
    UserProfileAlreadyExistsError,
)
from app.modules.identity.domain.models.user_profile import UserProfile
from app.modules.identity.domain.services.life_stage_state_machine import (
    LifeStageStateMachine,
)
from app.modules.identity.domain.value_objects.onboarding_context import (
    OnboardingContext,
)


class CompleteOnboardingUseCase:
    """Orchestrates initial calibration and creation of a user profile."""

    def __init__(self, repository: IUserProfileRepository) -> None:
        self._repository = repository

    async def execute(
        self,
        user: AuthenticatedUser,
        command: CompleteOnboardingCommand,
    ) -> UserProfile:
        existing = await self._repository.get_by_firebase_uid(user.firebase_uid)
        if existing is not None:
            raise UserProfileAlreadyExistsError(user.firebase_uid)

        context = OnboardingContext(
            birth_year=command.birth_year,
            primary_intents=command.primary_intents,
            hormonal_method=command.hormonal_method,
            diagnosed_conditions=command.diagnosed_conditions,
            clinical_context_completed=command.clinical_context_completed,
        )

        initial_modules = LifeStageStateMachine.get_default_modules_for_stage(
            command.current_life_stage
        )

        profile = UserProfile(
            id=uuid4(),
            firebase_uid=user.firebase_uid,
            first_name=command.first_name.strip(),
            last_name=command.last_name.strip(),
            current_life_stage=command.current_life_stage,
            onboarding_context=context,
            onboarding_completed=True,
            enabled_modules=initial_modules,
        )

        await self._repository.save(profile)
        return profile
