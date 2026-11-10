"""Unit tests for STRAW+10 staging engine and postmenopausal bleeding alert."""

from datetime import UTC, date, datetime

import pytest

from app.modules.mature_health.domain.exceptions import (
    InvalidCardiometabolicReadingError,
    InvalidHotFlashEpisodeError,
)
from app.modules.mature_health.domain.models.vasomotor_and_metabolic_logs import (
    CardiometabolicPanel,
    HotFlashEpisode,
    VaginalBleedingObservation,
)
from app.modules.mature_health.domain.services.menopause_transition_service import (
    MenopauseTransitionService,
)
from app.modules.mature_health.domain.value_objects import (
    CardiometabolicRiskLevel,
    HotFlashSeverity,
    HotFlashType,
    MenopauseClinicalAlertSeverity,
    Straw10Stage,
)


def test_straw10_stage_reproductive_late_when_regular() -> None:
    """Low variability (< 7 days) classifies as late reproductive."""
    service = MenopauseTransitionService()
    # Consecutive cycle lengths: 28, 29, 27, 28
    cycle_lengths = [28, 29, 27, 28]
    stage = service.classify_straw10_stage(
        age=43,
        consecutive_cycle_lengths=cycle_lengths,
        days_since_last_menstruation=20,
    )
    assert stage == Straw10Stage.LATE_REPRODUCTIVE


def test_straw10_stage_early_transition_persistent_variability() -> None:
    """Persistent cycle difference >= 7 days classifies as early transition (-2)."""
    service = MenopauseTransitionService()
    # Cycle difference: |36 - 28| = 8 days (>= 7 days)
    cycle_lengths = [28, 36, 27, 35]
    stage = service.classify_straw10_stage(
        age=47,
        consecutive_cycle_lengths=cycle_lengths,
        days_since_last_menstruation=25,
    )
    assert stage == Straw10Stage.EARLY_TRANSITION


def test_straw10_stage_late_transition_amenorrhea_ge_60_days() -> None:
    """Amenorrhea >= 60 days classifies as late transition (-1)."""
    service = MenopauseTransitionService()
    stage = service.classify_straw10_stage(
        age=50,
        consecutive_cycle_lengths=[28, 35, 50],
        days_since_last_menstruation=75,  # >= 60 days
    )
    assert stage == Straw10Stage.LATE_TRANSITION


def test_straw10_stage_established_postmenopause_ge_365_days() -> None:
    """Amenorrhea >= 365 days (12 months) establishes postmenopause (+1/+2)."""
    service = MenopauseTransitionService()
    stage = service.classify_straw10_stage(
        age=52,
        consecutive_cycle_lengths=[45, 90],
        days_since_last_menstruation=380,  # >= 365 days
    )
    assert stage == Straw10Stage.POSTMENOPAUSE


def test_inviolable_postmenopausal_bleeding_alert_triggered() -> None:
    """Bleeding after >= 365 days amenorrhea MUST trigger emergency alert."""
    service = MenopauseTransitionService()
    observation = VaginalBleedingObservation(
        observation_date=date(2026, 5, 10),
        days_of_prior_amenorrhea=410,
        flow_intensity="LIGHT",
        has_cramping=True,
        notes="Ligero manchado marrón",
    )

    alert = service.evaluate_bleeding_safety(observation)

    assert alert is not None
    assert alert.code == "POSTMENOPAUSAL_BLEEDING_ALERT"
    assert alert.severity == MenopauseClinicalAlertSeverity.URGENT_EMERGENCY
    assert "endometrial" in alert.clinical_guidance.lower()
    assert alert.requires_immediate_clinical_evaluation is True


def test_bleeding_during_perimenopause_does_not_trigger_postmenopausal_alert() -> None:
    """Bleeding before 365 days amenorrhea is transition bleeding."""
    service = MenopauseTransitionService()
    observation = VaginalBleedingObservation(
        observation_date=date(2026, 5, 10),
        days_of_prior_amenorrhea=70,  # Late transition
        flow_intensity="MEDIUM",
        has_cramping=False,
    )

    alert = service.evaluate_bleeding_safety(observation)

    assert alert is None


def test_hot_flash_episode_validation() -> None:
    """Hot flash episode enforces valid severity, type, and sleep disruption."""
    episode = HotFlashEpisode(
        occurred_at=datetime(2026, 5, 10, 14, 30, tzinfo=UTC),
        severity=HotFlashSeverity.SEVERE,
        flash_type=HotFlashType.DAYTIME,
        duration_minutes=8,
        triggers=["caffeine", "stress"],
        sleep_disruption_level=0,
        associated_with_hrt=True,
    )
    assert episode.duration_minutes == 8
    assert episode.flash_type == HotFlashType.DAYTIME
    assert "caffeine" in episode.triggers

    with pytest.raises(InvalidHotFlashEpisodeError):
        HotFlashEpisode(
            occurred_at=datetime.now(UTC),
            severity=0,  # type: ignore[arg-type]
            flash_type=HotFlashType.NIGHT_SWEATS,
            duration_minutes=5,
        )


def test_cardiometabolic_panel_evaluation() -> None:
    """Cardiometabolic evaluation identifies high lipid / blood pressure risk."""
    service = MenopauseTransitionService()
    panel = CardiometabolicPanel(
        measurement_date=date(2026, 5, 1),
        systolic_bp=142,
        diastolic_bp=92,
        total_cholesterol_mg_dl=245.0,
        ldl_cholesterol_mg_dl=168.0,
        hdl_cholesterol_mg_dl=42.0,
        triglycerides_mg_dl=190.0,
        fasting_glucose_mg_dl=108.0,
    )

    assessment = service.evaluate_cardiometabolic_panel(panel)

    assert assessment.risk_level == CardiometabolicRiskLevel.ELEVATED_RISK
    assert len(assessment.flagged_parameters) >= 3
    assert "ldl_cholesterol" in assessment.flagged_parameters
    assert "blood_pressure" in assessment.flagged_parameters


def test_cardiometabolic_panel_rejects_negative_values() -> None:
    """Negative lipid or glucose measurements are invalid."""
    with pytest.raises(InvalidCardiometabolicReadingError):
        CardiometabolicPanel(
            measurement_date=date(2026, 5, 1),
            systolic_bp=120,
            diastolic_bp=80,
            ldl_cholesterol_mg_dl=-10.0,
        )
