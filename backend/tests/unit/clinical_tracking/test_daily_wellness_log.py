from datetime import date
from uuid import uuid4

import pytest

from app.modules.clinical_tracking.application.dtos.wellness_dtos import (
    UpsertWellnessDTO,
)
from app.modules.clinical_tracking.application.ports.wellness_repository_port import (
    IWellnessRepository,
)
from app.modules.clinical_tracking.application.use_cases.upsert_daily_wellness_use_case import (  # noqa: E501
    UpsertDailyWellnessUseCase,
)
from app.modules.clinical_tracking.domain.exceptions.clinical_tracking_exceptions import (  # noqa: E501
    InvalidWellnessMetricError,
)
from app.modules.clinical_tracking.domain.models.daily_wellness_log import (
    DailyWellnessLog,
)
from app.modules.clinical_tracking.domain.value_objects.wellness_metrics import (
    EnergyLevel,
    ExerciseMinutes,
    HydrationMl,
    MoodTag,
    SleepHours,
    SleepQuality,
)


class InMemoryWellnessRepository(IWellnessRepository):
    """In-memory implementation of IWellnessRepository for fast unit tests."""

    def __init__(self) -> None:
        self.logs: dict[tuple[str, date], DailyWellnessLog] = {}

    async def upsert(self, log: DailyWellnessLog) -> DailyWellnessLog:
        self.logs[(log.user_id, log.log_date)] = log
        return log

    async def get_by_date(
        self, user_id: str, log_date: date
    ) -> DailyWellnessLog | None:
        return self.logs.get((user_id, log_date))

    async def get_history(
        self, user_id: str, start_date: date, end_date: date
    ) -> list[DailyWellnessLog]:
        return [
            log
            for (uid, d), log in self.logs.items()
            if uid == user_id and start_date <= d <= end_date
        ]


def test_sleep_hours_validation() -> None:
    assert SleepHours(7.5).value == 7.5
    assert SleepHours(0.0).value == 0.0
    assert SleepHours(24.0).value == 24.0

    with pytest.raises(InvalidWellnessMetricError, match="Horas de sueño"):
        SleepHours(-0.5)

    with pytest.raises(InvalidWellnessMetricError, match="Horas de sueño"):
        SleepHours(24.5)


def test_sleep_quality_validation() -> None:
    assert SleepQuality(1).value == 1
    assert SleepQuality(5).value == 5

    with pytest.raises(InvalidWellnessMetricError, match="Calidad de sueño"):
        SleepQuality(0)

    with pytest.raises(InvalidWellnessMetricError, match="Calidad de sueño"):
        SleepQuality(6)


def test_energy_level_validation() -> None:
    assert EnergyLevel(3).value == 3

    with pytest.raises(InvalidWellnessMetricError, match="Nivel de energía"):
        EnergyLevel(0)

    with pytest.raises(InvalidWellnessMetricError, match="Nivel de energía"):
        EnergyLevel(6)


def test_hydration_ml_validation() -> None:
    assert HydrationMl(2500).value == 2500
    assert HydrationMl(0).value == 0

    with pytest.raises(InvalidWellnessMetricError, match="Hidratación"):
        HydrationMl(-1)

    with pytest.raises(InvalidWellnessMetricError, match="Hidratación"):
        HydrationMl(10001)


def test_exercise_minutes_validation() -> None:
    assert ExerciseMinutes(45).value == 45

    with pytest.raises(InvalidWellnessMetricError, match="Actividad física"):
        ExerciseMinutes(-5)

    with pytest.raises(InvalidWellnessMetricError, match="Actividad física"):
        ExerciseMinutes(1441)


def test_daily_wellness_log_merge_patch_preserves_unmodified_fields() -> None:
    user_id = str(uuid4())
    log_date = date(2026, 11, 7)

    # Initial morning log: sleep and calm mood
    initial_log = DailyWellnessLog.create(
        user_id=user_id,
        log_date=log_date,
        sleep_hours=SleepHours(8.0),
        sleep_quality=SleepQuality(4),
        mood_tags=[MoodTag.CALM],
    )

    assert initial_log.sleep_hours == SleepHours(8.0)
    assert initial_log.sleep_quality == SleepQuality(4)
    assert initial_log.hydration_ml is None
    assert initial_log.exercise_minutes is None
    assert initial_log.mood_tags == [MoodTag.CALM]

    # Afternoon update: adding hydration and energetic mood without sending sleep
    updated_log = initial_log.merge_patch(
        hydration_ml=HydrationMl(1500),
        energy_level=EnergyLevel(4),
        mood_tags=[MoodTag.CALM, MoodTag.ENERGETIC],
    )

    # Prior sleep fields must be preserved
    assert updated_log.sleep_hours == SleepHours(8.0)
    assert updated_log.sleep_quality == SleepQuality(4)
    # New fields must be updated
    assert updated_log.hydration_ml == HydrationMl(1500)
    assert updated_log.energy_level == EnergyLevel(4)
    assert updated_log.mood_tags == [MoodTag.CALM, MoodTag.ENERGETIC]


@pytest.mark.asyncio
async def test_upsert_daily_wellness_use_case_merges_data_across_the_day() -> None:
    repo = InMemoryWellnessRepository()
    use_case = UpsertDailyWellnessUseCase(repo)
    user_id = "test-user-123"
    today = date(2026, 11, 7)

    # 1. Morning check-in
    morning_dto = UpsertWellnessDTO(
        sleep_hours=7.5,
        sleep_quality=4,
        energy_level=3,
        mood_tags=["calm", "focused"],
    )
    result_morning = await use_case.execute(
        user_id=user_id, log_date=today, dto=morning_dto
    )
    assert result_morning.sleep_hours.value == 7.5  # type: ignore[union-attr]
    assert result_morning.hydration_ml is None

    # 2. Evening check-in: records water and workout
    evening_dto = UpsertWellnessDTO(
        hydration_ml=2200,
        exercise_minutes=45,
        notes="Buena caminata por la tarde",
    )
    result_evening = await use_case.execute(
        user_id=user_id, log_date=today, dto=evening_dto
    )

    # Consolidates both sessions
    assert result_evening.sleep_hours.value == 7.5  # type: ignore[union-attr]
    assert result_evening.sleep_quality.value == 4  # type: ignore[union-attr]
    assert result_evening.energy_level.value == 3  # type: ignore[union-attr]
    assert result_evening.hydration_ml.value == 2200  # type: ignore[union-attr]
    assert result_evening.exercise_minutes.value == 45  # type: ignore[union-attr]
    assert result_evening.notes == "Buena caminata por la tarde"
