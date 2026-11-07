import uuid
from datetime import UTC, date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.modules.treatments.domain.models.treatment_regimen import (
    DoseIntakeLog,
    IntakeStatus,
    TreatmentRegimen,
)
from app.modules.treatments.domain.value_objects.dosage_schedule import (
    DosageSchedule,
    ScheduleType,
    TreatmentCategory,
)


class TreatmentRegimenModel(Base):
    """SQLAlchemy ORM table mapping for TreatmentRegimen aggregate."""

    __tablename__ = "treatment_regimens"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    category: Mapped[str] = mapped_column(String(50), nullable=False)
    dosage: Mapped[str] = mapped_column(String(100), nullable=False)
    schedule_type: Mapped[str] = mapped_column(String(50), nullable=False)
    scheduled_time: Mapped[str] = mapped_column(String(10), nullable=False)
    active_days: Mapped[int | None] = mapped_column(Integer, nullable=True)
    break_days: Mapped[int | None] = mapped_column(Integer, nullable=True)
    interval_days: Mapped[int | None] = mapped_column(Integer, nullable=True)
    replacement_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    instructions: Mapped[str | None] = mapped_column(Text, nullable=True)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
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

    intakes: Mapped[list["DoseIntakeLogModel"]] = relationship(
        "DoseIntakeLogModel",
        back_populates="regimen",
        cascade="all, delete-orphan",
        order_by="DoseIntakeLogModel.scheduled_for",
        lazy="selectin",
    )

    def to_domain(self) -> TreatmentRegimen:
        schedule = DosageSchedule(
            schedule_type=ScheduleType(self.schedule_type),
            scheduled_time=self.scheduled_time,
            active_days=self.active_days,
            break_days=self.break_days,
            interval_days=self.interval_days,
            replacement_date=self.replacement_date,
        )
        return TreatmentRegimen(
            id=str(self.id),
            user_id=str(self.user_id),
            name=self.name,
            category=TreatmentCategory(self.category),
            dosage=self.dosage,
            schedule=schedule,
            start_date=self.start_date,
            end_date=self.end_date,
            instructions=self.instructions,
            is_active=self.is_active,
            created_at=self.created_at,
            updated_at=self.updated_at,
        )

    @classmethod
    def from_domain(cls, domain: TreatmentRegimen) -> "TreatmentRegimenModel":
        return cls(
            id=uuid.UUID(domain.id),
            user_id=uuid.UUID(domain.user_id),
            name=domain.name,
            category=domain.category.value,
            dosage=domain.dosage,
            schedule_type=domain.schedule.schedule_type.value,
            scheduled_time=domain.schedule.scheduled_time,
            active_days=domain.schedule.active_days,
            break_days=domain.schedule.break_days,
            interval_days=domain.schedule.interval_days,
            replacement_date=domain.schedule.replacement_date,
            instructions=domain.instructions,
            start_date=domain.start_date,
            end_date=domain.end_date,
            is_active=domain.is_active,
            created_at=domain.created_at,
            updated_at=domain.updated_at,
        )


class DoseIntakeLogModel(Base):
    """SQLAlchemy ORM table mapping for DoseIntakeLog."""

    __tablename__ = "dose_intake_logs"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    regimen_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("treatment_regimens.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    scheduled_for: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), index=True, nullable=False
    )
    taken_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    status: Mapped[str] = mapped_column(String(20), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    client_mutation_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid(as_uuid=True), unique=True, nullable=True, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    regimen: Mapped["TreatmentRegimenModel"] = relationship(
        "TreatmentRegimenModel",
        back_populates="intakes",
    )

    def to_domain(self) -> DoseIntakeLog:
        return DoseIntakeLog(
            id=str(self.id),
            regimen_id=str(self.regimen_id),
            scheduled_for=self.scheduled_for,
            taken_at=self.taken_at,
            status=IntakeStatus(self.status),
            notes=self.notes,
            client_mutation_id=str(self.client_mutation_id)
            if self.client_mutation_id
            else None,
            created_at=self.created_at,
        )

    @classmethod
    def from_domain(cls, domain: DoseIntakeLog) -> "DoseIntakeLogModel":
        return cls(
            id=uuid.UUID(domain.id),
            regimen_id=uuid.UUID(domain.regimen_id),
            scheduled_for=domain.scheduled_for,
            taken_at=domain.taken_at,
            status=domain.status.value,
            notes=domain.notes,
            client_mutation_id=uuid.UUID(domain.client_mutation_id)
            if domain.client_mutation_id
            else None,
            created_at=domain.created_at,
        )
