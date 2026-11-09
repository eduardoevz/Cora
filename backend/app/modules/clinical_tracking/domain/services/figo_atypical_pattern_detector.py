from dataclasses import dataclass, field
from enum import StrEnum
from typing import Any

from app.modules.clinical_tracking.domain.models.menstrual_cycle import (
    CycleSymptomLog,
    MenstrualCycle,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    BleedingFlow,
    PatientCycleContext,
)
from app.modules.identity.domain.value_objects.life_stage import LifeStage


class FigoAlertType(StrEnum):
    """FIGO standard classification for atypical uterine bleeding patterns."""

    POLYMENORRHEA = "polymenorrhea"
    OLIGOMENORRHEA = "oligomenorrhea"
    PROLONGED_BLEEDING = "prolonged_bleeding"
    INTERMENSTRUAL_SPOTTING = "intermenstrual_spotting"
    SEVERE_PELVIC_PAIN_ENDOMETRIOSIS_RISK = "severe_pelvic_pain_endometriosis_risk"


class AlertSeverity(StrEnum):
    """Clinical severity level for preventative guidance."""

    INFO = "info"
    ATTENTION = "attention"
    CLINICAL_RECOMMENDATION = "clinical_recommendation"


@dataclass(frozen=True)
class ClinicalPatternAlert:
    """Structured preventative alert adhering to empathetic clinical language."""

    alert_type: FigoAlertType
    severity: AlertSeverity
    title_es: str
    description_es: str
    recommendation_es: str
    evidence: dict[str, Any] = field(default_factory=dict)


