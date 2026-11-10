from decimal import Decimal

from app.modules.maternal_care.domain.value_objects.maternal_vitals import (
    BloodPressure,
    CapillaryGlucoseReading,
    GlucoseTiming,
    MaternalAlertSeverity,
    MaternalClinicalAlert,
    MaternalRiskCategory,
    MaternalSymptom,
    MaternalSymptomType,
)


class MaternalRiskEvaluator:
    """
    Deterministic clinical risk evaluator for maternal care following ACOG guidelines.
    Evaluates:
    1. Blood Pressure & Preeclampsia severity
    2. Capillary glucose & Gestational Diabetes indicators
    3. Severe obstetric warning signs
    """

    SEVERE_PREECLAMPSIA_SYMPTOMS = {
        MaternalSymptomType.PERSISTENT_SEVERE_HEADACHE,
        MaternalSymptomType.SCOTOMAS_VISUAL_BLUR,
        MaternalSymptomType.EPIGASTRIC_RUQ_PAIN,
        MaternalSymptomType.SUDDEN_FACIAL_HAND_EDEMA,
    }

    def evaluate_vitals(
        self,
        blood_pressure: BloodPressure | None,
        gestational_weeks: int,
        symptoms: list[MaternalSymptom],
        glucose: CapillaryGlucoseReading | None = None,
    ) -> list[MaternalClinicalAlert]:
        alerts: list[MaternalClinicalAlert] = []

        if blood_pressure is not None:
            self._evaluate_blood_pressure(blood_pressure, symptoms, alerts)

        if glucose is not None:
            self._evaluate_glucose(glucose, alerts)

        self._evaluate_emergency_symptoms(symptoms, alerts)

        return alerts

    def _evaluate_blood_pressure(
        self,
        bp: BloodPressure,
        symptoms: list[MaternalSymptom],
        alerts: list[MaternalClinicalAlert],
    ) -> None:
        # Severe hypertension: systolic >= 160 or diastolic >= 110
        if bp.systolic_mmhg >= 160 or bp.diastolic_mmhg >= 110:
            alerts.append(
                MaternalClinicalAlert(
                    severity=MaternalAlertSeverity.URGENT_EMERGENCY,
                    category=MaternalRiskCategory.PREECLAMPSIA_RISK,
                    title="Crisis Hipertensiva / Sospecha de Preeclampsia Severa",
                    message=(
                        f"Presión arterial ({bp.formatted}) en rango de severidad "
                        "(>= 160/110 mmHg). Riesgo elevado de complicaciones agudas."
                    ),
                    action_recommended=(
                        "Acudir de inmediato al servicio de urgencias obstétricas o "
                        "centro médico más cercano sin esperar."
                    ),
                )
            )
            return

        # Mild/Moderate hypertension: systolic >= 140 or diastolic >= 90
        if bp.systolic_mmhg >= 140 or bp.diastolic_mmhg >= 90:
            severe_symptom_found = any(
                s.symptom_type in self.SEVERE_PREECLAMPSIA_SYMPTOMS for s in symptoms
            )
            if severe_symptom_found:
                alerts.append(
                    MaternalClinicalAlert(
                        severity=MaternalAlertSeverity.URGENT_EMERGENCY,
                        category=MaternalRiskCategory.PREECLAMPSIA_RISK,
                        title="Preeclampsia con signos de alarma",
                        message=(
                            f"Presión arterial ({bp.formatted}) acompañada de "
                            "síntomas de alarma (cefalea severa o visión borrosa)."
                        ),
                        action_recommended=(
                            "Acudir inmediatamente a urgencias obstétricas. "
                            "No esperar a que los síntomas cedan solos."
                        ),
                    )
                )
            else:
                alerts.append(
                    MaternalClinicalAlert(
                        severity=MaternalAlertSeverity.PRIORITY_CONSULT,
                        category=MaternalRiskCategory.PREECLAMPSIA_RISK,
                        title="Hipertensión gestacional / Cifras tensionales elevadas",
                        message=(
                            f"Presión arterial ({bp.formatted}) por encima del umbral "
                            "seguro (>= 140/90 mmHg)."
                        ),
                        action_recommended=(
                            "Descansar 15 minutos en decúbito lateral izquierdo y "
                            "repetir la medición. Notificar a su obstetra hoy mismo."
                        ),
                    )
                )

    def _evaluate_glucose(
        self,
        glucose: CapillaryGlucoseReading,
        alerts: list[MaternalClinicalAlert],
    ) -> None:
        if glucose.timing == GlucoseTiming.FASTING and glucose.value_mg_dl >= Decimal(
            "95.0"
        ):
            alerts.append(
                MaternalClinicalAlert(
                    severity=MaternalAlertSeverity.PRIORITY_CONSULT,
                    category=MaternalRiskCategory.GESTATIONAL_DIABETES_RISK,
                    title="Glucemia Basal Elevada en Embarazo",
                    message=(
                        f"Glucemia en ayunas ({glucose.value_mg_dl} mg/dL) superior a "
                        "la meta orientativa ACOG (95 mg/dL)."
                    ),
                    action_recommended=(
                        "Registrar su alimentación reciente y compartir este valor "
                        "con su obstetra para evaluar necesidad de curva de tolerancia."
                    ),
                )
            )
        elif (
            glucose.timing == GlucoseTiming.POSTPRANDIAL_1H
            and glucose.value_mg_dl >= Decimal("140.0")
        ):
            alerts.append(
                MaternalClinicalAlert(
                    severity=MaternalAlertSeverity.PRIORITY_CONSULT,
                    category=MaternalRiskCategory.GESTATIONAL_DIABETES_RISK,
                    title="Glucemia Posprandial (1h) Elevada",
                    message=(
                        f"Glucemia a 1 hora ({glucose.value_mg_dl} mg/dL) superior "
                        "a la meta orientativa ACOG (140 mg/dL)."
                    ),
                    action_recommended=(
                        "Comentar el registro con su equipo de salud para valorar plan "
                        "nutricional o tamizaje metabólico."
                    ),
                )
            )
        elif (
            glucose.timing == GlucoseTiming.POSTPRANDIAL_2H
            and glucose.value_mg_dl >= Decimal("120.0")
        ):
            alerts.append(
                MaternalClinicalAlert(
                    severity=MaternalAlertSeverity.PRIORITY_CONSULT,
                    category=MaternalRiskCategory.GESTATIONAL_DIABETES_RISK,
                    title="Glucemia Posprandial (2h) Elevada",
                    message=(
                        f"Glucemia a 2 horas ({glucose.value_mg_dl} mg/dL) superior "
                        "a la meta orientativa ACOG (120 mg/dL)."
                    ),
                    action_recommended=(
                        "Registrar el valor para el próximo control prenatal y "
                        "consultar pautas dietéticas."
                    ),
                )
            )

    def _evaluate_emergency_symptoms(
        self,
        symptoms: list[MaternalSymptom],
        alerts: list[MaternalClinicalAlert],
    ) -> None:
        for s in symptoms:
            if s.symptom_type == MaternalSymptomType.VAGINAL_BLEEDING:
                alerts.append(
                    MaternalClinicalAlert(
                        severity=MaternalAlertSeverity.URGENT_EMERGENCY,
                        category=MaternalRiskCategory.GENERAL_OBSTETRIC,
                        title="Sangrado Vaginal en Gestación",
                        message=(
                            "Presencia de sangrado vaginal activo durante el embarazo."
                        ),
                        action_recommended=(
                            "Acudir de inmediato a urgencias obstétricas para "
                            "descartar desprendimiento o causas cervicales."
                        ),
                    )
                )
            elif s.symptom_type == MaternalSymptomType.AMNIOTIC_FLUID_LEAK:
                alerts.append(
                    MaternalClinicalAlert(
                        severity=MaternalAlertSeverity.URGENT_EMERGENCY,
                        category=MaternalRiskCategory.GENERAL_OBSTETRIC,
                        title="Sospecha de Rotura Prematura de Membranas",
                        message=("Pérdida continua o repentina de líquido amniótico."),
                        action_recommended=(
                            "Acudir a urgencias para confirmación clínica con "
                            "espéculo y test de líquido amniótico."
                        ),
                    )
                )
