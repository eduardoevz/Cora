from datetime import date

import pytest

from app.core.errors import DomainError
from app.modules.clinical_tracking.domain.models.menstrual_cycle import (
    CycleSymptomLog,
    MenstrualCycle,
)
from app.modules.clinical_tracking.domain.services.cycle_calendar_projection_service import (  # noqa: E501
    CycleCalendarProjectionService,
)
from app.modules.clinical_tracking.domain.services.cycle_phase_and_prediction_service import (  # noqa: E501
    CyclePhaseAndPredictionService,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    BleedingFlow,
    CalendarDayMarker,
    CalendarDisplayMode,
    CyclePhase,
    FertilityProbability,
    InitialPeriodRange,
    PatientCycleContext,
)
from app.modules.identity.domain.value_objects.life_stage import LifeStage
from app.modules.identity.domain.value_objects.onboarding_context import (
    CycleRegularity,
    DiagnosedCondition,
    HormonalMethod,
    OnboardingContext,
    PrimaryIntent,
)


def test_onboarding_context_validates_menstrual_baseline_ranges() -> None:
    valid = OnboardingContext(
        birth_year=1996,
        primary_intents=[PrimaryIntent.CYCLE_AND_SYMPTOMS],
        cycle_regularity=CycleRegularity.REGULAR,
        typical_cycle_length_days=29,
        typical_bleeding_duration_days=5,
    )
    assert valid.cycle_regularity == CycleRegularity.REGULAR
    assert valid.typical_cycle_length_days == 29
    assert valid.typical_bleeding_duration_days == 5

    with pytest.raises(DomainError):
        OnboardingContext(
            birth_year=1996,
            primary_intents=[PrimaryIntent.CYCLE_AND_SYMPTOMS],
            typical_cycle_length_days=10,
        )

    with pytest.raises(DomainError):
        OnboardingContext(
            birth_year=1996,
            primary_intents=[PrimaryIntent.CYCLE_AND_SYMPTOMS],
            typical_bleeding_duration_days=20,
        )


def test_initial_period_range_validates_dates_and_duration() -> None:
    p = InitialPeriodRange(start_date=date(2026, 10, 1), end_date=date(2026, 10, 5))
    assert p.bleeding_duration_days == 5

    with pytest.raises(DomainError):
        InitialPeriodRange(start_date=date(2026, 10, 10), end_date=date(2026, 10, 5))

    with pytest.raises(DomainError):
        InitialPeriodRange(start_date=date(2026, 9, 1), end_date=date(2026, 9, 25))


def test_prediction_calibrates_from_two_initial_periods_31d_regular() -> None:
    cycles = [
        MenstrualCycle.create(
            user_id="u1",
            start_date=date(2026, 9, 20),
            end_date=date(2026, 10, 20),
            cycle_length_days=31,
            bleeding_duration_days=4,
            is_current=False,
        ),
        MenstrualCycle.create(
            user_id="u1",
            start_date=date(2026, 10, 21),
            bleeding_duration_days=4,
            is_current=True,
        ),
    ]
    ctx = PatientCycleContext(
        life_stage=LifeStage.REGULAR_ADULT,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=1996,
        cycle_regularity=CycleRegularity.REGULAR,
        typical_cycle_length_days=31,
        typical_bleeding_duration_days=4,
    )

    status = CyclePhaseAndPredictionService().compute_status(
        cycles=cycles,
        context=ctx,
        reference_date=date(2026, 11, 6),
    )

    assert status.day_in_cycle == 17
    assert status.predicted_next_period == date(2026, 11, 21)
    # 31 - 14 = day 17 -> start + 16 = 2026-11-06
    assert status.ovulation_date == date(2026, 11, 6)
    assert status.current_phase == CyclePhase.OVULATORY
    assert status.has_extended_uncertainty is False


