from datetime import UTC, datetime, timedelta

from app.modules.maternal_care.domain.models.lactation_and_milk_stash import (
    FeedingType,
    LactationSession,
    MilkStashEntry,
    OfferedBreast,
    StorageLocation,
)
from app.modules.maternal_care.domain.services.postpartum_recovery_evaluator import (
    PostpartumRecoveryEvaluationInput,
    PostpartumRecoveryEvaluator,
)
from app.modules.maternal_care.domain.value_objects.postpartum_observations import (
    CesareanWoundStatus,
    LochiaFlow,
    LochiaStage,
    PelvicFloorSymptom,
    PerinealWoundStatus,
    PostpartumAlertSeverity,
)


def test_normal_postpartum_recovery_returns_no_critical_alerts() -> None:
    evaluator = PostpartumRecoveryEvaluator()
    obs = PostpartumRecoveryEvaluationInput(
        days_postpartum=3,
        lochia_stage=LochiaStage.RUBRA,
        lochia_flow=LochiaFlow.MODERATE,
        foul_odor=False,
        maternal_temperature_c=36.8,
        perineal_wound_status=PerinealWoundStatus.HEALING_NORMALLY,
        cesarean_wound_status=None,
        pelvic_floor_symptoms=[PelvicFloorSymptom.NORMAL],
    )

    alerts = evaluator.evaluate(obs)
    assert len(alerts) == 0


def test_secondary_postpartum_hemorrhage_triggers_urgent_emergency() -> None:
    evaluator = PostpartumRecoveryEvaluator()
    # Soaking pad in under 1 hour
    obs = PostpartumRecoveryEvaluationInput(
        days_postpartum=8,
        lochia_stage=LochiaStage.RUBRA,
        lochia_flow=LochiaFlow.HEAVY_SOAKING_PAD_UNDER_1H,
        foul_odor=False,
        maternal_temperature_c=37.0,
        perineal_wound_status=None,
        cesarean_wound_status=None,
        pelvic_floor_symptoms=[],
    )

    alerts = evaluator.evaluate(obs)
    assert any(
        a.severity == PostpartumAlertSeverity.URGENT_EMERGENCY
        and "hemorragia" in a.title.lower()
        for a in alerts
    )


def test_large_clots_trigger_urgent_emergency() -> None:
    evaluator = PostpartumRecoveryEvaluator()
    obs = PostpartumRecoveryEvaluationInput(
        days_postpartum=5,
        lochia_stage=LochiaStage.RUBRA,
        lochia_flow=LochiaFlow.CLOTS_GREATER_THAN_GOLF_BALL,
        foul_odor=False,
        maternal_temperature_c=36.9,
        perineal_wound_status=None,
        cesarean_wound_status=None,
        pelvic_floor_symptoms=[],
    )

    alerts = evaluator.evaluate(obs)
    assert any(a.severity == PostpartumAlertSeverity.URGENT_EMERGENCY for a in alerts)


def test_puerperal_endometritis_with_foul_odor_triggers_urgent_emergency() -> None:
    evaluator = PostpartumRecoveryEvaluator()
    obs = PostpartumRecoveryEvaluationInput(
        days_postpartum=6,
        lochia_stage=LochiaStage.SEROSA,
        lochia_flow=LochiaFlow.LIGHT,
        foul_odor=True,
        maternal_temperature_c=38.2,
        perineal_wound_status=None,
        cesarean_wound_status=None,
        pelvic_floor_symptoms=[],
    )

    alerts = evaluator.evaluate(obs)
    assert any(
        a.severity == PostpartumAlertSeverity.URGENT_EMERGENCY
        and ("infección" in a.title.lower() or "endometritis" in a.title.lower())
        for a in alerts
    )


