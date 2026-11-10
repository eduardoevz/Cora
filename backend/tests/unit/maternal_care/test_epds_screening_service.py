from datetime import datetime, timezone
import pytest

from app.modules.maternal_care.domain.services.epds_screening_service import (
    EpdsAssessmentResult,
    EpdsQuestionnaireInput,
    EpdsScreeningService,
)
from app.modules.maternal_care.domain.value_objects.postpartum_observations import (
    PostpartumAlertSeverity,
)


def test_epds_scoring_all_zeros_returns_reassuring() -> None:
    service = EpdsScreeningService()
    # All items answered with lowest score (0 points)
    # Note: items 1,2,4 normal: index 0 -> 0 pts
    # items 3,5,6,7,8,9,10 reverse: index 3 -> 0 pts
    responses = EpdsQuestionnaireInput(
        item_1=0,  # 0 pts
        item_2=0,  # 0 pts
        item_3=3,  # 0 pts
        item_4=0,  # 0 pts
        item_5=3,  # 0 pts
        item_6=3,  # 0 pts
        item_7=3,  # 0 pts
        item_8=3,  # 0 pts
        item_9=3,  # 0 pts
        item_10=3, # 0 pts (Never)
    )

    result: EpdsAssessmentResult = service.evaluate(responses)

    assert result.total_score == 0
    assert result.item_10_score == 0
    assert result.self_harm_risk is False
    assert result.severity == PostpartumAlertSeverity.REASSURING
    assert "adecuado" in result.title.lower() or "tranquilizador" in result.title.lower()


def test_epds_scoring_mild_symptoms_between_10_and_12_triggers_routine_monitoring() -> None:
    service = EpdsScreeningService()
    # Construct total = 11 points with item 10 = 0
    # item 1 = 2 (2 pts)
    # item 2 = 2 (2 pts)
    # item 3 = 1 (2 pts)
    # item 4 = 2 (2 pts)
    # item 5 = 2 (1 pt)
    # item 6 = 2 (1 pt)
    # item 7 = 2 (1 pt)
    # item 8 = 3 (0 pts)
    # item 9 = 3 (0 pts)
    # item 10 = 3 (0 pts)
    # Total = 2 + 2 + 2 + 2 + 1 + 1 + 1 = 11
    responses = EpdsQuestionnaireInput(
        item_1=2,
        item_2=2,
        item_3=1,
        item_4=2,
        item_5=2,
        item_6=2,
        item_7=2,
        item_8=3,
        item_9=3,
        item_10=3,
    )

    result = service.evaluate(responses)

    assert result.total_score == 11
    assert result.item_10_score == 0
    assert result.self_harm_risk is False
    assert result.severity == PostpartumAlertSeverity.ROUTINE_MONITORING
    assert "2 semanas" in result.action_recommended.lower() or "seguimiento" in result.action_recommended.lower()


def test_epds_scoring_severe_symptoms_greater_or_equal_13_triggers_priority_consult() -> None:
    service = EpdsScreeningService()
    # Construct total = 16 points with item 10 = 0
    # item 1 = 3 (3 pts)
    # item 2 = 3 (3 pts)
    # item 3 = 0 (3 pts)
    # item 4 = 3 (3 pts)
    # item 5 = 1 (2 pts)
    # item 6 = 1 (2 pts)
    # item 7 = 3 (0 pts)
    # item 8 = 3 (0 pts)
    # item 9 = 3 (0 pts)
    # item 10 = 3 (0 pts)
    # Total = 3 + 3 + 3 + 3 + 2 + 2 = 16
    responses = EpdsQuestionnaireInput(
        item_1=3,
        item_2=3,
        item_3=0,
        item_4=3,
        item_5=1,
        item_6=1,
        item_7=3,
        item_8=3,
        item_9=3,
        item_10=3,
    )

    result = service.evaluate(responses)

    assert result.total_score == 16
    assert result.item_10_score == 0
    assert result.self_harm_risk is False
    assert result.severity == PostpartumAlertSeverity.PRIORITY_CONSULT
    assert "salud mental perinatal" in result.action_recommended.lower() or "profesional" in result.action_recommended.lower()


def test_epds_item_10_positive_triggers_immediate_crisis_support_even_with_low_total() -> None:
    service = EpdsScreeningService()
    # Total score is very low (e.g. 2 points total: item 1=1, item 10=2 which is 1 pt: "casi nunca")
    # All other items 0 points
    responses = EpdsQuestionnaireInput(
        item_1=1,  # 1 pt
        item_2=0,  # 0 pts
        item_3=3,  # 0 pts
        item_4=0,  # 0 pts
        item_5=3,  # 0 pts
        item_6=3,  # 0 pts
        item_7=3,  # 0 pts
        item_8=3,  # 0 pts
        item_9=3,  # 0 pts
        item_10=2, # 1 pt ("Casi nunca")
    )

    result = service.evaluate(responses)

    assert result.total_score == 2
    assert result.item_10_score == 1
    assert result.self_harm_risk is True
    # MUST unconditionally trigger IMMEDIATE_CRISIS_SUPPORT
    assert result.severity == PostpartumAlertSeverity.IMMEDIATE_CRISIS_SUPPORT
    assert "crisis" in result.title.lower() or "urgente" in result.title.lower() or "apoyo" in result.title.lower()
    assert "línea" in result.action_recommended.lower() or "urgencia" in result.action_recommended.lower()


def test_epds_item_10_maximum_score_triggers_immediate_crisis_support() -> None:
    service = EpdsScreeningService()
    # Item 10 index 0 ("Sí, bastante a menudo") = 3 points
    responses = EpdsQuestionnaireInput(
        item_1=0,
        item_2=0,
        item_3=3,
        item_4=0,
        item_5=3,
        item_6=3,
        item_7=3,
        item_8=3,
        item_9=3,
        item_10=0, # 3 pts
    )

    result = service.evaluate(responses)

    assert result.total_score == 3
    assert result.item_10_score == 3
    assert result.self_harm_risk is True
    assert result.severity == PostpartumAlertSeverity.IMMEDIATE_CRISIS_SUPPORT


def test_epds_invalid_response_index_raises_value_error() -> None:
    service = EpdsScreeningService()
    with pytest.raises(ValueError, match="Response index must be between 0 and 3"):
        EpdsQuestionnaireInput(
            item_1=5,
            item_2=0,
            item_3=0,
            item_4=0,
            item_5=0,
            item_6=0,
            item_7=0,
            item_8=0,
            item_9=0,
            item_10=0,
        )