def test_projection_marks_recorded_predicted_fertile_and_ovulation() -> None:
    cycles = [
        MenstrualCycle.create(
            user_id="u1",
            start_date=date(2026, 10, 1),
            end_date=date(2026, 10, 28),
            cycle_length_days=28,
            bleeding_duration_days=5,
            is_current=False,
        ),
        MenstrualCycle.create(
            user_id="u1",
            start_date=date(2026, 10, 29),
            bleeding_duration_days=5,
            is_current=True,
        ),
    ]
    logs = [
        CycleSymptomLog.create(
            user_id="u1",
            log_date=date(2026, 11, 10),
            bleeding_flow=BleedingFlow.SPOTTING,
            pelvic_pain=3,
        )
    ]
    ctx = PatientCycleContext(
        life_stage=LifeStage.REGULAR_ADULT,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=1995,
        cycle_regularity=CycleRegularity.REGULAR,
        typical_cycle_length_days=28,
        typical_bleeding_duration_days=5,
    )

    projection = CycleCalendarProjectionService().project_month(
        year=2026,
        month=11,
        cycles=cycles,
        symptom_logs=logs,
        context=ctx,
        today=date(2026, 11, 6),
    )

    assert projection.display_mode == CalendarDisplayMode.STANDARD_CYCLE
    assert projection.estimated_cycle_length_days == 28
    assert len(projection.days) == 30

    by_day = {d.date.day: d for d in projection.days}
    # Oct 29..Nov 2 is active bleeding (days 1-2 of Nov recorded)
    assert by_day[1].day_marker == CalendarDayMarker.RECORDED_PERIOD
    assert by_day[2].day_marker == CalendarDayMarker.RECORDED_PERIOD
    # Ovulation: Oct 29 + 13 = Nov 11 (day 14)
    assert by_day[11].day_marker == CalendarDayMarker.PREDICTED_OVULATION
    assert by_day[11].fertility_probability == FertilityProbability.HIGH
    # Fertile window around Nov 6..12 (excluding spotting day Nov 10 marker priority)
    assert by_day[8].day_marker == CalendarDayMarker.FERTILE_WINDOW
    assert by_day[10].day_marker == CalendarDayMarker.SPOTTING
    assert by_day[10].has_logged_symptoms is True
    assert by_day[10].pelvic_pain == 3
    # Next cycle predicted: Oct 29 + 28 = Nov 26..30
    assert by_day[26].day_marker == CalendarDayMarker.PREDICTED_PERIOD
    assert by_day[30].day_marker == CalendarDayMarker.PREDICTED_PERIOD


def test_irregular_and_hormonal_and_non_menstrual_stage_adaptations() -> None:
    cycles = [
        MenstrualCycle.create(
            user_id="u1",
            start_date=date(2026, 11, 1),
            bleeding_duration_days=4,
            is_current=True,
        )
    ]
    service = CycleCalendarProjectionService()

    # Irregular sets uncertainty
    irreg_proj = service.project_month(
        year=2026,
        month=11,
        cycles=cycles,
        symptom_logs=[],
        context=PatientCycleContext(
            life_stage=LifeStage.PERIMENOPAUSE,
            hormonal_method=HormonalMethod.NONE,
            diagnosed_conditions=[DiagnosedCondition.NONE],
            birth_year=1978,
            cycle_regularity=CycleRegularity.IRREGULAR,
            typical_cycle_length_days=36,
        ),
        today=date(2026, 11, 10),
    )
    assert irreg_proj.display_mode == CalendarDisplayMode.PERIMENOPAUSE_STRAW10
    assert irreg_proj.has_extended_uncertainty is True

    # Hormonal suppresses ovulation markers
    hormonal_proj = service.project_month(
        year=2026,
        month=11,
        cycles=cycles,
        symptom_logs=[],
        context=PatientCycleContext(
            life_stage=LifeStage.REGULAR_ADULT,
            hormonal_method=HormonalMethod.COMBINED_ORAL_PILL,
            diagnosed_conditions=[DiagnosedCondition.NONE],
            birth_year=1997,
            cycle_regularity=CycleRegularity.REGULAR,
            typical_cycle_length_days=28,
        ),
        today=date(2026, 11, 10),
    )
    assert hormonal_proj.display_mode == CalendarDisplayMode.HORMONALLY_MANAGED
    assert hormonal_proj.ovulation_date is None
    assert all(
        d.day_marker
        not in (
            CalendarDayMarker.FERTILE_WINDOW,
            CalendarDayMarker.PREDICTED_OVULATION,
        )
        for d in hormonal_proj.days
    )

    # Pregnancy & Senior suppress period/ovulation predictions
    for stage, expected_mode in (
        (LifeStage.PREGNANCY, CalendarDisplayMode.PREGNANCY_GESTATIONAL),
        (LifeStage.SENIOR_VITALITY, CalendarDisplayMode.SENIOR_PREVENTIVE),
    ):
        proj = service.project_month(
            year=2026,
            month=11,
            cycles=[],
            symptom_logs=[],
            context=PatientCycleContext(
                life_stage=stage,
                hormonal_method=HormonalMethod.NONE,
                diagnosed_conditions=[DiagnosedCondition.NONE],
                birth_year=1992 if stage == LifeStage.PREGNANCY else 1958,
                cycle_regularity=CycleRegularity.NOT_APPLICABLE,
            ),
            today=date(2026, 11, 10),
        )
        assert proj.display_mode == expected_mode
        assert proj.predicted_next_period is None
        assert proj.ovulation_date is None
        assert all(d.day_marker == CalendarDayMarker.NONE for d in proj.days)
