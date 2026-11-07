from datetime import UTC, date, datetime
from uuid import uuid4

import pytest

from app.modules.treatments.application.dtos.treatment_dtos import (
    CreateTreatmentRegimenDTO,
    LogDoseIntakeDTO,
)
from app.modules.treatments.application.ports.treatment_repository_port import (
    ITreatmentRepository,
)
from app.modules.treatments.application.use_cases.manage_treatments_use_cases import (
    CreateTreatmentRegimenUseCase,
    GetTreatmentAdherenceUseCase,
    LogDoseIntakeUseCase,
)
from app.modules.treatments.domain.exceptions.treatment_exceptions import (
    InvalidScheduleConfigurationError,
)
from app.modules.treatments.domain.models.treatment_regimen import (
    DoseIntakeLog,
    IntakeStatus,
    TreatmentRegimen,
)
from app.modules.treatments.domain.services.adherence_and_missed_dose_service import (
    AdherenceAndMissedDoseService,
    LarcAlertLevel,
)
from app.modules.treatments.domain.value_objects.dosage_schedule import (
    DosageSchedule,
    ScheduleType,
    TreatmentCategory,
)


class InMemoryTreatmentRepository(ITreatmentRepository):
    """In-memory repository for unit testing treatments module."""

    def __init__(self) -> None:
        self.regimens: dict[str, TreatmentRegimen] = {}
        self.intakes: dict[str, DoseIntakeLog] = {}

    async def save_regimen(self, regimen: TreatmentRegimen) -> TreatmentRegimen:
        self.regimens[regimen.id] = regimen
        return regimen

    async def get_regimens(
        self, user_id: str, is_active: bool | None = None
    ) -> list[TreatmentRegimen]:
        return [
            r
            for r in self.regimens.values()
            if r.user_id == user_id and (is_active is None or r.is_active == is_active)
        ]

    async def get_regimen_by_id(self, regimen_id: str) -> TreatmentRegimen | None:
        return self.regimens.get(regimen_id)

    async def log_intake(self, intake: DoseIntakeLog) -> DoseIntakeLog:
        self.intakes[intake.id] = intake
        return intake

    async def get_intakes(
        self, regimen_id: str, start_dt: datetime, end_dt: datetime
    ) -> list[DoseIntakeLog]:
        return [
            i
            for i in self.intakes.values()
            if i.regimen_id == regimen_id and start_dt <= i.scheduled_for <= end_dt
        ]


def test_dosage_schedule_cyclic_validation() -> None:
    # Valid 21/7 regimen
    schedule = DosageSchedule(
        schedule_type=ScheduleType.CYCLIC_ACTIVE_BREAK,
        scheduled_time="09:00",
        active_days=21,
        break_days=7,
    )
    assert schedule.active_days == 21
    assert schedule.break_days == 7

    # Invalid cyclic: missing active/break days
    with pytest.raises(InvalidScheduleConfigurationError):
        DosageSchedule(
            schedule_type=ScheduleType.CYCLIC_ACTIVE_BREAK,
            scheduled_time="09:00",
            active_days=None,
            break_days=7,
        )


def test_dosage_schedule_larc_validation() -> None:
    # Valid LARC
    replacement = date(2028, 5, 10)
    schedule = DosageSchedule(
        schedule_type=ScheduleType.LONG_ACTING_REPLACEMENT,
        scheduled_time="10:00",
        replacement_date=replacement,
    )
    assert schedule.replacement_date == replacement

    # Invalid LARC: missing replacement date
    with pytest.raises(InvalidScheduleConfigurationError):
        DosageSchedule(
            schedule_type=ScheduleType.LONG_ACTING_REPLACEMENT,
            scheduled_time="10:00",
            replacement_date=None,
        )


