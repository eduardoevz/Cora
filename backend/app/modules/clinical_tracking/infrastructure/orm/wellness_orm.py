import uuid
from datetime import UTC, date, datetime

from sqlalchemy import (
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import JSON

from app.core.database import Base
from app.modules.clinical_tracking.domain.models.daily_wellness_log import (
    DailyWellnessLog,
)
from app.modules.clinical_tracking.domain.value_objects.wellness_metrics import (
    EnergyLevel,
    ExerciseMinutes,
    HydrationMl,
    MoodTag,
    SleepHours,
    SleepQuality,
)

JSONType = JSON().with_variant(JSONB, "postgresql")


class DailyWellnessLogModel(Base):
    """SQLAlchemy ORM table mapping for DailyWellnessLog."""

    __tablename__ = "daily_wellness_logs"
    __table_args__ = (
        UniqueConstraint(
            "user_id", "log_date", name="uq_daily_wellness_logs_user_date"
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    log_date: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    sleep_hours: Mapped[float | None] = mapped_column(Float, nullable=True)
    sleep_quality: Mapped[int | None] = mapped_column(Integer, nullable=True)
    energy_level: Mapped[int | None] = mapped_column(Integer, nullable=True)
    hydration_ml: Mapped[int | None] = mapped_column(Integer, nullable=True)
    exercise_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    mood_tags: Mapped[list[str]] = mapped_column(JSONType, default=list, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
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

    def to_domain(self) -> DailyWellnessLog:
        return DailyWellnessLog(
            id=str(self.id),
            user_id=str(self.user_id),
            log_date=self.log_date,
            sleep_hours=SleepHours(self.sleep_hours)
            if self.sleep_hours is not None
            else None,
            sleep_quality=SleepQuality(self.sleep_quality)
            if self.sleep_quality is not None
            else None,
            energy_level=EnergyLevel(self.energy_level)
            if self.energy_level is not None
            else None,
            hydration_ml=HydrationMl(self.hydration_ml)
            if self.hydration_ml is not None
            else None,
            exercise_minutes=ExerciseMinutes(self.exercise_minutes)
            if self.exercise_minutes is not None
            else None,
            mood_tags=[MoodTag(m) for m in self.mood_tags],
            notes=self.notes,
            created_at=self.created_at,
            updated_at=self.updated_at,
        )

    @classmethod
    def from_domain(cls, domain: DailyWellnessLog) -> "DailyWellnessLogModel":
        return cls(
            id=uuid.UUID(domain.id),
            user_id=uuid.UUID(domain.user_id),
            log_date=domain.log_date,
            sleep_hours=domain.sleep_hours.value
            if domain.sleep_hours is not None
            else None,
            sleep_quality=domain.sleep_quality.value
            if domain.sleep_quality is not None
            else None,
            energy_level=domain.energy_level.value
            if domain.energy_level is not None
            else None,
            hydration_ml=domain.hydration_ml.value
            if domain.hydration_ml is not None
            else None,
            exercise_minutes=domain.exercise_minutes.value
            if domain.exercise_minutes is not None
            else None,
            mood_tags=[m.value for m in domain.mood_tags],
            notes=domain.notes,
            created_at=domain.created_at,
            updated_at=domain.updated_at,
        )