def test_atypical_lochia_regression_after_14_days_triggers_priority_consult() -> None:
    evaluator = PostpartumRecoveryEvaluator()
    # Week 3 (day 21) returning to heavy bright red rubra
    obs = PostpartumRecoveryEvaluationInput(
        days_postpartum=21,
        lochia_stage=LochiaStage.RUBRA,
        lochia_flow=LochiaFlow.MODERATE,
        foul_odor=False,
        maternal_temperature_c=36.7,
        perineal_wound_status=None,
        cesarean_wound_status=None,
        pelvic_floor_symptoms=[],
    )

    alerts = evaluator.evaluate(obs)
    assert any(
        a.severity == PostpartumAlertSeverity.PRIORITY_CONSULT
        and "regresión" in a.title.lower()
        for a in alerts
    )


def test_cesarean_wound_purulent_drainage_triggers_urgent_emergency() -> None:
    evaluator = PostpartumRecoveryEvaluator()
    obs = PostpartumRecoveryEvaluationInput(
        days_postpartum=7,
        lochia_stage=LochiaStage.SEROSA,
        lochia_flow=LochiaFlow.LIGHT,
        foul_odor=False,
        maternal_temperature_c=37.5,
        perineal_wound_status=None,
        cesarean_wound_status=CesareanWoundStatus.PURULENT_DRAINAGE_OR_DEHISCENCE,
        pelvic_floor_symptoms=[],
    )

    alerts = evaluator.evaluate(obs)
    assert any(
        a.severity == PostpartumAlertSeverity.URGENT_EMERGENCY
        and "quirúrgica" in a.title.lower()
        for a in alerts
    )


def test_perineal_wound_erythema_edema_triggers_priority_consult() -> None:
    evaluator = PostpartumRecoveryEvaluator()
    obs = PostpartumRecoveryEvaluationInput(
        days_postpartum=4,
        lochia_stage=LochiaStage.RUBRA,
        lochia_flow=LochiaFlow.LIGHT,
        foul_odor=False,
        maternal_temperature_c=36.9,
        perineal_wound_status=PerinealWoundStatus.ERYTHEMA_EDEMA,
        cesarean_wound_status=None,
        pelvic_floor_symptoms=[],
    )

    alerts = evaluator.evaluate(obs)
    assert any(a.severity == PostpartumAlertSeverity.PRIORITY_CONSULT for a in alerts)


def test_milk_stash_expiration_calculation_per_cdc_who() -> None:
    now = datetime(2026, 11, 10, 10, 0, tzinfo=UTC)

    # 1. Room temp: 4 hours
    room_stash = MilkStashEntry.create(
        user_id="usr_123",
        pumped_at=now,
        volume_ml=120.0,
        storage_location=StorageLocation.ROOM_TEMP,
    )
    assert room_stash.expires_at == now + timedelta(hours=4)

    # 2. Refrigerator: 4 days
    fridge_stash = MilkStashEntry.create(
        user_id="usr_123",
        pumped_at=now,
        volume_ml=150.0,
        storage_location=StorageLocation.REFRIGERATOR,
    )
    assert fridge_stash.expires_at == now + timedelta(days=4)

    # 3. Freezer: 180 days (6 months)
    freezer_stash = MilkStashEntry.create(
        user_id="usr_123",
        pumped_at=now,
        volume_ml=200.0,
        storage_location=StorageLocation.FREEZER,
    )
    assert freezer_stash.expires_at == now + timedelta(days=180)


def test_lactation_session_creation_and_next_breast_suggestion() -> None:
    now = datetime.now(UTC)
    session = LactationSession(
        id="lact_01",
        user_id="usr_123",
        started_at=now - timedelta(minutes=25),
        ended_at=now,
        left_duration_seconds=600,
        right_duration_seconds=900,
        last_offered_breast=OfferedBreast.RIGHT,
        bottle_volume_ml=None,
        feeding_type=FeedingType.BREAST_ONLY,
        notes="Buena succión",
    )

    assert session.total_duration_seconds == 1500
    assert session.suggested_next_breast == OfferedBreast.LEFT