class FigoAtypicalPatternDetector:
    """Clinical domain service evaluating menstrual cycles and symptom logs

    Detects atypical patterns according to FIGO criteria and adolescent guidelines.
    """

    def evaluate(
        self,
        cycles: list[MenstrualCycle],
        symptoms: list[CycleSymptomLog],
        context: PatientCycleContext,
    ) -> list[ClinicalPatternAlert]:
        alerts: list[ClinicalPatternAlert] = []

        is_teen = context.life_stage == LifeStage.ADOLESCENCE
        min_normal_days = 21 if is_teen else 24
        max_normal_days = 45 if is_teen else 38

        # 1. Cycle Length & Frequency Rules (FIGO) - Only for natural cycles
        if not context.is_hormonally_suppressed:
            short_cycles = [
                c
                for c in cycles
                if c.cycle_length_days is not None
                and c.cycle_length_days < min_normal_days
            ]
            if short_cycles:
                desc = (
                    f"Tus ciclos recientes han durado menos de {min_normal_days} "
                    "días. Según los criterios FIGO, esto se clasifica como "
                    "sangrado frecuente (polimenorrea)."
                    if not is_teen
                    else (
                        "Tus ciclos recientes han tenido una duración menor a 21 "
                        "días, por debajo del rango habitual para tu etapa de "
                        "desarrollo."
                    )
                )
                alerts.append(
                    ClinicalPatternAlert(
                        alert_type=FigoAlertType.POLYMENORRHEA,
                        severity=AlertSeverity.ATTENTION,
                        title_es="Patrón de sangrado frecuente (Polimenorrea)",
                        description_es=desc,
                        recommendation_es=(
                            "Te recomendamos registrar con atención tus días de "
                            "sangrado y consultar con un ginecólogo si este "
                            "patrón persiste."
                        ),
                        evidence={
                            "min_normal_days": min_normal_days,
                            "observed_lengths": [
                                c.cycle_length_days for c in short_cycles
                            ],
                        },
                    )
                )

            long_cycles = [
                c
                for c in cycles
                if c.cycle_length_days is not None
                and c.cycle_length_days > max_normal_days
            ]
            if long_cycles:
                if context.has_pcos:
                    title = "Intervalo menstrual prolongado en contexto de SOP"
                    desc = (
                        "Tus ciclos han superado los umbrales habituales. En el "
                        "síndrome de ovario poliquístico, la ovulación infrecuente "
                        "es un patrón común."
                    )
                    recom = (
                        "Continúa monitoreando tus síntomas y mantén el "
                        "seguimiento con tu especialista en ginecología o "
                        "endocrinología."
                    )
                else:
                    title = "Patrón de sangrado infrecuente (Oligomenorrea)"
                    desc = (
                        f"Tus ciclos recientes han durado más de {max_normal_days} "
                        "días. Según los criterios FIGO, esto corresponde a "
                        "sangrado infrecuente u oligomenorrea."
                        if not is_teen
                        else (
                            "Tus ciclos han superado los 45 días de duración, "
                            "por encima de la variabilidad esperada para tu "
                            "desarrollo."
                        )
                    )
                    recom = (
                        "Es aconsejable comentar esta variación con tu médica "
                        "o ginecóloga para evaluar tus niveles hormonales."
                    )

                alerts.append(
                    ClinicalPatternAlert(
                        alert_type=FigoAlertType.OLIGOMENORRHEA,
                        severity=AlertSeverity.ATTENTION,
                        title_es=title,
                        description_es=desc,
                        recommendation_es=recom,
                        evidence={
                            "max_normal_days": max_normal_days,
                            "observed_lengths": [
                                c.cycle_length_days for c in long_cycles
                            ],
                        },
                    )
                )

        # 2. Bleeding Duration (Prolonged Bleeding > 8 days)
        prolonged_cycles = [
            c
            for c in cycles
            if c.bleeding_duration_days is not None and c.bleeding_duration_days > 8
        ]
        if prolonged_cycles:
            alerts.append(
                ClinicalPatternAlert(
                    alert_type=FigoAlertType.PROLONGED_BLEEDING,
                    severity=AlertSeverity.ATTENTION,
                    title_es="Sangrado menstrual prolongado",
                    description_es=(
                        "Has registrado sangrado durante más de 8 días. "
                        "El criterio FIGO considera prolongado cualquier "
                        "sangrado que exceda los 8 días."
                    ),
                    recommendation_es=(
                        "Si el sangrado persiste o te sientes fatigada, acude a "
                        "valoración médica para evaluar tus niveles de hierro."
                    ),
                    evidence={
                        "max_duration_threshold": 8,
                        "observed_durations": [
                            c.bleeding_duration_days for c in prolonged_cycles
                        ],
                    },
                )
            )

        # 3. Intermenstrual Spotting
        # Spotting entries in symptoms (outside the first 5 days of cycle)
        spotting_logs = [
            s for s in symptoms if s.bleeding_flow == BleedingFlow.SPOTTING
        ]
        if len(spotting_logs) >= 2:
            alerts.append(
                ClinicalPatternAlert(
                    alert_type=FigoAlertType.INTERMENSTRUAL_SPOTTING,
                    severity=AlertSeverity.ATTENTION,
                    title_es="Manchado intermenstrual detectado",
                    description_es=(
                        "Hemos detectado registros de manchado ligero fuera de tus "
                        "días habituales de menstruación."
                    ),
                    recommendation_es=(
                        "El manchado intermenstrual repetido amerita observación "
                        "clínica para valorar causas funcionales o anatómicas."
                    ),
                    evidence={
                        "spotting_dates": [
                            s.log_date.isoformat() for s in spotting_logs
                        ]
                    },
                )
            )

        # 4. Severe Pelvic Pain / Endometriosis Risk (Pain >= 7 in >= 2 cycles)
        severe_pain_logs = [
            s
            for s in symptoms
            if (s.pelvic_pain is not None and s.pelvic_pain >= 7)
            or (s.dysmenorrhea is not None and s.dysmenorrhea >= 7)
        ]
        # Identify how many distinct cycles have severe pain
        cycles_with_pain = {
            s.cycle_id for s in severe_pain_logs if s.cycle_id is not None
        }
        if len(cycles_with_pain) >= 2:
            alerts.append(
                ClinicalPatternAlert(
                    alert_type=FigoAlertType.SEVERE_PELVIC_PAIN_ENDOMETRIOSIS_RISK,
                    severity=AlertSeverity.CLINICAL_RECOMMENDATION,
                    title_es="Dolor pélvico persistente de intensidad elevada",
                    description_es=(
                        "Has reportado dolor pélvico o cólicos menstruales severos "
                        "(7/10 o superior) durante al menos dos ciclos distintos. "
                        "Este dolor no debe normalizarse y sugiere valoración "
                        "ginecológica para descartar condiciones como endometriosis."
                    ),
                    recommendation_es=(
                        "Agenda una consulta ginecológica integral orientada a "
                        "salud pélvica. Lleva tu historial de Cora a la consulta."
                    ),
                    evidence={
                        "affected_cycle_count": len(cycles_with_pain),
                        "max_pain_score": max(
                            [s.pelvic_pain or 0 for s in severe_pain_logs]
                            + [s.dysmenorrhea or 0 for s in severe_pain_logs]
                        ),
                    },
                )
            )

        return alerts
