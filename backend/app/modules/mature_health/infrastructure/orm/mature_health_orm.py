"""SQLAlchemy 2.0 ORM models for mature health module."""

import uuid
from datetime import UTC, date, datetime
from typing import Any

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import JSON

from app.core.database import Base

JSONType = JSON().with_variant(JSONB(), "postgresql")


class HotFlashEpisodeModel(Base):
    """ORM mapping for hot flash and night sweat episodes."""

    __tablename__ = "hot_flash_episodes"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    occurred_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        index=True,
    )
    severity: Mapped[int] = mapped_column(Integer, nullable=False)
    flash_type: Mapped[str] = mapped_column(String(32), nullable=False)
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    triggers: Mapped[list[Any]] = mapped_column(
        JSONType,
        nullable=False,
        default=list,
    )
    sleep_disruption_level: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0
    )
    associated_with_hrt: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )


class CardiometabolicPanelModel(Base):
    """ORM mapping for cardiometabolic panels."""

    __tablename__ = "cardiometabolic_panels"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    measurement_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    systolic_bp: Mapped[int | None] = mapped_column(Integer, nullable=True)
    diastolic_bp: Mapped[int | None] = mapped_column(Integer, nullable=True)
    total_cholesterol_mg_dl: Mapped[float | None] = mapped_column(Float, nullable=True)
    ldl_cholesterol_mg_dl: Mapped[float | None] = mapped_column(Float, nullable=True)
    hdl_cholesterol_mg_dl: Mapped[float | None] = mapped_column(Float, nullable=True)
    triglycerides_mg_dl: Mapped[float | None] = mapped_column(Float, nullable=True)
    fasting_glucose_mg_dl: Mapped[float | None] = mapped_column(Float, nullable=True)
    risk_level: Mapped[str] = mapped_column(
        String(32), nullable=False, default="OPTIMAL"
    )
    flagged_parameters: Mapped[list[Any]] = mapped_column(
        JSONType, nullable=False, default=list
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )


class VaginalBleedingObservationModel(Base):
    """ORM mapping for vaginal bleeding observations."""

    __tablename__ = "vaginal_bleeding_observations"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    observation_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    days_of_prior_amenorrhea: Mapped[int] = mapped_column(Integer, nullable=False)
    flow_intensity: Mapped[str] = mapped_column(
        String(32), nullable=False, default="LIGHT"
    )
    has_cramping: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    is_postmenopausal_alert_triggered: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )


class DexaBoneResultModel(Base):
    """ORM mapping for DXA bone density results."""

    __tablename__ = "dexa_bone_results"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    scan_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    anatomical_site: Mapped[str] = mapped_column(String(32), nullable=False)
    t_score: Mapped[float] = mapped_column(Float, nullable=False)
    z_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    bmd_g_cm2: Mapped[float | None] = mapped_column(Float, nullable=True)
    previous_fragility_fracture: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    category: Mapped[str] = mapped_column(String(32), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )


class FallRiskAssessmentModel(Base):
    """ORM mapping for fall risk assessments."""

    __tablename__ = "fall_risk_assessments"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    assessment_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    falls_past_year: Mapped[int] = mapped_column(Integer, nullable=False)
    has_gait_unsteadiness: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    uses_walking_aid: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    timed_up_and_go_seconds: Mapped[float | None] = mapped_column(Float, nullable=True)
    risk_level: Mapped[str] = mapped_column(String(32), nullable=False)
    composite_score: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    environmental_hazards: Mapped[list[Any]] = mapped_column(
        JSONType, nullable=False, default=list
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )


class ContinenceAndPelvicLogModel(Base):
    """ORM mapping for continence and pelvic floor logs."""

    __tablename__ = "continence_and_pelvic_logs"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    log_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    incontinence_type: Mapped[str] = mapped_column(String(32), nullable=False)
    daily_pad_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    has_pelvic_heaviness: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    vaginal_dryness_level: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0
    )
    has_dyspareunia: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )


class TrustedSupportContactModel(Base):
    """ORM mapping for trusted family/support contacts."""

    __tablename__ = "trusted_support_contacts"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    contact_name: Mapped[str] = mapped_column(String(128), nullable=False)
    relationship: Mapped[str] = mapped_column(String(64), nullable=False)
    phone_number: Mapped[str] = mapped_column(String(32), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_primary: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )
