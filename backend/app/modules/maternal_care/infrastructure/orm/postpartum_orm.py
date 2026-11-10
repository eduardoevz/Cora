import uuid
from datetime import UTC, datetime
from decimal import Decimal
from typing import Any

from sqlalchemy import (
    Boolean,
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

JSONType = JSON().with_variant(JSONB(), "postgresql")


class PostpartumRecoveryLogModel(Base):
    __tablename__ = "postpartum_recovery_logs"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    logged_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        index=True,
        nullable=False,
    )
    days_postpartum: Mapped[int] = mapped_column(Integer, nullable=False)
    lochia_stage: Mapped[str] = mapped_column(String(32), nullable=False)
    lochia_flow: Mapped[str] = mapped_column(String(64), nullable=False)
    foul_odor: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    maternal_temperature_c: Mapped[Decimal | None] = mapped_column(
        Numeric(4, 2), nullable=True
    )
    perineal_wound_status: Mapped[str | None] = mapped_column(String(64), nullable=True)
    cesarean_wound_status: Mapped[str | None] = mapped_column(String(64), nullable=True)
    pelvic_floor_symptoms: Mapped[list[str]] = mapped_column(
        JSONType, default=list, nullable=False
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    alerts: Mapped[list[dict[str, Any]]] = mapped_column(
        JSONType, default=list, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )


class LactationSessionModel(Base):
    __tablename__ = "lactation_sessions"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        index=True,
        nullable=False,
    )
    ended_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    left_duration_seconds: Mapped[int] = mapped_column(
        Integer, default=0, nullable=False
    )
    right_duration_seconds: Mapped[int] = mapped_column(
        Integer, default=0, nullable=False
    )
    last_offered_breast: Mapped[str] = mapped_column(String(16), nullable=False)
    bottle_volume_ml: Mapped[Decimal | None] = mapped_column(
        Numeric(6, 1), nullable=True
    )
    feeding_type: Mapped[str] = mapped_column(String(32), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )


class MilkStashEntryModel(Base):
    __tablename__ = "milk_stash_entries"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    pumped_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        index=True,
        nullable=False,
    )
    volume_ml: Mapped[Decimal] = mapped_column(Numeric(6, 1), nullable=False)
    storage_location: Mapped[str] = mapped_column(String(32), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        index=True,
        nullable=False,
    )
    is_consumed: Mapped[bool] = mapped_column(
        Boolean, default=False, index=True, nullable=False
    )
    consumed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )


class EpdsScreeningModel(Base):
    __tablename__ = "epds_screenings"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    screened_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        index=True,
        nullable=False,
    )
    days_postpartum: Mapped[int] = mapped_column(Integer, nullable=False)
    responses: Mapped[dict[str, Any]] = mapped_column(JSONType, nullable=False)
    total_score: Mapped[int] = mapped_column(Integer, nullable=False)
    item_10_score: Mapped[int] = mapped_column(Integer, nullable=False)
    self_harm_risk: Mapped[bool] = mapped_column(
        Boolean, default=False, index=True, nullable=False
    )
    severity: Mapped[str] = mapped_column(String(32), nullable=False)
    clinical_summary: Mapped[str] = mapped_column(Text, nullable=False)
    action_recommended: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )
