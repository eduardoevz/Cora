import uuid
from datetime import date

import pytest

from app.modules.maternal_care.domain.exceptions.maternal_care_exceptions import (
    InvalidGestationalAgeError,
    PregnancyEpisodeValidationError,
)
from app.modules.maternal_care.domain.models.pregnancy_episode import (
    GestationalAge,
    PregnancyEpisode,
)
from app.modules.maternal_care.domain.services.fetal_weekly_milestones_catalog import (
    FetalWeeklyMilestonesCatalog,
)


class TestGestationalAge:
    def test_valid_gestational_age(self) -> None:
        ga = GestationalAge(weeks=12, days=3)
        assert ga.weeks == 12
        assert ga.days == 3
        assert ga.total_days == 87
        assert str(ga) == "12 semanas y 3 días"

    @pytest.mark.parametrize(
        "weeks,days",
        [
            (12, 7),
            (12, -1),
            (1, 0),
            (45, 0),
        ],
    )
    def test_invalid_gestational_age_raises_error(self, weeks: int, days: int) -> None:
        with pytest.raises(InvalidGestationalAgeError):
            GestationalAge(weeks=weeks, days=days)

    def test_from_dates_naegele(self) -> None:
        lmp = date(2026, 1, 1)
        ref = date(2026, 3, 5)  # 63 days -> 9 weeks, 0 days
        ga = GestationalAge.from_dates(last_menstrual_period=lmp, reference_date=ref)
        assert ga.weeks == 9
        assert ga.days == 0


class TestPregnancyEpisode:
    def test_create_episode_calculates_edd_from_lmp(self) -> None:
        lmp = date(2026, 2, 1)
        episode = PregnancyEpisode.create_from_lmp(
            user_id=uuid.uuid4(),
            last_menstrual_period=lmp,
        )
        assert episode.clinical_edd == date(2026, 11, 8)  # + 280 days
        assert episode.is_active is True

        ga = episode.calculate_gestational_age(as_of=date(2026, 4, 1))
        # 59 days between Feb 1 and Apr 1 -> 8 weeks, 3 days
        assert ga.weeks == 8
        assert ga.days == 3
        assert episode.current_trimester(as_of=date(2026, 4, 1)) == 1

    def test_recalibrate_with_ultrasound_edd(self) -> None:
        lmp = date(2026, 2, 1)
        episode = PregnancyEpisode.create_from_lmp(
            user_id=uuid.uuid4(),
            last_menstrual_period=lmp,
        )
        new_ultrasound_edd = date(2026, 11, 15)

        episode.recalibrate_with_ultrasound(
            ultrasound_edd=new_ultrasound_edd,
            note="Ajuste por longitud craneocaudal (LCC) en eco semana 12",
        )
        assert episode.ultrasound_edd == new_ultrasound_edd
        assert episode.clinical_edd == new_ultrasound_edd
        assert episode.last_menstrual_period == lmp  # Preserved!
        assert len(episode.recalibration_history) == 1

    def test_cannot_create_episode_without_lmp_or_edd(self) -> None:
        with pytest.raises(PregnancyEpisodeValidationError):
            PregnancyEpisode(
                id=uuid.uuid4(),
                user_id=uuid.uuid4(),
                last_menstrual_period=None,
                ultrasound_edd=None,
                clinical_edd=None,  # type: ignore[arg-type]
                is_active=True,
                started_at=date(2026, 1, 1),  # type: ignore[arg-type]
            )


class TestFetalWeeklyMilestonesCatalog:
    def test_catalog_retrieves_all_weeks(self) -> None:
        catalog = FetalWeeklyMilestonesCatalog()
        for week in range(4, 43):
            milestone = catalog.get_milestone(week)
            assert milestone.week == week
            assert milestone.fruit_or_vegetable_comparison != ""
            assert milestone.anatomical_highlights != ""
            assert milestone.clinical_recommendations != ""

    def test_specific_milestone_milestones(self) -> None:
        catalog = FetalWeeklyMilestonesCatalog()
        w12 = catalog.get_milestone(12)
        assert "ciruela" in w12.fruit_or_vegetable_comparison.lower()
        w20 = catalog.get_milestone(20)
        assert (
            "plátano" in w20.fruit_or_vegetable_comparison.lower()
            or "platano" in w20.fruit_or_vegetable_comparison.lower()
        )
        w40 = catalog.get_milestone(40)
        assert (
            "sandía" in w40.fruit_or_vegetable_comparison.lower()
            or "calabaza" in w40.fruit_or_vegetable_comparison.lower()
        )
