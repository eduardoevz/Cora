from dataclasses import dataclass
from datetime import date, datetime
from enum import StrEnum

from app.modules.treatments.domain.models.treatment_regimen import (
    DoseIntakeLog,
    IntakeStatus,
    TreatmentRegimen,
)
from app.modules.treatments.domain.value_objects.dosage_schedule import (
    ScheduleType,
    TreatmentCategory,
)


class LarcAlertLevel(StrEnum):
    """Urgency level for long-acting contraceptive replacement alerts."""

    NONE = "none"
    WARNING = "warning"
    CRITICAL = "critical"


@dataclass(frozen=True)
class LarcAlert:
    """Clinical alert for long-acting reversible contraceptive expiration."""

    alert_level: LarcAlertLevel
    days_remaining: int
    message: str


@dataclass(frozen=True)
class IntakeAssessment:
    """Evaluation result of medication dose timing and backup requirements."""

    status: IntakeStatus
    delay_hours: float
    is_critical_missed_dose: bool
    requires_backup_contraception: bool
    guidance_message: str | None = None


@dataclass(frozen=True)
class AdherenceSummary:
    """Aggregated clinical compliance report for a treatment regimen."""

    regimen_id: str
    scheduled_doses: int
    taken_doses: int
    missed_doses: int
    delayed_doses: int
    adherence_percentage: float


class AdherenceAndMissedDoseService:
    """Deterministic domain service assessing intake punctuality and compliance."""

    def evaluate_intake(
        self,
        regimen: TreatmentRegimen,
        scheduled_for: datetime,
        taken_at: datetime | None,
        current_time: datetime,
    ) -> IntakeAssessment:
        if taken_at is not None:
            delay_seconds = (taken_at - scheduled_for).total_seconds()
        else:
            delay_seconds = (current_time - scheduled_for).total_seconds()

        delay_hours = max(0.0, delay_seconds / 3600.0)

        if taken_at is not None:
            status = IntakeStatus.DELAYED if delay_hours >= 2.0 else IntakeStatus.TAKEN
        else:
            status = IntakeStatus.MISSED

        is_critical = False
        requires_backup = False
        guidance = None

        if regimen.category == TreatmentCategory.CONTRACEPTIVE_PROGESTIN_ONLY:
            if delay_hours > 12.0:
                is_critical = True
                requires_backup = True
                guidance = (
                    "Retraso superior a 12 horas en anticonceptivo de progestina sola. "
                    "Se recomienda utilizar método de barrera de respaldo durante las "
                    "próximas 48 horas y consultar el prospecto."
                )

        elif regimen.category == TreatmentCategory.CONTRACEPTIVE_ORAL_COMBINED:
            if delay_hours >= 24.0:
                is_critical = True
                requires_backup = True
                guidance = (
                    "Omisión de 24 horas o más en anticonceptivo oral combinado. "
                    "Toma la dosis olvidada lo antes posible, continúa con "
                    "el horario habitual y utiliza preservativo por 7 días "
                    "si se omitieron 2 o más tomas."
                )

        return IntakeAssessment(
            status=status,
            delay_hours=round(delay_hours, 2),
            is_critical_missed_dose=is_critical,
            requires_backup_contraception=requires_backup,
            guidance_message=guidance,
        )

    def is_in_cyclic_break(self, regimen: TreatmentRegimen, target_date: date) -> bool:
        if regimen.schedule.schedule_type != ScheduleType.CYCLIC_ACTIVE_BREAK:
            return False

        active_days = regimen.schedule.active_days or 21
        break_days = regimen.schedule.break_days or 7
        cycle_len = active_days + break_days

        days_since_start = (target_date - regimen.start_date).days
        if days_since_start < 0:
            return False

        day_in_cycle = days_since_start % cycle_len
        return day_in_cycle >= active_days

    def check_larc_replacement(
        self, regimen: TreatmentRegimen, current_date: date
    ) -> LarcAlert:
        if (
            regimen.schedule.schedule_type != ScheduleType.LONG_ACTING_REPLACEMENT
            or regimen.schedule.replacement_date is None
        ):
            return LarcAlert(
                alert_level=LarcAlertLevel.NONE,
                days_remaining=0,
                message="No aplica a tratamientos no LARC.",
            )

        days_remaining = (regimen.schedule.replacement_date - current_date).days

        if days_remaining <= 30:
            return LarcAlert(
                alert_level=LarcAlertLevel.CRITICAL,
                days_remaining=days_remaining,
                message=(
                    f"Recambio de DIU/implante en 30 días o menos "
                    f"({days_remaining} días). Agenda tu cita médica prioritaria."
                ),
            )
        elif days_remaining <= 90:
            return LarcAlert(
                alert_level=LarcAlertLevel.WARNING,
                days_remaining=days_remaining,
                message=(
                    f"Recambio de DIU/implante en 90 días o menos "
                    f"({days_remaining} días). Planifica tu consulta ginecológica."
                ),
            )

        return LarcAlert(
            alert_level=LarcAlertLevel.NONE,
            days_remaining=days_remaining,
            message=(
                f"DIU/implante vigente. Faltan {days_remaining} días para su recambio."
            ),
        )

    def calculate_adherence_summary(
        self,
        regimen: TreatmentRegimen,
        intakes: list[DoseIntakeLog],
    ) -> AdherenceSummary:
        scheduled_count = len(intakes)
        taken_count = sum(
            1 for i in intakes if i.status in (IntakeStatus.TAKEN, IntakeStatus.DELAYED)
        )
        missed_count = sum(1 for i in intakes if i.status == IntakeStatus.MISSED)
        delayed_count = sum(1 for i in intakes if i.status == IntakeStatus.DELAYED)

        if scheduled_count > 0:
            pct = round((taken_count / scheduled_count) * 100.0, 2)
        else:
            pct = 100.0

        return AdherenceSummary(
            regimen_id=regimen.id,
            scheduled_doses=scheduled_count,
            taken_doses=taken_count,
            missed_doses=missed_count,
            delayed_doses=delayed_count,
            adherence_percentage=pct,
        )
