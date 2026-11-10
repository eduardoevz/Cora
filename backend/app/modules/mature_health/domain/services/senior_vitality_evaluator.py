"""Domain service for WHO DXA bone density, fall risk, and pelvic health."""

from app.modules.mature_health.domain.models.bone_fall_and_urogynecology import (
    ContinenceAndPelvicLog,
    DexaBoneResult,
    FallRiskAssessment,
)
from app.modules.mature_health.domain.value_objects import (
    BoneDensityCategory,
    BoneDensityClassification,
    FallRiskLevel,
    FallRiskResult,
    FractureRiskAlert,
    IncontinenceType,
    PelvicFloorGuidance,
)


class SeniorVitalityEvaluator:
    """Evaluates bone mineral density, fall hazards, and pelvic floor wellbeing."""

    def classify_bone_density(self, dexa: DexaBoneResult) -> BoneDensityClassification:
        """Classify bone mineral density according to WHO criteria."""
        if dexa.t_score <= -2.5:
            if dexa.previous_fragility_fracture:
                category = BoneDensityCategory.SEVERE_OSTEOPOROSIS
                summary = (
                    "Osteoporosis severa confirmada por T-score <= -2.5 y "
                    "antecedente de fractura por fragilidad."
                )
            else:
                category = BoneDensityCategory.OSTEOPOROSIS
                summary = (
                    "Osteoporosis identificada según criterios OMS (T-score <= -2.5). "
                    "Se sugiere evaluación médica para prevención de fracturas."
                )
        elif dexa.t_score < -1.0:
            category = BoneDensityCategory.OSTEOPENIA
            summary = (
                "Osteopenia (densidad ósea reducida con T-score entre -1.0 y -2.5). "
                "Se aconseja ejercicio con carga, calcio y vitamina D."
            )
        else:
            category = BoneDensityCategory.NORMAL
            summary = "Densidad mineral ósea normal (T-score >= -1.0)."

        return BoneDensityClassification(
            category=category,
            t_score=dexa.t_score,
            anatomical_site=dexa.anatomical_site,
            clinical_summary=summary,
        )

    def evaluate_fall_risk(self, assessment: FallRiskAssessment) -> FallRiskResult:
        """Evaluate functional mobility and calculate composite fall risk."""
        score = 0
        actions: list[str] = []

        if assessment.falls_past_year >= 2:
            score += 3
            actions.append(
                "Múltiples caídas en el último año: requiere revisión médica."
            )
        elif assessment.falls_past_year == 1:
            score += 2
            actions.append("Caída reciente: revisar calzado y factores ambientales.")

        if assessment.has_gait_unsteadiness:
            score += 2
            actions.append(
                "Inestabilidad de marcha: se sugiere valoración de equilibrio."
            )

        if assessment.uses_walking_aid:
            score += 1

        if (
            assessment.timed_up_and_go_seconds is not None
            and assessment.timed_up_and_go_seconds > 12.0
        ):
            score += 2
            actions.append("Prueba Timed Up and Go (>12s) sugiere riesgo motor.")

        if score >= 4:
            level = FallRiskLevel.HIGH
            actions.append(
                "Riesgo de caídas elevado: adaptar iluminación y barras de apoyo."
            )
        elif score >= 2:
            level = FallRiskLevel.MODERATE
            actions.append(
                "Riesgo de caídas moderado: ejercicio para balance y fuerza."
            )
        else:
            level = FallRiskLevel.LOW
            actions.append(
                "Bajo riesgo de caídas: mantener caminatas diarias y vida activa."
            )

        return FallRiskResult(
            risk_level=level,
            score=score,
            preventive_actions=tuple(actions),
        )

    def generate_fracture_prevention_alert(
        self,
        dexa_result: DexaBoneResult,
        fall_assessment: FallRiskAssessment,
    ) -> FractureRiskAlert | None:
        """Trigger alert when fall risk intersects with compromised bone strength."""
        bone_classification = self.classify_bone_density(dexa_result)
        fall_eval = self.evaluate_fall_risk(fall_assessment)

        bone_at_risk = bone_classification.category in (
            BoneDensityCategory.OSTEOPENIA,
            BoneDensityCategory.OSTEOPOROSIS,
            BoneDensityCategory.SEVERE_OSTEOPOROSIS,
        )
        fall_at_risk = fall_eval.risk_level in (
            FallRiskLevel.MODERATE,
            FallRiskLevel.HIGH,
        )

        if bone_at_risk and fall_at_risk:
            return FractureRiskAlert(
                code="HIGH_FRACTURE_RISK_ALERT",
                priority="HIGH",
                recommendations=(
                    "Se detectó riesgo elevado de fractura osteoporótica por la "
                    "combinación de densidad mineral ósea disminuida y riesgo de "
                    "caídas. Se aconseja fisioterapia motriz preventiva y adecuación "
                    "en el hogar."
                ),
            )
        return None

    def evaluate_pelvic_health(
        self, log: ContinenceAndPelvicLog
    ) -> PelvicFloorGuidance:
        """Provide supportive urogynecological and pelvic recommendations."""
        needs_consult = (
            log.incontinence_type != IncontinenceType.NONE
            or log.has_dyspareunia
            or log.vaginal_dryness_level >= 2
            or log.has_pelvic_heaviness
        )

        tips: list[str] = [
            "Ejercicios guiados de suelo pélvico (Kegel) adaptados.",
            "Mantener ingesta hídrica adecuada distribuida en el día.",
        ]

        if log.vaginal_dryness_level >= 1 or log.has_dyspareunia:
            tips.append(
                "Uso de hidratantes íntimos o consulta sobre terapia estrogénica local."
            )
        if log.daily_pad_count > 0:
            tips.append("Diario miccional y consulta médica uroginecológica integral.")

        return PelvicFloorGuidance(
            requires_urogynecology_consult=needs_consult,
            supportive_tips=tuple(tips),
        )
