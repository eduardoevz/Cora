from datetime import UTC, datetime, timedelta

from app.modules.maternal_care.domain.services.contraction_and_kick_analyzer import (
    ContractionAndKickAnalyzer,
    ContractionEvent,
    ContractionIntensity,
    ContractionPattern,
    ContractionSession,
    KickSession,
)
from app.modules.maternal_care.domain.value_objects.maternal_vitals import (
    MaternalAlertSeverity,
    MaternalRiskCategory,
)


class TestContractionAnalyzer:
    def test_term_pregnancy_511_rule_detected(self) -> None:
        start = datetime(2026, 11, 10, 10, 0, tzinfo=UTC)
        events = []
        for i in range(13):
            events.append(
                ContractionEvent(
                    started_at=start + timedelta(minutes=i * 4),
                    duration_seconds=65,
                    intensity=ContractionIntensity.STRONG,
                )
            )
        session = ContractionSession(events=events)
        analyzer = ContractionAndKickAnalyzer()
        assessment = analyzer.analyze_contractions(
            session=session, gestational_weeks=39
        )

        assert assessment.pattern == ContractionPattern.ACTIVE_LABOR_511
        assert assessment.alert is not None
        assert assessment.alert.severity == MaternalAlertSeverity.PRIORITY_CONSULT
        assert "5-1-1" in assessment.alert.title
        assert assessment.average_interval_minutes <= 5.0
        assert assessment.average_duration_seconds >= 60.0

    def test_preterm_pregnancy_regular_contractions_triggers_preterm_risk(self) -> None:
        start = datetime(2026, 11, 10, 10, 0, tzinfo=UTC)
        events = []
        for i in range(5):
            events.append(
                ContractionEvent(
                    started_at=start + timedelta(minutes=i * 4),  # 5 in 16 min
                    duration_seconds=45,
                    intensity=ContractionIntensity.MODERATE,
                )
            )
        session = ContractionSession(events=events)
        analyzer = ContractionAndKickAnalyzer()
        assessment = analyzer.analyze_contractions(
            session=session, gestational_weeks=31
        )

        assert assessment.pattern == ContractionPattern.PRETERM_LABOR_RISK
        assert assessment.alert is not None
        assert assessment.alert.severity == MaternalAlertSeverity.URGENT_EMERGENCY
        assert assessment.alert.category == MaternalRiskCategory.PRETERM_LABOR_RISK
        assert "pretérmino" in assessment.alert.title.lower()

    def test_irregular_braxton_hicks_contractions_no_urgent_alert(self) -> None:
        start = datetime(2026, 11, 10, 10, 0, tzinfo=UTC)
        events = [
            ContractionEvent(
                started_at=start,
                duration_seconds=30,
                intensity=ContractionIntensity.MILD,
            ),
            ContractionEvent(
                started_at=start + timedelta(minutes=18),
                duration_seconds=35,
                intensity=ContractionIntensity.MILD,
            ),
            ContractionEvent(
                started_at=start + timedelta(minutes=38),
                duration_seconds=25,
                intensity=ContractionIntensity.MILD,
            ),
        ]
        session = ContractionSession(events=events)
        analyzer = ContractionAndKickAnalyzer()
        assessment = analyzer.analyze_contractions(
            session=session, gestational_weeks=38
        )

        assert assessment.pattern == ContractionPattern.IRREGULAR_OR_EARLY
        assert (
            assessment.alert is None
            or assessment.alert.severity == MaternalAlertSeverity.INFO
        )


class TestCardiffKickAnalyzer:
    def test_reassuring_kicks_reached_10_within_120_minutes(self) -> None:
        start = datetime(2026, 11, 10, 14, 0, tzinfo=UTC)
        session = KickSession(
            started_at=start,
            kicks_count=10,
            duration_minutes=42,
            target_reached_at_minutes=42,
        )
        analyzer = ContractionAndKickAnalyzer()
        result = analyzer.analyze_kicks(session=session, gestational_weeks=32)

        assert result.is_reassuring is True
        assert result.alert is None
        assert result.target_reached is True

    def test_abnormal_kicks_less_than_10_in_120_minutes_triggers_urgent_alert(
        self,
    ) -> None:
        start = datetime(2026, 11, 10, 14, 0, tzinfo=UTC)
        session = KickSession(
            started_at=start,
            kicks_count=6,
            duration_minutes=120,
            target_reached_at_minutes=None,
        )
        analyzer = ContractionAndKickAnalyzer()
        result = analyzer.analyze_kicks(session=session, gestational_weeks=34)

        assert result.is_reassuring is False
        assert result.alert is not None
        assert result.alert.severity == MaternalAlertSeverity.URGENT_EMERGENCY
        assert result.alert.category == MaternalRiskCategory.FETAL_WELLBEING_RISK
        assert "movimientos fetales" in result.alert.title.lower()
