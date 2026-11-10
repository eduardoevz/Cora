"""Unit tests for DXA bone density, fall risk, and urogynecology."""

from datetime import date

import pytest

from app.modules.mature_health.domain.exceptions import (
    InvalidBoneDensityReadingError,
    InvalidFallAssessmentError,
    InvalidSupportContactError,
)
from app.modules.mature_health.domain.models.bone_fall_and_urogynecology import (
    ContinenceAndPelvicLog,
    DexaBoneResult,
    FallRiskAssessment,
)
from app.modules.mature_health.domain.models.trusted_support_contact import (
    TrustedSupportContact,
)
from app.modules.mature_health.domain.services.senior_vitality_evaluator import (
    SeniorVitalityEvaluator,
)
from app.modules.mature_health.domain.value_objects import (
    AnatomicalSite,
    BoneDensityCategory,
    FallRiskLevel,
    IncontinenceType,
)


def test_dexa_classification_normal() -> None:
    """T-score >= -1.0 is classified as Normal bone mineral density."""
    evaluator = SeniorVitalityEvaluator()
    dexa = DexaBoneResult(
        scan_date=date(2026, 4, 15),
        anatomical_site=AnatomicalSite.LUMBAR_SPINE,
        t_score=-0.8,
        z_score=-0.2,
        bmd_g_cm2=1.05,
    )
    classification = evaluator.classify_bone_density(dexa)
    assert classification.category == BoneDensityCategory.NORMAL


def test_dexa_classification_osteopenia() -> None:
    """T-score between -1.0 and -2.5 is classified as Osteopenia."""
    evaluator = SeniorVitalityEvaluator()
    dexa = DexaBoneResult(
        scan_date=date(2026, 4, 15),
        anatomical_site=AnatomicalSite.FEMORAL_NECK,
        t_score=-1.8,
        z_score=-1.0,
        bmd_g_cm2=0.82,
    )
    classification = evaluator.classify_bone_density(dexa)
    assert classification.category == BoneDensityCategory.OSTEOPENIA


def test_dexa_classification_osteoporosis() -> None:
    """T-score <= -2.5 is classified as Osteoporosis."""
    evaluator = SeniorVitalityEvaluator()
    dexa = DexaBoneResult(
        scan_date=date(2026, 4, 15),
        anatomical_site=AnatomicalSite.TOTAL_HIP,
        t_score=-2.8,
        z_score=-2.1,
        bmd_g_cm2=0.65,
    )
    classification = evaluator.classify_bone_density(dexa)
    assert classification.category == BoneDensityCategory.OSTEOPOROSIS


def test_dexa_classification_severe_osteoporosis_with_fracture() -> None:
    """T-score <= -2.5 with prior fragility fracture is severe osteoporosis."""
    evaluator = SeniorVitalityEvaluator()
    dexa = DexaBoneResult(
        scan_date=date(2026, 4, 15),
        anatomical_site=AnatomicalSite.FEMORAL_NECK,
        t_score=-2.7,
        previous_fragility_fracture=True,
    )
    classification = evaluator.classify_bone_density(dexa)
    assert classification.category == BoneDensityCategory.SEVERE_OSTEOPOROSIS


def test_dexa_rejects_unphysiological_t_scores() -> None:
    """T-scores outside the range [-10.0, 10.0] raise error."""
    with pytest.raises(InvalidBoneDensityReadingError):
        DexaBoneResult(
            scan_date=date(2026, 4, 15),
            anatomical_site=AnatomicalSite.LUMBAR_SPINE,
            t_score=-15.0,
        )


def test_fall_risk_assessment_high_when_multiple_risk_factors() -> None:
    """Falls in past year + gait unsteadiness + slow TUG is High Risk."""
    evaluator = SeniorVitalityEvaluator()
    assessment = FallRiskAssessment(
        assessment_date=date(2026, 5, 2),
        falls_past_year=2,
        has_gait_unsteadiness=True,
        uses_walking_aid=True,
        timed_up_and_go_seconds=15.5,  # > 12s is elevated
    )
    result = evaluator.evaluate_fall_risk(assessment)
    assert result.risk_level == FallRiskLevel.HIGH


def test_fall_risk_assessment_low_when_no_risk_factors() -> None:
    """Zero falls and fast TUG classifies as Low Risk."""
    evaluator = SeniorVitalityEvaluator()
    assessment = FallRiskAssessment(
        assessment_date=date(2026, 5, 2),
        falls_past_year=0,
        has_gait_unsteadiness=False,
        uses_walking_aid=False,
        timed_up_and_go_seconds=8.5,
    )
    result = evaluator.evaluate_fall_risk(assessment)
    assert result.risk_level == FallRiskLevel.LOW


def test_fall_assessment_rejects_negative_metrics() -> None:
    """Negative fall count or negative TUG seconds raise error."""
    with pytest.raises(InvalidFallAssessmentError):
        FallRiskAssessment(
            assessment_date=date(2026, 5, 2),
            falls_past_year=-1,
        )


def test_composite_fracture_risk_alert_generated() -> None:
    """High fall risk with Osteoporosis triggers fracture risk alert."""
    evaluator = SeniorVitalityEvaluator()
    dexa = DexaBoneResult(
        scan_date=date(2026, 4, 15),
        anatomical_site=AnatomicalSite.FEMORAL_NECK,
        t_score=-2.9,
    )
    fall = FallRiskAssessment(
        assessment_date=date(2026, 5, 2),
        falls_past_year=1,
        has_gait_unsteadiness=True,
        timed_up_and_go_seconds=14.0,
    )

    alert = evaluator.generate_fracture_prevention_alert(
        dexa_result=dexa,
        fall_assessment=fall,
    )

    assert alert is not None
    assert alert.code == "HIGH_FRACTURE_RISK_ALERT"
    assert "fisioterapia" in alert.recommendations.lower()
    assert alert.priority == "HIGH"


def test_urogynecology_log_and_recommendations() -> None:
    """Pelvic floor log identifies mixed incontinence and dryness symptoms."""
    evaluator = SeniorVitalityEvaluator()
    log = ContinenceAndPelvicLog(
        log_date=date(2026, 5, 5),
        incontinence_type=IncontinenceType.MIXED,
        daily_pad_count=2,
        has_pelvic_heaviness=True,
        vaginal_dryness_level=2,
        has_dyspareunia=True,
    )

    guidance = evaluator.evaluate_pelvic_health(log)
    assert guidance.requires_urogynecology_consult is True
    assert len(guidance.supportive_tips) >= 2
    assert any("pélvico" in tip.lower() for tip in guidance.supportive_tips)


def test_trusted_support_contact_validation() -> None:
    """Trusted contact requires valid name and non-empty phone number."""
    contact = TrustedSupportContact(
        contact_name="Dra. Carmen Silva (Hija)",
        relationship="Hija / Cuidadora",
        phone_number="+525512345678",
        notes="Llamar preferentemente en las mañanas",
        is_primary=True,
    )
    assert contact.contact_name == "Dra. Carmen Silva (Hija)"
    assert contact.is_primary is True

    with pytest.raises(InvalidSupportContactError):
        TrustedSupportContact(
            contact_name="   ",
            relationship="Hija",
            phone_number="+525512345678",
        )

    with pytest.raises(InvalidSupportContactError):
        TrustedSupportContact(
            contact_name="Carmen",
            relationship="Hija",
            phone_number="",
        )
