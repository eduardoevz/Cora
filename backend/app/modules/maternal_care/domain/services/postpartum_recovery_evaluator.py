from dataclasses import dataclass, field

from app.modules.maternal_care.domain.value_objects.postpartum_observations import (
    CesareanWoundStatus,
    LochiaFlow,
    LochiaStage,
    PelvicFloorSymptom,
    PerinealWoundStatus,
    PostpartumAlertSeverity,
    PostpartumClinicalAlert,
)


@dataclass(frozen=True)
class PostpartumRecoveryEvaluationInput:
    days_postpartum: int
    lochia_stage: LochiaStage
    lochia_flow: LochiaFlow
    foul_odor: bool = False
    maternal_temperature_c: float | None = None
    perineal_wound_status: PerinealWoundStatus | None = None
    cesarean_wound_status: CesareanWoundStatus | None = None
    pelvic_floor_symptoms: list[PelvicFloorSymptom] = field(default_factory=list)


class PostpartumRecoveryEvaluator:
    """Evaluates physiological postpartum recovery, lochia, and wound healing."""

    def evaluate(
        self, obs: PostpartumRecoveryEvaluationInput
    ) -> list[PostpartumClinicalAlert]:
        alerts: list[PostpartumClinicalAlert] = []

        # 1. Secondary Postpartum Hemorrhage
        if obs.lochia_flow == LochiaFlow.HEAVY_SOAKING_PAD_UNDER_1H:
            alerts.append(
                PostpartumClinicalAlert(
                    severity=PostpartumAlertSeverity.URGENT_EMERGENCY,
                    category="secondary_postpartum_hemorrhage",
                    title="Sospecha de Hemorragia Posparto Secundaria",
                    message=(
                        "Empapar una compresa grande en menos de 1 hora requiere "
                        "atención urgente."
                    ),
                    action_recommended=(
                        "Acudir de inmediato al servicio de urgencias obstétricas "
                        "sin demora."
                    ),
                )
            )
        elif obs.lochia_flow == LochiaFlow.CLOTS_GREATER_THAN_GOLF_BALL:
            alerts.append(
                PostpartumClinicalAlert(
                    severity=PostpartumAlertSeverity.URGENT_EMERGENCY,
                    category="secondary_postpartum_hemorrhage",
                    title="Expulsión de Coágulos Excesivos",
                    message=(
                        "Presencia de coágulos persistentes mayores a una pelota "
                        "de golf."
                    ),
                    action_recommended=(
                        "Acudir a urgencias para revisión ecográfica y tono uterino."
                    ),
                )
            )

        # 2. Puerperal Endometritis and Fever
        if obs.foul_odor:
            alerts.append(
                PostpartumClinicalAlert(
                    severity=PostpartumAlertSeverity.URGENT_EMERGENCY,
                    category="puerperal_infection",
                    title="Loquios Fétidos / Sospecha de Endometritis",
                    message=(
                        "El olor fétido o desagradable en los loquios es signo "
                        "cardinal de infección intrauterina."
                    ),
                    action_recommended=(
                        "Acudir a valoración médica urgente para descarte de "
                        "endometritis puerperal."
                    ),
                )
            )
        elif (
            obs.maternal_temperature_c is not None
            and obs.maternal_temperature_c >= 38.0
        ):
            alerts.append(
                PostpartumClinicalAlert(
                    severity=PostpartumAlertSeverity.URGENT_EMERGENCY,
                    category="puerperal_fever",
                    title="Fiebre Puerperal (>= 38.0 °C)",
                    message=(
                        f"Temperatura materna de {obs.maternal_temperature_c:.1f} °C "
                        "en periodo posparto."
                    ),
                    action_recommended=(
                        "Consulta médica urgente para identificar foco infeccioso "
                        "(uterino, mastitis o herida)."
                    ),
                )
            )

        # 3. Atypical Lochia Regression
        if (
            obs.days_postpartum >= 14
            and obs.lochia_stage == LochiaStage.RUBRA
            and obs.lochia_flow
            in (LochiaFlow.MODERATE, LochiaFlow.HEAVY_SOAKING_PAD_UNDER_1H)
        ):
            alerts.append(
                PostpartumClinicalAlert(
                    severity=PostpartumAlertSeverity.PRIORITY_CONSULT,
                    category="atypical_lochia_regression",
                    title="Regresión Atípica de Loquios",
                    message=(
                        f"Retorno de sangrado rojo moderado a abundante a los "
                        f"{obs.days_postpartum} días posparto."
                    ),
                    action_recommended=(
                        "Contactar a su gineco-obstetra para descartar "
                        "subinvolución uterina o restos."
                    ),
                )
            )

        # 4. Cesarean Wound Healing
        if (
            obs.cesarean_wound_status
            == CesareanWoundStatus.PURULENT_DRAINAGE_OR_DEHISCENCE
        ):
            alerts.append(
                PostpartumClinicalAlert(
                    severity=PostpartumAlertSeverity.URGENT_EMERGENCY,
                    category="cesarean_wound_infection",
                    title="Alerta de Infección en Herida Quirúrgica de Cesárea",
                    message=(
                        "Presencia de secreción purulenta o separación de bordes en "
                        "la incisión."
                    ),
                    action_recommended=(
                        "Acudir de urgencia para curación, cultivo y valoración "
                        "quirúrgica."
                    ),
                )
            )
        elif obs.cesarean_wound_status == CesareanWoundStatus.ERYTHEMA_HEAT:
            alerts.append(
                PostpartumClinicalAlert(
                    severity=PostpartumAlertSeverity.PRIORITY_CONSULT,
                    category="cesarean_wound_inflammation",
                    title="Inflamación en Herida de Cesárea",
                    message=(
                        "Enrojecimiento o calor local en los bordes de la cicatriz."
                    ),
                    action_recommended=(
                        "Consulta prioritaria con su obstetra para vigilar evolución "
                        "de la herida."
                    ),
                )
            )

        # 5. Perineal Wound / Episiotomy
        if (
            obs.perineal_wound_status
            == PerinealWoundStatus.PURULENT_DISCHARGE_OR_DEHISCENCE
        ):
            alerts.append(
                PostpartumClinicalAlert(
                    severity=PostpartumAlertSeverity.URGENT_EMERGENCY,
                    category="perineal_wound_infection",
                    title="Infección o Dehiscencia en Episiotomía / Periné",
                    message=(
                        "Secreción purulenta o dehiscencia de suturas perineales."
                    ),
                    action_recommended=(
                        "Acudir a urgencias para revisión ginecológica y curación."
                    ),
                )
            )
        elif obs.perineal_wound_status == PerinealWoundStatus.ERYTHEMA_EDEMA:
            alerts.append(
                PostpartumClinicalAlert(
                    severity=PostpartumAlertSeverity.PRIORITY_CONSULT,
                    category="perineal_wound_inflammation",
                    title="Inflamación Perineal Marcada",
                    message="Edema o eritema pronunciado en la zona perineal.",
                    action_recommended=(
                        "Revisión médica para control de cicatrización y analgesia "
                        "adecuada."
                    ),
                )
            )

        # 6. Pelvic Floor
        if PelvicFloorSymptom.PELVIC_HEAVINESS_PROLAPSE in obs.pelvic_floor_symptoms:
            alerts.append(
                PostpartumClinicalAlert(
                    severity=PostpartumAlertSeverity.PRIORITY_CONSULT,
                    category="pelvic_floor_dysfunction",
                    title="Sensación de Peso o Prolapso Pélvico",
                    message="Sensación de bulto o pesadez perineal al ponerse de pie.",
                    action_recommended=(
                        "Programar valoración especializada de suelo pélvico tras "
                        "la cuarentena."
                    ),
                )
            )

        return alerts
