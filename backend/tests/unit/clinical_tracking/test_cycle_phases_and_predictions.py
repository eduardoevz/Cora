from datetime import date
from uuid import uuid4

from app.modules.clinical_tracking.domain.models.menstrual_cycle import (
    MenstrualCycle,
)
from app.modules.clinical_tracking.domain.services import (
    CyclePhaseAndPredictionService,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    CyclePhase,
    PatientCycleContext,
)
from app.modules.identity.domain.value_objects.life_stage import LifeStage
from app.modules.identity.domain.value_objects.onboarding_context import (
    DiagnosedCondition,
    HormonalMethod,
)


def _make_cycle(
    user_id: str,
    start_date: date,
    end_date: date | None = None,
    bleeding_duration: int | None = 5,
    is_current: bool = False,
) -> MenstrualCycle:
    cycle_length = (end_date - start_date).days + 1 if end_date else None
    return MenstrualCycle.create(
        cycle_id=str(uuid4()),
        user_id=user_id,
        start_date=start_date,
        end_date=end_date,
        cycle_length_days=cycle_length,
        bleeding_duration_days=bleeding_duration,
        is_current=is_current,
    )


def test_regular_adult_28_day_cycle_4_phases() -> None:
    service = CyclePhaseAndPredictionService()
    user_id = "user-regular-1"

    # Context: Regular adult, natural cycle, no conditions
    context = PatientCycleContext(
        life_stage=LifeStage.REGULAR_ADULT,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=1996,
    )

    # Completed historical cycle 1: Oct 1 - Oct 28 (28 days)
    cycle1 = _make_cycle(user_id, date(2026, 10, 1), date(2026, 10, 28), 5)
    # Current active cycle started Oct 29
    current_cycle = _make_cycle(
        user_id, date(2026, 10, 29), is_current=True, bleeding_duration=5
    )

    cycles = [cycle1, current_cycle]

    # Test Menstrual phase (Day 3: Oct 31)
    status_day3 = service.compute_status(
        cycles=cycles, context=context, reference_date=date(2026, 10, 31)
    )
    assert status_day3.current_phase == CyclePhase.MENSTRUAL
    assert status_day3.day_in_cycle == 3
    assert status_day3.is_hormonally_managed is False
    assert status_day3.predicted_next_period == date(2026, 11, 26)

    # Test Follicular phase (Day 8: Nov 5)
    status_day8 = service.compute_status(
        cycles=cycles, context=context, reference_date=date(2026, 11, 5)
    )
    assert status_day8.current_phase == CyclePhase.FOLLICULAR
    assert status_day8.day_in_cycle == 8

    # Test Ovulatory phase & fertile window (Day 14: Nov 11)
    status_day14 = service.compute_status(
        cycles=cycles, context=context, reference_date=date(2026, 11, 11)
    )
    assert status_day14.current_phase == CyclePhase.OVULATORY
    assert status_day14.day_in_cycle == 14
    assert status_day14.ovulation_date == date(2026, 11, 11)
    assert status_day14.fertile_window_start == date(2026, 11, 6)
    assert status_day14.fertile_window_end == date(2026, 11, 12)

    # Test Luteal phase (Day 20: Nov 17)
    status_day20 = service.compute_status(
        cycles=cycles, context=context, reference_date=date(2026, 11, 17)
    )
    assert status_day20.current_phase == CyclePhase.LUTEAL
    assert status_day20.day_in_cycle == 20


def test_adolescence_cycle_variability_tolerance_and_educational_messaging() -> None:
    service = CyclePhaseAndPredictionService()
    user_id = "user-teen-1"

    # Context: 14yo adolescent, 1 year post-menarche (2025)
    context = PatientCycleContext(
        life_stage=LifeStage.ADOLESCENCE,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=2012,
        menarche_year=2025,
    )

    # Historical cycles of 38 and 42 days (physiologically normal in teen)
    cycle1 = _make_cycle(user_id, date(2026, 8, 1), date(2026, 9, 7), 5)  # 38 days
    cycle2 = _make_cycle(user_id, date(2026, 9, 8), date(2026, 10, 19), 6)  # 42 days
    current = _make_cycle(
        user_id, date(2026, 10, 20), is_current=True, bleeding_duration=5
    )

    cycles = [cycle1, cycle2, current]

    # Evaluate Day 15 (Nov 3): Still in follicular phase with wider uncertainty
    status = service.compute_status(
        cycles=cycles, context=context, reference_date=date(2026, 11, 3)
    )
    assert status.day_in_cycle == 15
    assert status.is_hormonally_managed is False
    assert status.has_extended_uncertainty is True
    # The message should reassure that cycle length is developmentally normal
    assert (
        "primeros años" in status.phase_description_es.lower()
        or "desarrollo" in status.phase_description_es.lower()
    )


def test_hormonally_managed_cycle_suppresses_natural_ovulation() -> None:
    service = CyclePhaseAndPredictionService()
    user_id = "user-pill-1"

    # Context: Combined pill active
    context = PatientCycleContext(
        life_stage=LifeStage.REGULAR_ADULT,
        hormonal_method=HormonalMethod.COMBINED_ORAL_PILL,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=1998,
    )

    current = _make_cycle(
        user_id, date(2026, 11, 1), is_current=True, bleeding_duration=4
    )

    status = service.compute_status(
        cycles=[current], context=context, reference_date=date(2026, 11, 14)
    )

    assert status.current_phase == CyclePhase.HORMONALLY_MANAGED
    assert status.is_hormonally_managed is True
    assert status.ovulation_date is None
    assert status.fertile_window_start is None
    assert status.fertile_window_end is None
    assert (
        "deprivación" in status.phase_description_es.lower()
        or "hormonal" in status.phase_description_es.lower()
    )


def test_pcos_cycle_adapts_follicular_uncertainty() -> None:
    service = CyclePhaseAndPredictionService()
    user_id = "user-pcos-1"

    context = PatientCycleContext(
        life_stage=LifeStage.REGULAR_ADULT,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.PCOS],
        birth_year=1995,
    )

    # 44 day cycles typical in PCOS
    cycle1 = _make_cycle(user_id, date(2026, 8, 1), date(2026, 9, 13), 6)  # 44 days
    current = _make_cycle(
        user_id, date(2026, 9, 14), is_current=True, bleeding_duration=6
    )

    status = service.compute_status(
        cycles=[cycle1, current], context=context, reference_date=date(2026, 10, 10)
    )

    assert status.is_hormonally_managed is False
    assert status.has_extended_uncertainty is True
    assert (
        "sop" in status.daily_tip_es.lower()
        or "ovulación variable" in status.daily_tip_es.lower()
    )


def test_first_cycle_without_history_uses_safe_defaults() -> None:
    service = CyclePhaseAndPredictionService()
    user_id = "user-new-1"

    context = PatientCycleContext(
        life_stage=LifeStage.REGULAR_ADULT,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=2000,
    )

    # Zero historical cycles, only current one started 4 days ago
    current = _make_cycle(
        user_id, date(2026, 11, 1), is_current=True, bleeding_duration=None
    )

    status = service.compute_status(
        cycles=[current], context=context, reference_date=date(2026, 11, 5)
    )

    assert status.day_in_cycle == 5
    assert status.current_phase == CyclePhase.MENSTRUAL
    # Population default 28 days
    assert status.predicted_next_period == date(2026, 11, 29)
    assert status.ovulation_date == date(2026, 11, 14)
