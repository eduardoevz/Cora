from datetime import UTC, datetime
from decimal import Decimal

import pytest

from app.modules.maternal_care.domain.exceptions.maternal_care_exceptions import (
    InvalidBloodPressureError,
    InvalidGlucoseValueError,
)
from app.modules.maternal_care.domain.services.maternal_risk_evaluator import (
    MaternalRiskEvaluator,
)
from app.modules.maternal_care.domain.value_objects.maternal_vitals import (
    BloodPressure,
    CapillaryGlucoseReading,
    GlucoseTiming,
    MaternalAlertSeverity,
    MaternalRiskCategory,
    MaternalSymptom,
    MaternalSymptomType,
)


class TestBloodPressureValidation:
    def test_valid_blood_pressure(self) -> None:
        bp = BloodPressure(systolic_mmhg=118, diastolic_mmhg=76)
        assert bp.systolic_mmhg == 118
        assert bp.diastolic_mmhg == 76
        assert bp.formatted == "118/76 mmHg"

    @pytest.mark.parametrize(
        "systolic,diastolic,expected_msg",
        [
            (
                80,
                120,
                "Sistólica (80) debe ser estrictamente mayor que la diastólica (120)",
            ),
            (
                90,
                90,
                "Sistólica (90) debe ser estrictamente mayor que la diastólica (90)",
            ),
            (50, 40, "Sistólica (50) fuera de rango fisiológico (60-260 mmHg)"),
            (270, 80, "Sistólica (270) fuera de rango fisiológico (60-260 mmHg)"),
            (120, 25, "Diastólica (25) fuera de rango fisiológico (30-160 mmHg)"),
            (120, 170, "Diastólica (170) fuera de rango fisiológico (30-160 mmHg)"),
        ],
    )
    def test_invalid_blood_pressure_raises_error(
        self, systolic: int, diastolic: int, expected_msg: str
    ) -> None:
        with pytest.raises(InvalidBloodPressureError) as exc_info:
            BloodPressure(systolic_mmhg=systolic, diastolic_mmhg=diastolic)
        assert expected_msg in str(exc_info.value)


class TestACOGHypertensionAndPreeclampsiaRisk:
    def test_normal_blood_pressure_no_alerts(self) -> None:
        bp = BloodPressure(systolic_mmhg=115, diastolic_mmhg=75)
        evaluator = MaternalRiskEvaluator()
        alerts = evaluator.evaluate_vitals(
            blood_pressure=bp,
            gestational_weeks=24,
            symptoms=[],
        )
        preeclampsia_alerts = [
            a for a in alerts if a.category == MaternalRiskCategory.PREECLAMPSIA_RISK
        ]
        assert len(preeclampsia_alerts) == 0

    @pytest.mark.parametrize(
        "systolic,diastolic",
        [
            (140, 90),
            (145, 92),
            (155, 98),
            (138, 92),
            (142, 85),
        ],
    )
    def test_gestational_hypertension_triggers_priority_consult(
        self, systolic: int, diastolic: int
    ) -> None:
        bp = BloodPressure(systolic_mmhg=systolic, diastolic_mmhg=diastolic)
        evaluator = MaternalRiskEvaluator()
        alerts = evaluator.evaluate_vitals(
            blood_pressure=bp,
            gestational_weeks=28,
            symptoms=[],
        )
        pe_alerts = [
            a for a in alerts if a.category == MaternalRiskCategory.PREECLAMPSIA_RISK
        ]
        assert len(pe_alerts) == 1
        assert pe_alerts[0].severity == MaternalAlertSeverity.PRIORITY_CONSULT
        assert (
            "Hipertensión gestacional" in pe_alerts[0].title
            or "Cifras tensionales elevadas" in pe_alerts[0].title
        )

    @pytest.mark.parametrize(
        "systolic,diastolic",
        [
            (160, 110),
            (165, 100),
            (145, 112),
            (175, 120),
        ],
    )
    def test_severe_range_hypertension_triggers_urgent_emergency(
        self, systolic: int, diastolic: int
    ) -> None:
        bp = BloodPressure(systolic_mmhg=systolic, diastolic_mmhg=diastolic)
        evaluator = MaternalRiskEvaluator()
        alerts = evaluator.evaluate_vitals(
            blood_pressure=bp,
            gestational_weeks=32,
            symptoms=[],
        )
        pe_alerts = [
            a for a in alerts if a.category == MaternalRiskCategory.PREECLAMPSIA_RISK
        ]
        assert len(pe_alerts) == 1
        assert pe_alerts[0].severity == MaternalAlertSeverity.URGENT_EMERGENCY
        assert (
            "severa" in pe_alerts[0].title.lower()
            or "crisis" in pe_alerts[0].title.lower()
        )

    @pytest.mark.parametrize(
        "symptom_type",
        [
            MaternalSymptomType.PERSISTENT_SEVERE_HEADACHE,
            MaternalSymptomType.SCOTOMAS_VISUAL_BLUR,
            MaternalSymptomType.EPIGASTRIC_RUQ_PAIN,
            MaternalSymptomType.SUDDEN_FACIAL_HAND_EDEMA,
        ],
    )
    def test_mild_hypertension_with_severe_symptom_escalates_to_urgent_emergency(
        self, symptom_type: MaternalSymptomType
    ) -> None:
        bp = BloodPressure(systolic_mmhg=142, diastolic_mmhg=92)
        symptoms = [
            MaternalSymptom(
                symptom_type=symptom_type, notes="Presente desde hace 2 horas"
            )
        ]
        evaluator = MaternalRiskEvaluator()
        alerts = evaluator.evaluate_vitals(
            blood_pressure=bp,
            gestational_weeks=30,
            symptoms=symptoms,
        )
        pe_alerts = [
            a for a in alerts if a.category == MaternalRiskCategory.PREECLAMPSIA_RISK
        ]
        assert len(pe_alerts) == 1
        assert pe_alerts[0].severity == MaternalAlertSeverity.URGENT_EMERGENCY
        assert "Preeclampsia con signos de alarma" in pe_alerts[0].title


