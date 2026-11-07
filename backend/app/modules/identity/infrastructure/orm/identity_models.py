import uuid
from datetime import UTC, datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.types import JSON

from app.core.database import Base
from app.modules.identity.domain.models.user_profile import (
    LifeStageTransition,
    UserProfile,
)
from app.modules.identity.domain.value_objects.life_stage import (
    LifeStage,
    TransitionReason,
)
from app.modules.identity.domain.value_objects.onboarding_context import (
    DiagnosedCondition,
    HormonalMethod,
    OnboardingContext,
    PrimaryIntent,
)

JSONType = JSON().with_variant(JSONB, "postgresql")


class UserProfileModel(Base):
    """SQLAlchemy ORM table mapping for UserProfile aggregate."""

    __tablename__ = "user_profiles"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    firebase_uid: Mapped[str] = mapped_column(
        String(128),
        unique=True,
        index=True,
        nullable=False,
    )
    first_name: Mapped[str] = mapped_column(String(100), nullable=False)
    last_name: Mapped[str] = mapped_column(String(100), nullable=False)
    current_life_stage: Mapped[str] = mapped_column(String(50), nullable=False)
    birth_year: Mapped[int] = mapped_column(Integer, nullable=False)
    primary_intents: Mapped[list[str]] = mapped_column(JSONType, nullable=False)
    hormonal_method: Mapped[str | None] = mapped_column(String(50), nullable=True)
    diagnosed_conditions: Mapped[list[str]] = mapped_column(JSONType, nullable=False)
    clinical_context_completed: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    onboarding_completed: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )
    enabled_modules: Mapped[list[str]] = mapped_column(JSONType, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(UTC), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        onupdate=lambda: datetime.now(UTC),
        nullable=False,
    )

    transitions: Mapped[list["LifeStageTransitionModel"]] = relationship(
        "LifeStageTransitionModel",
        back_populates="user_profile",
        cascade="all, delete-orphan",
        order_by="LifeStageTransitionModel.occurred_at",
        lazy="selectin",
    )

    def to_domain(self) -> UserProfile:
        """Convert ORM row into pure domain aggregate UserProfile."""
        intents = [PrimaryIntent(i) for i in self.primary_intents]
        conditions = [DiagnosedCondition(c) for c in self.diagnosed_conditions]
        method = HormonalMethod(self.hormonal_method) if self.hormonal_method else None

        context = OnboardingContext(
            birth_year=self.birth_year,
            primary_intents=intents,
            hormonal_method=method,
            diagnosed_conditions=conditions,
            clinical_context_completed=self.clinical_context_completed,
        )

        domain_transitions = [t.to_domain() for t in self.transitions]

        return UserProfile(
            id=self.id,
            firebase_uid=self.firebase_uid,
            first_name=self.first_name,
            last_name=self.last_name,
            current_life_stage=LifeStage(self.current_life_stage),
            onboarding_context=context,
            onboarding_completed=self.onboarding_completed,
            enabled_modules=list(self.enabled_modules),
            transition_history=domain_transitions,
            created_at=self.created_at,
            updated_at=self.updated_at,
        )

    @classmethod
    def from_domain(cls, profile: UserProfile) -> "UserProfileModel":
        """Build ORM entity from domain aggregate."""
        model = cls(
            id=profile.id,
            firebase_uid=profile.firebase_uid,
            first_name=profile.first_name,
            last_name=profile.last_name,
            current_life_stage=profile.current_life_stage.value,
            birth_year=profile.onboarding_context.birth_year,
            primary_intents=[
                intent.value for intent in profile.onboarding_context.primary_intents
            ],
            hormonal_method=(
                profile.onboarding_context.hormonal_method.value
                if profile.onboarding_context.hormonal_method
                else None
            ),
            diagnosed_conditions=[
                cond.value for cond in profile.onboarding_context.diagnosed_conditions
            ],
            clinical_context_completed=(
                profile.onboarding_context.clinical_context_completed
            ),
            onboarding_completed=profile.onboarding_completed,
            enabled_modules=list(profile.enabled_modules),
            created_at=profile.created_at,
            updated_at=profile.updated_at,
        )
        model.transitions = [
            LifeStageTransitionModel.from_domain(t, profile.id)
            for t in profile.transition_history
        ]
        return model


class LifeStageTransitionModel(Base):
    """SQLAlchemy ORM table mapping for LifeStageTransition entries."""

    __tablename__ = "life_stage_transitions"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    from_stage: Mapped[str] = mapped_column(String(50), nullable=False)
    to_stage: Mapped[str] = mapped_column(String(50), nullable=False)
    reason: Mapped[str] = mapped_column(String(50), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    occurred_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )

    user_profile: Mapped[UserProfileModel] = relationship(
        UserProfileModel, back_populates="transitions"
    )

    def to_domain(self) -> LifeStageTransition:
        return LifeStageTransition(
            id=self.id,
            from_stage=LifeStage(self.from_stage),
            to_stage=LifeStage(self.to_stage),
            reason=TransitionReason(self.reason),
            occurred_at=self.occurred_at,
            notes=self.notes,
        )

    @classmethod
    def from_domain(
        cls, transition: LifeStageTransition, user_profile_id: uuid.UUID
    ) -> "LifeStageTransitionModel":
        return cls(
            id=transition.id,
            user_profile_id=user_profile_id,
            from_stage=transition.from_stage.value,
            to_stage=transition.to_stage.value,
            reason=transition.reason.value,
            occurred_at=transition.occurred_at,
            notes=transition.notes,
        )
