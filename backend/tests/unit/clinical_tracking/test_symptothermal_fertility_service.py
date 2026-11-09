from datetime import date
from decimal import Decimal
from uuid import uuid4

import pytest

from app.modules.clinical_tracking.domain.exceptions.clinical_tracking_exceptions import (  # noqa: E501
    InvalidBasalTemperatureError,
)
from app.modules.clinical_tracking.domain.models.menstrual_cycle import (
    MenstrualCycle,
)
from app.modules.clinical_tracking.domain.models.preconception_checklist import (
    PreconceptionChecklist,
)
from app.modules.clinical_tracking.domain.services.symptothermal_fertility_service import (  # noqa: E501
    SymptothermalFertilityService,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    PatientCycleContext,
)
from app.modules.clinical_tracking.domain.value_objects.fertility_biomarkers import (
    BasalBodyTemperature,
    CervicalMucusType,
    DailyFertilityLog,
    FertilityStatus,
    LhStripResult,
)
from app.modules.identity.domain.value_objects.life_stage import LifeStage
from app.modules.identity.domain.value_objects.onboarding_context import (
    DiagnosedCondition,
    HormonalMethod,
)


def _make_cycle(start_date: date, cycle_length_days: int = 28) -> MenstrualCycle:
    return MenstrualCycle.create(
        cycle_id=str(uuid4()),
        user_id="test-fertility-user",
        start_date=start_date,
        cycle_length_days=cycle_length_days,
        is_current=True,
    )


def test_bbt_physiological_range_validation() -> None:
    # Valid temperatures
    bbt1 = BasalBodyTemperature(celsius=Decimal("36.45"))
    assert bbt1.celsius == Decimal("36.45")
    assert not bbt1.is_fever
    assert not bbt1.is_disturbed

    # Under minimum boundary (35.00)
    with pytest.raises(InvalidBasalTemperatureError):
        BasalBodyTemperature(celsius=Decimal("34.99"))

    # Over maximum boundary (42.00)
    with pytest.raises(InvalidBasalTemperatureError):
        BasalBodyTemperature(celsius=Decimal("42.01"))


def test_bbt_fever_and_disturbance_flagging() -> None:
    # Fever (>= 38.00 C) automatically flagged as disturbed
    fever_bbt = BasalBodyTemperature(celsius=Decimal("38.20"))
    assert fever_bbt.is_fever
    assert fever_bbt.is_disturbed

    # Manual disturbance (alcohol / lack of sleep)
    disturbed_bbt = BasalBodyTemperature(
        celsius=Decimal("36.70"),
        is_disturbed=True,
        disturbance_reason="Insomnio severo (<3h)",
    )
    assert not disturbed_bbt.is_fever
    assert disturbed_bbt.is_disturbed
    assert disturbed_bbt.disturbance_reason == "Insomnio severo (<3h)"


def test_bbt_fahrenheit_conversion() -> None:
    bbt = BasalBodyTemperature(celsius=Decimal("36.50"))
    # (36.50 * 9/5) + 32 = 65.7 + 32 = 97.70 F
    fahrenheit = bbt.to_fahrenheit()
    assert fahrenheit == Decimal("97.70")

    from_f = BasalBodyTemperature.from_fahrenheit(Decimal("97.70"))
    assert from_f.celsius == Decimal("36.50")


def test_symptothermal_three_over_six_rule_confirms_ovulation() -> None:
    service = SymptothermalFertilityService()
    cycle = _make_cycle(start_date=date(2026, 11, 1))
    context = PatientCycleContext(
        life_stage=LifeStage.CONCEPTION_SEARCH,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=1995,
    )

    # 6 low baseline temperatures (Days 7 to 12):
    # D7..D12 -> max = 36.35 (coverline)
    logs = [
        DailyFertilityLog(
            log_date=date(2026, 11, 7),
            bbt=BasalBodyTemperature(Decimal("36.25")),
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 8),
            bbt=BasalBodyTemperature(Decimal("36.30")),
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 9),
            bbt=BasalBodyTemperature(Decimal("36.20")),
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 10),
            bbt=BasalBodyTemperature(Decimal("36.35")),
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 11),
            bbt=BasalBodyTemperature(Decimal("36.25")),
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 12),
            bbt=BasalBodyTemperature(Decimal("36.30")),
            cervical_mucus=CervicalMucusType.EGG_WHITE,
            lh_result=LhStripResult.PEAK,
        ),
        # 3 elevated temperatures (Days 13 to 15):
        DailyFertilityLog(
            log_date=date(2026, 11, 13),
            bbt=BasalBodyTemperature(Decimal("36.45")),
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 14),
            bbt=BasalBodyTemperature(Decimal("36.50")),
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 15),
            bbt=BasalBodyTemperature(Decimal("36.60")),
        ),
    ]

    assessment = service.evaluate_cycle_fertility(
        current_cycle=cycle,
        daily_logs=logs,
        patient_context=context,
        reference_date=date(2026, 11, 15),
    )

    assert assessment.is_biphasic_shift_detected is True
    assert assessment.coverline_celsius == Decimal("36.35")
    assert assessment.ovulation_confirmed_date == date(2026, 11, 12)
    assert assessment.status == FertilityStatus.OVULATION_CONFIRMED


def test_fever_and_disturbances_are_excluded_from_coverline_and_shift() -> None:
    service = SymptothermalFertilityService()
    cycle = _make_cycle(start_date=date(2026, 11, 1))
    context = PatientCycleContext(
        life_stage=LifeStage.CONCEPTION_SEARCH,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=1995,
    )

    logs = [
        DailyFertilityLog(
            log_date=date(2026, 11, 6),
            bbt=BasalBodyTemperature(Decimal("36.20")),
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 7),
            bbt=BasalBodyTemperature(Decimal("36.25")),
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 8),
            bbt=BasalBodyTemperature(Decimal("36.30")),
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 9),
            bbt=BasalBodyTemperature(Decimal("38.50")),  # Fever! Excluded
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 10),
            bbt=BasalBodyTemperature(Decimal("36.35")),
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 11),
            bbt=BasalBodyTemperature(Decimal("36.25")),
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 12),
            bbt=BasalBodyTemperature(Decimal("36.30")),
        ),
        # Shift
        DailyFertilityLog(
            log_date=date(2026, 11, 13),
            bbt=BasalBodyTemperature(Decimal("36.45")),
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 14),
            bbt=BasalBodyTemperature(Decimal("36.50")),
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 15),
            bbt=BasalBodyTemperature(Decimal("36.60")),
        ),
    ]

    assessment = service.evaluate_cycle_fertility(
        current_cycle=cycle,
        daily_logs=logs,
        patient_context=context,
        reference_date=date(2026, 11, 15),
    )

    assert assessment.is_biphasic_shift_detected is True
    assert assessment.coverline_celsius == Decimal("36.35")
    assert assessment.status == FertilityStatus.OVULATION_CONFIRMED


def test_pcos_lh_surge_without_bbt_shift_remains_tentative() -> None:
    service = SymptothermalFertilityService()
    cycle = _make_cycle(start_date=date(2026, 11, 1))
    context = PatientCycleContext(
        life_stage=LifeStage.CONCEPTION_SEARCH,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.PCOS],
        birth_year=1994,
    )

    # User has LH peak on D14, but BBT remains low
    logs = [
        DailyFertilityLog(
            log_date=date(2026, 11, 12),
            bbt=BasalBodyTemperature(Decimal("36.25")),
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 13),
            bbt=BasalBodyTemperature(Decimal("36.30")),
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 14),
            bbt=BasalBodyTemperature(Decimal("36.25")),
            lh_result=LhStripResult.PEAK,
            cervical_mucus=CervicalMucusType.CREAMY,
        ),
        DailyFertilityLog(
            log_date=date(2026, 11, 15),
            bbt=BasalBodyTemperature(Decimal("36.28")),  # No rise!
        ),
    ]

    assessment = service.evaluate_cycle_fertility(
        current_cycle=cycle,
        daily_logs=logs,
        patient_context=context,
        reference_date=date(2026, 11, 15),
    )

    assert assessment.is_biphasic_shift_detected is False
    assert assessment.status == FertilityStatus.PEAK_FERTILITY
    assert (
        "SOP" in assessment.evaluation_notes_es
        or "LH" in assessment.evaluation_notes_es
    )


@pytest.mark.parametrize(
    ("birth_year", "seeking_months", "expect_advisory"),
    [
        (1996, 11, False),  # 30 years old, 11 months -> under 12 months threshold
        (1996, 12, True),  # 30 years old, 12 months -> advisory triggered
        (1996, 15, True),  # 30 years old, 15 months -> advisory triggered
        (1989, 5, False),  # 37 years old, 5 months -> under 6 months threshold
        (1989, 6, True),  # 37 years old, 6 months -> advisory triggered
        (1989, 9, True),  # 37 years old, 9 months -> advisory triggered
    ],
)
def test_age_and_duration_based_medical_guidance(
    birth_year: int, seeking_months: int, expect_advisory: bool
) -> None:
    service = SymptothermalFertilityService()
    cycle = _make_cycle(start_date=date(2026, 11, 1))
    context = PatientCycleContext(
        life_stage=LifeStage.CONCEPTION_SEARCH,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=birth_year,
    )

    assessment = service.evaluate_cycle_fertility(
        current_cycle=cycle,
        daily_logs=[],
        patient_context=context,
        reference_date=date(2026, 11, 15),
        active_seeking_months=seeking_months,
    )

    if expect_advisory:
        assert assessment.active_seeking_guidance_es is not None
        assert "especialista" in assessment.active_seeking_guidance_es.lower()
    else:
        assert assessment.active_seeking_guidance_es is None


def test_preconception_checklist_completion_calculation() -> None:
    checklist = PreconceptionChecklist(
        user_id="user-123",
        taking_folic_acid=True,
        folic_acid_dose_mcg=400,
        medical_checkup_done=True,
        rubella_immunity_checked=False,
        dental_checkup_done=False,
        toxic_habits_stopped=True,
        partner_evaluation_planned=False,
        active_seeking_months=3,
    )

    assert checklist.completion_percentage == 50
    assert checklist.is_folic_acid_adequate is True
