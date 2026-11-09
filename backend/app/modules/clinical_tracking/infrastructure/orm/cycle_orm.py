import uuid
from datetime import UTC, date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    SmallInteger,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import JSON

from app.core.database import Base
from app.modules.clinical_tracking.domain.models.menstrual_cycle import (
    CycleSymptomLog,
    MenstrualCycle,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    BleedingFlow,
)

JSONType = JSON().with_variant(JSONB, "postgresql")


class MenstrualCycleModel(Base):
    """SQLAlchemy ORM table mapping for MenstrualCycle."""

    __tablename__ = "menstrual_cycles"
    __table_args__ = (
        UniqueConstraint(
            "user_id", "start_date", name="uq_menstrual_cycles_user_start_date"
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    start_date: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    cycle_length_days: Mapped[int | None] = mapped_column(Integer, nullable=True)
    bleeding_duration_days: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_current: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
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

    def to_domain(self) -> MenstrualCycle:
        return MenstrualCycle(
            id=str(self.id),
            user_id=str(self.user_id),
            start_date=self.start_date,
            end_date=self.end_date,
            cycle_length_days=self.cycle_length_days,
            bleeding_duration_days=self.bleeding_duration_days,
            is_current=self.is_current,
            created_at=self.created_at,
            updated_at=self.updated_at,
        )

    @classmethod
    def from_domain(cls, entity: MenstrualCycle) -> "MenstrualCycleModel":
        return cls(
            id=uuid.UUID(entity.id),
            user_id=uuid.UUID(entity.user_id),
            start_date=entity.start_date,
            end_date=entity.end_date,
            cycle_length_days=entity.cycle_length_days,
            bleeding_duration_days=entity.bleeding_duration_days,
            is_current=entity.is_current,
            created_at=entity.created_at,
            updated_at=entity.updated_at,
        )


class CycleSymptomLogModel(Base):
    """SQLAlchemy ORM table mapping for CycleSymptomLog."""

    __tablename__ = "cycle_symptom_logs"
    __table_args__ = (
        UniqueConstraint("user_id", "log_date", name="uq_cycle_symptom_logs_user_date"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    cycle_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("menstrual_cycles.id", ondelete="SET NULL"),
        index=True,
        nullable=True,
    )
    log_date: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    bleeding_flow: Mapped[str] = mapped_column(
        String(length=32), default=BleedingFlow.NONE.value, nullable=False
    )
    pelvic_pain: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    dysmenorrhea: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    dyspareunia: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    acne_severity: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    hirsutism: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    fatigue_level: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    gi_symptoms: Mapped[list[str]] = mapped_column(
        JSONType, default=list, nullable=False
    )
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

    def to_domain(self) -> CycleSymptomLog:
        return CycleSymptomLog(
            id=str(self.id),
            user_id=str(self.user_id),
            log_date=self.log_date,
            cycle_id=str(self.cycle_id) if self.cycle_id is not None else None,
            bleeding_flow=BleedingFlow(self.bleeding_flow),
            pelvic_pain=self.pelvic_pain,
            dysmenorrhea=self.dysmenorrhea,
            dyspareunia=self.dyspareunia,
            acne_severity=self.acne_severity,
            hirsutism=self.hirsutism,
            fatigue_level=self.fatigue_level,
            gi_symptoms=self.gi_symptoms or [],
            notes=self.notes,
            created_at=self.created_at,
            updated_at=self.updated_at,
        )

    @classmethod
    def from_domain(cls, entity: CycleSymptomLog) -> "CycleSymptomLogModel":
        return cls(
            id=uuid.UUID(entity.id),
            user_id=uuid.UUID(entity.user_id),
            cycle_id=uuid.UUID(entity.cycle_id) if entity.cycle_id else None,
            log_date=entity.log_date,
            bleeding_flow=entity.bleeding_flow.value,
            pelvic_pain=entity.pelvic_pain,
            dysmenorrhea=entity.dysmenorrhea,
            dyspareunia=entity.dyspareunia,
            acne_severity=entity.acne_severity,
            hirsutism=entity.hirsutism,
            fatigue_level=entity.fatigue_level,
            gi_symptoms=entity.gi_symptoms,
            notes=entity.notes,
            created_at=entity.created_at,
            updated_at=entity.updated_at,
        )
