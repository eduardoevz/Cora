from uuid import UUID

import pytest
from fastapi import HTTPException

from app.core.security import AuthenticatedUser
from app.modules.identity.application.dtos.identity_dtos import (
    CompleteOnboardingCommand,
    SwitchLifeStageCommand,
    UpdateModulePreferencesCommand,
)
from app.modules.identity.application.ports.user_profile_repository_port import (
    IUserProfileRepository,
)
from app.modules.identity.application.use_cases.complete_onboarding_use_case import (
    CompleteOnboardingUseCase,
)
from app.modules.identity.application.use_cases.switch_life_stage_use_case import (
    SwitchLifeStageUseCase,
)
from app.modules.identity.application.use_cases.update_module_preferences_use_case import (  # noqa: E501
    UpdateModulePreferencesUseCase,
)
from app.modules.identity.domain.exceptions.identity_exceptions import (
    UserProfileAlreadyExistsError,
    UserProfileNotFoundError,
)
from app.modules.identity.domain.models.user_profile import UserProfile
from app.modules.identity.domain.value_objects.life_stage import (
    LifeStage,
    TransitionReason,
)
from app.modules.identity.domain.value_objects.onboarding_context import (
    DiagnosedCondition,
    HormonalMethod,
    PrimaryIntent,
)
from app.modules.identity.infrastructure.adapters.firebase_token_verifier import (
    MockTokenVerifier,
)


class InMemoryUserProfileRepository(IUserProfileRepository):
    """In-memory double for unit tests."""

    def __init__(self) -> None:
        self.profiles: dict[UUID, UserProfile] = {}
        self.by_firebase_uid: dict[str, UUID] = {}

    async def get_by_id(self, user_id: UUID) -> UserProfile | None:
        return self.profiles.get(user_id)

    async def get_by_firebase_uid(self, firebase_uid: str) -> UserProfile | None:
        profile_id = self.by_firebase_uid.get(firebase_uid)
        if profile_id:
            return self.profiles.get(profile_id)
        return None

    async def save(self, profile: UserProfile) -> None:
        self.profiles[profile.id] = profile
        self.by_firebase_uid[profile.firebase_uid] = profile.id


@pytest.fixture
def repository() -> InMemoryUserProfileRepository:
    return InMemoryUserProfileRepository()


@pytest.fixture
def current_user() -> AuthenticatedUser:
    return AuthenticatedUser(
        firebase_uid="uid-camila-123",
        email="camila@example.com",
    )


async def test_complete_onboarding_creates_profile_and_default_modules(
    repository: InMemoryUserProfileRepository,
    current_user: AuthenticatedUser,
) -> None:
    use_case = CompleteOnboardingUseCase(repository=repository)
    command = CompleteOnboardingCommand(
        first_name="Camila",
        last_name="Torres",
        current_life_stage=LifeStage.REGULAR_ADULT,
        birth_year=1995,
        primary_intents=[PrimaryIntent.CYCLE_AND_SYMPTOMS],
        hormonal_method=HormonalMethod.COMBINED_ORAL_PILL,
        diagnosed_conditions=[DiagnosedCondition.PCOS],
        clinical_context_completed=True,
    )

    profile = await use_case.execute(user=current_user, command=command)

    assert profile.firebase_uid == current_user.firebase_uid
    assert profile.first_name == "Camila"
    assert profile.current_life_stage == LifeStage.REGULAR_ADULT
    assert profile.onboarding_completed is True
    assert profile.onboarding_context.clinical_context_completed is True
    assert "cycle_tracking" in profile.enabled_modules

    saved = await repository.get_by_firebase_uid(current_user.firebase_uid)
    assert saved is not None
    assert saved.id == profile.id


async def test_complete_onboarding_rejects_duplicate_creation(
    repository: InMemoryUserProfileRepository,
    current_user: AuthenticatedUser,
) -> None:
    use_case = CompleteOnboardingUseCase(repository=repository)
    command = CompleteOnboardingCommand(
        first_name="Camila",
        last_name="Torres",
        current_life_stage=LifeStage.REGULAR_ADULT,
        birth_year=1995,
        primary_intents=[PrimaryIntent.CYCLE_AND_SYMPTOMS],
    )
    await use_case.execute(user=current_user, command=command)

    with pytest.raises(UserProfileAlreadyExistsError):
        await use_case.execute(user=current_user, command=command)


async def test_switch_life_stage_use_case(
    repository: InMemoryUserProfileRepository,
    current_user: AuthenticatedUser,
) -> None:
    onboarding_use_case = CompleteOnboardingUseCase(repository=repository)
    await onboarding_use_case.execute(
        user=current_user,
        command=CompleteOnboardingCommand(
            first_name="Camila",
            last_name="Torres",
            current_life_stage=LifeStage.CONCEPTION_SEARCH,
            birth_year=1995,
            primary_intents=[PrimaryIntent.FAMILY_PLANNING],
        ),
    )

    switch_use_case = SwitchLifeStageUseCase(repository=repository)
    updated_profile = await switch_use_case.execute(
        user=current_user,
        command=SwitchLifeStageCommand(
            target_stage=LifeStage.PREGNANCY,
            reason=TransitionReason.CONCEPTION_CONFIRMED,
            notes="Embarazo confirmado",
        ),
    )

    assert updated_profile.current_life_stage == LifeStage.PREGNANCY
    assert len(updated_profile.transition_history) == 1
    assert "fetal_development" in updated_profile.enabled_modules


async def test_switch_life_stage_fails_when_profile_not_found(
    repository: InMemoryUserProfileRepository,
    current_user: AuthenticatedUser,
) -> None:
    switch_use_case = SwitchLifeStageUseCase(repository=repository)
    with pytest.raises(UserProfileNotFoundError):
        await switch_use_case.execute(
            user=current_user,
            command=SwitchLifeStageCommand(
                target_stage=LifeStage.PREGNANCY,
                reason=TransitionReason.CONCEPTION_CONFIRMED,
            ),
        )


async def test_update_module_preferences_use_case(
    repository: InMemoryUserProfileRepository,
    current_user: AuthenticatedUser,
) -> None:
    onboarding_use_case = CompleteOnboardingUseCase(repository=repository)
    await onboarding_use_case.execute(
        user=current_user,
        command=CompleteOnboardingCommand(
            first_name="Camila",
            last_name="Torres",
            current_life_stage=LifeStage.REGULAR_ADULT,
            birth_year=1995,
            primary_intents=[PrimaryIntent.CYCLE_AND_SYMPTOMS],
        ),
    )

    prefs_use_case = UpdateModulePreferencesUseCase(repository=repository)
    updated = await prefs_use_case.execute(
        user=current_user,
        command=UpdateModulePreferencesCommand(
            enabled_modules=["cycle_tracking", "symptom_logger"],
        ),
    )

    assert updated.enabled_modules == ["cycle_tracking", "symptom_logger"]


async def test_token_verifier_mock_authenticates_valid_token() -> None:
    verifier = MockTokenVerifier()
    user = await verifier.verify_token("test-token:uid-sofia-456:sofia@cora.health")
    assert user.firebase_uid == "uid-sofia-456"
    assert user.email == "sofia@cora.health"


async def test_token_verifier_mock_rejects_invalid_token() -> None:
    verifier = MockTokenVerifier()
    with pytest.raises(HTTPException) as exc_info:
        await verifier.verify_token("invalid-malformed-token")
    assert exc_info.value.status_code == 401
