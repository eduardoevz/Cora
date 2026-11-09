import uuid
from datetime import UTC, date, datetime, time
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    Time,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.modules.clinical_tracking.domain.models.preconception_checklist import (
    PreconceptionChecklist,
)
from app.modules.clinical_tracking.domain.value_objects.fertility_biomarkers import (
    BasalBodyTemperature,
    CervicalMucusType,
    DailyFertilityLog,
    IntercourseType,
    LhStripResult,
)


class DailyFertilityLogModel(Base):
    """SQLAlchemy ORM table mapping for DailyFertilityLog."""

    __tablename__ = "daily_fertility_logs"
    __table_args__ = (
        UniqueConstraint(
            "user_id", "log_date", name="uq_daily_fertility_logs_user_date"
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    log_date: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    bbt_celsius: Mapped[Decimal | None] = mapped_column(Numeric(4, 2), nullable=True)
    is_disturbed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    disturbance_reason: Mapped[str | None] = mapped_column(String(128), nullable=True)
    measured_at_time: Mapped[time | None] = mapped_column(Time, nullable=True)
    cervical_mucus: Mapped[str | None] = mapped_column(String(32), nullable=True)
    lh_result: Mapped[str | None] = mapped_column(String(32), nullable=True)
    intercourse_had: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    intercourse_type: Mapped[str] = mapped_column(
        String(32), default="none", nullable=False
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

    def to_domain(self) -> DailyFertilityLog:
        bbt_vo: BasalBodyTemperature | None = None
        if self.bbt_celsius is not None:
            bbt_vo = BasalBodyTemperature(
                celsius=Decimal(str(self.bbt_celsius)),
                is_disturbed=self.is_disturbed,
                disturbance_reason=self.disturbance_reason,
                measured_at_time=self.measured_at_time,
            )

        mucus = CervicalMucusType(self.cervical_mucus) if self.cervical_mucus else None
        lh = LhStripResult(self.lh_result) if self.lh_result else None
        intercourse = (
            IntercourseType(self.intercourse_type)
            if self.intercourse_type
            else IntercourseType.NONE
        )

        return DailyFertilityLog(
            log_date=self.log_date,
            bbt=bbt_vo,
            cervical_mucus=mucus,
            lh_result=lh,
            intercourse_had=self.intercourse_had,
            intercourse_type=intercourse,
            notes=self.notes,
        )


class PreconceptionChecklistModel(Base):
    """SQLAlchemy ORM table mapping for PreconceptionChecklist."""

    __tablename__ = "preconception_checklists"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        unique=True,
        index=True,
        nullable=False,
    )
    taking_folic_acid: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    folic_acid_dose_mcg: Mapped[int | None] = mapped_column(
        Integer, default=400, nullable=True
    )
    medical_checkup_done: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    rubella_immunity_checked: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    dental_checkup_done: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    toxic_habits_stopped: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    partner_evaluation_planned: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    active_seeking_months: Mapped[int] = mapped_column(
        Integer, default=0, nullable=False
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

    def to_domain(self) -> PreconceptionChecklist:
        return PreconceptionChecklist(
            user_id=str(self.user_id),
            taking_folic_acid=self.taking_folic_acid,
            folic_acid_dose_mcg=self.folic_acid_dose_mcg,
            medical_checkup_done=self.medical_checkup_done,
            rubella_immunity_checked=self.rubella_immunity_checked,
            dental_checkup_done=self.dental_checkup_done,
            toxic_habits_stopped=self.toxic_habits_stopped,
            partner_evaluation_planned=self.partner_evaluation_planned,
            active_seeking_months=self.active_seeking_months,
            updated_at=self.updated_at,
        )