class TestGestationalDiabetesEvaluation:
    def test_glucose_value_validation(self) -> None:
        with pytest.raises(InvalidGlucoseValueError):
            CapillaryGlucoseReading(
                measured_at=datetime.now(UTC),
                value_mg_dl=Decimal("20.0"),
                timing=GlucoseTiming.FASTING,
            )
        with pytest.raises(InvalidGlucoseValueError):
            CapillaryGlucoseReading(
                measured_at=datetime.now(UTC),
                value_mg_dl=Decimal("650.0"),
                timing=GlucoseTiming.FASTING,
            )

    @pytest.mark.parametrize(
        "timing,value,is_elevated",
        [
            (GlucoseTiming.FASTING, Decimal("88.0"), False),
            (GlucoseTiming.FASTING, Decimal("95.0"), True),
            (GlucoseTiming.FASTING, Decimal("105.0"), True),
            (GlucoseTiming.POSTPRANDIAL_1H, Decimal("135.0"), False),
            (GlucoseTiming.POSTPRANDIAL_1H, Decimal("140.0"), True),
            (GlucoseTiming.POSTPRANDIAL_1H, Decimal("155.0"), True),
            (GlucoseTiming.POSTPRANDIAL_2H, Decimal("115.0"), False),
            (GlucoseTiming.POSTPRANDIAL_2H, Decimal("120.0"), True),
            (GlucoseTiming.POSTPRANDIAL_2H, Decimal("132.0"), True),
        ],
    )
    def test_glucose_acog_thresholds(
        self, timing: GlucoseTiming, value: Decimal, is_elevated: bool
    ) -> None:
        evaluator = MaternalRiskEvaluator()
        glucose = CapillaryGlucoseReading(
            measured_at=datetime.now(UTC),
            value_mg_dl=value,
            timing=timing,
        )
        alerts = evaluator.evaluate_vitals(
            blood_pressure=None,
            glucose=glucose,
            gestational_weeks=26,
            symptoms=[],
        )
        gdm_alerts = [
            a
            for a in alerts
            if a.category == MaternalRiskCategory.GESTATIONAL_DIABETES_RISK
        ]
        if is_elevated:
            assert len(gdm_alerts) == 1
            assert gdm_alerts[0].severity == MaternalAlertSeverity.PRIORITY_CONSULT
        else:
            assert len(gdm_alerts) == 0
