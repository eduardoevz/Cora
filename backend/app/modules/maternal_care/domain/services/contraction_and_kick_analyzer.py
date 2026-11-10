from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum

from app.modules.maternal_care.domain.value_objects.maternal_vitals import (
    MaternalAlertSeverity,
    MaternalClinicalAlert,
    MaternalRiskCategory,
)


class ContractionIntensity(StrEnum):
    MILD = "mild"
    MODERATE = "moderate"
    STRONG = "strong"


@dataclass(frozen=True)
class ContractionEvent:
    started_at: datetime
    duration_seconds: int
    intensity: ContractionIntensity


@dataclass(frozen=True)
class ContractionSession:
    events: list[ContractionEvent]


class ContractionPattern(StrEnum):
    ACTIVE_LABOR_511 = "active_labor_511"
    PRETERM_LABOR_RISK = "preterm_labor_risk"
    REGULAR_EARLY = "regular_early"
    IRREGULAR_OR_EARLY = "irregular_or_early"
    INSUFFICIENT_DATA = "insufficient_data"


@dataclass(frozen=True)
class ContractionAssessment:
    pattern: ContractionPattern
    alert: MaternalClinicalAlert | None
    average_interval_minutes: float
    average_duration_seconds: float
    total_contractions: int


@dataclass(frozen=True)
class KickSession:
    started_at: datetime
    kicks_count: int
    duration_minutes: int
    target_reached_at_minutes: int | None = None


@dataclass(frozen=True)
class KickAssessment:
    is_reassuring: bool
    target_reached: bool
    alert: MaternalClinicalAlert | None
    kicks_count: int
    duration_minutes: int


class ContractionAndKickAnalyzer:
    """
    Evaluates uterine contractions (Rule 5-1-1 vs Preterm Risk)
    and fetal kick counts (Cardiff count-to-10 protocol).
    """

    def analyze_contractions(
        self, session: ContractionSession, gestational_weeks: int
    ) -> ContractionAssessment:
        events = sorted(session.events, key=lambda e: e.started_at)
        total = len(events)

        if total < 2:
            avg_dur = float(events[0].duration_seconds) if total == 1 else 0.0
            return ContractionAssessment(
                pattern=ContractionPattern.INSUFFICIENT_DATA,
                alert=None,
                average_interval_minutes=0.0,
                average_duration_seconds=avg_dur,
                total_contractions=total,
            )

        # Calculate intervals between consecutive contraction starts
        intervals_sec: list[float] = []
        for i in range(1, total):
            delta = (events[i].started_at - events[i - 1].started_at).total_seconds()
            intervals_sec.append(delta)

        avg_interval_min = (sum(intervals_sec) / len(intervals_sec)) / 60.0
        avg_duration_sec = sum(e.duration_seconds for e in events) / float(total)

        # 1. Preterm assessment (< 37 weeks)
        if gestational_weeks < 37:
            is_preterm_risk = False
            for i in range(total):
                t0 = events[i].started_at
                count_20m = sum(
                    1
                    for e in events
                    if 0 <= (e.started_at - t0).total_seconds() <= 1200
                )
                count_60m = sum(
                    1
                    for e in events
                    if 0 <= (e.started_at - t0).total_seconds() <= 3600
                )
                if count_20m >= 4 or count_60m >= 8:
                    is_preterm_risk = True
                    break

            if is_preterm_risk:
                alert = MaternalClinicalAlert(
                    severity=MaternalAlertSeverity.URGENT_EMERGENCY,
                    category=MaternalRiskCategory.PRETERM_LABOR_RISK,
                    title="Contracciones Regulares / Riesgo Pretérmino",
                    message=(
                        f"Se registran {total} contracciones regulares a las "
                        f"{gestational_weeks} semanas. Riesgo de parto pretérmino."
                    ),
                    action_recommended=(
                        "Acudir de inmediato a urgencias obstétricas para evaluación "
                        "con tocodinamometría y longitud cervical."
                    ),
                )
                return ContractionAssessment(
                    pattern=ContractionPattern.PRETERM_LABOR_RISK,
                    alert=alert,
                    average_interval_minutes=avg_interval_min,
                    average_duration_seconds=avg_duration_sec,
                    total_contractions=total,
                )

        # 2. Term assessment (>= 37 weeks): Rule 5-1-1
        is_511 = avg_interval_min <= 5.0 and avg_duration_sec >= 60.0 and total >= 8

        if is_511:
            alert = MaternalClinicalAlert(
                severity=MaternalAlertSeverity.PRIORITY_CONSULT,
                category=MaternalRiskCategory.GENERAL_OBSTETRIC,
                title="Patrón 5-1-1: Trabajo de Parto Activo",
                message=(
                    f"Contracciones regulares cada {avg_interval_min:.1f} min, con "
                    f"{avg_duration_sec:.0f} s de duración promedio."
                ),
                action_recommended=(
                    "Momento oportuno para contactar a su equipo de obstetricia "
                    "o trasladarse a la maternidad según su plan de parto."
                ),
            )
            return ContractionAssessment(
                pattern=ContractionPattern.ACTIVE_LABOR_511,
                alert=alert,
                average_interval_minutes=avg_interval_min,
                average_duration_seconds=avg_duration_sec,
                total_contractions=total,
            )

        # 3. Regular early vs Irregular
        if avg_interval_min <= 10.0 and total >= 4:
            return ContractionAssessment(
                pattern=ContractionPattern.REGULAR_EARLY,
                alert=None,
                average_interval_minutes=avg_interval_min,
                average_duration_seconds=avg_duration_sec,
                total_contractions=total,
            )

        return ContractionAssessment(
            pattern=ContractionPattern.IRREGULAR_OR_EARLY,
            alert=None,
            average_interval_minutes=avg_interval_min,
            average_duration_seconds=avg_duration_sec,
            total_contractions=total,
        )

    def analyze_kicks(
        self, session: KickSession, gestational_weeks: int
    ) -> KickAssessment:
        target_reached = session.kicks_count >= 10

        if target_reached:
            return KickAssessment(
                is_reassuring=True,
                target_reached=True,
                alert=None,
                kicks_count=session.kicks_count,
                duration_minutes=session.duration_minutes,
            )

        # If session >= 120 minutes and not reached 10 kicks -> urgent warning
        if session.duration_minutes >= 120 and session.kicks_count < 10:
            alert = MaternalClinicalAlert(
                severity=MaternalAlertSeverity.URGENT_EMERGENCY,
                category=MaternalRiskCategory.FETAL_WELLBEING_RISK,
                title="Disminución de Movimientos Fetales (Cardiff < 10)",
                message=(
                    f"Solo {session.kicks_count} movimientos fetales registrados "
                    f"en {session.duration_minutes} min (meta: 10 en <= 120 min)."
                ),
                action_recommended=(
                    "Estimular al bebé bebiendo algo frío o con azúcar y recostarse "
                    "sobre el lado izquierdo. Si no alcanza 10 movimientos, acudir "
                    "de inmediato al hospital para monitoreo fetal y RCTG."
                ),
            )
            return KickAssessment(
                is_reassuring=False,
                target_reached=False,
                alert=alert,
                kicks_count=session.kicks_count,
                duration_minutes=session.duration_minutes,
            )

        # Session in progress, under 120 min
        return KickAssessment(
            is_reassuring=True,
            target_reached=False,
            alert=None,
            kicks_count=session.kicks_count,
            duration_minutes=session.duration_minutes,
        )
