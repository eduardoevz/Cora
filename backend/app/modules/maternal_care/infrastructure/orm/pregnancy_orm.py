import uuid
from datetime import UTC, date, datetime
from decimal import Decimal
from typing import Any

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import JSON

from app.core.database import Base
from app.modules.maternal_care.domain.models.pregnancy_episode import (
    BirthPlanPreference,
    PregnancyEpisode,
    PrenatalAppointment,
)

# Portable JSON type: JSONB in Postgres, JSON in SQLite
JSONType = JSON().with_variant(JSONB(), "postgresql")


class PregnancyEpisodeModel(Base):
    __tablename__ = "pregnancy_episodes"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    clinical_edd: Mapped[date] = mapped_column(Date, nullable=False)
    last_menstrual_period: Mapped[date | None] = mapped_column(Date, nullable=True)
    ultrasound_edd: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )
    ended_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    recalibration_history: Mapped[list[dict[str, Any]]] = mapped_column(
        JSONType, default=list, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        onupdate=lambda: datetime.now(UTC),
        nullable=False,
    )

    def to_domain(self) -> PregnancyEpisode:
        return PregnancyEpisode(
            id=self.id,
            user_id=self.user_id,
            clinical_edd=self.clinical_edd,
            is_active=self.is_active,
            started_at=self.started_at,
            last_menstrual_period=self.last_menstrual_period,
            ultrasound_edd=self.ultrasound_edd,
            ended_at=self.ended_at,
            recalibration_history=self.recalibration_history or [],
        )

    @classmethod
    def from_domain(cls, domain: PregnancyEpisode) -> "PregnancyEpisodeModel":
        return cls(
            id=domain.id,
            user_id=domain.user_id,
            clinical_edd=domain.clinical_edd,
            last_menstrual_period=domain.last_menstrual_period,
            ultrasound_edd=domain.ultrasound_edd,
            is_active=domain.is_active,
            started_at=domain.started_at,
            ended_at=domain.ended_at,
            recalibration_history=domain.recalibration_history,
        )


class MaternalVitalsLogModel(Base):
    __tablename__ = "maternal_vitals_logs"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    pregnancy_episode_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("pregnancy_episodes.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    measured_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )
    gestational_weeks: Mapped[int] = mapped_column(Integer, nullable=False)
    systolic_mmhg: Mapped[int | None] = mapped_column(Integer, nullable=True)
    diastolic_mmhg: Mapped[int | None] = mapped_column(Integer, nullable=True)
    glucose_mg_dl: Mapped[Decimal | None] = mapped_column(Numeric(5, 1), nullable=True)
    glucose_timing: Mapped[str | None] = mapped_column(String(32), nullable=True)
    weight_kg: Mapped[Decimal | None] = mapped_column(Numeric(5, 2), nullable=True)
    symptoms: Mapped[list[dict[str, Any]]] = mapped_column(
        JSONType, default=list, nullable=False
    )
    alerts: Mapped[list[dict[str, Any]]] = mapped_column(
        JSONType, default=list, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )


class ContractionSessionModel(Base):
    __tablename__ = "contraction_sessions"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    pregnancy_episode_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("pregnancy_episodes.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    ended_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    gestational_weeks: Mapped[int] = mapped_column(Integer, nullable=False)
    pattern: Mapped[str] = mapped_column(String(32), nullable=False)
    total_contractions: Mapped[int] = mapped_column(Integer, nullable=False)
    avg_interval_seconds: Mapped[Decimal | None] = mapped_column(
        Numeric(6, 1), nullable=True
    )
    avg_duration_seconds: Mapped[Decimal | None] = mapped_column(
        Numeric(6, 1), nullable=True
    )
    events: Mapped[list[dict[str, Any]]] = mapped_column(
        JSONType, default=list, nullable=False
    )
    alert: Mapped[dict[str, Any] | None] = mapped_column(JSONType, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )


class KickSessionModel(Base):
    __tablename__ = "kick_sessions"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    pregnancy_episode_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("pregnancy_episodes.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    gestational_weeks: Mapped[int] = mapped_column(Integer, nullable=False)
    kicks_count: Mapped[int] = mapped_column(Integer, nullable=False)
    target_reached: Mapped[bool] = mapped_column(Boolean, nullable=False)
    target_reached_at_minutes: Mapped[int | None] = mapped_column(
        Integer, nullable=True
    )
    is_reassuring: Mapped[bool] = mapped_column(Boolean, nullable=False)
    alert: Mapped[dict[str, Any] | None] = mapped_column(JSONType, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )


class BirthPlanModel(Base):
    __tablename__ = "birth_plans"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    pregnancy_episode_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("pregnancy_episodes.id", ondelete="CASCADE"),
        unique=True,
        index=True,
        nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    companion_preferences: Mapped[list[str]] = mapped_column(
        JSONType, default=list, nullable=False
    )
    pain_management: Mapped[list[str]] = mapped_column(
        JSONType, default=list, nullable=False
    )
    delivery_environment: Mapped[list[str]] = mapped_column(
        JSONType, default=list, nullable=False
    )
    immediate_postpartum: Mapped[list[str]] = mapped_column(
        JSONType, default=list, nullable=False
    )
    special_requests: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        onupdate=lambda: datetime.now(UTC),
        nullable=False,
    )

    def to_domain(self) -> BirthPlanPreference:
        return BirthPlanPreference(
            companion_preferences=self.companion_preferences or [],
            pain_management=self.pain_management or [],
            delivery_environment=self.delivery_environment or [],
            immediate_postpartum=self.immediate_postpartum or [],
            special_requests=self.special_requests,
        )


class PrenatalAppointmentModel(Base):
    __tablename__ = "prenatal_appointments"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    pregnancy_episode_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("pregnancy_episodes.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    scheduled_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    doctor_or_clinic: Mapped[str] = mapped_column(String(255), nullable=False)
    gestational_week: Mapped[int] = mapped_column(Integer, nullable=False)
    topics_to_discuss: Mapped[list[str]] = mapped_column(
        JSONType, default=list, nullable=False
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        onupdate=lambda: datetime.now(UTC),
        nullable=False,
    )

    def to_domain(self) -> PrenatalAppointment:
        return PrenatalAppointment(
            id=self.id,
            pregnancy_episode_id=self.pregnancy_episode_id,
            scheduled_at=self.scheduled_at,
            doctor_or_clinic=self.doctor_or_clinic,
            gestational_week=self.gestational_week,
            topics_to_discuss=self.topics_to_discuss or [],
            notes=self.notes,
            is_completed=self.is_completed,
        )
