from datetime import date
from uuid import uuid4

from app.modules.clinical_tracking.domain.models.menstrual_cycle import (
    CycleSymptomLog,
    MenstrualCycle,
)
from app.modules.clinical_tracking.domain.services import (
    AlertSeverity,
    FigoAlertType,
    FigoAtypicalPatternDetector,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    BleedingFlow,
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
    return MenstrualCycle.create(
        user_id=user_id,
        start_date=start_date,
        end_date=end_date,
        bleeding_duration_days=bleeding_duration,
        is_current=is_current,
        cycle_id=str(uuid4()),
    )


def test_normal_adult_cycles_generate_no_alerts() -> None:
    detector = FigoAtypicalPatternDetector()
    user_id = "user-normal-1"

    context = PatientCycleContext(
        life_stage=LifeStage.REGULAR_ADULT,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=1996,
    )

    cycles = [
        _make_cycle(user_id, date(2026, 7, 1), date(2026, 7, 28), 5),  # 28d
        _make_cycle(user_id, date(2026, 7, 29), date(2026, 8, 27), 5),  # 30d
        _make_cycle(user_id, date(2026, 8, 28), date(2026, 9, 25), 4),  # 29d
    ]

    alerts = detector.evaluate(cycles=cycles, symptoms=[], context=context)
    assert len(alerts) == 0


def test_polymenorrhea_detected_in_adult_when_under_24_days() -> None:
    detector = FigoAtypicalPatternDetector()
    user_id = "user-poly-1"

    context = PatientCycleContext(
        life_stage=LifeStage.REGULAR_ADULT,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=1995,
    )

    # 2 consecutive short cycles of 21 and 22 days
    cycles = [
        _make_cycle(user_id, date(2026, 7, 1), date(2026, 7, 21), 4),  # 21d
        _make_cycle(user_id, date(2026, 7, 22), date(2026, 8, 12), 4),  # 22d
    ]

    alerts = detector.evaluate(cycles=cycles, symptoms=[], context=context)
    poly_alerts = [a for a in alerts if a.alert_type == FigoAlertType.POLYMENORRHEA]
    assert len(poly_alerts) == 1
    assert poly_alerts[0].severity == AlertSeverity.ATTENTION
    assert (
        "frecuente" in poly_alerts[0].title_es.lower()
        or "polimenorrea" in poly_alerts[0].title_es.lower()
    )


def test_adolescent_cycle_tolerates_21_to_45_days_without_false_alarm() -> None:
    detector = FigoAtypicalPatternDetector()
    user_id = "teen-1"

    context = PatientCycleContext(
        life_stage=LifeStage.ADOLESCENCE,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=2012,
        menarche_year=2025,
    )

    # Cycles of 23 and 42 days (physiologically normal in early adolescence)
    cycles = [
        _make_cycle(user_id, date(2026, 6, 1), date(2026, 6, 23), 5),  # 23d
        _make_cycle(user_id, date(2026, 6, 24), date(2026, 8, 4), 5),  # 42d
    ]

    alerts = detector.evaluate(cycles=cycles, symptoms=[], context=context)
    # Neither polymenorrhea (<21) nor oligomenorrhea (>45) in teens
    assert len(alerts) == 0


def test_adolescent_flags_when_exceeding_teen_figo_thresholds() -> None:
    detector = FigoAtypicalPatternDetector()
    user_id = "teen-2"

    context = PatientCycleContext(
        life_stage=LifeStage.ADOLESCENCE,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=2012,
        menarche_year=2025,
    )

    # Cycles of 18 days (<21d) and 52 days (>45d)
    cycles = [
        _make_cycle(user_id, date(2026, 6, 1), date(2026, 6, 18), 4),  # 18d
        _make_cycle(user_id, date(2026, 6, 19), date(2026, 8, 9), 5),  # 52d
    ]

    alerts = detector.evaluate(cycles=cycles, symptoms=[], context=context)
    types = {a.alert_type for a in alerts}
    assert FigoAlertType.POLYMENORRHEA in types
    assert FigoAlertType.OLIGOMENORRHEA in types


def test_prolonged_bleeding_detected_when_exceeding_8_days() -> None:
    detector = FigoAtypicalPatternDetector()
    user_id = "user-prolonged-1"

    context = PatientCycleContext(
        life_stage=LifeStage.REGULAR_ADULT,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=1990,
    )

    cycle = _make_cycle(
        user_id, date(2026, 8, 1), date(2026, 8, 30), bleeding_duration=10
    )

    alerts = detector.evaluate(cycles=[cycle], symptoms=[], context=context)
    prolonged = [a for a in alerts if a.alert_type == FigoAlertType.PROLONGED_BLEEDING]
    assert len(prolonged) == 1
    assert (
        "8 días" in prolonged[0].description_es
        or "prolongado" in prolonged[0].title_es.lower()
    )


def test_intermenstrual_spotting_detected_from_symptoms() -> None:
    detector = FigoAtypicalPatternDetector()
    user_id = "user-spotting-1"

    context = PatientCycleContext(
        life_stage=LifeStage.REGULAR_ADULT,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=1994,
    )

    cycle = _make_cycle(
        user_id, date(2026, 8, 1), date(2026, 8, 29), bleeding_duration=5
    )

    # Spotting logged on day 16 and day 17 (intermenstrual window)
    symptoms = [
        CycleSymptomLog.create(
            user_id=user_id,
            log_date=date(2026, 8, 16),
            cycle_id=cycle.id,
            bleeding_flow=BleedingFlow.SPOTTING,
        ),
        CycleSymptomLog.create(
            user_id=user_id,
            log_date=date(2026, 8, 17),
            cycle_id=cycle.id,
            bleeding_flow=BleedingFlow.SPOTTING,
        ),
    ]

    alerts = detector.evaluate(cycles=[cycle], symptoms=symptoms, context=context)
    spotting_alerts = [
        a for a in alerts if a.alert_type == FigoAlertType.INTERMENSTRUAL_SPOTTING
    ]
    assert len(spotting_alerts) == 1
    assert spotting_alerts[0].severity == AlertSeverity.ATTENTION


def test_severe_pelvic_pain_in_two_cycles_alerts_endometriosis_risk() -> None:
    detector = FigoAtypicalPatternDetector()
    user_id = "user-endo-1"

    context = PatientCycleContext(
        life_stage=LifeStage.REGULAR_ADULT,
        hormonal_method=HormonalMethod.NONE,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=1992,
    )

    cycle1 = _make_cycle(user_id, date(2026, 7, 1), date(2026, 7, 28), 5)
    cycle2 = _make_cycle(user_id, date(2026, 7, 29), date(2026, 8, 27), 5)

    symptoms = [
        CycleSymptomLog.create(
            user_id=user_id,
            log_date=date(2026, 7, 2),
            cycle_id=cycle1.id,
            pelvic_pain=8,
            dysmenorrhea=8,
        ),
        CycleSymptomLog.create(
            user_id=user_id,
            log_date=date(2026, 7, 30),
            cycle_id=cycle2.id,
            pelvic_pain=9,
            dysmenorrhea=9,
        ),
    ]

    alerts = detector.evaluate(
        cycles=[cycle1, cycle2], symptoms=symptoms, context=context
    )
    pain_alerts = [
        a
        for a in alerts
        if a.alert_type == FigoAlertType.SEVERE_PELVIC_PAIN_ENDOMETRIOSIS_RISK
    ]
    assert len(pain_alerts) == 1
    assert pain_alerts[0].severity == AlertSeverity.CLINICAL_RECOMMENDATION
    assert (
        "endometriosis" in pain_alerts[0].description_es.lower()
        or "ginecológica" in pain_alerts[0].description_es.lower()
    )


def test_hormonal_contraception_suppresses_figo_natural_cycle_alerts() -> None:
    detector = FigoAtypicalPatternDetector()
    user_id = "user-pill-2"

    context = PatientCycleContext(
        life_stage=LifeStage.REGULAR_ADULT,
        hormonal_method=HormonalMethod.COMBINED_ORAL_PILL,
        diagnosed_conditions=[DiagnosedCondition.NONE],
        birth_year=1998,
    )

    # Irregularly spaced due to pill packs, natural FIGO rules do not apply
    cycles = [
        _make_cycle(user_id, date(2026, 7, 1), date(2026, 7, 20), 3),  # 20d
        _make_cycle(user_id, date(2026, 7, 21), date(2026, 8, 30), 4),  # 41d
    ]

    alerts = detector.evaluate(cycles=cycles, symptoms=[], context=context)
    # Natural cycle rhythm alerts (polymenorrhea, oligomenorrhea) should not be fired
    rhythm_alerts = [
        a
        for a in alerts
        if a.alert_type in (FigoAlertType.POLYMENORRHEA, FigoAlertType.OLIGOMENORRHEA)
    ]
    assert len(rhythm_alerts) == 0
