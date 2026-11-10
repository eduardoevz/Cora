"""Domain service for STRAW+10 staging, bleeding safety, and lipid panels."""

from app.modules.mature_health.domain.models.vasomotor_and_metabolic_logs import (
    CardiometabolicPanel,
    VaginalBleedingObservation,
)
from app.modules.mature_health.domain.value_objects import (
    CardiometabolicAssessment,
    CardiometabolicRiskLevel,
    MenopauseClinicalAlert,
    MenopauseClinicalAlertSeverity,
    Straw10Stage,
)


class MenopauseTransitionService:
    """Evaluates menopausal staging, postmenopausal bleeding, and lipids."""

    def classify_straw10_stage(
        self,
        age: int,
        consecutive_cycle_lengths: list[int],
        days_since_last_menstruation: int,
    ) -> Straw10Stage:
        """Classify menopausal transition stage based on STRAW+10 criteria."""
        # Postmenopause: >= 365 days (12 consecutive months) of amenorrhea
        if days_since_last_menstruation >= 365:
            return Straw10Stage.POSTMENOPAUSE

        # Late transition: amenorrhea interval >= 60 days
        if days_since_last_menstruation >= 60:
            return Straw10Stage.LATE_TRANSITION

        # Early transition: persistent difference >= 7 days in consecutive cycles
        if len(consecutive_cycle_lengths) >= 2:
            has_persistent_variability = False
            for i in range(len(consecutive_cycle_lengths) - 1):
                diff = abs(
                    consecutive_cycle_lengths[i + 1] - consecutive_cycle_lengths[i]
                )
                if diff >= 7:
                    has_persistent_variability = True
                    break
            if has_persistent_variability:
                return Straw10Stage.EARLY_TRANSITION

        # Late reproductive stage
        return Straw10Stage.LATE_REPRODUCTIVE

    def evaluate_bleeding_safety(
        self, observation: VaginalBleedingObservation
    ) -> MenopauseClinicalAlert | None:
        """Inviolable Clinical Rule: Bleeding after >= 365d amenorrhea is a red flag."""
        if observation.days_of_prior_amenorrhea >= 365:
            return MenopauseClinicalAlert(
                code="POSTMENOPAUSAL_BLEEDING_ALERT",
                severity=MenopauseClinicalAlertSeverity.URGENT_EMERGENCY,
                title="Alerta de Sangrado Posmenopáusico",
                clinical_guidance=(
                    "Se ha registrado sangrado vaginal tras 12 o más meses "
                    "consecutivos de amenorrea. Esta situación requiere "
                    "evaluación médica prioritaria por ginecología con ecografía "
                    "transvaginal para evaluar el grosor endometrial y descartar "
                    "patología o hiperplasia endometrial."
                ),
                requires_immediate_clinical_evaluation=True,
            )
        return None

    def evaluate_cardiometabolic_panel(
        self, panel: CardiometabolicPanel
    ) -> CardiometabolicAssessment:
        """Evaluate cardiometabolic risks given lipid profile and blood pressure."""
        flagged: list[str] = []
        recommendations: list[str] = []

        if panel.ldl_cholesterol_mg_dl is not None:
            if panel.ldl_cholesterol_mg_dl >= 160.0:
                flagged.append("ldl_cholesterol")
                recommendations.append(
                    "Colesterol LDL elevado: evaluación médica y plan nutricional."
                )
            elif panel.ldl_cholesterol_mg_dl >= 130.0:
                flagged.append("ldl_cholesterol_borderline")

        if panel.hdl_cholesterol_mg_dl is not None and (
            panel.hdl_cholesterol_mg_dl < 50.0
        ):
            flagged.append("hdl_cholesterol")
            recommendations.append(
                "Colesterol HDL bajo: se sugiere actividad física aeróbica regular."
            )

        if panel.triglycerides_mg_dl is not None and (
            panel.triglycerides_mg_dl >= 150.0
        ):
            flagged.append("triglycerides")
            recommendations.append(
                "Triglicéridos elevados: moderar azúcares simples y carbohidratos."
            )

        if panel.systolic_bp is not None and panel.diastolic_bp is not None:
            if panel.systolic_bp >= 140 or panel.diastolic_bp >= 90:
                flagged.append("blood_pressure")
                recommendations.append(
                    "Presión arterial en rango de hipertensión: control médico."
                )
            elif panel.systolic_bp >= 130 or panel.diastolic_bp >= 85:
                flagged.append("blood_pressure_borderline")

        if panel.fasting_glucose_mg_dl is not None and (
            panel.fasting_glucose_mg_dl >= 100.0
        ):
            flagged.append("fasting_glucose")
            recommendations.append(
                "Glucosa en ayuno alterada: se aconseja hemoglobina glucosilada."
            )

        if (
            any(
                p in flagged
                for p in ["ldl_cholesterol", "blood_pressure", "fasting_glucose"]
            )
            or len(flagged) >= 2
        ):
            risk_level = CardiometabolicRiskLevel.ELEVATED_RISK
        elif flagged:
            risk_level = CardiometabolicRiskLevel.BORDERLINE
        else:
            risk_level = CardiometabolicRiskLevel.OPTIMAL
            recommendations.append(
                "Perfil cardiometabólico en rangos óptimos. Estilo de vida activo."
            )

        return CardiometabolicAssessment(
            risk_level=risk_level,
            flagged_parameters=tuple(flagged),
            recommendations=tuple(recommendations),
        )