def test_missed_dose_progestin_only_triggers_backup_after_12h() -> None:
    service = AdherenceAndMissedDoseService()
    regimen = TreatmentRegimen.create(
        user_id="user-1",
        name="Cerazette",
        category=TreatmentCategory.CONTRACEPTIVE_PROGESTIN_ONLY,
        dosage="75 mcg",
        schedule=DosageSchedule(
            schedule_type=ScheduleType.DAILY_FIXED,
            scheduled_time="08:00",
        ),
        start_date=date(2026, 1, 1),
    )

    scheduled_for = datetime(2026, 11, 7, 8, 0, tzinfo=UTC)

    # 1. Taken 2 hours late -> DELAYED, but not critical
    taken_at_2h = datetime(2026, 11, 7, 10, 0, tzinfo=UTC)
    assessment_2h = service.evaluate_intake(
        regimen=regimen,
        scheduled_for=scheduled_for,
        taken_at=taken_at_2h,
        current_time=taken_at_2h,
    )
    assert assessment_2h.status == IntakeStatus.DELAYED
    assert assessment_2h.requires_backup_contraception is False

    # 2. Taken 13 hours late (> 12h) -> CRITICAL alert requiring backup method
    taken_at_13h = datetime(2026, 11, 7, 21, 0, tzinfo=UTC)
    assessment_13h = service.evaluate_intake(
        regimen=regimen,
        scheduled_for=scheduled_for,
        taken_at=taken_at_13h,
        current_time=taken_at_13h,
    )
    assert assessment_13h.status == IntakeStatus.DELAYED
    assert assessment_13h.requires_backup_contraception is True
    assert (
        assessment_13h.guidance_message is not None
        and "método de barrera de respaldo" in assessment_13h.guidance_message
    )


def test_missed_dose_combined_oral_contraceptive_triggers_backup_after_24h() -> None:
    service = AdherenceAndMissedDoseService()
    regimen = TreatmentRegimen.create(
        user_id="user-2",
        name="Yasmin",
        category=TreatmentCategory.CONTRACEPTIVE_ORAL_COMBINED,
        dosage="1 comprimido",
        schedule=DosageSchedule(
            schedule_type=ScheduleType.CYCLIC_ACTIVE_BREAK,
            scheduled_time="09:00",
            active_days=21,
            break_days=7,
        ),
        start_date=date(2026, 1, 1),
    )

    scheduled_for = datetime(2026, 11, 7, 9, 0, tzinfo=UTC)

    # Taken 14h late -> Not critical for combined pill (< 24h)
    taken_at_14h = datetime(2026, 11, 7, 23, 0, tzinfo=UTC)
    assessment_14h = service.evaluate_intake(
        regimen=regimen,
        scheduled_for=scheduled_for,
        taken_at=taken_at_14h,
        current_time=taken_at_14h,
    )
    assert assessment_14h.requires_backup_contraception is False

    # Taken 26h late (>= 24h) -> Critical for combined pill
    taken_at_26h = datetime(2026, 11, 8, 11, 0, tzinfo=UTC)
    assessment_26h = service.evaluate_intake(
        regimen=regimen,
        scheduled_for=scheduled_for,
        taken_at=taken_at_26h,
        current_time=taken_at_26h,
    )
    assert assessment_26h.requires_backup_contraception is True
    assert (
        assessment_26h.guidance_message is not None
        and "24 horas o más" in assessment_26h.guidance_message
    )


def test_cyclic_break_period_does_not_penalize_adherence() -> None:
    service = AdherenceAndMissedDoseService()
    start_date = date(2026, 11, 1)  # Day 1: Nov 1
    # For a 21/7 regimen: Days 1..21 are active (Nov 1 to Nov 21)
    # Days 22..28 are break/placebo (Nov 22 to Nov 28)
    regimen = TreatmentRegimen.create(
        user_id="user-3",
        name="Microgynon 21",
        category=TreatmentCategory.CONTRACEPTIVE_ORAL_COMBINED,
        dosage="1 comprimido",
        schedule=DosageSchedule(
            schedule_type=ScheduleType.CYCLIC_ACTIVE_BREAK,
            scheduled_time="20:00",
            active_days=21,
            break_days=7,
        ),
        start_date=start_date,
    )

    # Check Day 10 (Nov 10): Active day
    assert service.is_in_cyclic_break(regimen, date(2026, 11, 10)) is False

    # Check Day 22 (Nov 22): Placebo / Break day
    assert service.is_in_cyclic_break(regimen, date(2026, 11, 22)) is True

    # Check Day 28 (Nov 28): Placebo / Break day
    assert service.is_in_cyclic_break(regimen, date(2026, 11, 28)) is True

    # Check Day 29 (Nov 29): New active cycle starts!
    assert service.is_in_cyclic_break(regimen, date(2026, 11, 29)) is False


