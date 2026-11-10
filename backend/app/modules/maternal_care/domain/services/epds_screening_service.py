from dataclasses import dataclass

from app.modules.maternal_care.domain.value_objects.postpartum_observations import (
    PostpartumAlertSeverity,
)


@dataclass(frozen=True)
class EpdsQuestionnaireInput:
    item_1: int
    item_2: int
    item_3: int
    item_4: int
    item_5: int
    item_6: int
    item_7: int
    item_8: int
    item_9: int
    item_10: int

    def __post_init__(self) -> None:
        items = [
            self.item_1,
            self.item_2,
            self.item_3,
            self.item_4,
            self.item_5,
            self.item_6,
            self.item_7,
            self.item_8,
            self.item_9,
            self.item_10,
        ]
        for idx, val in enumerate(items, start=1):
            if not isinstance(val, int) or val < 0 or val > 3:
                raise ValueError(
                    f"Response index must be between 0 and 3 for item {idx}"
                )


@dataclass(frozen=True)
class EpdsAssessmentResult:
    total_score: int
    item_10_score: int
    self_harm_risk: bool
    severity: PostpartumAlertSeverity
    title: str
    message: str
    action_recommended: str
    item_scores: dict[str, int]


class EpdsScreeningService:
    """
    Edinburgh Postnatal Depression Scale (EPDS) scoring service.
    Follows validated international scoring standards:
    - Normal scored items: 1, 2, 4 (0, 1, 2, 3)
    - Reverse scored items: 3, 5, 6, 7, 8, 9, 10 (3, 2, 1, 0)
    - Item 10 > 0 unconditionally triggers IMMEDIATE_CRISIS_SUPPORT.
    """

    @staticmethod
    def evaluate(responses: EpdsQuestionnaireInput) -> EpdsAssessmentResult:
        item_scores: dict[str, int] = {
            "item_1": responses.item_1,
            "item_2": responses.item_2,
            "item_3": 3 - responses.item_3,
            "item_4": responses.item_4,
            "item_5": 3 - responses.item_5,
            "item_6": 3 - responses.item_6,
            "item_7": 3 - responses.item_7,
            "item_8": 3 - responses.item_8,
            "item_9": 3 - responses.item_9,
            "item_10": 3 - responses.item_10,
        }

        total_score = sum(item_scores.values())
        item_10_score = item_scores["item_10"]
        self_harm_risk = item_10_score > 0

        # Invariant 1: Item 10 positive unconditionally triggers crisis support
        if self_harm_risk:
            return EpdsAssessmentResult(
                total_score=total_score,
                item_10_score=item_10_score,
                self_harm_risk=True,
                severity=PostpartumAlertSeverity.IMMEDIATE_CRISIS_SUPPORT,
                title="Atención y Apoyo Urgente Requerido",
                message=(
                    f"Puntaje global EPDS: {total_score}/30 con respuesta positiva "
                    f"en pensamientos de autolesión (ítem 10 = {item_10_score} pts)."
                ),
                action_recommended=(
                    "Por favor, comunícate de inmediato con una línea de apoyo en "
                    "crisis, acude a urgencias o contacta a un profesional de salud "
                    "mental perinatal. No estás sola y hay acompañamiento disponible."
                ),
                item_scores=item_scores,
            )

        # Invariant 2: Item 10 is zero, classify by total cut-off points
        if total_score >= 13:
            return EpdsAssessmentResult(
                total_score=total_score,
                item_10_score=0,
                self_harm_risk=False,
                severity=PostpartumAlertSeverity.PRIORITY_CONSULT,
                title="Sintomatología Depresiva Posparto Significativa",
                message=(
                    f"Puntaje EPDS de {total_score}/30 (por encima del umbral "
                    "clínico de corte >= 13)."
                ),
                action_recommended=(
                    "Recomendamos prioritariamente consultar con un profesional de "
                    "salud mental perinatal o con tu obstetra para una valoración "
                    "diagnóstica y plan de apoyo."
                ),
                item_scores=item_scores,
            )
        elif 10 <= total_score <= 12:
            return EpdsAssessmentResult(
                total_score=total_score,
                item_10_score=0,
                self_harm_risk=False,
                severity=PostpartumAlertSeverity.ROUTINE_MONITORING,
                title="Sintomatología Emocional Leve a Moderada",
                message=(
                    f"Puntaje EPDS de {total_score}/30 en rango preventivo de "
                    "atención (10–12)."
                ),
                action_recommended=(
                    "Sugerimos compartir cómo te sientes con tu red de apoyo familiar, "
                    "procurar descanso y repetir el tamizaje en 2 semanas."
                ),
                item_scores=item_scores,
            )

        return EpdsAssessmentResult(
            total_score=total_score,
            item_10_score=0,
            self_harm_risk=False,
            severity=PostpartumAlertSeverity.REASSURING,
            title="Bienestar Emocional Adecuado",
            message=(
                f"Puntaje EPDS de {total_score}/30 dentro del rango esperable (< 10)."
            ),
            action_recommended=(
                "Continúa atendiendo tu descanso y bienestar. Si en algún momento "
                "sientes que las emociones te sobrepasan, puedes repetir el tamizaje."
            ),
            item_scores=item_scores,
        )
