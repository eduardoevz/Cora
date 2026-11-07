from dataclasses import dataclass
from enum import StrEnum

from app.modules.clinical_tracking.domain.exceptions.clinical_tracking_exceptions import (  # noqa: E501
    InvalidWellnessMetricError,
)


class MoodTag(StrEnum):
    """Categorized emotional and somatic mood states."""

    HAPPY = "happy"
    CALM = "calm"
    ANXIOUS = "anxious"
    SAD = "sad"
    IRRITATED = "irritated"
    ENERGETIC = "energetic"
    EXHAUSTED = "exhausted"
    CRAMPY = "crampy"
    BLOATED = "bloated"
    FOCUSED = "focused"
    STRESSED = "stressed"


@dataclass(frozen=True)
class SleepHours:
    """Daily total sleep duration in hours."""

    value: float

    def __post_init__(self) -> None:
        if not (0.0 <= self.value <= 24.0):
            raise InvalidWellnessMetricError(
                metric_name="Horas de sueño",
                value=self.value,
                valid_range="0.0 a 24.0 horas",
            )


@dataclass(frozen=True)
class SleepQuality:
    """Subjective sleep quality score on 1-5 Likert scale."""

    value: int

    def __post_init__(self) -> None:
        if not (1 <= self.value <= 5):
            raise InvalidWellnessMetricError(
                metric_name="Calidad de sueño",
                value=self.value,
                valid_range="1 a 5",
            )


@dataclass(frozen=True)
class EnergyLevel:
    """Subjective vitality score on 1-5 Likert scale."""

    value: int

    def __post_init__(self) -> None:
        if not (1 <= self.value <= 5):
            raise InvalidWellnessMetricError(
                metric_name="Nivel de energía",
                value=self.value,
                valid_range="1 a 5",
            )


@dataclass(frozen=True)
class HydrationMl:
    """Cumulative daily water intake in milliliters."""

    value: int

    def __post_init__(self) -> None:
        if not (0 <= self.value <= 10000):
            raise InvalidWellnessMetricError(
                metric_name="Hidratación",
                value=self.value,
                valid_range="0 a 10,000 ml",
            )


@dataclass(frozen=True)
class ExerciseMinutes:
    """Daily moderate-to-vigorous physical activity in minutes."""

    value: int

    def __post_init__(self) -> None:
        if not (0 <= self.value <= 1440):
            raise InvalidWellnessMetricError(
                metric_name="Actividad física",
                value=self.value,
                valid_range="0 a 1440 minutos",
            )