def test_larc_replacement_alerts_at_90_and_30_days() -> None:
    service = AdherenceAndMissedDoseService()
    replacement_date = date(2027, 2, 1)
    regimen = TreatmentRegimen.create(
        user_id="user-4",
        name="Mirena DIU",
        category=TreatmentCategory.LARC_IUD_IMPLANT,
        dosage="52 mg",
        schedule=DosageSchedule(
            schedule_type=ScheduleType.LONG_ACTING_REPLACEMENT,
            scheduled_time="10:00",
            replacement_date=replacement_date,
        ),
        start_date=date(2022, 2, 1),
    )

    # 1. 100 days remaining -> No alert
    alert_100 = service.check_larc_replacement(regimen, current_date=date(2026, 10, 24))
    assert alert_100.alert_level == LarcAlertLevel.NONE

    # 2. 80 days remaining (<= 90 days) -> WARNING alert
    alert_80 = service.check_larc_replacement(regimen, current_date=date(2026, 11, 13))
    assert alert_80.alert_level == LarcAlertLevel.WARNING
    assert "90 días o menos" in alert_80.message

    # 3. 20 days remaining (<= 30 days) -> CRITICAL alert
    alert_20 = service.check_larc_replacement(regimen, current_date=date(2027, 1, 12))
    assert alert_20.alert_level == LarcAlertLevel.CRITICAL
    assert "30 días o menos" in alert_20.message


@pytest.mark.asyncio
async def test_treatment_use_cases_and_adherence_calculation() -> None:
    repo = InMemoryTreatmentRepository()
    create_uc = CreateTreatmentRegimenUseCase(repo)
    log_uc = LogDoseIntakeUseCase(repo)
    adherence_uc = GetTreatmentAdherenceUseCase(repo)
    user_id = str(uuid4())

    # Create supplement regimen (Folic Acid)
    dto = CreateTreatmentRegimenDTO(
        name="Ácido Fólico",
        category="supplement",
        dosage="400 mcg",
        schedule_type="daily_fixed",
        scheduled_time="09:00",
        start_date="2026-11-01",
    )
    regimen = await create_uc.execute(user_id=user_id, dto=dto)
    assert regimen.name == "Ácido Fólico"
    assert regimen.category == TreatmentCategory.SUPPLEMENT

    # Log 3 doses taken, 1 missed
    dt_nov_1 = datetime(2026, 11, 1, 9, 0, tzinfo=UTC)
    dt_nov_2 = datetime(2026, 11, 2, 9, 0, tzinfo=UTC)
    dt_nov_3 = datetime(2026, 11, 3, 9, 0, tzinfo=UTC)
    dt_nov_4 = datetime(2026, 11, 4, 9, 0, tzinfo=UTC)

    await log_uc.execute(
        user_id=user_id,
        regimen_id=regimen.id,
        dto=LogDoseIntakeDTO(
            scheduled_for=dt_nov_1.isoformat(),
            taken_at=dt_nov_1.isoformat(),
            status="taken",
        ),
    )
    await log_uc.execute(
        user_id=user_id,
        regimen_id=regimen.id,
        dto=LogDoseIntakeDTO(
            scheduled_for=dt_nov_2.isoformat(),
            taken_at=dt_nov_2.isoformat(),
            status="taken",
        ),
    )
    await log_uc.execute(
        user_id=user_id,
        regimen_id=regimen.id,
        dto=LogDoseIntakeDTO(
            scheduled_for=dt_nov_3.isoformat(),
            taken_at=dt_nov_3.isoformat(),
            status="taken",
        ),
    )
    await log_uc.execute(
        user_id=user_id,
        regimen_id=regimen.id,
        dto=LogDoseIntakeDTO(
            scheduled_for=dt_nov_4.isoformat(),
            taken_at=None,
            status="missed",
        ),
    )

    summary = await adherence_uc.execute(
        user_id=user_id,
        regimen_id=regimen.id,
        start_date=date(2026, 11, 1),
        end_date=date(2026, 11, 4),
    )
    assert summary.scheduled_doses == 4
    assert summary.taken_doses == 3
    assert summary.missed_doses == 1
    assert summary.adherence_percentage == 75.0
